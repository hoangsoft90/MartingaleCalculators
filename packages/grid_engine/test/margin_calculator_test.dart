import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

void main() {
  group('MarginCalculator', () {
    late AccountSpec account;
    late InstrumentSpec xauusd;
    late ExecutionSpec execution;
    late List<GridLevel> levels;

    setUp(() {
      account = const AccountSpec(
        balance: 10000,
        equity: 10000,
        leverage: 500,
      );
      xauusd = InstrumentSpec.xauusd;
      execution = const ExecutionSpec();
      levels = [
        const GridLevel(
          index: 1,
          rawLot: 0.01,
          roundedLot: 0.01,
          entryPrice: 3300.0,
          cumulativeLot: 0.01,
          requiredMargin: 0,
        ),
        const GridLevel(
          index: 2,
          rawLot: 0.015,
          roundedLot: 0.02,
          entryPrice: 3290.0,
          cumulativeLot: 0.03,
          requiredMargin: 0,
        ),
      ];
    });

    group('hedgingFull', () {
      test('calculates margin per level independently', () {
        MarginCalculator.calculate(
          levels: levels,
          account: account,
          instrument: xauusd,
          execution: execution,
        );

        // Level 1: 0.01 × 100 × 3300 / 500 = 6.6
        expect(levels[0].requiredMargin, closeTo(6.6, 0.01));
        // Level 2: 0.02 × 100 × 3290 / 500 = 13.16
        expect(levels[1].requiredMargin, closeTo(13.16, 0.01));
      });

      test('totalMargin sums all levels', () {
        MarginCalculator.calculate(
          levels: levels,
          account: account,
          instrument: xauusd,
          execution: execution,
        );

        final total = MarginCalculator.totalMargin(levels);
        expect(total, closeTo(19.76, 0.01));
      });

      test('freeMargin is equity minus totalMargin', () {
        MarginCalculator.calculate(
          levels: levels,
          account: account,
          instrument: xauusd,
          execution: execution,
        );

        final free = MarginCalculator.freeMargin(account, levels);
        expect(free, closeTo(10000 - 19.76, 0.01));
      });
    });

    group('netting', () {
      test('calculates margin on net position', () {
        final nettingExec = const ExecutionSpec(hedgeMode: HedgeMode.netting);
        MarginCalculator.calculate(
          levels: levels,
          account: account,
          instrument: xauusd,
          execution: nettingExec,
        );

        // Net lot increases, margin based on cumulative
        expect(levels[0].requiredMargin, closeTo(6.6, 0.01));
        // Level 2: cumulative lot = 0.03, but net margin is on net position
        // For single-direction grid, net = cumulative
        expect(levels[1].requiredMargin, greaterThan(levels[0].requiredMargin));
      });
    });
  });
}
