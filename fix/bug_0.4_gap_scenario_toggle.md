# Bug 0.4 — Gap Scenario: Sequential vs At Market là fake toggle

> Chỉ giao sau khi Bug 0.3 đã xanh và merge.

**File:** `app/lib/screens/gap_scenario/gap_scenario_screen.dart`

**Spec khớp lệnh cần implement (chốt rõ, không mơ hồ):**

| Mode | Hành vi |
|---|---|
| **Sequential** | Mỗi level khớp đúng tại entry price đã đặt trước (giả định fill lý tưởng, không trượt giá). |
| **At Market** | Mọi level nằm trong khoảng gap khớp cùng 1 giá — giá đầu tiên xuất hiện sau gap (First Available Open Price). P/L và margin phải tính lại dựa trên giá khớp thực tế này, khác Sequential. |

**Yêu cầu:** hai mode phải cho ra **kết quả khác nhau** khi test với cùng input gap. Nếu chưa implement được At Market đúng trong sprint này, **ẩn toggle** (chỉ giữ Sequential + ghi rõ trong Assumptions), không để user chọn 1 toggle không có tác dụng.

---

## Prompt giao cho agent

> Đọc `gap_scenario_screen.dart`, `execution_spec.dart` (`ExecutionMode` enum). Bug: chọn Sequential hay At Market cho kết quả giống nhau. Fix: khi `ExecutionMode.atMarket`, mọi level có entry price nằm trong khoảng gap (giữa giá cũ và giá gap-tới) phải dùng chung 1 entry price = giá đầu tiên sau gap, thay vì entry price đã tính theo level. Nếu chưa chắc implement đúng trong phạm vi này, ẩn toggle At Market khỏi UI và chỉ giữ Sequential với disclaimer rõ. Test: cùng input gap, Sequential và At Market phải cho kết quả P/L/margin khác nhau (khi implement đủ), hoặc toggle bị ẩn (khi chưa implement).

## Quy trình bắt buộc (nhắc lại)
1. Đọc code trước, xác nhận hiểu đúng bug (không đoán).
2. Viết regression test thất bại trước khi sửa (chứng minh bug tồn tại).
3. Sửa đúng phạm vi được giao — **không sửa file/feature ngoài scope**.
4. Chạy toàn bộ test suite sau khi sửa, không chỉ test mới.
5. Báo lại diff để review trước khi merge.
