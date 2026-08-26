import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

void main() {
  group('SurvivalEngine', () {
    late AccountSpec account;
    late InstrumentSpec xauusd;
    late ExecutionSpec execution;
    late StrategySpec strategy;

    setUp(() {
      account = const AccountSpec(
        balance: 10000,
        equity: 10000,
        leverage: 500,
        stopOutLevelPercent: 20,
      );
      xauusd = InstrumentSpec.xauusd;
      execution = const ExecutionSpec();
      strategy = const StrategySpec(
        direction: Direction.buy,
        initialLot: 0.01,
        multiplier: 1.5,
        fixedDistance: 10,
        levels: 5,
      );
    });

    test('survives all levels with small lots', () {
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

      final result = SurvivalEngine.analyze(
        levels: levels,
        account: account,
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
      );

      expect(result.survivableLevels, greaterThanOrEqualTo(1));
    });

    test('survivableLevels is at most configured levels', () {
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

      final result = SurvivalEngine.analyze(
        levels: levels,
        account: account,
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
      );

      expect(result.survivableLevels, lessThanOrEqualTo(levels.length));
    });

    test('high multiplier reduces survivable levels', () {
      final lowMultStrategy = strategy.copyWith(multiplier: 1.2);
      final highMultStrategy = strategy.copyWith(multiplier: 2.0);

      final lowLevels = GridBuilder.build(
        strategy: lowMultStrategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300,
      );
      MarginCalculator.calculate(
        levels: lowLevels,
        account: account,
        instrument: xauusd,
        execution: execution,
      );
      final lowResult = SurvivalEngine.analyze(
        levels: lowLevels,
        account: account,
        strategy: lowMultStrategy,
        instrument: xauusd,
        execution: execution,
      );

      final highLevels = GridBuilder.build(
        strategy: highMultStrategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300,
      );
      MarginCalculator.calculate(
        levels: highLevels,
        account: account,
        instrument: xauusd,
        execution: execution,
      );
      final highResult = SurvivalEngine.analyze(
        levels: highLevels,
        account: account,
        strategy: highMultStrategy,
        instrument: xauusd,
        execution: execution,
      );

      expect(lowResult.survivableLevels, greaterThanOrEqualTo(highResult.survivableLevels));
    });
  });
}
