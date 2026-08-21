# Cosmic Wish Backend

Supabase Edge Function giữ MiniMax API key và thực hiện hội thoại hai lượt:

1. Nhận điều ước, trả một câu hỏi suy ngẫm.
2. Nhận câu trả lời suy ngẫm, trả lời tiên tri cuối.

`supabase/` ở thư mục gốc là nguồn cấu hình, migrations và deploy duy nhất.
`backend/` chỉ chứa tài liệu cùng script test.

## Thiết lập

```bash
supabase login
supabase link --project-ref <PROJECT_REF>
supabase secrets set AI_API_KEY=<KEY>          # hoặc MINIMAX_API_KEY cũ
supabase secrets set ADMIN_PASSWORD=<MẬT KHẨU MẠNG, >= 16 KÝ TỰ>
supabase db push
supabase functions deploy generate-wish
supabase functions deploy admin
```

Flutter phải được build với anon key để gọi function có JWT verification:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<PROJECT_REF>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY>
```

## Chạy local

```bash
supabase functions serve generate-wish \
  --env-file ./supabase/.env.local \
  --no-verify-jwt

bash backend/test.sh
```

## API

Lượt đầu:

```json
{
  "category": "love",
  "transcript": "Tôi muốn tìm một công việc mới",
  "locale": "vi"
}
```

```json
{
  "type": "question",
  "text": "...",
  "source": "minimax"
}
```

Lượt hai gửi thêm `question` và `reflection`:

```json
{
  "type": "prophecy",
  "text": "...",
  "mode": "clear",
  "source": "minimax"
}
```

Function chỉ chấp nhận `POST`, yêu cầu Supabase JWT, giới hạn mỗi trường text
ở 500 ký tự và áp dụng rate limit cơ bản theo IP trên từng Edge isolate.
Chia sẻ cộng đồng cũng đi qua function; anon client chỉ có quyền đọc bảng.
Production nên bổ sung rate limiter toàn cục ở gateway, Redis hoặc database.

Status chính:

- `200`: phản hồi MiniMax hợp lệ
- `400`: nội dung rỗng hoặc không hợp lệ
- `401`: thiếu hoặc sai Supabase JWT
- `405`: sai HTTP method
- `413`: text dài quá giới hạn
- `429`: vượt rate limit
- `502` / `503`: model hoặc cấu hình model không sẵn sàng

Backend không trả lời fallback dựng sẵn như thể đó là kết quả AI.

## Admin console (ẩn trong app)

Cấu hình AI provider (base URL, model, API key) có thể đổi trực tiếp
trong app mà không cần sửa code hay deploy lại: vào **Cài đặt → chạm
5 lần vào dòng phiên bản** ở cuối màn hình, đăng nhập bằng
`ADMIN_PASSWORD`, sửa cấu hình và Lưu.

Cách hoạt động:

- Bảng `app_config` (migration `20260820`) giữ cấu hình hiện tại.
  RLS bật nhưng không có policy nào — chỉ service role (Edge Function)
  đọc/ghi được.
- `generate-wish` đọc bảng này mỗi request với cache ~60 giây; bảng
  trống hoặc lỗi DB thì fallback về env `AI_API_KEY`/`MINIMAX_API_KEY`
  cùng default MiniMax.
- Edge Function `admin` xác thực bằng mật khẩu, cấp token HMAC TTL
  30 phút, giới hạn 5 lần đăng nhập sai / 5 phút / IP (theo isolate —
  best-effort). API key không bao giờ trả về nguyên văn (chỉ 4 ký tự cuối).

Secrets liên quan:

- `ADMIN_PASSWORD` (bắt buộc để dùng admin) — dùng mật khẩu mạnh.
- `ADMIN_SESSION_SECRET` (tuỳ chọn) — secret ký token; bỏ trống thì
  dùng lại `ADMIN_PASSWORD`.
- `AI_API_KEY` (mới) hoặc `MINIMAX_API_KEY` (cũ) — key dự phòng khi
  bảng `app_config` trống.

Endpoint: `POST /functions/v1/admin`, dispatch theo `action`:
`login`, `get-config`, `save-config`, `test-connection`,
`reset-config`. Script test:

```bash
supabase functions serve admin generate-wish \
  --env-file ./supabase/.env.local --no-verify-jwt

ADMIN_PASSWORD=xxx bash backend/test_admin.sh
```

## Phát hành bản cập nhật (self-update)

App tự kiểm tra bảng `app_releases` khi mở; có bản mới thì hiện
thông báo, tải APK về và mở trình cài đặt.

APK nằm trên **GitHub Release** (repo public — link tải không cần
auth); Supabase chỉ giữ metadata (bảng `app_releases`) vì Storage
giới hạn upload 50MB/lần trong khi APK universal ~60MB.

Setup một lần:

1. Thêm GitHub secret `SUPABASE_SERVICE_ROLE_KEY` (dashboard →
   Settings → API).

Phát hành mỗi lần:

1. Bump `version:` trong `pubspec.yaml` (ví dụ `1.3.0+3` — số sau
   `+` là `version_code`, bắt buộc tăng).
2. Thêm mục tương ứng vào `CHANGELOG.md` (workflow tự trích làm
   release notes).
3. `git tag v1.3.0 && git push origin v1.3.0` — workflow
   `release.yml` làm phần còn lại: build APK universal ký cùng
   keystore, tạo GitHub Release đính kèm APK, upsert `app_releases`.

Lưu ý: APK cập nhật phải cùng chữ ký với bản đã cài (cùng
`COSMIC_KEYSTORE_*`), và user phải đồng ý "cho phép cài ứng dụng
không rõ nguồn" một lần khi Android hỏi.

## CI secrets

- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_PROJECT_REF`
- `SUPABASE_DB_PASSWORD`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (cho release workflow upload APK)
- `COSMIC_KEYSTORE_BASE64`
- `COSMIC_KEYSTORE_PASSWORD`
- `COSMIC_KEY_ALIAS`
- `COSMIC_KEY_PASSWORD`
