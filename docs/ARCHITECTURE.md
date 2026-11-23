# Checklist-Student — Architecture & Engineering Guide

## 1. Project Overview
**Checklist-Student** is a single-codebase Flutter Web application for classroom management (attendance, assignments, scoring, grading, report export, and a read-only student portal).
- **Multi-tenant from Day 1:** Isolated per teacher using Supabase Row Level Security (`teacher_id = auth.uid()`).
- **Development Priority:** Complete Teacher App (`/teacher/...`) first; build Student Portal (`/student/:teacherCode`) last on pre-designed database tables and RPCs.

## 2. Tech Stack & Infrastructure
- **Frontend:** Flutter Web (Dart), Material Design 3
- **State Management:** Riverpod
- **Routing:** `go_router` (`/teacher/...` and `/student/:teacherCode`)
- **Backend:** Supabase (Google Auth, PostgreSQL + RLS, Edge Functions via Local Docker, Private Storage `import-sources`)
- **Local Database (Phase 6 Offline-First):** Drift (SQLite WASM + IndexedDB for Flutter Web) — prepared via empty `*_local_datasource.dart` interfaces during Phases 1–5
- **AI Integration:** Gemini API Free Tier invoked strictly via Supabase Edge Functions, gated by `teacher_feature_flags.can_use_ai`
- **CI/CD:** GitHub Actions (`flutter analyze` + `flutter build web` on `dev` and `main`) -> Pull Request to `main` -> Auto Deploy on Vercel

## 3. Project Folder Structure (Single Source of Truth)
```text
checklist_student/
├── .github/
│   └── workflows/
│       └── ci.yml                      # รัน flutter analyze + flutter build web ทั้ง dev และ main
├── docs/
│   ├── ARCHITECTURE.md                 # สถาปัตยกรรมและโครงสร้างโฟลเดอร์ (Single Source of Truth)
│   ├── AI_RULES.md                     # กติกากลางสำหรับ AI Agent ทุกตัว
│   └── USE_CASE_TEST_LOG.md            # เช็กลิสต์บันทึกปัญหาจากใช้งานจริงเพื่อต่อยอด Test
├── AGENTS.md                           # ไฟล์ชี้เป้าให้ AI Agent อ่าน docs/AI_RULES.md และ docs/ARCHITECTURE.md
├── supabase/
│   ├── config.toml                     # ตั้งค่า Supabase Local Docker
│   ├── migrations/                     # ไฟล์ SQL Schema, RLS, Triggers, RPCs, pg_cron
│   └── functions/
│       └── parse-roster-ai/            # Edge Function เรียก Gemini API อ่านรูป/PDF รายชื่อ
├── assets/
│   └── fonts/
│       └── Sarabun-Regular.ttf         # ฟอนต์สารบรรณสำหรับ Export PDF ทางการ
├── lib/
│   ├── main.dart                       # จุดเริ่มต้นแอพ (Init Supabase + ProviderScope เท่านั้น)
│   ├── app.dart                        # Root MaterialApp.router (Theme + Router)
│   ├── core/
│   │   ├── config/
│   │   │   └── env_config.dart
│   │   ├── constants/
│   │   │   ├── app_routes.dart         # /teacher/... และ /student/:teacherCode
│   │   │   ├── attendance_status.dart  # present / late / leave / absent
│   │   │   └── submission_status.dart  # submitted / late / missing
│   │   ├── errors/
│   │   │   ├── app_exception.dart
│   │   │   └── thai_error_mapper.dart
│   │   ├── network/
│   │   │   ├── supabase_client_provider.dart
│   │   │   └── connectivity_provider.dart
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   └── auth_redirect_guard.dart
│   │   ├── theme/
│   │   │   ├── app_color_scheme.dart   # Indigo Slate (#3B5BDB) Light / Dark Mode
│   │   │   ├── app_theme.dart          # Material Design 3 + Noto Sans Thai / Prompt
│   │   │   └── theme_mode_provider.dart
│   │   ├── utils/
│   │   │   ├── thai_date_formatter.dart
│   │   │   ├── thai_prefix_parser.dart
│   │   │   ├── export_filename_builder.dart
│   │   │   └── image_pdf_compressor.dart
│   │   └── widgets/
│   │       ├── app_shell_scaffold.dart
│   │       ├── app_splash_view.dart
│   │       ├── skeleton_box.dart
│   │       ├── app_feedback_banner.dart
│   │       ├── unsaved_changes_guard.dart
│   │       └── typed_confirm_dialog.dart
│   └── features/
│       ├── auth/
│       ├── dashboard/
│       ├── academic_structure/
│       ├── homeroom_roster/
│       ├── attendance/
│       ├── grading/                    # [แม่แบบมาตรฐาน 3 ชั้น + 1 ไฟล์ 1 หน้าที่สำหรับทุก Feature]
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── grading_remote_datasource.dart
│       │   │   │   └── grading_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── score_category_dto.dart
│       │   │   │   ├── assignment_dto.dart
│       │   │   │   └── student_score_dto.dart
│       │   │   └── repositories/
│       │   │       └── grading_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── score_category.dart
│       │   │   │   ├── assignment.dart
│       │   │   │   ├── student_score.dart
│       │   │   │   └── grade_result.dart
│       │   │   ├── repositories/
│       │   │   │   └── grading_repository.dart
│       │   │   └── services/
│       │   │       ├── score_calculator_service.dart
│       │   │       ├── grade_evaluator_service.dart
│       │   │       └── special_grade_advisor_service.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   ├── grading_table_controller.dart
│       │       │   ├── grading_filter_provider.dart
│       │       │   └── plan_editor_controller.dart
│       │       ├── pages/
│       │       │   ├── grading_table_page.dart
│       │       │   └── grading_plan_page.dart
│       │       └── widgets/
│       │           ├── frozen_grade_grid.dart
│       │           ├── editable_score_cell.dart
│       │           ├── save_status_indicator.dart
│       │           ├── student_profile_drawer.dart
│       │           ├── special_grade_badge.dart
│       │           └── copy_plan_dialog.dart
│       ├── audit_log/
│       ├── export_reports/
│       ├── sync_queue/
│       ├── settings/
│       └── student_portal/
└── test/
    ├── core/
    │   └── thai_prefix_parser_test.dart
    └── features/
        ├── grading/
        │   ├── score_calculator_service_test.dart
        │   ├── grade_evaluator_service_test.dart
        │   └── special_grade_advisor_service_test.dart
        └── sync_queue/
            └── offline_sync_queue_test.dart
```

## 4. Architectural Principles

### 4.1 Feature-First + Clean Layered Architecture
Every feature under `lib/features/<feature_name>/` (all 11 features, following the `features/grading/` blueprint) is strictly divided into 3 layers:
1. **`data/`** — Remote/Local DataSources, DTOs (JSON serialization), and Repository Implementations. **Only this layer may import `supabase_flutter` or `drift` / local database packages.**
2. **`domain/`** — Pure Dart Entities, Abstract Repository Interfaces, and Pure Business Logic Services (grading, prefix parsing, risk calculations). **Zero Flutter UI or Supabase dependencies.**
3. **`presentation/`** — Riverpod Controllers/Providers, Pages, and modular Widgets. Communicates with data strictly through Domain Repository Interfaces.

### 4.2 Repository Pattern (Offline-First Preparation)
- Repositories expose clean domain methods to Riverpod controllers.
- Phases 1–5 implement `*_remote_datasource.dart` only while keeping empty `*_local_datasource.dart` interfaces.
- Phase 6 plugs **Drift** (`*_local_datasource.dart`, caching **active term only**) and Sync Queue into `*_repository_impl.dart` without modifying UI or domain logic.
- Mutable classroom tables (`attendance_sessions`, `attendance_records`, `assignments`, `student_scores`, `class_enrollments`) include `version` for Optimistic Locking conflict detection.

### 4.3 Single Responsibility Principle (1 File = 1 Responsibility)
- One public class, widget, provider/controller, entity, or pure service per file.
- File names must explicitly describe their role using `snake_case` (e.g., `editable_score_cell.dart`, `grade_evaluator_service.dart`, `copy_plan_dialog.dart`).
- Keep UI files lean: split reusable sections, dialogs, and table cells into separate widget files inside `presentation/widgets/`.

## 5. UI, Design System & Localization Standards
- **Theme:** Material Design 3, Indigo Slate seed (`#3B5BDB`), supporting Light and Dark modes.
- **Typography:** `Noto Sans Thai` or `Prompt` for app UI; `Sarabun` exclusively for official PDF exports.
- **Responsive Layout:**
  - Desktop: Collapsible left Sidebar + full data grid experience (frozen left columns & top header, Enter/Tab navigation).
  - Mobile/Tablet: Bottom Navigation Bar optimized for fast classroom attendance checking.
- **Loading & Feedback:**
  - Splash screen on initial load + Skeleton Loading for async content (no blank screens).
  - Thai-language `Snackbar`/`Banner` with retry actions for immediate errors + dedicated Sync Queue status page.
- **Dates & Numbers:**
  - Store dates as standard ISO Date (`YYYY-MM-DD`) in PostgreSQL; display in **Thai Buddhist Era (พ.ศ.)** across UI and exports via `core/utils/thai_date_formatter.dart`.
  - Display total scores with **exact decimals (no automatic rounding)**.

## 6. Core Domain Rules (Non-Negotiable)
1. **4-Level Hierarchy:** `Academic Year (พ.ศ.)` -> `Term` -> `Subject` -> `Subject Class`. Active term is derived from date range with manual pin override (max 1 pinned active term per teacher enforced via Partial Unique Index `idx_terms_one_pinned_active_per_teacher` + RPC `set_pinned_active_term`) and dropdown history switching. Past terms remain editable under standard safety guards.
2. **Term-Level Homeroom Roster:** Shared roster per `Academic Year + Term`. Edits inside a subject class prompt whether to update this class only or sync back to the master homeroom.
3. **Student Lifecycle:** Mid-term additions leave prior attendance blank (`enrolled_at`); withdrawals use Soft Delete (`status = 'transferred_out'`) preserving original `student_number` (manual "Renumber" action available).
4. **Accidental-Edit Protection:**
   - Attendance: Fixed 4 statuses (`present`, `late`, `leave`, `absent`), "Mark All Present", and lock/confirmation against accidental overwrite.
   - Gradebook: Preview mode by default (require double/triple tap or explicit "Edit" button), Auto-save per cell with `"บันทึกแล้ว"` indicator.
   - Student Drawer: Opens only via dedicated trailing icon button (clicking row/name does not open it).
   - Settings/Plan Forms: Confirm before leaving with unsaved changes (`UnsavedChangesGuard`).
   - Structural Deletion: Display impact summary counts and require typed name confirmation (`TypedConfirmDialog`).
5. **Free-Tier Guardrails:**
   - Imported image/PDF originals compressed client-side to `<= 500 KB`, retained for 1 academic year, with manual yearly cleanup.
   - Score Audit Log: `AFTER INSERT OR UPDATE OF score` on `student_scores` (initial non-null entry locked as `is_initial_entry = TRUE`, 2-minute debounce, max 10 entries per score cell) + `AFTER UPDATE OF special_grade_override` on `class_enrollments` (`target_type = 'grade_status'`), plus manual CSV/JSON export before yearly reset and `pg_cron` automated cleanup for logs older than 1 year (scores are never deleted).
6. **Student Portal Security:**
   - URL format: `/student/:teacherCode?openExternalBrowser=1` (supports auto-redirect from old codes).
   - `anon` role has zero direct table access; all reads/PIN checks go through `SECURITY DEFINER` RPCs with Bcrypt-hashed 6-digit PINs, 5-attempt lockout, and server-side filtering of score/grade visibility toggles.

## 7. Testing & Maintenance Workflow
- Write Unit Tests in `test/` for critical pure logic: score calculation, flexible grading, `ร`/`มส` recommendations, Thai prefix parsing, and offline sync queue behavior.
- Log all real-world classroom bugs and edge cases in `docs/USE_CASE_TEST_LOG.md` to convert into regression tests over time.
- Branching: Develop on feature/`dev` branches -> verify GitHub Actions CI passes (`flutter analyze` + `flutter build web`) -> open PR to `main`.
