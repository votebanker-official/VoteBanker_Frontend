import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/models/domain_suggestion.dart';
import 'package:votebanker/features/onboarding/screens/domain_search_screen.dart';
import 'package:votebanker/features/onboarding/services/domain_service.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  test('domainSlug keeps latin labels and rejects blank or non-latin names', () {
    expect(domainSlug('Arjun Verma'), 'arjunverma');
    expect(domainSlug('Vote-Banker'), 'vote-banker');
    expect(domainSlug('   '), isNull);
    expect(domainSlug('ಅರ್ಜುನ್'), isNull);
  });

  test('DomainSuggestion.fromJson maps availability, price, and premium flags', () {
    final available = DomainSuggestion.fromJson({
      'domain': 'votebanker.com',
      'available': true,
      'status': 'free',
      'price': {'amount': 12.5, 'currency': 'USD'},
      'isPremium': false,
    });
    expect(available.name, 'votebanker.com');
    expect(available.available, isTrue);
    expect(available.priceAmount, 12.5);
    expect(available.priceCurrency, 'USD');

    final unavailable = DomainSuggestion.fromJson({
      'domain': 'votebanker.in',
      'available': false,
      'status': 'in use',
      'price': null,
      'isPremium': false,
    });
    expect(unavailable.available, isFalse);
    expect(unavailable.priceAmount, isNull);

    final premium = DomainSuggestion.fromJson({
      'domain': 'vote.ai',
      'available': true,
      'status': 'free',
      'price': {'amount': 219.8, 'currency': 'EUR'},
      'isPremium': true,
    });
    expect(premium.isPremium, isTrue);

    final failed = DomainSuggestion.fromJson({
      'domain': 'votebanker.org',
      'available': false,
      'status': 'unknown',
      'error': 'missing_result',
    });
    expect(failed.checkFailed, isTrue);
  });

  test('DomainService posts to /api/domains/search and parses results', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/domains/search');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['name'], 'votebanker');
      expect(body['extensions'], defaultDomainExtensions);
      return http.Response(
        jsonEncode({
          'success': true,
          'results': [
            {
              'domain': 'votebanker.com',
              'available': true,
              'status': 'free',
              'price': {'amount': 12.5, 'currency': 'USD'},
              'isPremium': false,
            },
            {
              'domain': 'votebanker.in',
              'available': false,
              'status': 'in use',
              'price': null,
              'isPremium': false,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = DomainService(
      client: client,
      baseUrls: const ['http://domain.test'],
    );
    final results = await service.search('Vote Banker');
    expect(results.map((item) => item.name).toList(), [
      'votebanker.com',
      'votebanker.in',
    ]);
    expect(results.first.available, isTrue);
    expect(results.last.available, isFalse);
  });

  test('a slow local search is not replaced by the remote login error', () async {
    final client = MockClient((request) async {
      if (request.url.host == '127.0.0.1') {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      return http.Response(
        jsonEncode({
          'success': false,
          'error': 'openprovider_auth_failed',
          'serverIp': '152.55.178.69',
        }),
        502,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = DomainService(
      client: client,
      baseUrls: const ['http://127.0.0.1:5000', 'https://railway.test'],
      timeout: const Duration(milliseconds: 200),
    );

    expect(
      service.search('vaishnavi'),
      throwsA(
        isA<DomainException>().having(
          (error) => error.code,
          'code',
          'openprovider_timeout',
        ),
      ),
    );
  });

  testWidgets('domain search shows loading, success, and error states', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completer = Completer<http.Response>();
    var calls = 0;
    final client = MockClient((request) async {
      calls += 1;
      if (calls == 1) {
        return completer.future;
      }
      return http.Response(
        jsonEncode({'success': false, 'error': 'openprovider_check_failed'}),
        502,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = DomainService(
      client: client,
      baseUrls: const ['http://domain.test'],
    );
    final controller = OnboardingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        controller: controller,
        child: DomainSearchScreen(domainService: service),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Vote Banker');
    await tester.tap(find.text('Search'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      http.Response(
        jsonEncode({
          'success': true,
          'results': [
            {
              'domain': 'votebanker.online',
              'available': true,
              'status': 'free',
              'price': {'amount': 8, 'currency': 'USD'},
              'isPremium': false,
            },
            {
              'domain': 'votebanker.com',
              'available': true,
              'status': 'free',
              'price': {'amount': 12.5, 'currency': 'USD'},
              'isPremium': false,
            },
            {
              'domain': 'votebanker.in',
              'available': false,
              'status': 'in use',
              'price': null,
              'isPremium': false,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await tester.pumpAndSettle();

    // Only available domains are shown; standard TLDs come before extras.
    expect(find.text('votebanker.com'), findsOneWidget);
    expect(find.text('votebanker.online'), findsOneWidget);
    expect(find.text('votebanker.in'), findsNothing);
    expect(find.text('Unavailable'), findsNothing);
    expect(find.text('Available'), findsWidgets);
    expect(find.textContaining('12.50 USD'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('votebanker.com')).dy,
      lessThan(tester.getTopLeft(find.text('votebanker.online')).dy),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Domain search failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  test('INR prices under 1500 use the floor and other amounts stay exact', () {
    expect(customerFacingAmount(900.25, 'INR'), 1500);
    expect(customerFacingAmount(1500, 'INR'), 1500);
    expect(customerFacingAmount(15870.8, 'INR'), 15870.8);
    expect(customerFacingAmount(12.5, 'USD'), 12.5);
  });

  testWidgets('portfolio search shows the new button and the rupee floor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final extensions = (body['extensions'] as List).cast<String>();
      expect(extensions, contains('leader'));
      expect(extensions, contains('page'));
      expect(extensions, contains('neta'));
      return http.Response(
        jsonEncode({
          'success': true,
          'results': [
            {
              'domain': 'vaishnavi.xyz',
              'available': true,
              'status': 'free',
              'price': {'amount': 900.25, 'currency': 'INR'},
              'renewalPrice': {'amount': 400, 'currency': 'INR'},
            },
            {
              'domain': 'vaishnavi.ai',
              'available': true,
              'status': 'free',
              'price': {'amount': 15870.8, 'currency': 'INR'},
              'renewalPrice': {'amount': 7935.4, 'currency': 'INR'},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final controller = OnboardingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(
        controller: controller,
        child: DomainSearchScreen(
          domainService: DomainService(
            client: client,
            baseUrls: const ['http://domain.test'],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'vaishnavi');
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Select Portfolio Name'), findsWidgets);
    expect(find.textContaining('1500 INR'), findsWidgets);
    expect(find.textContaining('15870.80 INR'), findsOneWidget);
    expect(find.textContaining('7935.40 INR'), findsOneWidget);
    expect(find.textContaining('900'), findsNothing);
    expect(find.textContaining('rupees'), findsNothing);
  });
}

Widget _app({required Widget child, required OnboardingController controller}) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: controller,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
}
