# Phase 1 — P0 Core Decision Features

## Summary
Implement 7 P0 features that transform the app from "calculate and close" to "Create → Stress Test → Fail → Adjust → Compare → Save" workflow. All features reuse existing engine modules.

## Scope

### 1.1 Failure/Bottleneck Explanation
- `ConstraintEvaluator.findFirstViolation()` returns first violated constraint with level and excess
- `FailureExplanationPanel` widget shows bottleneck on Dashboard
- Reuses existing `ConstraintEvaluator` + `SurvivalEngine`

### 1.2 Risk Budget
- `RiskBudgetScreen` — user enters Max Loss $, solver returns Max Initial Lot
- Reuses existing `ReverseSolver` with `maxLossAmount` constraint

### 1.3 Max Levels Solver
- `SurvivalEngine.maxSurvivableLevels()` — finds max levels before stop-out or constraint violation
- `MaxLevelsScreen` — displays max levels with per-level PASS/FAIL breakdown

### 1.4 Basket TP Simulator
- `PnlCalculator.priceForTargetPnl()` — solves reverse equation for target P/L
- `BasketTPTable` widget — shows BE / +$50 / +$100 / +$200 prices

### 1.5 Existing Exposure (Synthetic Level 0)
- `GridBuilder.buildWithExistingExposure()` — injects Level 0 from open position
- Accepts equity, floating PnL, total lots (3 inputs only)

### 1.6 Gap Scenario (ExecutionMode.atMarket)
- `ExecutionMode` enum added to `ExecutionSpec`
- `GapAnalyzer` module — Sequential vs At Market execution
- AtMarket: all triggered levels use gap price as entry

### 1.7 Strategy Templates
- `strategy_templates.dart` — Low/Medium/High multiplier presets
- `TemplatePicker` — shows risk preview before applying

## Non-Goals
- P1 features (Lock & Find, Sensitivity, etc.)
- Engine refactoring
- Multi-direction grid support

## Test Evidence
- 58/58 engine tests pass
- Each feature has dedicated regression tests
