# คู่มือการ Deploy ขึ้น Production — Checklist-Student (Vercel + GitHub Actions + Supabase Cloud)

คู่มือฉบับจับมือทำตั้งแต่ศูนย์สำหรับ **ผู้ที่ยังไม่เคยสร้างโปรเจกต์ `Checklist-Student` บน Vercel มาก่อน** ครอบคลุมตั้งแต่การเตรียม Supabase Cloud, การสร้างโปรเจกต์บน Vercel, การตั้งค่า GitHub Secrets, การตั้งค่า Google OAuth จนถึงการทดสอบหลังเว็บออนไลน์จริง

> **สถาปัตยกรรมการ Deploy ที่ใช้ในโปรเจกต์นี้:**
> เครื่อง Build Container ของ Vercel ไม่มี Flutter SDK ติดตั้งไว้ล่วงหน้า โปรเจกต์นี้จึงออกแบบให้ **GitHub Actions (`.github/workflows/ci.yml`)** เป็นผู้รัน `flutter analyze` → `flutter test` → `flutter build web --release` (พร้อม `--dart-define`) แล้วส่งไฟล์ Prebuilt (`build/web`) ขึ้น **Vercel Edge CDN** โดยตรงผ่าน Vercel CLI (`vercel deploy --prebuilt`) ซึ่งเสถียร รวดเร็ว และรองรับ `vercel.json` (`rewrites`, `application/wasm`, `no-cache`, Security Headers) ครบ 100%

---

## หมวด 1: เตรียม Supabase Cloud Production

### 1.1 สร้างโปรเจกต์บน Supabase Cloud (หากยังไม่มี)
1. เข้า [https://supabase.com/dashboard](https://supabase.com/dashboard) → กด **New project**
2. เลือก Organization, ตั้งชื่อโปรเจกต์ (เช่น `checklist-student-prod`), ตั้ง Database Password (จดเก็บไว้ในที่ปลอดภัย) และเลือก Region **Southeast Asia (Singapore)** เพื่อความเร็วสูงสุดในประเทศไทย
3. รอระบบสร้างฐานข้อมูลจนเสร็จสมบูรณ์

### 1.2 Push SQL Migrations ทั้งหมดขึ้น Supabase Cloud (8 ไฟล์)
เปิด Terminal ในโฟลเดอร์โปรเจกต์ แล้วรันตามลำดับ:

```bash
# 1. ล็อกอิน Supabase CLI (จะเปิดหน้าเบราว์เซอร์ให้ยืนยัน)
npx supabase login

# 2. เชื่อมโปรเจกต์นี้เข้ากับ Supabase Cloud (ดู <project-ref> จาก URL หรือ Project Settings -> General)
npx supabase link --project-ref <your-supabase-project-ref>

# 3. ส่ง Migration ทั้ง 8 ไฟล์ขึ้น Production Database
npx supabase db push
```

<details>
<summary>รายชื่อ SQL Migrations ทั้ง 8 ไฟล์ที่จะถูก Apply ตามลำดับ (และวิธีสำรองผ่าน SQL Editor)</summary>

1. `supabase/migrations/20261123000001_initial_schema.sql`
2. `supabase/migrations/20261123000002_triggers_rls_storage.sql`
3. `supabase/migrations/20261124000003_grant_authenticated_privileges.sql`
4. `supabase/migrations/20261124000004_teacher_structure_rpcs.sql`
5. `supabase/migrations/20261125000001_grading_rpcs.sql`
6. `supabase/migrations/20261125000002_student_portal_rpcs.sql`
7. `supabase/migrations/20261125000003_revoke_anon_non_portal_rpc_execute.sql`
8. `supabase/migrations/20261125000004_make_term_dates_optional.sql`

> **วิธีสำรอง (หากไม่สะดวกใช้ CLI):** เปิด **Supabase Dashboard → SQL Editor → New query** แล้วคัดลอกเนื้อหาแต่ละไฟล์มารันทีละไฟล์เรียงตามหมายเลข 1 → 8
</details>

### 1.3 Deploy Edge Function (`parse-roster-ai`) และตั้งค่า Secrets (สำหรับ AI นำเข้ารายชื่อ)
โปรเจกต์มี Edge Function 1 ตัวคือ `supabase/functions/parse-roster-ai` (ทำงานเฉพาะครูที่มี `teacher_feature_flags.can_use_ai = true`):

```bash
# ตั้งค่า Secret ฝั่ง Supabase Cloud (ห้ามนำคีย์นี้ไปใส่ใน Flutter Web หรือ Vercel!)
npx supabase secrets set GEMINI_API_KEY="<your-google-ai-studio-gemini-api-key>"
npx supabase secrets set GEMINI_MODEL="gemini-3-flash-preview"

# Deploy Edge Function โดยปิด verify_jwt ที่ Gateway (ฟังก์ชันตรวจ JWT ผ่าน supabase.auth.getUser ภายในเอง)
npx supabase functions deploy parse-roster-ai --no-verify-jwt
```

> **หมายเหตุ:** หากยังไม่ต้องการเปิดใช้ฟีเจอร์นำเข้าด้วย AI ในทันที สามารถข้ามคำสั่งตั้งค่า `GEMINI_API_KEY` ได้ แอปจะยังใช้งาน Excel/CSV และฟีเจอร์อื่นๆ ได้ครบ 100%

### 1.4 ตรวจสอบ `pg_cron` Job ล้าง Audit Log รายปี
เปิด **Supabase Dashboard → SQL Editor** แล้วรันตรวจสอบ:
```sql
SELECT jobid, jobname, schedule, active FROM cron.job;
```
ควรพบงานล้าง `score_audit_logs` ที่เก่าเกิน 1 ปี (สร้างอัตโนมัติจาก Migration) หากต้องการเปิด Extension `pg_cron` ก่อน ให้ไปที่ **Database → Extensions → ค้นหา `pg_cron` → Enable**

### 1.5 คัดลอกค่า `SUPABASE_URL` และ `SUPABASE_ANON_KEY`
1. ไปที่ **Supabase Dashboard → Project Settings → API** (หรือ **Data API / API Keys**)
2. คัดลอกเก็บไว้ 2 ค่า:
   - **Project URL** → ใช้เป็น `SUPABASE_URL` (เช่น `https://abcdefghijkl.supabase.co`)
   - **`anon` `public` key** → ใช้เป็น `SUPABASE_ANON_KEY`
3. ⚠️ **ห้ามคัดลอก `service_role` key ไปใช้ในฝั่ง Flutter Web, GitHub Actions Build หรือ Vercel เด็ดขาด**

---

## หมวด 2: สร้างโปรเจกต์ใหม่บน Vercel ตั้งแต่ศูนย์ (First-Time Setup)

เนื่องจากผู้ใช้ยังไม่เคยสร้างโปรเจกต์ `Checklist-Student` บน Vercel มาก่อน แนะนำให้ใช้ **วิธี A (CLI Link — เร็วและสะอาดที่สุด ไม่ชน Auto-Build)** หรือ **วิธี B (ผ่านหน้าเว็บ Vercel Dashboard)** อย่างใดอย่างหนึ่ง

### วิธี A (แนะนำ): สร้างและเชื่อมโปรเจกต์ด้วย `npx vercel link`
วิธีนี้จะสร้างโปรเจกต์เปล่าบน Vercel โดย **ไม่ผูก Git Auto-Build ให้ซ้ำซ้อนกับ GitHub Actions** และสร้างไฟล์ `.vercel/project.json` ที่มี `orgId` กับ `projectId` ให้ทันที:

```bash
# 1. ล็อกอินบัญชี Vercel (จะเปิดเบราว์เซอร์ให้ยืนยัน)
npx vercel login

# 2. รันในโฟลเดอร์ root ของโปรเจกต์ Checklist-Student
npx vercel link
```
ตอบคำถามใน Terminal ตามลำดับ:
- `Set up "D:\Project\Checklist-Student"?` → ตอบ **`Y`**
- `Which scope should contain your project?` → เลือกบัญชี/Team ของคุณ
- `Found project ...?` / `Link to existing project?` → ตอบ **`N`** (สร้างโปรเจกต์ใหม่)
- `What's your project's name?` → พิมพ์ **`checklist-student`** (หรือชื่อที่ต้องการ จะได้โดเมน `https://<ชื่อโปรเจกต์>.vercel.app`)
- `In which directory is your code located?` → กด **Enter** (`./`)
- หากถามเรื่อง Override settings → ตอบ **`N`**

หลังจบคำสั่ง ให้เปิดดูไฟล์ `.vercel/project.json` (ไฟล์นี้อยู่ใน `.gitignore` แล้ว จะไม่ถูก commit ขึ้น Git):
```json
{
  "projectId": "prj_xxxxxxxxxxxxxxxxxxxx",
  "orgId": "team_xxxxxxxxxxxxxxxxxxxx"
}
```
จดค่า 2 ตัวนี้ไว้สำหรับใส่ใน GitHub Secrets:
- `orgId` → ใช้เป็น **`VERCEL_ORG_ID`**
- `projectId` → ใช้เป็น **`VERCEL_PROJECT_ID`**

### วิธี B (ทางเลือก): สร้างผ่านหน้าเว็บ Vercel Dashboard
1. เข้า [https://vercel.com/new](https://vercel.com/new) → ล็อกอินด้วย GitHub
2. เลือก Import Repository `Checklist-Student` → ตั้งชื่อโปรเจกต์ → ยังไม่ต้องคาดหวังให้ Build รอบแรกผ่าน
3. ⚠️ **ขั้นตอนสำคัญมาก (ห้ามข้ามเด็ดขาดเมื่อใช้วิธี B):**
   - เข้าหน้าโปรเจกต์บน Vercel → **Settings → Git → Ignored Build Step**
   - เลือก **Custom** แล้วใส่คำสั่ง:
     ```bash
     exit 0
     ```
   - กด **Save**
   - *เหตุผล:* เพื่อให้ Vercel ข้าม Auto-Build จาก Git integration (ซึ่งไม่มี Flutter SDK) และปล่อยให้ **GitHub Actions** เป็นผู้ Build & Deploy Prebuilt ขึ้นแทนทุกครั้งโดยไม่ขึ้นกากบาทแดงซ้ำซ้อน
4. ไปที่ **Settings → General** เพื่อคัดลอก **Project ID** (`VERCEL_PROJECT_ID`) และไปที่ **Account/Team Settings → General** เพื่อคัดลอก **Team ID / Your ID** (`VERCEL_ORG_ID`)

### 2.1 สร้าง `VERCEL_TOKEN` สำหรับ GitHub Actions
1. เข้า [https://vercel.com/account/tokens](https://vercel.com/account/tokens)
2. กด **Create Token**:
   - **Token Name:** `checklist-student-github-actions`
   - **Scope:** เลือกบัญชี/Team ที่มีโปรเจกต์ `checklist-student`
   - **Expiration:** เลือก `No Expiration` หรือ `1 year` (แล้วจดเตือนต่ออายุ)
3. กด **Create** แล้ว **คัดลอก Token ทันที** (แสดงครั้งเดียว) → ใช้เป็น **`VERCEL_TOKEN`**

### 2.2 การตั้งค่า Custom Domain (Optional)
หากมีโดเมนโรงเรียนหรือโดเมนส่วนตัว (เช่น `checklist.myschool.ac.th`):
1. ไปที่โปรเจกต์บน Vercel → **Settings → Domains** → กด **Add** พิมพ์โดเมนที่ต้องการ
2. เพิ่ม DNS Record (`CNAME` ชี้ไปที่ `cname.vercel-dns.com` หรือ `A` Record ตามที่ Vercel แนะนำ)
3. เมื่อสถานะขึ้น **Valid Configuration (HTTPS Active)** ให้นำโดเมนนี้ไปเพิ่มใน **หมวด 4 (Supabase Auth & Google OAuth)** ด้วย

---

## หมวด 3: ตั้งค่า GitHub Repository Secrets (สำหรับ CI/CD)

ไปที่ GitHub Repository ของคุณ → **Settings → Secrets and variables → Actions → แท็บ Secrets → กด New repository secret** แล้วเพิ่มให้ครบทั้ง **5 ตัว** (สะกดชื่อให้ตรงเป๊ะ 100% ตาม `.github/workflows/ci.yml`):

| ชื่อ GitHub Secret | แหล่งที่มาของค่า | ใช้ในขั้นตอนใด |
|---|---|---|
| `SUPABASE_URL` | Supabase Dashboard → Project Settings → API → **Project URL** | ส่งเข้า `--dart-define=SUPABASE_URL` ตอน Build Web |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Project Settings → API → **`anon` `public` key** | ส่งเข้า `--dart-define=SUPABASE_ANON_KEY` ตอน Build Web |
| `VERCEL_TOKEN` | Vercel Account Settings → Tokens (จากข้อ 2.1) | ยืนยันสิทธิ์ Vercel CLI ใน GitHub Actions |
| `VERCEL_ORG_ID` | ค่า `orgId` ใน `.vercel/project.json` (หรือ Account/Team ID บน Vercel) | ระบุ Scope/Team ของโปรเจกต์บน Vercel |
| `VERCEL_PROJECT_ID` | ค่า `projectId` ใน `.vercel/project.json` (หรือ Project Settings → General) | ระบุโปรเจกต์ปลายทางบน Vercel |

> **ตรวจสอบความปลอดภัย:** ไม่ต้องใส่ `SUPABASE_SERVICE_ROLE_KEY` หรือ `GEMINI_API_KEY` ใน GitHub Secrets ของฝั่งเว็บ เพราะ Flutter Web Client ไม่เคยใช้คีย์ทั้งสองนี้

---

## หมวด 4: ตั้งค่า Supabase Auth & Google Cloud OAuth สำหรับ Production URL

> โปรเจกต์นี้ตั้งค่า `redirectTo` ฝั่งเว็บเป็น `${Uri.base.origin}/teacher/dashboard` (ดูใน `lib/features/auth/data/datasources/auth_remote_datasource.dart`) ดังนั้นต้องเพิ่ม URL ของ Vercel ให้ครบทั้งใน Supabase และ Google Cloud

### 4.1 ตั้งค่าใน Supabase Dashboard
ไปที่ **Supabase Dashboard → Authentication → URL Configuration**:
1. **Site URL:** ตั้งเป็น Production URL ของคุณ (ไม่มี `/` ปิดท้าย):
   ```text
   https://<your-project>.vercel.app
   ```
   *(หรือ Custom Domain เช่น `https://checklist.myschool.ac.th`)*
2. **Redirect URLs:** กด **Add URL** เพิ่มรายการต่อไปนี้ให้ครบ:
   ```text
   https://<your-project>.vercel.app/**
   https://<your-project>.vercel.app/teacher/dashboard
   https://*-<your-vercel-scope>.vercel.app/**
   http://localhost:8080/**
   http://127.0.0.1:8080/**
   ```
3. กด **Save**
4. ตรวจที่ **Authentication → Providers → Google**:
   - เปิด **Enable Sign in with Google** เป็น `ON`
   - ใส่ **Client ID** และ **Client Secret** จาก Google Cloud Console แล้วกด **Save**

### 4.2 ตั้งค่าใน Google Cloud Console
ไปที่ [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials) → เลือก **OAuth 2.0 Client ID** ประเภท Web application ของโปรเจกต์:
1. **Authorized JavaScript origins:** ตรวจสอบ/เพิ่มให้ครบ:
   ```text
   https://<your-project>.vercel.app
   https://<your-supabase-project-ref>.supabase.co
   http://localhost:8080
   ```
2. **Authorized redirect URIs:** ต้องมี Callback URL ของ Supabase Cloud (ห้ามพิมพ์ผิด):
   ```text
   https://<your-supabase-project-ref>.supabase.co/auth/v1/callback
   ```
3. กด **Save** (อาจใช้เวลา propagate 1–5 นาที)
4. ตรวจที่ **OAuth consent screen**: หาก Publishing status ยังเป็น `Testing` ให้กด **Publish App** (หรือเพิ่มอีเมลครูที่ใช้งานใน Test users)

---

## หมวด 5: ขั้นตอน Deploy ขึ้น Production (`dev → main`)

### 5.1 ตรวจสอบความสะอาดและ Commit โค้ดบน Branch `dev`
```bash
# ตรวจไฟล์ที่เปลี่ยนแปลง (ห้ามมี .env หรือ .vercel/ ติดมา)
git status

# เพิ่มไฟล์ทั้งหมดและ Commit บน dev
git add .
git commit -m "chore(release): prepare Step 8.2 CI/CD, Vercel config, and deployment docs"

# Push ขึ้น branch dev เพื่อรัน CI + Deploy Vercel Preview
git push origin dev
```

### 5.2 ตรวจสอบ Preview Deployment บน GitHub Actions
1. เปิด GitHub Repository → แท็บ **Actions** → ดู Workflow **Flutter Web CI & Vercel Deploy**
2. รอให้ทั้ง 2 Job ขึ้นเครื่องหมายถูกสีเขียว:
   - `Analyze, Test & Verify Web Build`
   - `Build & Deploy to Vercel` (จะแสดงลิงก์ **Preview URL** ในหน้า Summary)
3. ทดลองเปิด Preview URL เช็กความเรียบร้อยเบื้องต้น

### 5.3 Merge `dev → main` เพื่อขึ้น Production จริง
**วิธีที่ 1 (แนะนำ — ผ่าน Pull Request บน GitHub):**
1. เปิด GitHub → แท็บ **Pull requests** → กด **New pull request**
2. เลือก `base: main` ← `compare: dev` → กด **Create pull request**
3. รอ CI Check `Analyze, Test & Verify Web Build` ผ่านสีเขียว → กด **Merge pull request**
4. GitHub Actions บน `main` จะเริ่มทำงานและ Deploy ขึ้น **Production URL** (`https://<your-project>.vercel.app`) อัตโนมัติ

**วิธีที่ 2 (ผ่าน Git CLI):**
```bash
git checkout main
git pull origin main
git merge dev
git push origin main
git checkout dev
```

> **หมายเหตุ:** หากต้องการสั่ง Re-deploy ใหม่หลังแก้ GitHub Secrets สามารถไปที่ **GitHub Actions → Flutter Web CI & Vercel Deploy → Run workflow** แล้วเลือก `preview` หรือ `production` ได้ทันที

---

## หมวด 6: Post-Deploy Production Smoke Test Checklist

เมื่อ Production URL ออนไลน์แล้ว ให้ทดสอบครบทั้ง **10 ข้อ** บนเว็บจริง:

- [ ] **1. Teacher Google OAuth Login:** เปิด `https://<your-project>.vercel.app/login` → กด **"เข้าสู่ระบบด้วย Google"** → ล็อกอินผ่านและเด้งเข้า `/teacher/dashboard` โดยไม่ติด Redirect Error
- [ ] **2. Drift WASM & Network Integrity:** เปิด Chrome DevTools (`F12`) → แท็บ **Console** และ **Network** → ยืนยันว่า `sqlite3.wasm` โหลดด้วย `200 OK` และ Response Header มี `Content-Type: application/wasm` รวมถึง `drift_worker.js` โหลดผ่านโดยไม่มี CORS/MIME Error
- [ ] **3. SPA Deep Link Refresh (`F5`):** เข้าหน้า `/teacher/academic-structure` และ `/teacher/settings` แล้วกดรีเฟรชหน้า (`F5`) → ต้องโหลดหน้าเดิมได้ปกติ ไม่ขึ้น `404 Not Found`
- [ ] **4. Core Classroom Flow:** ทดลองสร้าง **ปีการศึกษา → เทอม (แบบไม่ระบุวันเปิด–ปิด) → รายวิชา → ห้องเรียน**, นำเข้ารายชื่อนักเรียน และเช็คชื่อรายวัน 1 คาบแล้วกดบันทึก
- [ ] **5. Offline-First & Auto Sync:** เปิด DevTools → Network → เปลี่ยนเป็น **Offline** → ทดลองเช็คชื่อ/กรอกคะแนน (ข้อมูลต้องลงคิวออฟไลน์ได้ทันที) → สลับกลับเป็น **Online** → ยืนยันว่ารายการซิงค์ขึ้น Supabase อัตโนมัติและคิวกลับเป็น 0
- [ ] **6. Export ปพ.5 ทั้ง 3 รูปแบบ:** เข้าหน้าส่งออกรายงาน → ทดลองกด **ส่งออก PDF**, **Excel**, และ **Word** → เปิดไฟล์จริงยืนยันว่า **PDF ฟอนต์สารบรรณภาษาไทยอ่านได้ชัดไม่เป็นสี่เหลี่ยม**, ทศนิยมคะแนนตรงเป๊ะ และวันที่เป็น พ.ศ.
- [ ] **7. Student Portal & External Browser Link:** ไปที่หน้าตั้งค่า → กดปุ่ม **"คัดลอกลิงก์"** (ต้องได้ URL `/student/<teacherCode>?openExternalBrowser=1`) → นำไปเปิดในหน้าต่าง **Incognito** → ยืนยันว่าไม่เด้งไป `/login`, ค้นหานักเรียนและตั้ง PIN 6 หลักได้จริง
- [ ] **8. Server-Side Privacy Filter:** ปิดสวิตช์ **"แสดงคะแนนรวม / เกรดให้นักเรียนเห็น"** ที่หน้าแผนเก็บงาน → รีเฟรชหน้า Student Portal ใน Incognito พร้อมดู DevTools → Network (`get_student_portal_summary`) ยืนยันว่าค่า `score` / `displayed_grade` ถูกส่งกลับมาเป็น `null` จากฝั่งเซิร์ฟเวอร์จริง
- [ ] **9. Mobile PWA Install:** เปิด Production URL บนมือถือจริง (Chrome บน Android หรือ Safari บน iOS) → กด **Install App / Add to Home Screen** → เปิดจากไอคอนหน้าจอหลักแสดงแบบ Standalone เต็มจอ
- [ ] **10. Sign-Out Local Cache Wipe:** กดออกจากระบบฝั่งครู → ยืนยันว่าเด้งกลับหน้า `/login` และข้อมูลแคช Drift ใน IndexedDB ของครูคนเดิมถูกล้างออกเรียบร้อย
