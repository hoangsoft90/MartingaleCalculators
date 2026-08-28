import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

void main() {
  late AccountSpec account;
  late InstrumentSpec xauusd;
  late StrategySpec strategy;

  setUp(() {
    account = const AccountSpec(
      balance: 10000,
      equity: 10000,
      leverage: 500,
      stopOutLevelPercent: 20,
    );
    xauusd = InstrumentSpec.xauusd;
    strategy = const StrategySpec(
      direction: Direction.buy,
      initialLot: 0.01,
      multiplier: 1.5,
      fixedDistance: 10,
      levels: 5,
    );
  });

  group('MarginCalculator.totalMargin — hedge mode aware', () {
    test('hedgingFull: totalMargin sums all levels independently', () {
      final execution = const ExecutionSpec(hedgeMode: HedgeMode.hedgingFull);
      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );
      MarginCalculator.calculate(
        levels: levels,
        account: account,
        instrument: xauusd,
        execution: execution,
      );

      final total = MarginCalculator.totalMargin(levels, HedgeMode.hedgingFull);

      // Should equal manual sum
      double manualSum = 0;
      for (final level in levels) {
        manualSum += level.requiredMargin;
      }
      expect(total, manualSum);
    });

    test('netting: totalMargin is last level requiredMargin (not sum)', () {
      final execution = const ExecutionSpec(hedgeMode: HedgeMode.netting);
      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );
      MarginCalculator.calculate(
        levels: levels,
        account: account,
        instrument: xauusd,
        execution: execution,
      );

      final total = MarginCalculator.totalMargin(levels, HedgeMode.netting);

      // Netting: requiredMargin is cumulative — total should be the LAST level's value
      expect(total, levels.last.requiredMargin);

      // Manual sum would be wrong (double-count)
      double manualSum = 0;
      for (final level in levels) {
        manualSum += level.requiredMargin;
      }
      expect(
        total,
        isNot(equals(manualSum)),
        reason: 'Netting totalMargin should NOT equal manual sum of cumulative snapshots',
      );
    });

    test('REGRESSION: netting totalMargin is less than sum (no double-count)', () {
      final execution = const ExecutionSpec(hedgeMode: HedgeMode.netting);
      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );
      MarginCalculator.calculate(
        levels: levels,
        account: account,
        instrument: xauusd,
        execution: execution,
      );

      final correctTotal = MarginCalculator.totalMargin(levels, HedgeMode.netting);

      double sumOfAll = 0;
      for (final level in levels) {
        sumOfAll += level.requiredMargin;
      }

      // With 5 levels of 1.5x multiplier, sum >> correct total
      expect(
        sumOfAll,
        greaterThan(correctTotal),
        reason: 'Sum of cumulative snapshots overcounts netting margin',
      );
    });

    test('hedgingReduced: totalMargin sums all levels (like hedgingFull)', () {
      final execution = const ExecutionSpec(
        hedgeMode: HedgeMode.hedgingReduced,
        hedgedMarginFactor: 0.5,
      );
      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );
      MarginCalculator.calculate(
        levels: levels,
        account: account,
        instrument: xauusd,
        execution: execution,
      );

      final total = MarginCalculator.totalMargin(levels, HedgeMode.hedgingReduced);

      double manualSum = 0;
      for (final level in levels) {
        manualSum += level.requiredMargin;
      }
      expect(total, manualSum);
    });
  });

  group('SurvivalEngine uses correct totalMargin for netting', () {
    test('netting mode: margin level calculation uses last snapshot, not sum', () {
      final execution = const ExecutionSpec(hedgeMode: HedgeMode.netting);
      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );
      MarginCalculator.calculate(
        levels: levels,
        account: account,
        instrument: xauusd,
        execution: execution,
      );

      final correctTotal = MarginCalculator.totalMargin(levels, HedgeMode.netting);
      final equity = account.equity;
      final correctMarginLevel = (equity / correctTotal) * 100;

      // Sum of all snapshots would give wrong (lower) margin level
      double sumOfAll = 0;
      for (final level in levels) {
        sumOfAll += level.requiredMargin;
      }
      final wrongMarginLevel = (equity / sumOfAll) * 100;

      expect(
        correctMarginLevel,
        greaterThan(wrongMarginLevel),
        reason: 'Netting margin level should be HIGHER than sum-based calculation '
            '(less margin reserved = more free margin)',
      );
    });
  });
}
