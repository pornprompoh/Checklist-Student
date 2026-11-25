-- ============================================================
-- 1. Triggers จัดการโปรไฟล์ครู รหัสครูสั้น และประวัติรหัสเก่า
-- ============================================================

-- 1.1 สร้างโปรไฟล์ครูและสิทธิ์เริ่มต้นอัตโนมัติเมื่อล็อกอิน Google ครั้งแรก
CREATE OR REPLACE FUNCTION public.handle_new_teacher()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code TEXT;
BEGIN
  -- สุ่มรหัสสั้น เช่น t-8492 โดยวนสุ่มจนกว่าจะไม่ซ้ำทั้งรหัสปัจจุบันและประวัติรหัสเก่า
  LOOP
    v_code := 't-' || lpad(floor(random() * 10000)::int::text, 4, '0');
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.teachers WHERE teacher_code = v_code)
          AND NOT EXISTS (SELECT 1 FROM public.teacher_code_history WHERE old_code = v_code);
  END LOOP;

  INSERT INTO public.teachers (id, email, display_name, teacher_code)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    v_code
  );

  INSERT INTO public.teacher_feature_flags (teacher_id, can_use_ai)
  VALUES (NEW.id, FALSE);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_teacher();

-- 1.2 เก็บรหัสครูเก่าลง teacher_code_history อัตโนมัติเมื่อครูเปลี่ยนรหัสใหม่
CREATE OR REPLACE FUNCTION public.archive_old_teacher_code()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.teacher_code <> OLD.teacher_code THEN
    -- ห้ามตั้งรหัสใหม่ซ้ำกับรหัสเก่าของครูคนอื่น
    IF EXISTS (
      SELECT 1 FROM public.teacher_code_history
      WHERE old_code = NEW.teacher_code AND teacher_id <> NEW.id
    ) THEN
      RAISE EXCEPTION 'รหัสนี้เคยถูกใช้งานแล้ว กรุณาเลือกรหัสอื่น';
    END IF;

    -- ลบออกจาก history หากครูเปลี่ยนกลับมาใช้รหัสเดิมของตัวเอง
    DELETE FROM public.teacher_code_history
    WHERE old_code = NEW.teacher_code AND teacher_id = NEW.id;

    -- บันทึกรหัสเก่าไว้สำหรับ Redirect
    INSERT INTO public.teacher_code_history (old_code, teacher_id)
    VALUES (OLD.teacher_code, OLD.id)
    ON CONFLICT (old_code) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_archive_teacher_code ON public.teachers;
CREATE TRIGGER trg_archive_teacher_code
BEFORE UPDATE OF teacher_code ON public.teachers
FOR EACH ROW EXECUTE FUNCTION public.archive_old_teacher_code();

-- ============================================================
-- 2. Audit Log 3 ชั้น (คะแนน + สถานะเกรดพิเศษ ร/มส + pg_cron รายปี)
-- ============================================================

-- 2.1 Audit Log สำหรับคะแนน (AFTER INSERT OR UPDATE OF score)
-- - INSERT ที่ score IS NOT NULL: สร้างรายการแรกทันทีพร้อมล็อก is_initial_entry = TRUE
-- - UPDATE ที่ score เปลี่ยนจริง: Debounce 2 นาที + จำกัด 10 ครั้งต่อช่อง (ล็อกครั้งแรกสุด)
CREATE OR REPLACE FUNCTION public.log_student_score_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year_id UUID;
  v_last_log RECORD;
  v_count INT;
  v_old_score_text TEXT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.score IS NULL THEN
      RETURN NEW;
    END IF;
    v_old_score_text := NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.score IS NOT DISTINCT FROM NEW.score THEN
      RETURN NEW;
    END IF;
    v_old_score_text := OLD.score::text;
  END IF;

  -- หา academic_year_id ของคะแนนช่องนี้
  SELECT t.academic_year_id INTO v_year_id
  FROM public.assignments a
  JOIN public.subject_classes sc ON sc.id = a.subject_class_id
  JOIN public.subjects s ON s.id = sc.subject_id
  JOIN public.terms t ON t.id = s.term_id
  WHERE a.id = NEW.assignment_id;

  IF v_year_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- ตรวจสอบรายการล่าสุดของช่องนี้
  SELECT * INTO v_last_log
  FROM public.score_audit_logs
  WHERE student_score_id = NEW.id AND target_type = 'score'
  ORDER BY changed_at DESC
  LIMIT 1;

  -- ชั้นที่ 1: Debounce 2 นาที (ยุบทับรายการล่าสุด คง old_value เดิมไว้ เปลี่ยนเฉพาะ new_value + เวลา)
  IF v_last_log IS NOT NULL AND (NOW() - v_last_log.changed_at) <= INTERVAL '2 minutes' THEN
    UPDATE public.score_audit_logs
    SET new_value = NEW.score::text,
        changed_at = NOW()
    WHERE id = v_last_log.id;
    RETURN NEW;
  END IF;

  -- บันทึกรายการใหม่ (หากเป็นรายการแรกสุดของช่องนี้ ให้ล็อก is_initial_entry = TRUE)
  INSERT INTO public.score_audit_logs (
    teacher_id, academic_year_id, target_type, student_score_id, enrollment_id,
    old_value, new_value, is_initial_entry
  ) VALUES (
    NEW.teacher_id, v_year_id, 'score', NEW.id, NEW.enrollment_id,
    v_old_score_text, NEW.score::text, (v_last_log IS NULL)
  );

  -- ชั้นที่ 2: จำกัด 10 ครั้งต่อช่อง (ล็อกรายการแรกสุดห้ามลบ)
  SELECT COUNT(*) INTO v_count
  FROM public.score_audit_logs
  WHERE student_score_id = NEW.id AND target_type = 'score';

  IF v_count > 10 THEN
    DELETE FROM public.score_audit_logs
    WHERE id IN (
      SELECT id FROM public.score_audit_logs
      WHERE student_score_id = NEW.id
        AND target_type = 'score'
        AND is_initial_entry = FALSE
      ORDER BY changed_at ASC
      LIMIT (v_count - 10)
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_student_score_audit ON public.student_scores;
CREATE TRIGGER trg_student_score_audit
AFTER INSERT OR UPDATE OF score ON public.student_scores
FOR EACH ROW EXECUTE FUNCTION public.log_student_score_change();

-- 2.2 Audit Log สำหรับสถานะเกรดพิเศษ ร / มส (target_type = 'grade_status')
CREATE OR REPLACE FUNCTION public.log_enrollment_grade_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year_id UUID;
  v_has_prior_log BOOLEAN;
BEGIN
  IF OLD.special_grade_override IS NOT DISTINCT FROM NEW.special_grade_override THEN
    RETURN NEW;
  END IF;

  SELECT t.academic_year_id INTO v_year_id
  FROM public.subject_classes sc
  JOIN public.subjects s ON s.id = sc.subject_id
  JOIN public.terms t ON t.id = s.term_id
  WHERE sc.id = NEW.subject_class_id;

  IF v_year_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.score_audit_logs
    WHERE enrollment_id = NEW.id AND target_type = 'grade_status'
  ) INTO v_has_prior_log;

  INSERT INTO public.score_audit_logs (
    teacher_id, academic_year_id, target_type, student_score_id, enrollment_id,
    old_value, new_value, is_initial_entry
  ) VALUES (
    NEW.teacher_id, v_year_id, 'grade_status', NULL, NEW.id,
    OLD.special_grade_override, NEW.special_grade_override, (NOT v_has_prior_log)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enrollment_grade_status_audit ON public.class_enrollments;
CREATE TRIGGER trg_enrollment_grade_status_audit
AFTER UPDATE OF special_grade_override ON public.class_enrollments
FOR EACH ROW EXECUTE FUNCTION public.log_enrollment_grade_status_change();

-- 2.3 ชั้นที่ 3: ตั้งเวลาลบเฉพาะ Log อายุเกิน 1 ปีอัตโนมัติด้วย pg_cron
-- รันทุกวันที่ 1 ของเดือน เวลา 03:00 น. (UTC) โดยไม่แตะต้องตารางคะแนนจริง
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'pg_cron') THEN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'cleanup-expired-score-audit-logs';

    PERFORM cron.schedule(
      'cleanup-expired-score-audit-logs',
      '0 3 1 * *',
      $cron$DELETE FROM public.score_audit_logs WHERE changed_at < NOW() - INTERVAL '1 year';$cron$
    );
  END IF;
END;
$$;

-- ============================================================
-- 3. RPC สลับปักหมุดเทอมปัจจุบันแบบ Atomic (ไม่ชน Partial Unique Index)
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_pinned_active_term(p_term_id UUID DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_teacher_id UUID := auth.uid();
BEGIN
  IF v_teacher_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_term_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.terms
    WHERE id = p_term_id AND teacher_id = v_teacher_id
  ) THEN
    RAISE EXCEPTION 'ไม่พบเทอมที่ต้องการปักหมุด';
  END IF;

  -- ปลดหมุดเทอมเดิมของครูคนนี้ก่อนทั้งหมด
  UPDATE public.terms
  SET is_pinned_active = FALSE,
      updated_at = NOW()
  WHERE teacher_id = v_teacher_id
    AND is_pinned_active = TRUE;

  -- ปักหมุดเทอมใหม่ (หากส่ง NULL จะเป็นการปลดหมุดเพื่อกลับไปคำนวณตามช่วงวันที่อัตโนมัติ)
  IF p_term_id IS NOT NULL THEN
    UPDATE public.terms
    SET is_pinned_active = TRUE,
        updated_at = NOW()
    WHERE id = p_term_id
      AND teacher_id = v_teacher_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.set_pinned_active_term(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_pinned_active_term(UUID) TO authenticated;

-- ============================================================
-- 4. Row Level Security (Multi-tenant แยกข้อมูลรายครู ครบ 18 ตาราง)
-- ============================================================
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_code_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homerooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subject_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homeroom_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.import_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.score_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.score_audit_logs ENABLE ROW LEVEL SECURITY;

-- 4.1 ตาราง teachers: ครูดูและแก้ได้เฉพาะแถวของตนเอง
DROP POLICY IF EXISTS "teachers_self_access" ON public.teachers;
CREATE POLICY "teachers_self_access" ON public.teachers
  FOR ALL TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- 4.2 ตาราง teacher_feature_flags: ครู "อ่าน" ได้อย่างเดียว (ห้ามแก้สิทธิ์ AI เองเด็ดขาด)
DROP POLICY IF EXISTS "feature_flags_read_own" ON public.teacher_feature_flags;
CREATE POLICY "feature_flags_read_own" ON public.teacher_feature_flags
  FOR SELECT TO authenticated
  USING (teacher_id = auth.uid());

-- 4.3 ตาราง teacher_code_history: ครูอ่านประวัติรหัสเก่าของตนเองได้
DROP POLICY IF EXISTS "code_history_read_own" ON public.teacher_code_history;
CREATE POLICY "code_history_read_own" ON public.teacher_code_history
  FOR SELECT TO authenticated
  USING (teacher_id = auth.uid());

-- 4.4 ตารางข้อมูลการสอนอีก 15 ตาราง: ครูจัดการได้เฉพาะข้อมูลที่มี teacher_id ตรงกับตนเอง
DO $$
DECLARE
  tbl TEXT;
  teacher_tables TEXT[] := ARRAY[
    'academic_years', 'terms', 'subjects', 'homerooms', 'subject_classes',
    'student_identities', 'homeroom_students', 'class_enrollments', 'import_files',
    'attendance_sessions', 'attendance_records', 'score_categories',
    'assignments', 'student_scores', 'score_audit_logs'
  ];
BEGIN
  FOREACH tbl IN ARRAY teacher_tables LOOP
    EXECUTE format('DROP POLICY IF EXISTS "teacher_isolation_%I" ON public.%I;', tbl, tbl);
    EXECUTE format(
      'CREATE POLICY "teacher_isolation_%I" ON public.%I FOR ALL TO authenticated USING (teacher_id = auth.uid()) WITH CHECK (teacher_id = auth.uid());',
      tbl, tbl
    );
  END LOOP;
END $$;

-- หมายเหตุด้านความปลอดภัย: ไม่มีการสร้าง Policy ใดๆ ให้บทบาท anon บนตารางทั้ง 18 ตาราง

-- ============================================================
-- 5. Supabase Storage Private Bucket (import-sources <= 500 KB) & Policy
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'import-sources',
  'import-sources',
  FALSE,
  512000,
  ARRAY['image/jpeg', 'image/png', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "teacher_manage_own_import_files" ON storage.objects;
CREATE POLICY "teacher_manage_own_import_files" ON storage.objects
  FOR ALL TO authenticated
  USING (
    bucket_id = 'import-sources'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'import-sources'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
