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
      );

      expect(result.iterations, lessThanOrEqualTo(20));
    });

    test('tighter constraint reduces maximum lot', () {
      final looseConstraints = const ConstraintSet(maxDrawdownPercent: 50);
      final tightConstraints = const ConstraintSet(maxDrawdownPercent: 15);

      final looseResult = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: looseConstraints,
      );

      final tightResult = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: tightConstraints,
      );

      expect(tightResult.maximumInitialLot, lessThanOrEqualTo(looseResult.maximumInitialLot));
    });

    test('result is multiple of lotStep', () {
      final result = ReverseSolver.solve(
        account: account,
        instrument: xauusd,
        execution: execution,
        strategy: strategy,
        constraints: constraints,
      );

      final remainder = result.maximumInitialLot % xauusd.lotStep;
      expect(remainder, closeTo(0, 0.001));
    });
  });
}
