# Native permission patches

After running `flutter create --platforms=android,ios .`, apply these manually.

## Android — `android/app/src/main/AndroidManifest.xml`

Add inside the `<manifest>` element (above `<application>`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

## iOS — `ios/Runner/Info.plist`

Add inside the top-level `<dict>`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>يستخدم التطبيق الميكروفون للتحقق من تسميع القرآن الكريم.</string>
```

iOS minimum deployment target should be 12.0 or later for `record` 5.x — edit `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

## iOS — Keychain entitlement for flutter_secure_storage

`flutter_secure_storage` ^9.x uses the iOS Keychain. Open the project in
Xcode (`ios/Runner.xcworkspace`), select the Runner target, go to
"Signing & Capabilities", and click **+ Capability → Keychain Sharing**.
A blank entry in the Keychain Groups list is sufficient — the package
does not require a custom access group.

No Android-side changes are required for `flutter_secure_storage` beyond
the standard manifest.

## Android — cleartext for local dev

If you point the app at `http://10.0.2.2:3000` (Android emulator → host), add to `AndroidManifest.xml` inside `<application>`:

```xml
android:usesCleartextTraffic="true"
```

This is dev-only; production must use HTTPS.

## ⚠️ Before Production Release

- [ ] Remove `android:usesCleartextTraffic="true"` from `AndroidManifest.xml`
- [ ] Set `JWT_SECRET` to a strong random value (min 32 chars)
- [ ] Set `GROQ_API_KEY` in backend `.env` (never in mobile build)
- [ ] Enable HTTPS on your backend domain
- [ ] Set CORS origins to your production domain only
- [ ] Run `npm run migration:run` on the production database
- [ ] Verify `flutter_secure_storage` Keychain Sharing is enabled (iOS)
