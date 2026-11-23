# AI Coding Agent Rules — Checklist-Student

Read `docs/ARCHITECTURE.md` before writing or modifying any code. Every task must strictly obey the rules below.

## 1. Strict Code Structure & Clean Code
1. **1 File = 1 Responsibility:** Never place multiple unrelated widgets, models, repositories, or providers in a single file. If a file exceeds ~200 lines or handles more than one visual/logical concern, split it immediately.
2. **Descriptive Naming:** Use `snake_case` filenames that make the file's exact role obvious without opening it (e.g., `student_profile_drawer.dart`, `copy_plan_dialog.dart`, not `widgets.dart` or `helpers.dart`).
3. **Strict Layer Boundaries (Repository Pattern):**
   - Every feature (all 11 features) must follow the 3-layer `data/` + `domain/` + `presentation/` template of `lib/features/grading/`.
   - UI (`presentation/`) MUST NOT import `supabase_flutter` or `drift` or run raw queries.
   - Domain (`domain/`) MUST be pure Dart (no `package:flutter/...`, no `supabase_flutter`, no `drift`).
   - All backend and local DB calls go through `data/datasources/` and `data/repositories/`.
4. **State Management:** Use Riverpod consistently. Keep business calculations inside `domain/services/` rather than inside widgets or controllers.

## 2. UI, UX & Thai Language Standards
1. **Material Design 3 + Theme:** Always use `Theme.of(context).colorScheme` and `textTheme` (Indigo Slate `#3B5BDB`). Never hardcode raw colors that break Dark Mode (except semantic attendance/risk tokens defined in theme extensions).
2. **Responsive First:** Every screen must work cleanly on Desktop (Sidebar) and Mobile/Tablet (Bottom Bar). Avoid fixed pixel widths that overflow on 390px viewports.
3. **Loading & Error States:** Always render Skeleton Loading states while fetching data and Thai-language error feedback (`Snackbar`/`Banner`) with a retry option. Never show raw English stack traces or Supabase error codes to users.
4. **Thai Dates & Decimals:** Format all displayed dates via `thai_date_formatter.dart` (พ.ศ.). Never auto-round student total scores.
5. **Safety Guards:**
   - Never make gradebook cells editable on a single accidental tap; respect Preview Mode vs Edit Mode.
   - Never trigger `StudentProfileDrawer` from a generic table row tap; bind only to the explicit trailing icon button.
   - Always attach `UnsavedChangesGuard` to large settings/grading-plan forms.
   - Always show impact counts + typed name confirmation before deleting terms, subjects, or classes.

## 3. Supabase, Security & Free-Tier Compliance
1. **Never bypass RLS:** All teacher tables must include `teacher_id`. Never put Service Role keys or Gemini API keys in Flutter Web client code.
2. **AI Features:** Invoke Gemini API strictly via Supabase Edge Functions (`supabase/functions/`). Always check `teacher_feature_flags.can_use_ai` before showing AI import UI.
3. **Client-Side Compression:** Enforce `<= 500 KB` limit on imported images/PDFs before uploading to the `import-sources` bucket.
4. **Student Portal:** Never grant `anon` direct `SELECT`/`UPDATE` on tables. Use `SECURITY DEFINER` RPCs only.
5. **Optimistic Locking:** When updating `student_scores`, `attendance_records`, `attendance_sessions`, `assignments`, or `class_enrollments`, preserve `version` handling for Phase 6 Drift Offline Sync.

## 4. Workflow & Quality Gates
1. **Small Focused Edits:** Modify only files relevant to the current task. Do not refactor unrelated features unless explicitly instructed.
2. **No Dead Code or Warnings:** Code must pass `flutter analyze` with zero warnings and compile cleanly with `flutter build web`.
3. **Pure Logic Tests:** Whenever creating or modifying calculation/parsing logic in `domain/services/` or `core/utils/`, create or update matching unit tests in `test/`.
4. **Do Not Invent Schema:** Check `supabase/migrations/` before referencing table or column names. If a schema change is required, create a new migration file instead of assuming columns exist.
5. **Document Discovered Edge Cases:** When fixing a bug reported from real usage, append the scenario to `docs/USE_CASE_TEST_LOG.md`.
