import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the light/dark choice. Light is the default; the choice is saved.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.initial = ThemeMode.light]);

  static const _prefsKey = 'theme_mode';

  bool get isDark => value == ThemeMode.dark;

  /// Reads the saved choice. Never throws: if storage is unavailable the
  /// default (light) stays.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'dark') {
        value = ThemeMode.dark;
      } else if (saved == 'light') {
        value = ThemeMode.light;
      }
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> toggle() async {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, isDark ? 'dark' : 'light');
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}

/// Makes the [ThemeController] available to widgets like the toggle button.
class ThemeScope extends InheritedWidget {
  const ThemeScope({required this.controller, required super.child, super.key});

  final ThemeController controller;

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope is missing above this widget.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      controller != oldWidget.controller;
}
