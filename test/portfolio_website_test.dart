import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

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

    tester.view.physicalSize = const Size(390, 900);
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
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('profileAssembly')),
        matching: find.byType(TextField),
      ),
      'Hubballi',
    );
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

    expect(find.text('Portfolio Website'), findsOneWidget);
    expect(find.text('Rahul Kumar'), findsWidgets);
    expect(find.textContaining('Hubballi'), findsWidgets);
    expect(find.textContaining('Indian National Congress'), findsWidgets);
    expect(find.byKey(const ValueKey('preview-modern')), findsOneWidget);
    expect(find.text('Modern'), findsWidgets);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('template-traditional')));
    await tester.pump();
    expect(find.byKey(const ValueKey('preview-traditional')), findsOneWidget);
    expect(find.text('Rooted in Service'), findsOneWidget);
    expect(controller.draft.websiteTemplate, 'traditional');

    await tester.tap(find.byKey(const ValueKey('template-peopleFirst')));
    await tester.pump();
    expect(find.byKey(const ValueKey('preview-peopleFirst')), findsOneWidget);
    expect(find.text('A constituency that listens'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('template-modern')));
    await tester.pump();
    expect(find.text('A Stronger Constituency'), findsOneWidget);

    await tester.tap(find.text('My Website'));
    await tester.pumpAndSettle();
    expect(find.text('Rahul Kumar'), findsWidgets);
    expect(find.text('Constituency Leader'), findsWidgets);
    expect(
      find.text(
        'Your website is ready to customize with the selected template.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
    expect(find.text('Make it yours'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Leader Profile'), findsOneWidget);
    expect(controller.draft.leaderName, 'Rahul Kumar');
    expect(controller.draft.photoBytes, isNotNull);

    await _tap(tester, 'Save & Continue');
    await _tap(tester, 'Skip for now');
    expect(find.text('Meta Social Media'), findsOneWidget);
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
