import '../models/strategy_spec.dart';
import '../models/instrument_spec.dart';
import '../models/execution_spec.dart';
import '../models/grid_level.dart';

/// Calculates floating P/L and basket breakeven.
///
/// Implements formulas from spec sections 3.5 (floating P/L) and 3.6 (breakeven).
class PnlCalculator {
  /// Calculate floating P/L for each triggered level at [assumedPrice].
  ///
  /// closePrice = direction == buy
  ///   ? assumedPrice - spreadPoints/2 * tickSize  (close Buy at Bid)
  ///   : assumedPrice + spreadPoints/2 * tickSize  (close Sell at Ask)
  ///
  /// pnlPerLevel(n) = (closePrice - entryPrice(n)) × direction_sign
  ///                   × contractSize × roundedLot(n)
  ///                   - commissionPerLot × roundedLot(n)
  ///                   - swapPerLotPerDay × roundedLot(n) × holdingDays
  static double calculateFloatingPnl({
    required List<GridLevel> levels,
    required Direction direction,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required double assumedPrice,
  }) {
    final closePrice = _getClosePrice(
      assumedPrice,
      direction,
      execution.spreadPoints,
      instrument.tickSize,
    );

    double totalPnl = 0;
    final directionSign = direction == Direction.buy ? 1.0 : -1.0;

    for (final level in levels) {
      if (!level.isTriggered) continue;

      final pnl = (closePrice - level.entryPrice) *
          directionSign *
          instrument.contractSize *
          level.roundedLot;

      final commission = execution.commissionPerLot * level.roundedLot;
      final swap = execution.swapPerLotPerDay *
          level.roundedLot *
          execution.holdingDays;

      totalPnl += pnl - commission - swap;
    }

    return totalPnl;
  }

  /// Calculate close price from assumed mid price.
  ///
  /// Buy  → close at Bid (mid - spread/2 * tickSize)
  /// Sell → close at Ask (mid + spread/2 * tickSize)
  static double _getClosePrice(
    double assumedPrice,
    Direction direction,
    double spreadPoints,
    double tickSize,
  ) {
    final halfSpread = (spreadPoints / 2) * tickSize;
    switch (direction) {
      case Direction.buy:
        return assumedPrice - halfSpread; // Bid
      case Direction.sell:
        return assumedPrice + halfSpread; // Ask
    }
  }

  /// Calculate basket breakeven price.
  ///
  /// The price at which totalFloatingPnl == 0.
  /// For linear P/L (no new levels triggered):
  ///   priceBE = averageEntry ± (totalCost / (cumulativeLot × contractSize))
  static double calculateBasketBreakeven({
    required List<GridLevel> levels,
    required Direction direction,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
  }) {
    double totalCost = 0;
    double totalWeightedEntry = 0;
    double totalLot = 0;

    for (final level in levels) {
      if (!level.isTriggered) continue;
      totalWeightedEntry += level.roundedLot * level.entryPrice;
      totalLot += level.roundedLot;
      totalCost += execution.commissionPerLot * level.roundedLot;
      totalCost +=
          execution.swapPerLotPerDay * level.roundedLot * execution.holdingDays;
    }

    if (totalLot == 0) return 0;

    final avgEntry = totalWeightedEntry / totalLot;
    final costPerUnit = totalCost / (totalLot * instrument.contractSize);

    switch (direction) {
      case Direction.buy:
        return avgEntry + costPerUnit; // Need higher price to cover costs
      case Direction.sell:
        return avgEntry - costPerUnit; // Need lower price to cover costs
    }
  }

  /// Calculate rebind distance to breakeven.
  static double calculateRebindDistance({
    required double currentPrice,
    required double basketBreakevenPrice,
  }) {
    return (basketBreakevenPrice - currentPrice).abs();
  }
}
