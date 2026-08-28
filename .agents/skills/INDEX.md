# Skills Index — Grid Survival Simulator

> Đọc skill phù hợp TRƯỚC KHI bắt đầu làm task tương ứng.

## Khi nào dùng skill nào?

| Task | Skill |
|------|-------|
| Build APK/AAB trên CI | `flutter-android-build-lessons.md` |
| Sửa engine calculation | `grid-engine-coding-lessons.md` |
| Git commit / CI workflow | `git-ci-workflow-lessons.md` |
| Cross-project (bất kỳ Flutter/Android project) | `cross-project-lessons.md` |

## Tóm tắt bài học quan trọng nhất

### Engine (6 bugs đã fix)
1. **Không hardcode placeholder** — `0` ≠ "chưa biết", dùng `null` hoặc tính thật
2. **Netting = cumulative** — KHÔNG sum `requiredMargin`, dùng `totalMargin(hedgeMode)`
3. **Grid build 1 lần** — entry prices cố định, slider chỉ thay đổi `assumedPrice`
4. **hedgingReduced = hedgingFull** — single-direction không có hedged portion
5. **Constraint evaluate tại giá đang xem** — không copy từ base calculation
6. **Logic ở engine layer** — UI chỉ display, engine mới test được
7. **isTriggeredAlwaysTrue vs isTriggeredAtPrice** — phân biệt 2 khái niệm
8. **GapAnalyzer ở engine layer** — không để logic phức tạp trong UI

### Build (8 lỗi đã fix)
1. **Flutter không có `--release-key-store`** — dùng `build.gradle.kts` + env vars
2. **Kotlin naming conflict** — không đặt tên variable trùng property
3. **R8 thiếu class** — thêm keep rules cho Play Core + Ads + Sentry
4. **Artifact path sai** — tính đúng `<flutter-dir>/build/app/outputs/...`
5. **targetSdk 36 compatibility chain** — AGP ≥ 8.7.0, compileSdk ≥ 36
6. **Flutter targetSdkVersion override** — set cứng thay vì dùng flutter.targetSdkVersion
7. **AGP version phải match compileSdk** — 8.1.0 không hỗ trợ API 36
8. **Google Play deadline** — API 36 yêu cầu từ 31/8/2026

### Workflow
1. **Keystore** — lưu trong GitHub Secrets, KHÔNG commit file `.jks`
2. **Build local** — chỉ test + analyze, KHÔNG build APK/AAB
3. **Commit message** — feat/fix/refactor/test/docs + Codebuff footer
4. **OpenSpec** — mỗi change có proposal + tasks, archive khi xong

## Version Compatibility Matrix

| Component | Current | Min for API 36 | File |
|-----------|---------|----------------|------|
| compileSdk | 36 | 36 | `app/build.gradle.kts` |
| targetSdk | 36 | 36 | `app/build.gradle.kts` |
| AGP | 8.7.0 | 8.7.0 | `settings.gradle.kts` |
| Kotlin | 1.9.0 | 1.9.0 | `settings.gradle.kts` |
| Java | 17 | 17 | `build.gradle.kts` |
| Flutter | 3.24.0 | 3.22+ | `.github/workflows/*.yml` |
