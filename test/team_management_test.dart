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
    expect(find.text('Email Address'), findsNothing);
    expect(find.text('Mobile Number'), findsNothing);
    expect(find.text('WhatsApp Number'), findsOneWidget);
    expect(find.text('Enter WhatsApp Number'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    final label = tester.getRect(find.text('Full Name'));
    final field = tester.getRect(find.byKey(const Key('team-name')));
    expect(label.bottom, lessThanOrEqualTo(field.top));
    final facebookBox = tester.getRect(find.byKey(const Key('team-facebook')));
    final instagramBox = tester.getRect(find.byKey(const Key('team-instagram')));
    expect(facebookBox.overlaps(instagramBox), isFalse);
    expect(instagramBox.left, greaterThan(facebookBox.right - 1));
    expect((instagramBox.top - facebookBox.top).abs(), lessThan(8));
    await tester.enterText(find.byKey(const Key('team-name')), 'Meera Nair');
    await tester.enterText(find.byKey(const Key('team-whatsapp')), '9876543210');
    await tester.enterText(find.byKey(const Key('team-facebook')), 'https://facebook.com/meera');
    await tester.enterText(find.byKey(const Key('team-instagram')), 'https://instagram.com/meera');
    await tester.enterText(find.byKey(const Key('team-designation')), 'Booth lead');
    await tester.enterText(find.byKey(const Key('team-location')), 'Kochi');
    await tester.tap(find.byKey(const Key('team-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordinator').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View dashboard'));
    await tester.tap(find.text('View dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team-send')));
    await tester.pumpAndSettle();

    expect(find.text('Team member added.'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    final whatsappHeader = tester.getRect(find.text('WhatsApp'));
    final facebookHeader = tester.getRect(find.text('Facebook'));
    final instagramHeader = tester.getRect(find.text('Instagram'));
    expect(whatsappHeader.overlaps(facebookHeader), isFalse);
    expect(facebookHeader.overlaps(instagramHeader), isFalse);
    expect(facebookHeader.left, greaterThan(whatsappHeader.right - 1));
    expect(instagramHeader.left, greaterThan(facebookHeader.right - 1));
    final facebookLink = tester.widget<Text>(find.text('https://facebook.com/meera'));
    final instagramLink = tester.widget<Text>(find.text('https://instagram.com/meera'));
    expect(facebookLink.maxLines, 1);
    expect(facebookLink.overflow, TextOverflow.ellipsis);
    expect(instagramLink.maxLines, 1);
    expect(instagramLink.overflow, TextOverflow.ellipsis);
    expect(find.byTooltip('https://facebook.com/meera'), findsOneWidget);
    expect(find.byTooltip('https://instagram.com/meera'), findsOneWidget);
    expect(repository.members.single.whatsappNumber, '9876543210');
    expect(repository.members.single.facebookUrl, 'https://facebook.com/meera');
    expect(repository.members.single.instagramUrl, 'https://instagram.com/meera');
    expect(repository.members.single.email, isEmpty);
    expect(repository.members.single.permissions, contains('View dashboard'));
    expect(repository.members.single.role, 'Coordinator');
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

  testWidgets('social profile fields stack on a narrow screen without overlapping', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(TeamManagementScreen(repository: _MemoryTeamRepository())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-team-member')));
    await tester.pumpAndSettle();

    expect(find.text('Email Address'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('team-instagram')));
    await tester.pumpAndSettle();

    final name = tester.getRect(find.byKey(const Key('team-name')));
    final whatsapp = tester.getRect(find.byKey(const Key('team-whatsapp')));
    final facebook = tester.getRect(find.byKey(const Key('team-facebook')));
    final instagram = tester.getRect(find.byKey(const Key('team-instagram')));
    expect(name.overlaps(whatsapp), isFalse);
    expect(whatsapp.top, greaterThanOrEqualTo(name.bottom - 1));
    expect(facebook.overlaps(instagram), isFalse);
    expect(instagram.top, greaterThanOrEqualTo(facebook.bottom - 1));
    expect((facebook.left - instagram.left).abs(), lessThan(2));
  });

  testWidgets('add team member dialog uses the dark reference colors', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(TeamManagementScreen(repository: _MemoryTeamRepository())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-team-member')));
    await tester.pumpAndSettle();

    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, const Color(0xFF101E32));
    final field = tester.widget<TextField>(find.byKey(const Key('team-whatsapp')));
    expect(field.decoration?.fillColor, const Color(0xFF0E1C30));
    expect(find.text('Email Address'), findsNothing);
    expect(find.text('Send Invitation'), findsOneWidget);
    expect(find.text('View dashboard'), findsOneWidget);
    expect(find.text('Full access'), findsOneWidget);
  });

  testWidgets('missing social urls show a dash and stored email stays out of the table', (tester) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(TeamManagementScreen(
      repository: _MemoryTeamRepository(),
      initialMembers: const [
        TeamMember(
          id: 'm1',
          fullName: 'ashwini',
          mobile: '8085758575',
          email: 'ashwini@example.com',
          designation: 'a',
          location: 'hubli',
          role: 'Member',
          permissions: [],
          status: 'pending',
          facebookUrl: 'https://facebook.com/ashwini',
          instagramUrl: '',
        ),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsNothing);
    expect(find.text('ashwini@example.com'), findsNothing);
    expect(find.text('https://facebook.com/ashwini'), findsOneWidget);
    expect(find.text('—'), findsNothing);
    expect(find.text('-'), findsNothing);
    expect(find.text('N/A'), findsNothing);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Designation'), findsOneWidget);

    await tester.tap(find.byTooltip('View'));
    await tester.pumpAndSettle();
    expect(find.text('ashwini@example.com'), findsNothing);
    expect(find.text('https://facebook.com/ashwini'), findsWidgets);
    expect(find.text('Instagram'), findsWidgets);
    expect(find.text('N/A'), findsNothing);
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
      mobile: '${payload['whatsappNumber'] ?? payload['mobile'] ?? ''}',
      email: '${payload['email'] ?? ''}',
      facebookUrl: '${payload['facebookUrl'] ?? ''}',
      instagramUrl: '${payload['instagramUrl'] ?? ''}',
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
