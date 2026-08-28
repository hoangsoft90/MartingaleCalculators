import '../models/strategy_spec.dart';
import '../models/instrument_spec.dart';
import '../models/execution_spec.dart';
import '../models/grid_level.dart';
import '../rounding/lot_rounding.dart';

/// Builds grid levels with entry prices and lot sizes.
///
/// Implements formulas from spec sections 3.1 (lot sizing) and 3.2 (entry prices).
class GridBuilder {
  /// Build all configured grid levels.
  ///
  /// Returns a list of [GridLevel] objects with calculated:
  /// - rawLot and roundedLot per level
  /// - entryPrice per level (with spread applied)
  /// - cumulativeLot per level
  static List<GridLevel> build({
    required StrategySpec strategy,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required double currentPrice,
    List<String>? warnings,
  }) {
    final levels = <GridLevel>[];
    double cumulativeLot = 0;
    double previousMidPrice = currentPrice;

    for (int n = 1; n <= strategy.levels; n++) {
      // 3.1: Lot per level
      final rawLot = strategy.initialLot * _pow(strategy.multiplier, n - 1);
      final roundedLot = LotRounding.apply(
        rawLot,
        instrument.lotStep,
        strategy.roundingMode,
        lotMin: instrument.lotMin,
        lotMax: instrument.lotMax,
      );

      // Warn if rounding caused significant deviation
      if (warnings != null &&
          LotRounding.hasSignificantDeviation(rawLot, roundedLot)) {
        warnings.add(
          'Level $n lot rounded from ${rawLot.toStringAsFixed(4)} '
          'to ${roundedLot.toStringAsFixed(2)} '
          '(deviation > 5%)',
        );
      }

      // 3.2: Entry price per level (with spread)
      double midPrice;
      if (n == 1) {
        midPrice = currentPrice;
      } else {
        final distance = strategy.distanceForLevel(n - 1);
        midPrice = strategy.direction == Direction.buy
            ? previousMidPrice - distance // Buy grid goes down
            : previousMidPrice + distance; // Sell grid goes up
      }

      final entryPrice = _applySpread(
        midPrice,
        strategy.direction,
        execution.spreadPoints,
        instrument.tickSize,
      );

      // 3.4: Cumulative lot
      cumulativeLot += roundedLot;

      levels.add(GridLevel(
        index: n,
        rawLot: rawLot,
        roundedLot: roundedLot,
        entryPrice: entryPrice,
        cumulativeLot: cumulativeLot,
        requiredMargin: 0, // Calculated by MarginCalculator
        isTriggered: true, // All configured levels are triggered at full range
      ));

      previousMidPrice = midPrice;
    }

    return levels;
  }

  /// Apply spread to get entry price from mid price.
  ///
  /// Buy  → entry at Ask (mid + spread/2 * tickSize)
  /// Sell → entry at Bid (mid - spread/2 * tickSize)
  static double _applySpread(
    double midPrice,
    Direction direction,
    double spreadPoints,
    double tickSize,
  ) {
    final halfSpread = (spreadPoints / 2) * tickSize;
    switch (direction) {
      case Direction.buy:
        return midPrice + halfSpread; // Ask
      case Direction.sell:
        return midPrice - halfSpread; // Bid
    }
  }

  /// Build grid levels with an existing open position (synthetic Level 0).
  ///
  /// Creates a synthetic Level 0 representing the current open position,
  /// then builds the remaining grid levels normally. The equity is used
  /// as the baseline for all calculations.
  ///
  /// When [existingEquity], [existingFloatingPnl], and [existingTotalLots]
  /// are all 0 or null, the result is identical to [build] (backward-compatible).
  static List<GridLevel> buildWithExistingExposure({
    required StrategySpec strategy,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required double currentPrice,
    double existingEquity = 0,
    double existingFloatingPnl = 0,
    double existingTotalLots = 0,
    List<String>? warnings,
  }) {
    final levels = <GridLevel>[];

    // If no existing exposure, delegate to normal build
    if (existingTotalLots <= 0) {
      return build(
        strategy: strategy,
        instrument: instrument,
        execution: execution,
        currentPrice: currentPrice,
        warnings: warnings,
      );
    }

    // Calculate entry price from floating P/L
    // floatingPnl = (closePrice - entryPrice) * direction * contractSize * totalLots
    // entryPrice = closePrice - floatingPnl / (direction * contractSize * totalLots)
    final directionSign = strategy.direction == Direction.buy ? 1.0 : -1.0;
    final closePrice = strategy.direction == Direction.buy
        ? currentPrice - (execution.spreadPoints / 2) * instrument.tickSize
        : currentPrice + (execution.spreadPoints / 2) * instrument.tickSize;
    
    double existingEntryPrice;
    if (existingTotalLots > 0 && instrument.contractSize > 0) {
      existingEntryPrice = closePrice -
          existingFloatingPnl / (directionSign * instrument.contractSize * existingTotalLots);
    } else {
      existingEntryPrice = currentPrice;
    }

    // Create synthetic Level 0
    levels.add(GridLevel(
      index: 0,
      rawLot: existingTotalLots,
      roundedLot: existingTotalLots,
      entryPrice: existingEntryPrice,
      cumulativeLot: existingTotalLots,
      requiredMargin: 0, // Will be calculated by MarginCalculator
      isTriggered: true,
    ));

    // Build remaining levels starting from Level 1
    final futureLevels = build(
      strategy: strategy,
      instrument: instrument,
      execution: execution,
      currentPrice: currentPrice,
      warnings: warnings,
    );

    // Adjust cumulative lots for future levels
    double cumulativeLot = existingTotalLots;
    for (final level in futureLevels) {
      cumulativeLot += level.roundedLot;
      levels.add(level.copyWith(cumulativeLot: cumulativeLot));
    }

    return levels;
  }

  /// Integer power (avoids floating-point math.pow for small exponents).
  static double _pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
