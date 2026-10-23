import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
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
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byKey(const ValueKey('profileParty')),
        )
        .onChanged!('Indian National Congress');
    await tester.pump();
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byKey(const ValueKey('profileDesignation')),
        )
        .onChanged!('Constituency Leader');
    await tester.pump();
    await _tap(tester, 'Save & Continue');
    expect(find.text('Portfolio Name Search'), findsOneWidget);
    await _tap(tester, 'Skip for now');

    expect(find.textContaining('Choose Your Website Template'), findsOneWidget);
    expect(find.text('Rahul Kumar'), findsWidgets);
    expect(find.textContaining('Hubballi'), findsWidgets);
    expect(find.textContaining('Indian National Congress'), findsWidgets);
    expect(find.byKey(const ValueKey('preview-professional')), findsOneWidget);
    expect(find.text('Professional'), findsWidgets);
    expect(find.byIcon(Icons.check_circle), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('template-official')));
    await tester.tap(find.byKey(const ValueKey('template-official')));
    await tester.pump();
    // Selecting uses the Select Template button inside the card.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('template-official')),
        matching: find.text('Select Template'),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('preview-official')), findsOneWidget);
    expect(find.text('Serving with Responsibility'), findsOneWidget);
    expect(controller.draft.websiteTemplate, WebsiteTemplates.official);

    await tester.ensureVisible(
      find.byKey(const ValueKey('template-community')),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('template-community')),
        matching: find.text('Select Template'),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('preview-community')), findsOneWidget);
    expect(find.text('Growing Together'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('template-professional')),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('template-professional')),
        matching: find.text('Select Template'),
      ),
    );
    await tester.pump();
    expect(find.text('Building a Better Tomorrow'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('My Website'),
      find.byType(Scrollable).first,
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Website'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('editWebsite')), findsOneWidget);

    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Make it yours'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Portfolio Name Search'), findsOneWidget);
    await _tap(tester, 'Back');
    expect(find.text('Leader Profile'), findsOneWidget);
    expect(controller.draft.leaderName, 'Rahul Kumar');
    expect(controller.draft.photoBytes, isNotNull);

    await _tap(tester, 'Save & Continue');
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
