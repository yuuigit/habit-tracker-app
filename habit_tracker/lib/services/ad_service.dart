import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // テスト用バナー広告ID（本番リリース時は実際のIDに変更）
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}
