import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/localization/translations/en.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/features/merchandise/screens/merchandise_screen.dart';
import 'package:votebanker/features/merchandise/services/merchandise_service.dart';
import 'package:votebanker/features/onboarding/screens/social_setup_screen.dart';
import 'package:votebanker/features/onboarding/services/social_connection_service.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

class _FakeService extends SocialConnectionService {
  _FakeService({this.error})
      : super(client: MockClient((_) async => http.Response('{"connections":[]}', 200)));

  final String? error;
  var startCalls = 0;

  @override
  Future<List<SocialConnection>> load() async => const [];

  @override
  Future<String> start(String provider, String returnTo) async {
    startCalls += 1;
    throw SocialConnectionException(error ?? 'not_configured');
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Connect opens the confirmation dialog and Cancel stays disconnected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app(SocialSetupScreen(service: _FakeService())));
    await tester.pumpAndSettle();

    expect(find.text(enTranslations['socialTitle']!), findsOneWidget);
    expect(find.text(enTranslations['socialConnect']!), findsWidgets);
    expect(find.text(enTranslations['socialConnectedBadge']!), findsNothing);

    await tester.tap(find.text(enTranslations['socialConnect']!).first);
    await tester.pumpAndSettle();

    expect(find.text('Connect Instagram'), findsOneWidget);
    expect(find.text(enTranslations['socialSecureTitle']!), findsOneWidget);
    expect(find.text(enTranslations['socialPermissionsTitle']!), findsOneWidget);
    expect(find.text('Continue to Instagram'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Connect Instagram'), findsNothing);
    expect(find.text(enTranslations['socialConnectedBadge']!), findsNothing);
  });

  testWidgets('a missing provider configuration does not mark the account Connected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final service = _FakeService();
    AuthService.instance.session = const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'user-1',
      phone: '+910000000000',
    );
    addTearDown(() => AuthService.instance.session = null);
    await tester.pumpWidget(_app(SocialSetupScreen(service: service)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(enTranslations['socialConnect']!).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue to Instagram'));
    await tester.tap(find.text('Continue to Instagram'));
    await tester.pumpAndSettle();

    expect(service.startCalls, 1);
    expect(find.text(enTranslations['socialNotConfiguredProvider']!), findsOneWidget);
    expect(find.text(enTranslations['socialRetry']!), findsOneWidget);
    expect(find.text(enTranslations['socialConnectedBadge']!), findsNothing);
  });

  testWidgets('Skip for now and Save & Continue both open Campaign', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app(SocialSetupScreen(service: _FakeService())));
    await tester.pumpAndSettle();

    final skip = find.text(enTranslations['skipForNow']!);
    final save = find.text(enTranslations['saveAndContinue']!);
    expect(tester.getTopLeft(skip).dy, lessThan(tester.getTopLeft(save).dy));

    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(find.text('Campaign'), findsWidgets);
    expect(find.text(enTranslations['socialTitle']!), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text(enTranslations['socialTitle']!), findsOneWidget);

    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Campaign'), findsWidgets);
  });
}

Widget _app(Widget child) {
  return ThemeScope(
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
        home: child,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.merchandise) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const MerchandiseScreen(
                initialCatalog: MerchandiseCatalog(
                  products: [],
                  storageReady: true,
                ),
              ),
            );
          }
          return AppRouter.onGenerateRoute(settings);
        },
      ),
    ),
  );
}
