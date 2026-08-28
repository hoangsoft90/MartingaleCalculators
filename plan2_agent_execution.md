# AGENT EXECUTION PLAN — Grid Survival Simulator: Feature Additions

> Nguồn: `plan2_final.md`. Tài liệu này là bản **thực thi kỹ thuật** — mỗi mục có: file cần sửa/tạo, thay đổi data model, function signature, UI cần làm, Definition of Done (DoD), và test bắt buộc.
> Agent code làm tuần tự đúng thứ tự PHASE bên dưới, **không nhảy cóc sang PHASE sau khi PHASE trước chưa đạt DoD.**
> Giả định cấu trúc thư mục kế thừa từ bản build spec trước: `packages/grid_engine/` (pure Dart) + `app/` (Flutter/Riverpod/Hive).

---

## PHASE 0 — Gate 0: Calculation Audit + Release Hygiene (BLOCKING)

Không PHASE nào sau được bắt đầu nếu PHASE 0 chưa đạt DoD.

### 0.1 Golden Cases thật
- **File:** `packages/grid_engine/test/golden_cases/golden_cases.json`
- **Việc agent code làm:** viết/generate cấu trúc để chứa 30–50 case (đã có 12 placeholder — giữ format, chỉ mở rộng), mỗi case gồm: `input` (đầy đủ AccountSpec/InstrumentSpec/ExecutionSpec/StrategySpec) + `expectedOutput` (per-level margin, floating P/L, cumulative exposure, stop-out price) + `source` (string ghi rõ "MT5 Exness demo #12345" hoặc tương tự) + `tolerancePercent` (default 0.5).
- **Việc CẦN NGƯỜI làm (agent code không tự làm được):** điền 30–50 case thật từ MT4/MT5. Agent code chỉ dựng khung, viết loader, và để `status: "PLACEHOLDER"` rõ ràng cho case chưa có data thật.
- **File test:** `packages/grid_engine/test/golden_validation_test.dart` — đọc từng case trong JSON, nếu `status != "PLACEHOLDER"` thì **test FAIL nếu sai số > tolerancePercent** (không skip). Nếu `status == "PLACEHOLDER"`, in cảnh báo rõ ràng ra console nhưng không fail build.
- **DoD:** test suite chạy được, có cơ chế phân biệt rõ case thật vs placeholder; khi có ≥30 case thật với sai số <0.5%, đổi CI config để **fail nếu còn bất kỳ case nào status = PLACEHOLDER** (chốt cứng trước khi release).

### 0.2 Sửa MarginCalculator cho Dynamic Leverage / Hedging
- **File:** `packages/grid_engine/lib/src/engine/margin_calculator.dart`
- **Thay đổi:** thêm tham số optional `leverageTiers: List<LeverageTier>?` (mỗi tier: `{minEquity, maxEquity, leverage}`) vào `AccountSpec` hoặc truyền riêng vào hàm tính margin — nếu null, dùng leverage cố định như hiện tại (không breaking change). Khi có tiers, chọn tier theo `equity` hiện tại trước khi tính `notional / leverage`.
- **DoD:** unit test cho cả 2 trường hợp (leverage cố định — behavior cũ không đổi; leverage theo tier — chọn đúng tier theo equity biên).

### 0.3 Network Security
- **File:** `app/android/app/src/main/AndroidManifest.xml`, `app/android/app/src/main/res/xml/network_security_config.xml`
- **Việc làm:** set `android:usesCleartextTraffic="false"` trên `<application>`; xóa mọi `<domain-config cleartextTrafficPermitted="true">` không cần thiết; chỉ giữ domain thật sự cần (Sentry DSN host, AdMob host) dưới HTTPS.
- **DoD:** build release APK, verify network calls tới Sentry/AdMob vẫn hoạt động (log không có lỗi cleartext blocked).

### 0.4 AdMob Placement
- **Files:** mọi screen trong `app/lib/screens/dashboard/`, `price_ladder/`, `what_if/`, `reverse_mode/`, `share/`
- **Việc làm:** xóa widget `BannerAdWidget`/tương đương khỏi 5 screen trên. Giữ nguyên ở `app/lib/screens/quick_calculator/` và `app/lib/screens/saved_strategies/`.
- **DoD:** grep toàn bộ codebase để xác nhận không còn ad widget nào ở 5 screen bị loại; QA thủ công mở từng screen kiểm tra.

### 0.5 APK Size Audit
- **Việc làm:** chạy `flutter build apk --analyze-size`, xác định thành phần chiếm dung lượng lớn nhất (thường là native libs Sentry/AdMob hoặc unused assets). Bật `--split-per-abi` cho release build. Loại bỏ font/asset không dùng.
- **DoD:** ghi lại kích thước trước/sau vào changelog; mục tiêu giảm đáng kể so với ~96MB (không đặt số cứng vì phụ thuộc kết quả audit thực tế).

### 0.6 Release Checklist còn thiếu
- i18n vi/en: đảm bảo mọi string mới ở PHASE 1+ đều đi qua hệ thống l10n có sẵn (`app/lib/l10n/`), không hard-code string tiếng Việt trong widget.
- Privacy Policy + Terms of Service: tạo 2 file tĩnh (markdown hoặc trang trong app) — nội dung do người phụ trách sản phẩm cung cấp, agent code chỉ dựng khung màn hình hiển thị + link trong Settings/About.
- AdMob real ID: thay `ca-app-pub-3940256099942544` (test ID) bằng ID thật trong config trước submit — agent code cần đảm bảo ID đọc từ file config (`.env` hoặc `--dart-define`), không hard-code, để dễ swap.

---

## PHASE 1 — P0 Features (chỉ bắt đầu sau khi PHASE 0 đạt DoD)

**Quy tắc thực thi:** mỗi mục dưới đây làm xong → viết test riêng → merge → mới sang mục kế tiếp. Không gộp PR nhiều feature.

### 1.1 Failure/Bottleneck Explanation (forward direction)
- **Files:**
  - `packages/grid_engine/lib/src/engine/constraint_evaluator.dart` — thêm hàm `ConstraintCheckResult findFirstViolation(List<GridLevel> levels, ConstraintSet constraints)` trả về constraint đầu tiên bị vi phạm + level + độ lệch (`actualValue - limitValue`).
  - `app/lib/widgets/failure_explanation_panel.dart` (mới) — hiển thị kết quả từ `findFirstViolation`.
  - `app/lib/screens/dashboard/dashboard_screen.dart` — gọi panel này khi `constraintResults` có ít nhất 1 FAIL.
- **Output format bắt buộc (không đổi nội dung, chỉ đổi diễn đạt theo ngôn ngữ UI đang dùng):**
  ```
  ❌ [ConstraintName] violated at Level [n] ([actualValue] vs limit [limitValue])
  ```
  Không thêm câu "khuyến nghị an toàn" dạng khẳng định — chỉ hiển thị số liệu + optional "Try adjusting: Multiplier" là gợi ý tham số liên quan (suy từ constraint nào bị vi phạm), không phải giá trị cụ thể được app "khuyến nghị".
- **Test:** `packages/grid_engine/test/constraint_evaluator_test.dart` — case nhiều constraint cùng fail, verify chọn đúng constraint đầu tiên theo thứ tự level tăng dần.
- **DoD:** Dashboard hiển thị đúng bottleneck khi Calculate ra kết quả FAIL; unit test pass.

### 1.2 Risk Budget
- **Files:**
  - `packages/grid_engine/lib/src/engine/reverse_solver.dart` — verify hàm hiện tại `solveMaxInitialLot(...)` nhận `ConstraintSet` đã bao gồm `maxLossAmount`; nếu chưa, bổ sung field này vào constraint input path.
  - `app/lib/screens/risk_budget/risk_budget_screen.dart` (mới) — form đơn giản: Balance, Multiplier, Grid distance, Configured levels, **Max Loss ($)** là input chính (không phải advanced/optional như hiện tại).
- **DoD:** từ 1 input Max Loss, ra đúng 1 Max Initial Lot; test tái sử dụng bộ test đã có của `reverse_solver_test.dart`, thêm case dùng riêng `maxLossAmount` làm constraint duy nhất.

### 1.3 Max Levels Solver
- **Files:**
  - `packages/grid_engine/lib/src/engine/survival_engine.dart` — thêm hàm `int maxSurvivableLevels(StrategySpec spec, ConstraintSet constraints, {int upperBound = 50})` — chạy tuần tự, dừng ở level đầu tiên có bất kỳ constraint nào fail hoặc chạm stop-out.
  - `app/lib/screens/max_levels/max_levels_screen.dart` (mới).
- **DoD:** unit test: constraint chặt → kết quả nhỏ; không có constraint nào → dừng đúng ở stop-out; test overflow (upperBound đạt mà chưa fail → trả về upperBound kèm flag `reachedUpperBound: true`, không loop vô hạn).

### 1.4 Basket TP Simulator
- **Files:**
  - `packages/grid_engine/lib/src/engine/pnl_calculator.dart` — thêm hàm `double priceForTargetPnl(List<GridLevel> levels, double targetPnl, Direction direction, ExecutionSpec exec)` — giải ngược phương trình tuyến tính đã dùng cho `basketBreakevenPrice` (mục 3.6 trong build spec trước), với target khác 0.
  - `app/lib/widgets/basket_tp_table.dart` (mới) — bảng nhanh BE / +$50 / +$100 / +$200 (giá trị mốc có thể cấu hình).
- **DoD:** test `priceForTargetPnl(levels, 0, ...) == basketBreakevenPrice(levels, ...)` (regression tự nhiên: target=0 phải trùng hàm breakeven đã có); test với target dương/âm cho kết quả đúng chiều.

### 1.5 Existing Exposure — Synthetic Level 0
- **Files:**
  - `packages/grid_engine/lib/src/models/grid_level.dart` — không đổi model, chỉ đảm bảo field `isTriggered`/`index` chấp nhận `index = 0` hợp lệ cho level tổng hợp.
  - `packages/grid_engine/lib/src/engine/grid_builder.dart` — thêm hàm `List<GridLevel> buildWithExistingExposure({required double equity, required double floatingPnl, required double totalLots, required StrategySpec futureStrategy, ...})`. Logic: tạo 1 `GridLevel(index: 0, roundedLot: totalLots, entryPrice: <suy ra từ floatingPnl>, requiredMargin: 0, isTriggered: true)`, dùng `equity` (không phải `balance`) làm baseline cho toàn bộ tính toán margin/survival phía sau, rồi nối tiếp danh sách level build theo `futureStrategy` như bình thường.
  - `app/lib/screens/quick_calculator/` — thêm section "Existing Position (optional)" với đúng 3 input: Equity, Floating P/L, Total Lots.
- **DoD:** test: khi 3 input này để trống/0, kết quả phải **giống hệt** kết quả không có existing exposure (đảm bảo backward-compatible); test khi có exposure, `SurvivalEngine` dùng đúng `equity` làm baseline.

### 1.6 Gap Scenario — ExecutionMode.atMarket
- **Files:**
  - `packages/grid_engine/lib/src/models/execution_spec.dart` — thêm:
    ```dart
    enum ExecutionMode { sequential, atMarket }
    ```
    field mới `final ExecutionMode executionMode` (default `sequential` — không phá vỡ code cũ).
  - `packages/grid_engine/lib/src/engine/scenario_engine.dart` — khi `executionMode == atMarket` và scenario tính tại 1 mức giá cụ thể: xác định các level có `entryPrice` nằm trong khoảng giữa giá cũ và giá mới (khoảng gap), gán chung 1 `entryPrice = giá đầu tiên sau gap` cho toàn bộ các level đó thay vì entry theo level đã tính.
  - `app/lib/screens/gap_scenario/gap_scenario_screen.dart` (mới) — input: mức giá gap tới, toggle Sequential/At Market.
- **UI bắt buộc:** hiển thị disclaimer *"Actual execution may differ due to broker/order execution behavior."* ngay dưới kết quả.
- **DoD:** test: gap nhỏ hơn 1 level distance → kết quả giống `sequential`; gap qua nhiều level → tất cả level trong khoảng gap có cùng `entryPrice`.

### 1.7 Strategy Templates
- **Files:**
  - `app/lib/data/strategy_templates.dart` (mới) — danh sách const: `LowMultiplierTemplate (1.2x)`, `MediumMultiplierTemplate (1.5x)`, `HighMultiplierTemplate (2.0x)` — chỉ chứa `StrategySpec` mặc định, không chứa nhãn "safe/aggressive".
  - `app/lib/screens/quick_calculator/template_picker.dart` (mới) — khi chọn template, tự động chạy `SurvivalEngine` với balance mặc định để hiển thị Risk Preview (`Max DD X%, Survival Y/10`) trước khi user xác nhận áp dụng.
- **DoD:** UI review — không còn chữ nào gợi ý "an toàn/nguy hiểm" trong copy, chỉ có số liệu multiplier + risk preview.

---

## PHASE 2 — P1 Features (chỉ bắt đầu sau khi PHASE 1 đạt DoD toàn bộ)

### 2.1 Lock & Find Optimizer + Feasible Range
- **Files:**
  - `app/lib/screens/lock_and_find/lock_and_find_screen.dart` (mới) — UI icon khóa 🔒 trên từng field (Initial Lot, Multiplier, Grid Distance); yêu cầu tối thiểu 2/3 bị khóa trước khi bấm "Solve".
  - `packages/grid_engine/lib/src/engine/reverse_solver.dart` — thêm hàm tiện ích `List<FeasibleRow> sweepMultiplier(StrategySpec baseSpec, List<double> multiplierValues, ConstraintSet constraints)` — gọi `solveMaxInitialLot` lặp lại cho từng giá trị multiplier, trả về danh sách dòng bảng.
- **DoD:** test `sweepMultiplier` trả đúng số dòng = độ dài `multiplierValues`; mỗi dòng độc lập đúng như gọi `solveMaxInitialLot` đơn lẻ (regression check).

### 2.2 Sensitivity Analysis
- **Files:**
  - `packages/grid_engine/lib/src/engine/sensitivity_analyzer.dart` (mới, nhưng chỉ compose `SurvivalEngine`) — hàm `List<SensitivityResult> analyze(StrategySpec base, {double perturbPercent = 0.1})` chạy ±perturbPercent cho từng field số (multiplier, distance, spread, leverage), so sánh `survivableLevels` trước/sau.
  - `app/lib/screens/sensitivity/sensitivity_screen.dart` (mới) — hiển thị bar chart (fl_chart) độ nhạy từng tham số, sắp xếp giảm dần.
- **DoD:** test perturb đúng field, không ảnh hưởng field khác; kết quả sort giảm dần theo `abs(levelDelta)`.

### 2.3 Stress Test Matrix / Heatmap
- **Files:**
  - `packages/grid_engine/lib/src/engine/stress_matrix_builder.dart` (mới, compose `ScenarioEngine`) — hàm `List<List<StressCell>> build(StrategySpec base, List<ExecutionSpec> executionScenarios, List<double> priceOffsets)`.
  - `app/lib/widgets/stress_heatmap.dart` (mới) — grid N×M dùng `CustomPainter` hoặc `fl_chart` heatmap, mỗi ô ✓/⚠/❌ theo `constraintResults`.
- **DoD:** test ma trận kích thước đúng `executionScenarios.length × priceOffsets.length`; mỗi ô độc lập tính đúng như gọi `ScenarioEngine` trực tiếp.

### 2.4 Strategy Comparison / Battle Mode
- **Files:**
  - `app/lib/screens/comparison/comparison_screen.dart` (mới) — chạy engine 2 lần (2 `StrategySpec` từ Saved Strategies), hiển thị 2 cột song song các metric hiện có trên Dashboard.
  - Không cần thay đổi engine — chỉ compose kết quả `CalculationResult` 2 lần.
- **DoD:** UI hiển thị đúng, có dòng tóm tắt dạng "Lower modeled drawdown: [A/B]" — chỉ so sánh số liệu, không dùng chữ "Winner"/"Better".

### 2.5 Custom Grid Builder
- **Files:**
  - `packages/grid_engine/lib/src/models/strategy_spec.dart` — verify `GridDistanceMode.manual` đã support `manualDistances`; nếu Custom Grid Builder cần cả entry lẫn lot tùy ý (không theo công thức multiplier), thêm `GridDistanceMode.custom` + field `List<GridLevel>? customLevels` (override hoàn toàn phần build tự động).
  - `packages/grid_engine/lib/src/engine/grid_builder.dart` — khi `distanceMode == custom`, bỏ qua công thức `initialLot × multiplier^n`, dùng thẳng `customLevels` (chỉ tính lại margin/P/L, không tính lại lot/entry).
  - `app/lib/screens/custom_grid/custom_grid_builder_screen.dart` (mới) — form nhập từng level (Entry, Lot) dạng list editable.
- **DoD:** test `distanceMode.custom` cho kết quả margin/P/L đúng dựa trên input tùy ý; test không phá vỡ `fixed`/`manual` mode hiện có.

### 2.6 Strategy Versioning
- **Files:**
  - `app/lib/persistence/hive_repository.dart` — mở rộng model `SavedStrategy` (Hive adapter) thêm field `String? parentId`, `int versionNumber`.
  - `app/lib/screens/saved_strategies/version_history_screen.dart` (mới) — hiển thị cây version, mỗi node có delta chính (so `CalculationResult` giữa version hiện tại và version cha).
- **DoD:** test Hive: save version con với `parentId` trỏ đúng; load lại toàn bộ cây không mất liên kết; migration cho data cũ (chưa có `parentId`) không crash (`parentId = null` mặc định).

### 2.7 ATR Reference — chỉnh câu chữ
- **Files:** field/text hiện có trong Dashboard hiển thị Survival/ATR ratio — chỉ sửa chuỗi hiển thị + thêm chú thích cố định *"This is a volatility comparison, not a safety prediction."*
- **DoD:** review copy toàn bộ, không còn cụm "an toàn"/"còn bao nhiêu pips an toàn" ở bất kỳ đâu liên quan ATR.

---

## PHASE 3 — Không làm (nhắc lại để agent code không tự ý thêm)

Không implement bất kỳ mục nào sau nếu không có yêu cầu rõ ràng mới: Risk Score 0–100, Monte Carlo Probability, Local Notification/Market Alert dạng tự động, Cloud Sync/Team Sharing/White-label, App Lock, News Feed, Social Feed, Live Price Feed, Historical OHLC Backtest, Prop-firm templates, Multi-symbol correlation.

---

## Checklist tổng hợp theo thứ tự PR (agent code bám theo đúng thứ tự này)

```
[ ] PHASE 0.1  Golden cases scaffold + loader (test không skip, phân biệt PLACEHOLDER)
[ ] PHASE 0.2  MarginCalculator hỗ trợ leverage tiers (optional, backward-compatible)
[ ] PHASE 0.3  Network security config
[ ] PHASE 0.4  AdMob placement fix (5 screens)
[ ] PHASE 0.5  APK size audit + split-per-abi
[ ] PHASE 0.6  i18n hygiene + Privacy/ToS scaffold + AdMob real ID qua config
────────────────────────────────────────────
[ ] PHASE 1.1  Failure/Bottleneck Explanation (forward)
[ ] PHASE 1.2  Risk Budget
[ ] PHASE 1.3  Max Levels Solver
[ ] PHASE 1.4  Basket TP Simulator
[ ] PHASE 1.5  Existing Exposure (synthetic Level 0)
[ ] PHASE 1.6  Gap Scenario (ExecutionMode.atMarket)
[ ] PHASE 1.7  Strategy Templates
────────────────────────────────────────────
[ ] PHASE 2.1  Lock & Find Optimizer + Feasible Range
[ ] PHASE 2.2  Sensitivity Analysis
[ ] PHASE 2.3  Stress Test Matrix / Heatmap
[ ] PHASE 2.4  Strategy Comparison / Battle Mode
[ ] PHASE 2.5  Custom Grid Builder
[ ] PHASE 2.6  Strategy Versioning
[ ] PHASE 2.7  ATR Reference copy fix
```

**Quy tắc PR:** mỗi dòng checklist = 1 PR riêng, có test riêng, DoD đạt mới merge. Không gộp PHASE 1.x nhiều mục vào 1 PR. Mọi thay đổi trong `packages/grid_engine/` bắt buộc có unit test đi kèm trong cùng PR — không có ngoại lệ, kể cả thay đổi nhỏ như thêm 1 enum value.