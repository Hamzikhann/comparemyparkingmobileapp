# Compare My Parking app: Mac setup and store builds (iOS + Android)

Written 2026-11-17. App repo: https://github.com/Hamzikhann/comparemyparkingmobileapp (branch `main`). Flutter app; backend is a separate Node repo; website is a separate Next.js repo.

## 1. Install on the Mac (do this before build day; Xcode is ~15 GB)

| What | How | Notes |
|---|---|---|
| macOS updates | System Settings > Software Update | Latest Xcode needs a recent macOS |
| Xcode | App Store | Open once, accept licence. Xcode > Settings > Components: download the **iOS platform** |
| Command line tools | `xcode-select --install` then `sudo xcodebuild -runFirstLaunch` | |
| Homebrew | install command from https://brew.sh | |
| CocoaPods | `brew install cocoapods` | iOS plugins (Firebase, Stripe, ...) |
| **Flutter 3.41.9 exactly** | flutter.dev SDK archive, or `git clone https://github.com/flutter/flutter.git` then `git checkout 3.41.9` | Must match the Windows PC. Newer Flutter needs Gradle/AGP/Kotlin upgrades we chose not to do |
| Git | comes with command line tools | |

Add Flutter to PATH (e.g. in `~/.zshrc`: `export PATH="$HOME/dev/flutter/bin:$PATH"`), then run `flutter doctor`.
**Flutter** and **Xcode** must be green. The Android line may stay red on the Mac (Android can be built on Windows).

## 2. Accounts and access to have ready

- **Apple Developer account** (paid). In Xcode > Settings > Accounts, sign in with an Apple ID that is a member of team **BC93M26DDS** (the team set in the project).
- **App Store Connect** access (upload builds, TestFlight).
- **Bundle ID `com.comparemyparking`** must exist under that team (developer.apple.com > Identifiers). Already there if the app is on the App Store.
- **iPhone push notifications:** Firebase Console > Project settings > Cloud Messaging > Apple app configuration needs an **APNs key (.p8)** uploaded. Without it Android gets notifications but iPhones do not. Create one at developer.apple.com > Keys if missing.
- **Apple Pay:** merchant ID `merchant.com.comparemyparking` must exist in the same Apple team.

## 3. Get the code onto the Mac

1. Backend and website changes must also be pushed and deployed.
2. On the Mac: `git clone https://github.com/Hamzikhann/comparemyparkingmobileapp.git` (branch `main`).
3. Do not copy `build/` or `ios/Pods` from Windows; they are rebuilt.
4. In the app folder:
   ```
   flutter pub get
   cd ios && pod install && cd ..
   ```
5. Open `ios/Runner.xcworkspace` in Xcode (the workspace, not the .xcodeproj). Runner target > Signing & Capabilities: team BC93M26DDS, "Automatically manage signing" on. Check capabilities: Background Modes (remote notifications), Apple Pay with the merchant ID above.
6. **Required (checked 2026-11-26): add Push Notifications.** The project does not have it yet (`Runner.entitlements` only has Apple Pay, no `aps-environment`), so iPhones cannot receive any notifications. Signing & Capabilities > **+ Capability** > **Push Notifications**. Xcode adds `aps-environment` to the entitlements and turns Push on for the App ID. Commit the changed `Runner.entitlements` / project file afterwards.
7. Firebase must have the **APNs auth key (.p8)** uploaded for `com.comparemyparking` (Project settings > Cloud Messaging > Apple app configuration, production and development, Team ID BC93M26DDS). It was missing on 2026-11-26.

## 4. Before building: decisions

- **Version number** in `pubspec.yaml` is currently `1.0.3+10` (Android 10 is live on Play). App Store Connect shows iOS **1.0** live, so `1.0.3 (10)` is accepted for iOS as it is. Both stores reject a build number they have already seen: for a second iOS upload raise only the number after `+` (e.g. `1.0.3+11`).
- **Export compliance:** `ITSAppUsesNonExemptEncryption = false` is set in `ios/Runner/Info.plist` (the app only uses the HTTPS built into iOS), so App Store Connect does not ask about encryption for each build.
- **Backend:** `lib/data/api/config.dart` has `useLocalBackend = false` (live comparemyairportparking.com). Must stay `false` for store builds.
- **Stripe key** in `lib/main.dart` is the LIVE key (correct for store builds; real charges).
- Backend + website changes must be deployed to the live server first (the app depends on them).

## 5. iOS build (on the Mac)

```
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```
Output: `build/ios/ipa/*.ipa` (and an archive in `build/ios/archive/`).
Upload: open the archive in Xcode Organizer (Window > Organizer > Distribute App > App Store Connect), or use Apple's **Transporter** app with the .ipa.
Then in App Store Connect: wait for processing, add to **TestFlight**, test on iPhones, then submit for review.

Common problems:
- `pod install` errors: run `pod repo update`, then `pod install` again.
- Signing errors: check the team and that the bundle ID / merchant ID / push capability exist in the Apple account.
- "Flutter version" mismatch: confirm `flutter --version` says 3.41.9.

## 6. Android build (Windows PC or Mac)

- Needs the app's **existing Play Store upload keystore** (`.jks` file + passwords) for package `com.stn00.parkingapp22`. The Windows PC has no `android/key.properties`, so it can only make debug-signed test APKs.
- Find the keystore from whoever published the app. If lost: Play Console > "Request upload key reset" (takes a few days).
- With the keystore, create `android/key.properties` (never commit it):
  ```
  storePassword=...
  keyPassword=...
  keyAlias=...
  storeFile=/full/path/to/upload-keystore.jks
  ```
- Build: `flutter build appbundle --release` -> `build/app/outputs/bundle/release/app-release.aab`. Upload to a Play Console testing track first.
- Windows PC note: Gradle needs less memory than the project asks for. Build with:
  `GRADLE_OPTS='-Dorg.gradle.jvmargs="-Xmx3g -XX:MaxMetaspaceSize=768m -XX:ReservedCodeCacheSize=256m" -Dkotlin.compiler.execution.strategy=in-process'`
- On a Mac, Android builds additionally need Android Studio, the Android SDK and Java 17.

## 7. Checklist for build day

- [ ] `flutter doctor` green for Flutter + Xcode
- [ ] Signed into Xcode with team BC93M26DDS
- [ ] APNs key uploaded in Firebase
- [ ] Code pulled on the Mac, `pod install` done
- [ ] Version number raised
- [ ] Backend + website deployed
- [ ] Upload keystore found (Android)
