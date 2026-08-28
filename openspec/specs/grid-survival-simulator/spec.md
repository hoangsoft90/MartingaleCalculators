# Grid Survival Simulator — Specification

## Overview
Offline Flutter calculator for grid trading risk analysis. Computes survivability, margin requirements, drawdown, and P/L for martingale/grid strategies on forex (XAUUSD, EURUSD, etc.).

## Architecture
- **Engine** (`packages/grid_engine/`): Pure Dart, no Flutter dependency. 8 core modules.
- **UI** (`app/`): Flutter + Riverpod + Hive persistence.

## Engine Modules

| Module | Responsibility |
|--------|---------------|
| `GridBuilder` | Builds grid levels with entry prices and lot sizes. Static `isTriggeredAtPrice()` predicate. |
| `MarginCalculator` | Calculates margin per level. Supports hedgingFull, hedgingReduced, netting. Hedge-mode-aware `totalMargin()`. |
| `PnlCalculator` | Floating P/L, basket breakeven, target P/L price. |
| `SurvivalEngine` | Survival analysis through grid levels. `maxSurvivableLevels()` solver. |
| `ScenarioEngine` | What-if scenario generation at price intervals. Uses static grid. |
| `ReverseSolver` | Binary search for maximum initial lot under constraints. Requires real `currentPrice`. |
| `ConstraintEvaluator` | PASS/FAIL against user-defined risk constraints. `findFirstViolation()` for bottleneck analysis. |
| `GapAnalyzer` | Gap scenario analysis. Sequential vs At Market execution modes. |

## Data Models
- `AccountSpec`: balance, equity, leverage, stopOutLevelPercent
- `InstrumentSpec`: symbol, contractSize, tickSize, lotMin/Max/Step
- `ExecutionSpec`: spreadPoints, commission, swap, hedgeMode, executionMode
- `StrategySpec`: direction, initialLot, multiplier, fixedDistance, levels
- `ConstraintSet`: maxDrawdownPercent, minMarginLevelPercent, maxTotalLot, maxLossAmount
- `GridLevel`: index, entryPrice, roundedLot, cumulativeLot, requiredMargin, isTriggered
- `CalculationResult`: full engine output with constraint results

## Key Design Decisions
- `isTriggered` on GridLevel is always `true` (backward compat for PnL calculator). Dynamic trigger check uses `GridBuilder.isTriggeredAtPrice()`.
- `MarginCalculator.totalMargin()` is hedge-mode-aware: netting returns last snapshot, hedgingFull sums all.
- `hedgingReduced` behaves as `hedgingFull` for single-direction grids (no opposing positions).
- ReverseSolver requires `currentPrice` parameter (not hardcoded 0).
- ConstraintEvaluator receives real `totalFloatingPnl` and `maxDrawdownPercent` (not hardcoded 0).

## Testing
- 58+ engine unit tests across 8 test files
- Golden cases: 12 scenarios (placeholder status, awaiting MT5 real data)
- Regression tests for each bug fix (0.1-0.6)

## Phases
- **Phase 0** (COMPLETE): Bug fixes 0.1-0.6 — Calculation audit + release hygiene
- **Phase 1** (COMPLETE): P0 features — Failure explanation, Risk Budget, Max Levels, Basket TP, Existing Exposure, Gap Scenario, Strategy Templates
- **Phase 2** (PLANNED): P1 features — Lock & Find, Sensitivity, Stress Matrix, Comparison, Custom Grid, Versioning, ATR
