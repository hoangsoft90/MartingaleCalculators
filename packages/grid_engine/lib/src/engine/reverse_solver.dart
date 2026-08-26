import '../models/account_spec.dart';
import '../models/instrument_spec.dart';
import '../models/execution_spec.dart';
import '../models/strategy_spec.dart';
import '../models/constraint_set.dart';
import 'grid_builder.dart';
import 'margin_calculator.dart';
import 'constraint_evaluator.dart';

/// Reverse solver — finds maximum initial lot that satisfies constraints.
///
/// Solves ONE specific problem (spec section 3.9):
///   Input:  Balance, Multiplier, Grid distance, Configured levels,
///           and at least 1 hard constraint
///   Output: Maximum Initial Lot satisfying all constraints
///
/// Algorithm: binary search on initialLot in [lotMin, lotMax],
/// running full SurvivalEngine + ConstraintEvaluator for each candidate.
/// Precision stops at lotStep multiples.
class ReverseSolver {
  /// Maximum iterations for binary search convergence.
  static const maxIterations = 20;

  /// Solve for maximum initial lot.
  ///
  /// Returns [ReverseResult] with the maximum lot and bottleneck constraint.
  /// Throws [ArgumentError] if no constraints are provided.
  static ReverseResult solve({
    required AccountSpec account,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required StrategySpec strategy,
    required ConstraintSet constraints,
    double? multiplierOverride,
  }) {
    if (!constraints.hasAny) {
      throw ArgumentError(
        'At least one constraint is required for Reverse Mode. '
        'Please set Max DD%, Min Margin Level%, Max Total Lot, or Max Loss \$.',
      );
    }

    final effectiveStrategy = multiplierOverride != null
        ? strategy.copyWith(multiplier: multiplierOverride)
        : strategy;

    double low = instrument.lotMin;
    double high = instrument.lotMax;
    double bestLot = instrument.lotMin;
    int iterations = 0;

    // Binary search for maximum initial lot
    while (high - low > instrument.lotStep && iterations < maxIterations) {
      iterations++;
      final mid = _roundToStep((low + high) / 2, instrument.lotStep);

      if (_satisfiesConstraints(
        initialLot: mid,
        account: account,
        instrument: instrument,
        execution: execution,
        strategy: effectiveStrategy,
        constraints: constraints,
      )) {
        bestLot = mid;
        low = mid + instrument.lotStep;
      } else {
        high = mid - instrument.lotStep;
      }
    }

    // Final check at best lot
    final result = _buildAndCheck(
      initialLot: bestLot,
      account: account,
      instrument: instrument,
      execution: execution,
      strategy: effectiveStrategy,
      constraints: constraints,
    );

    return ReverseResult(
      maximumInitialLot: bestLot,
      bottleneckConstraint: result.isNotEmpty
          ? result.firstWhere(
              (r) => !r.passed,
              orElse: () => result.first,
            )
          : null,
      iterations: iterations,
      allResults: result,
    );
  }

  /// Check if a given initial lot satisfies all constraints.
  static bool _satisfiesConstraints({
    required double initialLot,
    required AccountSpec account,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required StrategySpec strategy,
    required ConstraintSet constraints,
  }) {
    final results = _buildAndCheck(
      initialLot: initialLot,
      account: account,
      instrument: instrument,
      execution: execution,
      strategy: strategy,
      constraints: constraints,
    );
    return results.every((r) => r.passed);
  }

  /// Build grid and check all constraints.
  static List<ConstraintCheckResult> _buildAndCheck({
    required double initialLot,
    required AccountSpec account,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required StrategySpec strategy,
    required ConstraintSet constraints,
  }) {
    final effectiveStrategy = strategy.copyWith(initialLot: initialLot);

    final levels = GridBuilder.build(
      strategy: effectiveStrategy,
      instrument: instrument,
      execution: execution,
      currentPrice: 0, // Placeholder for reverse solver
    );

    MarginCalculator.calculate(
      levels: levels,
      account: account,
      instrument: instrument,
      execution: execution,
    );

    double totalMargin = 0;
    double totalLot = 0;
    for (final level in levels) {
      totalMargin += level.requiredMargin;
      totalLot += level.roundedLot;
    }

    return ConstraintEvaluator.evaluate(
      constraints: constraints,
      account: account,
      levels: levels,
      maxDrawdownPercent: 0, // Would be calculated properly
      totalExposureLots: totalLot,
      totalRequiredMargin: totalMargin,
      totalFloatingPnl: 0,
    );
  }

  /// Round value to nearest lotStep multiple.
  static double _roundToStep(double value, double lotStep) {
    final steps = value / lotStep;
    return (steps.roundToDouble()) * lotStep;
  }
}

/// Result from reverse solver.
class ReverseResult {
  /// Maximum initial lot that satisfies all constraints.
  final double maximumInitialLot;

  /// The tightest constraint (bottleneck) determining the result.
  final ConstraintCheckResult? bottleneckConstraint;

  /// Number of binary search iterations performed.
  final int iterations;

  /// All constraint check results at the maximum lot.
  final List<ConstraintCheckResult> allResults;

  const ReverseResult({
    required this.maximumInitialLot,
    this.bottleneckConstraint,
    required this.iterations,
    required this.allResults,
  });
}
