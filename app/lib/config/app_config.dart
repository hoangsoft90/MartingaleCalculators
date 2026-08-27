/// App configuration for AdMob and feature flags.
class AppConfig {
  // ─── Feature Flags ──────────────────────────────────────────
  /// Master switch for ads. Set to `false` to disable all ads.
  static const bool enableAds = true;

  /// Set to `true` to use Google's test ad units (safe to click).
  /// Set to `false` to use real ad unit IDs.
  /// Only effective when [enableAds] is `true`.
  static const bool testAds = false;

  // ─── AdMob App IDs ─────────────────────────────────────────
  static const String _androidAppId = 'ca-app-pub-6917313063209470~3347852055';
  static const String _iosAppId = 'ca-app-pub-6917313063209470~3347852055';

  // ─── Test Ad Unit IDs (Google sample — safe to click) ──────
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  // ─── Real Ad Unit IDs ─────────────────────────────────────
  static const String _realBannerAndroid = 'ca-app-pub-6917313063209470/6109746764';
  static const String _realBannerIos = 'ca-app-pub-6917313063209470/6109746764';
  static const String _realInterstitialAndroid = 'ca-app-pub-6917313063209470/3483583421';
  static const String _realInterstitialIos = 'ca-app-pub-6917313063209470/3483583421';
  static const String _realRewardedAndroid = 'ca-app-pub-6917313063209470/6985618238';
  static const String _realRewardedIos = 'ca-app-pub-6917313063209470/6985618238';

  // ─── Public API ────────────────────────────────────────────
  static String get androidAppId =>
      testAds ? 'ca-app-pub-3940256099942544~3347511713' : _androidAppId;

  static String get iosAppId =>
      testAds ? 'ca-app-pub-3940256099942544~1458002511' : _iosAppId;

  static String get bannerAdUnitIdAndroid =>
      testAds ? _testBannerAndroid : _realBannerAndroid;

  static String get bannerAdUnitIdIos =>
      testAds ? _testBannerIos : _realBannerIos;

  static String get interstitialAdUnitIdAndroid =>
      testAds ? _testInterstitialAndroid : _realInterstitialAndroid;

  static String get interstitialAdUnitIdIos =>
      testAds ? _testInterstitialIos : _realInterstitialIos;

  static String get rewardedAdUnitIdAndroid =>
      testAds ? _testRewardedAndroid : _realRewardedAndroid;

  static String get rewardedAdUnitIdIos =>
      testAds ? _testRewardedIos : _realRewardedIos;
}
