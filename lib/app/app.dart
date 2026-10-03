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
            return MaterialApp(
              title: 'VOTE BANKER',
              debugShowCheckedModeBanner: false,
              navigatorKey: _navigatorKey,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
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
              builder: (context, child) {
                return ValueListenableBuilder<Locale>(
                  valueListenable: _controller.locale,
                  builder: (context, locale, navigator) {
                    return Localizations.override(
                      context: context,
                      locale: locale,
                      child: navigator,
                    );
                  },
                  child: child,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
