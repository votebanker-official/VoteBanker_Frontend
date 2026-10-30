import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/dashboard/screens/dashboard_placeholder_screen.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard keeps Volunteers card and hides summary panel', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ThemeScope(
        controller: ThemeController(),
        child: OnboardingScope(
          controller: OnboardingController(),
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const DashboardPlaceholderScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Volunteers'), findsWidgets);
    expect(find.text('Manage Volunteers'), findsNothing);
    expect(find.text('Total Volunteers'), findsNothing);
    expect(find.text('Unassigned'), findsNothing);
    expect(find.text('My Portfolio'), findsWidgets);
    expect(find.text('Saved Voters'), findsWidgets);
    expect(find.text('AI Content Studio'), findsWidgets);
    expect(find.text('My Voters'), findsWidgets);
    expect(find.text('Team'), findsWidgets);
    expect(find.text('Marketplace'), findsWidgets);
    expect(find.textContaining('Administrations'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.text(
        'Register, organize, assign, and manage volunteers from one place.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.text(
        'Register, organize, assign, and manage volunteers from one place.',
      ),
    );
    await tester.tap(
      find.text(
        'Register, organize, assign, and manage volunteers from one place.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BrightPath Volunteers'), findsNothing);
    expect(find.text('No volunteers found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
