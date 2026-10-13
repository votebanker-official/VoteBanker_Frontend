import 'package:shared_preferences/shared_preferences.dart';

import '../models/portfolio_config.dart';

class PortfolioStore {
  PortfolioStore._();

  static final PortfolioStore instance = PortfolioStore._();
  static const prefsKey = 'portfolio_website_config_v2';

  Future<PortfolioConfig?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return null;
      return PortfolioConfig.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PortfolioConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, config.encode());
    } catch (_) {
      // Keep the session copy if storage fails.
    }
  }
}
