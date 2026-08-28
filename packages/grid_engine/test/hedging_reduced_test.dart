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

  group('HedgingReduced for single-direction grid', () {
    test('hedgingReduced should equal hedgingFull (no hedged portion)', () {
      final fullExec = const ExecutionSpec(hedgeMode: HedgeMode.hedgingFull);
      final reducedExec = const ExecutionSpec(
        hedgeMode: HedgeMode.hedgingReduced,
        hedgedMarginFactor: 0.5,
      );

      final fullLevels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: fullExec,
        currentPrice: 3300.0,
      );
      final reducedLevels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: reducedExec,
        currentPrice: 3300.0,
      );

      MarginCalculator.calculate(
        levels: fullLevels,
        account: account,
        instrument: xauusd,
        execution: fullExec,
      );
      MarginCalculator.calculate(
        levels: reducedLevels,
        account: account,
        instrument: xauusd,
        execution: reducedExec,
      );

      final fullTotal = MarginCalculator.totalMargin(fullLevels, HedgeMode.hedgingFull);
      final reducedTotal = MarginCalculator.totalMargin(reducedLevels, HedgeMode.hedgingReduced);

      // BUG: reducedTotal is 50% of fullTotal (factor=0.5 applied to all)
      // FIX: reducedTotal should equal fullTotal (single-direction = no hedging)
      expect(
        reducedTotal,
        equals(fullTotal),
        reason: 'Single-direction grid: hedgingReduced should equal hedgingFull. '
            'Got reduced=$reducedTotal vs full=$fullTotal',
      );
    });

    test('REGRESSION: hedgingReduced does NOT reduce margin for single-direction', () {
      final reducedExec = const ExecutionSpec(
        hedgeMode: HedgeMode.hedgingReduced,
        hedgedMarginFactor: 0.3, // Very aggressive factor
      );

      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: reducedExec,
        currentPrice: 3300.0,
      );

      MarginCalculator.calculate(
        levels: levels,
        account: account,
        instrument: xauusd,
        execution: reducedExec,
      );

      // Calculate what hedgingFull would give
      final fullLevels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: const ExecutionSpec(hedgeMode: HedgeMode.hedgingFull),
        currentPrice: 3300.0,
      );
      MarginCalculator.calculate(
        levels: fullLevels,
        account: account,
        instrument: xauusd,
        execution: const ExecutionSpec(hedgeMode: HedgeMode.hedgingFull),
      );

      final reducedTotal = MarginCalculator.totalMargin(levels, HedgeMode.hedgingReduced);
      final fullTotal = MarginCalculator.totalMargin(fullLevels, HedgeMode.hedgingFull);

      // Before fix: reducedTotal = fullTotal * 0.3 (30% of full)
      // After fix: reducedTotal = fullTotal (same as full)
      expect(
        reducedTotal,
        equals(fullTotal),
        reason: 'hedgingReduced with factor=0.3 should NOT reduce margin '
            'for single-direction grid',
      );
    });

    test('each level margin equals hedgingFull for single-direction', () {
      final reducedExec = const ExecutionSpec(
        hedgeMode: HedgeMode.hedgingReduced,
        hedgedMarginFactor: 0.5,
      );
      final fullExec = const ExecutionSpec(hedgeMode: HedgeMode.hedgingFull);

      final reducedLevels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: reducedExec,
        currentPrice: 3300.0,
      );
      final fullLevels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: fullExec,
        currentPrice: 3300.0,
      );

      MarginCalculator.calculate(
        levels: reducedLevels,
        account: account,
        instrument: xauusd,
        execution: reducedExec,
      );
      MarginCalculator.calculate(
        levels: fullLevels,
        account: account,
        instrument: xauusd,
        execution: fullExec,
      );

      for (int i = 0; i < reducedLevels.length; i++) {
        expect(
          reducedLevels[i].requiredMargin,
          closeTo(fullLevels[i].requiredMargin, 0.001),
          reason: 'Level ${i + 1}: reduced margin ${reducedLevels[i].requiredMargin} '
              'should equal full margin ${fullLevels[i].requiredMargin}',
        );
      }
    });
  });
}
