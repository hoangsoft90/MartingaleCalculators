# Bug 0.1 — `ReverseSolver` dùng `currentPrice: 0`

> Đây là 1 trong 6 bug độc lập từ `plan3_final.md`. Chỉ giao đúng nội dung file này cho agent. Sau khi Bug 0.1 xanh (test pass, review xong) mới giao tiếp Bug 0.2.

**File:** `packages/grid_engine/lib/src/engine/reverse_solver.dart`, hàm `_buildAndCheck`

**Bằng chứng:**
```dart
final levels = GridBuilder.build(
  strategy: effectiveStrategy,
  instrument: instrument,
  execution: execution,
  currentPrice: 0, // Placeholder for reverse solver
);
```
Với `currentPrice = 0`, mọi entry price tính từ mid price = 0 → `notional = lot × contractSize × entryPrice` sai hoàn toàn → margin/constraint check vô nghĩa.

**Fix:** Thêm tham số bắt buộc `required double currentPrice` vào `ReverseSolver.solve()` và truyền xuyên suốt `_buildAndCheck`/`_satisfiesConstraints`. UI (`risk_budget_screen.dart`, `reverse_mode_screen.dart`) phải truyền `ref.read(currentPriceProvider)` — cùng giá trị dùng bởi Quick Calculator/Dashboard, không tự bịa số khác.

---

## Prompt giao cho agent

> Đọc `reverse_solver.dart`. Bug: `currentPrice: 0` hard-code trong `_buildAndCheck`. Sửa: thêm `required double currentPrice` vào `ReverseSolver.solve()`, truyền xuống `GridBuilder.build`. Cập nhật mọi call site (`risk_budget_screen.dart`, `reverse_mode_screen.dart`, `reverse_solver_test.dart`) để truyền giá trị thật. Không sửa gì khác trong PR này.

## Quy trình bắt buộc (nhắc lại)
1. Đọc code trước, xác nhận hiểu đúng bug (không đoán).
2. Viết regression test thất bại trước khi sửa (chứng minh bug tồn tại).
3. Sửa đúng phạm vi được giao — **không sửa file/feature ngoài scope**.
4. Chạy toàn bộ test suite sau khi sửa, không chỉ test mới.
5. Báo lại diff để review trước khi merge.
