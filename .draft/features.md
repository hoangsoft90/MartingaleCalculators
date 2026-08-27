# Grid Survival Simulator — Features & Expansion Guide

> **Mục đích:** Tài liệu này mô tả toàn bộ tính năng hiện tại (MVP) và các hướng mở rộng để phiên bản đầu tiên đủ hấp dẫn giữ lại người dùng.
>
> **Repo:** https://github.com/hoangsoft90/MartingaleCalculators
>
> **Tech:** Flutter 3.24.0 · Dart 3.5.0 · Riverpod 2.x · Hive 2.x · fl_chart · google_mobile_ads · sentry_flutter

---

## 📱 Tổng quan App

**Grid Survival Simulator** là công cụ phân tích rủi ro offline-first giúp trader stress-test chiến lược Grid/Martingale trước khi chạy thật trên tài khoản thật.

- **Tagline:** "Stress-test your Grid strategy before the market does."
- **Target users:** Forex/Gold traders đang dùng grid strategy (MT4/MT5)
- **Platform:** Flutter (iOS + Android)
- **Offline-first:** Không cần internet, không gửi dữ liệu đi đâu
- **Monetization:** AdMob banner ads (test mode hiện tại)
- **Error tracking:** Sentry SDK tích hợp sẵn

---

## ✅ Tính năng hiện tại (MVP)

### 1. Quick Calculator (Màn hình nhập liệu — Home)

| Tính năng | Mô tả | Status |
|---|---|---|
| Symbol selector | Chọn XAUUSD hoặc EURUSD | ✅ |
| Direction selector | Buy hoặc Sell (SegmentedButton) | ✅ |
| Account inputs | Balance, Leverage, Stop-out % | ✅ |
| Strategy inputs | Initial Lot, Multiplier, Distance, Levels | ✅ |
| Current Price | Giá hiện tại để tính toán | ✅ |
| Execution (Advanced) | Spread, Commission, Swap, Holding Days | ✅ |
| Risk Constraints (Advanced) | Max DD%, Max Total Lot, Min Margin Level%, Max Loss $ | ✅ |
| Form validation | Kiểm tra input hợp lệ trước khi tính | ✅ |
| Disclaimer | "Not financial advice" ở mọi màn hình | ✅ |
| Banner ad | AdMob test banner ở bottom | ✅ |

### 2. Risk Dashboard (Màn hình kết quả chính)

| Tính năng | Mô tả | Status |
|---|---|---|
| Survivable Levels | Số level có thể sống sót / tổng level | ✅ |
| Max Drawdown % | Drawdown tối đa (tính đúng từ worst-case P/L) | ✅ |
| Estimated Stop-out Price | Giá ước tính stop-out (interpolation) | ✅ |
| Basket Breakeven | Giá hòa vốn basket (bao gồm commission + swap) | ✅ |
| Rebind Distance | Khoảng cách cần hồi để hòa vốn | ✅ |
| Total Exposure | Tổng exposure (lots) | ✅ |
| Constraint Check | PASS/FAIL theo constraint user đặt | ✅ |
| Grid Levels Table | Bảng chi tiết từng level (lot, entry, cum lot, margin) | ✅ |
| Assumptions Panel | Danh sách giả định đã dùng (Spread, Commission, Swap, Hedge mode, Rounding) | ✅ |
| Navigation buttons | Price Ladder, What-if, Reverse, Share, Saved | ✅ |
| Edit button | Quay về Calculator chỉnh tham số | ✅ |
| Pre-flight warnings | Banner đỏ khi constraint bị vi phạm | ✅ |
| Banner ad | AdMob test banner ở bottom | ✅ |

### 3. Price Ladder (Biểu đồ trực quan)

| Tính năng | Mô tả | Status |
|---|---|---|
| Line chart | Biểu đồ đường hiển thị grid levels (fl_chart) | ✅ |
| Level markers | Mỗi level là 1 điểm trên chart | ✅ |
| Avg Entry line | Đường entry trung bình (green, dashed) | ✅ |
| Basket BE line | Đường breakeven (orange, dashed) | ✅ |
| Stop-out line | Đường stop-out (red, dotted, nếu có) | ✅ |
| Tap to select | Tap vào level trên chart → hiện chi tiết | ✅ |
| Level details panel | Hiển thị Lot, Entry, Cum. Lot, Margin khi tap | ✅ |
| Legend | Giải thích màu sắc | ✅ |
| Banner ad | AdMob test banner ở bottom | ✅ |

### 4. What-if Slider (Phân tích kịch bản)

| Tính năng | Mô tả | Status |
|---|---|---|
| Price slider | Kéo để thay đổi giá giả định (±10%) | ✅ |
| Realtime update | Dashboard cập nhật realtime khi kéo | ✅ |
| Triggered levels | Số level đã trigger tại giá đó | ✅ |
| Drawdown % | Drawdown tại giá giả định | ✅ |
| Margin Level | Margin level tại giá giả định | ✅ |
| Floating P/L | Lỗ/lãi tại giá giả định | ✅ |
| Quick State Inspector | Nhập giá thủ công → thấy trạng thái ngay | ✅ |
| Constraint status | Kiểm tra constraint tại giá giả định | ✅ |
| Banner ad | AdMob test banner ở bottom | ✅ |

### 5. Reverse Mode (Tìm Max Lot)

| Tính năng | Mô tả | Status |
|---|---|---|
| Constraint inputs | Nhập Max DD%, Min Margin Level%, Max Lot, Max Loss | ✅ |
| Binary search solver | Tìm Maximum Initial Lot thỏa mãn TẤT CẢ constraint | ✅ |
| Result display | Hiển thị max lot tìm được (font lớn, dễ thấy) | ✅ |
| Iteration count | Số iterations binary search (tối đa 20) | ✅ |
| Bottleneck constraint | Constraint chặt nhất quyết định kết quả | ✅ |
| All results | Danh sách kết quả tất cả constraint | ✅ |
| Validation | Yêu cầu ít nhất 1 constraint trước khi chạy | ✅ |
| Banner ad | AdMob test banner ở bottom | ✅ |

### 6. Save/Load Strategies

| Tính năng | Mô tả | Status |
|---|---|---|
| Save strategy | Lưu tên + toàn bộ spec + timestamp | ✅ |
| Load strategy | Tải lại → pushReplacement DashboardScreen | ✅ |
| Delete strategy | Xóa strategy đã lưu (với confirmation dialog) | ✅ |
| Max 5 strategies | Giới hạn MVP | ✅ |
| Persistence | Lưu offline bằng Hive (auto-corrupt recovery) | ✅ |
| Empty state | Icon + hướng dẫn khi chưa có strategy nào | ✅ |
| Banner ad | AdMob test banner ở bottom | ✅ |

### 7. Share as Image

| Tính năng | Mô tả | Status |
|---|---|---|
| Screenshot card | Card tổng hợp kết quả (screenshot package) | ✅ |
| Share via share_plus | Chia sẻ ảnh PNG | ✅ |
| Included info | Symbol, Direction, Lot, Multiplier, Levels, Distance, Survivable, DD, BE, Stop-out, Exposure | ✅ |
| Disclaimer | "Not financial advice" trên ảnh | ✅ |
| Banner ad | AdMob test banner ở bottom | ✅ |

### 8. Core Engine (Pure Dart — packages/grid_engine)

| Module | Mô tả |公式 | Status |
|---|---|---|---|
| GridBuilder | Tính lot + entry price theo level | lot(n) = initialLot × multiplier^(n-1) | ✅ |
| MarginCalculator | Margin theo 3 hedge modes | notional / leverage | ✅ |
| PnlCalculator | Floating P/L + Basket Breakeven | (close - entry) × direction × contractSize × lot | ✅ |
| SurvivalEngine | Deterministic survival analysis | Margin level > stop-out % | ✅ |
| ScenarioEngine | What-if table generation | Sweep prices ±10% | ✅ |
| ReverseSolver | Binary search max lot | Binary search trên [lotMin, lotMax] | ✅ |
| ConstraintEvaluator | PASS/FAIL checks | Objective comparison against user limits | ✅ |
| LotRounding | Round/Floor/Ceiling với lotStep | Clamp to [lotMin, lotMax] | ✅ |

### 9. Navigation & UX

| Tính năng | Mô tả | Status |
|---|---|---|
| SafeScaffold | PopScope + SafeArea cho Android 3-button nav | ✅ |
| Named routes | Deep link support (/dashboard, /what-if, etc.) | ✅ |
| AppNavigation helper | push, pushReplacement, popOrDashboard | ✅ |
| No dead ends | Mọi screen đều có thể quay về | ✅ |
| Direction selector | Buy/Sell toggle trên Calculator | ✅ |
| Theme | Light/Dark theo system settings | ✅ |

### 10. Infrastructure

| Tính năng | Mô tả | Status |
|---|---|---|
| AdMob integration | Banner ads với test_ads flag | ✅ |
| Sentry error tracking | Auto-capture crashes + 20% perf tracing | ✅ |
| SafeArea | Android 3-button navigation không che content | ✅ |
| Network security | HTTP allowed cho mọi domain (release APK) | ✅ |
| App icon | Custom icon (candlestick + grid pattern) | ✅ |
| CI/CD | GitHub Actions build debug APK | ✅ |
| Deep linking | Named routes cho web + mobile | ✅ |

### 11. Testing

| Loại test | Số lượng | Status |
|---|---|---|
| Unit tests (engine) | 37 tests | ✅ |
| Golden cases (MT5 data) | 12 scenarios (placeholder) | ✅ |
| Validation tests | 6 tests (skip khi chưa có data thật) | ✅ |
| Reverse Solver tests | 5 tests | ✅ |
| Edge case tests | 5 tests | ✅ |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                  UI LAYER (Flutter)              │
│  Quick Calculator | Dashboard | Price Ladder     │
│  What-if Slider | Reverse Mode | Save/Share      │
│  SafeScaffold + BannerAd (AdMob)                │
└───────────────────────▲─────────────────────────┘
                        │ Riverpod
┌───────────────────────┴─────────────────────────┐
│              APPLICATION / STATE LAYER           │
│  Providers: Strategy, Scenario, Constraint       │
│  AppConfig (test_ads flag)                       │
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

┌─────────────────────────────────────────────────┐
│              INFRASTRUCTURE                      │
│  AdMob (banner ads) | Sentry (error tracking)   │
│  GitHub Actions (CI/CD) | SafeArea (nav)         │
└─────────────────────────────────────────────────┘
```

---

## 📊 Tech Stack

| Thành phần | Technology | Version | Ghi chú |
|---|---|---|---|
| Framework | Flutter | 3.24.0 | Dart 3.5.0 |
| State management | Riverpod | 2.x | |
| Persistence | Hive | 2.x | Offline-first |
| Charts | fl_chart | 0.66.x | Price ladder |
| Share | screenshot + share_plus | 7.0.0 | Share as image |
| Ads | google_mobile_ads | 5.3.0 | Test mode |
| Error tracking | sentry_flutter | 8.14.0 | Auto-capture |
| Engine | Pure Dart | 3.x | Tách riêng, tái sử dụng |
| Tests | test package | 1.31.x | 37+ tests |
| CI/CD | GitHub Actions | - | Auto build APK |

---

## 🔄 User Flow

```
┌─────────────────┐
│ Quick Calculator │ ← Nhập tham số (Symbol, Direction, Lot, Multiplier, Distance, Levels)
└────────┬────────┘
         │ Calculate
         ▼
┌─────────────────┐
│   Dashboard     │ ← Xem 5 key metrics + constraint check + grid table
└────────┬────────┘
         │
    ┌────┴────┬──────────┬──────────┬──────────┬──────────┐
    ▼         ▼          ▼          ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ Price  │ │ What-if│ │Reverse │ │ Share  │ │ Saved  │
│ Ladder │ │ Slider │ │ Mode   │ │ Image  │ │ Strats │
│(chart) │ │(realtime)│ │(max lot)│ │(PNG)  │ │(Hive)  │
└────────┘ └────────┘ └────────┘ └────────┘ └────────┘
```

---

## 🎯 Hướng mở rộng — Tính năng nên thêm để giữ chân user

### Priority 1 — PHẢI CÓ NGAY (MVP+)

| # | Tính năng | Lý do giữ chân user | Difficulty | Effort |
|---|---|---|---|---|
| 1 | **Custom Broker Profile** | User nhập spread/commission/swap thật theo broker → kết quả chính xác hơn | Easy | 1-2h |
| 2 | **ATR Reference** | Nhập ATR → hiển thị survival/ATR ratio → trader hiểu rõ "còn bao nhiêu pips an toàn" | Easy | 1h |
| 3 | **Manual Grid Distance per level** | Cho phép distance riêng cho mỗi level (khoảng cách thực tế thường không đều) | Medium | 3-4h |
| 4 | **Export to JSON/CSV** | Lưu kết quả ra file để phân tích sau, import lại sau | Easy | 1-2h |
| 5 | **Dark/Light Theme toggle** | Cho phép user chọn theme thủ công (hiện tại chỉ theo system) | Easy | 30min |
| 6 | **History chart (Bar chart)** | Biểu đồ P/L theo từng level (bar chart) —直观 hơn line chart | Medium | 2-3h |
| 7 | **Stress Test Presets** | 1-tap test: Spread×2, Spread×5, Leverage↓ — giúp user thấy "worst case" nhanh | Easy | 1h |
| 8 | **Multi-symbol support** | Thêm GBPUSD, US30, BTCUSD, XAGUSD — mở rộng đối tượng user | Easy | 2h |

### Priority 2 — NÊN CÓ (Retention)

| # | Tính năng | Lý do giữ chân user | Difficulty | Effort |
|---|---|---|---|---|
| 9 | **Strategy Comparison A/B** | So sánh 2 strategy cạnh nhau → "chọn strategy nào tốt hơn" | Medium | 4-5h |
| 10 | **Configurable Grid Distance modes** | Fixed ($), % price, ATR-based — linh hoạt hơn | Medium | 3h |
| 11 | **Widget/App Lock** | PIN/biometric bảo mật — trader không muốn người khác thấy strategy | Medium | 3h |
| 12 | **Push notification reminder** | Nhắc user check lại strategy khi market biến động mạnh | Hard | 5h |
| 13 | **Onboarding tutorial** | Hướng dẫn sử dụng lần đầu — giảm barrier cho user mới | Medium | 3h |
| 14 | **Form auto-save** | Tự lưu nháp khi exit — không mất dữ liệu khi app bị kill | Easy | 1h |
| 15 | **Undo/Redo** | Cho phép undo thay đổi — tránh mất config đã setup | Medium | 2h |

### Priority 3 — DELUXE (Engagement)

| # | Tính năng | Lý do giữ chân user | Difficulty | Effort |
|---|---|---|---|---|
| 16 | **Live price feed** | Kết nối websocket lấy giá real-time — app dùng được hàng ngày | Hard | 8h |
| 17 | **Backtest with OHLC** | Chạy strategy trên dữ liệu lịch sử — "strategy này đã sống sót trong crash 2020 không?" | Very Hard | 20h |
| 18 | **Monte Carlo simulation** | Phân tích xác suất survival — chuyên sâu hơn | Very Hard | 15h |
| 19 | **Risk Score (0-100)** | Đánh giá rủi ro tổng hợp — "strategy này được 72/100" — dễ hiểu cho newbie | Medium | 3h |
| 20 | **Social sharing** | Share kết quả lên Facebook/Zalo/Telegram — viral marketing | Medium | 2h |
| 21 | **News/Macro calendar** | Hiển thị sự kiện kinh tế quan trọng — "đừng chạy grid khi Fed họp" | Medium | 4h |

### Priority 4 — PRO (Monetization)

| # | Tính năng | Lý do giữ chân user | Difficulty | Effort |
|---|---|---|---|---|
| 22 | **Cloud sync** | Đồng bộ strategy giữa nhiều thiết bị | Hard | 10h |
| 23 | **Team sharing** | Chia sẻ strategy trong nhóm | Hard | 8h |
| 24 | **Advanced analytics dashboard** | Dashboard nâng cao với nhiều chart, heatmap | Medium | 5h |
| 25 | **API integration (MT4/MT5)** | Kết nối tự động — "import từ MT5" | Very Hard | 20h |
| 26 | **Subscription plan** | Free vs Pro features — monetization | Medium | 5h |
| 27 | **White-label** | Cho phép broker customize branding | Hard | 10h |

---

## 🔧 Kỹ thuật cần cải thiện

| # | Vấn đề | Hiện tại | Nên làm | Priority |
|---|---|---|---|---|
| 1 | **i18n** | Chưa có | Thêm tiếng Việt + English | P1 |
| 2 | **Error handling** | Basic try-catch | User-friendly error messages + retry | P1 |
| 3 | **Loading states** | CircularProgressIndicator | Skeleton loading / shimmer | P2 |
| 4 | **Empty states** | Text đơn giản | Illustration + CTA button | P2 |
| 5 | **Responsive layout** | Mobile-first only | Tablet/Desktop layout | P3 |
| 6 | **Accessibility** | Chưa có | Screen reader, semantic labels | P3 |
| 7 | **Performance** | OK nhưng chưa optimize | Lazy loading, image cache | P3 |

---

## 📐 Design Guidelines

### Colors
```dart
Primary:      #1E3A5F (Dark Navy)
Background:   #FFFFFF (Light) / #0D1B2A (Dark)
Accent:       #FFD700 (Gold)
Success:      #4CAF50 (Green)
Warning:      #FF9800 (Orange)
Danger:       #F44336 (Red)
Surface:      #F5F5F5 (Light) / #1A1A2E (Dark)
```

### Typography
```dart
Headline:     24-32px, Bold — Key metrics
Title:        18-20px, SemiBold — Section headers
Body:         14-16px, Regular — Main content
Caption:      12px, Regular — Labels, hints
```

### Spacing
```dart
XS: 4px
S:  8px
M:  16px
L:  24px
XL: 32px
```

### App Icon
```dart
Background: Dark navy (#0D1B2A) với grid pattern
Candlesticks: Green (#4CAF50) up, Red (#F44336) down
Trend line: Gold (#FFD700) upward arrow
```

---

## 📝 Notes cho AI Research

### Context quan trọng:
1. **App là offline-first** — không có backend, không cần auth
2. **Target users là trader** — cần chính xác về số liệu tài chính
3. **Không được dùng từ "profit/guaranteed/safe"** — vi phạm app store policy
4. **Mỗi kết quả phải có disclaimer** — "Not financial advice"
5. **Engine tách riêng** — có thể tái sử dụng cho project khác
6. **Đã có AdMob + Sentry** — nhưng test mode, cần switch sang real IDs trước khi publish
7. **Đã có SafeArea** — content không bị che bởi Android 3-button nav

### Constraints:
- Không dùng package financial bên thứ 3 — tự viết để kiểm soát
- Không fetch data real-time ở MVP — giữ offline
- Không làm PDF ở MVP — chỉ share image
- Tối đa 5 strategies saved ở MVP
- Phải pass flutter analyze (chỉ info warnings)
- Phải pass 37+ engine tests

### Success metrics:
- User mở app ≥ 3 lần/tuần
- User save ≥ 1 strategy
- User share ≥ 1 kết quả
- Rating ≥ 4.0 trên store
- Crash rate < 1% (theo Sentry)

---

## 🚀 Release Checklist

### Before Beta:
- [ ] i18n (vi + en) — b锁ing cho store
- [ ] Onboarding screen — giảm barrier cho user mới
- [ ] Custom broker profiles — tính năng killer
- [ ] Stress test presets — 1-tap worst case
- [ ] Export to JSON/CSV — lưu kết quả
- [ ] Dark/Light theme toggle — user preference

### Before Launch:
- [ ] Switch AdMob from test to real IDs
- [ ] Add real AdMob App IDs to AndroidManifest.xml + config
- [ ] App store screenshots (iOS + Android)
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Beta test với 5-10 traders
- [ ] Fix all Sentry-reported crashes
- [ ] Optimize APK size (current ~96MB)
