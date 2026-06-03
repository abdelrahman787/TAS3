# Quran Tasmee3 — Flutter app

## First-time setup

Platform folders (`android/`, `ios/`) are not committed — generate them on first checkout:

```bash
cd mobile
flutter create --platforms=android,ios --org com.qurantasmee3 .
flutter pub get
```

## Run

```bash
flutter run
```

The default backend URL is `http://10.0.2.2:3000` (Android emulator → host). To override:

```bash
flutter run --dart-define=BACKEND_URL=http://192.168.1.50:3000
```

iOS simulator uses `http://localhost:3000` — pass it via `--dart-define`.

## ASR

Speech recognition is proxied through the backend (`POST /asr/transcribe`).
The Groq API key lives in `backend/.env` only — it is no longer shipped in the
mobile binary. The Bearer token from auth is attached automatically by the
Dio interceptor.

## Microphone permission

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

For iOS, add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Quran Tasmee3 uses the microphone to verify your recitation.</string>
```

## Font

The Uthmani Hafs font is referenced in `pubspec.yaml` but not committed. See `assets/fonts/README.md` for how to obtain it. The app runs without it (falling back to the system Arabic font).
