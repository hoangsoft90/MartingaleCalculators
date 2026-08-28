import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _screenshotController = ScreenshotController();

  Future<void> _shareImage(InstrumentSpec instrument, BuildContext context) async {
    final image = await _screenshotController.capture();
    if (image != null && mounted) {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/grid_result.png').writeAsBytes(image);
      // Get share position for iPad/tablet (required or crashes)
      final box = context.findRenderObject() as RenderBox?;
      final shareOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.zero;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Grid Survival Simulator - ${instrument.symbol}',
        sharePositionOrigin: shareOrigin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(calculationResultProvider);
    final strategy = ref.watch(strategySpecProvider);
    final instrument = ref.watch(instrumentSpecProvider);
    if (result == null) {
      return const SafeScaffold(
        title: 'Share Results',
        showBannerAd: false,
        body: Center(child: Text('No data to share')),
      );
    }

    return SafeScaffold(
      title: 'Share Results',
      showBannerAd: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareImage(instrument, context),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shareable card
          Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.grid_view,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Grid Survival Simulator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Symbol & Direction
                  _infoRow('Symbol', instrument.symbol),
                  _infoRow('Direction', strategy.direction.name.toUpperCase()),
                  _infoRow('Initial Lot', strategy.initialLot.toStringAsFixed(2)),
                  _infoRow('Multiplier', strategy.multiplier.toStringAsFixed(2)),
                  _infoRow('Levels', '${strategy.levels}'),
                  _infoRow('Distance', strategy.fixedDistance.toString()),
                  const Divider(),

                  // Results
                  _resultRow(
                    'Survivable Levels',
                    '${result.survivableLevels} / ${strategy.levels}',
                    result.survivableLevels >= strategy.levels
                        ? Colors.green
                        : Colors.orange,
                  ),
                  _resultRow(
                    'Max Drawdown',
                    '${result.maxDrawdownPercent.toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                  _resultRow(
                    'Basket Breakeven',
                    '\$${result.basketBreakevenPrice.toStringAsFixed(2)}',
                    Colors.orange,
                  ),
                  if (result.estimatedStopOutPrice != null)
                    _resultRow(
                      'Est. Stop-out',
                      '\$${result.estimatedStopOutPrice!.toStringAsFixed(2)}',
                      Colors.red,
                    ),
                  _resultRow(
                    'Total Exposure',
                    '${result.totalExposureLots.toStringAsFixed(2)} lots',
                    Colors.teal,
                  ),

                  const Divider(),

                  // Disclaimer
                  const Text(
                    'Analytical/educational tool. Not financial advice. Actual broker outcome may differ.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Share button
          FilledButton.icon(
            onPressed: () => _shareImage(instrument, context),
            icon: const Icon(Icons.share),
            label: const Text('Share as Image'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
