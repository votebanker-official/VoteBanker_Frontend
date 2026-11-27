import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.session = null;
  });

  tearDown(() {
    AuthService.instance.session = null;
  });

  testWidgets('guest website heading stays My Website', (tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    controller.draft.leaderName = 'Rahul Kumar';

    await _pumpWebsite(
      tester,
      controller,
      const Size(1280, 900),
      keyName: 'guest',
    );

    expect(find.text('My Website'), findsOneWidget);
    expect(find.text('Rahul.com'), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('websiteBuilderHeading')))
          .data,
      'My Website',
    );
  });

  testWidgets('signed-in heading uses the account first name', (tester) async {
    AuthService.instance.session = _session(
      userId: 'google-user',
      fullName: 'vaishnavi kaladagi',
    );
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    controller.draft.leaderName = 'Previous Leader';

    await _pumpWebsite(
      tester,
      controller,
      const Size(1280, 900),
      keyName: 'google',
    );
    expect(find.text('Vaishnavi.com'), findsOneWidget);
    expect(find.text('Previous.com'), findsNothing);
    expect(find.text('My Website'), findsNothing);

    AuthService.instance.session = null;
    await _pumpWebsite(
      tester,
      controller,
      const Size(1280, 900),
      keyName: 'guest',
    );
    expect(find.text('My Website'), findsOneWidget);
    expect(find.text('Vaishnavi.com'), findsNothing);

    AuthService.instance.session = _session(
      userId: 'facebook-user',
      fullName: 'RAHUL SHARMA',
    );
    await _pumpWebsite(
      tester,
      controller,
      const Size(390, 844),
      keyName: 'facebook',
    );
    expect(find.text('Rahul.com'), findsOneWidget);
    expect(find.text('Vaishnavi.com'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing account name keeps the guest heading', (tester) async {
    AuthService.instance.session = _session(
      userId: 'email-user',
      fullName: 'priya@example.com',
      email: 'priya@example.com',
    );
    final controller = OnboardingController();
    addTearDown(controller.dispose);

    await _pumpWebsite(
      tester,
      controller,
      const Size(320, 740),
      keyName: 'email',
    );

    expect(find.text('My Website'), findsOneWidget);
    expect(find.text('.com'), findsNothing);
    expect(find.textContaining('null.com'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long first name stays inside the header', (tester) async {
    AuthService.instance.session = _session(
      userId: 'email-user',
      fullName: 'Verylongfirstname Extra',
    );
    final controller = OnboardingController();
    addTearDown(controller.dispose);

    await _pumpWebsite(
      tester,
      controller,
      const Size(320, 740),
      keyName: 'long',
    );

    expect(find.text('Verylongfirstname.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AuthSession _session({
  required String userId,
  required String fullName,
  String email = '',
}) {
  return AuthSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    userId: userId,
    phone: '',
    fullName: fullName,
    email: email,
  );
}

Future<void> _pumpWebsite(
  WidgetTester tester,
  OnboardingController controller,
  Size size, {
  required String keyName,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ThemeScope(
      controller: ThemeController(),
      child: OnboardingScope(
        controller: controller,
        child: MaterialApp(
          key: ValueKey(keyName),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.website,
          onGenerateRoute: AppRouter.onGenerateRoute,
          onGenerateInitialRoutes: (initialRoute) {
            return [
              AppRouter.onGenerateRoute(RouteSettings(name: initialRoute)),
            ];
          },
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
