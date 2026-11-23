-- เปิด Extension ที่จำเป็น (สำหรับ Bcrypt PIN Hash ใน Student Portal)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- ชุดที่ 1: บัญชีครู สิทธิ์ และโครงสร้าง 4 ระดับ
-- ============================================================

-- 1. ตารางโปรไฟล์ครู (ผูก 1:1 กับ auth.users จาก Google Sign-In)
CREATE TABLE public.teachers (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT NOT NULL DEFAULT '',
  school_name TEXT NOT NULL DEFAULT '',
  department TEXT NOT NULL DEFAULT '',
  teacher_code TEXT NOT NULL UNIQUE, -- เช่น 't-8492' หรือรหัสที่ครูตั้งเอง
  default_absent_threshold_pct NUMERIC(5,2) NOT NULL DEFAULT 20.00,
  default_missing_work_threshold INT NOT NULL DEFAULT 3,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT teacher_code_format CHECK (teacher_code ~ '^[a-z0-9-]{3,30}$')
);

-- 2. ตารางสิทธิ์ฟีเจอร์แยกต่างหาก (ครูอ่านได้อย่างเดียว แก้ไขได้เฉพาะ Owner ใน Supabase Dashboard)
CREATE TABLE public.teacher_feature_flags (
  teacher_id UUID PRIMARY KEY REFERENCES public.teachers(id) ON DELETE CASCADE,
  can_use_ai BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. ประวัติรหัสครูเก่า (สำหรับ Redirect ลิงก์เดิมในโน้ต LINE ไปยังรหัสใหม่อัตโนมัติ)
CREATE TABLE public.teacher_code_history (
  old_code TEXT PRIMARY KEY,
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. ระดับที่ 1: ปีการศึกษา (เก็บเลข พ.ศ. เช่น 2569)
CREATE TABLE public.academic_years (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  year_be INT NOT NULL CHECK (year_be BETWEEN 2500 AND 2700),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (teacher_id, year_be)
);

-- 5. ระดับที่ 2: เทอม (เก็บวันที่เป็น ISO Date เพื่อคำนวณเทอมปัจจุบันอัตโนมัติ + ปักหมุดเองได้)
CREATE TABLE public.terms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  term_label TEXT NOT NULL, -- เช่น '1', '2', 'ฤดูร้อน'
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_pinned_active BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (end_date >= start_date),
  UNIQUE (academic_year_id, term_label)
);

-- 6. ระดับที่ 3: รายวิชา
CREATE TABLE public.subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  term_id UUID NOT NULL REFERENCES public.terms(id) ON DELETE CASCADE,
  subject_code TEXT NOT NULL, -- เช่น 'ว31101'
  subject_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (term_id, subject_code)
);

-- 7. คลังห้องเรียนระดับปีการศึกษา + เทอม (ชุดรายชื่อกลาง)
CREATE TABLE public.homerooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  term_id UUID NOT NULL REFERENCES public.terms(id) ON DELETE CASCADE,
  name TEXT NOT NULL, -- เช่น 'ม.4/1'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (term_id, name)
);

-- 8. ระดับที่ 4: ห้องที่สอนจริงในแต่ละรายวิชา (1 วิชา + 1 ห้องเรียน)
CREATE TABLE public.subject_classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  homeroom_id UUID REFERENCES public.homerooms(id) ON DELETE SET NULL,
  room_name TEXT NOT NULL, -- เช่น 'ม.4/1'
  teaching_days SMALLINT[] NOT NULL DEFAULT '{}', -- 1=จันทร์ ... 7=อาทิตย์ (ใช้ดันการ์ดบน Dashboard)
  is_pinned BOOLEAN NOT NULL DEFAULT FALSE,

  -- สวิตช์ควบคุมฝั่ง Student Portal
  show_score_to_student BOOLEAN NOT NULL DEFAULT TRUE,
  show_grade_to_student BOOLEAN NOT NULL DEFAULT TRUE,

  -- เกณฑ์เวลาเรียนและความเสี่ยงเฉพาะห้อง/วิชา
  absent_threshold_pct NUMERIC(5,2) NOT NULL DEFAULT 20.00,
  missing_work_threshold INT NOT NULL DEFAULT 3,
  late_to_absent_ratio INT CHECK (late_to_absent_ratio IS NULL OR late_to_absent_ratio > 0), -- NULL = ไม่นับสายเป็นขาด
  count_leave_as_absent BOOLEAN NOT NULL DEFAULT FALSE,
  attendance_score_weight NUMERIC(5,2) DEFAULT NULL, -- เผื่ออนาคตผูกคะแนนเข้าเรียน

  -- โครงสร้างเกณฑ์ตัดเกรด (ยืดหยุ่นรายวิชาและคัดลอกข้ามห้อง/เทอมได้ทันที)
  grading_scale_type TEXT NOT NULL DEFAULT '0-4' CHECK (grading_scale_type IN ('0-4', 'A-F', 'custom')),
  grading_rules JSONB NOT NULL DEFAULT '[
    {"grade":"4","min":80},{"grade":"3.5","min":75},{"grade":"3","min":70},
    {"grade":"2.5","min":65},{"grade":"2","min":60},{"grade":"1.5","min":55},
    {"grade":"1","min":50},{"grade":"0","min":0}
  ]'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (subject_id, room_name)
);

-- ============================================================
-- ชุดที่ 2: ตัวตนนักเรียน คลังรายชื่อกลาง การลงทะเบียน และไฟล์นำเข้า
-- ============================================================

-- 9. ตัวตนนักเรียนระดับบัญชีครู (เก็บ PIN 6 หลักแบบ Hash เพื่อดูได้ทุกเทอม/ทุกวิชาภายใต้ครูคนนี้)
CREATE TABLE public.student_identities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  student_code TEXT NOT NULL,
  pin_hash TEXT DEFAULT NULL, -- เก็บด้วย crypt(..., gen_salt('bf')) / NULL = ยังไม่ตั้ง หรือถูกครูรีเซต
  pin_updated_at TIMESTAMPTZ DEFAULT NULL,
  failed_attempts INT NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (teacher_id, student_code)
);

-- 10. รายชื่อนักเรียนในคลังกลางของห้อง (ระดับปีการศึกษา + เทอม)
CREATE TABLE public.homeroom_students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  homeroom_id UUID NOT NULL REFERENCES public.homerooms(id) ON DELETE CASCADE,
  student_identity_id UUID NOT NULL REFERENCES public.student_identities(id) ON DELETE RESTRICT,
  student_code TEXT NOT NULL,
  student_number INT NOT NULL CHECK (student_number > 0), -- คงเลขที่เดิมแม้มีคนย้ายออก
  prefix TEXT NOT NULL DEFAULT '',
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'transferred_out')),
  transferred_out_at DATE DEFAULT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (homeroom_id, student_code)
);

-- 11. รายชื่อนักเรียนที่ผูกกับแต่ละวิชา+ห้อง (รองรับแก้เฉพาะวิชา หรือซิงค์กลับคลังกลาง)
CREATE TABLE public.class_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  subject_class_id UUID NOT NULL REFERENCES public.subject_classes(id) ON DELETE CASCADE,
  homeroom_student_id UUID REFERENCES public.homeroom_students(id) ON DELETE SET NULL,
  student_identity_id UUID NOT NULL REFERENCES public.student_identities(id) ON DELETE RESTRICT,
  student_code TEXT NOT NULL,
  student_number INT NOT NULL CHECK (student_number > 0),
  prefix TEXT NOT NULL DEFAULT '',
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'transferred_out')),
  enrolled_at DATE NOT NULL DEFAULT CURRENT_DATE, -- ใช้แยกเคสย้ายเข้ากลางเทอม
  transferred_out_at DATE DEFAULT NULL,

  -- การจัดการเกรดพิเศษ ร / มส และป้ายกำกับฝั่งครูเมื่อแก้ผ่านแล้ว
  special_grade_override TEXT DEFAULT NULL CHECK (special_grade_override IN ('ร', 'มส')),
  was_r_resolved BOOLEAN NOT NULL DEFAULT FALSE,
  was_ms_resolved BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_grade_at TIMESTAMPTZ DEFAULT NULL,

  version INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (subject_class_id, student_code)
);

-- 12. บันทึกไฟล์ต้นฉบับที่ AI อ่าน (บีบอัด <= 500 KB เพื่อตามลบคืนพื้นที่ Storage หลังครบ 1 ปี)
CREATE TABLE public.import_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  homeroom_id UUID REFERENCES public.homerooms(id) ON DELETE SET NULL,
  storage_path TEXT NOT NULL,
  original_filename TEXT NOT NULL,
  mime_type TEXT NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png', 'application/pdf')),
  file_size_bytes INT NOT NULL CHECK (file_size_bytes > 0 AND file_size_bytes <= 512000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- ============================================================
-- ชุดที่ 3: เช็คชื่อ แผนเก็บงาน คะแนน และ Audit Log
-- ============================================================

-- 13. คาบเช็คชื่อ (1 วิชา+ห้อง เช็คได้ 1 ครั้งต่อวัน แต่คนละวิชาห้องเดิมเช็คแยกกันได้)
CREATE TABLE public.attendance_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  subject_class_id UUID NOT NULL REFERENCES public.subject_classes(id) ON DELETE CASCADE,
  session_date DATE NOT NULL,
  is_locked BOOLEAN NOT NULL DEFAULT FALSE, -- ป้องกันการกดซ้ำหรือมือลั่นแก้ทับ
  note TEXT NOT NULL DEFAULT '',
  version INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (subject_class_id, session_date)
);

-- 14. รายละเอียดการเช็คชื่อรายบุคคล
CREATE TABLE public.attendance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES public.attendance_sessions(id) ON DELETE CASCADE,
  enrollment_id UUID NOT NULL REFERENCES public.class_enrollments(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('present', 'late', 'leave', 'absent')),
  note TEXT NOT NULL DEFAULT '',
  version INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, enrollment_id)
);

-- 15. หมวดคะแนนรายวิชา (เช่น เก็บ / กลางภาค / ปลายภาค)
CREATE TABLE public.score_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  subject_class_id UUID NOT NULL REFERENCES public.subject_classes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  target_max_score NUMERIC(6,2) DEFAULT NULL CHECK (target_max_score IS NULL OR target_max_score >= 0),
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 16. แผนชิ้นงาน (แก้ไขชื่องาน/คะแนนเต็มได้ตลอดโดยไม่พังข้อมูลคะแนนเดิม)
CREATE TABLE public.assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  subject_class_id UUID NOT NULL REFERENCES public.subject_classes(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.score_categories(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  max_score NUMERIC(6,2) NOT NULL CHECK (max_score >= 0),
  is_mandatory BOOLEAN NOT NULL DEFAULT FALSE, -- งานบังคับส่ง (เงื่อนไขแนะนำติด ร)
  due_date DATE DEFAULT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  version INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 17. คะแนนและสถานะงานรายบุคคล (เก็บทศนิยมตามจริงไม่ปัดเศษ)
CREATE TABLE public.student_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  assignment_id UUID NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE,
  enrollment_id UUID NOT NULL REFERENCES public.class_enrollments(id) ON DELETE CASCADE,
  submission_status TEXT NOT NULL DEFAULT 'missing' CHECK (submission_status IN ('submitted', 'late', 'missing')),
  score NUMERIC(6,2) DEFAULT NULL CHECK (score IS NULL OR score >= 0),
  note TEXT NOT NULL DEFAULT '',
  version INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (assignment_id, enrollment_id)
);

-- 18. ประวัติการแก้ไขคะแนนและสถานะเกรด (Audit Log คุมขนาด 3 ชั้น)
CREATE TABLE public.score_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL CHECK (target_type IN ('score', 'grade_status')),
  student_score_id UUID REFERENCES public.student_scores(id) ON DELETE CASCADE,
  enrollment_id UUID NOT NULL REFERENCES public.class_enrollments(id) ON DELETE CASCADE,
  old_value TEXT, -- เช่น '7.50' หรือ 'ร'
  new_value TEXT, -- เช่น '8.50' หรือ '3.5'
  is_initial_entry BOOLEAN NOT NULL DEFAULT FALSE, -- ล็อกห้ามลบเมื่อเกินโควตา 10 ครั้ง
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Indexes สำคัญ (9 Indexes ตามเอกสาร + 1 Partial Unique Index ปักหมุดเทอม)
-- ============================================================
CREATE INDEX idx_terms_teacher_year ON public.terms(teacher_id, academic_year_id);
CREATE UNIQUE INDEX idx_terms_one_pinned_active_per_teacher ON public.terms(teacher_id) WHERE is_pinned_active = TRUE;
CREATE INDEX idx_subject_classes_teacher ON public.subject_classes(teacher_id, subject_id);
CREATE INDEX idx_enrollments_class_status ON public.class_enrollments(subject_class_id, status);
CREATE INDEX idx_enrollments_identity ON public.class_enrollments(student_identity_id);
CREATE INDEX idx_attendance_records_session ON public.attendance_records(session_id);
CREATE INDEX idx_student_scores_assignment ON public.student_scores(assignment_id);
CREATE INDEX idx_student_scores_enrollment ON public.student_scores(enrollment_id);
CREATE INDEX idx_audit_logs_score_time ON public.score_audit_logs(student_score_id, changed_at DESC);
CREATE INDEX idx_audit_logs_year_cleanup ON public.score_audit_logs(teacher_id, academic_year_id, changed_at);
