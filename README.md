# Grid Survival Simulator

> Stress-test your Grid strategy before the market does.

A offline-first analytical tool for traders to evaluate grid trading strategy risk before going live. **Not financial advice.**

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-blue)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🎯 What It Does

Grid Survival Simulator helps traders answer critical questions:

- **How many levels** can your account survive before stop-out?
- **Where is the basket breakeven** — how far does price need to rebound?
- **What's the maximum drawdown** under adverse conditions?
- **Are your risk constraints** being violated?

### What It Does NOT Do

- ❌ Predict market direction
- ❌ Generate trading signals
- ❌ Guarantee any outcome
- ❌ Replace proper risk management

---

## 📱 Screenshots

| Quick Calculator | Dashboard | Price Ladder | What-if Slider |
|---|---|---|---|
| Input form with collapsible sections | 5 key metrics + constraint check | Visual grid levels on price axis | Realtime scenario analysis |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                  UI LAYER (Flutter)              │
│  Quick Calculator | Dashboard | Price Ladder     │
│  What-if Slider | Reverse Mode | Save/Share      │
└───────────────────────▲─────────────────────────┘
                        │ Riverpod
┌───────────────────────┴─────────────────────────┐
│              APPLICATION / STATE LAYER           │
│  Providers: Strategy, Scenario, Constraint       │
└───────────────────────▲─────────────────────────┘
                        │ Pure Dart
┌───────────────────────┴─────────────────────────┐
│           CORE ENGINE (packages/grid_engine)     │
│  Models + Calculations — 100% unit-testable      │
│  NO Flutter, Hive, or UI dependency              │
└───────────────────────▲─────────────────────────┘
                        │
┌───────────────────────┴─────────────────────────┐
│              PERSISTENCE (Hive, offline)         │
│  Saved Strategies | Instrument Specs | Settings  │
└─────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Engine is pure Dart** — can be used in any Dart/Flutter project, tested independently
2. **No financial libraries** — all formulas hand-written for full control and testability
3. **Offline-first** — no internet required, no data sent anywhere
4. **Objective metrics only** — PASS/FAIL against user-defined constraints, no "safe/dangerous" labels

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK 3.x

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd MartingaleCalculators

# Install engine dependencies
cd packages/grid_engine
dart pub get

# Install app dependencies
cd ../../app
flutter pub get
```

### Run Tests

```bash
# Run all engine tests (37 tests)
cd packages/grid_engine
dart test

# Run with verbose output
dart test --reporter expanded
```

### Run App

```bash
cd app
flutter run
```

---

## 📊 Features

### MVP (Implemented)

| Feature | Description |
|---|---|
| **Symbols** | XAUUSD, EURUSD (extensible architecture) |
| **Grid Types** | Fixed distance, manual distance per level |
| **Lot Sizing** | Initial lot + multiplier (Martingale-style) |
| **Rounding** | Round/Floor/Ceiling with lotStep clamping |
| **Execution Costs** | Spread, commission, swap (optional) |
| **Hedge Modes** | Netting, Hedging Full, Hedging Reduced |
| **Survival Analysis** | Deterministic level-by-level evaluation |
| **Basket Breakeven** | Price where basket breaks even (incl. costs) |
| **Price Ladder** | Visual chart of grid levels (fl_chart) |
| **What-if Slider** | Realtime scenario analysis |
| **Quick State Inspector** | Enter price → see instant metrics |
| **Reverse Mode** | Find max initial lot given constraints |
| **Risk Constraints** | PASS/FAIL checks (user-defined limits) |
| **Pre-flight Check** | Validation before showing results |
| **Save/Load** | Persist up to 5 strategies (Hive) |
| **Share as Image** | Export summary card via screenshot |

### Not in MVP

- Monte Carlo simulation
- Dynamic/ATR-based grid distance
- Multi-pair correlation
- Backtest with OHLC history
- PDF export
- Partial close logic

---

## 🧮 Engine Formulas

### Lot per Level

```
rawLot(n) = initialLot × multiplier^(n-1)
roundedLot(n) = applyRounding(rawLot(n), lotStep, mode)
```

### Entry Price (with Spread)

```
Buy:  entryPrice = midPrice + spread/2 × tickSize  (Ask)
Sell: entryPrice = midPrice - spread/2 × tickSize  (Bid)
```

### Margin Required

```
notional = roundedLot × contractSize × entryPrice
margin = notional / leverage
```

### Floating P/L

```
closePrice = direction == buy
  ? assumedPrice - spread/2 × tickSize  (Bid)
  : assumedPrice + spread/2 × tickSize  (Ask)

pnl = (closePrice - entryPrice) × direction × contractSize × lot
    - commission × lot
    - swap × lot × holdingDays
```

### Basket Breakeven

```
breakevenPrice = averageEntry ± (totalCost / (totalLot × contractSize))
```

### Survival Analysis

```
marginLevel = (equity + floatingPnl) / totalMargin × 100
survivableLevels = max level where marginLevel > stopOutLevel
```

---

## 🧪 Testing

### Test Structure

```
packages/grid_engine/test/
├── golden_cases_test.dart      # Validation against MT5 data
├── lot_rounding_test.dart      # Rounding edge cases
├── margin_calculator_test.dart # Margin formulas
├── survival_engine_test.dart   # Survival analysis
├── reverse_solver_test.dart    # Binary search solver
├── edge_cases_test.dart        # Overflow, flat grid, etc.
└── golden_cases/
    ├── golden_cases.json       # 12 test scenarios
    └── mt5_data_template.csv   # Template for real data
```

### Running Tests

```bash
cd packages/grid_engine

# All tests
dart test

# Specific file
dart test test/lot_rounding_test.dart

# With coverage
dart test --coverage=coverage
```

### Adding Real MT5 Data

1. Open `golden_cases.json`
2. Replace `"PLACEHOLDER"` with real values from MT5
3. Run `dart test` — validation tests auto-activate

---

## 📁 Project Structure

```
MartingaleCalculators/
├── packages/
│   └── grid_engine/              # Pure Dart engine
│       ├── lib/
│       │   ├── src/models/       # AccountSpec, InstrumentSpec, etc.
│       │   ├── src/engine/       # GridBuilder, SurvivalEngine, etc.
│       │   └── src/rounding/     # LotRounding
│       └── test/                 # 37 unit tests
│
├── app/                          # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── state/                # Riverpod providers
│   │   ├── persistence/          # Hive repository
│   │   └── screens/
│   │       ├── quick_calculator/ # Input form
│   │       ├── dashboard/        # Results display
│   │       ├── price_ladder/     # fl_chart visualization
│   │       ├── what_if/          # Slider + inspector
│   │       ├── reverse_mode/     # Max lot solver
│   │       ├── saved_strategies/ # Save/Load
│   │       └── share/            # Screenshot + share
│   └── pubspec.yaml
│
├── grid_survival_simulator_build_spec.md  # Full build spec
├── README.md
└── .gitignore
```

---

## 🔧 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| State | Riverpod |
| Charts | fl_chart |
| Persistence | Hive (offline) |
| Share | screenshot + share_plus |
| i18n | Flutter built-in |
| Engine | Pure Dart (no Flutter) |

---

## 📋 Golden Cases

12 test scenarios covering:

| Dimension | Coverage |
|---|---|
| Symbols | XAUUSD (8), EURUSD (4) |
| Direction | Buy (7), Sell (5) |
| Multiplier | 1.0, 1.3, 1.5, 2.0 |
| Levels | 5, 8, 10, 15, 20 |
| Rounding | Round, Floor, Ceiling |
| Hedge Mode | HedgingFull, Netting |
| Commission/Swap | With and Without |
| Constraints | With and Without |

See `packages/grid_engine/test/golden_cases/MT5_DATA_COLLECTION_GUIDE.md` for data collection instructions.

---

## ⚠️ Disclaimer

This is an **analytical/educational tool only**. It does not constitute financial advice. Actual broker outcomes may differ based on:

- Real-time spread fluctuations
- Slippage and execution delays
- Broker-specific margin calculations
- Market conditions not modeled

Always conduct proper risk management and consult a financial advisor before trading.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `dart test` in `packages/grid_engine/`
5. Run `flutter analyze` in `app/`
6. Submit a pull request

---

## 📧 Contact

For questions or feedback, please open an issue on GitHub.
