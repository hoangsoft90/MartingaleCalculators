import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

/// Reusable AdMob banner ad widget.
///
/// Shows a banner ad at the bottom of screens.
/// Automatically uses test ads when [AppConfig.testAds] is true.
class AppBannerAd extends StatefulWidget {
  final AdSize adSize;

  const AppBannerAd({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _bannerAd;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  String get _adUnitId {
    if (Platform.isAndroid) {
      return AppConfig.bannerAdUnitIdAndroid;
    } else {
      return AppConfig.bannerAdUnitIdIos;
    }
  }

  void _loadAd() {
    final bannerAd = BannerAd(
      size: widget.adSize,
      adUnitId: _adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        },
      ),
    );

    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: _bannerAd == null
          ? const SizedBox()
          : AdWidget(ad: _bannerAd!),
    );
  }
}
