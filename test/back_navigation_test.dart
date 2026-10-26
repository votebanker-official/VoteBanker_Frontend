import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/dashboard/screens/dashboard_placeholder_screen.dart';
import 'package:votebanker/features/onboarding/screens/social_setup_screen.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard hides back when it is the root route', (tester) async {
    await tester.pumpWidget(_app(const DashboardPlaceholderScreen()));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsNothing);
    expect(find.text('VOTE BANKER'), findsWidgets);
    expect(find.byType(DashboardPlaceholderScreen), findsOneWidget);
  });

  testWidgets('dashboard back returns to the previous screen', (tester) async {
    await tester.pumpWidget(_stack(const DashboardPlaceholderScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('VOTE BANKER'), findsWidgets);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Previous'), findsOneWidget);
    expect(find.byType(DashboardPlaceholderScreen), findsNothing);
  });

  testWidgets('social setup back returns without changing actions', (tester) async {
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
    expect(find.text('Email'), findsOneWidget);
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
