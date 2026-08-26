import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

void main() {
  group('LotRounding', () {
    group('apply', () {
      test('rounds to nearest lotStep', () {
        expect(LotRounding.apply(0.023, 0.01, LotRoundingMode.round, lotMin: 0.01, lotMax: 100), 0.02);
        expect(LotRounding.apply(0.025, 0.01, LotRoundingMode.round, lotMin: 0.01, lotMax: 100), 0.03);
        expect(LotRounding.apply(0.024, 0.01, LotRoundingMode.round, lotMin: 0.01, lotMax: 100), 0.02);
      });

      test('floors to nearest lotStep', () {
        expect(LotRounding.apply(0.029, 0.01, LotRoundingMode.floor, lotMin: 0.01, lotMax: 100), 0.02);
        expect(LotRounding.apply(0.021, 0.01, LotRoundingMode.floor, lotMin: 0.01, lotMax: 100), 0.02);
        expect(LotRounding.apply(0.020, 0.01, LotRoundingMode.floor, lotMin: 0.01, lotMax: 100), 0.02);
      });

      test('ceilings to nearest lotStep', () {
        expect(LotRounding.apply(0.021, 0.01, LotRoundingMode.ceiling, lotMin: 0.01, lotMax: 100), 0.03);
        expect(LotRounding.apply(0.020, 0.01, LotRoundingMode.ceiling, lotMin: 0.01, lotMax: 100), 0.02);
        expect(LotRounding.apply(0.011, 0.01, LotRoundingMode.ceiling, lotMin: 0.01, lotMax: 100), 0.02);
      });

      test('clamps to lotMin', () {
        expect(LotRounding.apply(0.001, 0.01, LotRoundingMode.floor, lotMin: 0.01, lotMax: 100), 0.01);
        expect(LotRounding.apply(0.005, 0.01, LotRoundingMode.round, lotMin: 0.01, lotMax: 100), 0.01);
      });

      test('clamps to lotMax', () {
        expect(LotRounding.apply(150, 0.01, LotRoundingMode.ceiling, lotMin: 0.01, lotMax: 100), 100);
        expect(LotRounding.apply(100.5, 0.01, LotRoundingMode.round, lotMin: 0.01, lotMax: 100), 100);
      });

      test('handles lotStep = 0.01 (XAUUSD)', () {
        expect(LotRounding.apply(0.015, 0.01, LotRoundingMode.round, lotMin: 0.01, lotMax: 100), 0.02);
        expect(LotRounding.apply(0.014, 0.01, LotRoundingMode.round, lotMin: 0.01, lotMax: 100), 0.01);
      });

      test('handles lotStep = 0.05', () {
        // 0.07 / 0.05 = 1.4 → rounds to 1 → 0.05
        expect(LotRounding.apply(0.07, 0.05, LotRoundingMode.round, lotMin: 0.05, lotMax: 100), 0.05);
        // 0.08 / 0.05 = 1.6 → rounds to 2 → 0.10
        expect(LotRounding.apply(0.08, 0.05, LotRoundingMode.round, lotMin: 0.05, lotMax: 100), 0.10);
      });

      test('throws on lotStep = 0', () {
        expect(
          () => LotRounding.apply(0.1, 0, LotRoundingMode.round, lotMin: 0.01, lotMax: 100),
          throwsArgumentError,
        );
      });
    });

    group('hasSignificantDeviation', () {
      test('detects deviation > 5%', () {
        expect(LotRounding.hasSignificantDeviation(0.1, 0.05), true); // 50% deviation
        expect(LotRounding.hasSignificantDeviation(0.1, 0.096), false); // 4% deviation, below 5% threshold
        expect(LotRounding.hasSignificantDeviation(0.1, 0.09), true); // 10% deviation
      });

      test('handles zero rawLot', () {
        expect(LotRounding.hasSignificantDeviation(0, 0.01), false);
      });
    });
  });
}
