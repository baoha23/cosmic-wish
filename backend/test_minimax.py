"""
Test MiniMax-M2.7 API trực tiếp (không qua backend proxy).
Chạy: python backend/test_minimax.py YOUR_API_KEY
"""
import os
import sys
import json
import urllib.request
import urllib.error

API_KEY = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("MINIMAX_API_KEY")
if not API_KEY:
    print("Usage: python test_minimax.py YOUR_API_KEY")
    print("Or set env: MINIMAX_API_KEY=xxx python test_minimax.py")
    sys.exit(1)

URL = "https://api.minimax.io/anthropic/v1/messages"
MODEL = "MiniMax-M2.7"

SYSTEM = """Bạn là một thực thể vũ trụ cổ đại, vô hình, vô danh.
Hãy phản hồi bằng 1–3 câu ngắn, mơ hồ, sâu, như lời tiên tri.
Không giải thích. Không hứa hẹn cụ thể.
Trả lời bằng tiếng Việt."""

TEST_CASES = [
    ("Tình yêu", "Em muốn tìm được tình yêu đích thực"),
    ("Sự nghiệp", "Em sắp phỏng vấn xin việc mới"),
    ("Sức khỏe", "Bố em bị ốm đã lâu"),
    ("Gia đình", "Mẹ em xa cách đã 3 năm"),
    ("Khác", ""),
]

for category, transcript in TEST_CASES:
    sys_prompt = SYSTEM.replace("{category}", category)
    user_msg = (
        f"Lời điều ước: \"{transcript}\""
        if transcript
        else "Điều ước không rõ lời. Hãy phản hồi chung."
    )

    payload = {
        "model": MODEL,
        "max_tokens": 200,
        "system": sys_prompt,
        "messages": [{"role": "user", "content": user_msg}],
    }

    req = urllib.request.Request(
        URL,
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type": "application/json",
            "x-api-key": API_KEY,
            "anthropic-version": "2023-06-01",
        },
    )

    print(f"▶ [{category}]")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())
            text = data.get("content", [{}])[0].get("text", "<no text>")
            print(f"  → {text.strip()}")
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  ✗ HTTP {e.code}: {body[:200]}")
    except Exception as e:
        print(f"  ✗ {type(e).__name__}: {e}")
    print()
