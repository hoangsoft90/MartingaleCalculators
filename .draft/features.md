# Grid Survival Simulator — Features & Expansion Guide

> **Mục đích:** Tài liệu này mô tả toàn bộ tính năng hiện tại (MVP) và các hướng mở rộng để phiên bản đầu tiên đủ hấp dẫn giữ lại người dùng.

---

## 📱 Tổng quan App

**Grid Survival Simulator** là công cụ phân tích rủi ro offline-first giúp trader stress-test chiến lược Grid trước khi chạy thật.

- **Tagline:** "Stress-test your Grid strategy before the market does."
- **Target users:** Forex/Gold traders đang dùng grid strategy
- **Platform:** Flutter (iOS + Android)
- **Offline-first:** Không cần internet, không gửi dữ liệu đi đâu

---

## ✅ Tính năng hiện tại (MVP)

### 1. Quick Calculator (Màn hình nhập liệu)

| Tính năng | Mô tả | Status |
|---|---|---|
| Symbol selector | Chọn XAUUSD hoặc EURUSD | ✅ |
| Direction selector | Buy hoặc Sell (SegmentedButton) | ✅ |
| Account inputs | Balance, Leverage, Stop-out % | ✅ |
| Strategy inputs | Initial Lot, Multiplier, Distance, Levels | ✅ |
| Current Price | Giá hiện tại để tính toán | ✅ |
| Execution (Advanced) | Spread, Commission | ✅ |
| Risk Constraints (Advanced) | Max DD%, Max Total Lot, Min Margin Level%, Max Loss $ | ✅ |
| Form validation | Kiểm tra input hợp lệ trước khi tính | ✅ |
| Disclaimer | "Not financial advice" ở mọi màn hình | ✅ |

### 2. Risk Dashboard (Màn hình kết quả)

| Tính năng | Mô tả | Status |
|---|---|---|
| Survivable Levels | Số level có thể sống sót / tổng level | ✅ |
| Max Drawdown % | Drawdown tối đa | ✅ |
| Estimated Stop-out Price | Giá ước tính stop-out | ✅ |
| Basket Breakeven | Giá hòa vốn basket | ✅ |
| Rebind Distance | Khoảng cách cần hồi để hòa vốn | ✅ |
| Total Exposure | Tổng exposure (lots) | ✅ |
| Constraint Check | PASS/FAIL theo constraint user đặt | ✅ |
| Grid Levels Table | Bảng chi tiết từng level | ✅ |
| Assumptions Panel | Danh sách giả định đã dùng | ✅ |
| Navigation buttons | Price Ladder, What-if, Reverse, Share, Saved | ✅ |
| Edit button | Quay về Calculator chỉnh tham số | ✅ |

### 3. Price Ladder (Visual)

| Tính năng | Mô tả | Status |
|---|---|---|
| Line chart | Biểu đồ đường hiển thị grid levels | ✅ |
| Level markers | Mỗi level là 1 điểm trên chart | ✅ |
| Avg Entry line | Đường entry trung bình (green) | ✅ |
| Basket BE line | Đường breakeven (orange) | ✅ |
| Stop-out line | Đường stop-out (red, nếu có) | ✅ |
| Touch tooltip | Tap vào level xem chi tiết | ✅ |
| Level details panel | Hiển thị Lot, Entry, Cum. Lot, Margin | ✅ |
| Legend | Giải thích màu sắc | ✅ |

### 4. What-if Slider (Scenario Analysis)

| Tính năng | Mô tả | Status |
|---|---|---|
| Price slider | Kéo để thay đổi giá giả định | ✅ |
| Realtime update | Dashboard cập nhật realtime khi kéo | ✅ |
| Triggered levels | Số level đã trigger tại giá đó | ✅ |
| Drawdown % | Drawdown tại giá giả định | ✅ |
| Margin Level | Margin level tại giá giả định | ✅ |
| Floating P/L | Lỗ/lãi tại giá giả định | ✅ |
| Quick State Inspector | Nhập giá thủ công → thấy trạng thái ngay | ✅ |
| Constraint status | Kiểm tra constraint tại giá giả định | ✅ |

### 5. Reverse Mode

| Tính năng | Mô tả | Status |
|---|---|---|
| Constraint inputs | Nhập Max DD%, Min Margin Level%, Max Lot, Max Loss | ✅ |
| Binary search solver | Tìm Maximum Initial Lot thỏa mãn constraint | ✅ |
| Result display | Hiển thị max lot tìm được | ✅ |
| Iteration count | Số iterations binary search | ✅ |
| Bottleneck constraint | Constraint chặt nhất quyết định kết quả | ✅ |
| All results | Danh sách kết quả tất cả constraint | ✅ |
| Validation | Yêu cầu ít nhất 1 constraint trước khi chạy | ✅ |

### 6. Save/Load Strategies

| Tính năng | Mô tả | Status |
|---|---|---|
| Save strategy | Lưu tên + toàn bộ spec + timestamp | ✅ |
| Load strategy | Tải lại → fill vào Calculator → hiển thị Dashboard | ✅ |
| Delete strategy | Xóa strategy đã lưu | ✅ |
| Max 5 strategies | Giới hạn MVP | ✅ |
| Persistence | Lưu offline bằng Hive | ✅ |

### 7. Share as Image

| Tính năng | Mô tả | Status |
|---|---|---|
| Screenshot card | Card tổng hợp kết quả | ✅ |
| Share via share_plus | Chia sẻ ảnh PNG | ✅ |
| Included info | Symbol, Strategy, Survivable, DD, BE, Stop-out | ✅ |
| Disclaimer | "Not financial advice" trên ảnh | ✅ |

### 8. Core Engine (Pure Dart)

| Module | Mô tả | Status |
|---|---|---|
| GridBuilder | Tính lot + entry price theo level | ✅ |
| MarginCalculator | Margin theo 3 hedge modes | ✅ |
| PnlCalculator | Floating P/L + Basket BE | ✅ |
| SurvivalEngine | Deterministic survival analysis | ✅ |
| ScenarioEngine | What-if table generation | ✅ |
| ReverseSolver | Binary search max lot | ✅ |
| ConstraintEvaluator | PASS/FAIL checks | ✅ |
| LotRounding | Round/Floor/Ceiling với lotStep | ✅ |

### 9. Navigation & UX

| Tính năng | Mô tả | Status |
|---|---|---|
| SafeScaffold | PopScope cho web back button | ✅ |
| Named routes | Deep link support (/dashboard, /what-if, etc.) | ✅ |
| AppNavigation helper | push, pushReplacement, popOrDashboard | ✅ |
| No dead ends | Mọi screen đều có thể quay về | ✅ |
| Direction selector | Buy/Sell toggle | ✅ |

### 10. Testing

| Loại test | Số lượng | Status |
|---|---|---|
| Unit tests (engine) | 37 tests | ✅ |
| Golden cases (MT5 data) | 12 scenarios | ✅ (placeholder) |
| Validation tests | 6 tests | ✅ |
| Widget tests | 2 tests | ✅ |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                  UI LAYER (Flutter)              │
│  Quick Calculator | Dashboard | Price Ladder     │
│  What-if Slider | Reverse Mode | Save/Share      │
└───────────────────────▲─────────────────────────┘
                        │ Riverpod
┌───────────────────────┴─────────────────────────┐
│              APPLICATION / STATE LAYER           │
│  Providers: Strategy, Scenario, Constraint       │
└───────────────────────▲─────────────────────────┘
                        │ Pure Dart
┌───────────────────────┴─────────────────────────┐
│           CORE ENGINE (packages/grid_engine)     │
│  Models + Calculations — 100% unit-testable      │
└───────────────────────▲─────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────┐
│              PERSISTENCE (Hive, offline)         │
│  Saved Strategies | Instrument Specs | Settings  │
└─────────────────────────────────────────────────┘
```

---

## 📊 Tech Stack

| Thành phần | Technology | Version |
|---|---|---|
| Framework | Flutter | 3.24.0 |
| State management | Riverpod | 2.x |
| Persistence | Hive | 2.x |
| Charts | fl_chart | 0.66.x |
| Share | screenshot + share_plus | latest |
| Engine | Pure Dart | 3.x |
| Tests | test package | 1.31.x |

---

## 🔄 User Flow

```
┌─────────────────┐
│ Quick Calculator │ ← Nhập tham số
└────────┬────────┘
         │ Calculate
         ▼
┌─────────────────┐
│   Dashboard     │ ← Xem kết quả
└────────┬────────┘
         │
    ┌────┴────┬──────────┬──────────┬──────────┐
    ▼         ▼          ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ Price  │ │ What-if│ │Reverse │ │ Share  │ │ Saved  │
│ Ladder │ │ Slider │ │ Mode   │ │ Image  │ │ Strats │
└────────┘ └────────┘ └────────┘ └────────┘ └────────┘
```

---

## 🎯 Hướng mở rộng — Tính năng nên thêm để giữ chân user

### Priority 1 — Phải có ngay (MVP+)

| # | Tính năng | Lý do | Difficulty |
|---|---|---|---|
| 1 | **Custom Broker Profile** | User nhập spread/commission theo broker thật | Easy |
| 2 | **ATR Reference** | Nhập ATR thủ công → hiển thị survival/ATR ratio | Easy |
| 3 | **Manual Grid Distance** | Cho phép nhập distance riêng cho mỗi level | Medium |
| 4 | **Export to JSON/CSV** | Lưu kết quả ra file để phân tích sau | Easy |
| 5 | **Dark/Light Theme toggle** | Cho phép user chọn theme thủ công | Easy |
| 6 | **History chart** | Biểu đồ P/L theo từng level (bar chart) | Medium |

### Priority 2 — Nên có (Retention)

| # | Tính năng | Lý do | Difficulty |
|---|---|---|---|
| 7 | **Strategy Comparison A/B** | So sánh 2 strategy cạnh nhau | Medium |
| 8 | **Stress Test Presets** | Spread×2, Spread×5, Leverage↓ — 1 tap | Easy |
| 9 | **Multi-symbol support** | Thêm GBPUSD, US30, BTCUSD | Easy |
| 10 | **Configurable Grid Distance** | Fixed, % price, ATR-based | Medium |
| 11 | **Widget/App Lock** | PIN/biometric bảo mật | Medium |
| 12 | **Push notification提醒** | nhắc user check lại strategy định kỳ | Hard |

### Priority 3 — Deluxe (Engagement)

| # | Tính năng | Lý do | Difficulty |
|---|---|---|---|
| 13 | **Live price feed** | Kết nối websocket lấy giá real-time | Hard |
| 14 | **Backtest with OHLC** | Chạy strategy trên dữ liệu lịch sử | Very Hard |
| 15 | **Monte Carlo simulation** | Phân tích xác suất | Very Hard |
| 16 | **Risk Score** | Đánh giá rủi ro tổng hợp (0-100) | Medium |
| 17 | **Social sharing** | Share kết quả lên Facebook/Zalo | Medium |
| 18 | **Tutorial/Onboarding** | Hướng dẫn sử dụng lần đầu | Medium |

### Priority 4 — Pro (Monetization)

| # | Tính năng | Lý do | Difficulty |
|---|---|---|---|
| 19 | **Cloud sync** | Đồng bộ strategy giữa nhiều thiết bị | Hard |
| 20 | **Team sharing** | Chia sẻ strategy trong nhóm | Hard |
| 21 | **Advanced analytics** | Dashboard nâng cao với nhiều chart | Medium |
| 22 | **API integration** | Kết nối MT4/MT5 tự động | Very Hard |
| 23 | **Subscription plan** | Free vs Pro features | Medium |

---

## 🔧 Kỹ thuật cần cải thiện

| # | Vấn đề | Hiện tại | Nên làm |
|---|---|---|---|
| 1 | **i18n** | Chưa có | Thêm tiếng Việt + English |
| 2 | **Error handling** | Basic try-catch | User-friendly error messages |
| 3 | **Loading states** | CircularProgressIndicator | Skeleton loading |
| 4 | **Empty states** | Text đơn giản | Illustration + CTA |
| 5 | **Form auto-save** | Không lưu | Tự lưu nháp khi exit |
| 6 | **Undo/Redo** | Không có | Cho phép undo thay đổi |
| 7 | **Responsive layout** | Mobile-first | Tablet/Desktop layout |
| 8 | **Accessibility** | Chưa có | Screen reader support |

---

## 📐 Design Guidelines

### Colors
```dart
Primary: #1E3A5F (Dark Navy)
Background: #FFFFFF (Light) / #0D1B2A (Dark)
Accent: #FFD700 (Gold)
Success: #4CAF50 (Green)
Warning: #FF9800 (Orange)
Danger: #F44336 (Red)
```

### Typography
```dart
Headline: 24-32px, Bold
Title: 18-20px, SemiBold
Body: 14-16px, Regular
Caption: 12px, Regular
```

### Spacing
```dart
XS: 4px
S: 8px
M: 16px
L: 24px
XL: 32px
```

---

## 📝 Notes cho AI Research

### Context quan trọng:
1. **App là offline-first** — không có backend, không cần auth
2. **Target users là trader** — cần chính xác về số liệu tài chính
3. **Không được dùng từ "profit/guaranteed/safe"** — vi phạm app store policy
4. **Mỗi kết quả phải có disclaimer** — "Not financial advice"
5. **Engine tách riêng** — có thể tái sử dụng cho project khác

### Constraints:
- Không dùng package financial bên thứ 3 — tự viết để kiểm soát
- Không fetch data real-time ở MVP — giữ offline
- Không làm PDF ở MVP — chỉ share image
- Tối đa 5 strategies saved ở MVP

### Success metrics:
- User mở app ≥ 3 lần/tuần
- User save ≥ 1 strategy
- User share ≥ 1 kết quả
- Rating ≥ 4.0 trên store

---

## 🚀 Release Checklist

- [ ] i18n (vi + en)
- [ ] Onboarding screen
- [ ] Custom broker profiles
- [ ] Stress test presets
- [ ] Export to JSON/CSV
- [ ] Dark/Light theme toggle
- [ ] App store screenshots
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Beta test với 5-10 traders
