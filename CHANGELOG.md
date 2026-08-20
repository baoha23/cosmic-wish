# Changelog

All notable changes to Cosmic Wish.

## [1.2.0+2] - 2026-08-20

### Features
- In-app self-update: checks `app_releases` on launch, prompts with
  a dialog (skip-version supported), downloads the new universal APK
  with a progress bar and opens the system installer
- Gold dot badge on the Settings icon when an update is pending
- "Check for updates" row in Settings (manual check, bypasses skip)
- Version footer now reads the real build version via
  package_info_plus (5-tap admin gesture unchanged)

### Tech
- New `app_releases` table (public read, service-role write) +
  public Storage bucket `releases` for APK hosting
- Tag-triggered Release workflow: builds universal APK (same
  keystore), uploads to Storage, upserts `app_releases`, attaches a
  GitHub Release archive
- CI no longer splits per ABI (one universal APK everywhere)
- New permission: REQUEST_INSTALL_PACKAGES (with system consent)

### Quality
- 59 unit tests passing (14 new for UpdateService/UpdateState)
- flutter analyze: 0 issues

## [1.1.0+1] - 2026-08-20

### Features
- Hidden admin console (Settings → tap version 5×, password login)
- Change AI provider (base URL, model, API key) in-app without
  redeploying: presets for MiniMax / OpenAI / OpenRouter / Gemini,
  live "Test Connection" with latency, reset to server defaults
- Config stored in new `app_config` table (service-role only);
  `generate-wish` reads it per request (~60s cache) and falls back to
  env `AI_API_KEY`/`MINIMAX_API_KEY` + MiniMax defaults when empty

### Tech
- New Edge Function `admin`: HMAC session tokens (30 min TTL),
  login rate limiting (5 tries / 5 min / IP), masked API key replies
- `AdminService` (Flutter) with typed exceptions; token kept in
  memory only
- CI deploys both `generate-wish` and `admin`

### Quality
- 45 unit tests passing (7 new for AdminService)
- flutter analyze: 0 issues

## [1.0.0+1] - 2026-06-14

### Features
- Mystical Flutter app for sending wishes to the universe
- Camera capture with rune overlay + speech-to-text
- AI-powered mystical responses via MiniMax-M2.7
- Local history (50 entries) with swipe-to-delete
- Daily reminder notifications
- App icon + splash screen
- Ambient audio + sound effects
- Multi-language: Vietnamese + English
- Settings: sound, haptics, star density, animation speed, language
- Backup/restore history as JSON
- Backup support for restore/import
- Custom launcher icons (adaptive)

### Tech
- Flutter 3.41 / Dart 3.11
- Provider for state management
- SharedPreferences for persistence
- Camera, speech_to_text, just_audio, flutter_local_notifications
- flutter_localizations + intl for i18n
- Supabase Edge Function (Deno) backend proxy
- GitHub Actions CI: analyze, test, build APK, deploy edge

### Quality
- 11 unit tests passing
- flutter analyze: 0 errors, 0 warnings
- ProGuard rules for release builds (minify + shrinkResources)
- Core library desugaring (minSdk 24)
- RepaintBoundary on starfield for smooth animation
- Semantic labels for screen readers
