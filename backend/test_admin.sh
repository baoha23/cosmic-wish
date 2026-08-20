#!/usr/bin/env bash
# Test script: gọi Edge Function admin local
# Chạy:
#   bash backend/test_admin.sh [URL] [ADMIN_PASSWORD]
# Mặc định: http://localhost:54321/functions/v1/admin và mật khẩu
# đọc từ biến môi trường ADMIN_PASSWORD.

set -e

URL="${1:-http://localhost:54321/functions/v1/admin}"
PASSWORD="${2:-${ADMIN_PASSWORD:-}}"

if [ -z "$PASSWORD" ]; then
  echo "Usage: bash backend/test_admin.sh [URL] [ADMIN_PASSWORD]"
  echo "Or set env: ADMIN_PASSWORD=xxx bash backend/test_admin.sh"
  exit 1
fi

echo "Testing $URL"
echo "---"

post() {
  curl -sS -X POST "$URL" \
    -H "Content-Type: application/json" \
    ${TOKEN:+-H "Authorization: Bearer $TOKEN"} \
    -d "$1"
}

echo "▶ 1. Login sai mật khẩu → mong đợi 401"
post '{"action":"login","password":"sai-roi"}' | grep -q invalid-password \
  && echo "  OK: invalid-password"

echo "▶ 2. Lần 6 → mong đợi 429 (rate limit dò mật khẩu)"
for i in 1 2 3 4 5; do
  post '{"action":"login","password":"sai-roi"}' > /dev/null
done
post '{"action":"login","password":"sai-roi"}' | grep -q rate-limit-exceeded \
  && echo "  OK: rate-limit-exceeded"

echo "▶ 3. Token rác → mong đợi 401"
TOKEN="v1.999.fake.sig"
post '{"action":"get-config"}' | grep -q invalid-token \
  && echo "  OK: invalid-token"
TOKEN=""

echo "▶ 4. Login đúng mật khẩu"
RESPONSE=$(post '{"action":"login","password":"'"$PASSWORD"'"}')
TOKEN=$(echo "$RESPONSE" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
[ -n "$TOKEN" ] && echo "  OK: token=${TOKEN:0:12}…"

echo "▶ 5. get-config (chưa có row) → mode fallback"
post '{"action":"get-config"}' | grep -q '"mode":"fallback"' \
  && echo "  OK: fallback"

echo "▶ 6. test-connection với cấu hình hiện tại"
post '{"action":"test-connection"}'

echo ""
echo "▶ 7. save-config URL sai → mong đợi 400"
post '{"action":"save-config","baseUrl":"not-a-url","model":"x"}' \
  | grep -q invalid-base-url && echo "  OK: invalid-base-url"

echo "▶ 8. save-config hợp lệ → mode database"
post '{"action":"save-config","baseUrl":"https://api.minimax.io/v1/chat/completions","model":"MiniMax-M2.7"}' \
  | grep -q '"ok":true' && echo "  OK: saved"
post '{"action":"get-config"}' | grep -q '"mode":"database"' \
  && echo "  OK: database"

echo "▶ 9. reset-config → về fallback"
post '{"action":"reset-config"}' | grep -q '"ok":true' && echo "  OK: reset"
post '{"action":"get-config"}' | grep -q '"mode":"fallback"' \
  && echo "  OK: fallback"

echo ""
echo "✓ All admin tests passed"
