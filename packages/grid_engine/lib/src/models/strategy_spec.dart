/// Grid strategy specification.
///
/// Defines the grid parameters: direction, lot sizing, distance between levels,
/// and rounding behavior.
enum Direction { buy, sell }

enum GridDistanceMode { fixed, manual }

enum LotRoundingMode { round, floor, ceiling }

/// Complete strategy configuration.
class StrategySpec {
  /// Trade direction for the grid.
  final Direction direction;

  /// Initial lot size for level 1.
  final double initialLot;

  /// Multiplier for lot sizing at each subsequent level.
  final double multiplier;

  /// Grid distance mode: fixed (same distance) or manual (per-level).
  final GridDistanceMode distanceMode;

  /// Fixed distance between grid levels (used when distanceMode = fixed).
  final double fixedDistance;

  /// Manual distances between levels (used when distanceMode = manual).
  /// Length must be levels - 1.
  final List<double>? manualDistances;

  /// Number of configured grid levels.
  final int levels;

  /// Lot rounding mode.
  final LotRoundingMode roundingMode;

  const StrategySpec({
    required this.direction,
    required this.initialLot,
    this.multiplier = 1.0,
    this.distanceMode = GridDistanceMode.fixed,
    this.fixedDistance = 10.0,
    this.manualDistances,
    required this.levels,
    this.roundingMode = LotRoundingMode.round,
  }) : assert(
          distanceMode == GridDistanceMode.fixed ||
              manualDistances == null ||
              manualDistances.length == levels - 1,
          'manualDistances length must be levels - 1',
        );

  /// Get distance for a specific level transition.
  /// [fromLevel] is the current level (1-based), returns distance to next level.
  double distanceForLevel(int fromLevel) {
    assert(fromLevel >= 1 && fromLevel < levels);
    if (distanceMode == GridDistanceMode.fixed) {
      return fixedDistance;
    }
    return manualDistances![fromLevel - 1];
  }

  StrategySpec copyWith({
    Direction? direction,
    double? initialLot,
    double? multiplier,
    GridDistanceMode? distanceMode,
    double? fixedDistance,
    List<double>? manualDistances,
    int? levels,
    LotRoundingMode? roundingMode,
  }) {
    return StrategySpec(
      direction: direction ?? this.direction,
      initialLot: initialLot ?? this.initialLot,
      multiplier: multiplier ?? this.multiplier,
      distanceMode: distanceMode ?? this.distanceMode,
      fixedDistance: fixedDistance ?? this.fixedDistance,
      manualDistances: manualDistances ?? this.manualDistances,
      levels: levels ?? this.levels,
      roundingMode: roundingMode ?? this.roundingMode,
    );
  }
}
