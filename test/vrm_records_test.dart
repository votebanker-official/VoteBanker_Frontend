import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/vrm/models/vrm_voter_record.dart';
import 'package:votebanker/features/vrm/screens/vrm_records_screen.dart';
import 'package:votebanker/features/vrm/services/vrm_service.dart';

void main() {
  test('VrmVoterRecord.fromJson maps voter and contact fields', () {
    final row = VrmVoterRecord.fromJson({
      'id': 'abc',
      'name': 'Akshay',
      'age': 30,
      'gender': 'Male',
      'epicNumber': 'NNA4656914',
      'whatsappContact': '+919999999999',
      'instagramContact': 'akshay',
      'facebookContact': 'akshay.fb',
      'needsReview': false,
    });
    expect(row.name, 'Akshay');
    expect(row.epicNumber, 'NNA4656914');
    expect(row.whatsappContact, '+919999999999');
    expect(row.instagramContact, 'akshay');
    expect(row.facebookContact, 'akshay.fb');
  });

  test('VrmService lists shared records without auth', () async {
    AuthService.instance.session = null;

    final client = MockClient((request) async {
      expect(request.url.path, '/api/vrm/records');
      expect(request.headers.containsKey('Authorization'), isFalse);
      return http.Response(
        jsonEncode({
          'success': true,
          'records': [
            {
              'id': '1',
              'name': 'Shabanna Bijapur',
              'age': 48,
              'gender': 'Female',
              'epicNumber': 'NNA4411195',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = VrmService(client: client, baseUrls: const ['http://vrm.test']);
    final rows = await service.listRecords();
    expect(rows, hasLength(1));
    expect(rows.first.epicNumber, 'NNA4411195');
  });

  test('VrmService saveContacts requires auth and PATCHes only contacts', () async {
    AuthService.instance.session = const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'user-a',
      phone: '+919999999999',
    );

    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/vrm/records/rec-1/contacts');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['whatsappContact'], '+918888888888');
      expect(body.containsKey('name'), isFalse);
      return http.Response(
        jsonEncode({
          'success': true,
          'record': {
            'id': 'rec-1',
            'name': 'Shabanna Bijapur',
            'age': 48,
            'gender': 'Female',
            'epicNumber': 'NNA4411195',
            'whatsappContact': '+918888888888',
            'instagramContact': 'shabanna',
            'facebookContact': '',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = VrmService(client: client, baseUrls: const ['http://vrm.test']);
    final updated = await service.saveContacts(
      recordId: 'rec-1',
      whatsappContact: '+918888888888',
      instagramContact: 'shabanna',
      facebookContact: '',
    );
    expect(updated.whatsappContact, '+918888888888');
    expect(updated.name, 'Shabanna Bijapur');
    AuthService.instance.session = null;
  });

  testWidgets('VRM screen shows contact fields and pay button', (tester) async {
    AuthService.instance.session = null;

    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'records': [
            {
              'id': '1',
              'name': 'Shabanna Bijapur',
              'age': 48,
              'gender': 'Female',
              'epicNumber': 'NNA4411195',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(
      ThemeScope(
        controller: ThemeController(),
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: VrmRecordsScreen(
            service: VrmService(client: client, baseUrls: const ['http://vrm.test']),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Shabanna Bijapur'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Pay to Get More Voters'), findsOneWidget);
  });
}
