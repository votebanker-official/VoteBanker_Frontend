import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the light/dark choice. Light is the default; the choice is saved.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.initial = ThemeMode.light]);

  static const _prefsKey = 'theme_mode';

  bool get isDark => switch (value) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

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
      } else if (saved == 'system') {
        value = ThemeMode.system;
      }
    } catch (_) {
      // Keep the default.
    }
  }

  Future<void> toggle() async {
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      });
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
