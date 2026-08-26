# BUILD SPEC — Grid Survival Simulator (Flutter, offline-first)

> Tài liệu này dành cho **agent code**. Đây là bản kỹ thuật thực thi, tổng hợp từ plan1.md → plan1_final.md → 5 vòng review phản biện. Không cần đọc lại các file khác — mọi quyết định cuối cùng đã chốt ở đây.
> Ngôn ngữ code/biến: tiếng Anh. Ngôn ngữ UI mặc định: tiếng Việt (có khung sẵn cho i18n).

---

## 0. Product Thesis (đã chốt, không bàn lại)

> **Grid Survival Simulator** là công cụ phân tích rủi ro offline-first giúp trader stress-test một chiến lược Grid trước khi chạy nó: chiến lược tạo ra bao nhiêu exposure & drawdown ở từng mức giá, basket breakeven nằm ở đâu, cần hồi bao xa để thoát, và tài khoản còn bao nhiêu buffer trước các risk constraint mà chính trader tự đặt ra.
>
> App **không** dự đoán thị trường, **không** đưa tín hiệu giao dịch, **không** tuyên bố chiến lược "an toàn". App chỉ mô hình hóa hậu quả của các giả định do trader cung cấp.

**Tagline:** "Stress-test your Grid strategy before the market does." — tuyệt đối tránh tagline kiểu "biết trước khi tài khoản chết" (quá tiêu cực, gợi cảm giác gambling/recovery).

**Không dùng từ "Martingale" ở app title, subtitle, ASO metadata, screenshot store.** Chỉ dùng trong nội dung mô tả tính năng bên trong app (nơi ít rủi ro policy hơn). Cũng tránh các từ: profit, recovery, guaranteed, safe, win, signals, investment advice, automated trading — trong mọi copy hướng ra store.

Mọi màn hình kết quả **bắt buộc** có dòng: *"Analytical/educational tool. Not financial advice. Actual broker outcome may differ."*

---

## 1. Kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────┐
│                          UI LAYER (Flutter widgets)       │
│  Dashboard | Price Ladder | Grid Card List | What-if      │
│  Slider | Reverse Mode | Constraint Editor | Save/Share   │
└───────────────────────────▲─────────────────────────────┘
                             │ (state mgmt: Riverpod)
┌───────────────────────────┴─────────────────────────────┐
│                    APPLICATION / STATE LAYER               │
│   Providers: StrategyProvider, ScenarioProvider,           │
│   ConstraintProvider, SavedStrategiesProvider               │
└───────────────────────────▲─────────────────────────────┘
                             │ (pure Dart, no Flutter import)
┌───────────────────────────┴─────────────────────────────┐
│                      CORE ENGINE (pure Dart package)        │
│  models/  → AccountSpec, InstrumentSpec, ExecutionSpec,     │
│             StrategySpec, GridLevel, ConstraintSet          │
│  engine/  → GridBuilder, MarginCalculator, PnlCalculator,   │
│             SurvivalEngine, ScenarioEngine, ReverseSolver,  │
│             ConstraintEvaluator                              │
│  NO dependency on Flutter, Hive, or UI. 100% unit-testable. │
└───────────────────────────▲─────────────────────────────┘
                             │
┌───────────────────────────┴─────────────────────────────┐
│                    PERSISTENCE (Hive, offline)              │
│  Boxes: saved_strategies, instrument_specs, app_settings     │
└─────────────────────────────────────────────────────────┘
```

**Nguyên tắc bất di bất dịch:** Core Engine là một package Dart thuần (`packages/grid_engine/`), tách biệt hoàn toàn khỏi Flutter. Agent code phải viết engine này **trước**, có bộ test đầy đủ chạy pass, rồi mới build UI gọi vào engine. Không viết công thức tính toán trực tiếp trong widget.

### Cấu trúc thư mục đề xuất

```
grid_survival_simulator/
├── packages/
│   └── grid_engine/                 # pure Dart package, không phụ thuộc Flutter
│       ├── lib/
│       │   ├── src/
│       │   │   ├── models/
│       │   │   │   ├── account_spec.dart
│       │   │   │   ├── instrument_spec.dart
│       │   │   │   ├── execution_spec.dart
│       │   │   │   ├── strategy_spec.dart
│       │   │   │   ├── grid_level.dart
│       │   │   │   ├── constraint_set.dart
│       │   │   │   └── calculation_result.dart
│       │   │   ├── engine/
│       │   │   │   ├── grid_builder.dart
│       │   │   │   ├── margin_calculator.dart
│       │   │   │   ├── pnl_calculator.dart
│       │   │   │   ├── survival_engine.dart
│       │   │   │   ├── scenario_engine.dart
│       │   │   │   ├── reverse_solver.dart
│       │   │   │   └── constraint_evaluator.dart
│       │   │   └── rounding/
│       │   │       └── lot_rounding.dart
│       │   └── grid_engine.dart     # public export file
│       └── test/
│           ├── golden_cases/
│           │   └── golden_cases.json   # placeholder fixtures — xem mục 8
│           ├── margin_calculator_test.dart
│           ├── survival_engine_test.dart
│           ├── reverse_solver_test.dart
│           └── edge_cases_test.dart
└── app/                             # Flutter app
    ├── lib/
    │   ├── main.dart
    │   ├── l10n/                    # vi + en
    │   ├── theme/
    │   ├── state/                   # Riverpod providers
    │   ├── screens/
    │   │   ├── quick_calculator/
    │   │   ├── dashboard/
    │   │   ├── price_ladder/
    │   │   ├── what_if/
    │   │   ├── reverse_mode/
    │   │   ├── constraints/
    │   │   ├── saved_strategies/
    │   │   └── share/
    │   ├── widgets/
    │   │   ├── grid_level_card.dart
    │   │   ├── price_ladder_chart.dart   # fl_chart
    │   │   ├── what_if_slider.dart
    │   │   ├── constraint_result_tile.dart
    │   │   └── assumptions_panel.dart
    │   └── persistence/
    │       └── hive_repository.dart
    └── test/
```

### Tech stack (chốt)
- **Flutter** (state management: **Riverpod** — lý do: tách rõ Core Engine gọi qua provider, dễ test, không cần BuildContext trong logic).
- **Hive** — lưu Saved Strategies, Instrument Specs, App Settings (offline, không dùng SQL vì data đơn giản, key-value phù hợp).
- **fl_chart** — Price Ladder visual, Risk Curve, Scenario chart.
- **screenshot** + **share_plus** — chức năng Share as image (không làm PDF ở MVP).
- **intl** / Flutter's built-in l10n — tiếng Việt mặc định, tiếng Anh dự phòng.
- Không dùng package tính toán tài chính bên thứ 3 — toàn bộ công thức viết tay trong `grid_engine` để kiểm soát độ chính xác và test được.

---

## 2. Data Model (Core Engine)

### 2.1 AccountSpec
```dart
class AccountSpec {
  final double balance;
  final double equity;           // mặc định = balance nếu không có lệnh mở khác
  final String accountCurrency;  // MVP: chỉ "USD" — nếu khác, UI chặn + cảnh báo
  final double leverage;         // vd 500 (nghĩa là 1:500)
  final double stopOutLevelPercent; // vd 20 (%)
  final double marginCallLevelPercent; // vd 100 (%), optional/nullable
}
```
*Không có field "accountType: Cent/Standard".* Cent account chỉ là biến thể của `ContractSize` + `accountCurrency` (xem review phản biện: đừng special-case). Nếu cần hỗ trợ Cent, user chọn Instrument profile có `contractSize` tương ứng — engine không biết khái niệm "Cent" tồn tại.

### 2.2 InstrumentSpec
```dart
class InstrumentSpec {
  final String symbol;            // "XAUUSD" | "EURUSD" (MVP chỉ 2 symbol)
  final double contractSize;      // XAUUSD: 100; EURUSD: 100000
  final double tickSize;          // đơn vị giá nhỏ nhất
  final double tickValuePerLot;   // giá trị 1 tick với 1 lot chuẩn
  final int digits;               // số chữ số thập phân giá
  final double lotMin;
  final double lotMax;
  final double lotStep;
  final double marginPercent;     // % margin yêu cầu theo notional (đa số Forex/Gold dùng leverage tài khoản; nhưng để mở rộng index/crypto thì cho phép override riêng theo symbol)
}
```
MVP ship sẵn 2 InstrumentSpec: **XAUUSD** và **EURUSD**, hard-code default values nhưng đọc từ Hive box `instrument_specs` (để sau này update mà không cần rebuild app). Kiến trúc phải cho phép thêm symbol mới chỉ bằng cách thêm data — không sửa engine.

### 2.3 ExecutionSpec (bắt buộc từ MVP, không optional trong model — chỉ optional trong UI)
```dart
class ExecutionSpec {
  final double spreadPoints;         // spread giả định, tính theo point
  final double commissionPerLot;     // default 0
  final double swapPerLotPerDay;     // default 0
  final int holdingDays;             // default 0 — dùng khi bật swap
  final HedgeMode hedgeMode;         // enum: netting | hedgingFull | hedgingReduced
  final double hedgedMarginFactor;   // 0.0–1.0, chỉ dùng khi hedgingReduced (user tự nhập %)
}

enum HedgeMode { netting, hedgingFull, hedgingReduced }
```
**Spread bắt buộc áp dụng vào entry/close price:** Buy → entry theo Ask (mid + spread/2), close theo Bid (mid - spread/2); Sell → ngược lại. Đây là lỗi phổ biến nhất khiến kết quả XAUUSD lệch — bắt buộc đúng ngay từ đầu, không để "thêm sau".

### 2.4 StrategySpec
```dart
class StrategySpec {
  final Direction direction;         // buy | sell
  final double initialLot;
  final double multiplier;
  final GridDistanceMode distanceMode; // fixed | manual (MVP); atr/percent → V1.5
  final double fixedDistance;        // dùng khi distanceMode = fixed
  final List<double>? manualDistances; // dùng khi distanceMode = manual — độ dài = levels-1
  final int levels;                  // configured levels (xem 2.5 phân biệt triggered)
  final LotRoundingMode roundingMode; // round | floor | ceiling
}

enum Direction { buy, sell }
enum GridDistanceMode { fixed, manual }
enum LotRoundingMode { round, floor, ceiling }
```

### 2.5 GridLevel (model linh hoạt, không phải hàng cố định trong bảng)
```dart
class GridLevel {
  final int index;                // 1-based
  final double rawLot;            // trước khi làm tròn
  final double roundedLot;        // sau khi làm tròn theo lotStep
  final double entryPrice;
  final double cumulativeLot;
  final double requiredMargin;
  final double floatingPnl;       // tại thời điểm định giá hiện tại (dùng trong scenario)
  final bool isTriggered;         // phân biệt "configured" vs "triggered" — quan trọng khi scenario
}
```
**Lưu ý bắt buộc:** thuật ngữ trong toàn bộ UI phải phân biệt **"Configured levels"** (số level user cấu hình, vd 10) và **"Triggered levels"** (số level đã thực sự bị kích hoạt tại một mức giá nhất định trong What-if/Scenario). Không dùng lẫn lộn "level" cho cả hai nghĩa.

### 2.6 ConstraintSet (Risk Constraint Engine — thay Risk Score màu)
```dart
class ConstraintSet {
  final double? maxDrawdownPercent;
  final double? maxTotalLot;
  final double? minMarginLevelPercent;
  final double? maxLossAmount;
}

class ConstraintCheckResult {
  final String constraintName;
  final bool passed;
  final int? violatedAtLevel;      // null nếu passed
  final String detailMessage;      // vd "Max DD 30% vi phạm tại Level 7 (32.1%)"
}
```
**Không có bất kỳ nhãn "SAFE/LOW/HIGH/Risk Score màu" nào trong engine hoặc UI.** Chỉ hiển thị PASS/FAIL khách quan theo constraint do chính user nhập. Nếu user chưa nhập constraint nào, hiển thị "No constraints set — enter your own limits to check" kèm 4 gợi ý giá trị mặc định phổ biến (xem mục 5.3) để tránh màn hình trắng vô dụng cho người mới.

### 2.7 CalculationResult (output tổng hợp)
```dart
class CalculationResult {
  final List<GridLevel> levels;
  final double totalExposureLots;
  final double averageEntryPrice;
  final double basketBreakevenPrice;     // giá cần để basket hòa vốn (tính cả spread/commission)
  final double rebindDistanceToBreakeven; // pips/$ cần hồi để hòa vốn
  final int survivableLevels;             // deterministic
  final double? estimatedStopOutPrice;    // null nếu không đạt trong configured levels
  final double maxDrawdownPercent;
  final List<ConstraintCheckResult> constraintResults;
  final List<String> assumptionsUsed;     // string list hiển thị minh bạch — xem mục 6
}
```

---

## 3. Công thức tính toán (Engine Spec — bắt buộc đúng, có unit test đi kèm)

### 3.1 Lot theo level
```
rawLot(n) = initialLot × multiplier^(n-1)
roundedLot(n) = applyRounding(rawLot(n), lotStep, roundingMode)
```
`applyRounding`: Round = làm tròn gần nhất theo bội số lotStep; Floor = làm tròn xuống; Ceiling = làm tròn lên. Luôn clamp trong khoảng [lotMin, lotMax]. Nếu roundedLot(n) khác rawLot(n) quá X% (threshold cấu hình, mặc định 5%), thêm cảnh báo vào `assumptionsUsed`.

### 3.2 Entry price theo level (áp dụng spread)
```
midPrice(1) = currentPrice
midPrice(n) = midPrice(n-1) ± distance(n-1)   // trừ nếu buy grid xuống, cộng nếu sell grid lên

entryPrice(n) = direction == buy
  ? midPrice(n) + spreadPoints/2 * tickSize   // vào theo Ask
  : midPrice(n) - spreadPoints/2 * tickSize   // vào theo Bid
```

### 3.3 Margin required per level
```
notional(n) = roundedLot(n) × contractSize × entryPrice(n)
requiredMargin(n) = notional(n) / leverage
```
Nếu `hedgeMode == hedgingReduced`: margin của phần lot đối ứng (min(buyLot, sellLot)) nhân với `hedgedMarginFactor` thay vì full margin. Nếu `netting`: chỉ tính margin theo net position. MVP grid thường một chiều nên chủ yếu dùng `hedgingFull` mặc định — nhưng model phải support cả 3 mode để không phải refactor sau.

### 3.4 Cumulative exposure & average entry
```
cumulativeLot(n) = Σ roundedLot(i) for i in 1..n
averageEntryPrice(n) = Σ (roundedLot(i) × entryPrice(i)) / cumulativeLot(n)
```

### 3.5 Floating P/L tại một mức giá giả định (dùng chung cho Survival + Scenario + What-if)
```
closePrice = direction == buy
  ? assumedPrice - spreadPoints/2 * tickSize   // đóng Buy theo Bid
  : assumedPrice + spreadPoints/2 * tickSize   // đóng Sell theo Ask

pnlPerLevel(n) = (closePrice - entryPrice(n)) × direction_sign × contractSize × roundedLot(n)
              - commissionPerLot × roundedLot(n)
              - swapPerLotPerDay × roundedLot(n) × holdingDays

totalFloatingPnl = Σ pnlPerLevel(n) for triggered levels
```

### 3.6 Basket Breakeven & Rebound Distance
```
basketBreakevenPrice = giá mà tại đó totalFloatingPnl(price) == 0
  (giải bằng công thức tuyến tính đơn giản vì P/L tuyến tính theo giá khi không còn level mới trigger:
   priceBE = averageEntryPrice ± (totalCommissionAndSwap / (cumulativeLot × contractSize)))

rebindDistance = |basketBreakevenPrice - currentPrice|   (tính cả pips và $ quy đổi)
```

### 3.7 Margin Level % và Survival (deterministic)
```
marginLevelPercent(n) = (equity + totalFloatingPnl(n)) / totalRequiredMargin(n) × 100
```
Duyệt tuần tự qua các level theo `distance`, tại mỗi level tính lại `marginLevelPercent`. **Survivable Levels** = số level lớn nhất mà `marginLevelPercent > stopOutLevelPercent`. **Estimated Stop-out Price** = giá tại đó `marginLevelPercent` chạm `stopOutLevelPercent` (nội suy tuyến tính giữa 2 level liền kề nếu cần độ chính xác cao hơn theo level).

Output luôn diễn đạt bằng câu: *"Account reaches estimated stop-out after ~$X adverse price movement, under these assumptions."* — không bao giờ nói "Account sẽ cháy tại $X".

### 3.8 Survival / ATR Ratio (thay cho Risk Score, optional field nếu có ATR reference)
```
survivalRatio = rebindDistanceOrStopOutDistance / atrReference
```
Hiển thị dạng số thô: *"Survival distance ≈ 1.47× vs 30-day ATR ($32)"*. **Không gán nhãn** "an toàn/nguy hiểm" theo ratio — chỉ hiển thị con số và một chú thích trung lập dạng thang đo mô tả (không phải đánh giá): `<1× rất hẹp so với biến động gần đây`, `1–2× hẹp`, `2–3× vừa`, `>3× rộng`. ATR reference trong MVP là **giá trị user tự nhập thủ công** (không tự fetch — giữ nguyên offline). Field này optional, ẩn nếu user không nhập.

### 3.9 Reverse Solver — MỘT bài toán duy nhất, không mơ hồ
Chỉ giải đúng 1 dạng bài toán (không "tối ưu chung chung"):

> **Input:** Balance, Multiplier (cố định hoặc range), Grid distance, Configured levels, và **ít nhất 1 hard constraint** (Max DD % hoặc Min Margin Level % hoặc Max Total Lot).
> **Output:** **Maximum Initial Lot** thỏa mãn toàn bộ constraint đã nhập, tại configured levels đã cho.

Thuật toán: **binary search** trên `initialLot` trong khoảng [lotMin, lotMax] — với mỗi giá trị thử, chạy lại toàn bộ `SurvivalEngine` + `ConstraintEvaluator`, kiểm tra PASS/FAIL, thu hẹp khoảng tìm kiếm. Độ chính xác dừng ở bội số của `lotStep`. Nếu không constraint nào được nhập, Reverse Mode disable và yêu cầu user nhập ít nhất 1 constraint trước khi chạy — tránh bài toán vô nghiệm/mơ hồ như review 1 đã cảnh báo.

---

## 4. Scenario Engine (What-if — UX core, không phải phụ)

Không chỉ "kéo slider → xem 1 con số". Bắt buộc implement dạng **Scenario Table + Slider liên động**:

```dart
class ScenarioPoint {
  final double priceOffset;        // vd -20, -40, -60 ($ hoặc theo digits của symbol)
  final int triggeredLevels;
  final double drawdownPercent;
  final double marginLevelPercent;
  final double floatingPnl;
  final bool constraintsAllPassed;
}
```

`ScenarioEngine.generate(strategySpec, step, range)` trả về danh sách `ScenarioPoint` tại các mốc giá cách đều (vd mỗi $10 hoặc theo % ATR nếu có). Slider UI đọc trực tiếp từ danh sách này (hoặc nội suy) để **mọi metric trên Dashboard cập nhật realtime** khi kéo — đây là điểm khác biệt biến "calculator" thành "simulator", ưu tiên implement cao nhất về UX sau khi engine đúng.

---

## 5. UI/UX Screens (chốt danh sách + nội dung từng màn)

### 5.1 Quick Calculator (màn hình nhập liệu)
Input theo nhóm rõ ràng (không nhồi 20 field cùng lúc — dùng section collapsible):
- **Symbol** (dropdown: XAUUSD, EURUSD) → tự điền InstrumentSpec mặc định, cho phép override
- **Direction** (Buy/Sell)
- **Account**: Balance, Leverage, Stop-out %, Account currency (khóa = USD, hiển thị disable + tooltip lý do)
- **Strategy**: Initial lot, Multiplier, Grid distance (Fixed), Levels, Rounding mode
- **Execution (Advanced, collapsed mặc định)**: Spread, Commission, Swap, Holding days, Hedge mode
- **Constraints (Advanced, collapsed mặc định)**: Max DD%, Max total lot, Min margin level%, Max loss $ — kèm placeholder gợi ý (vd "Nhiều trader dùng 20-30%" — **chỉ là placeholder text tham khảo, không phải khuyến nghị của app**)

Nút **"Calculate"** → chạy Pre-flight Check trước (mục 5.2), rồi chuyển sang Dashboard.

### 5.2 Pre-flight Check (chạy trước khi hiển thị kết quả đầy đủ)
Checklist dạng list, mỗi dòng ✓/⚠️/❌:
```
✓ Margin requirement < Free margin tại Level 1
⚠ Lot rounding: Level 4 lot bị làm tròn từ 0.0225 → 0.02 (giảm ~11% so với lý thuyết)
❌ Configured levels (10) vượt quá điểm Stop-out ước tính (chỉ đạt Level 7)
❌ Max DD constraint (20%) bị vi phạm tại Level 6 (23.4%)
```
Nếu có ❌, vẫn cho phép user xem tiếp Dashboard (không chặn cứng) nhưng banner cảnh báo đỏ ở đầu Dashboard.

### 5.3 Risk Dashboard (màn hình chính sau khi Calculate)
5 số lớn, không dùng màu xanh/vàng/đỏ đánh giá — chỉ dùng màu để phân nhóm neutral (vd xám cho "chưa vi phạm", đỏ cho "đã vi phạm constraint cụ thể user đặt", không có "an toàn"):
1. Survivable Levels (X / configured Y)
2. Max Drawdown %
3. Estimated Stop-out Price (kèm text "estimated", không khẳng định)
4. **Basket Breakeven + Rebound Distance** (đồng cấp độ quan trọng với #1, theo mục phản biện đã nêu — không giả định cái nào quan trọng hơn)
5. Total Exposure (lots)

Bên dưới: kết quả Constraint Check (PASS/FAIL list), nút mở **Price Ladder**, nút mở **What-if Slider**.

### 5.4 Price Ladder (visual chính, dùng fl_chart hoặc custom paint)
Trục giá thẳng đứng, mỗi level là 1 điểm/mốc:
```
3350 ── L1  0.01
3340 ── L2  0.015
3330 ── L3  0.022
    ⋮
      Average Entry ── 3318.4
      Basket BE ── 3324.1
      Est. Stop-out ── 3266.0
```
Tap vào từng mốc → bung chi tiết Margin/Floating P/L/Swap (Card Accordion behavior).

### 5.5 What-if Slider
Slider ngang, mốc 0 = giá hiện tại. Kéo trái/phải → toàn bộ số trên Dashboard (Equity, Margin Level, Triggered Levels, Floating P/L) cập nhật realtime từ `ScenarioEngine`. Không cần bấm "Calculate" lại.

**Quick State Inspector** (thay hoàn toàn Local Alert/Widget — đã bị 5/5 review bác bỏ): nút nổi "Nhập giá hiện tại" → popup nhập 1 số → hiển thị ngay: *"Ở mức giá này, bạn đang ở Level 4/10. Floating Loss: $240. Margin Level: 320%. Room còn lại trước Stop-out: 25 pips."* — không notification, không cần feed giá, không polling.

### 5.6 Reverse Mode
Input: Balance, Multiplier, Grid distance, Configured levels + ít nhất 1 constraint (bắt buộc). Output: 1 số duy nhất — **Maximum Initial Lot** — kèm giải thích ngắn constraint nào đang là "bottleneck" (constraint chặt nhất quyết định kết quả).

### 5.7 Save/Load Strategy
Lưu tối đa 5 strategy (MVP) vào Hive, mỗi entry gồm toàn bộ Spec + timestamp + tên do user đặt.

### 5.8 Share as Image
Render 1 card tổng hợp (Symbol, Strategy params, Survivable levels, Max DD, Basket BE, Est. stop-out) thành ảnh PNG qua package `screenshot`, share qua `share_plus`. Không làm PDF ở MVP.

### 5.9 Assumptions Panel (bắt buộc xuất hiện ở mọi màn hình kết quả)
Danh sách text đơn giản, generate động từ `assumptionsUsed`:
```
- Spread: 30 points (user-defined)
- Commission: $0/lot (not applied)
- Hedge mode: Hedging — Full margin
- Rounding: Round to nearest lot step
- Estimated stop-out uses linear interpolation between levels
- This is an indicative estimate. Actual broker outcome may differ.
```

---

## 6. Positioning / Policy Compliance Checklist (Gate #0 — phải pass trước khi submit store)

- [ ] Không xuất hiện "Martingale" ở: App name, Subtitle, Store description, Keywords/ASO metadata, Screenshot text
- [ ] Không xuất hiện các từ: profit, recovery, guaranteed, safe, win, signals, investment advice, automated trading — trong mọi copy hướng ra store
- [ ] Có disclaimer "Not financial advice" hiển thị ở: màn hình onboarding lần đầu + mọi màn hình kết quả tính toán
- [ ] Không dùng nhãn đánh giá "An toàn/Nguy hiểm" bất kỳ đâu trong app — chỉ dùng số liệu khách quan + PASS/FAIL theo constraint do chính user đặt
- [ ] Kiểm tra Google Play Financial Services policy + Apple App Store trading/financial app rules trước khi submit (việc research này nằm ngoài phạm vi agent code, do người phụ trách sản phẩm thực hiện trước Gate #0)

---

## 7. MVP Scope — chốt cuối (agent code build đúng phạm vi này, không tự thêm)

### Trong MVP
- Symbol: **XAUUSD + EURUSD** (kiến trúc mở rộng được, nhưng chỉ ship 2 symbol)
- Fixed grid + Multiplier + Manual override từng level (distance thủ công)
- Lot rounding (Round/Floor/Ceiling) hiển thị rõ + cảnh báo impact
- Spread, Commission, Swap (optional, engine support từ đầu, mặc định 0/ẩn trong Advanced)
- Hedge mode (Netting / Hedging Full / Hedging Reduced với factor %)
- Survival Engine (deterministic) + Survival/ATR ratio (optional, user nhập ATR thủ công)
- Basket Breakeven + Rebound Distance
- Price Ladder Visual
- What-if Slider realtime + Scenario table
- Reverse Mode (1 dạng: Max Initial Lot theo constraint)
- Risk Constraint Engine (PASS/FAIL, không màu sắc đánh giá)
- Pre-flight Check
- Quick State Inspector (nhập giá thủ công → trạng thái ngay lập tức)
- Save/Load tối đa 5 strategies (Hive)
- Assumptions Panel minh bạch
- Share as image

### Ngoài MVP (không build)
Monte Carlo/probability, Risk Score màu, Broker Presets cứng theo tên broker, Local Alert/Widget tự động, Prop-firm rule template, Dynamic/ATR-based grid distance, Multi-pair/correlation exposure, Backtest với OHLC lịch sử, PDF export, Partial close/scale-out logic.

### V1.5 (sau khi có data usage thật)
Dynamic Grid (%/ATR-based), Strategy comparison A/B, Stress test presets (spread×2, spread×5, leverage↓), Custom Broker Profile mở rộng (không phải preset cứng theo tên broker — user tự nhập rồi lưu làm profile cá nhân), thêm symbol (GBPUSD, US30, BTCUSD).

### V2 (cần research riêng, đổi tên nếu làm)
Nếu làm mô hình xác suất, **bắt buộc đổi tên thành "Market Stress Simulation"**, không gọi "probability of account blow-up". Phải có disclaimer "model-based estimate, not a forecast" và chỉ dựa trên historical volatility scenario (1-day/3-day/7-day adverse move), không claim % xác suất tuyệt đối.

---

## 8. Testing & Validation Plan (agent code thực hiện được phần nào, phần nào cần người)

### 8.1 Agent code TỰ làm được
- Unit test cho từng hàm engine theo công thức mục 3 (margin, P/L, basket BE, survival, reverse solver)
- Edge case test bắt buộc: `multiplier = 1`, `levels = 0`, lot vượt `lotMax`, số cực lớn (`levels = 100` với multiplier cao) → phải có overflow protection và validation, không crash, không silent wrong number
- Property-based test: `roundedLot` luôn là bội số hợp lệ của `lotStep` và nằm trong [lotMin, lotMax]
- Golden-value test suite chạy trên **fixtures giả lập** (`test/golden_cases/golden_cases.json`) — agent code tạo cấu trúc file test đúng format, nhưng **giá trị placeholder**, đánh dấu rõ `"status": "PLACEHOLDER — cần thay bằng số liệu MT5 thật"`
- Không dùng floating-point equality để so sánh threshold (dùng epsilon comparison)
- Deterministic rounding (không phụ thuộc locale/platform)

### 8.2 Cần người thực hiện (blocking dependency trước khi launch, KHÔNG phải việc của agent code)
- Thu thập 30–50 case thật: chụp màn hình Order Calculator / lịch sử lệnh MT4/MT5 từ tài khoản thật (Exness, IC Markets...), điền vào đúng format `golden_cases.json` mà agent code đã dựng sẵn
- Chạy lại test suite với data thật, yêu cầu sai số margin/stop-out < 0.5–1%
- Beta test với nhóm trader thật đối chiếu tài khoản thật của họ

**Agent code cần định nghĩa rõ format JSON fixture ngay từ đầu** (input spec đầy đủ + expected output) để bước điền data thật sau này không cần sửa code, chỉ cần điền số liệu.

---

## 9. Thứ tự công việc cho agent code (theo phase, mỗi phase có Definition of Done)

**Phase A — Core Engine**
- Viết đầy đủ models (mục 2) + formulas (mục 3) trong `packages/grid_engine/`
- DoD: tất cả unit test ở mục 8.1 pass; engine build độc lập không phụ thuộc Flutter

**Phase B — Scenario & Reverse**
- ScenarioEngine, ReverseSolver (binary search), ConstraintEvaluator
- DoD: test binary search hội tụ đúng trong ≤ 20 iteration cho mọi input hợp lệ; test constraint PASS/FAIL đúng với case biết trước

**Phase C — Persistence**
- Hive setup, model adapters cho StrategySpec (serialize toàn bộ spec để save/load)
- DoD: save → load → so khớp 100% với object gốc

**Phase D — UI cơ bản**
- Quick Calculator → Pre-flight Check → Dashboard (không có Price Ladder/Slider chart trước, chỉ số + list)
- DoD: luồng nhập → tính → hiển thị chạy end-to-end trên engine thật (không mock)

**Phase E — Visual & Interactivity**
- Price Ladder (fl_chart/custom paint), What-if Slider realtime, Quick State Inspector
- DoD: kéo slider cập nhật toàn bộ dashboard trong < 100ms (thuần Dart tính toán, không cần optimize nặng)

**Phase F — Reverse Mode UI, Save/Load UI, Share as image**
- DoD: đầy đủ luồng, ảnh share xuất đúng thông tin, không lỗi khi thiếu constraint (disable Reverse Mode với thông báo rõ)

**Phase G — i18n, Assumptions Panel, Policy Compliance copy**
- DoD: checklist mục 6 pass toàn bộ; UI có cả vi/en (mặc định vi)

**Phase H — Golden fixture scaffolding**
- Tạo `golden_cases.json` với ≥5 placeholder case đúng format, viết test đọc từ file này
- DoD: test suite chạy được ngay cả khi data là placeholder (test tự skip/warn rõ ràng thay vì fail im lặng)

Sau Phase H, bàn giao lại cho người phụ trách sản phẩm để: (1) điền golden cases thật, (2) chạy policy/store compliance research thật, (3) beta test — đây là các bước **ngoài phạm vi agent code**.