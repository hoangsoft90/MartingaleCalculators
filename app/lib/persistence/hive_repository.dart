import 'package:hive/hive.dart';
import 'package:grid_engine/grid_engine.dart';

/// Repository for persisting strategies using Hive.
///
/// MVP: save up to 5 strategies with full spec + timestamp + user name.
class HiveRepository {
  static const String _boxName = 'saved_strategies';
  static const int _maxStrategies = 5;

  /// Open the strategies box.
  static Future<Box<Map>> _openBox() async {
    return await Hive.openBox<Map>(_boxName);
  }

  /// Save a strategy with metadata.
  static Future<void> saveStrategy({
    required String name,
    required StrategySpec strategy,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required AccountSpec account,
    required double currentPrice,
    ConstraintSet? constraints,
  }) async {
    final box = await _openBox();

    if (box.length >= _maxStrategies) {
      throw StateError(
        'Maximum $_maxStrategies strategies reached. Delete one before saving.',
      );
    }

    final data = {
      'name': name,
      'timestamp': DateTime.now().toIso8601String(),
      'currentPrice': currentPrice,
      'strategy': _strategyToMap(strategy),
      'instrument': _instrumentToMap(instrument),
      'execution': _executionToMap(execution),
      'account': _accountToMap(account),
      'constraints': _constraintsToMap(constraints ?? const ConstraintSet()),
    };

    await box.add(data);
  }

  /// Load all saved strategies.
  static Future<List<SavedStrategy>> loadAll() async {
    final box = await _openBox();
    final strategies = <SavedStrategy>[];

    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null) {
        strategies.add(SavedStrategy(
          index: i,
          name: data['name'] as String? ?? 'Unnamed',
          timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ?? DateTime.now(),
          strategy: _mapToStrategy(data['strategy'] as Map? ?? {}),
          instrument: _mapToInstrument(data['instrument'] as Map? ?? {}),
          execution: _mapToExecution(data['execution'] as Map? ?? {}),
          account: _mapToAccount(data['account'] as Map? ?? {}),
          currentPrice: (data['currentPrice'] as num?)?.toDouble() ?? 0,
          constraints: _mapToConstraints(data['constraints'] as Map? ?? {}),
        ));
      }
    }

    return strategies;
  }

  /// Delete a strategy by index.
  static Future<void> deleteStrategy(int index) async {
    final box = await _openBox();
    await box.deleteAt(index);
  }

  /// Get the number of saved strategies.
  static Future<int> count() async {
    final box = await _openBox();
    return box.length;
  }

  // --- Serialization helpers ---

  static Map _strategyToMap(StrategySpec s) => {
    'direction': s.direction.name,
    'initialLot': s.initialLot,
    'multiplier': s.multiplier,
    'distanceMode': s.distanceMode.name,
    'fixedDistance': s.fixedDistance,
    'manualDistances': s.manualDistances,
    'levels': s.levels,
    'roundingMode': s.roundingMode.name,
  };

  static StrategySpec _mapToStrategy(Map m) => StrategySpec(
    direction: Direction.values.firstWhere(
      (e) => e.name == m['direction'],
      orElse: () => Direction.buy,
    ),
    initialLot: (m['initialLot'] as num?)?.toDouble() ?? 0.01,
    multiplier: (m['multiplier'] as num?)?.toDouble() ?? 1.5,
    distanceMode: GridDistanceMode.values.firstWhere(
      (e) => e.name == m['distanceMode'],
      orElse: () => GridDistanceMode.fixed,
    ),
    fixedDistance: (m['fixedDistance'] as num?)?.toDouble() ?? 10,
    manualDistances: (m['manualDistances'] as List?)?.map((e) => (e as num).toDouble()).toList(),
    levels: m['levels'] as int? ?? 10,
    roundingMode: LotRoundingMode.values.firstWhere(
      (e) => e.name == m['roundingMode'],
      orElse: () => LotRoundingMode.round,
    ),
  );

  static Map _instrumentToMap(InstrumentSpec i) => {
    'symbol': i.symbol,
    'contractSize': i.contractSize,
    'tickSize': i.tickSize,
    'tickValuePerLot': i.tickValuePerLot,
    'digits': i.digits,
    'lotMin': i.lotMin,
    'lotMax': i.lotMax,
    'lotStep': i.lotStep,
    'marginPercent': i.marginPercent,
  };

  static InstrumentSpec _mapToInstrument(Map m) => InstrumentSpec(
    symbol: m['symbol'] as String? ?? 'XAUUSD',
    contractSize: (m['contractSize'] as num?)?.toDouble() ?? 100,
    tickSize: (m['tickSize'] as num?)?.toDouble() ?? 0.01,
    tickValuePerLot: (m['tickValuePerLot'] as num?)?.toDouble() ?? 1.0,
    digits: m['digits'] as int? ?? 2,
    lotMin: (m['lotMin'] as num?)?.toDouble() ?? 0.01,
    lotMax: (m['lotMax'] as num?)?.toDouble() ?? 100,
    lotStep: (m['lotStep'] as num?)?.toDouble() ?? 0.01,
    marginPercent: (m['marginPercent'] as num?)?.toDouble() ?? 100,
  );

  static Map _executionToMap(ExecutionSpec e) => {
    'spreadPoints': e.spreadPoints,
    'commissionPerLot': e.commissionPerLot,
    'swapPerLotPerDay': e.swapPerLotPerDay,
    'holdingDays': e.holdingDays,
    'hedgeMode': e.hedgeMode.name,
    'hedgedMarginFactor': e.hedgedMarginFactor,
  };

  static ExecutionSpec _mapToExecution(Map m) => ExecutionSpec(
    spreadPoints: (m['spreadPoints'] as num?)?.toDouble() ?? 30,
    commissionPerLot: (m['commissionPerLot'] as num?)?.toDouble() ?? 0,
    swapPerLotPerDay: (m['swapPerLotPerDay'] as num?)?.toDouble() ?? 0,
    holdingDays: m['holdingDays'] as int? ?? 0,
    hedgeMode: HedgeMode.values.firstWhere(
      (e) => e.name == m['hedgeMode'],
      orElse: () => HedgeMode.hedgingFull,
    ),
    hedgedMarginFactor: (m['hedgedMarginFactor'] as num?)?.toDouble() ?? 0.5,
  );

  static Map _accountToMap(AccountSpec a) => {
    'balance': a.balance,
    'equity': a.equity,
    'accountCurrency': a.accountCurrency,
    'leverage': a.leverage,
    'stopOutLevelPercent': a.stopOutLevelPercent,
    'marginCallLevelPercent': a.marginCallLevelPercent,
  };

  static AccountSpec _mapToAccount(Map m) => AccountSpec(
    balance: (m['balance'] as num?)?.toDouble() ?? 10000,
    equity: (m['equity'] as num?)?.toDouble(),
    accountCurrency: m['accountCurrency'] as String? ?? 'USD',
    leverage: (m['leverage'] as num?)?.toDouble() ?? 500,
    stopOutLevelPercent: (m['stopOutLevelPercent'] as num?)?.toDouble() ?? 20,
    marginCallLevelPercent: (m['marginCallLevelPercent'] as num?)?.toDouble(),
  );

  static Map _constraintsToMap(ConstraintSet c) => {
    'maxDrawdownPercent': c.maxDrawdownPercent,
    'maxTotalLot': c.maxTotalLot,
    'minMarginLevelPercent': c.minMarginLevelPercent,
    'maxLossAmount': c.maxLossAmount,
  };

  static ConstraintSet _mapToConstraints(Map m) => ConstraintSet(
    maxDrawdownPercent: (m['maxDrawdownPercent'] as num?)?.toDouble(),
    maxTotalLot: (m['maxTotalLot'] as num?)?.toDouble(),
    minMarginLevelPercent: (m['minMarginLevelPercent'] as num?)?.toDouble(),
    maxLossAmount: (m['maxLossAmount'] as num?)?.toDouble(),
  );
}

/// Saved strategy with metadata.
class SavedStrategy {
  final int index;
  final String name;
  final DateTime timestamp;
  final StrategySpec strategy;
  final InstrumentSpec instrument;
  final ExecutionSpec execution;
  final AccountSpec account;
  final double currentPrice;
  final ConstraintSet constraints;

  const SavedStrategy({
    required this.index,
    required this.name,
    required this.timestamp,
    required this.strategy,
    required this.instrument,
    required this.execution,
    required this.account,
    required this.currentPrice,
    required this.constraints,
  });
}
