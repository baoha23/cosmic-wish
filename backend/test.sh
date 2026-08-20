#!/usr/bin/env bash
# Test script: gọi Edge Function local với nhiều category
# Chạy: bash backend/test.sh

set -e

URL="${1:-http://localhost:54321/functions/v1/generate-wish}"

echo "Testing $URL"
echo "---"

test_category() {
  local category=$1
  local transcript=$2

  echo "▶ Category: $category"
  echo "  Transcript: $transcript"

  local response
  response=$(curl -sS -X POST "$URL" \
    -H "Content-Type: application/json" \
    -d "{\"category\":\"$category\",\"transcript\":\"$transcript\"}")

  echo "  Response: $response"
  echo ""
}

test_category "Tình yêu" "Em muốn tìm được người hiểu em"
test_category "Sự nghiệp" "Em sắp phỏng vấn xin việc mới"
test_category "Sức khỏe" "Bố em bị ốm đã lâu"
test_category "Gia đình" "Mẹ em xa cách đã 3 năm"
test_category "Khác" ""

echo "✓ All tests passed"
