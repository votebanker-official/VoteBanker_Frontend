import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/features/website/models/website_document.dart';
import 'package:votebanker/features/website/models/website_draft.dart';
import 'package:votebanker/features/website/services/website_content_planner.dart';
import 'package:votebanker/features/website/widgets/website_site_view.dart';

void main() {
  const example =
      'I have been working with people in my constituency for many years. '
      'My focus areas are education, healthcare, roads and employment. '
      'I want people to know about my work, upcoming events and vision. '
      'I also want people to be able to contact my office and submit public requests.';

  WebsiteDraft sample() {
    return WebsiteDraft()
      ..fullName = 'Arun Kumar'
      ..publicTitle = 'Public Representative'
      ..description = example
      ..style = 'public';
  }

  test('Arun Kumar description builds only the sections his words support', () {
    final page = planWebsite(sample());
    final types = page.sections.map((section) => section.type).toSet();
    final priorities = page.find(WebsiteSectionType.priorities);

    expect(page.personName, 'Arun Kumar');
    expect(page.professionalTitle, 'Public Representative');
    expect(page.introduction, contains('working with people'));
    expect(page.websiteType, 'leadership');
    expect(types, contains(WebsiteSectionType.hero));
    expect(types, contains(WebsiteSectionType.about));
    expect(types, contains(WebsiteSectionType.priorities));
    expect(types, contains(WebsiteSectionType.publicRequests));
    expect(types, contains(WebsiteSectionType.achievements));
    expect(types, contains(WebsiteSectionType.contact));
    expect(page.find(WebsiteSectionType.achievements)?.content.toLowerCase(), contains('work'));
    expect(page.find(WebsiteSectionType.contact)?.items, isEmpty);
    expect(page.find(WebsiteSectionType.contact)?.content.toLowerCase(), contains('contact'));
    expect(types, isNot(contains(WebsiteSectionType.vision)));
    expect(types, isNot(contains(WebsiteSectionType.events)));
    expect(
      priorities?.items.map((item) => item.title).toList(),
      ['Education', 'Healthcare', 'Roads', 'Employment'],
    );
  });

  test('achievements and contact appear only after the user supplies them', () {
    final draft = sample()
      ..achievements = 'Opened a study centre in 2019'
      ..phone = '0800000000';
    final page = planWebsite(draft);

    expect(page.has(WebsiteSectionType.achievements), isTrue);
    expect(page.find(WebsiteSectionType.achievements)?.content, 'Opened a study centre in 2019');
    expect(page.has(WebsiteSectionType.contact), isTrue);
    expect(page.find(WebsiteSectionType.contact)?.items.single.title, '0800000000');
  });

  test('a cat description does not create demo cards', () {
    final page = planWebsite(
      WebsiteDraft()
        ..description = 'website must be of describing cat smartness with lot of attractive hero card',
    );
    final copy = [
      page.introduction,
      for (final section in page.sections) ...[
        section.content,
        for (final item in section.items) '${item.title} ${item.description}',
      ],
    ].join(' ').toLowerCase();

    expect(copy, isNot(contains('quiet focus')));
    expect(copy, isNot(contains('fast learning')));
    expect(copy, isNot(contains('small puzzles')));
    expect(copy, isNot(contains('long memory')));
    expect(copy, isNot(contains('clear signals')));
    expect(copy, isNot(contains('measured jump')));
    expect(copy, contains('cat smartness'));
    expect(page.siteTitle.toLowerCase(), isNot('your name'));
    expect(page.websiteType, 'pet');
  });

  test('Luna description becomes a pet website', () {
    const description =
        'I want a beautiful website for my cat Luna. '
        'She loves playing, sleeping in sunny places, and chasing toys. '
        'Luna is curious, playful and very affectionate.';
    final page = planWebsite(WebsiteDraft()..description = description);
    final titles = page.sections.map((section) => section.heading).toList();
    final favorites = page.find(WebsiteSectionType.favoriteThings);

    expect(page.websiteType, 'pet');
    expect(page.siteTitle, 'Luna');
    expect(page.heroTitle, 'Meet Luna');
    expect(page.themeId, 'warm');
    expect(titles, contains('About Luna'));
    expect(titles, contains('Favorite things'));
    expect(titles, contains('Personality'));
    expect(titles, contains('Gallery'));
    expect(favorites?.items.map((item) => item.title).toList(), ['Playing', 'Sunny naps', 'Chasing toys']);
    expect(page.find(WebsiteSectionType.personality)?.items.map((item) => item.title).toList(), ['Curious', 'Playful', 'Affectionate']);
    expect(page.primaryCta, 'Meet Luna');
    expect(page.secondaryCta, 'View gallery');
    expect(page.introduction.toLowerCase(), isNot(contains('your name')));
  });

  test('Sweet Crumbs description becomes a bakery website', () {
    final page = planWebsite(
      WebsiteDraft()
        ..description = 'I run a bakery called Sweet Crumbs. We make custom birthday cakes, pastries and fresh bread.',
    );
    final headings = page.sections.map((section) => section.heading).join(' ').toLowerCase();

    expect(page.websiteType, 'business');
    expect(page.siteTitle, 'Sweet Crumbs');
    expect(page.themeId, 'warm');
    expect(headings, contains('menu'));
    expect(headings, contains('gallery'));
    expect(headings, contains('custom'));
    expect(page.find(WebsiteSectionType.menu)?.items.map((item) => item.title.toLowerCase()).toList(), contains('Pastries'.toLowerCase()));
    expect(page.websiteType, isNot('pet'));
    expect(page.websiteType, isNot('leadership'));
  });

  test('a photographer description becomes a portfolio website', () {
    final page = planWebsite(
      WebsiteDraft()..description = 'I am a photographer specializing in weddings and portraits.',
    );
    final titles = page.find(WebsiteSectionType.portfolio)?.items.map((item) => item.title).toList();

    expect(page.websiteType, 'photographer');
    expect(page.themeId, 'creative');
    expect(titles, ['Weddings', 'Portraits']);
    expect(page.has(WebsiteSectionType.gallery), isTrue);
    expect(page.has(WebsiteSectionType.priorities), isFalse);
    expect(page.has(WebsiteSectionType.publicRequests), isFalse);
  });

  test('a constituency description becomes a leadership website without invented facts', () {
    final page = planWebsite(
      WebsiteDraft()
        ..description =
            'I have worked for my constituency for ten years and focus on education, healthcare, roads and employment.',
    );
    final copy = [
      page.heroTitle,
      page.introduction,
      page.professionalTitle,
      for (final section in page.sections) ...[
        section.heading,
        section.content,
        for (final item in section.items) '${item.title} ${item.description}',
      ],
    ].join(' ').toLowerCase();

    expect(page.websiteType, 'leadership');
    expect(page.themeId, 'civic');
    expect(page.find(WebsiteSectionType.priorities)?.items.map((item) => item.title).toList(), [
      'Education',
      'Healthcare',
      'Roads',
      'Employment',
    ]);
    expect(copy, contains('ten years'));
    expect(copy, isNot(contains('award')));
    expect(copy, isNot(contains('your name')));
    expect(page.find(WebsiteSectionType.contact)?.items ?? const [], isEmpty);
  });

  test('a doctor description stays a clinic website', () {
    final page = planWebsite(
      WebsiteDraft()
        ..description = 'I am a pediatrician with a clinic in Hubballi. I provide child healthcare and vaccination services.',
    );

    expect(page.websiteType, 'healthcare');
    expect(page.organization, 'Hubballi');
    expect(page.has(WebsiteSectionType.services), isTrue);
    expect(page.has(WebsiteSectionType.publicRequests), isFalse);
    expect(page.has(WebsiteSectionType.priorities), isFalse);
  });

  test('regenerate keeps the same facts and changes only the layout', () {
    final draft = sample();
    final first = planWebsite(draft);
    draft.layoutVariant = 1;
    final second = planWebsite(draft);

    expect(second.personName, first.personName);
    expect(second.introduction, first.introduction);
    expect(second.layoutVariant, 1);
    expect(first.layoutVariant, 0);
  });

  testWidgets('a pet page lays out on a phone and a desktop', (tester) async {
    final page = planWebsite(
      WebsiteDraft()
        ..description =
            'I want a beautiful website for my cat Luna. '
            'She loves playing, sleeping in sunny places, and chasing toys. '
            'Luna is curious, playful and very affectionate.',
    );
    for (final width in [390.0, 1100.0]) {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ListView(children: [WebsiteSiteView(document: page)])),
        ),
      );
      await tester.pump();
      expect(find.text('Meet Luna'), findsWidgets);
      expect(find.text('Playing'), findsWidgets);
      expect(find.text('Sunny naps'), findsWidgets);
      expect(find.text('Curious'), findsOneWidget);
      expect(find.text('Your name'), findsNothing);
      expect(find.text('Made with VOTE BANKER Website Builder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('the generated page lays out on a phone and a desktop', (tester) async {
    final page = planWebsite(sample());
    for (final width in [390.0, 1100.0]) {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ListView(children: [WebsiteSiteView(document: page)])),
        ),
      );
      await tester.pump();
      expect(find.text('Arun Kumar'), findsWidgets);
      expect(find.text('Education'), findsOneWidget);
      expect(find.text('Quiet focus'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
