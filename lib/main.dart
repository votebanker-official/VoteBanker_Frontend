import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  try {
    await AppTheme.preloadFonts().timeout(const Duration(seconds: 8));
  } catch (_) {
    // The app still opens if the font host cannot be reached.
  }
  runApp(const VoteBankerApp());
}
