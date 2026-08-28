# Phase 0 — Calculation Audit + Bug Fixes

## Summary
Fix 6 critical/medium bugs in the grid trading engine that cause incorrect margin calculations, broken what-if analysis, and non-functional UI toggles. All fixes are in the engine layer with corresponding UI updates.

## Motivation
The engine had several hardcoded placeholder values (`currentPrice: 0`, `totalFloatingPnl: 0`, `maxDrawdownPercent: 0`) that made constraint checks always pass, rendering risk analysis meaningless. Additionally, the what-if and gap scenario features had broken UX (always-triggered levels, fake toggle).

## Scope

### Bug 0.1 — ReverseSolver `currentPrice: 0`
- **Problem**: Grid entry prices calculated from mid price = 0, making margin/constraint checks meaningless.
- **Fix**: Added `required double currentPrice` parameter, passed through to `GridBuilder.build()`.
- **Files**: `reverse_solver.dart`, `reverse_mode_screen.dart`, `risk_budget_screen.dart`

### Bug 0.2 — Hardcoded `totalFloatingPnl: 0` / `maxDrawdownPercent: 0`
- **Problem**: Max Loss and Max DD constraints always pass because values are hardcoded to 0.
- **Fix**: Calculate real worst-case PnL via `PnlCalculator.calculateFloatingPnl()` at adverse price before calling `ConstraintEvaluator.evaluate()`.
- **Files**: `reverse_solver.dart`, `survival_engine.dart`, `strategy_provider.dart`

### Bug 0.3 — What-if rebuilds grid + `isTriggered` always true
- **Problem**: Slider rebuilds entry prices at each price (should be static). `isTriggered` always true, so triggered count never changes.
- **Fix**: Added `GridBuilder.isTriggeredAtPrice()` static predicate. Grid built once at original price. What-if uses `isTriggeredAtPrice()` for dynamic count. Constraints re-evaluated at slider price.
- **Files**: `grid_builder.dart`, `scenario_engine.dart`, `what_if_screen.dart`

### Bug 0.4 — Gap Scenario Sequential vs AtMarket = same
- **Problem**: Toggle has no effect — both modes produce identical results.
- **Fix**: Created `GapAnalyzer` engine module. AtMarket mode overrides entry prices to gap price for all triggered levels.
- **Files**: `gap_analyzer.dart` (new), `gap_scenario_screen.dart`

### Bug 0.5 — Netting margin double-count
- **Problem**: `totalMargin` sums all levels' `requiredMargin`, but netting stores cumulative values — double-counts.
- **Fix**: `MarginCalculator.totalMargin(levels, hedgeMode)` — netting returns last snapshot; hedgingFull sums all.
- **Files**: `margin_calculator.dart`, all consumers (6 files)

### Bug 0.6 — HedgingReduced factor on single-direction
- **Problem**: `hedgedMarginFactor` applied to entire position despite no opposing positions.
- **Fix**: `_calculateHedgingReduced` delegates to `_calculateHedgingFull` for single-direction grids.
- **Files**: `margin_calculator.dart`

## Non-Goals
- Not fixing notional formula in `_calculateNetting` (awaiting Golden Cases Phase 1)
- Not adding multi-direction grid support
- Not changing P1/P2 features

## Test Evidence
- 58/58 engine tests pass
- 6 new regression test files added
- Each bug has dedicated regression test proving the fix
