import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

void main() {
  late AccountSpec account;
  late InstrumentSpec xauusd;
  late ExecutionSpec baseExecution;
  late StrategySpec strategy;

  setUp(() {
    account = const AccountSpec(
      balance: 10000,
      equity: 10000,
      leverage: 500,
      stopOutLevelPercent: 20,
    );
    xauusd = InstrumentSpec.xauusd;
    baseExecution = const ExecutionSpec();
    strategy = const StrategySpec(
      direction: Direction.buy,
      initialLot: 0.01,
      multiplier: 1.5,
      fixedDistance: 10,
      levels: 5,
    );
  });

  group('Gap Scenario — Sequential vs At Market', () {
    test('triggered levels are the same for both modes', () {
      final seqResult = GapAnalyzer.analyze(
        strategy: strategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.sequential),
        currentPrice: 3300.0,
        gapPrice: 3270.0,
      );
      final atmResult = GapAnalyzer.analyze(
        strategy: strategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.atMarket),
        currentPrice: 3300.0,
        gapPrice: 3270.0,
      );

      expect(seqResult.triggeredCount, atmResult.triggeredCount);
      expect(seqResult.triggeredCount, greaterThan(1), reason: 'Gap should trigger multiple levels');
    });

    test('At Market: all effective entries equal gap price', () {
      final result = GapAnalyzer.analyze(
        strategy: strategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.atMarket),
        currentPrice: 3300.0,
        gapPrice: 3270.0,
      );

      for (final price in result.effectiveEntryPrices) {
        expect(price, 3270.0, reason: 'At Market: all entries should be gap price');
      }
    });

    test('REGRESSION: Sequential and At Market produce different PnL for same gap', () {
      final seqResult = GapAnalyzer.analyze(
        strategy: strategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.sequential),
        currentPrice: 3300.0,
        gapPrice: 3270.0,
      );
      final atmResult = GapAnalyzer.analyze(
        strategy: strategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.atMarket),
        currentPrice: 3300.0,
        gapPrice: 3270.0,
      );

      expect(
        seqResult.floatingPnl,
        isNot(equals(atmResult.floatingPnl)),
        reason: 'Sequential and At Market should produce different PnL. '
            'Sequential uses individual entry prices, At Market uses gap price for all.',
      );
    });

    test('At Market PnL is more favorable than Sequential for BUY gap down', () {
      final seqResult = GapAnalyzer.analyze(
        strategy: strategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.sequential),
        currentPrice: 3300.0,
        gapPrice: 3270.0,
      );
      final atmResult = GapAnalyzer.analyze(
        strategy: strategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.atMarket),
        currentPrice: 3300.0,
        gapPrice: 3270.0,
      );

      expect(
        atmResult.floatingPnl,
        greaterThan(seqResult.floatingPnl),
        reason: 'At Market BUY gap down: entering all at gap price (lower) '
            'should produce better PnL than sequential fills at higher entries',
      );
    });

    test('Sequential: each level retains its own entry price', () {
      final result = GapAnalyzer.analyze(
        strategy: strategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.sequential),
        currentPrice: 3300.0,
        gapPrice: 3270.0,
      );

      final uniquePrices = result.effectiveEntryPrices.toSet();
      expect(
        uniquePrices.length,
        greaterThan(1),
        reason: 'Sequential mode should have different entry prices per level',
      );
    });

    test('gap up triggers SELL levels correctly', () {
      final sellStrategy = strategy.copyWith(direction: Direction.sell);
      final result = GapAnalyzer.analyze(
        strategy: sellStrategy,
        instrument: xauusd,
        execution: baseExecution.copyWith(executionMode: ExecutionMode.atMarket),
        currentPrice: 3300.0,
        gapPrice: 3330.0,
      );

      expect(result.triggeredCount, greaterThan(0));
      for (final price in result.effectiveEntryPrices) {
        expect(price, 3330.0, reason: 'At Market SELL gap up: all entries should be gap price');
      }
    });
  });
}
