/// App configuration for AdMob and feature flags.
class AppConfig {
  // ─── AdMob ───────────────────────────────────────────────────
  /// Set to `true` to use Google's test ad units (safe to click).
  /// Set to `false` before publishing to use your real ad unit IDs.
  static const bool testAds = true;

  // ─── AdMob App IDs ───────────────────────────────────────────
  // TODO: Replace with your own AdMob App IDs before publishing
  static const String _androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String _iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  // ─── Test Ad Unit IDs (Google sample) ────────────────────────
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  // ─── Real Ad Unit IDs (TODO: replace before publishing) ──────
  static const String _realBannerAndroid = 'ca-app-pub-0000000000000000/0000000000';
  static const String _realBannerIos = 'ca-app-pub-0000000000000000/0000000000';

  // ─── Public API ──────────────────────────────────────────────
  static String get appId {
    if (testAds) return _androidAppId; // fallback, resolved per-platform
    return _androidAppId;
  }

  static String get androidAppId => _androidAppId;
  static String get iosAppId => _iosAppId;

  static String get bannerAdUnitId {
    return testAds ? _testBannerAndroid : _realBannerAndroid;
  }

  static String get bannerAdUnitIdAndroid =>
      testAds ? _testBannerAndroid : _realBannerAndroid;

  static String get bannerAdUnitIdIos =>
      testAds ? _testBannerIos : _realBannerIos;
}
