import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/features/onboarding/data/political_party.dart';
import 'package:votebanker/features/onboarding/widgets/party_symbol.dart';
import 'package:votebanker/features/website/models/website_builder_draft.dart';
import 'package:votebanker/features/website/widgets/website_builder_preview.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget host(WebsiteBuilderDraft draft) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: WebsiteBuilderPreview(draft: draft, isPreviewBanner: false),
      ),
    );
  }

  testWidgets('the preview uses the selected party logo and name', (
    tester,
  ) async {
    final draft = WebsiteBuilderDraft()
      ..fullName = 'Rahul Kumar'
      ..designation = 'Constituency Leader'
      ..constituency = 'Hubballi'
      ..party = 'Indian National Congress'
      ..biography = 'A public servant from Hubballi.'
      ..achievements.add(
        AchievementEntry(title: 'School renovation', description: 'Saved work'),
      );

    await tester.pumpWidget(host(draft));

    expect(find.text('Indian National Congress'), findsWidgets);
    expect(find.text('Rahul Kumar'), findsWidgets);
    expect(find.text('About the Leader'), findsOneWidget);
    expect(find.text('A public servant from Hubballi.'), findsOneWidget);
    expect(find.byKey(const ValueKey('aboutTheLeader')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('aboutTheLeader')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('aboutTheLeader')),
        matching: find.byType(CircleAvatar),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('websiteHeroPhoto')), findsOneWidget);
    expect(find.text('School renovation'), findsOneWidget);

    final congressLogos = tester.widgetList<PartySymbol>(find.byType(PartySymbol));
    expect(congressLogos, isNotEmpty);
    expect(
      congressLogos.every((logo) => logo.partyName == 'Indian National Congress'),
      isTrue,
    );
    expect(
      PartyOption.symbolFor('Indian National Congress'),
      'assets/images/parties/inc.svg',
    );

    draft.applyPartyFromProfile('Bharatiya Janata Party');
    await tester.pumpWidget(host(draft));

    expect(find.text('Bharatiya Janata Party'), findsWidgets);
    expect(find.text('Indian National Congress'), findsNothing);
    expect(find.text('A public servant from Hubballi.'), findsOneWidget);
    expect(find.text('School renovation'), findsOneWidget);
    expect(find.text('Rahul Kumar'), findsWidgets);
    final bjpLogos = tester.widgetList<PartySymbol>(find.byType(PartySymbol));
    expect(
      bjpLogos.every((logo) => logo.partyName == 'Bharatiya Janata Party'),
      isTrue,
    );
    expect(
      PartyOption.symbolFor('Bharatiya Janata Party'),
      'assets/images/parties/bjp.svg',
    );
  });

  test('an unknown party uses the fallback logo asset', () {
    expect(PartyOption.findByName('Independent Workers Union'), isNull);
    expect(
      PartyOption.symbolFor('Independent Workers Union'),
      PartyOption.fallbackAsset,
    );
  });

  testWidgets('a missing party still shows a named placeholder logo', (
    tester,
  ) async {
    final draft = WebsiteBuilderDraft()
      ..fullName = 'Rahul Kumar'
      ..party = 'Independent Workers Union';

    await tester.pumpWidget(host(draft));
    expect(find.text('Independent Workers Union'), findsWidgets);
    final logos = tester.widgetList<PartySymbol>(find.byType(PartySymbol));
    expect(logos, isNotEmpty);
    expect(
      logos.every((logo) => logo.partyName == 'Independent Workers Union'),
      isTrue,
    );
  });

  test('changing party leaves biography and achievements on the draft', () {
    final draft = WebsiteBuilderDraft()
      ..party = 'Indian National Congress'
      ..biography = 'Keep this biography'
      ..phone = '9876543210'
      ..achievements.add(AchievementEntry(title: 'Keep this achievement'));

    draft.applyPartyFromProfile('Aam Aadmi Party');

    expect(draft.party, 'Aam Aadmi Party');
    expect(draft.biography, 'Keep this biography');
    expect(draft.phone, '9876543210');
    expect(draft.achievements.single.title, 'Keep this achievement');
  });
}
