/// Risk constraints set by the user.
///
/// No "SAFE/LOW/HIGH" or color-coded risk scores in engine or UI.
/// Only objective PASS/FAIL against user-defined limits.
/// If no constraints are set, UI shows: "No constraints set — enter your own limits to check"
/// with 4 suggested default values.
class ConstraintSet {
  /// Maximum drawdown percentage (e.g., 30 means 30%).
  final double? maxDrawdownPercent;

  /// Maximum total lot across all triggered levels.
  final double? maxTotalLot;

  /// Minimum margin level percentage (e.g., 100 means 100%).
  final double? minMarginLevelPercent;

  /// Maximum loss amount in account currency (e.g., $500).
  final double? maxLossAmount;

  const ConstraintSet({
    this.maxDrawdownPercent,
    this.maxTotalLot,
    this.minMarginLevelPercent,
    this.maxLossAmount,
  });

  /// Returns true if at least one constraint is defined.
  bool get hasAny =>
      maxDrawdownPercent != null ||
      maxTotalLot != null ||
      minMarginLevelPercent != null ||
      maxLossAmount != null;

  /// Returns the number of defined constraints.
  int get count => [
        maxDrawdownPercent,
        maxTotalLot,
        minMarginLevelPercent,
        maxLossAmount,
      ].where((e) => e != null).length;

  ConstraintSet copyWith({
    double? maxDrawdownPercent,
    double? maxTotalLot,
    double? minMarginLevelPercent,
    double? maxLossAmount,
    bool clearMaxDrawdown = false,
    bool clearMaxTotalLot = false,
    bool clearMinMarginLevel = false,
    bool clearMaxLoss = false,
  }) {
    return ConstraintSet(
      maxDrawdownPercent: clearMaxDrawdown
          ? null
          : (maxDrawdownPercent ?? this.maxDrawdownPercent),
      maxTotalLot:
          clearMaxTotalLot ? null : (maxTotalLot ?? this.maxTotalLot),
      minMarginLevelPercent: clearMinMarginLevel
          ? null
          : (minMarginLevelPercent ?? this.minMarginLevelPercent),
      maxLossAmount:
          clearMaxLoss ? null : (maxLossAmount ?? this.maxLossAmount),
    );
  }
}

/// Result of checking a single constraint.
class ConstraintCheckResult {
  /// Human-readable name of the constraint.
  final String constraintName;

  /// Whether the constraint passed.
  final bool passed;

  /// Level at which the constraint was violated (null if passed).
  final int? violatedAtLevel;

  /// Detailed message, e.g., "Max DD 30% violated at Level 7 (32.1%)".
  final String detailMessage;

  const ConstraintCheckResult({
    required this.constraintName,
    required this.passed,
    this.violatedAtLevel,
    required this.detailMessage,
  });
}
