import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/dashboard/screens/dashboard_placeholder_screen.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(390, 844), Size(1280, 800)]) {
    for (final dark in const [false, true]) {
      testWidgets(
        'dashboard lays out at ${size.width.toInt()} ${dark ? 'dark' : 'light'}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            ThemeScope(
              controller: ThemeController(dark ? ThemeMode.dark : ThemeMode.light),
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
          expect(find.text('Dashboard'), findsWidgets);
          expect(find.text('My Portfolio'), findsWidgets);
          expect(find.text('Saved Voters'), findsWidgets);
          expect(find.text('My Voters'), findsWidgets);
          expect(find.text('Social Media'), findsWidgets);
        },
      );
    }
  }
}
