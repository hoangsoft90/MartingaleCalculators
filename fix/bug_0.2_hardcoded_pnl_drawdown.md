# Bug 0.2 — `totalFloatingPnl`/`maxDrawdownPercent` hard-code 0 (Max Loss/Max DD luôn PASS giả)

> Chỉ giao sau khi Bug 0.1 đã xanh và merge. Không gộp với Bug khác.

**Phạm vi rộng hơn các review khác nêu — xác nhận qua đọc trực tiếp code:**

| File | Hàm | Giá trị hard-code |
|---|---|---|
| `reverse_solver.dart` | `_buildAndCheck` | `maxDrawdownPercent: 0`, `totalFloatingPnl: 0` |
| `survival_engine.dart` | `maxSurvivableLevels` | `maxDrawdownPercent: 0`, `totalFloatingPnl: 0` |
| `app/lib/state/strategy_provider.dart` | `calculationResultProvider` | `totalFloatingPnl: 0` (⚠️ đây là **luồng Dashboard chính**, không chỉ Reverse Mode — bug này ảnh hưởng đến MỌI màn hình dùng `calculationResultProvider`) |

`ConstraintEvaluator.evaluate()` nhận `totalFloatingPnl`/`maxDrawdownPercent` từ caller, không tự tính. Vì `passed = totalFloatingPnl.abs() <= constraints.maxLossAmount!` và `0.abs() ≤ bất kỳ số dương nào`, constraint **"Max Loss $" không hoạt động ở bất kỳ đâu trong toàn app**, kể cả Dashboard chính.

**Fix:** Trước khi gọi `ConstraintEvaluator.evaluate()` ở cả 3 nơi, phải tính floating P/L thật tại kịch bản adverse (dùng `PnlCalculator.calculateFloatingPnl` tại giá worst-case — level cuối cho Buy, level đầu cho Sell, giống cách `calculationResultProvider` đã làm đúng cho `maxDrawdownPercent`) và truyền giá trị thật vào, thay vì `0`.

**Regression test bắt buộc (chính xác theo bug đã xác nhận):**
```
reverse_solver_test.dart — sửa test "tighter constraint reduces maximum lot":
  Hiện tại: dùng maxDrawdownPercent constraint, assertion tight ≤ loose PASS GIẢ
  (vì cả 2 hội tụ về lotMax=100.0 do DD luôn pass).
  Sau khi sửa: assert cụ thể looseResult.maximumInitialLot < xauusd.lotMax
  (chứng minh constraint thực sự chặn được kết quả, không hội tụ về biên trên).

Thêm test mới: Set Max Loss = $500 → verify returnedLot thỏa Loss ≤ $500,
  và returnedLot + lotStep phải FAIL (trừ khi returnedLot đã = lotMax).
```

---

## Prompt giao cho agent

> Đọc `reverse_solver.dart`, `survival_engine.dart`, `strategy_provider.dart`, `constraint_evaluator.dart`. Bug: cả 3 nơi hard-code `totalFloatingPnl: 0`/`maxDrawdownPercent: 0` trước khi gọi `ConstraintEvaluator.evaluate`, khiến Max Loss/Max DD luôn PASS. Fix: tính floating P/L và max DD thật tại kịch bản adverse (dùng `PnlCalculator.calculateFloatingPnl` tại entry price của level cuối theo hướng bất lợi) trước khi evaluate. Sửa test `reverse_solver_test.dart` — assertion "tighter constraint reduces maximum lot" hiện đang pass vì lý do sai (cả 2 kết quả hội tụ về lotMax); thêm assertion cụ thể chứng minh looseResult < lotMax. Thêm test Max Loss $500. Không sửa What-if/Gap trong PR này.

## Quy trình bắt buộc (nhắc lại)
1. Đọc code trước, xác nhận hiểu đúng bug (không đoán).
2. Viết regression test thất bại trước khi sửa (chứng minh bug tồn tại).
3. Sửa đúng phạm vi được giao — **không sửa file/feature ngoài scope**.
4. Chạy toàn bộ test suite sau khi sửa, không chỉ test mới.
5. Báo lại diff để review trước khi merge.
