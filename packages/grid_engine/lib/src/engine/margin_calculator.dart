import '../models/account_spec.dart';
import '../models/instrument_spec.dart';
import '../models/execution_spec.dart';
import '../models/grid_level.dart';

/// Calculates margin requirements for grid levels.
///
/// Implements formula from spec section 3.3:
///   notional(n) = roundedLot(n) × contractSize × entryPrice(n)
///   requiredMargin(n) = notional(n) / leverage
///
/// Supports all 3 hedge modes:
///   - netting: margin on net position only
///   - hedgingFull: full margin on all positions
///   - hedgingReduced: hedged portion uses hedgedMarginFactor
class MarginCalculator {
  /// Calculate required margin for each level and assign to [levels].
  ///
  /// Mutates [levels] in-place, setting requiredMargin on each level.
  static void calculate({
    required List<GridLevel> levels,
    required AccountSpec account,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
  }) {
    switch (execution.hedgeMode) {
      case HedgeMode.netting:
        _calculateNetting(levels, account, instrument);
        break;
      case HedgeMode.hedgingFull:
        _calculateHedgingFull(levels, account, instrument);
        break;
      case HedgeMode.hedgingReduced:
        _calculateHedgingReduced(
          levels,
          account,
          instrument,
          execution.hedgedMarginFactor,
        );
        break;
    }
  }

  /// Hedging Full: each level pays full margin independently.
  static void _calculateHedgingFull(
    List<GridLevel> levels,
    AccountSpec account,
    InstrumentSpec instrument,
  ) {
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final notional = level.roundedLot * instrument.contractSize * level.entryPrice;
      final margin = notional / account.leverage;
      levels[i] = level.copyWith(requiredMargin: margin);
    }
  }

  /// Netting: margin only on the net position.
  static void _calculateNetting(
    List<GridLevel> levels,
    AccountSpec account,
    InstrumentSpec instrument,
  ) {
    double netLot = 0;
    for (int i = 0; i < levels.length; i++) {
      netLot += levels[i].roundedLot;
      final notional = netLot * instrument.contractSize * levels[i].entryPrice;
      final margin = notional / account.leverage;
      levels[i] = levels[i].copyWith(requiredMargin: margin);
    }
  }

  /// Hedging Reduced: hedged portion uses reduced margin factor.
  static void _calculateHedgingReduced(
    List<GridLevel> levels,
    AccountSpec account,
    InstrumentSpec instrument,
    double hedgedMarginFactor,
  ) {
    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];

      // For single-direction grids, no hedging occurs
      // For mixed directions (future), calculate hedged portion
      final notional = level.roundedLot * instrument.contractSize * level.entryPrice;
      final fullMargin = notional / account.leverage;

      // Apply reduced margin factor
      final margin = fullMargin * hedgedMarginFactor;

      levels[i] = level.copyWith(requiredMargin: margin);
    }
  }

  /// Calculate total required margin across all levels.
  static double totalMargin(List<GridLevel> levels) {
    double total = 0;
    for (final level in levels) {
      total += level.requiredMargin;
    }
    return total;
  }

  /// Calculate free margin.
  static double freeMargin(AccountSpec account, List<GridLevel> levels) {
    return account.equity - totalMargin(levels);
  }
}
