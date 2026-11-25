# Checklist-Student

ระบบเช็คชื่อรายวัน ตรวจงาน ตัดเกรด ปพ.5 และพอร์ทัลตรวจสอบผลการเรียนสำหรับนักเรียนแบบ **Offline-First PWA** ออกแบบเฉพาะสำหรับบริบทห้องเรียนครูไทย (Flutter Web + Material Design 3 + Supabase + Drift SQLite WASM)

---

## ฟีเจอร์หลักครบทั้ง 7 เฟส

1. **ระบบบัญชีครูและการตั้งค่า (`Auth & Settings`)**
   - เข้าสู่ระบบด้วย Google OAuth ผ่าน Supabase Auth พร้อม Multi-Tenant Isolation ด้วย Row Level Security (`RLS`) 100% ครบทั้ง 18 ตาราง
   - จัดการข้อมูลโปรไฟล์ครู หัวเอกสาร ปพ.5 เกณฑ์เริ่มต้นของครู รหัสครูแบบกำหนดเอง (`teacher_code` พร้อมประวัติรหัสเก่าและ Auto-Redirect) และธีม Light / Dark Mode
2. **โครงสร้างปีการศึกษาและแดชบอร์ด (`Academic Structure & Dashboard`)**
   - โครงสร้าง 4 ระดับ: **ปีการศึกษา (พ.ศ.) → ภาคเรียน (กำหนดวันเปิด–ปิดหรือไม่ระบุก็ได้) → รายวิชา → ห้องเรียน**
   - คำนวณเทอมปัจจุบันอัตโนมัติพร้อมปุ่มปักหมุดเทอมปัจจุบัน (`set_pinned_active_term`)
   - แดชบอร์ดแสดงภาพรวม KPI, คาบสอนวันนี้, การ์ดห้องเรียนแบบ Equal-Height และทางลัดเข้าเช็คชื่อ/ตารางคะแนนในคลิกเดียว
3. **คลังรายชื่อกลางและนำเข้าด้วย AI (`Homeroom Roster & AI Import`)**
   - คลังรายชื่อนักเรียนประจำเทอม (`Homeroom`) เชื่อมโยงอัตโนมัติกับทุกวิชาที่สอนห้องเดียวกัน พร้อม Soft Delete (`transferred_out`) และคำสั่งเรียงเลขที่ใหม่
   - นำเข้ารายชื่อจาก **Excel / CSV (รองรับไฟล์ SGS)** และนำเข้าจาก **รูปภาพ/PDF ด้วย Gemini AI** ผ่าน Supabase Edge Function (`parse-roster-ai`) พร้อมบีบอัดไฟล์ฝั่งเบราว์เซอร์ไม่เกิน `500 KB`
4. **เช็คชื่อรายวันและเกณฑ์ มส (`Attendance & Risk Rules`)**
   - เช็คชื่อ 4 สถานะ (`มา`, `สาย`, `ลา`, `ขาด`), ปุ่ม "มาทั้งหมด", ล็อกคาบป้องกันการแก้พลาด, แยกผู้ย้ายออกเป็น Read-only และตั้งค่าเกณฑ์เสี่ยง มส รายห้อง
5. **แผนเก็บงาน ตารางคะแนน และประวัติคะแนน (`Grading Plan, Gradebook & Audit Log`)**
   - ออกแบบหมวดคะแนน, งานบังคับส่ง (`is_mandatory`), เกณฑ์ตัดเกรด (`0–4`, `A–F`, กำหนดเอง) และคัดลอกแผนข้ามห้อง/ข้ามเทอมผ่าน RPC
   - ตารางคะแนนแบบ **Frozen Columns + Preview Mode** ป้องกันการแตะแก้โดยไม่ได้ตั้งใจ, นำทางด้วย `Enter`/`Tab`, Auto-Save ทีละช่องพร้อม Optimistic Locking (`version`), คำนวณทศนิยมตามจริงไม่ปัดเศษ (`integer-cent`), แนะนำ `ร`/`มส` และ `StudentProfileDrawer`
   - ประวัติการแก้ไขคะแนน (`Audit Log`) พร้อม Debounce 2 นาที, จำกัด 10 รายการต่อช่อง, Export `.csv`/`.json` และระบบแจ้งเตือนล้าง Log รายปี (`pg_cron` 1 ปี)
6. **ส่งออกเอกสาร ปพ.5 และซิงค์ออฟไลน์ (`Export Reports & Offline-First Drift WASM`)**
   - ส่งออกรายงาน 3 รูปแบบ: **PDF ฟอนต์สารบรรณ (`Sarabun`)**, **Excel (`.xlsx` หลายชีต)** และ **Word (`.docx` ฟอนต์ `TH Sarabun New`)** พร้อมตัวอย่าง A4 แบบเรียลไทม์
   - แคชข้อมูลเทอมปัจจุบันลง **Drift SQLite WASM + IndexedDB** ใช้งานเช็คชื่อ/กรอกคะแนนต่อได้แม้เน็ตหลุด, ซิงค์อัตโนมัติพร้อม Exponential Backoff และหน้าเทียบ Conflict (`SyncQueuePage`) ไม่มี Silent Overwrite
7. **พอร์ทัลนักเรียน (`Student Portal`)**
   - นักเรียนเปิดลิงก์ `/student/:teacherCode?openExternalBrowser=1` (พร้อมแบนเนอร์แนะนำเปิดนอก LINE)
   - ยืนยันตัวตนด้วย **PIN 6 หลัก** (Bcrypt บนฝั่งเซิร์ฟเวอร์, ไม่เก็บ PIN ลง Storage ฝั่งเบราว์เซอร์, ล็อก 15 นาทีเมื่อกรอกผิด 5 ครั้ง) เข้าถึงข้อมูลผ่าน `SECURITY DEFINER` RPCs เท่านั้น และซ่อนคะแนน/เกรดจากฝั่งเซิร์ฟเวอร์ตามสวิตช์ครู

---

## Tech Stack & Architecture

- **Frontend:** Flutter Web (`3.44.4`, Dart `^3.12.2`), Material Design 3, Riverpod, `go_router` (Path URL Strategy)
- **Local Offline DB:** Drift (`sqlite3.wasm` + `drift_worker.js` บน IndexedDB)
- **Backend:** Supabase (PostgreSQL 17 + RLS + RPCs + `pg_cron` + Private Storage `import-sources` + Deno Edge Function `parse-roster-ai`)
- **Hosting & CI/CD:** GitHub Actions (`flutter analyze` → `flutter test` → `flutter build web --release`) → Vercel Prebuilt Edge CDN
- **Architecture:** Feature-First 3-Layer Clean Architecture (`data/` · `domain/` · `presentation/`) ครบทั้ง 11 Features

---

## การตั้งค่าและรันพัฒนาบนเครื่อง (Local Setup)

### 1. ข้อกำหนดเบื้องต้น
- Flutter SDK `3.44.4` (Stable Channel, เปิดใช้งาน Web)
- Node.js `20+` (สำหรับ `npx supabase` และ `npx vercel`)
- Docker Desktop (หากต้องการรัน Supabase Local Stack)

### 2. ตั้งค่าไฟล์ Environment
```bash
cp .env.example .env
```
กรอกค่าในไฟล์ `.env` (ห้าม commit ขึ้น Git):
```env
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<your-local-or-dev-anon-key>
```

### 3. เริ่มต้น Supabase Local (Optional สำหรับพัฒนาแบบออฟไลน์ในเครื่อง)
```bash
npx supabase start
npx supabase db reset
```
หากต้องการทดสอบ Edge Function นำเข้ารายชื่อด้วย AI (`parse-roster-ai`) บนเครื่อง:
```bash
cp supabase/functions/.env.example supabase/functions/.env
# กรอก GEMINI_API_KEY ใน supabase/functions/.env
npx supabase functions serve parse-roster-ai --env-file supabase/functions/.env
```

### 4. รันแอป Flutter Web
```bash
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define-from-file=.env
```

---

## การตรวจสอบคุณภาพและทดสอบ (Quality Gates)

```bash
# 1. ตรวจวิเคราะห์โค้ดแบบ Static Analysis (ต้อง 0 issues)
flutter analyze

# 2. รัน Automated Test Suite ทั้งหมด (Unit, Widget, 6-Viewport Responsive, Alignment, Architecture & Security Audit)
flutter test

# 3. คอมไพล์ Production Release Bundle
flutter build web --release \
  --dart-define=SUPABASE_URL="https://<your-project-ref>.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="<your-supabase-anon-key>"
```

---

## เอกสารสำคัญในโปรเจกต์

- **[docs/DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md)** — คู่มือสร้างโปรเจกต์บน Vercel ตั้งแต่ศูนย์, ตั้งค่า Supabase Cloud, GitHub Secrets, Google OAuth และ Post-Deploy Smoke Test
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — สถาปัตยกรรมระบบ โครงสร้างโฟลเดอร์ และกฎโดเมนหลัก
- **[docs/AI_RULES.md](docs/AI_RULES.md)** — มาตรฐานการเขียนโค้ด ความปลอดภัย และ UI Guardrails
- **[docs/USE_CASE_TEST_LOG.md](docs/USE_CASE_TEST_LOG.md)** — บันทึกปัญหาจากใช้งานจริงและรายการ Regression Test (`UC-001` – `UC-039`)
