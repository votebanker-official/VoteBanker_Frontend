import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/social_media/social_contact_links.dart';
import 'package:votebanker/features/social_media/social_media_screen.dart';
import 'package:votebanker/features/social_media/social_media_service.dart';
import 'package:votebanker/features/vrm/screens/vrm_records_screen.dart';
import 'package:votebanker/features/vrm/services/vrm_service.dart';

void main() {
  tearDown(() {
    AuthService.instance.session = null;
  });

  test('profile links open only for the matching host', () {
    expect(
      SocialContactLinks.profileUrl(
        'https://www.instagram.com/leader',
        SocialContactLinks.instagramHosts,
      ),
      isNotNull,
    );
    expect(
      SocialContactLinks.profileUrl(
        'https://evil.example/leader',
        SocialContactLinks.instagramHosts,
      ),
      isNull,
    );
    expect(SocialContactLinks.whatsAppUrl('leader'), isNull);
    expect(SocialContactLinks.whatsAppUrl('+91 98765 43210')?.host, 'wa.me');
    expect(SocialContactLinks.validProfile('shabanna', SocialContactLinks.instagramHosts), isTrue);
  });

  test('Social Media service asks the API as the signed-in user', () async {
    AuthService.instance.session = const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'user-a',
      phone: '+919999999999',
    );
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'success': true,
          'counts': {'whatsapp': 1, 'instagram': 0, 'facebook': 1},
          'whatsapp': [
            {
              'id': '1',
              'name': 'Shabanna Bijapur',
              'epicNumber': 'NNA4411195',
              'whatsappContact': '+919876543210',
            },
          ],
          'instagram': [
            {'id': '1', 'name': 'Shabanna Bijapur', 'instagramContact': ''},
          ],
          'facebook': [
            {
              'id': '2',
              'name': 'Akshay',
              'facebookContact': 'https://facebook.com/akshay',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = SocialMediaService(client: client, baseUrls: const ['http://social.test']);
    final contacts = await service.load(query: 'shabanna');
    expect(requests.single.headers['Authorization'], 'Bearer token');
    expect(requests.single.url.path, '/api/social-media/contacts');
    expect(requests.single.url.queryParameters['q'], 'shabanna');
    expect(requests.single.url.queryParameters.containsKey('ownerId'), isFalse);
    expect(contacts.whatsapp, hasLength(1));
    expect(contacts.instagram, isEmpty);
    expect(contacts.facebook.single.value, 'https://facebook.com/akshay');
  });

  testWidgets('Social Media shows saved contacts in the right sections', (tester) async {
    AuthService.instance.session = const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'user-a',
      phone: '',
    );
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'whatsapp': [
            {
              'id': '1',
              'name': 'Shabanna Bijapur',
              'epicNumber': 'NNA4411195',
              'whatsappContact': '+919876543210',
            },
          ],
          'instagram': [
            {'id': '1', 'name': 'Shabanna Bijapur', 'instagramContact': 'shabanna'},
          ],
          'facebook': const [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(_app(SocialMediaScreen(
      service: SocialMediaService(client: client, baseUrls: const ['http://social.test']),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Saved Voters'), findsOneWidget);
    expect(find.text('WhatsApp Contacts'), findsOneWidget);
    expect(find.text('Instagram Profiles'), findsOneWidget);
    expect(find.text('Facebook Profiles'), findsNothing);
    expect(find.text('1 WhatsApp'), findsOneWidget);
    expect(find.text('0 Facebook'), findsOneWidget);
    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.text('Open WhatsApp'), findsOneWidget);
    expect(find.text('Open Profile'), findsNothing);
    expect(find.text('shabanna'), findsOneWidget);
    expect(find.text('Copy'), findsNWidgets(2));
  });

  testWidgets('Social Media empty, error, and retry states', (tester) async {
    AuthService.instance.session = const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'user-a',
      phone: '',
    );
    var calls = 0;
    final client = MockClient((request) async {
      calls += 1;
      if (calls == 1) {
        return http.Response('nope', 500);
      }
      return http.Response(
        jsonEncode({
          'success': true,
          'whatsapp': const [],
          'instagram': const [],
          'facebook': const [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(_app(SocialMediaScreen(
      service: SocialMediaService(client: client, baseUrls: const ['http://social.test']),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Could not load social contacts. Please try again.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.textContaining('No social contact details have been saved yet'),
      findsOneWidget,
    );
  });

  testWidgets('VRM save rejects an invalid WhatsApp number before sending it', (tester) async {
    AuthService.instance.session = const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'user-a',
      phone: '',
    );
    final client = MockClient((request) async {
      if (request.method == 'PATCH') {
        fail('invalid contact must not be saved');
      }
      return http.Response(
        jsonEncode({
          'success': true,
          'records': [
            {
              'id': '1',
              'name': 'Shabanna Bijapur',
              'epicNumber': 'NNA4411195',
              'whatsappContact': '+919876543210',
              'instagramContact': 'shabanna',
              'facebookContact': 'shabanna.fb',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(_app(VrmRecordsScreen(
      service: VrmService(client: client, baseUrls: const ['http://vrm.test']),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField).at(1), 'not-a-number');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Check the contact details and try again.'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
  });
}

Widget _app(Widget home) {
  return ThemeScope(
    controller: ThemeController(),
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}
