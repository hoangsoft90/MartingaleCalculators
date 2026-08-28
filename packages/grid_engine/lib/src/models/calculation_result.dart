import 'grid_level.dart';
import 'constraint_set.dart';

/// Aggregated calculation result from the engine.
///
/// Contains all outputs needed for the Dashboard and scenario displays.
class CalculationResult {
  /// All grid levels with their calculated properties.
  final List<GridLevel> levels;

  /// Total exposure in lots across all triggered levels.
  final double totalExposureLots;

  /// Volume-weighted average entry price.
  final double averageEntryPrice;

  /// Price at which the basket breaks even (including spread/commission).
  final double basketBreakevenPrice;

  /// Distance in price units from current price to breakeven.
  final double rebindDistanceToBreakeven;

  /// Number of levels that can be survived before stop-out.
  final int survivableLevels;

  /// Estimated stop-out price (null if not reached within configured levels).
  final double? estimatedStopOutPrice;

  /// Maximum drawdown percentage observed.
  final double maxDrawdownPercent;

  /// Total required margin across all levels (in account currency).
  final double totalRequiredMargin;

  /// Results of constraint checks.
  final List<ConstraintCheckResult> constraintResults;

  /// List of assumptions used in this calculation (displayed transparently).
  final List<String> assumptionsUsed;

  const CalculationResult({
    required this.levels,
    required this.totalExposureLots,
    required this.averageEntryPrice,
    required this.basketBreakevenPrice,
    required this.rebindDistanceToBreakeven,
    required this.survivableLevels,
    this.estimatedStopOutPrice,
    required this.maxDrawdownPercent,
    required this.totalRequiredMargin,
    required this.constraintResults,
    required this.assumptionsUsed,
  });
}
