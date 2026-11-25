-- ============================================================
-- Migration 5: Grading Helper RPC (`copy_subject_class_plan`)
-- Atomic Transaction + Multi-tenant RLS (`SECURITY INVOKER` + `auth.uid()`)
-- ============================================================

CREATE OR REPLACE FUNCTION public.copy_subject_class_plan(
  p_source_class_id UUID,
  p_target_class_id UUID,
  p_replace_existing BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_teacher_id UUID := auth.uid();
  v_source RECORD;
  v_target RECORD;
  v_cat RECORD;
  v_new_category_id UUID;
  v_category_map JSONB := '{}'::jsonb;
  v_cat_sort_offset INT := 0;
  v_assign_sort_offset INT := 0;
  v_copied_categories INT := 0;
  v_copied_assignments INT := 0;
BEGIN
  IF v_teacher_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_source_class_id = p_target_class_id THEN
    RAISE EXCEPTION 'ไม่สามารถคัดลอกแผนไปยังห้องเรียนเดียวกันได้';
  END IF;

  SELECT id, grading_scale_type, grading_rules, missing_work_threshold
  INTO v_source
  FROM public.subject_classes
  WHERE id = p_source_class_id AND teacher_id = v_teacher_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ไม่พบห้องเรียนต้นทางที่ต้องการคัดลอก';
  END IF;

  SELECT id INTO v_target
  FROM public.subject_classes
  WHERE id = p_target_class_id AND teacher_id = v_teacher_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ไม่พบห้องเรียนปลายทาง';
  END IF;

  -- หากเลือกล้างแผนเดิมของห้องปลายทางก่อน (ใช้เมื่อครูยืนยันแล้วว่าต้องการแทนที่)
  IF COALESCE(p_replace_existing, FALSE) THEN
    DELETE FROM public.assignments
    WHERE subject_class_id = p_target_class_id AND teacher_id = v_teacher_id;

    DELETE FROM public.score_categories
    WHERE subject_class_id = p_target_class_id AND teacher_id = v_teacher_id;
  ELSE
    SELECT COALESCE(MAX(sort_order) + 1, 0) INTO v_cat_sort_offset
    FROM public.score_categories
    WHERE subject_class_id = p_target_class_id AND teacher_id = v_teacher_id;

    SELECT COALESCE(MAX(sort_order) + 1, 0) INTO v_assign_sort_offset
    FROM public.assignments
    WHERE subject_class_id = p_target_class_id AND teacher_id = v_teacher_id;
  END IF;

  -- 1. คัดลอกเกณฑ์ตัดเกรดและเกณฑ์งานค้างไปยังห้องปลายทาง
  UPDATE public.subject_classes
  SET
    grading_scale_type = v_source.grading_scale_type,
    grading_rules = v_source.grading_rules,
    missing_work_threshold = v_source.missing_work_threshold,
    updated_at = NOW()
  WHERE id = p_target_class_id AND teacher_id = v_teacher_id;

  -- 2. คัดลอกหมวดคะแนน (score_categories) พร้อมสร้าง map old_id -> new_id
  FOR v_cat IN
    SELECT id, name, target_max_score, sort_order
    FROM public.score_categories
    WHERE subject_class_id = p_source_class_id AND teacher_id = v_teacher_id
    ORDER BY sort_order ASC, created_at ASC
  LOOP
    INSERT INTO public.score_categories (
      teacher_id, subject_class_id, name, target_max_score, sort_order
    ) VALUES (
      v_teacher_id, p_target_class_id, v_cat.name, v_cat.target_max_score,
      v_cat_sort_offset + v_copied_categories
    )
    RETURNING id INTO v_new_category_id;

    v_category_map := v_category_map || jsonb_build_object(v_cat.id::text, v_new_category_id::text);
    v_copied_categories := v_copied_categories + 1;
  END LOOP;

  -- 3. คัดลอกชิ้นงาน (assignments) โดย map category_id ไปยังหมวดใหม่ของห้องปลายทาง
  INSERT INTO public.assignments (
    teacher_id, subject_class_id, category_id, title, description,
    max_score, is_mandatory, due_date, sort_order, version
  )
  SELECT
    v_teacher_id,
    p_target_class_id,
    CASE
      WHEN a.category_id IS NOT NULL AND (v_category_map ? a.category_id::text)
      THEN (v_category_map ->> a.category_id::text)::uuid
      ELSE NULL
    END,
    a.title,
    a.description,
    a.max_score,
    a.is_mandatory,
    a.due_date,
    v_assign_sort_offset + ROW_NUMBER() OVER (ORDER BY a.sort_order ASC, a.created_at ASC) - 1,
    1
  FROM public.assignments a
  WHERE a.subject_class_id = p_source_class_id AND a.teacher_id = v_teacher_id;

  GET DIAGNOSTICS v_copied_assignments = ROW_COUNT;

  RETURN jsonb_build_object(
    'copied_categories_count', v_copied_categories,
    'copied_assignments_count', v_copied_assignments,
    'grading_scale_type', v_source.grading_scale_type
  );
END;
$$;

REVOKE ALL ON FUNCTION public.copy_subject_class_plan(UUID, UUID, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.copy_subject_class_plan(UUID, UUID, BOOLEAN) FROM anon;
GRANT EXECUTE ON FUNCTION public.copy_subject_class_plan(UUID, UUID, BOOLEAN) TO authenticated;

-- ============================================================
-- Fix: PL/pgSQL RECORD IS NOT NULL pitfall when old_value IS NULL
-- ใช้ FOUND แทน v_last_log IS NOT NULL เพื่อให้ Debounce 2 นาทีทำงาน
-- แม้รายการล่าสุดจะเป็น initial entry (ที่ old_value เป็น NULL)
-- ============================================================
CREATE OR REPLACE FUNCTION public.log_student_score_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_year_id UUID;
  v_last_log RECORD;
  v_has_last_log BOOLEAN := FALSE;
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

  SELECT t.academic_year_id INTO v_year_id
  FROM public.assignments a
  JOIN public.subject_classes sc ON sc.id = a.subject_class_id
  JOIN public.subjects s ON s.id = sc.subject_id
  JOIN public.terms t ON t.id = s.term_id
  WHERE a.id = NEW.assignment_id;

  IF v_year_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT id, changed_at INTO v_last_log
  FROM public.score_audit_logs
  WHERE student_score_id = NEW.id AND target_type = 'score'
  ORDER BY changed_at DESC
  LIMIT 1;
  v_has_last_log := FOUND;

  -- ชั้นที่ 1: Debounce 2 นาที (ยุบทับรายการล่าสุด คง old_value และ is_initial_entry เดิมไว้)
  IF v_has_last_log AND (NOW() - v_last_log.changed_at) <= INTERVAL '2 minutes' THEN
    UPDATE public.score_audit_logs
    SET new_value = NEW.score::text,
        changed_at = NOW()
    WHERE id = v_last_log.id;
    RETURN NEW;
  END IF;

  INSERT INTO public.score_audit_logs (
    teacher_id, academic_year_id, target_type, student_score_id, enrollment_id,
    old_value, new_value, is_initial_entry
  ) VALUES (
    NEW.teacher_id, v_year_id, 'score', NEW.id, NEW.enrollment_id,
    v_old_score_text, NEW.score::text, (NOT v_has_last_log)
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
