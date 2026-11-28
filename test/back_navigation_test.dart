import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/dashboard/screens/dashboard_placeholder_screen.dart';
import 'package:votebanker/features/onboarding/screens/social_setup_screen.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('authenticated deep links remain the initial route', () {
    expect(
      AppRouter.initialRouteForPath(AppRoutes.voterLists, isSignedIn: true),
      AppRoutes.voterLists,
    );
  });

  test('guest deep links are retained for after login', () {
    expect(
      AppRouter.initialRouteForPath(
        '${AppRoutes.voterLists}?source=direct',
        isSignedIn: false,
      ),
      AppRoutes.login,
    );
    expect(AuthService.instance.takePostLoginRoute(), AppRoutes.voterLists);
  });

  testWidgets('unknown routes display a not found page', (tester) async {
    await tester.pumpWidget(_routed('/not-a-valid-route'));
    await tester.pumpAndSettle();

    expect(find.text('404'), findsOneWidget);
    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('dashboard shows a back arrow on the root route', (tester) async {
    await tester.pumpWidget(_app(const DashboardPlaceholderScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-welcome-back')), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(_topBarBack, findsNothing);
    expect(find.text('VOTE BANKER'), findsWidgets);
    expect(find.byType(DashboardPlaceholderScreen), findsOneWidget);
  });

  testWidgets('welcome back stays on the dashboard when it is the root', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const DashboardPlaceholderScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-welcome-back')));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardPlaceholderScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome back returns to the previous screen', (tester) async {
    await tester.pumpWidget(_stack(const DashboardPlaceholderScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-welcome-back')));
    await tester.pumpAndSettle();

    expect(find.text('Previous'), findsOneWidget);
    expect(find.byType(DashboardPlaceholderScreen), findsNothing);
  });

  testWidgets('dashboard top bar has no back button', (tester) async {
    await tester.pumpWidget(_routed(AppRoutes.dashboard));
    await tester.pumpAndSettle();

    expect(_topBarBack, findsNothing);
    expect(find.byKey(const Key('dashboard-welcome-back')), findsOneWidget);
    expect(find.byType(DashboardPlaceholderScreen), findsOneWidget);
  });

  testWidgets('root dashboard back restores the previous onboarding pages', (
    tester,
  ) async {
    await tester.pumpWidget(_routed(AppRoutes.dashboard));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-welcome-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ready-back')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ready-back')));
    await tester.pumpAndSettle();
    expect(find.text('Create Your Campaign Merchandise'), findsOneWidget);
    expect(find.text('1 of 12'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('voter-lists-back')), findsOneWidget);
    expect(find.byKey(const Key('voter-lists-title')), findsOneWidget);
  });

  testWidgets('social setup back returns without changing actions', (
    tester,
  ) async {
    await tester.pumpWidget(_stack(const SocialSetupScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Social Media Setup'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('X / Twitter'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Save & Continue'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Previous'), findsOneWidget);
    expect(find.byType(SocialSetupScreen), findsNothing);
  });

  testWidgets('a second back tap does not pop twice', (tester) async {
    await tester.pumpWidget(_stack(const SocialSetupScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byTooltip('Back'));
    AppRouter.popIfPossible(context);
    AppRouter.popIfPossible(context);
    await tester.pumpAndSettle();

    expect(find.text('Previous'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _topBarBack = find.byWidgetPredicate(
  (widget) =>
      widget is IconButton &&
      widget.tooltip == 'Back' &&
      widget.key != const Key('dashboard-welcome-back'),
);

Widget _app(Widget home) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}

Widget _routed(String route) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: route,
        onGenerateRoute: AppRouter.onGenerateRoute,
        onGenerateInitialRoutes: (String initialRoute) {
          return [AppRouter.onGenerateRoute(RouteSettings(name: initialRoute))];
        },
      ),
    ),
  );
}

Widget _stack(Widget destination) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Previous'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => destination),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
