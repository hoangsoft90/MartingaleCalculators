# PLAN2 FINAL — Tính năng cần bổ sung cho Grid Survival Simulator

> Tổng hợp từ: `features.md` (codebase MVP hiện tại) + `plan2.md` + 3 bản review AI độc lập + phân tích phản biện cuối.
> Mục tiêu: một danh sách tính năng bổ sung **đã chốt**, có thứ tự ưu tiên, kèm ghi chú kỹ thuật tái sử dụng engine hiện có — sẵn sàng đưa cho agent code.
> Nguyên tắc xuyên suốt: **không thêm feature mới nào trước khi qua Gate 0 (Calculation Audit).**

---

## 0. Gate 0 — Calculation Audit (bắt buộc, chặn mọi roadmap bên dưới)

Đây là điểm đồng thuận tuyệt đối của cả plan2.md và cả 3 review. Hiện trạng theo `features.md`:
- Unit tests: 37 (chỉ chứng minh code đúng theo công thức **tự viết**, chưa chứng minh khớp broker thật)
- Golden cases: 12 scenario, **vẫn là placeholder**
- Validation tests: 6 tests, **skip khi chưa có data thật**
- `MarginCalculator`: `notional / leverage` — chưa xử lý Dynamic Leverage, Hedging margin theo từng broker
- `Estimated Stop-out Price`: dùng interpolation — cần đối chiếu thực tế

### Việc cần làm (theo thứ tự)
1. Thu thập **30–50 scenario thật** từ lịch sử khớp lệnh / Order Calculator trên MT4/MT5 (Exness, IC Markets, XM, Pepperstone), gồm cả Standard và Cent account.
2. Nhập cùng thông số vào engine hiện tại → so từng level (lot, margin, floating P/L, stop-out) → ghi lại sai lệch.
3. Sửa `MarginCalculator`/`SurvivalEngine` đến khi sai số **< 0.5%**.
4. Chuyển toàn bộ 30–50 case thành **golden tests không được phép skip** trong CI (khác với 6 test hiện tại đang skip khi thiếu data thật).
5. **Governance:** từ nay, mọi thay đổi công thức engine phải kèm cập nhật/bổ sung golden case tương ứng trước khi merge — không để lặp lại tình trạng "37 test chỉ chứng minh code đúng theo công thức tự viết".

### Kỹ thuật đi kèm (không phải feature, nhưng cùng nhóm ưu tiên trước launch)
- **Network security:** sửa `HTTP allowed cho mọi domain` → đặt `usesCleartextTraffic="false"` trong AndroidManifest, xóa domain-config permissive. Sentry/AdMob SDK dùng HTTPS mặc định, không cần mở HTTP.
- **AdMob placement:** giữ banner ở **Calculator** (trước khi commit) và **Saved Strategies** (màn hình duyệt). Bỏ hoàn toàn banner ở **Dashboard, Price Ladder, What-if, Reverse Mode, Share** — mọi nơi đang hiển thị con số rủi ro (Stop-out, Margin, Drawdown) không nên có quảng cáo, làm giảm trust của app tài chính.
- **APK size ~96MB:** khá lớn cho một calculator offline — audit lại trước launch (tách build theo ABI, kiểm tra dung lượng SDK Sentry/AdMob kéo theo), ảnh hưởng trực tiếp tỷ lệ cài đặt trên store.
- **Release checklist đã có sẵn trong features.md nhưng dễ bị bỏ quên khi mải làm feature mới:** i18n (vi+en, đánh dấu "blocking cho store"), Privacy Policy, Terms of Service, chuyển AdMob từ test ID sang real ID trước khi submit. Không được để các mục này trôi trong lúc ưu tiên roadmap P0 bên dưới.

---

## 1. P0 — Core Decision Features (làm ngay sau Gate 0)

Nguyên tắc chọn P0: biến app từ "tính xong rồi đóng" thành vòng lặp *Create → Stress Test → Fail → "Cần đổi gì?" → Adjust → Compare → Save*.

### 1.1 Failure/Bottleneck Explanation (mở rộng, không phải xây mới)
**Lưu ý quan trọng:** logic "bottleneck constraint" đã tồn tại ở Reverse Mode (`features.md` mục 5: *"Bottleneck constraint: Constraint chặt nhất quyết định kết quả ✅"*). Việc cần làm là **đưa logic này sang chiều thuận (Dashboard)**: khi user tự nhập Levels và bị FAIL, hiển thị rõ constraint nào vi phạm đầu tiên, tại level nào, chênh lệch bao nhiêu.

```
❌ Max DD constraint violated at Level 7 (23.4% > 20%)
   Bottleneck: Max DD Constraint
   Khuyến nghị tham khảo: giảm Multiplier từ 1.5x → 1.35x để đạt Level 7 an toàn theo tiêu chí bạn đặt
```
- Dùng lại `ConstraintEvaluator` đã có (trả PASS/FAIL từng constraint) + `SurvivalEngine` để xác định level vi phạm đầu tiên.
- Effort: **thấp** — chủ yếu nối UI, không cần engine mới.
- Không dùng từ "khuyến nghị an toàn" — chỉ trình bày như tham số thay đổi kèm kết quả mô phỏng lại.

### 1.2 Risk Budget (Risk Budget → Strategy, thay vì Strategy → Risk)
User nhập điểm khởi đầu khác hẳn hiện tại:
> "Tôi chấp nhận mất tối đa $1,000" (thay vì bắt đầu từ Lot)

App trả về: Initial lot tối đa / Multiplier tối đa / Grid distance tối thiểu thỏa constraint.
- **Kỹ thuật:** đây là bản mở rộng UX của `ReverseSolver` đã có (chỉ đổi input mặc định là Max Loss $ thay vì để user tự chọn), không cần solver mới.
- Priority: ⭐⭐⭐⭐⭐ theo cả plan2.md lẫn 2 review.

### 1.3 Max Levels Solver
User nhập Balance + Initial lot + Multiplier + Grid distance + constraints → app trả:
> "Maximum modeled levels under your constraints: 7"

kèm bảng level nào PASS/FAIL và vì constraint gì.
- Tái dùng `SurvivalEngine` + `ConstraintEvaluator` hiện có, chạy tuần tự qua các level — không cần module tính toán mới.

### 1.4 Basket TP Simulator
App hiện đã có Basket Breakeven + Rebind Distance (`features.md` mục 2). Bổ sung:
- User nhập **Target basket profit ($)** → app trả **Required exit price** hoặc **TP distance từ average entry**.
- Hiển thị bảng nhanh: `Basket BE | +$50 | +$100 | +$200` với giá tương ứng.
- **Kỹ thuật:** mở rộng trực tiếp từ `PnlCalculator` đã tính basket breakeven — chỉ cần giải ngược phương trình tuyến tính đã có cho target P/L khác 0 thay vì = 0.

### 1.5 Existing Exposure (rút gọn UX)
**Không** cho nhập từng lệnh riêng lẻ (ticket, entry, volume) — đây là "ác mộng UX" trên mobile theo cả 2 review. Chỉ nhập 3 số tổng hợp dễ tìm trên MT4/MT5:
- Equity hiện tại
- Floating P/L ($) hiện tại
- Total Exposure (Lots) đang mở

**Kỹ thuật implement — "synthetic Level 0":** inject 1 level ảo vào đầu `GridBuilder` (lot = Total Lots, entry price suy ra từ Floating P/L đã biết, không tính margin mới cho level này vì đã nằm trong Equity) trước khi build tiếp các level Grid tương lai. `PnlCalculator`/`MarginCalculator` xử lý được ngay vì vốn đã làm việc trên danh sách level tuần tự — **không cần module "existing positions" riêng biệt**.

### 1.6 Gap Scenario (khớp lệnh thực tế, không tuần tự)
**Bắt buộc đúng cơ chế khớp lệnh:** khi giá gap qua nhiều level (vd 3305 → 3275, đi qua L5-L8), các lệnh Buy Stop/Sell Stop khớp tại **giá đầu tiên sau gap (First Available Price)**, không phải tại các mức giá đặt ban đầu.

**Kỹ thuật implement:** thêm 1 flag vào `ExecutionSpec` đã có:
```dart
enum ExecutionMode { sequential, atMarket }
```
Khi `atMarket`: mọi level nằm trong khoảng gap dùng chung 1 `entryPrice` (giá đầu tiên sau gap) thay vì entry theo level đã tính sẵn. **Tái dùng `ScenarioEngine` đã có sẵn** (vốn đã sweep giá), chỉ thêm biến thể cách gán entry price — không cần module riêng.
- Luôn kèm cảnh báo: *"Actual execution may differ due to broker/order execution behavior."*

### 1.7 Strategy Templates (onboarding, không gán nhãn an toàn)
Thay vì user mở app thấy form trống, cho chọn nhanh:
- Đặt tên trung lập theo thông số: **"Low Multiplier (1.2x)", "Medium Multiplier (1.5x)", "High Multiplier (2.0x)"** — tuyệt đối không dùng "Conservative/Safe/Aggressive-an toàn".
- Khi chọn, hiển thị ngay Risk Preview nhỏ: *"Max DD dự kiến X%, Survival Level Y/10"* để user chọn dựa trên số liệu, không phải cảm tính.

---

## 2. P1 — Tạo Moat (giữ chân, so sánh, tối ưu)

### 2.1 Lock & Find Optimizer + Feasible Range (hợp nhất 2 đề xuất tưởng mâu thuẫn)
Plan2.md muốn trả về cả bảng nhiều combo (Lot × Multiplier × Survival); 2 review muốn ép "khóa 2 tham số, tìm 1" để tránh vô số nghiệm. **Hai đề xuất này không mâu thuẫn — dùng chung 1 engine:**

- UI: mỗi tham số có biểu tượng khóa 🔒. User khóa tối thiểu 2 tham số (vd Distance = $10, Multiplier = 1.4).
- Kỹ thuật: `ReverseSolver` hiện tại (binary search 1 biến) đã đủ dùng. Muốn ra "bảng feasible range" như plan2.md đề xuất, chỉ cần **sweep giá trị Multiplier qua vài mốc cố định, gọi lại `ReverseSolver` cho mỗi mốc** → tự động ra bảng nhiều dòng mà vẫn giữ nguyên tắc "mỗi lần solve chỉ 1 ẩn số".
```
Multiplier   Max Initial Lot   Survival
1.20         0.021             10 levels
1.30         0.018              9 levels
1.40         0.014              7 levels
```
- **Không cần viết solver đa biến mới.**

### 2.2 Sensitivity Analysis
Chạy perturbation ±10% từng tham số (Multiplier, Grid distance, Spread, Leverage), đo mức thay đổi Survival Level:
```
Multiplier    +10%   → -2 levels
Grid distance -20%   → -1 level
Spread        ×2     → -0 levels
Leverage      -60%   → -1 level
```
Kết luận dạng trung lập: *"Parameter nhạy nhất: Multiplier"* — không gán nhãn "nguy hiểm/an toàn", chỉ nêu độ nhạy tương đối.
- Kỹ thuật: gọi lại `SurvivalEngine` nhiều lần với từng tham số biến thiên — tái dùng hoàn toàn engine hiện có, không cần thuật toán mới.

### 2.3 Stress Test Matrix (Heatmap)
Ma trận N×M: hàng = kịch bản (Normal/Spread×2/Leverage↓), cột = mức giá bất lợi ($20/$40/$60/$80) → mỗi ô hiển thị ✓/⚠/❌.
- Dùng `fl_chart` hoặc `CustomPainter` (đã có fl_chart trong dependency).
- Kỹ thuật: chạy `ScenarioEngine` lặp qua tổ hợp (execution spec biến thiên × price offset biến thiên) — vẫn là compose từ engine hiện có, không cần module mới.

### 2.4 Strategy Comparison / Battle Mode
So sánh 2 strategy cạnh nhau (không dùng chữ "Winner" theo nghĩa an toàn):
```
                 STRATEGY A       STRATEGY B
Max DD           34%               22%
Survival         7                 9
Exposure         0.82              0.57
Stop-out         $3,218            $3,041
→ Lower modeled drawdown: B
→ Higher modeled survival buffer: B
```
- Kỹ thuật: chạy engine 2 lần với 2 `StrategySpec` khác nhau, hiển thị side-by-side — không cần logic so sánh mới, chỉ cần UI 2 cột.

### 2.5 Custom Grid Builder (asymmetric grid)
Nâng "Manual Grid Distance per level" (đã có trong roadmap P1 cũ của features.md) thành builder đầy đủ: user tự nhập Entry/Lot cho từng level thay vì công thức toán học cố định. Đây là nền móng cho Dynamic/ATR grid sau này — nên làm engine đủ tổng quát ngay (accept danh sách level tùy ý) thay vì chỉ patch riêng cho fixed-step.

### 2.6 Strategy Versioning
Nâng Save/Load hiện tại (tên + spec + timestamp) thành cây phiên bản đơn giản: lưu `parentId` khi user "Save as new version" từ 1 strategy đã có, cho phép xem lịch sử thay đổi (v1 → v2 → v3) kèm delta chính (vd "v4: Multiplier 1.35 → DD giảm 29.4% → 23.1%"). Việc này chỉ mở rộng Hive schema hiện có, không phải hệ thống mới.

### 2.7 ATR Reference (giữ nguyên đề xuất cũ trong features.md, chỉnh cách trình bày)
Đã có trong roadmap Priority 1 cũ (`features.md`). Chỉnh câu chữ theo đúng nguyên tắc trung lập:
> "Modeled survival distance = 1.8 × 14D ATR" — kèm chú thích *"This is a volatility comparison, not a safety prediction."*
Không dùng cụm "còn bao nhiêu pips an toàn".

---

## 3. P2 — Chỉ làm khi có tín hiệu nhu cầu thật (không ưu tiên hiện tại)

- Live Price Feed / Live Strategy Monitor (phá vỡ offline-first, chỉ đáng làm nếu làm trọn vẹn thành "current state" thay vì chỉ hiển thị giá chạy)
- Historical OHLC Backtest
- Monte Carlo (nếu làm sau này, đổi tên thành "Market Stress Simulation", không nói "probability of account blow-up")
- Prop-firm rule templates
- Multi-symbol portfolio / correlation exposure
- Market-triggered alerts (cần price feed — khác hẳn "offline reminder" chỉ nhắc user tự mở app check)

---

## 4. Loại bỏ chính thức khỏi roadmap

| Tính năng | Lý do loại |
|---|---|
| Risk Score (0–100) | Con số cảm tính, dễ bị hiểu nhầm "an toàn"; "Data > arbitrary score" |
| Monte Carlo Probability | False precision — thị trường tài chính đuôi dày (fat-tailed), không stationary |
| Local Notification / Market Alert (bản offline hiện tại) | Không khả thi khi chưa có price feed |
| Cloud Sync / Team Sharing / White-label | Quá cồng kềnh khi chưa chứng minh Product-Market Fit |
| App Lock, News Feed, Social Feed features | Không tạo giá trị cốt lõi cho risk-analysis tool |

---

## 5. Thứ tự triển khai cuối cùng cho agent code

```
Gate 0  → Calculation Audit (golden cases thật, sửa MarginCalculator/SurvivalEngine,
          network security, AdMob placement, i18n/Privacy Policy/APK size)
   │
   ▼
P0-1    → Failure/Bottleneck Explanation (nối UI, engine đã có)
P0-2    → Risk Budget (mở rộng ReverseSolver)
P0-3    → Max Levels Solver (tái dùng SurvivalEngine)
P0-4    → Basket TP Simulator (mở rộng PnlCalculator)
P0-5    → Existing Exposure — synthetic Level 0 (mở rộng GridBuilder)
P0-6    → Gap Scenario — ExecutionMode.atMarket (mở rộng ExecutionSpec + ScenarioEngine)
P0-7    → Strategy Templates (UI + risk preview)
   │
   ▼
P1-1    → Lock & Find Optimizer + Feasible Range (compose nhiều lần ReverseSolver)
P1-2    → Sensitivity Analysis (compose nhiều lần SurvivalEngine)
P1-3    → Stress Test Matrix / Heatmap (compose ScenarioEngine)
P1-4    → Strategy Comparison / Battle (chạy engine song song 2 spec)
P1-5    → Custom Grid Builder (tổng quát hóa GridLevel input)
P1-6    → Strategy Versioning (mở rộng Hive schema)
P1-7    → ATR Reference (chỉnh câu chữ + hiển thị)
```

**Nguyên tắc quan trọng nhất khi thực thi:** làm **từng feature P0 một, mỗi feature có golden case/test riêng trước khi merge**, không batch nhiều feature P0 cùng lúc rồi mới test tổng — để tránh lặp lại đúng vấn đề đã xảy ra ở Gate 0 ("37 test chỉ chứng minh code đúng theo công thức tự viết"). Toàn bộ P0–P1 ở trên đều được thiết kế để **tái sử dụng 6 module engine hiện có** (`GridBuilder`, `MarginCalculator`, `PnlCalculator`, `SurvivalEngine`, `ScenarioEngine`, `ReverseSolver`, `ConstraintEvaluator`) — không cần viết engine mới, chỉ compose/mở rộng, giữ đúng nguyên tắc kiến trúc "Core Engine tách biệt UI" đã có sẵn trong `features.md`.