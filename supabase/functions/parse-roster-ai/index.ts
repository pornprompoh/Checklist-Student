import { createClient } from 'jsr:@supabase/supabase-js@2';

const MAX_FILE_SIZE_BYTES = 512000;
const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'application/pdf',
]);

const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface ParsedStudent {
  student_number: number | null;
  student_code: string;
  prefix: string;
  first_name: string;
  last_name: string;
  raw_full_name: string;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      'Content-Type': 'application/json; charset=utf-8',
    },
  });
}

function bytesToBase64(bytes: Uint8Array): string {
  const chunkSize = 0x8000;
  const chunks: string[] = [];
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const slice = bytes.subarray(i, Math.min(i + chunkSize, bytes.length));
    chunks.push(String.fromCharCode(...slice));
  }
  return btoa(chunks.join(''));
}

function sanitizeStudents(raw: unknown): ParsedStudent[] {
  if (!Array.isArray(raw)) {
    return [];
  }
  const results: ParsedStudent[] = [];
  for (const entry of raw) {
    if (!entry || typeof entry !== 'object') continue;
    const item = entry as Record<string, unknown>;
    const rawNum = item.student_number;
    let studentNumber: number | null = null;
    if (typeof rawNum === 'number' && Number.isFinite(rawNum) && rawNum > 0) {
      studentNumber = Math.trunc(rawNum);
    } else if (typeof rawNum === 'string') {
      const parsed = Number.parseInt(rawNum.trim(), 10);
      if (Number.isFinite(parsed) && parsed > 0) {
        studentNumber = parsed;
      }
    }

    const studentCode = String(item.student_code ?? '').trim();
    const prefix = String(item.prefix ?? '').trim();
    const firstName = String(item.first_name ?? '').trim();
    const lastName = String(item.last_name ?? '').trim();
    const rawFullName = String(item.raw_full_name ?? '').trim();

    if (!studentCode && !firstName && !rawFullName) {
      continue;
    }

    results.push({
      student_number: studentNumber,
      student_code: studentCode,
      prefix,
      first_name: firstName,
      last_name: lastName,
      raw_full_name: rawFullName,
    });
  }
  return results;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'รองรับเฉพาะคำขอแบบ POST เท่านั้น' }, 405);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse({ error: 'กรุณาเข้าสู่ระบบก่อนใช้งาน' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!supabaseUrl || !supabaseAnonKey) {
    return jsonResponse({ error: 'ระบบตั้งค่าเซิร์ฟเวอร์ไม่สมบูรณ์' }, 500);
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  // 1. Verify authenticated teacher JWT
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();
  if (authError || !user) {
    return jsonResponse(
      { error: 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง' },
      401,
    );
  }

  // 2. Server-side feature flag check (`teacher_feature_flags.can_use_ai`)
  const { data: featureFlag, error: flagError } = await supabase
    .from('teacher_feature_flags')
    .select('can_use_ai')
    .eq('teacher_id', user.id)
    .maybeSingle();

  if (flagError || !featureFlag || featureFlag.can_use_ai !== true) {
    return jsonResponse(
      { error: 'บัญชีของคุณยังไม่ได้เปิดใช้งานฟีเจอร์ AI อ่านรายชื่อ' },
      403,
    );
  }

  // 3. Parse and validate request payload
  let body: Record<string, unknown>;
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch {
    return jsonResponse({ error: 'รูปแบบข้อมูลคำขอไม่ถูกต้อง' }, 400);
  }

  const storagePath = String(body.storage_path ?? '').trim();
  const mimeType = String(body.mime_type ?? '').trim();

  if (
    !storagePath ||
    storagePath.includes('..') ||
    !storagePath.startsWith(`${user.id}/`)
  ) {
    return jsonResponse({ error: 'เส้นทางไฟล์ต้นฉบับไม่ถูกต้อง' }, 400);
  }

  if (!ALLOWED_MIME_TYPES.has(mimeType)) {
    return jsonResponse(
      { error: 'รองรับเฉพาะไฟล์ JPG, PNG และ PDF เท่านั้น' },
      400,
    );
  }

  // 4. Download original file from private bucket `import-sources` under user RLS
  const { data: fileBlob, error: downloadError } = await supabase.storage
    .from('import-sources')
    .download(storagePath);

  if (downloadError || !fileBlob) {
    return jsonResponse(
      { error: 'ไม่พบไฟล์ต้นฉบับในพื้นที่จัดเก็บ กรุณาอัปโหลดใหม่อีกครั้ง' },
      404,
    );
  }

  const fileBytes = new Uint8Array(await fileBlob.arrayBuffer());
  if (fileBytes.byteLength === 0 || fileBytes.byteLength > MAX_FILE_SIZE_BYTES) {
    return jsonResponse(
      { error: 'ขนาดไฟล์เกิน 500 KB ไม่สามารถส่งประมวลผลได้' },
      400,
    );
  }

  // 5. Invoke Gemini API using server-side secret only
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY')?.trim();
  if (!geminiApiKey) {
    return jsonResponse(
      { error: 'ยังไม่ได้ตั้งค่าคีย์บริการ AI ฝั่งเซิร์ฟเวอร์ กรุณาติดต่อผู้ดูแลระบบ' },
      500,
    );
  }
  const geminiModel =
    Deno.env.get('GEMINI_MODEL')?.trim() || 'gemini-2.5-flash';

  const extractionPrompt = [
    'คุณคือผู้ช่วยอ่านรายชื่อนักเรียนไทยจากรูปภาพหรือเอกสาร PDF ของโรงเรียน (เช่น ใบรายชื่อ ปพ.5 หรือรายงาน SGS)',
    'จงดึงรายชื่อนักเรียนทั้งหมดที่ปรากฏในเอกสาร เรียงตามลำดับที่ปรากฏ และคืนค่าเป็น JSON เท่านั้นตามโครงสร้างนี้:',
    '{"students":[{"student_number":number|null,"student_code":"string","prefix":"string","first_name":"string","last_name":"string","raw_full_name":"string"}]}',
    'กติกา:',
    '1. student_number เป็นเลขที่ (จำนวนเต็ม > 0 หรือ null ถ้าไม่มี)',
    '2. student_code เป็นเลขประจำตัวนักเรียนเป็นข้อความ (ไม่มีช่องว่าง; ถ้าไม่มีให้ส่ง "")',
    '3. แยกคำนำหน้าไทย เช่น ด.ช., ด.ญ., เด็กชาย, เด็กหญิง, นาย, นางสาว, น.ส., นาง ไว้ใน prefix และใส่ชื่อจริงใน first_name นามสกุลใน last_name (คงนามสกุลหลายคำ เช่น ณ อยุธยา ไว้ครบ)',
    '4. ใส่ชื่อเต็มตามที่เห็นจริงในเอกสารไว้ใน raw_full_name เสมอ',
    '5. ห้ามแต่งเติมข้อมูลที่ไม่มีในเอกสาร หากไม่พบรายชื่อให้คืน {"students":[]}',
  ].join('\n');

  const geminiEndpoint =
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(geminiModel)}:generateContent?key=${encodeURIComponent(geminiApiKey)}`;

  let geminiResponse: Response;
  try {
    geminiResponse = await fetch(geminiEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [
              { text: extractionPrompt },
              {
                inline_data: {
                  mime_type: mimeType,
                  data: bytesToBase64(fileBytes),
                },
              },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0,
        },
      }),
    });
  } catch {
    return jsonResponse(
      { error: 'ไม่สามารถเชื่อมต่อบริการ AI ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง' },
      502,
    );
  }

  if (!geminiResponse.ok) {
    const status = geminiResponse.status === 429 ? 429 : 502;
    const message =
      status === 429
        ? 'โควตาการใช้งาน AI ชั่วคราวเต็ม กรุณารอสักครู่แล้วลองใหม่'
        : 'บริการ AI ประมวลผลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
    return jsonResponse({ error: message }, status);
  }

  try {
    const payload = (await geminiResponse.json()) as {
      candidates?: Array<{
        content?: { parts?: Array<{ text?: string }> };
      }>;
    };
    const rawText =
      payload.candidates?.[0]?.content?.parts
        ?.map((p) => p.text ?? '')
        .join('')
        .trim() ?? '';

    const cleanedJson = rawText
      .replace(/^```json\s*/i, '')
      .replace(/^```\s*/i, '')
      .replace(/\s*```$/i, '')
      .trim();

    const parsed = JSON.parse(cleanedJson || '{"students":[]}') as {
      students?: unknown;
    };
    const students = sanitizeStudents(parsed.students);

    return jsonResponse({ students }, 200);
  } catch {
    return jsonResponse(
      { error: 'ไม่สามารถแปลงผลลัพธ์จาก AI ได้ กรุณาถ่ายภาพให้ชัดขึ้นแล้วลองใหม่' },
      502,
    );
  }
});
