import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/features/onboarding/data/political_party.dart';
import 'package:votebanker/features/onboarding/widgets/party_symbol.dart';
import 'package:votebanker/features/website/models/website_builder_draft.dart';
import 'package:votebanker/features/onboarding/models/onboarding_draft.dart';
import 'package:votebanker/features/website/services/leader_profile_binding.dart';
import 'package:votebanker/features/website/widgets/leader_portfolio_site.dart';
import 'package:votebanker/features/website/widgets/website_builder_preview.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget host(WebsiteBuilderDraft draft) {
    return MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
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
    expect(find.text('A public servant from Hubballi.'), findsNothing);
    expect(find.textContaining('Sample text for this preview'), findsOneWidget);
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
    expect(find.text('School renovation'), findsNothing);

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
    expect(find.text('A public servant from Hubballi.'), findsNothing);
    expect(find.text('School renovation'), findsNothing);
    expect(find.textContaining('Sabka Saath'), findsWidgets);
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

  test('saved profile photo and party replace the portfolio copy', () {
    final profile = OnboardingDraft()
      ..fullName = 'New Name'
      ..organization = 'Bharatiya Janata Party'
      ..designation = 'MLA'
      ..assemblyConstituency = 'Varanasi'
      ..stateRegion = 'Uttar Pradesh'
      ..photoBytes = Uint8List.fromList([1, 2, 3, 4])
      ..additionalProfile = {'about': 'Public service in Varanasi.'};
    final website = WebsiteBuilderDraft()
      ..fullName = 'Old Name'
      ..party = 'Indian National Congress'
      ..biography = 'Old biography'
      ..profilePhoto = MediaRef(base64: 'bbbb');

    applyLeaderProfile(website, profile);

    expect(website.fullName, 'New Name');
    expect(website.party, 'Bharatiya Janata Party');
    expect(website.designation, 'MLA');
    expect(website.constituency, 'Varanasi');
    expect(website.state, 'Uttar Pradesh');
    expect(website.biography, 'Public service in Varanasi.');
    expect(website.profilePhoto.bytes, profile.photoBytes);
    expect(PartyPalette.forParty(website.party).id, 'BJP');
    expect(PartyPalette.forParty('').id, 'default');
  });

  testWidgets('party sites use column, tablet, and desktop layouts', (tester) async {
    const sizes = [Size(390, 900), Size(800, 900), Size(1200, 900)];
    const layouts = ['hero-layout-column', 'hero-layout-row', 'hero-layout-row'];
    for (final party in PartyOption.national) {
      for (var i = 0; i < sizes.length; i++) {
        tester.view.physicalSize = sizes[i];
        tester.view.devicePixelRatio = 1;
        final draft = WebsiteBuilderDraft()
          ..fullName = 'Leader Name'
          ..designation = 'MLA'
          ..constituency = 'Shillong'
          ..state = 'Meghalaya'
          ..party = party.name
          ..biography = 'A public biography.';
        await tester.pumpWidget(host(draft));
        await tester.pump();
        expect(find.byKey(ValueKey('party-theme-${party.abbreviation}')), findsOneWidget);
        expect(find.byKey(ValueKey(layouts[i])), findsOneWidget);
        expect(find.text('About the Leader'), findsOneWidget);
        expect(find.text('Vision & Mission'), findsOneWidget);
        expect(find.text('Schemes and Initiatives'), findsOneWidget);
        expect(find.text('News & Updates'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('each national party theme is applied to the same layout', (
    tester,
  ) async {
    for (final party in PartyOption.national) {
      final draft = WebsiteBuilderDraft()
        ..fullName = 'Leader Name'
        ..party = party.name;
      await tester.pumpWidget(host(draft));
      expect(find.text(party.name), findsWidgets);
      expect(find.byKey(ValueKey('party-theme-${party.abbreviation}')), findsOneWidget);
      expect(find.byKey(const ValueKey('websiteHeroPhoto')), findsOneWidget);
    }
  });
}
