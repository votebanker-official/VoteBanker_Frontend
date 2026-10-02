/// Sample domain suggestions for this prototype.
/// Prices stay in this mock catalog so a domain provider can replace them later.
class DomainSuggestion {
  const DomainSuggestion({
    required this.name,
    required this.available,
    required this.priceInr,
  });

  final String name;
  final bool available;
  final int priceInr;
}

const _sampleTlds = <(String, int)>[
  ('com', 999),
  ('in', 499),
  ('co.in', 299),
  ('org', 899),
  ('net', 799),
];

/// Keeps letters and digits so "Arjun Verma" becomes "arjunverma".
String? domainSlug(String query) {
  final slug = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (slug.isEmpty) {
    return null;
  }
  return slug;
}

List<DomainSuggestion> suggestDomains(String query) {
  final slug = domainSlug(query);
  if (slug == null) {
    return const [];
  }

  return [
    for (final tld in _sampleTlds)
      DomainSuggestion(
        name: '$slug.${tld.$1}',
        available: true,
        priceInr: tld.$2,
      ),
  ];
}
