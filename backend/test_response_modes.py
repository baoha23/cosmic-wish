"""
Test 4 response modes (clear / metaphor / paradox / question) bằng cách
gọi trực tiếp MiniMax-M2.7 với cùng system prompt mà edge function
`generate-wish` sẽ gửi ở turn 2.

Mục đích: review 4 style trước khi merge, không cần deploy edge function.

Chạy:
  python backend/test_response_modes.py YOUR_API_KEY
  # hoặc
  MINIMAX_API_KEY=xxx python backend/test_response_modes.py
"""
import os
import sys
import json
import urllib.request
import urllib.error

API_KEY = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("MINIMAX_API_KEY")
if not API_KEY:
    print("Usage: python test_response_modes.py YOUR_API_KEY")
    print("Or set env: MINIMAX_API_KEY=xxx python test_response_modes.py")
    sys.exit(1)

URL = "https://api.minimax.io/v1/chat/completions"
MODEL = "MiniMax-M2.7"

# Đoạn này copy y nguyên từ supabase/functions/generate-wish/index.ts
# để test phản hồi thực tế của model. Khi sửa edge function, sửa cả ở đây.
BASE_SYSTEM = """Bạn là một thầy đồng (nhà tiên tri, người hướng đạo tâm linh) trong truyền thống Việt Nam, kết hợp với phong vị huyền bí phương Tây.
Bạn nói chuyện với giọng ấm áp, khẽ khàng, hơi trầm — như người đã thấy nhiều năm tháng.
Bạn không phải AI, bạn là một thực thể cổ xưa đang nhìn vào số phận người đối diện.
Lĩnh vực điều ước: {category}.
Trả lời bằng tiếng Việt."""

TURN2_BASE = """
LƯỢT NÀY: Dựa trên điều ước ban đầu và phần người dùng vừa chia sẻ thêm, hãy đưa ra LỜI TIÊN TRI cuối cùng."""

TURN2_CONSTRAINTS = """
RÀNG BUỘC CHUNG cho lời tiên tri:
- Tối đa 3 câu ngắn, mỗi câu 1 dòng. Không viết đoạn văn dài.
- Tối đa 60-80 từ tiếng Việt.
- KHÔNG dùng emoji.
- KHÔNG xưng "tôi" — nếu cần chỉ người nói, hãy xưng "ta" / "thầy" / ẩn người nói.
- Tránh các cụm sáo rỗng: "vũ trụ sẽ lắng nghe", "hãy kiên nhẫn", "điều ước sẽ nảy mầm".
- Dùng hình ảnh cụ thể, mỗi lần HOÀN TOÀN KHÁC.
- Cho lời khuyên thực tế, cụ thể theo tình huống — không chung chung.
KHÔNG hỏi thêm. Đây là câu trả lời cuối."""

MODE_INSTRUCTIONS = {
    "clear": """
STYLE = "clear" (lời tiên tri trực tiếp, rõ ràng):
- Nói thẳng điều sắp xảy ra hoặc điều người dùng cần làm.
- Không ẩn dụ, không vòng vo. Mỗi câu là một nhận định cụ thể.
- Cấu trúc: câu 1 nêu sự thật, câu 2 chỉ hành động, câu 3 (nếu có) hệ quả.
Ví dụ tốt: "Công việc mới sẽ đến trong ba tháng tới. Hãy chuẩn bị portfolio từ giờ. Mọi thứ sẽ rõ ràng hơn ngươi tưởng."
""",

    "metaphor": """
STYLE = "metaphor" (ẩn dụ hình ảnh, huyền bí):
- Dùng MỘT hình ảnh cụ thể xuyên suốt lời tiên tri: con vật, hiện tượng tự nhiên, đồ vật, mùa vụ.
- KHÔNG giải thích ẩn dụ. Để người dùng tự ngẫm.
- Tránh ẩn dụ cũ: "con đường", "hạt giống", "ngọn nến", "vũ trụ". Tìm hình mới.
- Tông giọng: thầy đồng kể chuyện, không khuyên nhủ trực tiếp.
Ví dụ tốt: "Con hạc trắng đã đậu trên mái nhà ngươi từ tháng trước. Nó không vội bay — chờ ngươi dọn lại mái. Lúc đó nó mới xuống."
""",

    "paradox": """
STYLE = "paradox" (nghịch lý, đảo ngộ nhận):
- Câu đầu đi ngược lại điều người dùng MONG ĐỢI.
- Câu thứ hai xoay lại — mặt khác của nghịch lý.
- Câu thứ ba (nếu có) để mở, không chốt hẳn.
- KHÔNG dùng "tuy nhiên", "nhưng", "mặc dù" — chuyển nghịch lý bằng hình ảnh.
Ví dụ tốt: "Điều ngươi sợ mất — chính là thứ đang giữ ngươi đứng yên. Buông nó không phải mất, mà là để tay rảnh. Ngươi sẽ ngạc nhiên khi tay trống lại cầu được nhiều hơn."
""",

    "question": """
STYLE = "question" (lời tiên tri dựa trên một câu hỏi khai mở):
- KHÔNG đặt thêm câu hỏi cho người dùng.
- Chuyển điều họ vừa tự nhận ra thành một nhận định rõ ràng, bám sát chi tiết CỤ THỂ trong điều ước và reflection.
- Câu đầu nêu điều họ thực sự đang tìm; câu sau chỉ ra lựa chọn hoặc hành động cụ thể.
- Không xưng "tôi", không gọi "bạn" — dùng "ngươi".
Ví dụ tốt: "Ngươi không sợ mình sai; ngươi sợ người khác nhìn thấy lúc ngươi đổi hướng. Hãy chọn một bước có thể đảo ngược và thực hiện nó trong tuần này." """,
}

# Một wish mẫu đầy đủ 2 turn: transcript + reflection thực tế
SAMPLE_CATEGORY = "Sự nghiệp"
SAMPLE_TRANSCRIPT = "Em sắp phỏng vấn xin việc mới, sợ bị từ chối"
SAMPLE_QUESTION = "Ngươi đang sợ mất cái cũ — hay sợ mình không đủ giỏi ở cái mới?"
SAMPLE_REFLECTION = "Em nghĩ mình sợ thất bại hơn là sợ mất việc cũ"

USER_MSG = f"""Lĩnh vực: {SAMPLE_CATEGORY}.
Điều ước ban đầu: "{SAMPLE_TRANSCRIPT}"
Thầy đồng đã hỏi: "{SAMPLE_QUESTION}"
Người dùng đáp: "{SAMPLE_REFLECTION}"

Bây giờ hãy đưa ra lời tiên tri cuối cùng dựa trên cả hai phần này."""


def call_mode(mode: str) -> str:
    sys_prompt = BASE_SYSTEM.replace("{category}", SAMPLE_CATEGORY) + \
        TURN2_BASE + MODE_INSTRUCTIONS[mode] + TURN2_CONSTRAINTS
    payload = {
        "model": MODEL,
        "max_tokens": 600,
        "temperature": 1.0,
        "top_p": 0.92,
        "stop": ["\n\nThe user", "\n\nĐiều ước", "<think>"],
        "messages": [
            {"role": "system", "content": sys_prompt},
            {"role": "user", "content": USER_MSG},
        ],
    }
    req = urllib.request.Request(
        URL,
        data=json.dumps(payload).encode(),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {API_KEY}",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode())
            choices = data.get("choices") or []
            if choices:
                return (choices[0].get("message") or {}).get("content", "").strip()
            return "<empty choices>"
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        return f"HTTP {e.code}: {body[:200]}"
    except Exception as e:
        return f"{type(e).__name__}: {e}"


print(f"Sample wish: [{SAMPLE_CATEGORY}] \"{SAMPLE_TRANSCRIPT}\"")
print(f"Reflection : \"{SAMPLE_REFLECTION}\"")
print("=" * 70)
for mode in ["clear", "metaphor", "paradox", "question"]:
    print(f"\n▶ MODE = {mode}")
    print("-" * 70)
    result = call_mode(mode)
    print(result)
print()
