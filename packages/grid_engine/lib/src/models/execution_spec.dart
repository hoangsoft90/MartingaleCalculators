/// Execution specification — spread, commission, swap, and hedge mode.
///
/// Spread is mandatory and must be applied to entry/close prices:
///   Buy  → entry at Ask (mid + spread/2), close at Bid (mid - spread/2)
///   Sell → entry at Bid (mid - spread/2), close at Ask (mid + spread/2)
///
/// This is the most common source of calculation errors for XAUUSD.
enum HedgeMode {
  netting,
  hedgingFull,
  hedgingReduced,
}

/// Execution costs and hedge configuration.
class ExecutionSpec {
  /// Spread in points (applied to entry/close price).
  final double spreadPoints;

  /// Commission per lot (one-way, default 0).
  final double commissionPerLot;

  /// Swap per lot per day (default 0).
  final double swapPerLotPerDay;

  /// Number of holding days for swap calculation (default 0).
  final int holdingDays;

  /// Hedge mode: netting, hedging full margin, or hedging reduced.
  final HedgeMode hedgeMode;

  /// Factor for hedged margin (0.0–1.0), only used with hedgingReduced.
  final double hedgedMarginFactor;

  const ExecutionSpec({
    this.spreadPoints = 30,
    this.commissionPerLot = 0,
    this.swapPerLotPerDay = 0,
    this.holdingDays = 0,
    this.hedgeMode = HedgeMode.hedgingFull,
    this.hedgedMarginFactor = 0.5,
  });

  ExecutionSpec copyWith({
    double? spreadPoints,
    double? commissionPerLot,
    double? swapPerLotPerDay,
    int? holdingDays,
    HedgeMode? hedgeMode,
    double? hedgedMarginFactor,
  }) {
    return ExecutionSpec(
      spreadPoints: spreadPoints ?? this.spreadPoints,
      commissionPerLot: commissionPerLot ?? this.commissionPerLot,
      swapPerLotPerDay: swapPerLotPerDay ?? this.swapPerLotPerDay,
      holdingDays: holdingDays ?? this.holdingDays,
      hedgeMode: hedgeMode ?? this.hedgeMode,
      hedgedMarginFactor: hedgedMarginFactor ?? this.hedgedMarginFactor,
    );
  }
}
