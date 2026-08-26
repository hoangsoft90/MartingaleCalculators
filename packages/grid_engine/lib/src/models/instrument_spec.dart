/// Instrument specification for a trading symbol.
///
/// Contains contract details needed for margin, P/L, and pip calculations.
/// MVP ships with XAUUSD and EURUSD defaults, but values are read from
/// Hive to allow updates without rebuilding the app.
class InstrumentSpec {
  final String symbol;
  final double contractSize;
  final double tickSize;
  final double tickValuePerLot;
  final int digits;
  final double lotMin;
  final double lotMax;
  final double lotStep;
  final double marginPercent;

  const InstrumentSpec({
    required this.symbol,
    required this.contractSize,
    required this.tickSize,
    required this.tickValuePerLot,
    required this.digits,
    required this.lotMin,
    required this.lotMax,
    required this.lotStep,
    this.marginPercent = 100.0,
  });

  /// Default XAUUSD specification (Gold vs USD).
  static const xauusd = InstrumentSpec(
    symbol: 'XAUUSD',
    contractSize: 100,
    tickSize: 0.01,
    tickValuePerLot: 1.0,
    digits: 2,
    lotMin: 0.01,
    lotMax: 100.0,
    lotStep: 0.01,
    marginPercent: 100.0,
  );

  /// Default EURUSD specification (Euro vs US Dollar).
  static const eurusd = InstrumentSpec(
    symbol: 'EURUSD',
    contractSize: 100000,
    tickSize: 0.0001,
    tickValuePerLot: 10.0,
    digits: 5,
    lotMin: 0.01,
    lotMax: 100.0,
    lotStep: 0.01,
    marginPercent: 100.0,
  );

  /// Get default spec by symbol name.
  static InstrumentSpec defaults(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'XAUUSD':
        return xauusd;
      case 'EURUSD':
        return eurusd;
      default:
        throw ArgumentError('No default spec for symbol: $symbol');
    }
  }

  InstrumentSpec copyWith({
    String? symbol,
    double? contractSize,
    double? tickSize,
    double? tickValuePerLot,
    int? digits,
    double? lotMin,
    double? lotMax,
    double? lotStep,
    double? marginPercent,
  }) {
    return InstrumentSpec(
      symbol: symbol ?? this.symbol,
      contractSize: contractSize ?? this.contractSize,
      tickSize: tickSize ?? this.tickSize,
      tickValuePerLot: tickValuePerLot ?? this.tickValuePerLot,
      digits: digits ?? this.digits,
      lotMin: lotMin ?? this.lotMin,
      lotMax: lotMax ?? this.lotMax,
      lotStep: lotStep ?? this.lotStep,
      marginPercent: marginPercent ?? this.marginPercent,
    );
  }
}
