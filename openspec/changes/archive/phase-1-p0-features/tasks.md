# Phase 1 Tasks — P0 Features

## Status: ✅ ALL COMPLETE

## Task 1.1 — Failure/Bottleneck Explanation
- [x] Add `findFirstViolation()` to `ConstraintEvaluator`
- [x] Create `FailureExplanationPanel` widget
- [x] Add panel to DashboardScreen
- [x] Tests pass

## Task 1.2 — Risk Budget
- [x] Create `RiskBudgetScreen` with Max Loss input
- [x] Uses `ReverseSolver` with `maxLossAmount` constraint
- [x] Tests pass

## Task 1.3 — Max Levels Solver
- [x] Add `maxSurvivableLevels()` to `SurvivalEngine`
- [x] Create `MaxLevelsScreen`
- [x] Tests pass

## Task 1.4 — Basket TP Simulator
- [x] Add `priceForTargetPnl()` to `PnlCalculator`
- [x] Create `BasketTPTable` widget
- [x] Add to DashboardScreen
- [x] Tests pass

## Task 1.5 — Existing Exposure
- [x] Add `buildWithExistingExposure()` to `GridBuilder`
- [x] Synthetic Level 0 from open position
- [x] Tests pass

## Task 1.6 — Gap Scenario
- [x] Add `ExecutionMode` enum to `ExecutionSpec`
- [x] Create `GapAnalyzer` module
- [x] Sequential vs At Market execution
- [x] Create `GapScenarioScreen`
- [x] Tests pass

## Task 1.7 — Strategy Templates
- [x] Create `strategy_templates.dart` (3 presets)
- [x] Create `TemplatePicker` widget
- [x] Risk preview on selection
- [x] Tests pass

## Files Changed

### Engine (7 files)
- `constraint_evaluator.dart` — findFirstViolation
- `survival_engine.dart` — maxSurvivableLevels
- `pnl_calculator.dart` — priceForTargetPnl
- `grid_builder.dart` — buildWithExistingExposure, isTriggeredAtPrice
- `execution_spec.dart` — ExecutionMode enum
- `gap_analyzer.dart` (NEW) — GapAnalyzer
- `scenario_engine.dart` — static grid optimization

### UI (7 files)
- `dashboard_screen.dart` — FailureExplanationPanel, BasketTPTable
- `risk_budget_screen.dart` (NEW)
- `max_levels_screen.dart` (NEW)
- `gap_scenario_screen.dart` (NEW)
- `quick_calculator/template_picker.dart` (NEW)
- `what_if_screen.dart` — dynamic constraints
- `strategy_provider.dart` — real PnL

### Data (1 file)
- `strategy_templates.dart` (NEW)
