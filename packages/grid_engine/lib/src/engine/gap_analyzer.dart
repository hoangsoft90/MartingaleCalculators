import '../models/account_spec.dart';
import '../models/strategy_spec.dart';
import '../models/instrument_spec.dart';
import '../models/execution_spec.dart';
import '../models/grid_level.dart';
import 'grid_builder.dart';
import 'margin_calculator.dart';
import 'pnl_calculator.dart';

/// Result of a gap scenario analysis.
class GapAnalysisResult {
  /// Number of levels triggered by the gap.
  final int triggeredCount;

  /// Total number of configured levels.
  final int totalLevels;

  /// Floating P/L at the gap price.
  final double floatingPnl;

  /// Effective entry prices used for each triggered level.
  /// Sequential: each level's own entry price.
  /// At Market: all equal to gapPrice.
  final List<double> effectiveEntryPrices;

  /// Lot sizes of triggered levels.
  final List<double> triggeredLots;

  /// Total required margin for triggered levels.
  final double totalMargin;

  /// Margin level at the gap price.
  final double marginLevelPercent;

  const GapAnalysisResult({
    required this.triggeredCount,
    required this.totalLevels,
    required this.floatingPnl,
    required this.effectiveEntryPrices,
    required this.triggeredLots,
    required this.totalMargin,
    required this.marginLevelPercent,
  });
}

/// Analyzes gap scenarios for grid trading.
///
/// Determines which levels are triggered by a price gap and calculates
/// P/L and margin under two execution modes:
/// - Sequential: each level fills at its own entry price
/// - At Market: all triggered levels fill at the gap price
class GapAnalyzer {
  /// Analyze a gap scenario.
  ///
  /// [gapPrice] is the price after the gap (First Available Open Price).
  /// For BUY: gapPrice < currentPrice (gap down).
  /// For SELL: gapPrice > currentPrice (gap up).
  static GapAnalysisResult analyze({
    required StrategySpec strategy,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required double currentPrice,
    required double gapPrice,
  }) {
    // Build grid at the original strategy price (static)
    final levels = GridBuilder.build(
      strategy: strategy,
      instrument: instrument,
      execution: execution,
      currentPrice: currentPrice,
    );

    // Calculate margin (doesn't change with gap price)
    final account = AccountSpec(
      balance: 10000, // Placeholder — margin level calculation needs account
      equity: 10000,
      leverage: 500,
      stopOutLevelPercent: 20,
    );
    MarginCalculator.calculate(
      levels: levels,
      account: account,
      instrument: instrument,
      execution: execution,
    );

    // Find triggered levels
    final triggered = <GridLevel>[];
    for (final level in levels) {
      if (strategy.direction == Direction.buy) {
        // BUY: level triggers when price drops to/below entry
        if (gapPrice <= level.entryPrice) {
          triggered.add(level);
        }
      } else {
        // SELL: level triggers when price rises to/above entry
        if (gapPrice >= level.entryPrice) {
          triggered.add(level);
        }
      }
    }

    // Apply execution mode to get effective entry prices
    final effectiveLevels = <GridLevel>[];
    final effectiveEntryPrices = <double>[];

    if (execution.executionMode == ExecutionMode.atMarket) {
      // At Market: all triggered levels use gap price as entry
      for (final level in triggered) {
        effectiveLevels.add(level.copyWith(entryPrice: gapPrice));
        effectiveEntryPrices.add(gapPrice);
      }
    } else {
      // Sequential: each level retains its own entry price
      for (final level in triggered) {
        effectiveLevels.add(level);
        effectiveEntryPrices.add(level.entryPrice);
      }
    }

    // Calculate floating P/L
    final floatingPnl = PnlCalculator.calculateFloatingPnl(
      levels: effectiveLevels,
      direction: strategy.direction,
      instrument: instrument,
      execution: execution,
      assumedPrice: gapPrice,
    );

    // Calculate margin (netting-aware)
    final totalMargin = MarginCalculator.totalMargin(effectiveLevels, execution.hedgeMode);
    final triggeredLots = <double>[];
    for (final level in triggered) {
      triggeredLots.add(level.roundedLot);
    }

    // Calculate margin level
    final equity = account.equity + floatingPnl;
    final marginLevel = totalMargin > 0
        ? (equity / totalMargin) * 100
        : double.infinity;

    return GapAnalysisResult(
      triggeredCount: triggered.length,
      totalLevels: levels.length,
      floatingPnl: floatingPnl,
      effectiveEntryPrices: effectiveEntryPrices,
      triggeredLots: triggeredLots,
      totalMargin: totalMargin,
      marginLevelPercent: marginLevel,
    );
  }
}
