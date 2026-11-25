import { encodeBase64 } from 'jsr:@std/encoding/base64';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const MAX_FILE_SIZE_BYTES = 512000;
const DEFAULT_GEMINI_MODELS = [
  'gemini-3-flash-preview',
  'gemini-3.1-flash-lite-preview',
  'gemini-flash-lite-latest',
  'gemini-3.8-flash',
  'gemini-flash-latest',
] as const;
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

interface GeminiAttemptResult {
  ok: boolean;
  status: number;
  bodyText: string;
  model: string;
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

function errorResponse(
  errorCode: string,
  message: string,
  status: number,
): Response {
  return jsonResponse(
    {
      error_code: errorCode,
      message,
      error: message,
    },
    status,
  );
}

function buildModelFallbackChain(configuredModel?: string): string[] {
  const trimmed = configuredModel?.trim();
  return Array.from(
    new Set<string>([
      ...(trimmed ? [trimmed] : []),
      ...DEFAULT_GEMINI_MODELS,
    ]),
  );
}

function isModelNotFoundFailure(attempt: GeminiAttemptResult): boolean {
  const lower = attempt.bodyText.toLowerCase();
  return (
    attempt.status === 404 ||
    lower.includes('not_found') ||
    lower.includes('is not found for api version') ||
    lower.includes('not supported for generatecontent')
  );
}

function isQuotaOrAuthFailure(attempt: GeminiAttemptResult): boolean {
  const lower = attempt.bodyText.toLowerCase();
  return (
    attempt.status === 429 ||
    attempt.status === 401 ||
    attempt.status === 403 ||
    lower.includes('resource_exhausted') ||
    lower.includes('api_key_invalid') ||
    lower.includes('api key not valid') ||
    lower.includes('permission_denied')
  );
}

function sanitizeStudents(raw: unknown): ParsedStudent[] {
  if (!Array.isArray(raw)) {
    return [];
  }
  const results: ParsedStudent[] = [];
  for (const entry of raw) {
    if (!entry || typeof entry !== 'object') continue;
    const item = entry as Record<string, unknown>;
    const rawNum = item.student_number ?? item.studentNumber ?? item.no;
    let studentNumber: number | null = null;
    if (typeof rawNum === 'number' && Number.isFinite(rawNum) && rawNum > 0) {
      studentNumber = Math.trunc(rawNum);
    } else if (typeof rawNum === 'string') {
      const parsed = Number.parseInt(rawNum.trim(), 10);
      if (Number.isFinite(parsed) && parsed > 0) {
        studentNumber = parsed;
      }
    }

    const studentCode = String(
      item.student_code ?? item.studentCode ?? item.code ?? '',
    ).trim();
    const prefix = String(item.prefix ?? '').trim();
    const firstName = String(
      item.first_name ?? item.firstName ?? '',
    ).trim();
    const lastName = String(item.last_name ?? item.lastName ?? '').trim();
    const rawFullName = String(
      item.raw_full_name ?? item.rawFullName ?? item.full_name ?? '',
    ).trim();

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

function extractStudentsFromJsonText(rawText: string): ParsedStudent[] | null {
  let cleaned = rawText
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();

  if (!cleaned) {
    return [];
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    // Fallback: extract first JSON object or array block if surrounded by prose.
    const firstBrace = cleaned.indexOf('{');
    const lastBrace = cleaned.lastIndexOf('}');
    const firstBracket = cleaned.indexOf('[');
    const lastBracket = cleaned.lastIndexOf(']');

    if (firstBrace !== -1 && lastBrace > firstBrace) {
      cleaned = cleaned.slice(firstBrace, lastBrace + 1);
    } else if (firstBracket !== -1 && lastBracket > firstBracket) {
      cleaned = cleaned.slice(firstBracket, lastBracket + 1);
    }

    try {
      parsed = JSON.parse(cleaned);
    } catch {
      return null;
    }
  }

  if (Array.isArray(parsed)) {
    return sanitizeStudents(parsed);
  }
  if (parsed && typeof parsed === 'object') {
    const obj = parsed as Record<string, unknown>;
    if (Array.isArray(obj.students)) {
      return sanitizeStudents(obj.students);
    }
  }
  return null;
}

async function callGemini({
  apiKey,
  model,
  prompt,
  mimeType,
  base64Data,
}: {
  apiKey: string;
  model: string;
  prompt: string;
  mimeType: string;
  base64Data: string;
}): Promise<GeminiAttemptResult> {
  const endpoint =
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [
            { text: prompt },
            {
              inline_data: {
                mime_type: mimeType,
                data: base64Data,
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

  const bodyText = await response.text();
  return {
    ok: response.ok,
    status: response.status,
    bodyText,
    model,
  };
}

function classifyGeminiFailure(
  attempt: GeminiAttemptResult,
  triedModels: string[],
): Response {
  const lower = attempt.bodyText.toLowerCase();

  if (attempt.status === 429 || lower.includes('resource_exhausted')) {
    return errorResponse(
      'GEMINI_QUOTA_EXCEEDED',
      'โควตา Gemini API ชั่วคราวเต็ม กรุณารอสักครู่แล้วลองใหม่อีกครั้ง',
      429,
    );
  }

  if (
    attempt.status === 401 ||
    attempt.status === 403 ||
    lower.includes('api_key_invalid') ||
    lower.includes('api key not valid') ||
    lower.includes('permission_denied')
  ) {
    return errorResponse(
      'GEMINI_API_ERROR',
      'คีย์ GEMINI_API_KEY บนเซิร์ฟเวอร์ไม่ถูกต้องหรือไม่มีสิทธิ์เรียกใช้ Gemini API กรุณาตรวจสอบค่า Secret บน Supabase',
      502,
    );
  }

  if (isModelNotFoundFailure(attempt)) {
    return errorResponse(
      'GEMINI_MODEL_NOT_FOUND',
      `ไม่พบโมเดล AI ที่รองรับในบัญชี Gemini (ลองแล้ว: ${triedModels.join(', ')}) กรุณาตรวจสอบค่า GEMINI_MODEL บนเซิร์ฟเวอร์`,
      502,
    );
  }

  if (
    lower.includes('password') ||
    lower.includes('encrypted') ||
    lower.includes('corrupt')
  ) {
    return errorResponse(
      'INVALID_FILE',
      'ไฟล์ PDF นี้มีการเข้ารหัสหรือเสียหาย AI ไม่สามารถเปิดอ่านได้ กรุณาบันทึกไฟล์ใหม่หรือส่งเป็นรูปภาพแทน',
      400,
    );
  }

  if (attempt.status === 503 || lower.includes('unavailable')) {
    return errorResponse(
      'GEMINI_API_ERROR',
      'ขณะนี้บริการ Gemini AI มีผู้ใช้งานหนาแน่นชั่วคราว (HTTP 503) กรุณารอสักครู่แล้วกด "ลองใหม่"',
      502,
    );
  }

  return errorResponse(
    'GEMINI_API_ERROR',
    `บริการ Gemini AI ตอบกลับข้อผิดพลาด (HTTP ${attempt.status} · ${attempt.model}) กรุณาตรวจสอบความคมชัดของไฟล์หรือดู Supabase Edge Function Logs`,
    502,
  );
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return errorResponse(
      'METHOD_NOT_ALLOWED',
      'รองรับเฉพาะคำขอแบบ POST เท่านั้น',
      405,
    );
  }

  const authHeader = req.headers.get('Authorization');
  const bearerToken = authHeader?.replace(/^Bearer\s+/i, '').trim() ?? '';
  if (!authHeader || !bearerToken) {
    return errorResponse('UNAUTHORIZED', 'กรุณาเข้าสู่ระบบก่อนใช้งาน', 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!supabaseUrl || !supabaseAnonKey) {
    console.error('[parse-roster-ai] Missing SUPABASE_URL or SUPABASE_ANON_KEY');
    return errorResponse(
      'SERVER_CONFIG_ERROR',
      'ระบบตั้งค่าเซิร์ฟเวอร์ไม่สมบูรณ์',
      500,
    );
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  // 1. Verify authenticated teacher JWT
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(bearerToken);
  if (authError || !user) {
    console.error('[parse-roster-ai] Auth verification failed:', authError?.message);
    return errorResponse(
      'UNAUTHORIZED',
      'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง',
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
    console.error('[parse-roster-ai] Feature flag denied:', {
      userId: user.id,
      flagError: flagError?.message,
      canUseAi: featureFlag?.can_use_ai,
    });
    return errorResponse(
      'AI_FEATURE_DISABLED',
      'บัญชีของคุณยังไม่ได้เปิดใช้งานฟีเจอร์ AI อ่านรายชื่อ',
      403,
    );
  }

  // 3. Parse and validate request payload
  let body: Record<string, unknown>;
  try {
    body = (await req.json()) as Record<string, unknown>;
  } catch {
    return errorResponse('INVALID_REQUEST', 'รูปแบบข้อมูลคำขอไม่ถูกต้อง', 400);
  }

  const storagePath = String(body.storage_path ?? '').trim();
  const mimeType = String(body.mime_type ?? '').trim();

  if (
    !storagePath ||
    storagePath.includes('..') ||
    !storagePath.startsWith(`${user.id}/`)
  ) {
    return errorResponse('INVALID_FILE', 'เส้นทางไฟล์ต้นฉบับไม่ถูกต้อง', 400);
  }

  if (!ALLOWED_MIME_TYPES.has(mimeType)) {
    return errorResponse(
      'INVALID_FILE',
      'รองรับเฉพาะไฟล์รูปภาพ JPG, PNG และเอกสาร PDF เท่านั้น',
      400,
    );
  }

  // 4. Download original file from private bucket `import-sources` under user RLS
  const { data: fileBlob, error: downloadError } = await supabase.storage
    .from('import-sources')
    .download(storagePath);

  if (downloadError || !fileBlob) {
    console.error('[parse-roster-ai] Storage download failed:', {
      storagePath,
      error: downloadError?.message,
    });
    return errorResponse(
      'STORAGE_DOWNLOAD_FAILED',
      'ไม่พบไฟล์ต้นฉบับในพื้นที่จัดเก็บ กรุณาอัปโหลดใหม่อีกครั้ง',
      404,
    );
  }

  const fileBytes = new Uint8Array(await fileBlob.arrayBuffer());
  if (fileBytes.byteLength === 0) {
    return errorResponse(
      'INVALID_FILE',
      'ไฟล์ที่อัปโหลดว่างเปล่า กรุณาเลือกไฟล์ใหม่',
      400,
    );
  }
  if (fileBytes.byteLength > MAX_FILE_SIZE_BYTES) {
    return errorResponse(
      'FILE_TOO_LARGE',
      'ขนาดไฟล์เกิน 500 KB ไม่สามารถส่งประมวลผลได้',
      400,
    );
  }

  // 5. Invoke Gemini REST API with Auto-Fallback Chain (server-side key only)
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY')?.trim();
  if (!geminiApiKey) {
    console.error('[parse-roster-ai] GEMINI_API_KEY secret is not configured');
    return errorResponse(
      'MISSING_GEMINI_API_KEY',
      'ยังไม่ได้ตั้งค่า GEMINI_API_KEY บนเซิร์ฟเวอร์ Supabase Edge Functions กรุณาตั้งค่า Secret ก่อนใช้งาน',
      500,
    );
  }

  const configuredModel = Deno.env.get('GEMINI_MODEL')?.trim();
  const modelChain = buildModelFallbackChain(configuredModel);
  const base64Data = encodeBase64(fileBytes);

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

  let finalAttempt: GeminiAttemptResult | null = null;
  const triedModels: string[] = [];

  for (let i = 0; i < modelChain.length; i++) {
    const model = modelChain[i];
    triedModels.push(model);

    let attempt: GeminiAttemptResult;
    try {
      attempt = await callGemini({
        apiKey: geminiApiKey,
        model,
        prompt: extractionPrompt,
        mimeType,
        base64Data,
      });
    } catch (networkErr) {
      console.error(
        `[parse-roster-ai] Gemini fetch threw error on model "${model}":`,
        networkErr,
      );
      return errorResponse(
        'GEMINI_API_ERROR',
        'ไม่สามารถเชื่อมต่อบริการ Gemini AI ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
        502,
      );
    }

    finalAttempt = attempt;
    if (attempt.ok) {
      break;
    }

    if (isQuotaOrAuthFailure(attempt)) {
      console.error('[parse-roster-ai] Gemini quota/auth error:', {
        model: attempt.model,
        status: attempt.status,
        detail: attempt.bodyText.slice(0, 500),
      });
      return classifyGeminiFailure(attempt, triedModels);
    }

    const hasNextModel = i < modelChain.length - 1;
    if (hasNextModel && (isModelNotFoundFailure(attempt) || attempt.status === 503)) {
      console.warn(
        `[parse-roster-ai] Model "${model}" unavailable (HTTP ${attempt.status}); falling back to "${modelChain[i + 1]}". Detail:`,
        attempt.bodyText.slice(0, 300),
      );
      continue;
    }

    break;
  }

  if (!finalAttempt || !finalAttempt.ok) {
    console.error('[parse-roster-ai] Gemini API error after trying models:', {
      triedModels,
      status: finalAttempt?.status,
      mimeType,
      bytes: fileBytes.byteLength,
      detail: finalAttempt?.bodyText.slice(0, 1000),
    });
    return finalAttempt
      ? classifyGeminiFailure(finalAttempt, triedModels)
      : errorResponse(
          'GEMINI_API_ERROR',
          'บริการ Gemini AI ไม่สามารถประมวลผลได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
          502,
        );
  }

  try {
    const payload = JSON.parse(finalAttempt.bodyText) as {
      candidates?: Array<{
        finishReason?: string;
        content?: { parts?: Array<{ text?: string }> };
      }>;
      promptFeedback?: { blockReason?: string };
    };

    const blockReason = payload.promptFeedback?.blockReason;
    if (blockReason) {
      console.error('[parse-roster-ai] Gemini blocked request:', blockReason);
      return errorResponse(
        'INVALID_AI_RESPONSE',
        'AI ไม่สามารถประมวลผลไฟล์นี้ได้ตามนโยบายความปลอดภัย กรุณาลองครอปเฉพาะตารางรายชื่อแล้วส่งใหม่',
        502,
      );
    }

    const rawText =
      payload.candidates?.[0]?.content?.parts
        ?.map((p) => p.text ?? '')
        .join('')
        .trim() ?? '';

    const students = extractStudentsFromJsonText(rawText);
    if (students === null) {
      console.error(
        '[parse-roster-ai] Could not parse JSON from Gemini response. Raw text preview:',
        rawText.slice(0, 500),
      );
      return errorResponse(
        'INVALID_AI_RESPONSE',
        'ไม่สามารถอ่านโครงสร้างรายชื่อจากผลลัพธ์ของ AI ได้ กรุณาตรวจสอบความคมชัดของเอกสารแล้วลองใหม่',
        502,
      );
    }

    console.info(
      `[parse-roster-ai] Extracted ${students.length} student(s) using model "${finalAttempt.model}"`,
    );
    return jsonResponse({ students, model_used: finalAttempt.model }, 200);
  } catch (parseErr) {
    console.error('[parse-roster-ai] Unexpected response parse error:', parseErr);
    return errorResponse(
      'INVALID_AI_RESPONSE',
      'ไม่สามารถแปลงผลลัพธ์จาก AI ได้ กรุณาถ่ายภาพให้ชัดขึ้นแล้วลองใหม่',
      502,
    );
  }
});
