-- เปิดสิทธิ์ระดับ Schema และ Sequence ให้ครูที่ล็อกอินแล้ว
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ตารางระบบและประวัติ: ให้สิทธิ์อ่านอย่างเดียว (SELECT)
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE
  public.teacher_feature_flags,
  public.teacher_code_history
FROM authenticated;

GRANT SELECT ON TABLE
  public.teacher_feature_flags,
  public.teacher_code_history
TO authenticated;

-- ตารางข้อมูลหลัก 16 ตาราง: ให้สิทธิ์อ่าน-เขียน (ควบคุมแถวข้อมูลด้วย RLS)
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
  public.teachers,
  public.academic_years,
  public.terms,
  public.subjects,
  public.subject_classes,
  public.homerooms,
  public.homeroom_students,
  public.student_identities,
  public.class_enrollments,
  public.attendance_sessions,
  public.attendance_records,
  public.score_categories,
  public.assignments,
  public.student_scores,
  public.score_audit_logs,
  public.import_files
TO authenticated;

-- คงการล็อกสิทธิ์ไม่ให้ anon เข้าถึงตารางโดยตรง
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
