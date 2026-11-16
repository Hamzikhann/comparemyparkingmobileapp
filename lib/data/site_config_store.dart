import 'package:parkingapp/data/booking_flow.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';

/// GET /api/site-config, loaded once per app run and shared by every screen
/// (the website's useSiteConfig). Until it answers, [current] is the built-in defaults.
class SiteConfigStore {
  static SiteConfig current = SiteConfig.defaults;
  static Future<SiteConfig>? _pending;
  static bool _loaded = false;

  static Future<SiteConfig> load() {
    if (_loaded) return Future.value(current);
    return _pending ??= GeneralRepository().getSiteConfig().then((config) {
      current = config;
      // A failed load returns the defaults; try again next time
      _loaded = !identical(config, SiteConfig.defaults);
      _pending = null;
      return config;
    });
  }
}
