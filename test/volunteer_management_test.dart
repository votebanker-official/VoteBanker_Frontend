import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:votebanker/features/volunteers/models/volunteer_models.dart';
import 'package:votebanker/features/volunteers/screens/volunteer_management_screen.dart';
import 'package:votebanker/features/volunteers/services/volunteer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('volunteers dashboard filters injected records and does not brand BrightPath', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: VolunteerManagementScreen(initialVolunteers: _directory())),
    );
    await tester.pump();

    expect(find.text('BrightPath Volunteers'), findsNothing);
    expect(find.text('Jamie Carter'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Maya Bennett'), findsOneWidget);
    expect(find.text('Hammersmith'), findsOneWidget);
    expect(find.text('Event Support'), findsWidgets);
    expect(find.text('Regular'), findsWidgets);
    expect(find.text('Onboarding'), findsWidgets);
    expect(find.text('Showing 1–5 of 5 volunteers'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byKey(const Key('volunteer-search')), 'Ethan');
    await tester.pump();
    expect(find.text('Ethan Cole'), findsOneWidget);
    expect(find.text('Maya Bennett'), findsNothing);
    expect(find.text('Showing 1–1 of 1 volunteers'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('volunteer-search')), '');
    await tester.pump();
    await tester.tap(find.text('All Statuses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onboarding').last);
    await tester.pumpAndSettle();
    expect(find.text('Ethan Cole'), findsOneWidget);
    expect(find.text('Noah Ellis'), findsOneWidget);
    expect(find.text('Maya Bennett'), findsNothing);
    expect(find.text('Showing 1–2 of 2 volunteers'), findsOneWidget);

    await tester.tap(find.byTooltip('View').first);
    await tester.pumpAndSettle();
    expect(find.text('ethan.cole@example.com'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('add volunteer form validates and inserts a row', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: VolunteerManagementScreen(initialVolunteers: [])),
    );
    await tester.pump();

    expect(find.text('No volunteers found'), findsOneWidget);
    await tester.tap(find.text('Add Volunteer').first);
    await tester.pumpAndSettle();
    final emailField = find.widgetWithText(TextFormField, 'Enter email address');
    expect(emailField, findsOneWidget);
    expect(tester.getSize(emailField).height, greaterThan(40));
    expect(tester.getSize(emailField).width, greaterThan(200));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    expect(find.text('Name is required.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Enter full name'), 'Amira Khan');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter location'), 'Ealing');
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter phone number'), '9876543210');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Amira Khan'), findsOneWidget);
    expect(find.text('Ealing'), findsOneWidget);
    expect(find.text('Showing 1–1 of 1 volunteers'), findsOneWidget);
    expect(find.text('Volunteer added.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone layout has a back arrow and no dummy volunteers', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: VolunteerManagementScreen()));
    await tester.pumpAndSettle();

    expect(find.text('BrightPath Volunteers'), findsNothing);
    expect(find.text('Maya Bennett'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('No volunteers found'), findsOneWidget);
    expect(find.text('Showing 0 of 0 volunteers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remove volunteer sends DELETE and drops the row', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = _RecordingClient();
    await tester.pumpWidget(
      MaterialApp(
        home: VolunteerManagementScreen(
          service: VolunteerService(client: client, baseUrls: const ['http://127.0.0.1:9']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Real Person'), findsOneWidget);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove volunteer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to permanently remove this volunteer?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Remove Volunteer'));
    await tester.pumpAndSettle();

    expect(client.calls.any((call) => call.startsWith('DELETE /api/volunteers/volunteers/v1')), isTrue);
    expect(find.text('Real Person'), findsNothing);
    expect(find.text('No volunteers found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

List<VolunteerRecord> _directory() {
  VolunteerRecord row({
    required String id,
    required String name,
    required String location,
    required String status,
    required String skills,
    String? availability,
    String? email,
  }) {
    return VolunteerRecord(
      id: id,
      volunteerCode: id,
      fullName: name,
      mobile: '9876543210',
      email: email,
      role: 'General Volunteer',
      location: location,
      skills: skills,
      availability: availability,
      status: status,
    );
  }

  return [
    row(
      id: 'maya',
      name: 'Maya Bennett',
      location: 'Hammersmith',
      status: 'active',
      skills: 'Event Support, Fundraising, Social Media',
      availability: 'Regular',
      email: 'maya@example.com',
    ),
    row(
      id: 'ethan',
      name: 'Ethan Cole',
      location: 'Brixton',
      status: 'pending',
      skills: 'Marketing, Communications, Data Entry',
      email: 'ethan.cole@example.com',
    ),
    row(
      id: 'priya',
      name: 'Priya Shah',
      location: 'Wembley',
      status: 'active',
      skills: 'Event Support, Mentoring, First Aid',
      availability: 'Ad Hoc',
    ),
    row(
      id: 'noah',
      name: 'Noah Ellis',
      location: 'Camden',
      status: 'pending',
      skills: 'Gardening, Facilities, Health & Safety',
      availability: 'Regular',
    ),
    row(
      id: 'sofia',
      name: 'Sofia Turner',
      location: 'Greenwich',
      status: 'active',
      skills: 'Counselling, Child Support, Safeguarding',
      availability: 'Regular',
    ),
  ];
}

class _RecordingClient extends http.BaseClient {
  final calls = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls.add('${request.method} ${request.url.path}');
    final listed = request.method == 'GET';
    final body = listed
        ? jsonEncode({
            'success': true,
            'volunteers': [
              {
                'id': 'v1',
                'volunteerCode': 'V-1',
                'fullName': 'Real Person',
                'mobile': '9876543210',
                'role': 'General Volunteer',
                'status': 'active',
                'location': 'Pune',
                'skills': 'Mentoring',
                'availability': 'Regular',
              },
            ],
            'page': 1,
            'pageSize': 1000,
            'total': 1,
            'locations': ['Pune'],
          })
        : jsonEncode({'success': true});
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
