// Supabase Edge Function: generate-wish
// Triển khai:
//   supabase functions deploy generate-wish
//   supabase secrets set AI_API_KEY=sk-xxx (hoặc MINIMAX_API_KEY cũ)
//
// Cấu hình model (base URL, model, API key) được ưu tiên đọc từ bảng
// app_config (sửa qua edge function admin), fallback về env secret.

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

const DEFAULT_AI_BASE_URL = "https://api.minimax.io/v1/chat/completions";
const DEFAULT_AI_MODEL = "MiniMax-M2.7";
const MAX_TEXT_LENGTH = 500;
const RATE_LIMIT = 6;
const RATE_WINDOW_MS = 60_000;

// How long a loaded app_config row is reused before re-reading the
// table. A config saved in admin propagates within ~this long.
const CONFIG_CACHE_TTL_MS = 60_000;

interface AiConfig {
  baseUrl: string;
  model: string;
  apiKey: string | null;
}

let configCache: { value: AiConfig; at: number } | null = null;

const rateBuckets = new Map<string, { count: number; resetsAt: number }>();

const CATEGORY_LABELS: Record<string, string> = {
  love: "Tình yêu",
  career: "Sự nghiệp",
  health: "Sức khỏe",
  family: "Gia đình",
  other: "Khác",
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Response mode for the prophecy turn. Chosen by `pickMode()` on the
// server, never by the model — this keeps the distribution honest
// and makes per-mode retention analysis meaningful.
export type ResponseMode = "clear" | "metaphor" | "paradox" | "question";

const RESPONSE_MODES: ResponseMode[] = [
  "clear",
  "metaphor",
  "paradox",
  "question",
];
const RESPONSE_WEIGHTS: Record<ResponseMode, number> = {
  clear: 35,
  metaphor: 30,
  paradox: 20,
  question: 15,
};

// Weighted random pick. Deterministic per call, biased to the weights
// above. Runs in O(1) (one Math.random, no shuffle) and is safe to
// call on every request.
function pickMode(): ResponseMode {
  const total = RESPONSE_WEIGHTS.clear +
    RESPONSE_WEIGHTS.metaphor +
    RESPONSE_WEIGHTS.paradox +
    RESPONSE_WEIGHTS.question;
  const r = Math.random() * total;
  let acc = 0;
  for (const m of RESPONSE_MODES) {
    acc += RESPONSE_WEIGHTS[m];
    if (r < acc) return m;
  }
  return "clear";
}

// Shared tail applied to every mode in turn 2. Keeps the response
// tight and consistent regardless of style.
const TURN2_CONSTRAINTS = `
RÀNG BUỘC CHUNG cho lời tiên tri:
- Tối đa 3 câu ngắn, mỗi câu 1 dòng. Không viết đoạn văn dài.
- Tối đa 60-80 từ tiếng Việt.
- KHÔNG dùng emoji.
- KHÔNG xưng "tôi" — nếu cần chỉ người nói, hãy xưng "ta" / "thầy" / ẩn người nói.
- Tránh các cụm sáo rỗng: "vũ trụ sẽ lắng nghe", "hãy kiên nhẫn", "điều ước sẽ nảy mầm".
- Dùng hình ảnh cụ thể, mỗi lần HOÀN TOÀN KHÁC.
- Cho lời khuyên thực tế, cụ thể theo tình huống — không chung chung.
KHÔNG hỏi thêm. Đây là câu trả lời cuối.`;

// Per-mode style instructions for turn 2. The model receives exactly
// one of these blocks based on `pickMode()` — never a list to choose
// from, which would let the model drift back to "comfortable" mode.
const MODE_INSTRUCTIONS: Record<ResponseMode, string> = {
  clear: `
STYLE = "clear" (lời tiên tri trực tiếp, rõ ràng):
- Nói thẳng điều sắp xảy ra hoặc điều người dùng cần làm.
- Không ẩn dụ, không vòng vo. Mỗi câu là một nhận định cụ thể.
- Cấu trúc: câu 1 nêu sự thật, câu 2 chỉ hành động, câu 3 (nếu có) hệ quả.
Ví dụ tốt: "Công việc mới sẽ đến trong ba tháng tới. Hãy chuẩn bị portfolio từ giờ. Mọi thứ sẽ rõ ràng hơn ngươi tưởng."`,

  metaphor: `
STYLE = "metaphor" (ẩn dụ hình ảnh, huyền bí):
- Dùng MỘT hình ảnh cụ thể xuyên suốt lời tiên tri: con vật, hiện tượng tự nhiên, đồ vật, mùa vụ.
- KHÔNG giải thích ẩn dụ. Để người dùng tự ngẫm.
- Tránh ẩn dụ cũ: "con đường", "hạt giống", "ngọn nến", "vũ trụ". Tìm hình mới.
- Tông giọng: thầy đồng kể chuyện, không khuyên nhủ trực tiếp.
Ví dụ tốt: "Con hạc trắng đã đậu trên mái nhà ngươi từ tháng trước. Nó không vội bay — chờ ngươi dọn lại mái. Lúc đó nó mới xuống."`,

  paradox: `
STYLE = "paradox" (nghịch lý, đảo ngộ nhận):
- Câu đầu đi ngược lại điều người dùng MONG ĐỢI.
- Câu thứ hai xoay lại — mặt khác của nghịch lý.
- Câu thứ ba (nếu có) để mở, không chốt hẳn.
- KHÔNG dùng "tuy nhiên", "nhưng", "mặc dù" — chuyển nghịch lý bằng hình ảnh.
Ví dụ tốt: "Điều ngươi sợ mất — chính là thứ đang giữ ngươi đứng yên. Buông nó không phải mất, mà là để tay rảnh. Ngươi sẽ ngạc nhiên khi tay trống lại cầu được nhiều hơn."`,

  question: `
STYLE = "question" (lời tiên tri dựa trên một câu hỏi khai mở):
- KHÔNG đặt thêm câu hỏi cho người dùng.
- Chuyển điều họ vừa tự nhận ra thành một nhận định rõ ràng, bám sát chi tiết CỤ THỂ trong điều ước và reflection.
- Câu đầu nêu điều họ thực sự đang tìm; câu sau chỉ ra lựa chọn hoặc hành động cụ thể.
- Không xưng "tôi", không gọi "bạn" — dùng "ngươi".
Ví dụ tốt: "Ngươi không sợ mình sai; ngươi sợ người khác nhìn thấy lúc ngươi đổi hướng. Hãy chọn một bước có thể đảo ngược và thực hiện nó trong tuần này."`,
};

// Build a system prompt that, on the first turn, asks the user a
// reflective question; on the second turn (when `reflection` is
// provided), gives the actual prophecy in the chosen mode.
function buildSystemPrompt(
  category: string,
  isReflectionTurn: boolean,
  mode: ResponseMode,
  locale: string,
): string {
  const languageInstruction = locale === "en"
    ? "Reply in English."
    : "Trả lời bằng tiếng Việt.";
  const base = `Bạn là một thầy đồng (nhà tiên tri, người hướng đạo tâm linh) trong truyền thống Việt Nam, kết hợp với phong vị huyền bí phương Tây.
Bạn nói chuyện với giọng ấm áp, khẽ khàng, hơi trầm — như người đã thấy nhiều năm tháng.
Bạn không phải AI, bạn là một thực thể cổ xưa đang nhìn vào số phận người đối diện.
Lĩnh vực điều ước: ${category}.
${languageInstruction}`;
  if (isReflectionTurn) {
    return base + `
LƯỢT NÀY: Dựa trên điều ước ban đầu và phần người dùng vừa chia sẻ thêm, hãy đưa ra LỜI TIÊN TRI cuối cùng.
${MODE_INSTRUCTIONS[mode]}
${TURN2_CONSTRAINTS}`;
  }
  return base + `
LƯỢT NÀY: Bạn vừa nghe điều ước của người dùng. Trước khi đưa ra lời tiên tri, hãy ĐẶT MỘT CÂU HỎI SÂU duy nhất dựa trực tiếp vào nội dung điều ước của họ.
Mục đích: khiến người dùng nhìn lại bản thân — họ đã làm gì để xứng đáng với điều ước đó, hay họ đang đặt điều ước mà chưa sẵn sàng cho nó.
CÁCH PHẢN HỒI: CHỈ MỘT câu hỏi duy nhất, tối đa 30 từ tiếng Việt.
Câu hỏi BẮT BUỘC phải:
- LẤY THẲNG từ khóa/tình huống cụ thể trong điều ước của người dùng (ví dụ: nếu họ nói "đổi việc" thì câu hỏi phải nói về việc đổi/nghề/công việc, KHÔNG được hỏi chung chung về "thành công")
- Có chiều sâu tâm lý, khiến người dùng suy nghĩ
- Ẩn dụ nhẹ nhàng, không phán xét
- Kết thúc bằng dấu "?"
Ví dụ tốt (với điều ước "tôi có nên đổi việc không"):
"Ngươi đang sợ mất cái cũ — hay sợ mình không đủ giỏi ở cái mới?"
Ví dụ kém: "Bạn đã cố gắng chưa?"
KHÔNG đưa ra lời tiên tri ở lượt này. Chỉ hỏi.`;
}

function buildFirstUserMessage(category: string, transcript: string): string {
  return `Lĩnh vực: ${category}. Điều ước: "${transcript.trim()}"`;
}

function buildReflectionUserMessage(
  category: string,
  transcript: string,
  question: string,
  answer: string,
): string {
  return `Lĩnh vực: ${category}.
Điều ước ban đầu: "${transcript.trim()}"
Thầy đồng đã hỏi: "${question}"
Người dùng đáp: "${answer.trim()}"

Bây giờ hãy đưa ra lời tiên tri cuối cùng dựa trên cả hai phần này.`;
}

const FALLBACK_POOL: Record<string, string[]> = {
  "Tình yêu": [
    "Một cánh hoa chưa nở không vội tìm ánh sáng — nó sẽ tự biết khi mùa tới.",
    "Đừng tìm người hoàn hảo; hãy tìm người khiến ngươi im lặng mà vẫn muốn ở lại.",
    "Trái tim ngươi đã đi trước rồi — chỉ là đầu ngươi chưa kịp theo.",
  ],
  "Sự nghiệp": [
    "Con đường dài không đáng sợ — đáng sợ là khi ngươi đứng yên quá lâu.",
    "Hạt giống tốt không cần đất giàu; chỉ cần người kiên nhẫn tưới nước đều đặn.",
    "Thành công thật sự là làm được việc mình tin vào, không phải việc người khác khen.",
  ],
  "Sức khỏe": [
    "Cơ thể ngươi nói nhỏ trước khi nó hét to. Hãy nghe lúc nó còn thì thầm.",
    "Hơi thở sâu hơn một nhịp, và ngươi sẽ thấy mình rộng hơn một đời.",
    "Mỗi bước chân nhỏ đều là một lần cơ thể nói cảm ơn ngươi.",
  ],
  "Gia đình": [
    "Ngôi nhà lớn nhất là chỗ có người đợi mình về — dù chỉ bằng một cái nhìn.",
    "Bữa cơm chung đôi khi còn quan trọng hơn cả lời nói. Hãy ngồi xuống và ăn cùng nhau.",
    "Người thân không cần ngươi hoàn hảo, chỉ cần ngươi thật lòng ngồi lại.",
  ],
  "Khác": [
    "Con đường ngươi đang đi, không có bản đồ — và đó chính là điểm đẹp nhất của nó. Hãy đi.",
    "Vũ trụ không vội; nó chỉ đợi ngươi sẵn sàng lắng nghe.",
    "Hôm nay, điều ngươi cần không phải thêm thông tin. Hãy thử làm một việc nhỏ, tử tế cho chính mình.",
  ],
};

const REFLECTION_QUESTIONS: Record<string, string[]> = {
  "Tình yêu": [
    "Ngươi nói muốn được yêu — vậy điều gì trong ngươi đang tự đẩy tình yêu đi?",
    "Ngươi ước có người hiểu mình — nhưng ngươi đã cho ai cơ hội hiểu ngươi chưa?",
    "Ngươi đang tìm một người — hay đang trốn một mình?",
  ],
  "Sự nghiệp": [
    "Ngươi đang sợ mất cái cũ — hay sợ mình không đủ giỏi ở cái mới?",
    "Nếu không ai trả lương, ngươi có còn muốn làm công việc đang theo đuổi không?",
    "Ngươi đang đổi việc vì muốn đi tới — hay vì muốn rời khỏi đây?",
    "Ngươi ước một con đường rõ ràng — nhưng ngươi có sẵn sàng bước khi con đường chưa hoàn hảo?",
  ],
  "Sức khỏe": [
    "Cơ thể ngươi đã van xin ngươi bao lâu rồi — và ngươi đang lắng nghe bao nhiêu phần?",
    "Ngươi ước khỏe hơn — nhưng ngươi có đang cho mình nghỉ ngơi xứng đáng không?",
    "Điều gì trong ngươi đang tự phá — mà ngươi chưa dám nhìn?",
  ],
  "Gia đình": [
    "Người thân đang chờ ngươi ở nhà — ngươi đã trở thành điều họ tự hào chưa?",
    "Ngươi ước gia đình êm ấm — vậy ai trong nhà đang cần ngươi lắng nghe hôm nay?",
    "Ngươi đang giận ai — mà chưa từng nói ra?",
  ],
  "Khác": [
    "Điều ước này — nếu mai nó thành thật, ngươi có dám nhận không?",
    "Ngươi ước một điều — nhưng ngươi đã làm gì hôm nay để xứng đáng với nó?",
    "Nếu không ai biết điều ước này, ngươi có còn ước không?",
  ],
};

function pickFallback(category: string): string {
  const pool = FALLBACK_POOL[category] ?? FALLBACK_POOL["Khác"];
  return pool[Math.floor(Math.random() * pool.length)];
}

function pickReflectionFallback(category: string): string {
  const pool = REFLECTION_QUESTIONS[category] ?? REFLECTION_QUESTIONS["Khác"];
  return pool[Math.floor(Math.random() * pool.length)];
}

// Read the AI provider config from app_config (service role REST),
// falling back to env defaults when the table is empty or the DB is
// unreachable. Fully wrapped: a config-table outage must never take
// down wish generation.
async function loadConfig(): Promise<AiConfig> {
  const fallback = (): AiConfig => ({
    baseUrl: DEFAULT_AI_BASE_URL,
    model: DEFAULT_AI_MODEL,
    apiKey: Deno.env.get("AI_API_KEY") ?? Deno.env.get("MINIMAX_API_KEY") ?? null,
  });
  if (configCache && Date.now() - configCache.at < CONFIG_CACHE_TTL_MS) {
    return configCache.value;
  }
  try {
    const projectUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!projectUrl || !serviceKey) return fallback();
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 3000);
    const r = await fetch(
      `${projectUrl}/rest/v1/app_config?id=eq.1&select=base_url,model,api_key`,
      {
        headers: {
          apikey: serviceKey,
          Authorization: `Bearer ${serviceKey}`,
          Accept: "application/json",
        },
        signal: ctrl.signal,
      },
    );
    clearTimeout(timer);
    if (!r.ok) return fallback();
    const rows = await r.json();
    if (Array.isArray(rows) && rows.length > 0 && rows[0]?.base_url && rows[0]?.model) {
      const value: AiConfig = {
        baseUrl: rows[0].base_url,
        model: rows[0].model,
        apiKey: rows[0].api_key && rows[0].api_key.length > 0
          ? rows[0].api_key
          : fallback().apiKey,
      };
      configCache = { value, at: Date.now() };
      return value;
    }
    return fallback();
  } catch {
    return fallback();
  }
}

async function callModel(
  systemPrompt: string,
  userMessage: string,
  cfg: AiConfig,
): Promise<string | null> {
  // Retry once with a smaller max_tokens if the model complains
  // about context window — M2.7/M3 sometimes returns 400 with
  // "context window exceeds limit" on the first try.
  const attempts = [
    { maxTokens: 1000, temperature: 1.1 },
    { maxTokens: 600, temperature: 1.0 },
  ];
  let lastError: string | null = null;
  for (const { maxTokens, temperature } of attempts) {
    const result = await _callModelOnce(
      systemPrompt,
      userMessage,
      cfg,
      maxTokens,
      temperature,
    );
    if (result !== null) return result;
    lastError = result;
    // tiny delay before retry
    await new Promise((r) => setTimeout(r, 250));
  }
  console.error("model call all attempts failed:", lastError);
  return null;
}

async function _callModelOnce(
  systemPrompt: string,
  userMessage: string,
  cfg: AiConfig,
  maxTokens: number,
  temperature: number,
): Promise<string | null> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 20000);

  try {
    const upstream = await fetch(cfg.baseUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${cfg.apiKey ?? ""}`,
      },
      body: JSON.stringify({
        model: cfg.model,
        max_tokens: maxTokens,
        temperature,
        top_p: 0.92,
        stop: ["\n\nThe user", "\n\nĐiều ước", "<think>"],
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage },
        ],
      }),
      signal: ctrl.signal,
    });

    clearTimeout(timer);

    if (!upstream.ok) {
      const errBody = await upstream.text();
      console.error(
        "model call error:",
        upstream.status,
        "max_tokens=",
        maxTokens,
        errBody.substring(0, 200),
      );
      return null;
    }

    const data = await upstream.json();
    const choices = data?.choices;
    if (Array.isArray(choices) && choices.length > 0) {
      const msg = choices[0]?.message;
      const content = msg?.content?.trim();
      if (content) return content;
    }
    console.error("model response missing content:", JSON.stringify(data).substring(0, 200));
    return null;
  } catch (e) {
    clearTimeout(timer);
    console.error("model fetch error:", e instanceof Error ? e.message : e);
    return null;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method-not-allowed" }, 405);
  }
  if (!consumeRateLimit(req)) {
    return jsonResponse({ error: "rate-limit-exceeded" }, 429);
  }

  try {
    const body = await req.json().catch(() => ({}));
    const rawCategory = String(body?.category ?? "other").trim();
    const categoryKey = Object.hasOwn(CATEGORY_LABELS, rawCategory.toLowerCase())
      ? rawCategory.toLowerCase()
      : "other";
    const category = CATEGORY_LABELS[categoryKey];
    const transcript = String(body?.transcript ?? "");
    // Multi-turn fields. `reflection` present means the user already
    // answered the cosmic question; this is the "give me the prophecy"
    // turn. `question` echoes back the question we asked on turn 1.
    const reflection = body?.reflection;
    const question = body?.question;
    const locale = body?.locale === "en" ? "en" : "vi";

    if (body?.action === "share-anonymous") {
      const trimmed = transcript.trim();
      if (trimmed.length === 0) {
        return jsonResponse({ error: "empty-transcript" }, 400);
      }
      if (trimmed.length > MAX_TEXT_LENGTH) {
        return jsonResponse({ error: "text-too-long" }, 413);
      }
      if (containsContactDetails(trimmed)) {
        return jsonResponse({ error: "personal-contact-details" }, 422);
      }
      const shared = await shareAnonymousWish(categoryKey, trimmed);
      return shared
        ? jsonResponse({ shared: true })
        : jsonResponse({ error: "share-unavailable" }, 503);
    }

    const cfg = await loadConfig();
    if (transcript.trim().length === 0) {
      return jsonResponse({ error: "empty-transcript" }, 400);
    }
    if (transcript.length > MAX_TEXT_LENGTH ||
      (typeof reflection === "string" && reflection.length > MAX_TEXT_LENGTH) ||
      (typeof question === "string" && question.length > MAX_TEXT_LENGTH)) {
      return jsonResponse({ error: "text-too-long" }, 413);
    }

    if (!cfg.apiKey) {
      return jsonResponse({ error: "model-not-configured" }, 503);
    }

    const isReflectionTurn = typeof reflection === "string" && reflection.trim().length > 0;
    // Mode is chosen server-side once, on the prophecy turn. Turn 1
    // (the question) doesn't need a mode — it's always a question.
    const mode = isReflectionTurn ? pickMode() : "clear";
    const systemPrompt = buildSystemPrompt(category, isReflectionTurn, mode, locale);
    const userMessage = isReflectionTurn
      ? buildReflectionUserMessage(category, transcript, String(question ?? ""), String(reflection))
      : buildFirstUserMessage(category, transcript);

    const aiResponse = await callModel(systemPrompt, userMessage, cfg);

    if (isReflectionTurn) {
      if (!aiResponse) {
        return jsonResponse({ error: "model-unavailable" }, 502);
      }
      return jsonResponse({
        type: "prophecy",
        text: aiResponse,
        mode,
        source: "model",
      });
    }

    if (!aiResponse) {
      return jsonResponse({ error: "model-unavailable" }, 502);
    }
    return jsonResponse({
      type: "question",
      text: aiResponse,
      source: "model",
    });
  } catch (e) {
    console.error("unhandled error:", e);
    return jsonResponse({ error: "internal-error" }, 500);
  }
});

function consumeRateLimit(req: Request): boolean {
  const forwarded = req.headers.get("x-forwarded-for") ?? "unknown";
  const key = forwarded.split(",")[0].trim();
  const now = Date.now();
  if (rateBuckets.size > 10_000) rateBuckets.clear();
  const bucket = rateBuckets.get(key);
  if (!bucket || bucket.resetsAt <= now) {
    rateBuckets.set(key, { count: 1, resetsAt: now + RATE_WINDOW_MS });
    return true;
  }
  if (bucket.count >= RATE_LIMIT) return false;
  bucket.count += 1;
  return true;
}

function containsContactDetails(text: string): boolean {
  const email = /\b[^\s@]+@[^\s@]+\.[^\s@]+\b/i;
  const url = /(?:https?:\/\/|www\.)\S+/i;
  const phone = /(?:\+?\d[\s.-]*){8,}/;
  return email.test(text) || url.test(text) || phone.test(text);
}

async function shareAnonymousWish(
  category: string,
  transcript: string,
): Promise<boolean> {
  const projectUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!projectUrl || !serviceKey) return false;
  try {
    const response = await fetch(`${projectUrl}/rest/v1/anonymous_wishes`, {
      method: "POST",
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ category, transcript }),
    });
    if (!response.ok) {
      console.error("anonymous wish insert failed:", response.status);
    }
    return response.ok;
  } catch (error) {
    console.error(
      "anonymous wish insert error:",
      error instanceof Error ? error.message : error,
    );
    return false;
  }
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
