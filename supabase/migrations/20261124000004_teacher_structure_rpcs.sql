-- ============================================================
-- 1. RPC: นับยอดผลกระทบจริงก่อนยืนยันลบโครงสร้าง (เทอม / รายวิชา / ห้องเรียน / ปีการศึกษา)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_delete_impact_summary(
  p_entity_type TEXT,
  p_entity_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_teacher_id UUID := auth.uid();
  v_terms_count INT := 0;
  v_subjects_count INT := 0;
  v_subject_classes_count INT := 0;
  v_homerooms_count INT := 0;
  v_students_count INT := 0;
  v_attendance_sessions_count INT := 0;
  v_assignments_count INT := 0;
  v_scored_assignments_count INT := 0;
BEGIN
  IF v_teacher_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_entity_type NOT IN ('academic_year', 'term', 'subject', 'subject_class') THEN
    RAISE EXCEPTION 'ประเภทโครงสร้างไม่ถูกต้อง: %', p_entity_type;
  END IF;

  IF p_entity_type = 'academic_year' THEN
    IF NOT EXISTS (SELECT 1 FROM public.academic_years WHERE id = p_entity_id AND teacher_id = v_teacher_id) THEN
      RAISE EXCEPTION 'ไม่พบปีการศึกษาที่ต้องการตรวจสอบ';
    END IF;

    SELECT COUNT(*) INTO v_terms_count
    FROM public.terms WHERE academic_year_id = p_entity_id AND teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_homerooms_count
    FROM public.homerooms h
    JOIN public.terms t ON t.id = h.term_id
    WHERE t.academic_year_id = p_entity_id AND h.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_subjects_count
    FROM public.subjects s
    JOIN public.terms t ON t.id = s.term_id
    WHERE t.academic_year_id = p_entity_id AND s.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_subject_classes_count
    FROM public.subject_classes sc
    JOIN public.subjects s ON s.id = sc.subject_id
    JOIN public.terms t ON t.id = s.term_id
    WHERE t.academic_year_id = p_entity_id AND sc.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_students_count
    FROM public.class_enrollments ce
    JOIN public.subject_classes sc ON sc.id = ce.subject_class_id
    JOIN public.subjects s ON s.id = sc.subject_id
    JOIN public.terms t ON t.id = s.term_id
    WHERE t.academic_year_id = p_entity_id AND ce.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_attendance_sessions_count
    FROM public.attendance_sessions ases
    JOIN public.subject_classes sc ON sc.id = ases.subject_class_id
    JOIN public.subjects s ON s.id = sc.subject_id
    JOIN public.terms t ON t.id = s.term_id
    WHERE t.academic_year_id = p_entity_id AND ases.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_assignments_count
    FROM public.assignments a
    JOIN public.subject_classes sc ON sc.id = a.subject_class_id
    JOIN public.subjects s ON s.id = sc.subject_id
    JOIN public.terms t ON t.id = s.term_id
    WHERE t.academic_year_id = p_entity_id AND a.teacher_id = v_teacher_id;

    SELECT COUNT(DISTINCT a.id) INTO v_scored_assignments_count
    FROM public.assignments a
    JOIN public.student_scores ss ON ss.assignment_id = a.id AND ss.score IS NOT NULL
    JOIN public.subject_classes sc ON sc.id = a.subject_class_id
    JOIN public.subjects s ON s.id = sc.subject_id
    JOIN public.terms t ON t.id = s.term_id
    WHERE t.academic_year_id = p_entity_id AND a.teacher_id = v_teacher_id;

  ELSIF p_entity_type = 'term' THEN
    IF NOT EXISTS (SELECT 1 FROM public.terms WHERE id = p_entity_id AND teacher_id = v_teacher_id) THEN
      RAISE EXCEPTION 'ไม่พบเทอมที่ต้องการตรวจสอบ';
    END IF;

    SELECT COUNT(*) INTO v_homerooms_count
    FROM public.homerooms WHERE term_id = p_entity_id AND teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_subjects_count
    FROM public.subjects WHERE term_id = p_entity_id AND teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_subject_classes_count
    FROM public.subject_classes sc
    JOIN public.subjects s ON s.id = sc.subject_id
    WHERE s.term_id = p_entity_id AND sc.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_students_count
    FROM public.class_enrollments ce
    JOIN public.subject_classes sc ON sc.id = ce.subject_class_id
    JOIN public.subjects s ON s.id = sc.subject_id
    WHERE s.term_id = p_entity_id AND ce.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_attendance_sessions_count
    FROM public.attendance_sessions ases
    JOIN public.subject_classes sc ON sc.id = ases.subject_class_id
    JOIN public.subjects s ON s.id = sc.subject_id
    WHERE s.term_id = p_entity_id AND ases.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_assignments_count
    FROM public.assignments a
    JOIN public.subject_classes sc ON sc.id = a.subject_class_id
    JOIN public.subjects s ON s.id = sc.subject_id
    WHERE s.term_id = p_entity_id AND a.teacher_id = v_teacher_id;

    SELECT COUNT(DISTINCT a.id) INTO v_scored_assignments_count
    FROM public.assignments a
    JOIN public.student_scores ss ON ss.assignment_id = a.id AND ss.score IS NOT NULL
    JOIN public.subject_classes sc ON sc.id = a.subject_class_id
    JOIN public.subjects s ON s.id = sc.subject_id
    WHERE s.term_id = p_entity_id AND a.teacher_id = v_teacher_id;

  ELSIF p_entity_type = 'subject' THEN
    IF NOT EXISTS (SELECT 1 FROM public.subjects WHERE id = p_entity_id AND teacher_id = v_teacher_id) THEN
      RAISE EXCEPTION 'ไม่พบรายวิชาที่ต้องการตรวจสอบ';
    END IF;

    SELECT COUNT(*) INTO v_subject_classes_count
    FROM public.subject_classes WHERE subject_id = p_entity_id AND teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_students_count
    FROM public.class_enrollments ce
    JOIN public.subject_classes sc ON sc.id = ce.subject_class_id
    WHERE sc.subject_id = p_entity_id AND ce.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_attendance_sessions_count
    FROM public.attendance_sessions ases
    JOIN public.subject_classes sc ON sc.id = ases.subject_class_id
    WHERE sc.subject_id = p_entity_id AND ases.teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_assignments_count
    FROM public.assignments a
    JOIN public.subject_classes sc ON sc.id = a.subject_class_id
    WHERE sc.subject_id = p_entity_id AND a.teacher_id = v_teacher_id;

    SELECT COUNT(DISTINCT a.id) INTO v_scored_assignments_count
    FROM public.assignments a
    JOIN public.student_scores ss ON ss.assignment_id = a.id AND ss.score IS NOT NULL
    JOIN public.subject_classes sc ON sc.id = a.subject_class_id
    WHERE sc.subject_id = p_entity_id AND a.teacher_id = v_teacher_id;

  ELSIF p_entity_type = 'subject_class' THEN
    IF NOT EXISTS (SELECT 1 FROM public.subject_classes WHERE id = p_entity_id AND teacher_id = v_teacher_id) THEN
      RAISE EXCEPTION 'ไม่พบห้องเรียนที่ต้องการตรวจสอบ';
    END IF;

    SELECT COUNT(*) INTO v_students_count
    FROM public.class_enrollments
    WHERE subject_class_id = p_entity_id AND teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_attendance_sessions_count
    FROM public.attendance_sessions
    WHERE subject_class_id = p_entity_id AND teacher_id = v_teacher_id;

    SELECT COUNT(*) INTO v_assignments_count
    FROM public.assignments
    WHERE subject_class_id = p_entity_id AND teacher_id = v_teacher_id;

    SELECT COUNT(DISTINCT a.id) INTO v_scored_assignments_count
    FROM public.assignments a
    JOIN public.student_scores ss ON ss.assignment_id = a.id AND ss.score IS NOT NULL
    WHERE a.subject_class_id = p_entity_id AND a.teacher_id = v_teacher_id;
  END IF;

  RETURN jsonb_build_object(
    'entity_type', p_entity_type,
    'entity_id', p_entity_id,
    'terms_count', v_terms_count,
    'homerooms_count', v_homerooms_count,
    'subjects_count', v_subjects_count,
    'subject_classes_count', v_subject_classes_count,
    'students_count', v_students_count,
    'attendance_sessions_count', v_attendance_sessions_count,
    'assignments_count', v_assignments_count,
    'scored_assignments_count', v_scored_assignments_count
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_delete_impact_summary(TEXT, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_delete_impact_summary(TEXT, UUID) TO authenticated;

-- ============================================================
-- 2. RPC: ซิงค์การอัปเดตนักเรียนในคลังกลางไปยังทุกวิชาที่ผูกไว้ในเทอมเดียวกัน
-- ============================================================
CREATE OR REPLACE FUNCTION public.sync_homeroom_student_update(
  p_homeroom_student_id UUID,
  p_apply_to_all_classes BOOLEAN
)
RETURNS INT
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_teacher_id UUID := auth.uid();
  v_hs RECORD;
  v_term_id UUID;
  v_updated_count INT := 0;
BEGIN
  IF v_teacher_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT hs.*, h.term_id INTO v_hs
  FROM public.homeroom_students hs
  JOIN public.homerooms h ON h.id = hs.homeroom_id
  WHERE hs.id = p_homeroom_student_id
    AND hs.teacher_id = v_teacher_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ไม่พบข้อมูลนักเรียนในคลังกลาง';
  END IF;

  v_term_id := v_hs.term_id;

  IF NOT COALESCE(p_apply_to_all_classes, FALSE) THEN
    RETURN 0;
  END IF;

  -- อัปเดตทุก class_enrollments ที่ผูกกับ homeroom_student นี้ภายใต้เทอมเดียวกัน พร้อมเพิ่ม version
  UPDATE public.class_enrollments ce
  SET
    student_code = v_hs.student_code,
    student_number = v_hs.student_number,
    prefix = v_hs.prefix,
    first_name = v_hs.first_name,
    last_name = v_hs.last_name,
    status = v_hs.status,
    transferred_out_at = v_hs.transferred_out_at,
    version = ce.version + 1,
    updated_at = NOW()
  FROM public.subject_classes sc
  JOIN public.subjects s ON s.id = sc.subject_id
  WHERE ce.subject_class_id = sc.id
    AND s.term_id = v_term_id
    AND ce.homeroom_student_id = p_homeroom_student_id
    AND ce.teacher_id = v_teacher_id;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_homeroom_student_update(UUID, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sync_homeroom_student_update(UUID, BOOLEAN) TO authenticated;
