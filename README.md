# Cosmic Wish

Gửi điều ước vào vũ trụ. Flutter app Android với theme huyền bí, sinh phản hồi AI.

## Features

- **Starfield animation** - hạt sao nhấp nháy (CustomPainter, 200 sao)
- **Mystical camera overlay** - camera trước làm nền khí, rune 6 cánh xoay chậm
- **Typed wish input** - gõ điều ước vào khung văn bản (TextField đa dòng)
- **AI response** - MiniMax-M2.7 hỏi một câu suy ngẫm cá nhân hóa rồi sinh lời tiên tri
- **Privacy** - camera preview không capture; AI chỉ nhận `category`, `transcript`, câu hỏi và câu trả lời suy ngẫm (text)
- **History** - lưu lịch sử điều ước (local, SharedPreferences) + export/import JSON
- **Settings** - chỉnh âm thanh, haptics, mật độ sao, tốc độ animation, daily reminder, ngôn ngữ
- **Anonymous wishes** - hiển thị điều ước cộng đồng; chia sẻ mới mặc định tắt và chỉ bật khi người dùng đồng ý
- **App icon + splash** riêng theo theme
- **Ambient audio** - drone synth 20s loop

## Tech stack

- **Flutter** 3.41 (Android target SDK 24+)
- **camera** — preview camera trước làm nền (không ghi hình)
- **just_audio** — ambient + SFX
- **flutter_animate** — transitions
- **shared_preferences** — lưu settings + history
- **http** — gọi backend proxy
- **flutter_local_notifications** — daily reminder + response countdown + 30-day farewell
- **file_picker** + **share_plus** — import/export JSON
- **Backend**: Supabase Edge Function (Deno) → MiniMax-M2.7

## Cấu trúc project

```
cosmic-wish/
├── lib/
│   ├── main.dart
│   ├── theme/                # colors + typography
│   ├── models/               # WishCategory, WishSession, WishHistoryEntry
│   ├── services/             # wish_service, audio_service, history_service, settings_service
│   ├── widgets/              # starfield_background, mystic_button
│   └── screens/              # luồng nghi lễ, reflection, kết quả, lịch sử và cài đặt
├── assets/
│   ├── audio/                # ambient.wav, chime.wav, swoosh.wav, tap.wav
│   └── icons/                # app icons (multiple sizes)
├── backend/                  # hướng dẫn và công cụ test backend
├── supabase/                 # Edge Function + migrations (nguồn deploy duy nhất)
├── docs/
│   └── TESTING.md            # test guide đầy đủ
├── tools/
│   ├── generate_icon.py      # tạo launcher icon
│   ├── generate_adaptive_icon.py
│   ├── generate_ambient.py   # tạo audio ambient
│   └── generate_sfx.py       # tạo sound effects
└── android/                  # Android config + manifest
```

## Flow app

1. **Home** - starfield + logo "COSMIC WISH" + nút BẮT ĐẦU
2. **Chọn loại điều ước** - 5 categories (Tình yêu, Sự nghiệp, Sức khỏe, Gia đình, Khác)
3. **Chuẩn bị** - breathing circle, đếm ngược 5s, ambient audio
4. **Camera** - camera trước làm nền khí, rune 6 cánh xoay, TextField để gõ điều ước
5. **Loading** - concentric rings + hint text xoay vòng, "Đang gửi đến vũ trụ..."
   → AI nhận `{ category, transcript }` và trả về một câu hỏi cá nhân hoá
6. **Suy ngẫm** - người dùng trả lời câu hỏi; app gửi thêm `{ question, reflection }`
7. **Kết quả** - lời tiên tri + countdown tới "vũ trụ hồi đáp" (7-30 ngày random) + nút TRỞ VỀ

## Cài đặt

### 1. Setup Flutter

```bash
flutter pub get
```

Android build cần JDK 17 hoặc 21; JDK 25 hiện chưa tương thích với Gradle
wrapper của dự án.

### 2. Setup Backend (Supabase)

Chi tiết tại `backend/README.md`. Tóm tắt:

```bash
supabase login
supabase link --project-ref <YOUR_REF>
supabase secrets set MINIMAX_API_KEY=sk-xxx
supabase db push
supabase functions deploy generate-wish
```

### 3. Cấu hình URL backend

Trong `lib/services/wish_service.dart`:

```dart
final String proxyUrl = 'https://<YOUR_REF>.supabase.co/functions/v1/generate-wish';
```

### 4. Build APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_ANON_KEY=<YOUR_ANON_KEY>
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Testing

Chi tiết tại `docs/TESTING.md`. Quick test:

```bash
# Test MiniMax API trực tiếp
python backend/test_minimax.py YOUR_API_KEY

# Test Edge Function local
bash backend/test.sh
```

## Permissions

- `CAMERA` - preview camera trước làm nền (không ghi hình)
- `POST_NOTIFICATIONS` (Android 13+) - daily reminder + response countdown
- `INTERNET` - gọi backend

Từ chối camera → app dùng nền thay thế và vẫn cho phép nhập điều ước.

## Privacy

- Camera chỉ dùng làm preview, không capture ảnh/video
- Chỉ gửi nội dung chữ cần thiết cho hai lượt AI lên backend
- Lịch sử cá nhân lưu local; dữ liệu cộng đồng chỉ được gửi khi build có Supabase anon key
- `anonymous_wishes` là public Supabase table; app chỉ đăng khi người dùng chủ động bật trong Settings
- History lưu local (SharedPreferences), user tự xóa được, có export/import JSON

## Lưu ý

- Test trên nhiều thiết bị Android (Samsung, Xiaomi, Pixel) để check camera preview
- Backend trả lỗi thật nếu MiniMax không sẵn sàng; app giữ nội dung và cho phép thử lại
- Notification dùng lịch không chính xác tuyệt đối để tránh quyền exact-alarm nhạy cảm

## License

Personal project. All rights reserved.
