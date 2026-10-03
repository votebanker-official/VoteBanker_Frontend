import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  try {
    await AppTheme.preloadFonts().timeout(const Duration(seconds: 8));
  } catch (_) {
    // The app still opens if the font host cannot be reached.
  }
  try {
    await AuthService.instance.restore();
  } catch (_) {
    // A broken saved session must never stop the app from opening.
  }
  final themeController = ThemeController();
  await themeController.load();
  runApp(VoteBankerApp(themeController: themeController));
}
