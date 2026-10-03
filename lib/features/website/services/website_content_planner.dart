import 'dart:typed_data';

import '../models/website_document.dart';
import '../models/website_draft.dart';

/// Reads the description and picks a website type. It does not call a model.
class WebsiteTypeDetector {
  const WebsiteTypeDetector();

  String detect(String story, WebsiteDraft draft) => detectWebsiteType(story, draft);
}

/// Chooses colors, type scale, radius, and hero layout from the type and style.
class WebsiteThemeEngine {
  const WebsiteThemeEngine();

  String choose({required String style, required String type}) => chooseTheme(style, type);

  String heroLayout({required String type, required int variant}) => _heroLayout(type, variant);
}

/// Decides which sections belong on the page.
class WebsiteSectionPlanner {
  const WebsiteSectionPlanner();

  WebsiteDocument plan(WebsiteDraft draft) => planWebsite(draft);
}

/// Turns the description into structured page copy.
class WebsiteContentGenerator {
  const WebsiteContentGenerator();

  WebsiteDocument generate(WebsiteDraft draft) => const WebsiteSectionPlanner().plan(draft);
}

/// Local stand-in for POST /api/website/generate.
/// It arranges the user's own words. It does not call a model.
WebsiteDocument planWebsite(WebsiteDraft draft) {
  final story = _story(draft);
  final type = const WebsiteTypeDetector().detect(story, draft);
  final subject = _subject(story, draft, type);
  final loves = type == 'pet' ? _afterVerb(story, RegExp(r'\bloves?\s+([^.]+)', caseSensitive: false)) : <String>[];
  final traits = type == 'pet' ? _traits(story) : <String>[];
  final made = _afterVerb(story, RegExp(r'\b(?:we make|we offer|specializing in|provides?|providing)\s+([^.]+)', caseSensitive: false));
  final focuses = type == 'leadership' ? focusTopics(story) : <String>[];
  final sentences = _sentences(story);
  final aboutField = draft.about.trim();
  final aboutBody = aboutField.isNotEmpty ? aboutField : _aboutBody(type, sentences);
  final heroLine = _heroLine(type, subject, loves, made, sentences);
  final theme = const WebsiteThemeEngine().choose(style: draft.style, type: type);
  final heroLayout = const WebsiteThemeEngine().heroLayout(type: type, variant: draft.layoutVariant);

  final sections = <WebsiteSection>[];
  var order = 0;
  void add(WebsiteSection section) {
    sections.add(section);
    order += 1;
  }

  add(
    WebsiteSection(
      id: 'hero',
      type: WebsiteSectionType.hero,
      titleKey: 'secHome',
      heading: 'Home',
      order: order,
      content: heroLine,
    ),
  );

  if (aboutBody.isNotEmpty) {
    add(
      WebsiteSection(
        id: 'about',
        type: WebsiteSectionType.about,
        titleKey: 'secAbout',
        heading: subject.name.isEmpty ? 'About' : 'About ${subject.name}',
        order: order,
        content: aboutBody,
      ),
    );
  }

  if (draft.vision.trim().isNotEmpty) {
    add(_prose('vision', WebsiteSectionType.vision, 'secVision', 'Vision', draft.vision.trim(), order));
  }
  if (draft.mission.trim().isNotEmpty) {
    add(_prose('mission', WebsiteSectionType.mission, 'secMission', 'Mission', draft.mission.trim(), order));
  }

  if (loves.isNotEmpty) {
    add(
      WebsiteSection(
        id: 'favorites',
        type: WebsiteSectionType.favoriteThings,
        titleKey: 'secAbout',
        heading: 'Favorite things',
        order: order,
        items: [
          for (final label in loves)
            WebsiteItem(title: _petCardTitle(label), description: label.trim()),
        ],
      ),
    );
  }
  if (traits.isNotEmpty) {
    add(_cards('personality', WebsiteSectionType.personality, 'Personality', traits, order));
  }
  if (focuses.isNotEmpty) {
    add(
      WebsiteSection(
        id: 'priorities',
        type: WebsiteSectionType.priorities,
        titleKey: 'prioritiesTitle',
        heading: 'Key priorities',
        order: order,
        content: _sentenceContaining(story, RegExp(r'focus|priorit', caseSensitive: false)),
        items: [for (final topic in focuses) WebsiteItem(title: topic)],
      ),
    );
  }
  if (made.isNotEmpty && type == 'business') {
    final cakes = made.where((item) => item.toLowerCase().contains('cake')).toList();
    add(_cards('menu', WebsiteSectionType.menu, 'Our menu', made, order));
    if (cakes.isNotEmpty && made.length > cakes.length) {
      add(_cards('cakes', WebsiteSectionType.services, 'Cakes', cakes, order));
    }
    if (story.toLowerCase().contains('custom')) {
      add(
        _prose(
          'orders',
          WebsiteSectionType.services,
          'secWork',
          'Custom orders',
          _sentenceContaining(story, RegExp(r'custom', caseSensitive: false)),
          order,
        ),
      );
    }
  }
  if (type == 'photographer') {
    final shots = made.isEmpty ? _photoSubjects(story) : made;
    if (shots.isNotEmpty) {
      add(_cards('portfolio', WebsiteSectionType.portfolio, 'Portfolio', shots, order));
    }
  }
  if (type == 'healthcare') {
    final services = made.isEmpty ? _careSubjects(story) : made;
    if (services.isNotEmpty) {
      add(_cards('services', WebsiteSectionType.services, 'Services', services, order));
    }
    final place = _place(story);
    if (place.isNotEmpty) {
      add(_prose('clinic', WebsiteSectionType.contact, 'secContact', 'Clinic', place, order));
    }
    add(_prose('appointments', WebsiteSectionType.appointments, 'secContact', 'Appointments', _sentenceContaining(story, RegExp(r'clinic|care|vaccin', caseSensitive: false)), order));
  }

  final workLines = _chunks(draft.achievements);
  if (workLines.isNotEmpty) {
    add(
      WebsiteSection(
        id: 'work',
        type: WebsiteSectionType.achievements,
        titleKey: 'workTitle',
        heading: 'My work',
        order: order,
        content: workLines.length == 1 ? workLines.first : '',
        items: workLines.length == 1 ? const [] : [for (final line in workLines) WebsiteItem(title: line)],
      ),
    );
  } else if (type == 'leadership' && RegExp(r'\bwork\b', caseSensitive: false).hasMatch(story)) {
    final line = _sentenceContaining(story, RegExp(r'\bwork\b', caseSensitive: false));
    if (line.isNotEmpty) {
      add(_prose('work', WebsiteSectionType.achievements, 'workTitle', 'My work', line, order));
    }
  }

  final events = _events(draft.eventsNote);
  if (events.isNotEmpty) {
    add(
      WebsiteSection(
        id: 'events',
        type: WebsiteSectionType.events,
        titleKey: 'secEvents',
        heading: 'Events',
        order: order,
        items: events,
      ),
    );
  }

  final wantsRequests = draft.sections.contains('requests') || RegExp(r'\brequests?\b', caseSensitive: false).hasMatch(story);
  if (wantsRequests && type == 'leadership') {
    add(
      WebsiteSection(
        id: 'requests',
        type: WebsiteSectionType.publicRequests,
        titleKey: 'secRequests',
        heading: 'Public requests',
        order: order,
        content: _sentenceContaining(story, RegExp(r'request', caseSensitive: false)),
      ),
    );
  }

  final showGallery = draft.photos.isNotEmpty || type == 'pet' || type == 'photographer' || type == 'business' || type == 'artist';
  final galleryItems = loves.isNotEmpty
      ? loves
      : made.isNotEmpty
      ? made
      : focuses;
  if (showGallery) {
    add(
      WebsiteSection(
        id: 'gallery',
        type: WebsiteSectionType.gallery,
        titleKey: 'secGallery',
        heading: 'Gallery',
        order: order,
        items: [for (final label in galleryItems.take(6)) WebsiteItem(title: label)],
      ),
    );
  }

  final contactItems = _contactItems(draft);
  final contactLine = _sentenceContaining(story, RegExp(r'contact|office|clinic', caseSensitive: false));
  final alreadyClinic = sections.any((section) => section.id == 'clinic');
  if (contactItems.isNotEmpty || (contactLine.isNotEmpty && !alreadyClinic && type != 'healthcare')) {
    add(
      WebsiteSection(
        id: 'contact',
        type: WebsiteSectionType.contact,
        titleKey: 'secContact',
        heading: 'Contact',
        order: order,
        content: contactItems.isEmpty ? contactLine : '',
        items: contactItems,
      ),
    );
  }

  final social = _socialItems(draft.socialLinks);
  if (social.isNotEmpty) {
    add(
      WebsiteSection(
        id: 'social',
        type: WebsiteSectionType.social,
        titleKey: 'secSocial',
        heading: 'Social',
        order: order,
        items: social,
      ),
    );
  }

  final ctas = _ctas(type, subject.name.isEmpty ? subject.fallback : subject.name, sections);
  final portrait = draft.logo ?? (draft.photos.isEmpty ? null : draft.photos.first);
  final gallery = draft.logo == null && draft.photos.length > 1
      ? draft.photos.skip(1).toList()
      : (draft.logo != null ? List<Uint8List>.from(draft.photos) : <Uint8List>[]);

  return WebsiteDocument(
    siteTitle: subject.name.isEmpty ? subject.fallback : subject.name,
    personName: draft.fullName.trim().isNotEmpty ? draft.fullName.trim() : (type == 'pet' || type == 'leadership' || type == 'healthcare' || type == 'personal' ? subject.name : ''),
    professionalTitle: draft.publicTitle.trim(),
    organization: draft.organization.trim().isNotEmpty ? draft.organization.trim() : (type == 'healthcare' ? _place(story) : ''),
    tagline: draft.callToAction.trim(),
    introduction: sentences.isNotEmpty ? sentences.first : heroLine,
    heroTitle: _heroTitle(type, subject),
    websiteType: type,
    heroLayout: heroLayout,
    primaryCta: ctas.$1,
    secondaryCta: ctas.$2,
    themeId: theme,
    layoutVariant: draft.layoutVariant % 3,
    languageCode: draft.websiteLanguage,
    translationPending: false,
    navigation: [for (final section in sections) section.heading],
    sections: sections,
    portrait: portrait,
    logo: draft.logo,
    gallery: gallery,
  );
}

String detectWebsiteType(String story, WebsiteDraft draft) {
  final text = story.toLowerCase();
  bool has(String pattern) => RegExp(pattern, caseSensitive: false).hasMatch(text);

  if (has(r'\b(photographer|photography|portraits?)\b')) {
    return 'photographer';
  }
  if (has(r'\b(pediatrician|doctor|dentist|physician|clinic|vaccination|hospital)\b')) {
    return 'healthcare';
  }
  if (has(r'\b(cat|cats|kitten|kittens|dog|dogs|puppy|pet|pets)\b')) {
    return 'pet';
  }
  if (has(r'\b(constituency|voters|mla|minister|election|public requests?)\b') || draft.sections.contains('requests')) {
    return 'leadership';
  }
  if (has(r'\b(bakery|cakes?|pastries|pastry|restaurant|cafe|café|shop|boutique)\b') || has(r'\b(i run|we make|we bake)\b')) {
    return 'business';
  }
  if (has(r'\b(artist|painter|illustrator)\b')) {
    return 'artist';
  }
  if (has(r'\b(ngo|charity|foundation)\b')) {
    return 'organization';
  }
  if (draft.fullName.trim().isNotEmpty) {
    return 'personal';
  }
  return 'other';
}

String chooseTheme(String style, String type) {
  return switch (style) {
    'executive' || 'elegant' => 'elegant',
    'modern' || 'modernCivic' => 'modern',
    'minimal' => 'minimal',
    'bold' => 'bold',
    'warm' || 'community' || 'issue' => 'warm',
    'editorial' => 'editorial',
    'creative' => 'creative',
    'civic' || 'publicLeadership' || 'work' => 'civic',
    _ => switch (type) {
      'pet' || 'business' => 'warm',
      'healthcare' => 'elegant',
      'photographer' || 'artist' => 'creative',
      'leadership' => 'civic',
      'personal' => 'editorial',
      _ => 'modern',
    },
  };
}

/// Topics the user named. Nothing is added that they did not write.
List<String> focusTopics(String text) {
  final found = <String>[];
  void add(String raw) {
    final label = _label(raw);
    if (label.isEmpty || found.any((item) => item.toLowerCase() == label.toLowerCase())) {
      return;
    }
    found.add(label);
  }

  final listed = RegExp(
    r'(?:focus(?:\s+areas)?|main focus|priorities)\s+(?:are|is|on)\s+([^.\n]+)',
    caseSensitive: false,
  ).firstMatch(text);
  if (listed != null) {
    for (final part in _splitList(listed.group(1)!)) {
      add(part);
    }
  }
  for (final topic in _topics) {
    if (RegExp('\\b$topic\\b', caseSensitive: false).hasMatch(text)) {
      add(topic);
    }
  }
  return found;
}

class _Subject {
  const _Subject(this.name, this.fallback, this.kindWord);
  final String name;
  final String fallback;
  final String kindWord;
}

_Subject _subject(String story, WebsiteDraft draft, String type) {
  final given = draft.fullName.trim();
  if (given.isNotEmpty && type != 'business') {
    return _Subject(given, given, type);
  }
  final called = RegExp(
    r'(?:called|named)\s+([A-Z][A-Za-z]*(?:\s+[A-Z][A-Za-z]*){0,3})',
  ).firstMatch(story);
  if (called != null) {
    return _Subject(called.group(1)!.trim(), called.group(1)!.trim(), type);
  }
  final petName = RegExp(r'\b(?:cat|dog|kitten|puppy)\s+([A-Z][a-z]+)\b').firstMatch(story);
  if (petName != null) {
    return _Subject(petName.group(1)!, petName.group(1)!, 'pet');
  }
  final brand = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b').firstMatch(story);
  if (brand != null && type == 'business') {
    return _Subject(brand.group(1)!, brand.group(1)!, type);
  }
  final iAm = RegExp(r'\bI am\s+(?!a\b|an\b)([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})').firstMatch(story);
  if (iAm != null) {
    return _Subject(iAm.group(1)!, iAm.group(1)!, type);
  }
  final kind = switch (type) {
    'pet' => _kindWord(story, const ['cat', 'dog', 'kitten', 'puppy', 'pet']),
    'business' => _kindWord(story, const ['bakery', 'cafe', 'shop', 'restaurant']),
    'healthcare' => _kindWord(story, const ['clinic', 'pediatrician', 'doctor']),
    'photographer' => 'Photography',
    'leadership' => 'Constituency',
    _ => '',
  };
  final fallback = kind.isEmpty ? _firstWords(story) : _label(kind);
  return _Subject(given, fallback, type);
}

String _heroTitle(String type, _Subject subject) {
  if (type == 'pet' && subject.name.isNotEmpty) {
    return 'Meet ${subject.name}';
  }
  if (subject.name.isNotEmpty) {
    return subject.name;
  }
  return subject.fallback;
}

String _heroLine(
  String type,
  _Subject subject,
  List<String> loves,
  List<String> made,
  List<String> sentences,
) {
  if (type == 'pet' && loves.isNotEmpty) {
    final who = subject.name.isEmpty ? 'This ${_kindWord(subject.fallback, const ['cat', 'dog', 'pet']).toLowerCase()}' : subject.name;
    return '$who loves ${_join(loves.map((item) => item.toLowerCase()).toList())}.';
  }
  if (type == 'business' && made.isNotEmpty) {
    return _join(made);
  }
  if (type == 'photographer' && made.isNotEmpty) {
    return _join(made);
  }
  if (type == 'healthcare' && made.isNotEmpty) {
    return _join(made);
  }
  if (sentences.isNotEmpty) {
    return sentences.first;
  }
  return '';
}

String _aboutBody(String type, List<String> sentences) {
  if (type == 'personal' && sentences.length <= 1) {
    return '';
  }
  final kept = sentences.where((sentence) {
    final lower = sentence.toLowerCase();
    return !lower.startsWith('i want a') && !lower.startsWith('i would like');
  }).toList();
  if (kept.isEmpty) {
    return '';
  }
  if (type == 'personal') {
    return kept.skip(1).join(' ');
  }
  return kept.join(' ');
}

String _petCardTitle(String phrase) {
  final lower = phrase.toLowerCase();
  if (lower.contains('sleep') && lower.contains('sun')) {
    return 'Sunny naps';
  }
  if (lower.contains('toy')) {
    return 'Chasing toys';
  }
  if (lower.contains('play')) {
    return 'Playing';
  }
  return _label(phrase);
}

(String, String) _ctas(String type, String name, List<WebsiteSection> sections) {
  bool has(WebsiteSectionType kind) => sections.any((section) => section.type == kind);
  return switch (type) {
    'pet' => ('Meet ${name.isEmpty ? 'them' : name}', has(WebsiteSectionType.gallery) ? 'View gallery' : ''),
    'leadership' => (
      has(WebsiteSectionType.contact) || has(WebsiteSectionType.publicRequests) ? 'Contact office' : '',
      has(WebsiteSectionType.achievements) ? 'View my work' : '',
    ),
    'business' => ('See the menu', has(WebsiteSectionType.gallery) ? 'View gallery' : ''),
    'photographer' || 'artist' => ('View portfolio', has(WebsiteSectionType.gallery) ? 'View gallery' : ''),
    'healthcare' => ('Clinic details', ''),
    _ => ('', ''),
  };
}

String _heroLayout(String type, int variant) {
  final layouts = switch (type) {
    'pet' => ['gradient', 'split', 'centered'],
    'photographer' || 'artist' => ['split', 'editorial', 'full'],
    'business' => ['centered', 'gradient', 'split'],
    'healthcare' => ['split', 'minimal', 'centered'],
    'leadership' => ['split', 'editorial', 'gradient'],
    _ => ['gradient', 'centered', 'minimal'],
  };
  return layouts[variant % layouts.length];
}

WebsiteSection _prose(String id, WebsiteSectionType type, String titleKey, String heading, String content, int order) {
  return WebsiteSection(
    id: id,
    type: type,
    titleKey: titleKey,
    heading: heading,
    order: order,
    content: content,
  );
}

WebsiteSection _cards(String id, WebsiteSectionType type, String heading, List<String> labels, int order) {
  return WebsiteSection(
    id: id,
    type: type,
    titleKey: 'secAbout',
    heading: heading,
    order: order,
    items: [
      for (final label in labels) WebsiteItem(title: _label(label), description: label.trim()),
    ],
  );
}

List<String> _afterVerb(String text, RegExp pattern) {
  final match = pattern.firstMatch(text);
  if (match == null) {
    return const [];
  }
  return _splitList(match.group(1)!).map(_tidyPhrase).where((item) => item.isNotEmpty).toList();
}

List<String> _traits(String text) {
  final match = RegExp(
    r'\b(?:is|are)\s+([a-z][a-z\s,]+)',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) {
    return const [];
  }
  return _splitList(match.group(1)!)
      .map((word) => word.replaceAll(RegExp(r'\bvery\b', caseSensitive: false), '').trim())
      .map(_label)
      .where((word) => word.isNotEmpty && !_traitSkip.contains(word.toLowerCase()))
      .toList();
}

List<String> _photoSubjects(String text) {
  final found = <String>[];
  for (final word in ['weddings', 'wedding', 'portraits', 'portrait']) {
    if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(text)) {
      final label = word.startsWith('wedding') ? 'Weddings' : 'Portraits';
      if (!found.contains(label)) {
        found.add(label);
      }
    }
  }
  return found;
}

List<String> _careSubjects(String text) {
  final found = <String>[];
  if (RegExp(r'child healthcare|child care|pediatric', caseSensitive: false).hasMatch(text)) {
    found.add('Child healthcare');
  }
  if (RegExp(r'vaccination', caseSensitive: false).hasMatch(text)) {
    found.add('Vaccination');
  }
  return found;
}

String _place(String text) {
  final match = RegExp(r'\b(?:in|at)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)').firstMatch(text);
  return match == null ? '' : match.group(1)!;
}

String _story(WebsiteDraft draft) {
  return [
    draft.description,
    draft.introduction,
    draft.about,
    draft.vision,
    draft.mission,
    draft.priorities,
    draft.fullName,
    draft.publicTitle,
    draft.organization,
  ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');
}

List<String> _sentences(String text) {
  return text
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((sentence) => sentence.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
}

List<String> _chunks(String text) {
  return text.split(RegExp(r'\n+')).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
}

List<WebsiteItem> _events(String note) {
  final items = <WebsiteItem>[];
  for (final line in _chunks(note)) {
    final parts = line.split('|').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      continue;
    }
    items.add(
      WebsiteItem(
        title: parts.first,
        meta: parts.length > 1 ? parts[1] : '',
        description: parts.length > 2 ? parts.sublist(2).join(' ') : '',
      ),
    );
  }
  return items;
}

List<WebsiteItem> _contactItems(WebsiteDraft draft) {
  final items = <WebsiteItem>[];
  void add(String meta, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    items.add(WebsiteItem(title: trimmed, meta: meta));
  }

  add('public', draft.publicContact);
  add('address', draft.address);
  add('phone', draft.phone);
  add('email', draft.email);
  add('link', draft.publicLinks);
  return items;
}

List<WebsiteItem> _socialItems(String raw) {
  final items = <WebsiteItem>[];
  for (final line in raw.split(RegExp(r'[\n,]+'))) {
    final value = line.trim();
    if (value.isEmpty) {
      continue;
    }
    final lower = value.toLowerCase();
    final network = _networks.entries.where((entry) => lower.contains(entry.key)).map((entry) => entry.value).firstOrNull;
    items.add(WebsiteItem(title: network ?? value, description: network == null ? '' : value));
  }
  return items;
}

String _sentenceContaining(String text, RegExp pattern) {
  for (final sentence in _sentences(text)) {
    if (pattern.hasMatch(sentence)) {
      return sentence;
    }
  }
  return '';
}

List<String> _splitList(String raw) {
  return raw
      .split(RegExp(r',|\band\b', caseSensitive: false))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

String _tidyPhrase(String raw) {
  var value = raw.trim().replaceAll(RegExp(r'[.]+$'), '');
  value = value.replaceAll(RegExp(r'^(and|or)\s+', caseSensitive: false), '');
  return value;
}

String _label(String raw) {
  final words = _tidyPhrase(raw).split(RegExp(r'\s+')).where((word) => word.isNotEmpty && !_skip.contains(word.toLowerCase())).toList();
  if (words.isEmpty || words.length > 6) {
    return words.length > 6 ? words.take(6).map(_cap).join(' ') : '';
  }
  return words.map(_cap).join(' ');
}

String _cap(String word) {
  if (word.isEmpty) {
    return word;
  }
  if (word == word.toUpperCase() && word.length <= 4) {
    return word;
  }
  return word[0].toUpperCase() + word.substring(1);
}

String _kindWord(String text, List<String> words) {
  for (final word in words) {
    if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(text)) {
      return _cap(word);
    }
  }
  return words.isEmpty ? '' : _cap(words.last);
}

String _firstWords(String text) {
  final words = text
      .replaceAll(RegExp(r'[^A-Za-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2 && !_intent.contains(word.toLowerCase()))
      .take(3)
      .toList();
  return words.isEmpty ? 'Website' : words.map(_cap).join(' ');
}

String _join(List<String> items) {
  if (items.isEmpty) {
    return '';
  }
  if (items.length == 1) {
    return items.first;
  }
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}

const _topics = <String>[
  'education',
  'healthcare',
  'health',
  'roads',
  'infrastructure',
  'employment',
  'jobs',
  'water',
  'housing',
  'sanitation',
  'safety',
];

const _skip = <String>{
  'a',
  'an',
  'and',
  'are',
  'for',
  'from',
  'in',
  'is',
  'my',
  'of',
  'on',
  'our',
  'the',
  'to',
  'with',
};

const _traitSkip = <String>{
  'a',
  'an',
  'the',
  'working',
  'able',
  'people',
};

const _intent = <String>{
  'want',
  'website',
  'beautiful',
  'the',
  'and',
  'for',
  'with',
  'that',
  'this',
  'have',
  'been',
};

const _networks = <String, String>{
  'facebook': 'Facebook',
  'instagram': 'Instagram',
  'youtube': 'YouTube',
  'linkedin': 'LinkedIn',
  'twitter': 'X',
  'x.com': 'X',
};
