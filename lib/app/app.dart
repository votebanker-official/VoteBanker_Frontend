import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/services/theme_controller.dart';
import '../features/onboarding/state/onboarding_controller.dart';
import 'localization/app_localizations.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class VoteBankerApp extends StatefulWidget {
  const VoteBankerApp({this.controller, this.themeController, super.key});

  final OnboardingController? controller;
  final ThemeController? themeController;

  @override
  State<VoteBankerApp> createState() => _VoteBankerAppState();
}

class _VoteBankerAppState extends State<VoteBankerApp> {
  late final OnboardingController _controller =
      widget.controller ?? OnboardingController();
  late final bool _ownsController = widget.controller == null;
  late final ThemeController _themeController =
      widget.themeController ?? ThemeController();
  late final bool _ownsThemeController = widget.themeController == null;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsThemeController) {
      _themeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: OnboardingScope(
        controller: _controller,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: _themeController,
          builder: (context, themeMode, _) {
            return ValueListenableBuilder<Locale>(
              valueListenable: _controller.locale,
              builder: (context, locale, _) {
                return MaterialApp(
                  title: 'VOTE BANKER',
                  debugShowCheckedModeBanner: false,
                  navigatorKey: _navigatorKey,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: themeMode,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    _MaterialLocalizationsFallback(),
                    _WidgetsLocalizationsFallback(),
                    _CupertinoLocalizationsFallback(),
                  ],
                  initialRoute: AppRoutes.login,
                  onGenerateRoute: AppRouter.onGenerateRoute,
                  scrollBehavior: const MaterialScrollBehavior().copyWith(
                    scrollbars: true,
                    dragDevices: <PointerDeviceKind>{
                      PointerDeviceKind.touch,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Flutter does not ship Material text for every language in the corner list.
/// Those codes still switch the app's own strings, while Flutter's controls
/// use English so menus and buttons keep a MaterialLocalizations ancestor.
class _MaterialLocalizationsFallback
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final delegate = GlobalMaterialLocalizations.delegate;
    final resolved = delegate.isSupported(locale) ? locale : const Locale('en');
    return delegate.load(resolved);
  }

  @override
  bool shouldReload(_MaterialLocalizationsFallback old) => false;
}

class _WidgetsLocalizationsFallback
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _WidgetsLocalizationsFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    final delegate = GlobalWidgetsLocalizations.delegate;
    final resolved = delegate.isSupported(locale) ? locale : const Locale('en');
    return delegate.load(resolved);
  }

  @override
  bool shouldReload(_WidgetsLocalizationsFallback old) => false;
}

class _CupertinoLocalizationsFallback
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoLocalizationsFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final delegate = GlobalCupertinoLocalizations.delegate;
    final resolved = delegate.isSupported(locale) ? locale : const Locale('en');
    return delegate.load(resolved);
  }

  @override
  bool shouldReload(_CupertinoLocalizationsFallback old) => false;
}
