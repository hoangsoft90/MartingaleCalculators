# AI Rules — Grid Survival Simulator

## Project Identity
- **Name**: Grid Survival Simulator
- **Package**: `com.gridsurvival.grid_survival_simulator`
- **Repo**: https://github.com/hoangsoft90/MartingaleCalculators
- **Branch**: main

## Architecture Rules

### Engine vs UI Separation
- `packages/grid_engine/` — Pure Dart, NO Flutter dependency. All calculation logic lives here.
- `app/` — Flutter UI layer. Never put calculation logic in UI files.
- Engine modules: `GridBuilder`, `MarginCalculator`, `PnlCalculator`, `SurvivalEngine`, `ScenarioEngine`, `ReverseSolver`, `ConstraintEvaluator`, `GapAnalyzer`.

### State Management
- **Riverpod** for all state. Providers in `app/lib/state/strategy_provider.dart`.
- Key providers: `currentPriceProvider`, `strategySpecProvider`, `accountSpecProvider`, `constraintSetProvider`, `calculationResultProvider`.
- Never use `setState` for shared state — only for local UI state (sliders, toggles).

### File Naming
- Kebab-case for files: `gap_scenario_screen.dart`, `margin_calculator.dart`
- Snake_case for Dart variables/functions
- UPPER_SNAKE for constants

## Testing Rules

### Engine Tests (MANDATORY)
- Every engine change MUST have corresponding unit test in `packages/grid_engine/test/`
- Run `dart test` from `packages/grid_engine/` before any commit
- Current test count: 58+ tests across 8 test files
- Golden cases: `test/golden_cases/golden_cases.json` (12 placeholder scenarios)

### Test Naming
- `test/<module>_test.dart` for unit tests
- `test/golden_cases_test.dart` for golden case validation
- Regression tests: prefix with `REGRESSION:` in test name

### What to Test
- Edge cases: 0 levels, lot exceeds lotMax, large numbers
- Hedge modes: hedgingFull, hedgingReduced, netting
- Directions: buy and sell grids
- Constraint evaluation: PASS and FAIL scenarios

## Code Rules

### MarginCalculator
- `totalMargin(levels, hedgeMode)` — hedge-mode-aware. Netting returns last snapshot; hedgingFull sums all.
- `hedgingReduced` behaves as `hedgingFull` for single-direction grids (no opposing positions).
- Notional formula in `_calculateNetting` is PENDING validation against Golden Cases (Phase 1).

### ReverseSolver
- ALWAYS requires `currentPrice` parameter (never hardcoded 0).
- Binary search precision stops at `lotStep` multiples.

### GridBuilder
- `build()` sets `isTriggered: true` for all levels (backward compat for PnL calculator).
- Dynamic trigger check uses `GridBuilder.isTriggeredAtPrice(level, price, direction)`.
- BUY: triggered when `price <= entryPrice`. SELL: triggered when `price >= entryPrice`.

### ConstraintEvaluator
- `evaluate()` receives real `totalFloatingPnl` and `maxDrawdownPercent` (never hardcoded 0).
- `findFirstViolation()` returns first violated constraint with level and excess.

### GapAnalyzer
- Sequential: each level fills at its own entry price.
- AtMarket: all triggered levels fill at gap price.

## Build Rules

### APK Build
- **NEVER build APK locally** — use GitHub Actions only
- GitHub Actions workflow: `.github/workflows/build-apk.yml`
- Debug APK (no keystore) via gradle direct (no EAS token)
- Repo: `https://github.com/hoangsoft90/MartingaleCalculators`

### AdMob
- Test ads: `test_ads=true` in config
- Real ads: `enable_ads=true` in config
- Banner only on: QuickCalculator, SavedStrategies
- No banner on: Dashboard, PriceLadder, WhatIf, ReverseMode, Share, RiskBudget, MaxLevels, GapScenario

## Commit Rules

### Message Format
```
<type>: <description>

<optional body>

🤖 Generated with Codebuff
Co-Authored-By: Codebuff <noreply@codebuff.com>
```

### Types
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code restructuring
- `test:` adding/updating tests
- `docs:` documentation only

### What to Commit
- Engine changes + corresponding tests in same commit
- UI changes separately from engine changes when possible
- Never commit secrets, API keys, or `.env` files

## Phase Status

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 0 | ✅ COMPLETE | Bug fixes 0.1-0.6 (Calculation Audit) |
| Phase 1 | ✅ COMPLETE | P0 Features (7 features) |
| Phase 2 | 📋 PLANNED | P1 Features (Lock & Find, Sensitivity, etc.) |
| Phase 3 | ❌ NOT PLANNED | Live Feed, Monte Carlo, etc. |

## Common Pitfalls

1. **Netting margin double-count**: Always use `MarginCalculator.totalMargin(levels, hedgeMode)` — never sum `requiredMargin` manually.
2. **What-if grid rebuild**: Grid must be built ONCE at original price. Use `isTriggeredAtPrice()` for dynamic count.
3. **ReverseSolver currentPrice**: Always pass real price from `currentPriceProvider`, never hardcode.
4. **Constraint values**: Never pass `totalFloatingPnl: 0` or `maxDrawdownPercent: 0` to `ConstraintEvaluator.evaluate()`.
5. **HedgingReduced**: Single-direction grid = full margin. Don't apply `hedgedMarginFactor`.
