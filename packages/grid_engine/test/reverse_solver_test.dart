import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

void main() {
  group('ReverseSolver', () {
    late AccountSpec account;
    late InstrumentSpec xauusd;
    late ExecutionSpec execution;
    late StrategySpec strategy;
    late ConstraintSet constraints;

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
        initialLot: 0.1, // Will be overridden by solver
        multiplier: 1.5,
        fixedDistance: 10,
        levels: 10,
      );
      constraints = const ConstraintSet(
        maxDrawdownPercent: 30,
      );
    });

    test('throws when no constraints provided', () {
      expect(
        () => ReverseSolver.solve(
          account: account,
          instrument: xauusd,
          execution: execution,
          strategy: strategy,
          constraints: const ConstraintSet(),
          currentPrice: 3300.00,
        ),
        throwsArgumentError,
      );
    });

    test('finds maximum initial lot within constraints', () {
      final result = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: constraints,
        currentPrice: 3300.00,
      );

      expect(result.maximumInitialLot, greaterThanOrEqualTo(xauusd.lotMin));
      expect(result.maximumInitialLot, lessThanOrEqualTo(xauusd.lotMax));
      expect(result.iterations, lessThanOrEqualTo(ReverseSolver.maxIterations));
    });

    test('binary search converges within 20 iterations', () {
      final result = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: constraints,
        currentPrice: 3300.00,
      );

      expect(result.iterations, lessThanOrEqualTo(20));
    });

    // (old 'tighter constraint reduces maximum lot' replaced by REGRESSION version below)

    test('result is multiple of lotStep', () {
      final result = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: constraints,
        currentPrice: 3300.00,
      );

      final remainder = result.maximumInitialLot % xauusd.lotStep;
      expect(remainder, closeTo(0, 0.001));
    });

    test('REGRESSION: currentPrice must not be 0 — grid entry prices depend on it', () {
      final tightConstraints = const ConstraintSet(maxTotalLot: 0.15);

      final result = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: tightConstraints,
        currentPrice: 3300.00,
      );

      expect(
        result.maximumInitialLot,
        lessThan(xauusd.lotMax),
        reason: 'Solver returned lotMax — maxTotalLot=0.15 should have capped it',
      );

      expect(result.bottleneckConstraint, isNotNull);
      expect(result.bottleneckConstraint!.passed, isFalse);
      expect(result.bottleneckConstraint!.constraintName, 'Max Total Lot');
    });

    test('REGRESSION: tighter constraint reduces maximum lot (DD actually binds)', () {
      // Before fix: both loose and tight DD constraints pass (value=0 always passes)
      // so both converge to lotMax=100. After fix: DD is calculated from real PnL,
      // so loose < lotMax and tight < loose.
      final looseConstraints = const ConstraintSet(maxDrawdownPercent: 80);
      final tightConstraints = const ConstraintSet(maxDrawdownPercent: 30);

      final looseResult = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: looseConstraints,
        currentPrice: 3300.00,
      );

      final tightResult = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: tightConstraints,
        currentPrice: 3300.00,
      );

      // Loose DD=80% should be binding (not lotMax)
      expect(
        looseResult.maximumInitialLot,
        lessThan(xauusd.lotMax),
        reason: 'Loose DD=80% returned lotMax — DD constraint not calculating real PnL',
      );

      // Tighter should reduce lot further
      expect(
        tightResult.maximumInitialLot,
        lessThan(looseResult.maximumInitialLot),
        reason: 'Tight DD=30% should produce smaller lot than loose DD=80%',
      );
    });

    test('REGRESSION: Max Loss 500 constraint limits lot correctly', () {
      // Before fix: totalFloatingPnl=0 → 0 <= 500 always passes → solver returns lotMax
      // After fix: actual PnL is calculated, so Max Loss constrains the lot.
      final maxLossConstraints = const ConstraintSet(maxLossAmount: 500);

      final result = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: maxLossConstraints,
        currentPrice: 3300.00,
      );

      // Solver should NOT return lotMax — the loss constraint must bind
      expect(
        result.maximumInitialLot,
        lessThan(xauusd.lotMax),
        reason: 'Max Loss 500 returned lotMax — totalFloatingPnl not calculated',
      );

      // The bottleneck should be Max Loss
      expect(result.bottleneckConstraint, isNotNull);
      expect(result.bottleneckConstraint!.passed, isFalse);
      expect(result.bottleneckConstraint!.constraintName, 'Max Loss');
    });
  });
}
