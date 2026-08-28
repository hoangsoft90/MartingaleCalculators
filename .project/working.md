# Working — Grid Survival Simulator

> Last updated: 2026-08-28

## Current Status

**Phase**: Phase 0 + Phase 1 COMPLETE → Ready for Phase 2
**Test Suite**: 58/58 engine tests pass
**Build**: GitHub Actions debug APK (no keystore)

## Session Log

### 2026-08-28 — Phase 0 Bug Fixes + Phase 1 Features

#### Phase 0 — Bug Fixes (0.1-0.6)

| Bug | Description | Files Changed | Status |
|-----|-------------|---------------|--------|
| 0.1 | `currentPrice: 0` in ReverseSolver | `reverse_solver.dart`, `reverse_mode_screen.dart`, `risk_budget_screen.dart` | ✅ Fixed |
| 0.2 | `totalFloatingPnl: 0` / `maxDrawdownPercent: 0` hardcoded | `reverse_solver.dart`, `survival_engine.dart`, `strategy_provider.dart` | ✅ Fixed |
| 0.3 | What-if rebuilds grid + `isTriggered` always true | `grid_builder.dart`, `scenario_engine.dart`, `what_if_screen.dart` | ✅ Fixed |
| 0.4 | Gap Scenario Sequential vs AtMarket = same | `gap_analyzer.dart` (NEW), `gap_scenario_screen.dart` | ✅ Fixed |
| 0.5 | Netting margin double-count | `margin_calculator.dart`, 6 consumer files | ✅ Fixed |
| 0.6 | HedgingReduced factor on single-direction | `margin_calculator.dart` | ✅ Fixed |

#### Phase 1 — P0 Features (1.1-1.7)

| Feature | Description | New Files | Status |
|---------|-------------|-----------|--------|
| 1.1 | Failure/Bottleneck Explanation | `failure_explanation_panel.dart` | ✅ Complete |
| 1.2 | Risk Budget | `risk_budget_screen.dart` | ✅ Complete |
| 1.3 | Max Levels Solver | `max_levels_screen.dart` | ✅ Complete |
| 1.4 | Basket TP Simulator | `basket_tp_table.dart` | ✅ Complete |
| 1.5 | Existing Exposure (Synthetic Level 0) | `grid_builder.dart` (extended) | ✅ Complete |
| 1.6 | Gap Scenario (At Market) | `gap_analyzer.dart` (NEW), `gap_scenario_screen.dart` | ✅ Complete |
| 1.7 | Strategy Templates | `strategy_templates.dart`, `template_picker.dart` | ✅ Complete |

#### New Test Files Created
- `packages/grid_engine/test/whatif_triggered_test.dart` — 5 tests
- `packages/grid_engine/test/gap_scenario_test.dart` — 6 tests
- `packages/grid_engine/test/margin_netting_test.dart` — 5 tests
- `packages/grid_engine/test/hedging_reduced_test.dart` — 3 tests

#### OpenSpec Updated
- `openspec/config.yaml` — project context
- `openspec/specs/grid-survival-simulator/spec.md` — full spec
- `openspec/changes/archive/phase-0-bugfixes/` — archived
- `openspec/changes/archive/phase-1-p0-features/` — archived

## Pending Work

### Phase 2 — P1 Features (Not Started)

| Feature | Priority | Engine Module to Reuse |
|---------|----------|----------------------|
| 2.1 Lock & Find Optimizer + Feasible Range | ⭐⭐⭐⭐⭐ | ReverseSolver (sweep) |
| 2.2 Sensitivity Analysis | ⭐⭐⭐⭐ | SurvivalEngine (perturb) |
| 2.3 Stress Test Matrix / Heatmap | ⭐⭐⭐⭐ | ScenarioEngine (compose) |
| 2.4 Strategy Comparison / Battle | ⭐⭐⭐ | CalculationResult (side-by-side) |
| 2.5 Custom Grid Builder | ⭐⭐⭐ | GridBuilder (custom input) |
| 2.6 Strategy Versioning | ⭐⭐ | Hive schema (extend) |
| 2.7 ATR Reference copy fix | ⭐⭐ | Dashboard text only |

### Golden Cases (Phase 1 Validation)
- 12 placeholder scenarios in `golden_cases.json`
- Need 30-50 real scenarios from MT4/MT5
- Notional formula in `_calculateNetting` pending validation

## Key Decisions Made

| Decision | Rationale | ADR |
|----------|-----------|-----|
| `isTriggered: true` default in GridBuilder | Backward compat for PnlCalculator | Bug 0.3 |
| `totalMargin(levels, hedgeMode)` | Netting = last snapshot, not sum | Bug 0.5 |
| `hedgingReduced` = `hedgingFull` | Single-direction = no hedged portion | Bug 0.6 |
| Static grid in What-if/Scenario | Entry prices don't change with slider | Bug 0.3 |
| `GapAnalyzer` as separate module | Testable, reusable gap logic | Bug 0.4 |

## File Structure

```
packages/grid_engine/
├── lib/
│   ├── grid_engine.dart                    (barrel)
│   └── src/
│       ├── engine/
│       │   ├── grid_builder.dart           (build, isTriggeredAtPrice)
│       │   ├── margin_calculator.dart      (calculate, totalMargin)
│       │   ├── pnl_calculator.dart         (floatingPnl, breakeven, targetPnl)
│       │   ├── survival_engine.dart        (analyze, maxSurvivableLevels)
│       │   ├── scenario_engine.dart        (generate, interpolate)
│       │   ├── reverse_solver.dart         (solve)
│       │   ├── constraint_evaluator.dart   (evaluate, findFirstViolation)
│       │   └── gap_analyzer.dart           (analyze)
│       ├── models/ (8 model files)
│       └── rounding/
└── test/
    ├── golden_cases_test.dart
    ├── reverse_solver_test.dart
    ├── whatif_triggered_test.dart
    ├── gap_scenario_test.dart
    ├── margin_netting_test.dart
    ├── hedging_reduced_test.dart
    ├── lot_rounding_test.dart
    ├── margin_calculator_test.dart
    ├── survival_engine_test.dart
    └── edge_cases_test.dart

app/lib/
├── main.dart
├── state/strategy_provider.dart
├── config/app_config.dart
├── persistence/hive_repository.dart
├── screens/
│   ├── dashboard/
│   ├── quick_calculator/
│   ├── price_ladder/
│   ├── what_if/
│   ├── reverse_mode/
│   ├── share/
│   ├── saved_strategies/
│   ├── risk_budget/
│   ├── max_levels/
│   ├── gap_scenario/
│   └── about/
├── widgets/
│   ├── safe_scaffold.dart
│   ├── banner_ad_widget.dart
│   ├── failure_explanation_panel.dart
│   └── basket_tp_table.dart
└── data/
    └── strategy_templates.dart
```
