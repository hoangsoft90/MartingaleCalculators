import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:grid_engine/grid_engine.dart';

/// Tolerance for floating point comparisons (0.5%).
const double tolerance = 0.005;

void main() {
  group('Golden Cases', () {
    late Map<String, dynamic> goldenData;
    late List<Map<String, dynamic>> cases;

    setUpAll(() async {
      final file = File('test/golden_cases/golden_cases.json');
      final contents = await file.readAsString();
      goldenData = jsonDecode(contents) as Map<String, dynamic>;
      cases = (goldenData['cases'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    });

    test('golden cases file exists and has correct structure', () {
      expect(goldenData, isNotNull);
      expect(goldenData['cases'], isA<List>());
      expect(cases.length, greaterThanOrEqualTo(2));
    });

    test('each case has required input fields', () {
      for (final c in cases) {
        expect(c['id'], isA<String>());
        expect(c['input'], isA<Map>());
        expect(c['input']['account'], isA<Map>());
        expect(c['input']['instrument'], isA<Map>());
        expect(c['input']['strategy'], isA<Map>());
        expect(c['input']['execution'], isA<Map>());
        expect(c['expected'], isA<Map>());
      }
    });

    test('engine processes all cases without crashing', () {
      for (final c in cases) {
        final result = _runEngine(c);
        expect(result.levels.length, c['input']['strategy']['levels']);
        expect(result.levels.first.rawLot,
            (c['input']['strategy']['initialLot'] as num).toDouble());
      }
    });
  });

  group('Validation (expected vs engine output)', () {
    late List<Map<String, dynamic>> cases;

    setUpAll(() async {
      final file = File('test/golden_cases/golden_cases.json');
      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;
      cases = (data['cases'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    });

    test('validates cases with real data (skips PLACEHOLDER)', () {
      final validated = <String>[];
      final skipped = <String>[];

      for (final c in cases) {
        final expected = c['expected'] as Map<String, dynamic>;
        final id = c['id'] as String;

        // Skip if still placeholder
        if (expected['survivableLevels'] == 'PLACEHOLDER' ||
            expected['totalExposureLots'] == 'PLACEHOLDER') {
          skipped.add(id);
          continue;
        }

        final result = _runEngine(c);

        // Validate totalExposureLots
        final expectedTotalLots = (expected['totalExposureLots'] as num).toDouble();
        final actualTotalLots = result.totalExposureLots;
        expect(
          actualTotalLots,
          closeTo(expectedTotalLots, expectedTotalLots * tolerance),
          reason: '$id: totalExposureLots mismatch',
        );

        // Validate averageEntryPrice
        final expectedAvgEntry = (expected['averageEntryPrice'] as num).toDouble();
        final actualAvgEntry = result.averageEntryPrice;
        expect(
          actualAvgEntry,
          closeTo(expectedAvgEntry, expectedAvgEntry * tolerance),
          reason: '$id: averageEntryPrice mismatch',
        );

        // Validate basketBreakevenPrice
        final expectedBE = (expected['basketBreakevenPrice'] as num).toDouble();
        final actualBE = result.basketBreakevenPrice;
        expect(
          actualBE,
          closeTo(expectedBE, expectedBE * tolerance),
          reason: '$id: basketBreakevenPrice mismatch',
        );

        // Validate rebindDistanceToBreakeven
        final expectedRebind = (expected['rebindDistanceToBreakeven'] as num).toDouble();
        final actualRebind = result.rebindDistanceToBreakeven;
        expect(
          actualRebind,
          closeTo(expectedRebind, expectedRebind * tolerance + 0.1),
          reason: '$id: rebindDistanceToBreakeven mismatch',
        );

        // Validate survivableLevels (exact match)
        final expectedSurvivable = expected['survivableLevels'] as int;
        expect(
          result.survivableLevels,
          expectedSurvivable,
          reason: '$id: survivableLevels mismatch',
        );

        // Validate estimatedStopOutPrice (if provided)
        if (expected['estimatedStopOutPrice'] != null &&
            expected['estimatedStopOutPrice'] != 'PLACEHOLDER') {
          final expectedStopOut = (expected['estimatedStopOutPrice'] as num).toDouble();
          final actualStopOut = result.estimatedStopOutPrice;
          expect(actualStopOut, isNotNull, reason: '$id: expected stop-out price but got null');
          expect(
            actualStopOut,
            closeTo(expectedStopOut, expectedStopOut * tolerance),
            reason: '$id: estimatedStopOutPrice mismatch',
          );
        }

        // Validate maxDrawdownPercent (if provided)
        if (expected['maxDrawdownPercent'] != null &&
            expected['maxDrawdownPercent'] != 'PLACEHOLDER') {
          final expectedDD = (expected['maxDrawdownPercent'] as num).toDouble();
          final actualDD = result.maxDrawdownPercent;
          expect(
            actualDD,
            closeTo(expectedDD, expectedDD * tolerance + 0.5),
            reason: '$id: maxDrawdownPercent mismatch',
          );
        }

        validated.add(id);
      }

      print('Validated: ${validated.length} cases');
      print('Skipped (PLACEHOLDER): ${skipped.length} cases → $skipped');

      // At least warn if nothing validated
      if (validated.isEmpty) {
        print('⚠️ No cases with real data found. Fill in golden_cases.json!');
      }
    });

    test('validates lot rounding is correct per lotStep', () {
      for (final c in cases) {
        final result = _runEngine(c);
        final lotStep = (c['input']['instrument']['lotStep'] as num).toDouble();
        final lotMin = (c['input']['instrument']['lotMin'] as num).toDouble();
        final lotMax = (c['input']['instrument']['lotMax'] as num).toDouble();

        for (final level in result.levels) {
          // roundedLot must be multiple of lotStep (with floating point tolerance)
          final remainder = level.roundedLot % lotStep;
          final normalizedRemainder = remainder < lotStep / 2 ? remainder : remainder - lotStep;
          expect(
            normalizedRemainder.abs(),
            lessThan(0.001),
            reason: '${c["id"]}: Level ${level.index} lot ${level.roundedLot} is not multiple of $lotStep (remainder: $remainder)',
          );

          // roundedLot must be in [lotMin, lotMax]
          expect(
            level.roundedLot,
            greaterThanOrEqualTo(lotMin),
            reason: '${c["id"]}: Level ${level.index} lot ${level.roundedLot} < lotMin $lotMin',
          );
          expect(
            level.roundedLot,
            lessThanOrEqualTo(lotMax),
            reason: '${c["id"]}: Level ${level.index} lot ${level.roundedLot} > lotMax $lotMax',
          );
        }
      }
    });

    test('validates entry prices follow direction rules', () {
      for (final c in cases) {
        final result = _runEngine(c);
        final direction = c['input']['strategy']['direction'] as String;
        final spreadPoints = (c['input']['execution']['spreadPoints'] as num).toDouble();
        final tickSize = (c['input']['instrument']['tickSize'] as num).toDouble();
        final halfSpread = (spreadPoints / 2) * tickSize;

        for (int i = 1; i < result.levels.length; i++) {
          final prev = result.levels[i - 1];
          final curr = result.levels[i];
          final distance = (c['input']['strategy']['fixedDistance'] as num).toDouble();

          if (direction == 'buy') {
            // Buy grid: prices go DOWN (lower entry at higher levels)
            expect(
              curr.entryPrice,
              lessThan(prev.entryPrice),
              reason: '${c["id"]}: Buy grid Level ${i+1} entry ${curr.entryPrice} should be < Level $i entry ${prev.entryPrice}',
            );
          } else {
            // Sell grid: prices go UP (higher entry at higher levels)
            expect(
              curr.entryPrice,
              greaterThan(prev.entryPrice),
              reason: '${c["id"]}: Sell grid Level ${i+1} entry ${curr.entryPrice} should be > Level $i entry ${prev.entryPrice}',
            );
          }
        }
      }
    });

    test('validates cumulativeLot is monotonically increasing', () {
      for (final c in cases) {
        final result = _runEngine(c);

        for (int i = 1; i < result.levels.length; i++) {
          expect(
            result.levels[i].cumulativeLot,
            greaterThan(result.levels[i - 1].cumulativeLot),
            reason: '${c["id"]}: Level ${i+1} cumulative ${result.levels[i].cumulativeLot} should be > Level $i ${result.levels[i-1].cumulativeLot}',
          );
        }
      }
    });

    test('validates margin is proportional to lot and price (hedgingFull only)', () {
      for (final c in cases) {
        final hedgeMode = c['input']['execution']['hedgeMode'] as String? ?? 'hedgingFull';
        // Skip netting mode - margin calculation is different
        if (hedgeMode != 'hedgingFull') continue;

        final result = _runEngine(c);
        final leverage = (c['input']['account']['leverage'] as num).toDouble();
        final contractSize = (c['input']['instrument']['contractSize'] as num).toDouble();

        for (int i = 0; i < result.levels.length; i++) {
          final level = result.levels[i];
          final expectedMargin = level.roundedLot * contractSize * level.entryPrice / leverage;
          // Allow 1% tolerance for floating point
          expect(
            level.requiredMargin,
            closeTo(expectedMargin, expectedMargin * 0.01),
            reason: '${c["id"]}: Level ${level.index} margin ${level.requiredMargin} != expected $expectedMargin',
          );
        }
      }
    });
  });

  group('Reverse Solver Validation', () {
    late List<Map<String, dynamic>> cases;

    setUpAll(() async {
      final file = File('test/golden_cases/golden_cases.json');
      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;
      cases = (data['cases'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    });

    test('reverse solver finds valid lot for each case with constraints', () {
      for (final c in cases) {
        final input = c['input'];
        final constraintsData = input['constraints'] as Map<String, dynamic>?;

        // Skip cases without constraints
        if (constraintsData == null) continue;

        final account = _buildAccount(input['account']);
        final instrument = _buildInstrument(input['instrument']);
        final execution = _buildExecution(input['execution']);
        final strategy = _buildStrategy(input['strategy']);

        final constraints = ConstraintSet(
          maxDrawdownPercent: (constraintsData['maxDrawdownPercent'] as num?)?.toDouble(),
          maxTotalLot: (constraintsData['maxTotalLot'] as num?)?.toDouble(),
          minMarginLevelPercent: (constraintsData['minMarginLevelPercent'] as num?)?.toDouble(),
          maxLossAmount: (constraintsData['maxLossAmount'] as num?)?.toDouble(),
        );

        if (!constraints.hasAny) continue;

        final result = ReverseSolver.solve(
          account: account,
          instrument: instrument,
          execution: execution,
          strategy: strategy,
          constraints: constraints,
          currentPrice: (input['currentPrice'] as num).toDouble(),
        );

        // Result must be within lot bounds
        expect(
          result.maximumInitialLot,
          greaterThanOrEqualTo(instrument.lotMin),
          reason: '${c["id"]}: Reverse lot ${result.maximumInitialLot} < lotMin',
        );
        expect(
          result.maximumInitialLot,
          lessThanOrEqualTo(instrument.lotMax),
          reason: '${c["id"]}: Reverse lot ${result.maximumInitialLot} > lotMax',
        );

        // Must converge within 20 iterations
        expect(
          result.iterations,
          lessThanOrEqualTo(20),
          reason: '${c["id"]}: Reverse solver took ${result.iterations} iterations (>20)',
        );

        // Verify the result is a valid lot within bounds
        expect(
          result.maximumInitialLot % instrument.lotStep,
          closeTo(0, 0.001),
          reason: '${c["id"]}: Reverse lot ${result.maximumInitialLot} is not multiple of lotStep ${instrument.lotStep}',
        );

        print('✅ ${c["id"]}: Reverse lot = ${result.maximumInitialLot} '
            '(${result.iterations} iterations, bottleneck: ${result.bottleneckConstraint?.constraintName ?? "none"})');
      }
    });
  });
}

/// Run engine and return full calculation result.
CalculationResult _runEngine(Map<String, dynamic> c) {
  final input = c['input'];

  final account = _buildAccount(input['account']);
  final instrument = _buildInstrument(input['instrument']);
  final execution = _buildExecution(input['execution']);
  final strategy = _buildStrategy(input['strategy']);
  final currentPrice = (input['currentPrice'] as num).toDouble();

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

  final hedgeMode = HedgeMode.values.firstWhere(
    (e) => e.name == (input['execution']['hedgeMode'] as String? ?? 'hedgingFull'),
    orElse: () => HedgeMode.hedgingFull,
  );
  final totalMargin = MarginCalculator.totalMargin(levels, hedgeMode);
  double totalLot = 0;
  for (final level in levels) {
    totalLot += level.roundedLot;
  }

  double avgEntry = 0;
  if (totalLot > 0) {
    double weightedSum = 0;
    for (final level in levels) {
      weightedSum += level.roundedLot * level.entryPrice;
    }
    avgEntry = weightedSum / totalLot;
  }

  // Calculate max drawdown (simplified: assume price drops to stop-out)
  double maxDD = 0;
  if (account.equity > 0 && survival.estimatedStopOutPrice != null) {
    final pnlAtStopOut = PnlCalculator.calculateFloatingPnl(
      levels: levels,
      direction: strategy.direction,
      instrument: instrument,
      execution: execution,
      assumedPrice: survival.estimatedStopOutPrice!,
    );
    maxDD = ((account.equity - (account.equity + pnlAtStopOut)) / account.equity * 100).abs();
  }

  return CalculationResult(
    levels: levels,
    totalExposureLots: totalLot,
    averageEntryPrice: avgEntry,
    basketBreakevenPrice: basketBreakeven,
    rebindDistanceToBreakeven: rebindDistance,
    survivableLevels: survival.survivableLevels,
    estimatedStopOutPrice: survival.estimatedStopOutPrice,
    maxDrawdownPercent: maxDD,
    totalRequiredMargin: totalMargin,
    constraintResults: [],
    assumptionsUsed: [],
  );
}

AccountSpec _buildAccount(Map data) => AccountSpec(
  balance: (data['balance'] as num).toDouble(),
  equity: (data['equity'] as num?)?.toDouble(),
  leverage: (data['leverage'] as num).toDouble(),
  stopOutLevelPercent: (data['stopOutPercent'] as num).toDouble(),
);

InstrumentSpec _buildInstrument(Map data) => InstrumentSpec(
  symbol: data['symbol'] as String,
  contractSize: (data['contractSize'] as num).toDouble(),
  tickSize: (data['tickSize'] as num).toDouble(),
  tickValuePerLot: (data['tickValuePerLot'] as num).toDouble(),
  digits: data['digits'] as int,
  lotMin: (data['lotMin'] as num).toDouble(),
  lotMax: (data['lotMax'] as num).toDouble(),
  lotStep: (data['lotStep'] as num).toDouble(),
);

ExecutionSpec _buildExecution(Map data) => ExecutionSpec(
  spreadPoints: (data['spreadPoints'] as num).toDouble(),
  commissionPerLot: (data['commissionPerLot'] as num?)?.toDouble() ?? 0,
  swapPerLotPerDay: (data['swapPerLotPerDay'] as num?)?.toDouble() ?? 0,
  holdingDays: data['holdingDays'] as int? ?? 0,
  hedgeMode: HedgeMode.values.firstWhere(
    (e) => e.name == (data['hedgeMode'] as String? ?? 'hedgingFull'),
    orElse: () => HedgeMode.hedgingFull,
  ),
);

StrategySpec _buildStrategy(Map data) => StrategySpec(
  direction: data['direction'] == 'buy' ? Direction.buy : Direction.sell,
  initialLot: (data['initialLot'] as num).toDouble(),
  multiplier: (data['multiplier'] as num).toDouble(),
  fixedDistance: (data['fixedDistance'] as num).toDouble(),
  levels: data['levels'] as int,
  roundingMode: LotRoundingMode.values.firstWhere(
    (e) => e.name == (data['roundingMode'] as String? ?? 'round'),
    orElse: () => LotRoundingMode.round,
  ),
);
