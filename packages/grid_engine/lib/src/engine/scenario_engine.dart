import '../models/account_spec.dart';
import '../models/strategy_spec.dart';
import '../models/instrument_spec.dart';
import '../models/execution_spec.dart';
import 'grid_builder.dart';
import 'margin_calculator.dart';
import 'pnl_calculator.dart';

/// Scenario engine for what-if analysis.
///
/// Generates a table of scenarios at different price offsets,
/// enabling the What-if Slider to update dashboard in realtime.
class ScenarioEngine {
  /// Generate scenario points at regular price intervals.
  ///
  /// [step] - price increment between scenarios (in price units)
  /// [range] - total range to cover (positive = both directions)
  static List<ScenarioPoint> generate({
    required StrategySpec strategy,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required double currentPrice,
    required double step,
    required double range,
    AccountSpec? account,
  }) {
    final scenarios = <ScenarioPoint>[];
    final startPrice = currentPrice - range;
    final endPrice = currentPrice + range;
    final scenarioAccount = account ?? const AccountSpec(
      balance: 10000,
      leverage: 500,
    );

    // Build grid ONCE at the original strategy price
    final baseLevels = GridBuilder.build(
      strategy: strategy,
      instrument: instrument,
      execution: execution,
      currentPrice: currentPrice,
    );

    // Calculate margin once (doesn't change with price)
    MarginCalculator.calculate(
      levels: baseLevels,
      account: scenarioAccount,
      instrument: instrument,
      execution: execution,
    );

    for (double price = startPrice; price <= endPrice; price += step) {
      final offset = price - currentPrice;

      // Count triggered levels at this scenario price using the static grid
      final triggeredCount = baseLevels
          .where((l) => GridBuilder.isTriggeredAtPrice(l, price, strategy.direction))
          .length;

      // Calculate floating P/L at this price using the static grid
      final floatingPnl = PnlCalculator.calculateFloatingPnl(
        levels: baseLevels,
        direction: strategy.direction,
        instrument: instrument,
        execution: execution,
        assumedPrice: price,
      );

      // Calculate margin level
      final totalMargin = MarginCalculator.totalMargin(baseLevels, execution.hedgeMode);
      final equity = scenarioAccount.equity + floatingPnl;
      final marginLevel = totalMargin > 0
          ? (equity / totalMargin) * 100
          : double.infinity;

      // Calculate drawdown
      final drawdown = scenarioAccount.equity > 0
          ? ((scenarioAccount.equity - equity) / scenarioAccount.equity) * 100
          : 0.0;

      scenarios.add(ScenarioPoint(
        priceOffset: offset,
        price: price,
        triggeredLevels: triggeredCount,
        drawdownPercent: drawdown.clamp(0, 100),
        marginLevelPercent: marginLevel,
        floatingPnl: floatingPnl,
        constraintsAllPassed: true, // Will be evaluated separately
      ));
    }

    return scenarios;
  }

  /// Interpolate a scenario point for a specific price.
  static ScenarioPoint interpolate({
    required List<ScenarioPoint> scenarios,
    required double targetPrice,
    required double currentPrice,
  }) {
    final offset = targetPrice - currentPrice;

    // Find bracketing scenarios
    for (int i = 0; i < scenarios.length - 1; i++) {
      if (offset >= scenarios[i].priceOffset &&
          offset <= scenarios[i + 1].priceOffset) {
        final t = (offset - scenarios[i].priceOffset) /
            (scenarios[i + 1].priceOffset - scenarios[i].priceOffset);
        return ScenarioPoint.lerp(scenarios[i], scenarios[i + 1], t);
      }
    }

    // Return closest scenario
    return scenarios.last;
  }
}

/// A single scenario point for the what-if analysis.
class ScenarioPoint {
  final double priceOffset;
  final double price;
  final int triggeredLevels;
  final double drawdownPercent;
  final double marginLevelPercent;
  final double floatingPnl;
  final bool constraintsAllPassed;

  const ScenarioPoint({
    required this.priceOffset,
    required this.price,
    required this.triggeredLevels,
    required this.drawdownPercent,
    required this.marginLevelPercent,
    required this.floatingPnl,
    required this.constraintsAllPassed,
  });

  /// Linear interpolation between two scenario points.
  static ScenarioPoint lerp(ScenarioPoint a, ScenarioPoint b, double t) {
    return ScenarioPoint(
      priceOffset: a.priceOffset + t * (b.priceOffset - a.priceOffset),
      price: a.price + t * (b.price - a.price),
      triggeredLevels: t < 0.5 ? a.triggeredLevels : b.triggeredLevels,
      drawdownPercent:
          a.drawdownPercent + t * (b.drawdownPercent - a.drawdownPercent),
      marginLevelPercent: a.marginLevelPercent +
          t * (b.marginLevelPercent - a.marginLevelPercent),
      floatingPnl: a.floatingPnl + t * (b.floatingPnl - a.floatingPnl),
      constraintsAllPassed:
          t < 0.5 ? a.constraintsAllPassed : b.constraintsAllPassed,
    );
  }
}


