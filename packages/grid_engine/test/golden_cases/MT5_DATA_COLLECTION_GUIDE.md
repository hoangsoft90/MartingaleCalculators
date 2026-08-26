# MT5 Data Collection Guide

## Mục đích
Thu thập dữ liệu thật từ MT5 để validate engine calculations.

## Yêu cầu
- MT5 demo account (tốt nhất: Exness, IC Markets, hoặc broker đang dùng)
- Quote history 30 ngày (cho ATR reference nếu cần)
-creenshot cho mỗi test case

---

## Bước thu thập

### 1. Mở MT5 → Tools → Order Calculator (Alt+F2)

Screenshot面板 hiển thị:
- Contract Size
- Margin requirements
- Pip value

### 2. Thiết lập Grid Strategy trên MT5

```
1. Mở chart (XAUUSD hoặc EURUSD)
2. Đặt Parameters giống case trong CSV:
   - Direction (Buy/Sell)
   - Initial Lot
   - Multiplier
   - Distance
   - Levels
3. Chạy strategy trên DEMO account
```

### 3. Ghi lại kết quả khi margin level chạm stop-out

| MT5 Metric |对应 CSV Column |
|---|---|
| Total lots triggered | `expected_total_lots` |
| Average entry price | `expected_avg_entry` |
| Basket breakeven (tính tay) | `expected_basket_be` |
| Rebound distance | `expected_rebind_distance` |
| Survivable levels | `expected_survivable_levels` |
| Stop-out price | `expected_stop_out_price` |
| Max drawdown % | `expected_max_dd_percent` |

### 4. Chụp screenshot và điền tên file

```
mt5_screenshot_filename = XAUUSD_001_mt5.png
```

---

## Cách tính Basket Breakeven (nếu MT5 không hiển thị)

```
basketBreakevenPrice = averageEntry ± (totalCost / (totalLot × contractSize))

totalCost = (commissionPerLot × totalLot) + (swapPerLotPerDay × totalLot × holdingDays)

Buy grid:  basketBE = avgEntry + costPerUnit
Sell grid: basketBE = avgEntry - costPerUnit
```

---

## Cách tính Rebind Distance

```
rebindDistance = |basketBreakevenPrice - currentPrice|
```

---

## Cách tính Survivable Levels

```
1. Tính margin level tại mỗi level trigger:
   marginLevel = (equity + floatingPnl) / totalMargin × 100

2. Survivable = level cuối cùng mà marginLevel > stopOutLevel
```

---

## Cách tính Max Drawdown %

```
maxDrawdown = (equity - lowestEquity) / equity × 100
```

---

## Validation Criteria

Sau khi điền data, chạy test:
```bash
cd packages/grid_engine
dart test test/golden_cases_test.dart
```

Yêu cầu sai số:
- Margin/Stop-out: < 0.5-1%
- Survivable levels: chính xác 100%

---

## Template CSV Columns

| Column | Mô tả | Example |
|---|---|---|
| case_id | Unique ID | XAUUSD_001 |
| symbol | Trading symbol | XAUUSD |
| direction | buy/sell | buy |
| leverage | Account leverage | 500 |
| stop_out_percent | Stop-out level % | 20 |
| balance | Account balance | 10000 |
| equity | Current equity | 10000 |
| spread_points | Spread in points | 30 |
| commission_per_lot | Commission per lot | 0 |
| swap_per_lot_per_day | Swap per lot/day | 0 |
| holding_days | Days to hold | 0 |
| hedge_mode | hedgingFull/netting/hedgingReduced | hedgingFull |
| initial_lot | Lot for level 1 | 0.01 |
| multiplier | Lot multiplier | 1.5 |
| distance | Distance mode | fixed |
| fixed_distance | Fixed distance value | 10 |
| levels | Number of levels | 10 |
| rounding_mode | round/floor/ceiling | round |
| current_price | Current market price | 3300.00 |
| expected_total_lots | **FILL FROM MT5** | |
| expected_avg_entry | **FILL FROM MT5** | |
| expected_basket_be | **FILL FROM MT5** | |
| expected_rebind_distance | **FILL FROM MT5** | |
| expected_survivable_levels | **FILL FROM MT5** | |
| expected_stop_out_price | **FILL FROM MT5** | |
| expected_max_dd_percent | **FILL FROM MT5** | |
| expected_constraint_violated_at_level | **FILL IF APPLICABLE** | |
| mt5_screenshot_filename | Screenshot filename | XAUUSD_001_mt5.png |
| notes | Additional notes | |

---

## Quick Checklist

- [ ] Ít nhất 5 cases điền data thật
- [ ] Cả XAUUSD và EURUSD
- [ ] Cả Buy và Sell
- [ ] Có commission/swap cases
- [ ] Có flat grid (multiplier 1.0)
- [ ] Có different hedge modes
- [ ] Screenshots đính kèm
- [ ] Sai số < 1% so với MT5
