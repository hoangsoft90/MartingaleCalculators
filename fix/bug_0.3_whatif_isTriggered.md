# Bug 0.3 — What-if Slider rebuild grid theo giá slider + `isTriggered` luôn `true`

> Chỉ giao sau khi Bug 0.2 đã xanh và merge. Đây là bug có nhiều quyết định thiết kế mở — review kỹ hơn các bug khác, không chỉ "sửa 1 dòng số 0".

**File:** `app/lib/screens/what_if/what_if_screen.dart`, `packages/grid_engine/lib/src/engine/scenario_engine.dart`, `packages/grid_engine/lib/src/engine/grid_builder.dart`

**Bằng chứng:**
```dart
// what_if_screen.dart / scenario_engine.dart — SAI
final levels = GridBuilder.build(..., currentPrice: price); // rebuild theo slider

// grid_builder.dart — SAI
isTriggered: true, // All configured levels are triggered at full range
```
Kéo slider → toàn bộ entry price re-anchor vào giá slider (như thể vừa mở grid mới tại đó) thay vì giữ nguyên entry gốc. Và vì `isTriggered` luôn `true` cho mọi level được build, `triggeredLevels` **luôn = configured levels** bất kể slider ở đâu — feature "UX core" của cả app không hoạt động đúng bản chất.

**Chốt contract semantics trước khi sửa (bắt buộc, tránh sửa nửa vời):**

| Option | Định nghĩa | Khuyến nghị |
|---|---|---|
| **A — Planned vs Triggered** | Grid levels = pending orders. `isTriggered(price)` = giá đã "đi qua" entry theo hướng adverse. What-if/Gap dùng predicate này. | **Chọn option này.** |
| B — Full stress (worst-case) | Giữ như hiện tại (mọi level coi như đã mở), nhưng đổi UI copy thành "Configured levels under full adverse fill", không dùng chữ "Triggered". | Chỉ chọn nếu team quyết định không làm Option A vì lý do effort. |

**Fix (theo Option A):**
1. `GridBuilder.build()` chỉ tính entry price 1 lần tại `currentPrice` gốc của chiến lược — không đổi khi What-if chạy.
2. Thêm hàm `bool isTriggered(GridLevel level, double assumedPrice, Direction direction)` — so sánh `assumedPrice` với `level.entryPrice` theo hướng adverse.
3. `ScenarioEngine`/What-if chỉ gọi `PnlCalculator.calculateFloatingPnl(..., assumedPrice: price)` trên **grid cố định**, không rebuild.
4. `ConstraintEvaluator` phải được evaluate lại **tại giá đang xem trên slider**, không copy static result từ base calculation.

**Test bắt buộc:**
```
- Kéo slider tới đúng entry price của level k → triggeredLevels == k.
- Constraint status đổi từ PASS sang FAIL khi slider đi vào vùng vi phạm
  (không phải copy từ base calculation).
```

---

## Prompt giao cho agent

> Đọc `what_if_screen.dart`, `scenario_engine.dart`, `grid_builder.dart`. Bug: `GridBuilder.build()` rebuild toàn bộ entry price theo giá slider, và luôn set `isTriggered: true` cho mọi level. Fix theo Option A (Planned vs Triggered): build grid 1 lần tại giá gốc chiến lược; thêm predicate `isTriggered(level, assumedPrice, direction)`; What-if chỉ thay đổi `assumedPrice` để tính P/L qua `PnlCalculator`, không rebuild entry; evaluate `ConstraintEvaluator` tại giá đang xem trên slider (không dùng static result). Test: slider tại entry của level k → triggered = k; constraint đổi khi vào vùng vi phạm. Không sửa Reverse/Gap trong PR này.

## Quy trình bắt buộc (nhắc lại)
1. Đọc code trước, xác nhận hiểu đúng bug (không đoán).
2. Viết regression test thất bại trước khi sửa (chứng minh bug tồn tại).
3. Sửa đúng phạm vi được giao — **không sửa file/feature ngoài scope**.
4. Chạy toàn bộ test suite sau khi sửa, không chỉ test mới.
5. Báo lại diff để review trước khi merge — bug này có nhiều quyết định thiết kế mở, review kỹ.
