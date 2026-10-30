import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/team/models/team_member.dart';
import 'package:votebanker/features/team/screens/team_management_screen.dart';
import 'package:votebanker/features/team/services/team_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('team dashboard starts empty and updates counts from members', (tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryTeamRepository();
    await tester.pumpWidget(_app(TeamManagementScreen(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('My Team'), findsWidgets);
    expect(find.text('No Team Members Found'), findsOneWidget);
    expect(find.text('Total Members'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('team-stat-total'))).data, '0');
    expect(tester.widget<Text>(find.byKey(const Key('team-stat-pending'))).data, '0');

    await tester.tap(find.byKey(const Key('add-team-member')));
    await tester.pumpAndSettle();
    final label = tester.getRect(find.text('Full Name'));
    final field = tester.getRect(find.byKey(const Key('team-name')));
    expect(label.bottom, lessThanOrEqualTo(field.top));
    await tester.enterText(find.byKey(const Key('team-name')), 'Meera Nair');
    await tester.enterText(find.byKey(const Key('team-mobile')), '9876543210');
    await tester.enterText(find.byKey(const Key('team-email')), 'meera@example.com');
    await tester.enterText(find.byKey(const Key('team-designation')), 'Booth lead');
    await tester.enterText(find.byKey(const Key('team-location')), 'Kochi');
    await tester.tap(find.byKey(const Key('team-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordinator').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team-send')));
    await tester.pumpAndSettle();

    expect(find.text('Team member added.'), findsOneWidget);
    expect(find.text('No Team Members Found'), findsNothing);
    expect(find.text('Meera Nair'), findsWidgets);
    expect(find.text('Pending'), findsWidgets);
    expect(tester.widget<Text>(find.byKey(const Key('team-stat-total'))).data, '1');
    expect(tester.widget<Text>(find.byKey(const Key('team-stat-pending'))).data, '1');
    expect(tester.widget<Text>(find.byKey(const Key('team-stat-active'))).data, '0');

    await tester.enterText(find.byKey(const Key('team-search')), 'missing');
    await tester.pump();
    expect(find.text('No matching team members'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('team-stat-total'))).data, '1');

    await tester.enterText(find.byKey(const Key('team-search')), 'kochi');
    await tester.pump();
    expect(find.text('Meera Nair'), findsWidgets);

    await tester.enterText(find.byKey(const Key('team-search')), '');
    await tester.pump();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team-send')));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('team-stat-active'))).data, '1');
    expect(tester.widget<Text>(find.byKey(const Key('team-stat-pending'))).data, '0');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No Team Members Found'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('team-stat-total'))).data, '0');
    expect(repository.members, isEmpty);
  });
}

Widget _app(Widget home) {
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
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    ),
  );
}

class _MemoryTeamRepository implements TeamRepository {
  final members = <TeamMember>[];
  var _next = 1;

  @override
  Future<List<TeamMember>> list() async => [...members];

  @override
  Future<TeamMember> create(Map<String, dynamic> payload) async {
    final member = _fromPayload('m${_next++}', payload, status: 'pending');
    members.insert(0, member);
    return member;
  }

  @override
  Future<TeamMember> update(String id, Map<String, dynamic> payload) async {
    final index = members.indexWhere((row) => row.id == id);
    final member = _fromPayload(id, payload, status: '${payload['status'] ?? 'pending'}');
    members[index] = member;
    return member;
  }

  @override
  Future<void> delete(String id) async {
    members.removeWhere((row) => row.id == id);
  }

  TeamMember _fromPayload(String id, Map<String, dynamic> payload, {required String status}) {
    return TeamMember(
      id: id,
      fullName: '${payload['fullName']}',
      mobile: '${payload['mobile']}',
      email: '${payload['email'] ?? ''}',
      designation: '${payload['designation'] ?? ''}',
      location: '${payload['location'] ?? ''}',
      role: '${payload['role']}',
      permissions: [
        for (final item in payload['permissions'] is List ? payload['permissions'] as List : const [])
          '$item',
      ],
      status: status,
    );
  }
}
