-- ============================================================
-- Migration 6: Student Portal SECURITY DEFINER RPCs (Phase 7 — Step 7.1)
-- Zero Direct Table Access for `anon`: ONLY these 4 RPCs are executable by `anon`.
-- - Uses `SET search_path = public, extensions` so pgcrypto `crypt()`/`gen_salt()`
--   work consistently on both Supabase Local Docker and Supabase Cloud.
-- - Enforces Bcrypt 6-digit PIN hashing, 5-attempt / 15-minute lockout,
--   server-side PIN re-verification on every summary fetch, and server-side
--   privacy masking for `show_score_to_student` / `show_grade_to_student`.
-- ============================================================

-- 1. Resolve current or historical teacher_code for Student Portal URLs
CREATE OR REPLACE FUNCTION public.resolve_teacher_code(
  p_teacher_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_code TEXT := lower(trim(COALESCE(p_teacher_code, '')));
  v_teacher RECORD;
BEGIN
  IF v_code = '' THEN
    RETURN jsonb_build_object(
      'found', FALSE,
      'is_redirected', FALSE,
      'requested_code', v_code
    );
  END IF;

  -- Check active teacher_code first
  SELECT teacher_code, display_name, school_name, department
  INTO v_teacher
  FROM public.teachers
  WHERE teacher_code = v_code;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'found', TRUE,
      'is_redirected', FALSE,
      'requested_code', v_code,
      'current_teacher_code', v_teacher.teacher_code,
      'teacher_display_name', v_teacher.display_name,
      'school_name', v_teacher.school_name,
      'department', v_teacher.department
    );
  END IF;

  -- Fallback to archived teacher_code_history for automatic redirect
  SELECT t.teacher_code, t.display_name, t.school_name, t.department
  INTO v_teacher
  FROM public.teacher_code_history h
  JOIN public.teachers t ON t.id = h.teacher_id
  WHERE h.old_code = v_code;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'found', TRUE,
      'is_redirected', TRUE,
      'requested_code', v_code,
      'current_teacher_code', v_teacher.teacher_code,
      'teacher_display_name', v_teacher.display_name,
      'school_name', v_teacher.school_name,
      'department', v_teacher.department
    );
  END IF;

  RETURN jsonb_build_object(
    'found', FALSE,
    'is_redirected', FALSE,
    'requested_code', v_code
  );
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_teacher_code(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_teacher_code(TEXT) TO anon, authenticated;

-- 2. Check whether student_code exists and whether a 6-digit PIN is set or locked
--    (NEVER returns student full name, student_identity_id, or pin_hash)
CREATE OR REPLACE FUNCTION public.check_student_portal_access(
  p_teacher_code TEXT,
  p_student_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_code TEXT := lower(trim(COALESCE(p_teacher_code, '')));
  v_student_code TEXT := trim(COALESCE(p_student_code, ''));
  v_teacher_id UUID;
  v_identity RECORD;
  v_is_locked BOOLEAN;
  v_remaining INT;
BEGIN
  SELECT id INTO v_teacher_id
  FROM public.teachers
  WHERE teacher_code = v_code;

  IF v_teacher_id IS NULL THEN
    SELECT teacher_id INTO v_teacher_id
    FROM public.teacher_code_history
    WHERE old_code = v_code;
  END IF;

  IF v_teacher_id IS NULL THEN
    RETURN jsonb_build_object(
      'teacher_found', FALSE,
      'student_found', FALSE,
      'has_pin', FALSE,
      'is_locked', FALSE,
      'locked_until', NULL,
      'remaining_attempts', 0
    );
  END IF;

  IF v_student_code = '' THEN
    RETURN jsonb_build_object(
      'teacher_found', TRUE,
      'student_found', FALSE,
      'has_pin', FALSE,
      'is_locked', FALSE,
      'locked_until', NULL,
      'remaining_attempts', 5
    );
  END IF;

  SELECT pin_hash, failed_attempts, locked_until
  INTO v_identity
  FROM public.student_identities
  WHERE teacher_id = v_teacher_id
    AND student_code = v_student_code;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'teacher_found', TRUE,
      'student_found', FALSE,
      'has_pin', FALSE,
      'is_locked', FALSE,
      'locked_until', NULL,
      'remaining_attempts', 5
    );
  END IF;

  v_is_locked := (v_identity.locked_until IS NOT NULL AND v_identity.locked_until > NOW());
  IF v_is_locked THEN
    v_remaining := 0;
  ELSIF v_identity.locked_until IS NOT NULL AND v_identity.locked_until <= NOW() THEN
    v_remaining := 5;
  ELSE
    v_remaining := GREATEST(0, 5 - COALESCE(v_identity.failed_attempts, 0));
  END IF;

  RETURN jsonb_build_object(
    'teacher_found', TRUE,
    'student_found', TRUE,
    'has_pin', (v_identity.pin_hash IS NOT NULL),
    'is_locked', v_is_locked,
    'locked_until', CASE WHEN v_is_locked THEN v_identity.locked_until ELSE NULL END,
    'remaining_attempts', v_remaining
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_student_portal_access(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_student_portal_access(TEXT, TEXT) TO anon, authenticated;

-- 3. Set initial 6-digit PIN (Bcrypt cost 8) or verify existing PIN with
--    5-attempt / 15-minute lockout rate limiting
CREATE OR REPLACE FUNCTION public.verify_or_set_student_pin(
  p_teacher_code TEXT,
  p_student_code TEXT,
  p_pin TEXT,
  p_mode TEXT DEFAULT 'verify'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_code TEXT := lower(trim(COALESCE(p_teacher_code, '')));
  v_student_code TEXT := trim(COALESCE(p_student_code, ''));
  v_pin TEXT := COALESCE(p_pin, '');
  v_mode TEXT := lower(trim(COALESCE(p_mode, 'verify')));
  v_teacher_id UUID;
  v_identity RECORD;
  v_new_attempts INT;
  v_locked_until TIMESTAMPTZ;
BEGIN
  IF v_pin !~ '^[0-9]{6}$' THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'INVALID_PIN_FORMAT',
      'message', 'กรุณากรอกรหัส PIN เป็นตัวเลข 6 หลัก'
    );
  END IF;

  IF v_mode NOT IN ('verify', 'setup') THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'INVALID_MODE',
      'message', 'โหมดการยืนยันรหัส PIN ไม่ถูกต้อง'
    );
  END IF;

  SELECT id INTO v_teacher_id
  FROM public.teachers
  WHERE teacher_code = v_code;

  IF v_teacher_id IS NULL THEN
    SELECT teacher_id INTO v_teacher_id
    FROM public.teacher_code_history
    WHERE old_code = v_code;
  END IF;

  IF v_teacher_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'TEACHER_NOT_FOUND',
      'message', 'ไม่พบรหัสครูผู้สอน กรุณาตรวจสอบลิงก์อีกครั้ง'
    );
  END IF;

  SELECT id, pin_hash, failed_attempts, locked_until
  INTO v_identity
  FROM public.student_identities
  WHERE teacher_id = v_teacher_id
    AND student_code = v_student_code
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'STUDENT_NOT_FOUND',
      'message', 'ไม่พบรหัสนักเรียนนี้ในระบบของครูผู้สอน'
    );
  END IF;

  IF v_identity.locked_until IS NOT NULL AND v_identity.locked_until > NOW() THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'PIN_LOCKED',
      'locked_until', v_identity.locked_until,
      'remaining_attempts', 0,
      'message', 'กรอกรหัส PIN ผิดเกินกำหนด กรุณารอสักครู่แล้วลองใหม่ หรือแจ้งครูเพื่อรีเซต PIN'
    );
  END IF;

  IF v_mode = 'setup' THEN
    IF v_identity.pin_hash IS NOT NULL THEN
      RETURN jsonb_build_object(
        'success', FALSE,
        'error_code', 'PIN_ALREADY_SET',
        'message', 'รหัสนักเรียนนี้ตั้ง PIN ไว้แล้ว กรุณาเข้าสู่ระบบด้วย PIN เดิม'
      );
    END IF;

    UPDATE public.student_identities
    SET
      pin_hash = crypt(v_pin, gen_salt('bf', 8)),
      pin_updated_at = NOW(),
      failed_attempts = 0,
      locked_until = NULL,
      updated_at = NOW()
    WHERE id = v_identity.id;

    RETURN jsonb_build_object(
      'success', TRUE,
      'mode', 'setup',
      'remaining_attempts', 5,
      'locked_until', NULL
    );
  END IF;

  -- Mode: verify
  IF v_identity.pin_hash IS NULL THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'PIN_NOT_SET',
      'message', 'ยังไม่ได้ตั้งรหัส PIN กรุณาตั้งรหัส PIN 6 หลักครั้งแรก'
    );
  END IF;

  IF crypt(v_pin, v_identity.pin_hash) = v_identity.pin_hash THEN
    UPDATE public.student_identities
    SET
      failed_attempts = 0,
      locked_until = NULL,
      updated_at = NOW()
    WHERE id = v_identity.id;

    RETURN jsonb_build_object(
      'success', TRUE,
      'mode', 'verify',
      'remaining_attempts', 5,
      'locked_until', NULL
    );
  END IF;

  v_new_attempts := CASE
    WHEN v_identity.locked_until IS NOT NULL AND v_identity.locked_until <= NOW() THEN 1
    ELSE COALESCE(v_identity.failed_attempts, 0) + 1
  END;

  IF v_new_attempts >= 5 THEN
    v_locked_until := NOW() + INTERVAL '15 minutes';
    UPDATE public.student_identities
    SET
      failed_attempts = 5,
      locked_until = v_locked_until,
      updated_at = NOW()
    WHERE id = v_identity.id;

    RETURN jsonb_build_object(
      'success', FALSE,
      'error_code', 'PIN_LOCKED',
      'locked_until', v_locked_until,
      'remaining_attempts', 0,
      'message', 'กรอกรหัส PIN ผิดครบ 5 ครั้ง ระบบล็อกชั่วคราว 15 นาที'
    );
  END IF;

  UPDATE public.student_identities
  SET
    failed_attempts = v_new_attempts,
    locked_until = NULL,
    updated_at = NOW()
  WHERE id = v_identity.id;

  RETURN jsonb_build_object(
    'success', FALSE,
    'error_code', 'INVALID_PIN',
    'remaining_attempts', 5 - v_new_attempts,
    'locked_until', NULL,
    'message', 'รหัส PIN ไม่ถูกต้อง'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.verify_or_set_student_pin(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.verify_or_set_student_pin(TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;

-- 4. Fetch authenticated student's own portal summary with server-side PIN check,
--    exact unrounded NUMERIC totals, and strict server-side privacy masking.
CREATE OR REPLACE FUNCTION public.get_student_portal_summary(
  p_teacher_code TEXT,
  p_student_code TEXT,
  p_pin TEXT,
  p_term_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_code TEXT := lower(trim(COALESCE(p_teacher_code, '')));
  v_student_code TEXT := trim(COALESCE(p_student_code, ''));
  v_pin TEXT := COALESCE(p_pin, '');
  v_teacher RECORD;
  v_is_redirected BOOLEAN := FALSE;
  v_identity RECORD;
  v_available_terms JSONB := '[]'::jsonb;
  v_selected_term_id UUID;
  v_student_info JSONB := NULL;
  v_classes JSONB := '[]'::jsonb;
  v_enrollment RECORD;
  v_total_eligible INT;
  v_recorded_sessions INT;
  v_present_count INT;
  v_late_count INT;
  v_leave_count INT;
  v_absent_count INT;
  v_converted_late INT;
  v_counted_leave INT;
  v_effective_absent INT;
  v_absent_pct NUMERIC;
  v_attendance_records JSONB;
  v_total_score NUMERIC;
  v_total_max_score NUMERIC;
  v_categories_json JSONB;
  v_assignments_json JSONB;
  v_displayed_grade TEXT;
  v_evaluated_grade TEXT;
BEGIN
  IF v_pin !~ '^[0-9]{6}$' THEN
    RETURN jsonb_build_object(
      'authorized', FALSE,
      'error_code', 'INVALID_PIN_FORMAT',
      'message', 'กรุณากรอกรหัส PIN เป็นตัวเลข 6 หลัก'
    );
  END IF;

  -- Resolve teacher (current or historical code)
  SELECT id, teacher_code, display_name, school_name, department
  INTO v_teacher
  FROM public.teachers
  WHERE teacher_code = v_code;

  IF NOT FOUND THEN
    SELECT t.id, t.teacher_code, t.display_name, t.school_name, t.department
    INTO v_teacher
    FROM public.teacher_code_history h
    JOIN public.teachers t ON t.id = h.teacher_id
    WHERE h.old_code = v_code;

    IF FOUND THEN
      v_is_redirected := TRUE;
    ELSE
      RETURN jsonb_build_object(
        'authorized', FALSE,
        'error_code', 'TEACHER_NOT_FOUND',
        'message', 'ไม่พบรหัสครูผู้สอน กรุณาตรวจสอบลิงก์อีกครั้ง'
      );
    END IF;
  END IF;

  -- Verify student identity & PIN every single call
  SELECT id, student_code, pin_hash, locked_until
  INTO v_identity
  FROM public.student_identities
  WHERE teacher_id = v_teacher.id
    AND student_code = v_student_code;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'authorized', FALSE,
      'error_code', 'STUDENT_NOT_FOUND',
      'message', 'ไม่พบรหัสนักเรียนนี้ในระบบของครูผู้สอน'
    );
  END IF;

  IF v_identity.locked_until IS NOT NULL AND v_identity.locked_until > NOW() THEN
    RETURN jsonb_build_object(
      'authorized', FALSE,
      'error_code', 'PIN_LOCKED',
      'locked_until', v_identity.locked_until,
      'message', 'กรอกรหัส PIN ผิดเกินกำหนด กรุณารอสักครู่แล้วลองใหม่ หรือแจ้งครูเพื่อรีเซต PIN'
    );
  END IF;

  IF v_identity.pin_hash IS NULL THEN
    RETURN jsonb_build_object(
      'authorized', FALSE,
      'error_code', 'PIN_NOT_SET',
      'message', 'ยังไม่ได้ตั้งรหัส PIN กรุณาตั้งรหัส PIN 6 หลักครั้งแรก'
    );
  END IF;

  IF crypt(v_pin, v_identity.pin_hash) <> v_identity.pin_hash THEN
    RETURN jsonb_build_object(
      'authorized', FALSE,
      'error_code', 'INVALID_PIN',
      'message', 'รหัส PIN ไม่ถูกต้อง'
    );
  END IF;

  -- Build ordered list of terms this student is enrolled in for this teacher
  WITH student_terms AS (
    SELECT DISTINCT
      t.id AS term_id,
      ay.year_be AS academic_year_be,
      t.term_label,
      t.start_date,
      t.end_date,
      t.is_pinned_active
    FROM public.class_enrollments ce
    JOIN public.subject_classes sc ON sc.id = ce.subject_class_id
    JOIN public.subjects sub ON sub.id = sc.subject_id
    JOIN public.terms t ON t.id = sub.term_id
    JOIN public.academic_years ay ON ay.id = t.academic_year_id
    WHERE ce.student_identity_id = v_identity.id
      AND ce.teacher_id = v_teacher.id
  ),
  ordered_terms AS (
    SELECT *
    FROM student_terms
    ORDER BY
      is_pinned_active DESC,
      (CURRENT_DATE BETWEEN start_date AND end_date) DESC,
      academic_year_be DESC,
      start_date DESC,
      term_label DESC
  )
  SELECT
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'term_id', ot.term_id,
          'academic_year_be', ot.academic_year_be,
          'term_label', ot.term_label,
          'start_date', ot.start_date,
          'end_date', ot.end_date,
          'is_pinned_active', ot.is_pinned_active
        )
      ),
      '[]'::jsonb
    ),
    CASE
      WHEN p_term_id IS NOT NULL AND EXISTS (SELECT 1 FROM ordered_terms WHERE term_id = p_term_id)
      THEN p_term_id
      ELSE (SELECT term_id FROM ordered_terms LIMIT 1)
    END
  INTO v_available_terms, v_selected_term_id
  FROM ordered_terms ot;

  -- Student display info (from selected term or latest enrollment; no teacher-only fields)
  SELECT jsonb_build_object(
    'student_code', ce.student_code,
    'prefix', ce.prefix,
    'first_name', ce.first_name,
    'last_name', ce.last_name
  )
  INTO v_student_info
  FROM public.class_enrollments ce
  JOIN public.subject_classes sc ON sc.id = ce.subject_class_id
  JOIN public.subjects sub ON sub.id = sc.subject_id
  WHERE ce.student_identity_id = v_identity.id
    AND ce.teacher_id = v_teacher.id
  ORDER BY
    (sub.term_id = v_selected_term_id) DESC,
    ce.updated_at DESC
  LIMIT 1;

  IF v_student_info IS NULL THEN
    v_student_info := jsonb_build_object(
      'student_code', v_identity.student_code,
      'prefix', '',
      'first_name', '',
      'last_name', ''
    );
  END IF;

  -- Build per-class attendance, assignments, scores, and grade with strict masking
  IF v_selected_term_id IS NOT NULL THEN
    FOR v_enrollment IN
      SELECT
        ce.id AS enrollment_id,
        ce.student_number,
        ce.status AS enrollment_status,
        ce.enrolled_at,
        ce.transferred_out_at,
        ce.special_grade_override,
        sc.id AS subject_class_id,
        sc.room_name,
        sc.show_score_to_student,
        sc.show_grade_to_student,
        sc.absent_threshold_pct,
        sc.late_to_absent_ratio,
        sc.count_leave_as_absent,
        sc.grading_rules,
        sub.subject_code,
        sub.subject_name
      FROM public.class_enrollments ce
      JOIN public.subject_classes sc ON sc.id = ce.subject_class_id
      JOIN public.subjects sub ON sub.id = sc.subject_id
      WHERE ce.student_identity_id = v_identity.id
        AND ce.teacher_id = v_teacher.id
        AND sub.term_id = v_selected_term_id
      ORDER BY sub.subject_code ASC, sc.room_name ASC
    LOOP
      -- A. Attendance statistics & per-session records (respecting enrolled_at & transferred_out_at)
      WITH eligible_sessions AS (
        SELECT
          ases.id AS session_id,
          ases.session_date,
          ar.status AS record_status,
          COALESCE(ar.note, '') AS record_note
        FROM public.attendance_sessions ases
        LEFT JOIN public.attendance_records ar
          ON ar.session_id = ases.id
         AND ar.enrollment_id = v_enrollment.enrollment_id
        WHERE ases.subject_class_id = v_enrollment.subject_class_id
          AND ases.teacher_id = v_teacher.id
          AND ases.session_date >= v_enrollment.enrolled_at
          AND (
            v_enrollment.enrollment_status <> 'transferred_out'
            OR v_enrollment.transferred_out_at IS NULL
            OR ases.session_date < v_enrollment.transferred_out_at
          )
      )
      SELECT
        COUNT(*)::int,
        COUNT(*) FILTER (WHERE record_status IS NOT NULL)::int,
        COUNT(*) FILTER (WHERE record_status = 'present')::int,
        COUNT(*) FILTER (WHERE record_status = 'late')::int,
        COUNT(*) FILTER (WHERE record_status = 'leave')::int,
        COUNT(*) FILTER (WHERE record_status = 'absent')::int,
        COALESCE(
          (
            SELECT jsonb_agg(
              jsonb_build_object(
                'session_date', es.session_date,
                'status', es.record_status,
                'note', es.record_note
              )
              ORDER BY es.session_date DESC
            )
            FROM eligible_sessions es
            WHERE es.record_status IS NOT NULL
          ),
          '[]'::jsonb
        )
      INTO
        v_total_eligible,
        v_recorded_sessions,
        v_present_count,
        v_late_count,
        v_leave_count,
        v_absent_count,
        v_attendance_records
      FROM eligible_sessions;

      v_converted_late := CASE
        WHEN v_enrollment.late_to_absent_ratio IS NOT NULL AND v_enrollment.late_to_absent_ratio > 0
        THEN FLOOR(v_late_count::numeric / v_enrollment.late_to_absent_ratio)::int
        ELSE 0
      END;
      v_counted_leave := CASE
        WHEN v_enrollment.count_leave_as_absent THEN v_leave_count
        ELSE 0
      END;
      v_effective_absent := v_absent_count + v_converted_late + v_counted_leave;
      v_absent_pct := CASE
        WHEN v_total_eligible > 0
        THEN (v_effective_absent::numeric * 100.0) / v_total_eligible::numeric
        ELSE 0.0
      END;

      -- B. Exact NUMERIC score calculation (unrounded) + server-side score masking
      SELECT
        COALESCE(SUM(ss.score), 0::numeric),
        COALESCE(SUM(a.max_score), 0::numeric)
      INTO v_total_score, v_total_max_score
      FROM public.assignments a
      LEFT JOIN public.student_scores ss
        ON ss.assignment_id = a.id
       AND ss.enrollment_id = v_enrollment.enrollment_id
      WHERE a.subject_class_id = v_enrollment.subject_class_id
        AND a.teacher_id = v_teacher.id;

      -- Category score breakdown (earned_score masked to NULL if show_score_to_student = FALSE)
      SELECT COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'category_id', cat_row.category_id,
            'category_name', cat_row.category_name,
            'target_max_score', cat_row.target_max_score,
            'max_score', cat_row.max_score,
            'earned_score', CASE
              WHEN v_enrollment.show_score_to_student THEN cat_row.earned_score
              ELSE NULL
            END
          )
          ORDER BY cat_row.sort_order ASC, cat_row.category_name ASC
        ),
        '[]'::jsonb
      )
      INTO v_categories_json
      FROM (
        SELECT
          sc_cat.id AS category_id,
          COALESCE(sc_cat.name, 'งานทั่วไป') AS category_name,
          sc_cat.target_max_score,
          COALESCE(sc_cat.sort_order, 2147483647) AS sort_order,
          COALESCE(SUM(a.max_score), 0::numeric) AS max_score,
          COALESCE(SUM(ss.score), 0::numeric) AS earned_score
        FROM public.assignments a
        LEFT JOIN public.score_categories sc_cat ON sc_cat.id = a.category_id
        LEFT JOIN public.student_scores ss
          ON ss.assignment_id = a.id
         AND ss.enrollment_id = v_enrollment.enrollment_id
        WHERE a.subject_class_id = v_enrollment.subject_class_id
          AND a.teacher_id = v_teacher.id
        GROUP BY sc_cat.id, sc_cat.name, sc_cat.target_max_score, sc_cat.sort_order
      ) AS cat_row;

      -- Assignment list (score masked to NULL if show_score_to_student = FALSE,
      -- while keeping submission_status, due_date, and is_mandatory visible)
      SELECT COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'assignment_id', a.id,
            'category_id', a.category_id,
            'category_name', COALESCE(sc_cat.name, 'งานทั่วไป'),
            'title', a.title,
            'description', a.description,
            'max_score', a.max_score,
            'is_mandatory', a.is_mandatory,
            'due_date', a.due_date,
            'submission_status', COALESCE(ss.submission_status, 'missing'),
            'score', CASE
              WHEN v_enrollment.show_score_to_student THEN ss.score
              ELSE NULL
            END,
            'note', COALESCE(ss.note, '')
          )
          ORDER BY COALESCE(sc_cat.sort_order, 2147483647) ASC, a.sort_order ASC, a.created_at ASC
        ),
        '[]'::jsonb
      )
      INTO v_assignments_json
      FROM public.assignments a
      LEFT JOIN public.score_categories sc_cat ON sc_cat.id = a.category_id
      LEFT JOIN public.student_scores ss
        ON ss.assignment_id = a.id
       AND ss.enrollment_id = v_enrollment.enrollment_id
      WHERE a.subject_class_id = v_enrollment.subject_class_id
        AND a.teacher_id = v_teacher.id;

      -- C. Grade evaluation using exact unrounded v_total_score + server-side grade masking
      v_displayed_grade := NULL;
      IF v_enrollment.show_grade_to_student THEN
        IF NULLIF(trim(COALESCE(v_enrollment.special_grade_override, '')), '') IS NOT NULL THEN
          v_displayed_grade := v_enrollment.special_grade_override;
        ELSE
          SELECT elem ->> 'grade'
          INTO v_evaluated_grade
          FROM jsonb_array_elements(v_enrollment.grading_rules) AS elem
          WHERE v_total_score >= (elem ->> 'min')::numeric
          ORDER BY (elem ->> 'min')::numeric DESC
          LIMIT 1;

          IF v_evaluated_grade IS NULL THEN
            SELECT elem ->> 'grade'
            INTO v_evaluated_grade
            FROM jsonb_array_elements(v_enrollment.grading_rules) AS elem
            ORDER BY (elem ->> 'min')::numeric ASC
            LIMIT 1;
          END IF;

          v_displayed_grade := v_evaluated_grade;
        END IF;
      END IF;

      -- Append sanitized class payload (ZERO teacher-only fields:
      -- no was_r_resolved, no was_ms_resolved, no resolved_grade_at, no grading_rules, no teacher_id)
      v_classes := v_classes || jsonb_build_array(
        jsonb_build_object(
          'subject_class_id', v_enrollment.subject_class_id,
          'subject_code', v_enrollment.subject_code,
          'subject_name', v_enrollment.subject_name,
          'room_name', v_enrollment.room_name,
          'student_number', v_enrollment.student_number,
          'enrollment_status', v_enrollment.enrollment_status,
          'enrolled_at', v_enrollment.enrolled_at,
          'show_score_to_student', v_enrollment.show_score_to_student,
          'show_grade_to_student', v_enrollment.show_grade_to_student,
          'total_score', CASE
            WHEN v_enrollment.show_score_to_student THEN v_total_score
            ELSE NULL
          END,
          'total_max_score', v_total_max_score,
          'displayed_grade', v_displayed_grade,
          'special_grade_override', CASE
            WHEN v_enrollment.show_grade_to_student THEN v_enrollment.special_grade_override
            ELSE NULL
          END,
          'attendance_summary', jsonb_build_object(
            'total_eligible_sessions', v_total_eligible,
            'recorded_sessions', v_recorded_sessions,
            'present_count', v_present_count,
            'late_count', v_late_count,
            'leave_count', v_leave_count,
            'absent_count', v_absent_count,
            'converted_late_absent_count', v_converted_late,
            'counted_leave_absent_count', v_counted_leave,
            'effective_absent_count', v_effective_absent,
            'absent_percentage', v_absent_pct,
            'absent_threshold_pct', v_enrollment.absent_threshold_pct
          ),
          'attendance_records', v_attendance_records,
          'category_scores', v_categories_json,
          'assignments', v_assignments_json
        )
      );
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'authorized', TRUE,
    'teacher', jsonb_build_object(
      'found', TRUE,
      'is_redirected', v_is_redirected,
      'requested_code', v_code,
      'current_teacher_code', v_teacher.teacher_code,
      'teacher_display_name', v_teacher.display_name,
      'school_name', v_teacher.school_name,
      'department', v_teacher.department
    ),
    'student', v_student_info,
    'available_terms', v_available_terms,
    'selected_term_id', v_selected_term_id,
    'classes', v_classes
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_portal_summary(TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_portal_summary(TEXT, TEXT, TEXT, UUID) TO anon, authenticated;
