# Phase 0 Tasks — Bug Fixes 0.1-0.6

## Status: ✅ ALL COMPLETE

## Task 0.1 — Fix ReverseSolver `currentPrice: 0`
- [x] Add `required double currentPrice` to `ReverseSolver.solve()`
- [x] Pass through `_satisfiesConstraints` and `_buildAndCheck`
- [x] Update UI call sites (`reverse_mode_screen.dart`, `risk_budget_screen.dart`)
- [x] Add regression test proving bug exists
- [x] All tests pass (58/58)

## Task 0.2 — Fix hardcoded `totalFloatingPnl: 0` / `maxDrawdownPercent: 0`
- [x] Calculate real worst-case PnL in `reverse_solver.dart _buildAndCheck`
- [x] Calculate real worst-case PnL in `survival_engine.dart maxSurvivableLevels`
- [x] Calculate real worst-case PnL in `strategy_provider.dart calculationResultProvider`
- [x] Add regression tests for Max DD and Max Loss constraints
- [x] All tests pass (58/58)

## Task 0.3 — Fix What-if rebuild + `isTriggered` always true
- [x] Add `GridBuilder.isTriggeredAtPrice()` static predicate
- [x] Fix `ScenarioEngine.generate()` — build grid once, use `isTriggeredAtPrice`
- [x] Fix `WhatIfScreen._calculateScenario()` — use static grid
- [x] Add `_evaluateConstraintsAtPrice()` for dynamic constraint display
- [x] Add regression tests (5 tests)
- [x] All tests pass (58/58)

## Task 0.4 — Fix Gap Scenario fake toggle
- [x] Create `GapAnalyzer` engine module
- [x] AtMarket mode: override entry prices to gap price
- [x] Update `gap_scenario_screen.dart` to use `GapAnalyzer`
- [x] Add regression tests (6 tests)
- [x] All tests pass (58/58)

## Task 0.5 — Fix Netting margin double-count
- [x] Update `MarginCalculator.totalMargin()` to accept `HedgeMode`
- [x] Netting: return last snapshot; hedgingFull: sum all
- [x] Replace manual sum loops in 6 consumer files
- [x] Add TODO for notional formula (Phase 1)
- [x] Add regression tests (5 tests)
- [x] All tests pass (58/58)

## Task 0.6 — Fix HedgingReduced on single-direction
- [x] `_calculateHedgingReduced` delegates to `_calculateHedgingFull`
- [x] Added TODO for multi-direction future
- [x] Add regression tests (3 tests)
- [x] All tests pass (58/58)

## Files Changed (14 files, +320/-102)

### Engine (7 files)
- `packages/grid_engine/lib/src/engine/margin_calculator.dart` — Bugs 0.5, 0.6
- `packages/grid_engine/lib/src/engine/reverse_solver.dart` — Bugs 0.1, 0.2
- `packages/grid_engine/lib/src/engine/survival_engine.dart` — Bugs 0.2, 0.5
- `packages/grid_engine/lib/src/engine/scenario_engine.dart` — Bugs 0.3, 0.5
- `packages/grid_engine/lib/src/engine/grid_builder.dart` — Bug 0.3
- `packages/grid_engine/lib/src/engine/constraint_evaluator.dart` — Bug 0.2
- `packages/grid_engine/lib/src/engine/gap_analyzer.dart` — Bug 0.4 (NEW)

### Models (1 file)
- `packages/grid_engine/lib/src/models/calculation_result.dart` — Bug 0.2

### UI (5 files)
- `app/lib/state/strategy_provider.dart` — Bugs 0.1, 0.2, 0.5
- `app/lib/screens/dashboard/dashboard_screen.dart` — Bugs 0.2
- `app/lib/screens/what_if/what_if_screen.dart` — Bugs 0.3, 0.5
- `app/lib/screens/gap_scenario/gap_scenario_screen.dart` — Bug 0.4
- `app/lib/screens/reverse_mode/reverse_mode_screen.dart` — Bug 0.1
- `app/lib/screens/risk_budget/risk_budget_screen.dart` — Bug 0.1

### Tests (6 files)
- `packages/grid_engine/test/reverse_solver_test.dart` — Bugs 0.1, 0.2
- `packages/grid_engine/test/whatif_triggered_test.dart` — Bug 0.3 (NEW)
- `packages/grid_engine/test/gap_scenario_test.dart` — Bug 0.4 (NEW)
- `packages/grid_engine/test/margin_netting_test.dart` — Bug 0.5 (NEW)
- `packages/grid_engine/test/hedging_reduced_test.dart` — Bug 0.6 (NEW)
- `packages/grid_engine/test/golden_cases_test.dart` — Bug 0.5
