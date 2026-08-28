# Bug 0.6 — Hedging Reduced áp factor cho toàn bộ position (single-direction)

> Chỉ giao sau khi Bug 0.5 đã xanh và merge. Đây là bug cuối trong Phase 0.

**File:** `margin_calculator.dart` (`_calculateHedgingReduced`)

**Bằng chứng:**
```dart
final fullMargin = notional / leverage;
final margin = fullMargin * hedgedMarginFactor; // áp cho TOÀN BỘ position
```
Comment nói "hedged portion uses reduced margin factor" nhưng grid hiện tại chỉ 1 chiều (không có lệnh đối ứng) — không có "hedged portion" để áp giảm. Áp factor lên toàn bộ khiến margin bị giảm giả tạo (underestimate risk).

**Fix:** Single-direction grid (hiện tại 100% các trường hợp trong app) phải dùng **Full margin**, không áp `hedgedMarginFactor`. Chỉ áp factor giảm khi thực sự có vị thế đối ứng 2 chiều (tính năng chưa tồn tại trong app — nếu chưa làm multi-direction, `hedgingReduced` nên tạm thời hoạt động giống `hedgingFull` cho tới khi có tính năng đối ứng thật).

---

## Prompt giao cho agent

> Đọc `_calculateHedgingReduced` trong `margin_calculator.dart`. Bug: áp `hedgedMarginFactor` cho toàn bộ position dù grid hiện tại chỉ single-direction (không có hedged portion thật). Fix: khi grid single-direction, `hedgingReduced` phải cho kết quả giống `hedgingFull` (không giảm margin giả tạo). Chỉ áp factor giảm khi có cơ chế phát hiện vị thế đối ứng 2 chiều thật (nếu chưa có, throw/log rõ "hedgingReduced not applicable to single-direction grid" thay vì âm thầm giảm margin sai). Thêm test xác nhận `hedgingReduced == hedgingFull` cho single-direction.

## Quy trình bắt buộc (nhắc lại)
1. Đọc code trước, xác nhận hiểu đúng bug (không đoán).
2. Viết regression test thất bại trước khi sửa (chứng minh bug tồn tại).
3. Sửa đúng phạm vi được giao — **không sửa file/feature ngoài scope**.
4. Chạy toàn bộ test suite sau khi sửa, không chỉ test mới.
5. Báo lại diff để review trước khi merge.

---

## Sau khi Bug 0.6 xanh — Phase 0 hoàn thành

Bước tiếp theo (không giao cho agent code, bạn tự làm hoặc phối hợp):
- **Phase 1 — Golden Dataset:** thu thập 30–50 case thật từ MT4/MT5 để xác nhận công thức notional (Bug 0.5 phần #1) và các nghi vấn khác. Xem chi tiết trong `plan3_final.md` mục PHASE 1.
- Sau khi Phase 1 xong, mới nên cân nhắc Phase 2 (Invariant tests) rồi Phase 3 (refactor `SimulationEngine`).
