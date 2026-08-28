/// A tier in a dynamic leverage schedule.
///
/// Brokers often reduce leverage as equity increases.
/// Example: 1:500 for equity ≤ $1000, 1:200 for $1000-$10000, etc.
class LeverageTier {
  /// Minimum equity (inclusive) for this tier.
  final double minEquity;

  /// Maximum equity (inclusive) for this tier. Use `double.infinity` for unbounded.
  final double maxEquity;

  /// Leverage for this tier (e.g. 500 means 1:500).
  final double leverage;

  const LeverageTier({
    required this.minEquity,
    required this.maxEquity,
    required this.leverage,
  });

  /// Check if a given equity falls within this tier.
  bool contains(double equity) => equity >= minEquity && equity <= maxEquity;
}
