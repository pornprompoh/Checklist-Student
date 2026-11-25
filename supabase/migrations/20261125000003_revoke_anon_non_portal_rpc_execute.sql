-- Security Hardening (Phase 8.1 Full Database Security Audit):
-- Revoke default PUBLIC/anon EXECUTE privilege on teacher-only RPC
-- `public.set_pinned_active_term(UUID)` and internal trigger functions so that
-- `anon` can EXECUTE strictly the 4 Student Portal RPCs and nothing else.

REVOKE ALL ON FUNCTION public.set_pinned_active_term(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_pinned_active_term(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.handle_new_teacher() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.archive_old_teacher_code() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.log_student_score_change() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.log_enrollment_grade_status_change() FROM PUBLIC, anon;
