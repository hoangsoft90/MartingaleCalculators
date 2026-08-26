/// Represents a single grid level with its calculated properties.
///
/// Important distinction in the UI:
///   - "Configured levels" = number of levels user set up (e.g., 10)
///   - "Triggered levels"  = number of levels actually activated at a given price
///
/// Never use "level" ambiguously for both meanings.
class GridLevel {
  /// Level index (1-based).
  final int index;

  /// Raw lot before rounding.
  final double rawLot;

  /// Lot after rounding according to lotStep and roundingMode.
  final double roundedLot;

  /// Entry price for this level (includes spread).
  final double entryPrice;

  /// Cumulative lot up to and including this level.
  final double cumulativeLot;

  /// Required margin for this level's position.
  final double requiredMargin;

  /// Floating P/L at the current evaluation price.
  final double floatingPnl;

  /// Whether this level has been triggered at the current scenario price.
  final bool isTriggered;

  const GridLevel({
    required this.index,
    required this.rawLot,
    required this.roundedLot,
    required this.entryPrice,
    required this.cumulativeLot,
    required this.requiredMargin,
    this.floatingPnl = 0.0,
    this.isTriggered = false,
  });

  GridLevel copyWith({
    int? index,
    double? rawLot,
    double? roundedLot,
    double? entryPrice,
    double? cumulativeLot,
    double? requiredMargin,
    double? floatingPnl,
    bool? isTriggered,
  }) {
    return GridLevel(
      index: index ?? this.index,
      rawLot: rawLot ?? this.rawLot,
      roundedLot: roundedLot ?? this.roundedLot,
      entryPrice: entryPrice ?? this.entryPrice,
      cumulativeLot: cumulativeLot ?? this.cumulativeLot,
      requiredMargin: requiredMargin ?? this.requiredMargin,
      floatingPnl: floatingPnl ?? this.floatingPnl,
      isTriggered: isTriggered ?? this.isTriggered,
    );
  }
}
