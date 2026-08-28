/// Grid Survival Simulator — Core Engine
///
/// Pure Dart calculation engine for grid trading strategy analysis.
/// No dependency on Flutter, Hive, or any UI framework.
library grid_engine;

// Models
export 'src/models/account_spec.dart';
export 'src/models/instrument_spec.dart';
export 'src/models/execution_spec.dart';
export 'src/models/strategy_spec.dart';
export 'src/models/grid_level.dart';
export 'src/models/constraint_set.dart';
export 'src/models/leverage_tier.dart';
export 'src/models/calculation_result.dart';

// Engine
export 'src/engine/grid_builder.dart';
export 'src/engine/margin_calculator.dart';
export 'src/engine/pnl_calculator.dart';
export 'src/engine/survival_engine.dart';
export 'src/engine/scenario_engine.dart';
export 'src/engine/reverse_solver.dart';
export 'src/engine/constraint_evaluator.dart';

// Rounding
export 'src/rounding/lot_rounding.dart';
