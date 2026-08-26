import '../models/strategy_spec.dart';

/// Lot rounding utilities.
///
/// Deterministic rounding that does not depend on locale or platform.
/// Always clamps result to [lotMin, lotMax].
class LotRounding {
  /// Apply rounding to [rawLot] according to [mode] and [lotStep].
  ///
  /// - [LotRoundingMode.round]: round to nearest lotStep multiple
  /// - [LotRoundingMode.floor]: round down to nearest lotStep multiple
  /// - [LotRoundingMode.ceiling]: round up to nearest lotStep multiple
  ///
  /// Result is always clamped to [lotMin]..[lotMax].
  static double apply(
    double rawLot,
    double lotStep,
    LotRoundingMode mode, {
    required double lotMin,
    required double lotMax,
  }) {
    if (lotStep <= 0) throw ArgumentError('lotStep must be > 0');

    final steps = rawLot / lotStep;
    double rounded;

    switch (mode) {
      case LotRoundingMode.round:
        rounded = _roundToNearest(steps) * lotStep;
        break;
      case LotRoundingMode.floor:
        rounded = steps.floorToDouble() * lotStep;
        break;
      case LotRoundingMode.ceiling:
        rounded = steps.ceilToDouble() * lotStep;
        break;
    }

    // Clamp to [lotMin, lotMax]
    if (rounded < lotMin) rounded = lotMin;
    if (rounded > lotMax) rounded = lotMax;

    // Round to avoid floating point artifacts
    final decimals = _countDecimals(lotStep);
    rounded = double.parse(rounded.toStringAsFixed(decimals));

    return rounded;
  }

  /// Check if rounding caused significant deviation from raw value.
  /// Returns true if deviation exceeds [thresholdPercent] (default 5%).
  static bool hasSignificantDeviation(
    double rawLot,
    double roundedLot, {
    double thresholdPercent = 5.0,
  }) {
    if (rawLot == 0) return false;
    final deviation = ((roundedLot - rawLot).abs() / rawLot) * 100;
    return deviation > thresholdPercent;
  }

  /// Count decimal places in a number (for string formatting).
  static int _countDecimals(double value) {
    final text = value.toString();
    final dotIndex = text.indexOf('.');
    if (dotIndex == -1) return 0;
    return text.length - dotIndex - 1;
  }

  /// Round to nearest integer (banker's rounding not needed for lot sizes).
  static double _roundToNearest(double value) {
    return (value + 0.5).floorToDouble();
  }
}
