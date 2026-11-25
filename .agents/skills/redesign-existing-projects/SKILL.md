---
name: redesign-existing-projects
description: "Audits and upgrades existing Checklist-Student Flutter Web screens and widgets to Modern EdTech SaaS quality (Material 3, Light & Dark dual theme, Thai typography, 0 RenderFlex overflow). Diagnoses generic AI patterns, card-in-card clutter, competing hierarchies, and missing states, then applies targeted fixes without breaking Clean Architecture or domain safety guards. Use whenever polishing, refining, auditing, or redesigning an existing page, dialog, drawer, or component."
---

# Redesign Existing Projects — Checklist-Student Edition (Flutter Web · Material 3)

This skill is a **diagnostic and refactoring guide** tailored specifically for **Checklist-Student** (Flutter Web + Material Design 3 + Riverpod + Thai EdTech SaaS). It identifies visual clutter, generic AI layout habits, weak interactive states, and responsive hazards on existing screens — then upgrades them in place without altering business logic or breaking tests.

## Design values

All concrete visual tokens (fonts, Light & Dark surfaces, semantic colors, spacing, radii, shared primitives, responsive breakpoints, and motion timing) live in the **Design Values** section at the bottom of this file and map directly to `lib/core/theme/app_color_scheme.dart`, `lib/core/theme/app_theme.dart`, and `lib/core/widgets/`.

Never invent an unapproved raw hex color, ad-hoc spacing number, arbitrary radius, or external UI framework. Always reference `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`, `AppSemanticColors.of(context)`, and `AppTheme.tabularFigures`.

## How this works

1. **Scan** — Read the target `presentation/` pages/widgets, their related tests, `docs/ARCHITECTURE.md`, `docs/AI_RULES.md`, `lib/core/theme/app_color_scheme.dart`, and `lib/core/theme/app_theme.dart`. Identify existing widgets, test assertions (text/keys/tooltips), and layout structure.
2. **Diagnose** — Run the full Design Audit below. List every generic AI pattern, card-in-card nesting issue, competing CTA hierarchy, cramped Thai typography, missing state, and narrow-viewport overflow risk before editing.
3. **Fix** — Apply targeted, modular upgrades inside Flutter Web + Material 3 following the **Fix Priority** order and **Project Guardrails**. Split any file exceeding ~200 lines into single-responsibility widgets, then verify with the mandatory test & build gate.

---

# Design audit

## 1. Typography & Thai Readability

- **Clipped Thai vowels or tone marks.** Ensure `height` stays within `1.3–1.55` (as configured in `AppTheme`) so upper vowels (`ิ ี ึ ื`), tone marks (`่ ้ ๊ ๋`), and lower vowels (`ุ ู`) are never clipped on tight buttons, chips, or table headers.
- **Flat weight hierarchy (only `w400` and `w700`).** Use the defined scale: `w400` body, `w500–w600` labels/subtitles/section titles, `w700` headings/key metrics. Avoid `w900` black weights and avoid italics anywhere — use weight, size, or `colorScheme.onSurfaceVariant` for emphasis.
- **Unaligned numbers in metrics, scores, or tables.** Apply `fontFeatures: AppTheme.tabularFigures` (`FontFeature.tabularFigures()`) on all KPI counters, attendance totals, scores, percentages, and countdown timers so columns align cleanly.
- **Arbitrary off-scale font sizes.** Resolve typography through `Theme.of(context).textTheme` (`headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`) instead of scattered raw `fontSize: 13.5` overrides.
- **Overlong uncontained text lines.** Keep descriptive copy concise and wrap text inside `Expanded` / `Flexible` with `maxLines` + `TextOverflow.ellipsis` where appropriate so long Thai room names or subject titles never trigger `RenderFlex overflowed`.

## 2. Color, Dual Theme & Surface Restraint

- **Hardcoded colors that break Dark Mode.** Never hardcode `Colors.white`, `Colors.black`, or raw `Color(0xFF...)` inside feature widgets. Use `colorScheme.surface`, `colorScheme.surfaceContainerLow`, `colorScheme.outlineVariant`, `colorScheme.onSurfaceVariant`, and `AppSemanticColors.of(context)`.
- **Card-inside-card clutter & heavy black drop shadows.** Replace nested `Card` widgets with flat `AppSurfaceCard` (`elevation: 0`, `1px` hairline `outlineVariant` border, `16px` radius) and subtle tinted inner panels (`surfaceContainerLow` without competing heavy borders). If elevation is needed (e.g., menus/dialogs), use subtle tinted elevation rather than harsh dark shadows.
- **Generic AI purple-blue gradient backgrounds.** Backgrounds stay calm and flat (`lightCanvasColor` `#F6F8FB` in Light Mode; `darkCanvasColor` `#0F141E` in Dark Mode) with a single considered Indigo Slate accent (`#3B5BDB` / `#9DB0FF`).
- **Dark-only bias or clashing surfaces.** Every screen must look equally crisp, low-glare, and WCAG AA readable (`>= 4.5:1`) in **both** Light Mode and Dark Mode.
- **Competing semantic colors.** Reserve `AppSemanticColors` strictly for real classroom meaning (`present`, `late`, `leave`, `absent`, `success`, `warning`, `danger`), never for decorative rainbow tags.

## 3. Layout, Spacing & Concentric Corner Radius

- **Concentric Corner Radius.** When a rounded box sits inside a container with padding `< 32px`, compute `innerRadius = outerRadius - padding` (applied when the result `> 2px`).
  - Example: `AppSurfaceCard` (`outerRadius: 16`) + `padding: 8` → inner box uses `BorderRadius.circular(8)`.
  - Example: `AppSurfaceCard` (`outerRadius: 16`) + `padding: 12` → inner panel/pill uses `BorderRadius.circular(4)` to `8`.
  - Example: `ClassWorkspaceBar` (`outerRadius: 12`) + `padding: 4` → active segment uses `BorderRadius.circular(8–9)`.
- **Ad-hoc spacing.** Snap all padding, gaps, and margins to the closed spacing scale: `4, 8, 12, 16, 20, 24, 32, 48`.
- **Fixed-aspect `GridView` clipping Thai text.** Never use `GridView.count` with hardcoded `childAspectRatio` for text-bearing KPI or class cards. Use `LayoutBuilder` + `Wrap` (with computed column width and intrinsic height) so cards expand naturally without clipping or bottom overflow.
- **Misaligned baselines across sibling cards.** Align headers, status badges, and bottom action rows consistently across neighboring cards; apply small `1–2px` optical adjustments where icons sit beside Thai text.
- **Missing max-width container on wide screens.** Constrain reading/form pages (`maxWidth: 960–1140`) while allowing data-dense grids (`GradingTablePage`) to use full horizontal viewport cleanly.
- **Narrow-viewport (`320px`) & short-height (`460px`) overflows.** Every `Row` with variable text must use `Expanded`/`Flexible` or convert to `Wrap`; narrow/short viewports must scroll vertically cleanly without `RenderFlex overflowed`.

## 4. Visual Hierarchy & Component Patterns

- **Competing CTAs on a single screen or card.** Keep **one clear Primary Action** (`FilledButton`) per page/card. Demote secondary actions to `OutlinedButton` / `FilledButton.tonal` and group infrequent/tertiary shortcuts into a `⋯` (`PopupMenuButton`) menu.
- **Modals for routine actions.** Prefer inline editing, expandable sections (`ExpansionTile` wrapped in `Material` — never directly inside `DecoratedBox`/`Container` with background), or slide-over drawers (`StudentProfileDrawer`) over stacked popup dialogs. Reserve dialogs for focused creation forms and destructive confirmations (`TypedConfirmDialog`).
- **Missing contextual navigation between class workspaces.** Use `ClassWorkspaceBar` (`เช็คชื่อ` · `ตารางคะแนน` · `แผนเก็บงาน` · `ส่งออกรายงาน`) on class-scoped pages so teachers switch views in 1 tap.
- **Duplicated ad-hoc headers or empty boxes.** Standardize on `AppPageHeader`, `AppSurfaceCard`, and `AppEmptyState` from `lib/core/widgets/`.
- **Single-side borders on cards.** Borders go cleanly all the way around (`RoundedRectangleBorder` with `1px` `outlineVariant`) or use surface tonal separation without border.

## 5. Interactivity & Complete UI States

- **Missing interactive feedback.** Every clickable card, tile, button, chip, and input must expose clear Hover, Pressed (`InkWell` / `Material`), Focus Ring (keyboard accessibility), and Disabled states via Material 3 `WidgetStateProperty` / theme styles.
- **Blank screens or bare spinners on load.** Use layout-matched `SkeletonBox` placeholders (never an empty white/dark void while awaiting async providers).
- **Unhelpful empty screens.** Use `AppEmptyState` (soft tinted icon circle + clear Thai title + concise guidance + 1 Primary CTA).
- **Raw error text or silent failures.** Show calm, actionable Thai feedback via `AppFeedbackBanner` (inline or floating SnackBar) mapped through `ThaiErrorMapper` with a retry button whenever recoverable.
- **Jerky transitions.** Keep micro-animations smooth and subtle (`180–260ms`, `Curves.easeOutCubic`) and avoid animating layout widths in ways that trigger transient `RenderFlex` overflows during animation frames.

## 6. Authentic Thai EdTech Copy

- **AI marketing clichés or Lorem Ipsum.** Never use filler phrases (e.g., `"ยกระดับอย่างไร้รอยต่อ"`, `"ปฏิวัติการทำงาน"`, `"ปลดล็อกศักยภาพ"`). Write direct, calm Thai classroom copy that tells teachers/students exactly what happens.
- **Vague button labels.** Replace generic `"ตกลง"` / `"ส่ง"` with concrete verb + object labels (`"เช็คชื่อวันนี้"`, `"บันทึกแผนเก็บงาน"`, `"ส่งออก ปพ.5"`, `"เข้าพอร์ทัลนักเรียน"`).
- **Calm, specific system messages.** Confirmations state the outcome clearly (`"บันทึกคะแนนเรียบร้อยแล้ว"`). Errors state what went wrong and the next action (`"ไม่สามารถเชื่อมต่อได้ บันทึกลงคิวออฟไลน์แล้ว"`).

---

# Fix priority

Apply upgrades in this order for maximum UX clarity and minimum regression risk:

1. **Typography & Visual Hierarchy** — Clear page header (`AppPageHeader`), 1 Primary CTA, Thai line heights, `AppTheme.tabularFigures`
2. **Color & Surface Cleanup** — Remove hardcoded colors and card-in-card nesting; adopt `AppSurfaceCard` + hairline `outlineVariant` + Dual Theme tokens
3. **Interactive States** — Hover, pressed, focus ring, disabled states, and clean `PopupMenuButton` for secondary actions
4. **Layout, Spacing & Concentric Radius** — Closed spacing scale, `innerRadius = outerRadius - padding`, `LayoutBuilder`/`Wrap` responsive layout (0 overflow across 6 viewports)
5. **Component Polish** — Plug in `ClassWorkspaceBar`, inline/slide-over patterns, consistent Material 3 controls
6. **Loading, Empty & Error States** — `SkeletonBox`, `AppEmptyState`, `AppFeedbackBanner` with retry
7. **Thai EdTech Copy Pass** — Crisp, natural classroom labels and calm system messages

---

# Design values (Checklist-Student Single Source of Truth)

**Tech Stack:** Flutter Web + Material Design 3 (`ThemeData`, `ColorScheme`, `AppSemanticColors`, `WidgetStateProperty`) + Riverpod + `go_router`. Never suggest Tailwind, CSS libraries, or replacing Flutter Material 3 widgets.

**Shared UI Primitives (`lib/core/widgets/`):**
- `AppPageHeader` — Standard responsive page header (`< 640px` stacks cleanly)
- `AppSurfaceCard` — Flat `16px` hairline surface card (`elevation: 0`)
- `AppEmptyState` — Tinted icon circle + title + description + 1 Primary CTA
- `ClassWorkspaceBar` — 1-tap segmented switcher (`เช็คชื่อ` · `ตารางคะแนน` · `แผนเก็บงาน` · `ส่งออกรายงาน`)
- `AppFeedbackBanner` · `SkeletonBox` · `UnsavedChangesGuard` · `TypedConfirmDialog`

**Dual Theme Surfaces (First-Class Light & Dark Mode):**

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| Canvas (`scaffoldBackgroundColor`) | `#F6F8FB` | `#0F141E` | Page backdrop behind cards |
| Surface (`colorScheme.surface`) | `#FFFFFF` | `#171F2E` | Primary cards, AppBar, Sidebar, Dialogs |
| Subtle Surface (`surfaceContainerLow`) | `#F8FAFC` | `#1A2333` | Inner strips, muted status boxes, inputs |
| Tonal Surface (`surfaceContainer`) | `#F1F5F9` | `#1E2839` | Segmented bar tracks, secondary pills |
| Hairline Border (`outlineVariant`) | `#E2E8F0` | `#273247` | `1px` borders and dividers |
| Primary Accent (`primary`) | `#3B5BDB` | `#9DB0FF` | Primary CTA, active nav icon, focus ring |
| Primary Container (`primaryContainer`) | `#E3E9FF` | `#26346E` | Selected nav pill, subject code badge |
| Text Primary (`onSurface`) | `#0F172A` | `#E2E8F0` | Headings, body text, table cells |
| Text Muted (`onSurfaceVariant`) | `#526077` | `#9AA8BE` | Subtitles, metadata, captions |

**Semantic Tokens (`AppSemanticColors.of(context)` — WCAG AA >= 4.5:1):**
- `present` / `presentContainer`, `late` / `lateContainer`, `leave` / `leaveContainer`, `absent` / `absentContainer`
- `success` / `successContainer`, `warning` / `warningContainer`, `danger` / `dangerContainer`

**Typography (Thai-First):**
- **App UI Font:** `Noto Sans Thai` (via `GoogleFonts.notoSansThaiTextTheme` in `AppTheme`; compatible with `IBM Plex Sans Thai` / `Sarabun` if configured in `AppTheme`). **Official PDF/Word Exports:** `Sarabun` / `TH Sarabun New`.
- **Line Height:** `1.3–1.35` headings/labels · `1.4–1.55` titles/body (prevents Thai vowel & tone mark clipping).
- **Weights:** `w400` body · `w500–w600` medium/semibold · `w700` bold. No italics.
- **Tabular Numbers:** Always apply `fontFeatures: AppTheme.tabularFigures` on scores, KPIs, attendance counts, and timers.

**Closed Spacing Scale:** `4, 8, 12, 16, 20, 24, 32, 48` px.

**Corner Radius Scale:**
- Buttons & compact pills: `10px` (min button height `42px`)
- Inputs, tiles, segmented bar tracks: `12px`
- Cards (`AppSurfaceCard`): `16px`
- Dialogs & bottom sheets: `20px`
- Nested elements (`padding < 32px`): `innerRadius = outerRadius - padding` (when result `> 2px`)

**Iconography:** Material Rounded (`Icons.*_rounded`) for filled/active icons and Material Outlined (`Icons.*_outlined`) for inactive/secondary icons. Never mix incompatible icon libraries or add unapproved packages.

**Motion:** `180–260ms`, `Curves.easeOutCubic` for sidebar/container/color transitions.

**Responsive Breakpoints & 6-Viewport Zero-Overflow Matrix:**
- Desktop Sidebar: `>= 900px` · Mobile/Tablet Bottom NavigationBar: `< 900px`
- Compact Header stacking: `< 640px`
- Mandatory 0 `RenderFlex overflow` test viewports: `320×568`, `390×844`, `640×460`, `899×520`, `900×520`, `1280×800`

---

# Project Non-Negotiable Guardrails (Checklist-Student)

This skill MUST NEVER violate or overwrite any of the following rules from `AGENTS.md`, `docs/ARCHITECTURE.md`, and `docs/AI_RULES.md`:

1. **Strict Scope (UI Layer Only):** Never modify `domain/`, `data/`, `supabase/migrations/`, or `lib/core/database/` during a UX/UI redesign pass.
2. **1 File = 1 Responsibility (~200 lines/file) & Strict Layer Boundaries:** Split large pages/cards into focused sub-widgets immediately. Never import `package:supabase_flutter/` or `package:drift/` inside `presentation/`, `lib/core/router/`, or `lib/core/widgets/`. Never use deprecated `dart:html`.
3. **Preserve All Safety & Domain Guards 100%:**
   - **Gradebook Preview Mode:** Single click/tap on a score cell MUST NEVER enter edit mode (require double-tap or explicit Edit Mode toggle).
   - **`StudentProfileDrawer` Guard:** Opens ONLY via the explicit trailing icon button — never by tapping a student row or name.
   - **Unsaved Changes Protection:** Keep `UnsavedChangesGuard` + `unsavedChangesStateProvider` intact on large forms and navigation switches.
   - **Destructive Action Protection:** Keep impact counts and `TypedConfirmDialog` on structural deletions and deleting scored assignments.
   - **Exact Decimals & Thai Buddhist Era:** Never auto-round student total scores; format all displayed dates in พ.ศ. via `ThaiDateFormatter`.
   - **Teacher-Only Resolved Badges:** `"เคยแก้ ร"` / `"เคยแก้ มส"` badges appear ONLY on teacher screens (never on Student Portal).
   - **Zero Client-Side PIN Persistence:** Never store Student Portal PINs in `localStorage`, `sessionStorage`, `SharedPreferences`, Drift, or URLs.
4. **Mandatory Verification Gate After Every UI Redesign:**
   - `flutter analyze` → **0 errors, 0 warnings**
   - `flutter test` → **100% pass** (including `test/core/responsive_overflow_audit_test.dart` across all 6 viewports and `test/core/architecture_and_security_audit_test.dart`)
   - `flutter build web --release` → builds cleanly

---

## Credits

Adapted for **Checklist-Student (Flutter Web + Material 3)** from [redesign-existing-projects](https://github.com/elayadesign/redesign-skill) and [taste-skill](https://github.com/Leonxlnx/taste-skill) by Leon Lin (`@LexnLin`), MIT licensed.

<details>
<summary>Original license (MIT)</summary>

```
MIT License

Copyright (c) 2026 Leonxlnx

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
</details>
