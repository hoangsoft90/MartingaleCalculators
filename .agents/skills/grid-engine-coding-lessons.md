# Skill: Grid Engine Coding Pitfalls

> Ghi lại từ 6 bug fixes (Phase 0) trong Grid Survival Simulator.
> Mỗi lần sửa engine code, đọc skill này TRƯỚC KHI viết code.

## 1. KHÔNG bao giờ hardcode placeholder values cho calculations

```
# SAI — always passes, constraint check vô nghĩa:
totalFloatingPnl: 0
maxDrawdownPercent: 0
currentPrice: 0

# ĐÚNG — tính giá trị thật trước khi evaluate:
worstCasePnl = PnlCalculator.calculateFloatingPnl(...)
maxDrawdownPercent = ((-worstCasePnl / account.equity) * 100).clamp(0, 100)
```

**Bài học**: Placeholder value = bug silent. Nếu cần giá trị "chưa biết", để `null` hoặc throw exception, KHÔNG dùng `0`.

## 2. Netting margin = cumulative snapshot, KHÔNG SUM

```
# SAI — double-count margin:
double totalMargin = 0;
for (final level in levels) {
  totalMargin += level.requiredMargin; // netting: mỗi level là cumulative snapshot!
}

# ĐÚNG — dùng hàm hedge-mode-aware:
final totalMargin = MarginCalculator.totalMargin(levels, execution.hedgeMode);
```

**Bài học**: Netting mode lưu `requiredMargin` dạng lũy kế. Sum tất cả = sai. Phân biệt rõ:
- **HedgingFull**: mỗi level độc lập → sum đúng
- **Netting**: cumulative → chỉ lấy level cuối cùng

## 3. Grid phải build 1 lần, không rebuild theo slider

```
# SAI — mỗi lần kéo slider rebuild toàn bộ entry price:
final levels = GridBuilder.build(..., currentPrice: sliderPrice);

# ĐÚNG — build 1 lần ở giá gốc, dùng isTriggeredAtPrice cho dynamic:
final levels = GridBuilder.build(..., currentPrice: originalPrice);
final triggeredCount = levels.where((l) =>
  GridBuilder.isTriggeredAtPrice(l, sliderPrice, direction)).length;
```

**Bài học**: Grid entry prices là "pending orders" — cố định khi strategy được tạo. What-if chỉ thay đổi `assumedPrice` để tính P/L.

## 4. Hedge mode reduced = hedgingFull cho single-direction

```
# SAI — áp factor cho toàn bộ position:
final margin = fullMargin * hedgedMarginFactor; // 0.5 → 50% margin!

# ĐÚNG — single-direction không có hedged portion:
if (isSingleDirection) {
  _calculateHedgingFull(levels, account, instrument, leverage);
} else {
  // Multi-direction: mới áp factor
}
```

**Bài học**: `hedgedMarginFactor` chỉ có ý nghĩa khi có vị thế đối ứng 2 chiều. Grid hiện tại 100% single-direction.

## 5. ConstraintEvaluator cần giá trị THẬT, không phải static

```
# SAI — hiển thị kết quả từ base calculation, không thay đổi khi slider chạy:
if (result != null && result.constraintResults.isNotEmpty) { ... }

# ĐÚNG — evaluate lại tại giá đang xem:
final constraintsAtPrice = _evaluateConstraintsAtPrice(sliderValue);
if (constraintsAtPrice.isNotEmpty) { ... }
```

**Bài học**: Constraint status phải được evaluate lại tại mỗi mức giá, không copy từ calculation gốc.

## 6. Logic tính toán nên ở engine layer, không ở UI

```
# SAI — logic trong UI, không test được:
class _WhatIfScreenState {
  ScenarioPoint _calculateScenario(double price) {
    final levels = GridBuilder.build(...); // logic trong UI!
  }
}

# ĐÚNG — logic trong engine, UI gọi:
class GapAnalyzer {
  static GapAnalysisResult analyze({...}) { ... } // engine layer, test được
}
```

**Bài học**: UI chỉ display + call engine. Tất cả logic tính toán phải ở `packages/grid_engine/` để unit test được.

## 7. ReverseSolver cần currentPrice thật

```
# SAI — entry price tính từ mid price = 0:
currentPrice: 0, // Placeholder

# ĐÚNG — truyền giá thật từ UI:
currentPrice: ref.read(currentPriceProvider),
```

**Bài học**: `currentPrice` là input bắt buộc cho grid calculation. Không bao giờ hardcode `0` hay bất kỳ giá nào.

## 8. GapAnalyzer phải ở engine layer để test được

```
# SAI — logic gap scenario trong UI:
final triggeredLevels = <GridLevel>[];
for (final level in levels) {
  if (level.entryPrice >= gapPrice) triggeredLevels.add(level);
}
// Không test được!

# ĐÚNG — tách thành engine module:
class GapAnalyzer {
  static GapAnalysisResult analyze({...}) { ... }
}
// Test được, tái sử dụng được
```

**Bài học**: Khi logic phức tạp (nhiều điều kiện, nhiều mode), tách thành engine module thay vì để trong UI.

## 9. isTriggeredAlwaysTrue vs isTriggeredAtPrice

```
# GridBuilder.build()设置 isTriggered: true cho TẤT CẢ levels
# → PnlCalculator dùng isTriggered để filter → backward compat

# But what-if cần dynamic count:
GridBuilder.isTriggeredAtPrice(level, price, direction)
// BUY: price <= entryPrice
// SELL: price >= entryPrice
```

**Bài học**: Hai khái niệm khác nhau:
- `level.isTriggered` = static, backward compat cho PnL
- `isTriggeredAtPrice()` = dynamic, cho what-if/gap analysis

## Checklist trước khi merge engine change

1. ✅ Không có hardcoded `0` hay placeholder cho calculation values
2. ✅ `totalMargin()` gọi hàm `MarginCalculator.totalMargin(levels, hedgeMode)`
3. ✅ Grid build 1 lần, không rebuild trong loop
4. ✅ Constraint evaluation tại giá đang xem (nếu liên quan what-if)
5. ✅ Logic tính toán ở engine layer, có unit test
6. ✅ `currentPrice` truyền từ UI, không hardcode
7. ✅ Gap scenario logic ở engine layer (GapAnalyzer), không ở UI
8. ✅ Phân biệt `isTriggered` (static) vs `isTriggeredAtPrice` (dynamic)
9. ✅ Chạy `dart test` từ `packages/grid_engine/` — tất cả pass
