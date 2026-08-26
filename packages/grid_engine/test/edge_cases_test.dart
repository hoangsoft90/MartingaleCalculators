import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

void main() {
  group('Edge Cases', () {
    late AccountSpec account;
    late InstrumentSpec xauusd;
    late ExecutionSpec execution;

    setUp(() {
      account = const AccountSpec(
        balance: 10000,
        equity: 10000,
        leverage: 500,
        stopOutLevelPercent: 20,
      );
      xauusd = InstrumentSpec.xauusd;
      execution = const ExecutionSpec();
    });

    group('multiplier = 1 (flat grid)', () {
      test('all levels have same lot size', () {
        final strategy = const StrategySpec(
          direction: Direction.buy,
          initialLot: 0.1,
          multiplier: 1.0,
          fixedDistance: 10,
          levels: 5,
        );

        final levels = GridBuilder.build(
          strategy: strategy,
          instrument: xauusd,
          execution: execution,
          currentPrice: 3300,
        );

        for (final level in levels) {
          expect(level.rawLot, 0.1);
          expect(level.roundedLot, 0.1);
        }
      });
    });

    group('levels = 0', () {
      test('returns empty list', () {
        final strategy = const StrategySpec(
          direction: Direction.buy,
          initialLot: 0.1,
          multiplier: 1.5,
          fixedDistance: 10,
          levels: 0,
        );

        final levels = GridBuilder.build(
          strategy: strategy,
          instrument: xauusd,
          execution: execution,
          currentPrice: 3300,
        );

        expect(levels, isEmpty);
      });
    });

    group('lot exceeds lotMax', () {
      test('clamps to lotMax', () {
        final strategy = const StrategySpec(
          direction: Direction.buy,
          initialLot: 0.1,
          multiplier: 10.0, // Rapid growth
          fixedDistance: 10,
          levels: 5,
        );

        final levels = GridBuilder.build(
          strategy: strategy,
          instrument: xauusd,
          execution: execution,
          currentPrice: 3300,
          warnings: [],
        );

        // Level 5: 0.1 * 10^4 = 1000, but lotMax = 100
        expect(levels.last.roundedLot, lessThanOrEqualTo(xauusd.lotMax));
      });
    });

    group('large numbers', () {
      test('handles levels = 100 with high multiplier without overflow', () {
        final strategy = const StrategySpec(
          direction: Direction.buy,
          initialLot: 0.01,
          multiplier: 1.1,
          fixedDistance: 10,
          levels: 100,
        );

        // Should not throw
        final levels = GridBuilder.build(
          strategy: strategy,
          instrument: xauusd,
          execution: execution,
          currentPrice: 3300,
        );

        expect(levels.length, 100);
        // All lots should be clamped to lotMax
        for (final level in levels) {
          expect(level.roundedLot, lessThanOrEqualTo(xauusd.lotMax));
          expect(level.roundedLot, greaterThanOrEqualTo(xauusd.lotMin));
        }
      });
    });

    group('floating point comparison', () {
      test('uses epsilon comparison for margin calculations', () {
        final strategy = const StrategySpec(
          direction: Direction.buy,
          initialLot: 0.01,
          multiplier: 1.0,
          fixedDistance: 10,
          levels: 3,
        );

        final levels = GridBuilder.build(
          strategy: strategy,
          instrument: xauusd,
          execution: execution,
          currentPrice: 3300,
        );

        MarginCalculator.calculate(
          levels: levels,
          account: account,
          instrument: xauusd,
          execution: execution,
        );

        // Margin should be close to expected value
        final expectedMargin = 0.01 * 100 * 3300 / 500;
        expect(levels[0].requiredMargin, closeTo(expectedMargin, 0.001));
      });
    });

    group('deterministic rounding', () {
      test('same input produces same output regardless of platform', () {
        final results = <double>[];
        for (int i = 0; i < 10; i++) {
          results.add(LotRounding.apply(
            0.025,
            0.01,
            LotRoundingMode.round,
            lotMin: 0.01,
            lotMax: 100,
          ));
        }

        // All results should be identical
        expect(results.toSet().length, 1);
        expect(results.first, 0.03);
      });
    });
  });
}
