import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/core/widgets/global_footer.dart';
import 'package:votebanker/features/dashboard/screens/dashboard_placeholder_screen.dart';
import 'package:votebanker/features/dashboard/widgets/dashboard_colors.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [
    Size(320, 740),
    Size(390, 844),
    Size(768, 1024),
    Size(1024, 800),
    Size(1280, 800),
    Size(1440, 900),
  ]) {
    for (final dark in const [false, true]) {
      testWidgets(
        'dashboard lays out at ${size.width.toInt()} ${dark ? 'dark' : 'light'}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            ThemeScope(
              controller: ThemeController(
                dark ? ThemeMode.dark : ThemeMode.light,
              ),
              child: OnboardingScope(
                controller: OnboardingController(),
                child: MaterialApp(
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  locale: const Locale('en'),
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: const DashboardPlaceholderScreen(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('VOTE BANKER'), findsWidgets);
          expect(find.text('My Portfolio'), findsWidgets);
          expect(find.text('Saved Voters'), findsNothing);
          expect(find.text('My Voters'), findsWidgets);
          expect(find.text('Social Media'), findsWidgets);
          final screenContext = tester.element(
            find.byType(DashboardPlaceholderScreen),
          );
          final colors = DashboardColors.of(screenContext);
          expect(
            tester
                .widget<Scaffold>(find.byType(Scaffold).first)
                .backgroundColor,
            colors.page,
          );
          final dashboardList =
              find
                  .descendant(
                    of: find.byType(DashboardPlaceholderScreen),
                    matching: find.byType(ListView),
                  )
                  .last;
          final dashboardScrollable =
              find
                  .descendant(
                    of: dashboardList,
                    matching: find.byType(Scrollable),
                  )
                  .first;
          await tester.scrollUntilVisible(
            find.text('Campaign Overview'),
            300,
            scrollable: dashboardScrollable,
          );
          await tester.pumpAndSettle();
          expect(find.text('Campaign Templates'), findsNothing);
          final overview = tester.widget<DecoratedBox>(
            find
                .ancestor(
                  of: find.text('Campaign Overview'),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          expect((overview.decoration as BoxDecoration).color, colors.card);
          await tester.scrollUntilVisible(
            find.text('Start Campaign'),
            300,
            scrollable: dashboardScrollable,
          );
          await tester.pumpAndSettle();
          final promo = tester.widget<DecoratedBox>(
            find
                .ancestor(
                  of: find.text('Start Campaign'),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          expect(
            (promo.decoration as BoxDecoration).color,
            dark ? colors.cardAlt : const Color(0xFFEFF6FF),
          );
          expect(tester.takeException(), isNull);
          if (size.width < 960) {
            await tester.tap(find.byIcon(Icons.menu));
            await tester.pumpAndSettle();
            expect(
              find.descendant(
                of: find.byType(Drawer),
                matching: find.text('Campaign Templates'),
              ),
              findsNothing,
            );
          }
        },
      );
    }
  }

  testWidgets('dashboard route uses the compact shared footer', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ThemeController();
    await tester.pumpWidget(
      ThemeScope(
        controller: controller,
        child: OnboardingScope(
          controller: OnboardingController(),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: controller,
            builder: (context, mode, _) {
              return MaterialApp(
                theme: AppTheme.light().copyWith(
                  platform: TargetPlatform.windows,
                ),
                darkTheme: AppTheme.dark().copyWith(
                  platform: TargetPlatform.windows,
                ),
                themeMode: mode,
                locale: const Locale('en'),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                initialRoute: AppRoutes.dashboard,
                onGenerateRoute: AppRouter.onGenerateRoute,
                onGenerateInitialRoutes:
                    (initialRoute) => [
                      AppRouter.onGenerateRoute(
                        RouteSettings(name: initialRoute),
                      ),
                    ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<GlobalFooter>(find.byType(GlobalFooter)).compact,
      isTrue,
    );
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Follow Us'), findsOneWidget);
    expect(tester.takeException(), isNull);

    controller.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Quick Links')).style!.color,
      const Color(0xFFF5F8FC),
    );
    expect(tester.takeException(), isNull);
  });
}
