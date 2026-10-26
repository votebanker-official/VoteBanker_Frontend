import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/onboarding/widgets/party_symbol.dart';
import 'package:votebanker/features/website/models/website_builder_draft.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('portfolio website uses the saved leader profile', (
    tester,
  ) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    controller.draft.photoBytes = _png;

    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(VoteBankerApp(controller: controller));
    await tester.pumpAndSettle();
    await _tap(tester, 'Skip for now');

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('profileLeaderName')),
        matching: find.byType(TextField),
      ),
      'Rahul Kumar',
    );
    controller.draft.assemblyConstituency = 'Hubballi';
    await tester.tap(find.byKey(const ValueKey('profileParty')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Indian National Congress').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profileDesignation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Constituency Leader').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('profileContact')),
        matching: find.byType(TextField),
      ),
      '9876543210',
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'Save & Continue');

    expect(find.textContaining('Portfolio Template'), findsOneWidget);
    expect(find.text('Rahul Kumar'), findsWidgets);
    expect(find.textContaining('Hubballi'), findsWidgets);
    expect(find.textContaining('Indian National Congress'), findsWidgets);
    expect(find.textContaining('Constituency Leader'), findsWidgets);
    expect(find.byKey(const ValueKey('preview-professional')), findsOneWidget);
    expect(find.byType(PartySymbol), findsWidgets);
    expect(find.text('Professional'), findsNothing);
    expect(find.text('Official'), findsNothing);
    expect(find.text('Community'), findsNothing);
    expect(find.text('Make it yours'), findsNothing);
    expect(find.text('Templates'), findsNothing);
    expect(find.text('My Website'), findsNothing);
    expect(find.text('About the Leader'), findsOneWidget);
    expect(find.text('Vision & Priorities'), findsWidgets);
    expect(find.text('Achievements & Development Work'), findsOneWidget);
    expect(find.text('Gallery & Community Updates'), findsOneWidget);
    expect(find.text('Know My Vision'), findsOneWidget);
    expect(find.text('Get in Touch'), findsOneWidget);
    expect(find.byKey(const ValueKey('aboutTheLeader')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('aboutTheLeader')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(find.textContaining('9876543210'), findsOneWidget);
    expect(controller.draft.websiteTemplate, WebsiteTemplates.professional);
    expect(find.byKey(const ValueKey('continueTemplate')), findsOneWidget);
    expect(find.byKey(const ValueKey('previewWebsite')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Leader Profile'), findsOneWidget);
    expect(controller.draft.leaderName, 'Rahul Kumar');
    expect(controller.draft.photoBytes, isNotNull);
    expect(controller.draft.party, 'Indian National Congress');

    await _tap(tester, 'Skip for now');
    await _tap(tester, 'Skip for now');
    expect(find.text('Social Media Setup'), findsOneWidget);
  });
}

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Future<void> _tap(WidgetTester tester, String text) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  final finder = find.text(text);
  await tester.ensureVisible(finder.last);
  await tester.pump();
  await tester.tap(finder.last);
  await tester.pumpAndSettle();
}
