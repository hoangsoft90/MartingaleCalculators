import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

void main() {
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

  group('GridBuilder.isTriggeredAtPrice', () {
    test('BUY: level triggers when price drops to or below entry', () {
      // Build grid at price 3300
      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );

      // Level 1 entry ~3300, Level 2 entry ~3290, etc.
      // At price 3300: only level 1 is triggered
      final triggeredAt3300 = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3300.0, Direction.buy))
          .length;
      expect(triggeredAt3300, 1);

      // At price 3290: level 1 and 2 triggered
      final triggeredAt3290 = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3290.0, Direction.buy))
          .length;
      expect(triggeredAt3290, 2);

      // At price 3280: levels 1, 2, 3 triggered
      final triggeredAt3280 = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3280.0, Direction.buy))
          .length;
      expect(triggeredAt3280, 3);
    });

    test('SELL: level triggers when price rises to or above entry', () {
      final sellStrategy = strategy.copyWith(direction: Direction.sell);

      final levels = GridBuilder.build(
        strategy: sellStrategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );

      // SELL grid goes UP: Level 1 ~3300, Level 2 ~3310, etc.
      // At price 3300: only level 1 is triggered
      final triggeredAt3300 = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3300.0, Direction.sell))
          .length;
      expect(triggeredAt3300, 1);

      // At price 3310: levels 1 and 2 triggered
      final triggeredAt3310 = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3310.0, Direction.sell))
          .length;
      expect(triggeredAt3310, 2);
    });
  });

  group('GridBuilder.build sets isTriggered correctly', () {
    test('build() sets isTriggered=true for all levels (backward compat)', () {
      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );

      // build() always sets isTriggered=true for all configured levels
      // (all levels are potential positions in worst-case analysis)
      final triggeredCount = levels.where((l) => l.isTriggered).length;
      expect(triggeredCount, levels.length);
    });

    test('isTriggeredAtPrice gives dynamic count for what-if analysis', () {
      final levels = GridBuilder.build(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
      );

      // At 3300 (original): only level 1 triggered
      final atOriginal = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3300.0, Direction.buy))
          .length;
      expect(atOriginal, 1);

      // At 3295 (between level 1 and 2): only level 1 should be triggered
      final at3295 = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3295.0, Direction.buy))
          .length;
      expect(at3295, 1);

      // At 3270 (at level 4 entry): levels 1, 2, 3, 4 triggered
      // (BUY: triggered when price <= entryPrice)
      final at3270 = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3270.0, Direction.buy))
          .length;
      expect(at3270, 4);

      // At 3250 (past all 5 levels): all triggered
      final at3250 = levels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, 3250.0, Direction.buy))
          .length;
      expect(at3250, 5);
    });
  });

  group('ScenarioEngine uses static grid', () {
    test('triggeredLevels count varies by price in scenario table', () {
      final scenarios = ScenarioEngine.generate(
        strategy: strategy,
        instrument: xauusd,
        execution: execution,
        currentPrice: 3300.0,
        step: 5.0,
        range: 20.0,
        account: account,
      );

      // Should have scenarios with different triggered counts
      final triggeredCounts = scenarios.map((s) => s.triggeredLevels).toSet();
      expect(
        triggeredCounts.length,
        greaterThan(1),
        reason: 'All scenarios have same triggeredLevels — grid not using isTriggeredAtPrice',
      );
    });
  });
}
