# Skill: Flutter Android Build Pitfalls

> Ghi lại từ kinh nghiệm thực tế build debug APK + release AAB trên GitHub Actions.
> Mỗi lần bắt đầu build Android, đọc skill này TRƯỚC KHI viết workflow.

## 1. Flutter CLI không接受 signing flags

```
# SAI — flutter không có flag này:
flutter build appbundle --release --release-key-store=keystore.jks

# ĐÚNG — signing phải xử lý trong build.gradle.kts qua env vars:
flutter build appbundle --release
```

**Nguyên nhân**: Flutter CLI chỉ hỗ trợ `--debug`/`--release`, không có flag ký tên.

**Cách đúng**: Dùng `System.getenv()` trong `signingConfigs` của `build.gradle.kts`.

## 2. Kotlin naming conflict trong build.gradle.kts

```
# SAI — "Val cannot be reassigned":
val storePassword = System.getenv("KEYSTORE_PASSWORD")
storePassword = storePassword  # ← conflict!

# ĐÚNG — gán trực tiếp:
storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "83793900"
```

**Nguyên nhân**: `storePassword` là property của `SigningConfig`. khai báo `val storePassword` cùng tên → shadow property gốc.

## 3. R8/ProGuard thiếu class khi minify release

```
# Lỗi: Missing class com.google.android.play.core.splitcompat.SplitCompatApplication
```

**Fix**: Thêm vào `proguard-rules.pro`:
```
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.gms.ads.** { *; }
-keep class io.sentry.** { *; }
```

Hoặc tắt minify: `isMinifyEnabled = false` trong buildTypes.release.

## 4. Artifact upload path sai trong CI

```
# Flutter output: build/app/outputs/bundle/release/app-release.aab (relative to app/)
# Từ repo root: app/build/app/outputs/bundle/release/app-release.aab

# SAI:
path: app/app/build/outputs/bundle/release/app-release.aab  # thừa app/
path: app/build/outputs/bundle/release/app-release.aab       # thiếu /app/ sau build/

# ĐÚNG:
path: app/build/app/outputs/bundle/release/app-release.aab
```

**Quy tắc**: `flutter build` output nằm trong `build/` của flutter project. Từ repo root: `<flutter-project-dir>/build/app/outputs/...`

## 5. Nâng targetSdk/compileSdk — Compatibility Chain

Khi nâng targetSdk phải kiểm tra TOÀN BỘ chain:

```
targetSdk 36 yêu cầu:
├── compileSdk ≥ 36
├── AGP (Android Gradle Plugin) ≥ 8.7.0
├── Kotlin ≥ 1.9.0 (đã OK)
├── Java 17 (đã OK)
└── Flutter SDK tương thích
```

**Checkpoint trước khi nâng:**
1. ✅ `compileSdk = 36` trong `build.gradle.kts`
2. ✅ `targetSdk = 36` trong `build.gradle.kts`
3. ✅ AGP version ≥ 8.7.0 trong `settings.gradle.kts`
4. ✅ `flutter.targetSdkVersion` KHÔNG override được → phải set cứng
5. ✅ Test build trên CI TRƯỚC KHI merge

**Google Play deadline**: API 36 yêu cầu từ 31/8/2026. Nếu chưa upgrade = không upload được.

## 6. GitHub Secrets cho keystore

```yaml
# Decode keystore từ base64 secret:
- run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > app/android/app/release-keystore.jks

# Set secrets:
gh secret set KEYSTORE_BASE64 --body "$(base64 release-keystore.jks)"
gh secret set KEYSTORE_PASSWORD --body "83793900"
gh secret set KEY_ALIAS --body "gridsurvival"
gh secret set KEY_PASSWORD --body "83793900"
```

**Lưu ý**: Keystore file KHÔNG nên commit vào repo. Chỉ lưu dưới dạng base64 secret.

## 7. Checklist trước khi build release

1. ✅ `build.gradle.kts` có `signingConfigs.create("release")` với env vars
2. ✅ `buildTypes.release.signingConfig = signingConfigs.getByName("release")`
3. ✅ `compileSdk` và `targetSdk` đúng version yêu cầu
4. ✅ AGP version trong `settings.gradle.kts` tương thích với compileSdk
5. ✅ `proguard-rules.pro` có đủ keep rules cho Flutter + Ads + Sentry
6. ✅ GitHub secrets đã set: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
7. ✅ Artifact upload path đúng: `<flutter-dir>/build/app/outputs/bundle/release/app-release.aab`
8. ✅ Keystore KHÔNG nằm trong `.gitignore` (nếu cần commit) hoặc đã decode từ secret

## 8. Version Compatibility Matrix

| Component | Current | Minimum for API 36 | Location |
|-----------|---------|-------------------|----------|
| compileSdk | 36 | 36 | `app/build.gradle.kts` |
| targetSdk | 36 | 36 | `app/build.gradle.kts` |
| AGP | 8.7.0 | 8.7.0 | `settings.gradle.kts` |
| Kotlin | 1.9.0 | 1.9.0 | `settings.gradle.kts` |
| Java | 17 | 17 | `build.gradle.kts` |
| Flutter | 3.24.0 | 3.22+ | `.github/workflows/*.yml` |
