# Testing Guide

## 1. Test MiniMax API (không cần Flutter)

Test trực tiếp model MiniMax-M2.7:

```bash
pip install urllib3   # chỉ cần nếu chưa có
python backend/test_minimax.py YOUR_API_KEY
```

Hoặc với curl:

```bash
curl -X POST https://api.minimax.io/anthropic/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "MiniMax-M2.7",
    "max_tokens": 200,
    "system": "Bạn là thực thể vũ trụ cổ đại. Trả lời bằng tiếng Việt, 1-3 câu huyền bí.",
    "messages": [{"role":"user","content":"Em muốn tìm tình yêu"}]
  }'
```

## 2. Test Edge Function local

Yêu cầu: Supabase CLI + Docker

```bash
# Setup
cp supabase/.env.local.example supabase/.env.local
# Sửa .env.local, thêm MINIMAX_API_KEY

# Chạy
supabase functions serve generate-wish --env-file ./supabase/.env.local

# Test (terminal khác)
bash test.sh
```

## 3. Test Flutter app

### Trên máy có Android SDK:

```bash
# Kiểm tra thiết bị
flutter devices

# Cài dependencies
flutter pub get

# Chạy debug
flutter run

# Build APK release
flutter build apk --release
# APK tại: build/app/outputs/flutter-apk/app-release.apk
```

### Test flow end-to-end:

1. Mở app → thấy Home screen với starfield + "COSMIC WISH"
2. Bấm "BẮT ĐẦU" → chọn category
3. Bấm "TIẾP TỤC" → màn hình breathing 3s
4. Auto chuyển sang camera (cần cấp quyền)
5. Nhập điều ước và bấm gửi (camera chỉ là preview, không ghi âm)
6. Loading lượt đầu
7. Trả lời câu hỏi suy ngẫm do AI tạo
8. Loading lượt hai
9. Result screen với lời tiên tri AI
10. Bấm "TRỞ VỀ" → về Home
11. Bấm icon History (góc trên phải) → xem wish đã lưu
12. Bấm icon Settings → chỉnh âm thanh, số sao, tốc độ animation

## 4. Test trên thiết bị thật

Lưu ý khi test:

- **Permissions**: Từ chối camera → app dùng nền thay thế và vẫn cho nhập điều ước
- **Network**: Test cả WiFi và 4G
- **Multiple devices**: Samsung, Xiaomi, Pixel (đặc biệt camera + audio conflict)
- **Offline**: Bật airplane mode → app hiển thị lỗi và cho phép thử lại mà không mất nội dung

## 5. Test permission edge cases

- Từ chối camera → vẫn nhập và gửi điều ước bình thường
- App không yêu cầu microphone

## 6. Performance

Test trên thiết bị yếu (RAM 3GB, Android 9):

- Starfield có chạy mượt với 400 sao không?
- Camera preview có lag khi rune overlay xoay?
- Loading screen có drop FPS với meteor swirl?

Nếu chậm: giảm starCount xuống 100-150 trong Settings.

## 7. Troubleshooting

### Lỗi camera
```
CameraException: Camera is closed
```
→ Check permission_handler đã yêu cầu chưa.

### Lỗi STT
```
error_audio_recording
```
→ Microphone bị app khác chiếm. Đóng các app khác.

### Lỗi backend
```
Failed host lookup
```
→ Check `proxyUrl` đúng chưa. Test bằng curl trước.

### APK build lỗi
```
Execution failed for task ':app:processDebugResources'
```
→ Check minSdk = 24, targetSdk theo Flutter SDK.
