import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/localization/translations/en.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/merchandise/screens/campaign_templates_screen.dart';
import 'package:votebanker/features/merchandise/services/merchandise_service.dart';
import 'package:votebanker/features/onboarding/blue_tik/blue_tik_models.dart';
import 'package:votebanker/features/onboarding/blue_tik/blue_tik_screen.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    BlueTikApplicationStore.instance.clear();
    AuthService.instance.session = null;
    await BlueTikIntent.clear();
  });

  test('assistance prices use rupee grouping', () {
    expect(formatInr(799), '₹799');
    expect(formatInr(999), '₹999');
    expect(formatInr(1999), '₹1,999');
    expect(BlueTikCatalog.instagram.priceInr, 799);
    expect(BlueTikCatalog.facebook.priceInr, 799);
    expect(BlueTikCatalog.whatsapp.priceInr, 999);
    expect(BlueTikCatalog.bundle.priceInr, 1999);
  });

  test('a request stays invalid until every field is usable', () {
    final empty = validateBlueTikRequest(
      name: ' ',
      mobile: '123',
      email: 'not-an-email',
      profileUrls: {'instagram': 'instagram.com/asha'},
    );
    expect(empty.isValid, isFalse);
    expect(empty.name, 'name_required');
    expect(empty.mobile, 'mobile_invalid');
    expect(empty.email, 'email_invalid');
    expect(empty.urls['instagram'], 'url_invalid');

    final ready = validateBlueTikRequest(
      name: 'Asha Rao',
      mobile: '9876543210',
      email: 'asha@example.com',
      profileUrls: {'instagram': 'https://instagram.com/asha'},
    );
    expect(ready.isValid, isTrue);
  });

  testWidgets('desktop keeps cards in a row and mobile stacks them', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, const Size(1280, 900));
    _expectOfferCopy();
    expect(find.text('VOTE BANKER'), findsNothing);
    expect(find.byType(Image), findsNothing);

    final instagram = tester.getCenter(
      find.byKey(const Key('blue-tik-card-instagram')),
    );
    final facebook = tester.getCenter(
      find.byKey(const Key('blue-tik-card-facebook')),
    );
    final whatsapp = tester.getCenter(
      find.byKey(const Key('blue-tik-card-whatsapp')),
    );
    expect(facebook.dx, greaterThan(instagram.dx + 40));
    expect(whatsapp.dx, greaterThan(facebook.dx + 40));
    expect((instagram.dy - facebook.dy).abs(), lessThan(20));
    expect((facebook.dy - whatsapp.dy).abs(), lessThan(20));
    _expectChromeBelowCards(tester);
    expect(tester.takeException(), isNull);

    await _pump(tester, const Size(390, 844));
    _expectOfferCopy();
    final narrowInstagram = tester.getCenter(
      find.byKey(const Key('blue-tik-card-instagram')),
    );
    final narrowFacebook = tester.getCenter(
      find.byKey(const Key('blue-tik-card-facebook')),
    );
    final narrowWhatsapp = tester.getCenter(
      find.byKey(const Key('blue-tik-card-whatsapp')),
    );
    expect(narrowFacebook.dy, greaterThan(narrowInstagram.dy + 40));
    expect(narrowWhatsapp.dy, greaterThan(narrowFacebook.dy + 40));
    expect((narrowInstagram.dx - narrowFacebook.dx).abs(), lessThan(20));
    _expectChromeBelowCards(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back returns to social setup and Skip Now opens voter lists', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(1280, 900));

    await tester.tap(find.byKey(const Key('blue-tik-back')));
    await tester.pumpAndSettle();
    expect(find.text(enTranslations['socialTitle']!), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-screen')), findsNothing);

    await tester.tap(find.text(enTranslations['saveAndContinue']!));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blue-tik-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('blue-tik-skip')));
    await tester.pumpAndSettle();
    expect(find.text('Get Your Voter Lists'), findsWidgets);
    expect(find.byKey(const Key('blue-tik-screen')), findsNothing);
  });

  testWidgets('Book Now submits the chosen platform as pending', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _signIn();
    final controller = OnboardingController()..draft.leaderName = 'Asha Rao';
    addTearDown(controller.dispose);
    await _pump(tester, const Size(1280, 1100), controller: controller);

    await tester.tap(find.byKey(const Key('blue-tik-book-instagram')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('blue-tik-booking')), findsOneWidget);
    expect(find.text('Selected service'), findsOneWidget);
    expect(find.text('Get Verified on Instagram'), findsOneWidget);
    expect(find.text('₹799'), findsWidgets);
    expect(find.byKey(const Key('blue-tik-url-instagram')), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-url-facebook')), findsNothing);
    expect(_fieldText(tester, const Key('blue-tik-name')), 'Asha Rao');

    await tester.tap(find.byKey(const Key('blue-tik-submit')));
    await tester.pumpAndSettle();
    expect(find.text(enTranslations['blueTikMobileInvalid']!), findsOneWidget);
    expect(BlueTikApplicationStore.instance.items, isEmpty);
    expect(find.byKey(const Key('blue-tik-confirmation')), findsNothing);

    await _enter(tester, const Key('blue-tik-mobile'), '9876543210');
    await _enter(tester, const Key('blue-tik-email'), 'asha@example.com');
    await _enter(
      tester,
      const Key('blue-tik-url-instagram'),
      'https://instagram.com/asha',
    );
    await tester.ensureVisible(find.byKey(const Key('blue-tik-submit')));
    await tester.tap(find.byKey(const Key('blue-tik-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('blue-tik-confirmation')), findsOneWidget);
    expect(find.text('Application submitted'), findsOneWidget);
    expect(find.text('Pending platform review'), findsOneWidget);
    expect(
      find.text('We received your request for Instagram (₹799).'),
      findsOneWidget,
    );
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.textContaining('Approved'), findsNothing);
    expect(find.textContaining('Verified'), findsNothing);

    final saved = BlueTikApplicationStore.instance.items.single;
    expect(saved.offerId, 'instagram');
    expect(saved.serviceName, 'Instagram');
    expect(saved.priceInr, 799);
    expect(saved.leaderName, 'Asha Rao');
    expect(saved.mobile, '+919876543210');
    expect(saved.email, 'asha@example.com');
    expect(saved.profileUrls['instagram'], 'https://instagram.com/asha');

    await tester.tap(find.byKey(const Key('blue-tik-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blue-tik-screen')), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-confirmation')), findsNothing);
  });

  testWidgets('WhatsApp and the combined package keep their own price', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    _signIn();
    await _pump(tester, const Size(390, 900));

    await tester.ensureVisible(find.byKey(const Key('blue-tik-book-whatsapp')));
    await tester.tap(find.byKey(const Key('blue-tik-book-whatsapp')));
    await tester.pumpAndSettle();
    expect(find.text('Get Verified on WhatsApp'), findsOneWidget);
    expect(find.text('₹999'), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-url-whatsapp')), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-url-instagram')), findsNothing);

    await tester.tap(find.byKey(const Key('blue-tik-back')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('blue-tik-book-bundle')));
    await tester.tap(find.byKey(const Key('blue-tik-book-bundle')));
    await tester.pumpAndSettle();
    expect(find.text('Get all 3 Blue Tik'), findsOneWidget);
    expect(find.text('₹1,999'), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-url-instagram')), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-url-facebook')), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-url-whatsapp')), findsOneWidget);
    expect(find.text('Get Verified on Instagram'), findsNothing);
  });

  testWidgets('Book Now sends a signed-out visitor to login', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, const Size(1280, 900));

    await tester.tap(find.byKey(const Key('blue-tik-book-facebook')));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Facebook'), findsOneWidget);
    expect(find.byKey(const Key('blue-tik-booking')), findsNothing);
    expect(await BlueTikIntent.peek(), 'facebook');

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('blue-tik-book-bundle')));
    await tester.tap(find.byKey(const Key('blue-tik-book-bundle')));
    await tester.pumpAndSettle();
    expect(await BlueTikIntent.peek(), 'bundle');
    expect(find.byKey(const Key('blue-tik-booking')), findsNothing);
  });
}

void _signIn() {
  AuthService.instance.session = const AuthSession(
    accessToken: 'test-token',
    refreshToken: 'test-refresh',
    userId: 'user-1',
    phone: '',
    email: 'asha@example.com',
  );
}

void _expectOfferCopy() {
  expect(find.text('Get Your Blue Tik'), findsOneWidget);
  expect(
    find.text(
      'Verify your social accounts and build more trust with your followers.',
    ),
    findsOneWidget,
  );
  expect(find.text('Instagram'), findsWidgets);
  expect(find.text('Facebook'), findsWidgets);
  expect(find.text('WhatsApp'), findsWidgets);
  expect(find.text('Get Verified on Instagram'), findsOneWidget);
  expect(find.text('Get Verified on Facebook'), findsOneWidget);
  expect(find.text('Get Verified on WhatsApp'), findsOneWidget);
  expect(find.text('₹799'), findsWidgets);
  expect(find.text('₹999'), findsOneWidget);
  expect(find.text('Get all 3 Blue Tik'), findsOneWidget);
  expect(find.text('₹1,999'), findsOneWidget);
  expect(find.text('Book Now'), findsNWidgets(4));
  expect(find.text('Skip'), findsOneWidget);
  expect(find.textContaining('not guaranteed'), findsOneWidget);
}

void _expectChromeBelowCards(WidgetTester tester) {
  final back = tester.getTopLeft(find.byKey(const Key('blue-tik-back')));
  final title = tester.getTopLeft(find.byKey(const Key('blue-tik-title')));
  final bundle = tester.getTopLeft(
    find.byKey(const Key('blue-tik-card-bundle')),
  );
  final skip = tester.getTopLeft(find.byKey(const Key('blue-tik-skip')));
  final whatsapp = tester.getTopLeft(
    find.byKey(const Key('blue-tik-card-whatsapp')),
  );
  expect(back.dy, lessThan(title.dy));
  expect(back.dx, lessThanOrEqualTo(title.dx + 1));
  expect(bundle.dy, greaterThan(whatsapp.dy));
  expect(skip.dy, lessThan(title.dy));
  expect(skip.dx, greaterThan(back.dx));
}

String _fieldText(WidgetTester tester, Key key) {
  final field = tester.widget<TextField>(
    find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
  );
  return field.controller?.text ?? '';
}

Future<void> _enter(WidgetTester tester, Key key, String value) async {
  final field = find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  OnboardingController? controller,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    _app(BlueTikScreen(saver: (_) async {}), controller: controller),
  );
  await tester.pumpAndSettle();
}

class _QuietMerchandiseService extends MerchandiseService {
  _QuietMerchandiseService() : super(baseUrls: const ['http://127.0.0.1:9']);
}

Widget _app(Widget home, {OnboardingController? controller}) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: controller ?? OnboardingController(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRoutes.blueTik,
        onGenerateInitialRoutes: (initialRoute) {
          return [
            MaterialPageRoute<void>(
              settings: RouteSettings(name: initialRoute),
              builder: (_) => home,
            ),
          ];
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.blueTik) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => home,
            );
          }
          if (settings.name == AppRoutes.campaignTemplates) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder:
                  (_) => CampaignTemplatesScreen(
                    service: _QuietMerchandiseService(),
                  ),
            );
          }
          return AppRouter.onGenerateRoute(settings);
        },
      ),
    ),
  );
}
