import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_engine/grid_engine.dart';

/// Current instrument spec provider.
final instrumentSpecProvider = StateProvider<InstrumentSpec>(
  (ref) => InstrumentSpec.xauusd,
);

/// Current strategy spec provider.
final strategySpecProvider = StateProvider<StrategySpec>(
  (ref) => const StrategySpec(
    direction: Direction.buy,
    initialLot: 0.01,
    multiplier: 1.5,
    fixedDistance: 10.0,
    levels: 10,
    roundingMode: LotRoundingMode.round,
  ),
);

/// Current execution spec provider.
final executionSpecProvider = StateProvider<ExecutionSpec>(
  (ref) => const ExecutionSpec(),
);

/// Current account spec provider.
final accountSpecProvider = StateProvider<AccountSpec>(
  (ref) => const AccountSpec(
    balance: 10000,
    leverage: 500,
    stopOutLevelPercent: 20,
  ),
);

/// Current constraint set provider.
final constraintSetProvider = StateProvider<ConstraintSet>(
  (ref) => const ConstraintSet(),
);

/// Current price provider (for scenario analysis).
final currentPriceProvider = StateProvider<double>(
  (ref) => 3300.0,
);

/// Calculated grid levels provider (depends on inputs).
final gridLevelsProvider = Provider<List<GridLevel>>((ref) {
  final strategy = ref.watch(strategySpecProvider);
  final instrument = ref.watch(instrumentSpecProvider);
  final execution = ref.watch(executionSpecProvider);
  final currentPrice = ref.watch(currentPriceProvider);

  return GridBuilder.build(
    strategy: strategy,
    instrument: instrument,
    execution: execution,
    currentPrice: currentPrice,
  );
});

/// Calculation result provider (full engine run).
final calculationResultProvider = Provider<CalculationResult?>((ref) {
  final strategy = ref.watch(strategySpecProvider);
  final instrument = ref.watch(instrumentSpecProvider);
  final execution = ref.watch(executionSpecProvider);
  final account = ref.watch(accountSpecProvider);
  final constraints = ref.watch(constraintSetProvider);
  final currentPrice = ref.watch(currentPriceProvider);

  final warnings = <String>[];
  final levels = GridBuilder.build(
    strategy: strategy,
    instrument: instrument,
    execution: execution,
    currentPrice: currentPrice,
    warnings: warnings,
  );

  MarginCalculator.calculate(
    levels: levels,
    account: account,
    instrument: instrument,
    execution: execution,
  );

  final survival = SurvivalEngine.analyze(
    levels: levels,
    account: account,
    strategy: strategy,
    instrument: instrument,
    execution: execution,
  );

  final basketBreakeven = PnlCalculator.calculateBasketBreakeven(
    levels: levels,
    direction: strategy.direction,
    instrument: instrument,
    execution: execution,
  );

  final rebindDistance = PnlCalculator.calculateRebindDistance(
    currentPrice: currentPrice,
    basketBreakevenPrice: basketBreakeven,
  );

  double totalMargin = 0;
  double totalLot = 0;
  for (final level in levels) {
    totalMargin += level.requiredMargin;
    totalLot += level.roundedLot;
  }

  // Calculate max drawdown: worst-case loss when all levels trigger
  double maxDrawdownPercent = 0;
  if (account.equity > 0) {
    final worstCasePnl = PnlCalculator.calculateFloatingPnl(
      levels: levels,
      direction: strategy.direction,
      instrument: instrument,
      execution: execution,
      assumedPrice: strategy.direction == Direction.buy
          ? (levels.isNotEmpty ? levels.last.entryPrice : currentPrice)
          : (levels.isNotEmpty ? levels.last.entryPrice : currentPrice),
    );
    final worstDrawdown = (-worstCasePnl / account.equity) * 100;
    maxDrawdownPercent = worstDrawdown.clamp(0, 100);
  }

  final constraintResults = ConstraintEvaluator.evaluate(
    constraints: constraints,
    account: account,
    levels: levels,
    maxDrawdownPercent: maxDrawdownPercent,
    totalExposureLots: totalLot,
    totalRequiredMargin: totalMargin,
    totalFloatingPnl: 0,
  );

  return CalculationResult(
    levels: levels,
    totalExposureLots: totalLot,
    averageEntryPrice: totalLot > 0
        ? levels.fold(0.0, (sum, l) => sum + l.roundedLot * l.entryPrice) /
            totalLot
        : 0,
    basketBreakevenPrice: basketBreakeven,
    rebindDistanceToBreakeven: rebindDistance,
    survivableLevels: survival.survivableLevels,
    estimatedStopOutPrice: survival.estimatedStopOutPrice,
    maxDrawdownPercent: maxDrawdownPercent,
    constraintResults: constraintResults,
    assumptionsUsed: [
      'Spread: ${execution.spreadPoints} points (user-defined)',
      'Commission: \$${execution.commissionPerLot}/lot',
      'Swap: \$${execution.swapPerLotPerDay}/lot/day for ${execution.holdingDays} days',
      'Hedge mode: ${execution.hedgeMode.name}',
      'Rounding: ${strategy.roundingMode.name} to nearest lot step',
    ],
  );
});
