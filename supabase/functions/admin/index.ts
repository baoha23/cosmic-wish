// Supabase Edge Function: admin
// Triển khai:
//   supabase functions deploy admin
//   supabase secrets set ADMIN_PASSWORD=<mật khẩu mạnh, >= 16 ký tự>
//   (tuỳ chọn) supabase secrets set ADMIN_SESSION_SECRET=<chuỗi ngẫu nhiên>
//
// Cho phép đổi cấu hình AI provider (base URL, model, API key) trong
// bảng app_config mà không cần sửa code hay deploy lại. generate-wish
// đọc bảng này mỗi request (cache ~60s) và fallback về env secret khi
// bảng trống.

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

const TOKEN_TTL_MS = 30 * 60_000;
// Login brute-force bucket, separate from the action bucket so a
// public flood on other actions can't lock the admin out and login
// attempts can't be hidden inside action traffic.
const LOGIN_RATE = 5;
const LOGIN_WINDOW_MS = 300_000;
const ACTION_RATE = 30;
const ACTION_WINDOW_MS = 60_000;

const DEFAULT_BASE_URL = "https://api.minimax.io/v1/chat/completions";
const DEFAULT_MODEL = "MiniMax-M2.7";

const loginBuckets = new Map<string, { count: number; resetsAt: number }>();
const actionBuckets = new Map<string, { count: number; resetsAt: number }>();

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function clientKey(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for") ?? "unknown";
  return forwarded.split(",")[0].trim();
}

// Same sliding-window shape as generate-wish's consumeRateLimit,
// shared by both buckets here.
function takeFromBucket(
  buckets: Map<string, { count: number; resetsAt: number }>,
  key: string,
  limit: number,
  windowMs: number,
): boolean {
  const now = Date.now();
  if (buckets.size > 10_000) buckets.clear();
  const bucket = buckets.get(key);
  if (!bucket || bucket.resetsAt <= now) {
    buckets.set(key, { count: 1, resetsAt: now + windowMs });
    return true;
  }
  if (bucket.count >= limit) return false;
  bucket.count += 1;
  return true;
}

// --- HMAC session tokens ---------------------------------------------
// Stateless `v1.<exp>.<sig>` tokens signed with HMAC-SHA256. The
// signing secret is ADMIN_SESSION_SECRET when set, otherwise the
// admin password itself (same trust level: anyone who can forge
// tokens already knows the password).

async function hmac(secret: string, data: string): Promise<ArrayBuffer> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign("HMAC", key, new TextEncoder().encode(data));
}

function toBase64Url(buf: ArrayBuffer): string {
  let bin = "";
  const bytes = new Uint8Array(buf);
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function signToken(exp: number, secret: string): Promise<string> {
  const payload = `v1.${exp}`;
  const sig = toBase64Url(await hmac(secret, payload));
  return `${payload}.${sig}`;
}

// Constant-time digest comparison.
function timingSafeEqual(a: ArrayBuffer, b: ArrayBuffer): boolean {
  if (a.byteLength !== b.byteLength) return false;
  const va = new Uint8Array(a);
  const vb = new Uint8Array(b);
  let diff = 0;
  for (let i = 0; i < va.length; i++) diff |= va[i] ^ vb[i];
  return diff === 0;
}

async function verifyToken(
  authHeader: string | null,
  secret: string,
): Promise<boolean> {
  if (!authHeader?.startsWith("Bearer ")) return false;
  const token = authHeader.slice(7).trim();
  const parts = token.split(".");
  if (parts.length !== 3 || parts[0] !== "v1") return false;
  const exp = Number(parts[1]);
  if (!Number.isFinite(exp) || exp <= Date.now()) return false;
  try {
    const expected = await hmac(secret, `${parts[0]}.${parts[1]}`);
    // Decode base64url back to bytes for comparison.
    const b64 = parts[2].replace(/-/g, "+").replace(/_/g, "/");
    const bin = atob(b64 + "=".repeat((4 - (b64.length % 4)) % 4));
    const got = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) got[i] = bin.charCodeAt(i);
    return timingSafeEqual(expected, got.buffer);
  } catch {
    return false;
  }
}

async function checkPassword(
  supplied: string,
  actual: string,
  secret: string,
): Promise<boolean> {
  // Compare HMAC digests instead of raw passwords so the comparison
  // length never leaks the password length.
  const a = await hmac(secret, `pw:${supplied}`);
  const b = await hmac(secret, `pw:${actual}`);
  return timingSafeEqual(a, b);
}

// --- app_config table access (service role) ---------------------------

interface ConfigRow {
  base_url: string;
  model: string;
  api_key: string | null;
  updated_at: string;
}

function serviceHeaders(serviceKey: string): Record<string, string> {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
  };
}

async function readConfigRow(
  projectUrl: string,
  serviceKey: string,
): Promise<ConfigRow | null> {
  const r = await fetch(
    `${projectUrl}/rest/v1/app_config?id=eq.1&select=base_url,model,api_key,updated_at`,
    { headers: { ...serviceHeaders(serviceKey), Accept: "application/json" } },
  );
  if (!r.ok) {
    console.error("app_config read failed:", r.status);
    return null;
  }
  const rows = await r.json();
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

async function writeConfigRow(
  projectUrl: string,
  serviceKey: string,
  baseUrl: string,
  model: string,
  apiKey: string | null,
): Promise<boolean> {
  // Merge-duplicates upsert onto the singleton row (id=1).
  const r = await fetch(`${projectUrl}/rest/v1/app_config`, {
    method: "POST",
    headers: {
      ...serviceHeaders(serviceKey),
      Prefer: "resolution=merge-duplicates,return=minimal",
    },
    body: JSON.stringify({ id: 1, base_url: baseUrl, model, api_key: apiKey }),
  });
  if (!r.ok) {
    console.error("app_config write failed:", r.status);
  }
  return r.ok;
}

async function deleteConfigRow(
  projectUrl: string,
  serviceKey: string,
): Promise<boolean> {
  const r = await fetch(`${projectUrl}/rest/v1/app_config?id=eq.1`, {
    method: "DELETE",
    headers: { ...serviceHeaders(serviceKey), Prefer: "return=minimal" },
  });
  if (!r.ok) {
    console.error("app_config delete failed:", r.status);
  }
  return r.ok;
}

function envApiKey(): string | null {
  return Deno.env.get("AI_API_KEY") ?? Deno.env.get("MINIMAX_API_KEY") ?? null;
}

function maskKey(key: string): string {
  return key.length <= 4 ? "••••" : `••••${key.slice(-4)}`;
}

function currentApiKey(row: ConfigRow | null): string | null {
  return row?.api_key && row.api_key.length > 0 ? row.api_key : envApiKey();
}

// --- upstream test call -----------------------------------------------

interface TestOutcome {
  ok: boolean;
  latencyMs: number;
  status?: number;
  error?: string;
  replyPreview?: string;
  model?: string;
}

// One tiny real chat completion against the configured provider.
// Never logs or echoes the API key.
async function testConnection(
  baseUrl: string,
  model: string,
  apiKey: string,
): Promise<TestOutcome> {
  const started = Date.now();
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 15_000);
  try {
    const r = await fetch(baseUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        max_tokens: 16,
        messages: [{ role: "user", content: "ping" }],
      }),
      signal: ctrl.signal,
    });
    clearTimeout(timer);
    const latencyMs = Date.now() - started;
    if (!r.ok) {
      const err = (await r.text()).substring(0, 300);
      return { ok: false, latencyMs, status: r.status, error: err };
    }
    const data = await r.json();
    const content = data?.choices?.[0]?.message?.content;
    const preview = typeof content === "string" ? content.substring(0, 120) : "";
    return { ok: true, latencyMs, replyPreview: preview, model };
  } catch (e) {
    clearTimeout(timer);
    return {
      ok: false,
      latencyMs: Date.now() - started,
      error: e instanceof Error ? e.message : String(e),
    };
  }
}

// --- request handler ---------------------------------------------------

function validBaseUrl(value: string): boolean {
  try {
    const u = new URL(value);
    return u.protocol === "https:" && value.length <= 500;
  } catch {
    return false;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method-not-allowed" }, 405);
  }

  const adminPassword = Deno.env.get("ADMIN_PASSWORD");
  const sessionSecret =
    Deno.env.get("ADMIN_SESSION_SECRET") ?? adminPassword ?? "";
  const projectUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  const body = await req.json().catch(() => ({}));
  const action = typeof body?.action === "string" ? body.action : "";

  if (action === "login") {
    // Rate limit first: cheap, and prevents unauthenticated work.
    if (!takeFromBucket(loginBuckets, clientKey(req), LOGIN_RATE, LOGIN_WINDOW_MS)) {
      return jsonResponse({ error: "rate-limit-exceeded" }, 429);
    }
    if (!adminPassword || !projectUrl || !serviceKey) {
      return jsonResponse({ error: "admin-not-configured" }, 503);
    }
    const password = typeof body?.password === "string" ? body.password : "";
    if (!(await checkPassword(password, adminPassword, sessionSecret))) {
      return jsonResponse({ error: "invalid-password" }, 401);
    }
    // Clear the failed-attempt bucket on success so a legit login
    // after a typo isn't punished.
    loginBuckets.delete(clientKey(req));
    const exp = Date.now() + TOKEN_TTL_MS;
    return jsonResponse({ token: await signToken(exp, sessionSecret), expiresAt: exp });
  }

  // Everything below requires a valid admin token. Actions get their
  // own light bucket so a stray loop in the app can't hammer the DB.
  if (!adminPassword || !projectUrl || !serviceKey) {
    return jsonResponse({ error: "admin-not-configured" }, 503);
  }
  if (!(await verifyToken(req.headers.get("authorization"), sessionSecret))) {
    return jsonResponse({ error: "invalid-token" }, 401);
  }
  if (!takeFromBucket(actionBuckets, clientKey(req), ACTION_RATE, ACTION_WINDOW_MS)) {
    return jsonResponse({ error: "rate-limit-exceeded" }, 429);
  }

  switch (action) {
    case "get-config": {
      const row = await readConfigRow(projectUrl, serviceKey);
      const apiKey = currentApiKey(row);
      return jsonResponse({
        mode: row ? "database" : "fallback",
        baseUrl: row?.base_url ?? DEFAULT_BASE_URL,
        model: row?.model ?? DEFAULT_MODEL,
        apiKeyMasked: apiKey ? maskKey(apiKey) : null,
        updatedAt: row?.updated_at ?? null,
      });
    }

    case "save-config": {
      const baseUrl = String(body?.baseUrl ?? "").trim();
      const model = String(body?.model ?? "").trim();
      if (!validBaseUrl(baseUrl)) {
        return jsonResponse({ error: "invalid-base-url" }, 400);
      }
      if (model.length < 1 || model.length > 100) {
        return jsonResponse({ error: "invalid-model" }, 400);
      }
      // Blank/missing apiKey keeps the stored one (or env fallback).
      const rawKey = body?.apiKey;
      let apiKey: string | null;
      if (typeof rawKey === "string" && rawKey.trim().length > 0) {
        apiKey = rawKey.trim();
        if (apiKey.length > 400) {
          return jsonResponse({ error: "invalid-api-key" }, 400);
        }
      } else {
        apiKey = currentApiKey(await readConfigRow(projectUrl, serviceKey));
      }
      const ok = await writeConfigRow(projectUrl, serviceKey, baseUrl, model, apiKey);
      if (!ok) return jsonResponse({ error: "write-failed" }, 503);
      return jsonResponse({
        ok: true,
        apiKeyMasked: apiKey ? maskKey(apiKey) : null,
        updatedAt: new Date().toISOString(),
      });
    }

    case "test-connection": {
      // Absent fields fall back to the saved config.
      const row = await readConfigRow(projectUrl, serviceKey);
      const baseUrl = typeof body?.baseUrl === "string" && body.baseUrl.trim()
        ? body.baseUrl.trim()
        : row?.base_url ?? DEFAULT_BASE_URL;
      const model = typeof body?.model === "string" && body.model.trim()
        ? body.model.trim()
        : row?.model ?? DEFAULT_MODEL;
      const apiKey = typeof body?.apiKey === "string" && body.apiKey.trim()
        ? body.apiKey.trim()
        : currentApiKey(row);
      if (!apiKey) {
        return jsonResponse({ error: "no-key-configured" }, 503);
      }
      if (!validBaseUrl(baseUrl)) {
        return jsonResponse({ error: "invalid-base-url" }, 400);
      }
      const outcome = await testConnection(baseUrl, model, apiKey);
      return jsonResponse(outcome);
    }

    case "reset-config": {
      const ok = await deleteConfigRow(projectUrl, serviceKey);
      if (!ok) return jsonResponse({ error: "delete-failed" }, 503);
      return jsonResponse({ ok: true });
    }

    default:
      return jsonResponse({ error: "unknown-action" }, 400);
  }
});
