import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_routes.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/vrm/models/vrm_voter_record.dart';
import 'package:votebanker/features/vrm/screens/vrm_get_more_screen.dart';
import 'package:votebanker/features/vrm/screens/vrm_records_screen.dart';
import 'package:votebanker/features/vrm/services/vrm_service.dart';

void main() {
  testWidgets('Skip Now opens campaign templates from voter records', (
    tester,
  ) async {
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
          routes: {
            AppRoutes.campaignTemplates:
                (_) => const Scaffold(
                  body: Text('campaign-templates-destination'),
                ),
          },
          home: VrmRecordsScreen(
            service: VrmService(
              client: MockClient(
                (_) async => http.Response(
                  jsonEncode({'success': true, 'records': []}),
                  200,
                  headers: {'content-type': 'application/json'},
                ),
              ),
              baseUrls: const ['http://vrm.test'],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Skip Now'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vrm-records-skip')));
    await tester.pumpAndSettle();

    expect(find.text('campaign-templates-destination'), findsOneWidget);
  });

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

    final service = VrmService(
      client: client,
      baseUrls: const ['http://vrm.test'],
    );
    final rows = await service.listRecords();
    expect(rows, hasLength(1));
    expect(rows.first.epicNumber, 'NNA4411195');
  });

  test(
    'VrmService saveContacts requires auth and PATCHes only contacts',
    () async {
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

      final service = VrmService(
        client: client,
        baseUrls: const ['http://vrm.test'],
      );
      final updated = await service.saveContacts(
        recordId: 'rec-1',
        whatsappContact: '+918888888888',
        instagramContact: 'shabanna',
        facebookContact: '',
      );
      expect(updated.whatsappContact, '+918888888888');
      expect(updated.name, 'Shabanna Bijapur');
      AuthService.instance.session = null;
    },
  );

  test(
    'VrmService submits only a package code with the signed-in token',
    () async {
      AuthService.instance.session = const AuthSession(
        accessToken: 'token',
        refreshToken: 'refresh',
        userId: 'user-a',
        phone: '+919999999999',
      );
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/vrm/package-requests');
        expect(request.headers['Authorization'], 'Bearer token');
        expect(jsonDecode(request.body), {'packageCode': 'voters_1000'});
        return http.Response(
          jsonEncode({
            'success': true,
            'request': {'id': 'req-1', 'status': 'requested'},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final request = await VrmService(
        client: client,
        baseUrls: const ['http://vrm.test'],
      ).requestPackage('voters_1000');

      expect(request['status'], 'requested');
      AuthService.instance.session = null;
    },
  );

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
            service: VrmService(
              client: client,
              baseUrls: const ['http://vrm.test'],
            ),
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
    expect(find.text('View more voters'), findsOneWidget);
    // Core fields alone are not enough — missing social contacts = incomplete.
    expect(find.text('Incomplete details'), findsOneWidget);
    expect(find.text('Complete details'), findsNothing);
  });

  testWidgets(
    'voter card turns complete only after WhatsApp Instagram Facebook',
    (tester) async {
      AuthService.instance.session = null;

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'records': [
              {
                'id': '1',
                'name': 'Ahmed Raza',
                'age': 21,
                'gender': 'Male',
                'epicNumber': 'NNA5100110',
                'whatsappContact': '+919876543210',
                'instagramContact': 'ahmed.raza',
                'facebookContact': 'ahmed.fb',
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
              service: VrmService(
                client: client,
                baseUrls: const ['http://vrm.test'],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Complete details'), findsOneWidget);
      expect(find.text('Incomplete details'), findsNothing);
    },
  );

  testWidgets(
    'voter cards stack contacts on mobile and sit in a row on desktop',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      Future<void> pump(Size size) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
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
                service: VrmService(
                  client: MockClient((request) async {
                    return http.Response(
                      jsonEncode({
                        'success': true,
                        'records': [
                          {
                            'id': '1',
                            'name': 'Fatima',
                            'age': 38,
                            'gender': 'Female',
                            'epicNumber': 'NNA3849201',
                            'whatsappContact': '+919876543210',
                            'instagramContact': 'Fatima.leader',
                            'facebookContact': 'bibi',
                          },
                          {
                            'id': '2',
                            'name': 'Parimal Patil',
                            'age': 69,
                            'gender': 'Female',
                            'epicNumber': 'NNA4590444',
                            'needsReview': false,
                          },
                        ],
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  }),
                  baseUrls: const ['http://vrm.test'],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      }

      await pump(const Size(1100, 900));
      final desktopWhatsapp = tester.getTopLeft(find.text('WhatsApp').first);
      final desktopInstagram = tester.getTopLeft(find.text('Instagram').first);
      expect(desktopInstagram.dx, greaterThan(desktopWhatsapp.dx + 40));
      expect((desktopInstagram.dy - desktopWhatsapp.dy).abs(), lessThan(8));
      expect(tester.takeException(), isNull);

      await pump(const Size(375, 800));
      final viewport =
          MediaQuery.sizeOf(
            tester.element(find.byType(VrmRecordsScreen)),
          ).width;
      expect(viewport, 375);
      final mobileWhatsapp = tester.getTopLeft(find.text('WhatsApp').first);
      final mobileInstagram = tester.getTopLeft(find.text('Instagram').first);
      expect(mobileInstagram.dy, greaterThan(mobileWhatsapp.dy + 20));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('View more voters lists the three priced options', (
    tester,
  ) async {
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
          home: const VrmGetMoreScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Request 100 voters for ₹100'), findsOneWidget);
    expect(find.text('Request 1000 voters for ₹999'), findsOneWidget);
    expect(find.text('Request 10000 voters for ₹9999'), findsOneWidget);
    expect(find.textContaining('rupees'), findsNothing);

    final first = tester.getTopLeft(find.text('Request 100 voters for ₹100'));
    final second = tester.getTopLeft(find.text('Request 1000 voters for ₹999'));
    final third = tester.getTopLeft(
      find.text('Request 10000 voters for ₹9999'),
    );
    expect(first.dy, lessThan(second.dy));
    expect(second.dy, lessThan(third.dy));
  });

  testWidgets('View more voters fits desktop tablet and mobile widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [1440.0, 1024.0, 768.0, 430.0, 375.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        ThemeScope(
          controller: ThemeController(),
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: VrmGetMoreScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('View More Voters'), findsOneWidget);
      expect(
        find.text('Choose how many more voter records you want.'),
        findsOneWidget,
      );
      expect(find.text('Request 100 voters for ₹100'), findsOneWidget);
      expect(find.text('Request 1000 voters for ₹999'), findsOneWidget);
      expect(find.text('Request 10000 voters for ₹9999'), findsOneWidget);
      expect(find.text('VOTE BANKER'), findsOneWidget);
      expect(
        find.text('Home'),
        width >= VrmGetMoreScreen.wideBreakpoint
            ? findsOneWidget
            : findsNothing,
      );
      expect(
        find.text('Voter Records'),
        width >= VrmGetMoreScreen.wideBreakpoint
            ? findsOneWidget
            : findsNothing,
      );
      expect(tester.takeException(), isNull);

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('View more voters records a request and clarifies no payment', (
    tester,
  ) async {
    addTearDown(() => AuthService.instance.session = null);
    AuthService.instance.session = const AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      userId: 'user-a',
      phone: '+919999999999',
    );
    var packageCode = '';
    final service = VrmService(
      client: MockClient((request) async {
        packageCode =
            (jsonDecode(request.body) as Map<String, dynamic>)['packageCode']
                as String;
        return http.Response(
          jsonEncode({
            'success': true,
            'request': {'id': 'req-1', 'status': 'requested'},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrls: const ['http://vrm.test'],
    );
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
          home: VrmGetMoreScreen(service: service),
        ),
      ),
    );
    await tester.tap(find.text('Request 100 voters for ₹100'));
    await tester.pumpAndSettle();

    expect(packageCode, 'voters_100');
    expect(
      find.textContaining(
        'No payment was processed and voter records have not been delivered.',
      ),
      findsOneWidget,
    );
  });
}
