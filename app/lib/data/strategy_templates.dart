import 'package:grid_engine/grid_engine.dart';

/// Predefined strategy templates with different risk profiles.
///
/// Each template provides default StrategySpec values. No safety labels
/// — just multiplier values and risk preview data.
class StrategyTemplates {
  /// Conservative template: low multiplier, tight spacing.
  static const lowMultiplier = StrategyTemplate(
    name: 'Low Multiplier (1.2x)',
    description: '1.2x lot multiplier with 10-unit spacing',
    strategy: StrategySpec(
      direction: Direction.buy,
      initialLot: 0.01,
      multiplier: 1.2,
      fixedDistance: 10.0,
      levels: 10,
      roundingMode: LotRoundingMode.round,
    ),
  );

  /// Balanced template: moderate multiplier.
  static const mediumMultiplier = StrategyTemplate(
    name: 'Medium Multiplier (1.5x)',
    description: '1.5x lot multiplier with 10-unit spacing',
    strategy: StrategySpec(
      direction: Direction.buy,
      initialLot: 0.01,
      multiplier: 1.5,
      fixedDistance: 10.0,
      levels: 10,
      roundingMode: LotRoundingMode.round,
    ),
  );

  /// Aggressive template: high multiplier.
  static const highMultiplier = StrategyTemplate(
    name: 'High Multiplier (2.0x)',
    description: '2.0x lot multiplier with 10-unit spacing',
    strategy: StrategySpec(
      direction: Direction.buy,
      initialLot: 0.01,
      multiplier: 2.0,
      fixedDistance: 10.0,
      levels: 10,
      roundingMode: LotRoundingMode.round,
    ),
  );

  /// All available templates.
  static const all = [lowMultiplier, mediumMultiplier, highMultiplier];
}

/// A strategy template preset.
class StrategyTemplate {
  /// Display name (e.g., 'Low Multiplier (1.2x)').
  final String name;

  /// Brief description of the template.
  final String description;

  /// The StrategySpec for this template.
  final StrategySpec strategy;

  const StrategyTemplate({
    required this.name,
    required this.description,
    required this.strategy,
  });
}
