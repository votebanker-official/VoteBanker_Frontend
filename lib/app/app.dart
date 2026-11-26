import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/services/auth_browser.dart';
import '../core/services/auth_service.dart';
import '../core/services/onboarding_progress_service.dart';
import '../core/services/theme_controller.dart';
import '../core/widgets/global_footer.dart';
import '../features/merchandise/merchandise_intent.dart';
import '../features/onboarding/blue_tik/blue_tik_models.dart';
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
  final _activeRouteName = ValueNotifier<String?>(null);
  final _activeRouteShowsMobileNavigation = ValueNotifier<bool>(false);
  late final _routeObserver = _AppRouteObserver(
    _activeRouteName,
    _activeRouteShowsMobileNavigation,
  );

  String get _initialRoute {
    final basePath = Uri.base.path;
    if (basePath == AppRoutes.profile || basePath == AppRoutes.authCallback) {
      return basePath;
    }
    final path =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName
            .split('?')
            .first;
    if (path == AppRoutes.profile || path == AppRoutes.authCallback)
      return path;
    return AppRoutes.login;
  }

  void _openRoute(String route) {
    final navigatorContext = _navigatorKey.currentState?.context;
    if (navigatorContext == null) {
      throw StateError('The app navigator is not available.');
    }
    AppRouter.open(
      navigatorContext,
      route,
      arguments:
          route == AppRoutes.website
              ? AppRoutes.mobileNavigationArgument
              : null,
    );
  }

  @override
  void initState() {
    super.initState();
    // Restore UI language from a pre-seeded or previously saved draft.
    _controller.syncLocaleFromDraft();
    if (AuthService.instance.openProfileAfterLogin ||
        _initialRoute == AppRoutes.profile ||
        AuthService.instance.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!AuthService.instance.isSignedIn) return;
        final pendingMerch = await MerchandiseIntent.peek();
        final pendingBlue = await BlueTikIntent.peek();
        final returningToProfile =
            AuthService.instance.openProfileAfterLogin ||
            _initialRoute == AppRoutes.profile;
        final shouldResume =
            pendingMerch != null ||
            pendingBlue != null ||
            returningToProfile ||
            AuthService.instance.isSignedIn;
        if (!shouldResume || !mounted) return;
        final resume =
            await OnboardingProgressService.instance.resolveResumeRoute();
        if (!mounted) return;
        final destination =
            pendingMerch != null
                ? AppRoutes.campaignTemplates
                : pendingBlue != null
                ? AppRoutes.blueTik
                : returningToProfile
                ? AppRoutes.profile
                : resume;
        replaceBrowserPath(destination);
        final navigator = _navigatorKey.currentState;
        if (navigator == null) return;
        var alreadyThere = false;
        navigator.popUntil((route) {
          alreadyThere = route.settings.name == destination;
          return true;
        });
        if (alreadyThere) return;
        navigator.pushNamedAndRemoveUntil(destination, (route) => false);
      });
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsThemeController) {
      _themeController.dispose();
    }
    _routeObserver.dispose();
    _activeRouteName.dispose();
    _activeRouteShowsMobileNavigation.dispose();
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
                  navigatorObservers: [_routeObserver],
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: themeMode,
                  builder: (context, child) {
                    return ValueListenableBuilder<String?>(
                      valueListenable: _activeRouteName,
                      builder:
                          (context, routeName, _) =>
                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    _activeRouteShowsMobileNavigation,
                                builder:
                                    (context, mobileNavigationEnabled, _) =>
                                        GlobalFooter.mainAppLayout(
                                          context,
                                          child ?? const SizedBox.shrink(),
                                          routeName: routeName,
                                          mobileNavigationEnabled:
                                              mobileNavigationEnabled,
                                          onNavigate: _openRoute,
                                        ),
                              ),
                    );
                  },
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    _MaterialLocalizationsFallback(),
                    _WidgetsLocalizationsFallback(),
                    _CupertinoLocalizationsFallback(),
                  ],
                  initialRoute: _initialRoute,
                  onGenerateRoute: AppRouter.onGenerateRoute,
                  onGenerateInitialRoutes: (String initialRoute) {
                    return [
                      AppRouter.onGenerateRoute(
                        RouteSettings(name: initialRoute),
                      ),
                    ];
                  },
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

class _AppRouteObserver extends NavigatorObserver {
  _AppRouteObserver(
    this.activeRouteName,
    this.activeRouteShowsMobileNavigation,
  );

  final ValueNotifier<String?> activeRouteName;
  final ValueNotifier<bool> activeRouteShowsMobileNavigation;
  bool _disposed = false;

  void dispose() {
    _disposed = true;
  }

  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;
    final normalized = AppRouter.normalizeRouteName(name);
    final showsMobileNavigation =
        AppRoutes.showsMobileNavigation(normalized) &&
        (normalized != AppRoutes.website ||
            route!.settings.arguments == AppRoutes.mobileNavigationArgument);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      activeRouteName.value = normalized;
      activeRouteShowsMobileNavigation.value = showsMobileNavigation;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    final name = route.settings.name;
    if (name != null &&
        activeRouteName.value == AppRouter.normalizeRouteName(name)) {
      _update(previousRoute);
    }
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
