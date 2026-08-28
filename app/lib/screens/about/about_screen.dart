import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/safe_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _privacyPolicyUrl = 'https://gridsurvivalsimulator.web.app/privacy.html';
  static const String _termsOfServiceUrl = 'https://gridsurvivalsimulator.web.app/guide.html';
  static const String _userGuideUrl = 'https://gridsurvivalsimulator.web.app/guide.html';

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      title: 'About',
      showBannerAd: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.grid_view,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Grid Survival Simulator',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'v1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stress-test your Grid/Martingale strategy\nbefore the market does.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legal
          Text(
            'Legal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('How we handle your data'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(_privacyPolicyUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  subtitle: const Text('Usage terms and conditions'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(_termsOfServiceUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Help
          Text(
            'Help',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('User Guide'),
                  subtitle: const Text('Learn how to use the app'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(_userGuideUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Disclaimer
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disclaimer',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app is an analytical and educational tool only. '
                    'It does not provide financial advice. Actual broker '
                    'outcomes may differ from simulated results. Trading '
                    'involves significant risk of loss.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
