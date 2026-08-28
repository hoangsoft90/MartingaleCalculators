# Cross-Project Lessons — Áp dụng cho mọi project Flutter/Android

> Những bài học này KHÔNG chỉ riêng Grid Survival Simulator.
> Bất kỳ project Flutter nào cũng có thể gặp phải.

---

## 1. Flutter CLI không có signing flags

**Lỗi**: `Could not find an option named "release-key-store"`

**Nguyên nhân**: `flutter build appbundle` không accept `--release-key-store`, `--release-key-password`, v.v.

**Fix**: Signing phải xử lý trong `build.gradle.kts` qua environment variables:
```kotlin
signingConfigs {
    create("release") {
        storeFile = file(System.getenv("KEYSTORE_FILE") ?: "keystore.jks")
        storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
        keyAlias = System.getenv("KEY_ALIAS") ?: ""
        keyPassword = System.getenv("KEY_PASSWORD") ?: ""
    }
}
```

**Áp dụng**: Mọi project Flutter build release APK/AAB.

---

## 2. Kotlin naming conflict trong build.gradle.kts

**Lỗi**: `Val cannot be reassigned`

**Nguyên nhân**: Đặt tên variable trùng với property của SigningConfig:
```kotlin
// SAI:
val storePassword = System.getenv("KEYSTORE_PASSWORD")
storePassword = storePassword  // ← conflict!

// ĐÚNG:
storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
```

**Áp dụng**: Mọi project dùng Kotlin DSL cho Gradle.

---

## 3. R8/ProGuard thiếu class khi minify release

**Lỗi**: `Missing class com.google.android.play.core.splitcompat.SplitCompatApplication`

**Fix**: Thêm vào `proguard-rules.pro`:
```
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.gms.ads.** { *; }
```

**Áp dụng**: Mọi project Flutter dùng AdMob + Sentry + minify enabled.

---

## 4. Artifact upload path sai trong CI

**Lỗi**: `No files were found with the provided path`

**Nguyên nhân**: Flutter output path tính từ thư mục flutter project, không phải repo root.

```
# Flutter output: build/app/outputs/bundle/release/app-release.aab (relative to app/)
# Từ repo root: app/build/app/outputs/bundle/release/app-release.aab
```

**Áp dụng**: Mọi project Flutter có CI build artifact.

---

## 5. AGP version phải match Gradle wrapper version

**Lỗi**: `Minimum supported Gradle version is 8.9. Current version is 8.3`

**Compatibility chain**:
| AGP | Minimum Gradle |
|-----|---------------|
| 8.1.x | 8.0 |
| 8.2.x | 8.2 |
| 8.3.x | 8.4 |
| 8.4.x | 8.6 |
| 8.5.x | 8.7 |
| 8.6.x | 8.7 |
| 8.7.x | 8.9 |

**Áp dụng**: Mọi project Android khi upgrade AGP.

---

## 6. targetSdk upgrade phải kiểm tra TOÀN BỘ chain

**Khi nâng targetSdk, phải upgrade cả**:
1. `compileSdk` ≥ targetSdk
2. AGP version tương thích
3. Gradle wrapper version tương thích
4. Flutter SDK tương thích

**Google Play deadline**: API 36 required from 31/8/2026.

**Áp dụng**: Mọi project Android publish lên Google Play.

---

## 7. Netting margin = cumulative, KHÔNG SUM

**Lỗi**: Margin hiển thị sai (quá lớn) khi dùng netting mode.

**Nguyên nhân**: Netting mode lưu `requiredMargin` dạng lũy kế. Sum tất cả = double-count.

**Fix**: Dùng hàm hedge-mode-aware:
```dart
// Netting: chỉ lấy level cuối cùng
// HedgingFull: sum tất cả
static double totalMargin(List<GridLevel> levels, HedgeMode hedgeMode) {
  if (hedgeMode == HedgeMode.netting) return levels.last.requiredMargin;
  return levels.fold(0.0, (sum, l) => sum + l.requiredMargin);
}
```

**Áp dụng**: Mọi trading/financial calculator có hedge mode.

---

## 8. Không hardcode placeholder cho calculation values

**Pattern sai**:
```dart
totalFloatingPnl: 0,  // ← "chưa biết" ≠ 0
maxDrawdownPercent: 0,
currentPrice: 0,
```

**Pattern đúng**:
```dart
// Tính thật hoặc để null
totalFloatingPnl: PnlCalculator.calculateFloatingPnl(...),
// Hoặc
totalFloatingPnl: null, // explicitly unknown
```

**Áp dụng**: Mọi calculator/financial app.

---

## 9. Logic tính toán phải ở engine/testable layer

**Pattern sai**: Logic trong UI → không test được
**Pattern đúng**: Logic ở engine layer → unit test được

**Áp dụng**: Mọi project có logic tính toán phức tạp.

---

## 10. Grid/static data build 1 lần, không rebuild theo input

**Pattern sai**: Mỗi lần input thay đổi → rebuild toàn bộ
**Pattern đúng**: Build 1 lần ở giá gốc, compute dynamic values riêng

**Áp dụng**: Mọi app có "what-if" analysis hoặc scenario simulation.

---

## 11. GitHub Secrets cho keystore

```bash
# Set:
gh secret set KEYSTORE_BASE64 --body "$(base64 release.jks)"
gh secret set KEYSTORE_PASSWORD --body "password"
gh secret set KEY_ALIAS --body "alias"
gh secret set KEY_PASSWORD --body "password"

# Workflow decode:
- run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > release.jks
```

**Lưu ý**: Keystore KHÔNG commit vào repo. Chỉ lưu trong secrets.

**Áp dụng**: Mọi project Android có CI/CD.

---

## 12. Commit message convention

```
feat: tính năng mới
fix: sửa bug
refactor: cải thiện code
test: thêm/sửa test
docs: tài liệu

🤖 Generated with Codebuff
Co-Authored-By: Codebuff <noreply@codebuff.com>
```

**Áp dụng**: Mọi project dùng Codebuff.
