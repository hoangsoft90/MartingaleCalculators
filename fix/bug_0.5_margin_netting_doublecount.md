# Bug 0.5 — Margin Netting: double-count do sum các snapshot lũy kế

> Chỉ giao sau khi Bug 0.4 đã xanh và merge. Đây là bug có 2 lỗi riêng biệt — chỉ sửa lỗi #2 (tiêu thụ dữ liệu) trong PR này, KHÔNG đụng công thức notional (#1), vì #1 cần chờ Golden Cases (Phase 1, xem file riêng).

**File:** `packages/grid_engine/lib/src/engine/margin_calculator.dart` (`_calculateNetting`) + mọi nơi tiêu thụ (`survival_engine.dart`, `reverse_solver.dart`, `strategy_provider.dart`)

**Đây là 2 lỗi riêng biệt cần phân biệt rõ khi sửa:**

1. **Công thức notional (review1 nêu) — KHÔNG sửa trong PR này:** `_calculateNetting` dùng `entryPrice` của level *hiện tại* cho toàn bộ net lot, thay vì giá trung bình hoặc phương pháp broker thật dùng. Cần đối chiếu với Golden Cases MT5 (Phase 1) để xác định công thức đúng — **không tự đoán**, để `"TODO: verify against golden case"` trong code cho tới khi có data thật.

2. **Lỗi tiêu thụ dữ liệu (phát hiện bổ sung, độc lập với #1) — SỬA trong PR này:** `level[i].requiredMargin` trong Netting mode lưu giá trị **lũy kế** (margin tại thời điểm level i đã trigger), nhưng `SurvivalEngine`/`ReverseSolver` đều làm:
   ```dart
   for (final triggered in triggeredLevels) {
     totalMargin += triggered.requiredMargin; // SAI cho Netting: cộng dồn các snapshot lũy kế
   }
   ```
   Với Netting mode, `totalMargin` đúng phải là `requiredMargin` của **level cuối cùng đã trigger** (giá trị lũy kế mới nhất), không phải tổng của tất cả các snapshot. Lỗi này gây overcount margin theo cấp số nhân tam giác khi số level tăng — độc lập với việc công thức notional ở bug #1 đúng hay sai.

**Fix:**
- Bug #2 (ưu tiên sửa trước, không phụ thuộc Golden Cases): thêm hàm `MarginCalculator.totalMargin(levels, hedgeMode)` nhận biết hedge mode — với `netting`, chỉ lấy `requiredMargin` của level cuối cùng đã trigger; với `hedgingFull`/`hedgingReduced`, giữ nguyên logic sum hiện tại (đúng vì mỗi level độc lập). Thay mọi chỗ đang tự cộng dồn thủ công (`for (final triggered in ...) { totalMargin += ... }`) bằng gọi hàm này.
- Bug #1: chờ Golden Cases (Phase 1) để xác nhận công thức, đánh dấu rõ trong code là "pending validation".

---

## Prompt giao cho agent

> Đọc `margin_calculator.dart` và mọi nơi tự cộng dồn `requiredMargin` thủ công (`survival_engine.dart`, `reverse_solver.dart`, `strategy_provider.dart`). Bug: với Netting mode, `requiredMargin` mỗi level lưu giá trị lũy kế, nhưng các nơi tiêu thụ lại sum tất cả level đã trigger lại lần nữa → overcount. Fix: tạo `MarginCalculator.totalMargin(levels, hedgeMode)` — với `netting` chỉ lấy giá trị của level cuối cùng đã trigger; với `hedgingFull`/`hedgingReduced` giữ nguyên sum. Thay mọi chỗ tự cộng dồn thủ công bằng hàm này. Không sửa công thức notional bên trong `_calculateNetting` trong PR này (chờ Golden Cases Phase 1) — chỉ để comment `// TODO: verify notional formula against golden case (Phase 1)`.

## Quy trình bắt buộc (nhắc lại)
1. Đọc code trước, xác nhận hiểu đúng bug (không đoán).
2. Viết regression test thất bại trước khi sửa (chứng minh bug tồn tại).
3. Sửa đúng phạm vi được giao — **không sửa file/feature ngoài scope, không tự đoán công thức notional**.
4. Chạy toàn bộ test suite sau khi sửa, không chỉ test mới.
5. Báo lại diff để review trước khi merge.
