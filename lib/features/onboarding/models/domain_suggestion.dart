/// Domain availability result from POST /api/domains/search.
class DomainSuggestion {
  const DomainSuggestion({
    required this.name,
    required this.available,
    required this.status,
    this.priceAmount,
    this.priceCurrency,
    this.supplierPriceAmount,
    this.supplierPriceCurrency,
    this.isPremium = false,
    this.error,
  });

  final String name;
  final bool available;
  final String status;
  final double? priceAmount;
  final String? priceCurrency;
  final double? supplierPriceAmount;
  final String? supplierPriceCurrency;
  final bool isPremium;
  final String? error;

  bool get checkFailed =>
      error != null ||
      status == 'unknown' ||
      (!available &&
          status != 'free' &&
          status != 'reserved' &&
          status != 'in use' &&
          status != 'active' &&
          status != 'taken' &&
          status != 'unavailable' &&
          status != 'registered');

  factory DomainSuggestion.fromJson(Map<String, dynamic> json) {
    final price = json['price'];
    double? amount;
    String? currency;
    if (price is Map<String, dynamic>) {
      final rawAmount = price['amount'];
      if (rawAmount is num) {
        amount = rawAmount.toDouble();
      }
      final rawCurrency = price['currency'];
      if (rawCurrency is String && rawCurrency.trim().isNotEmpty) {
        currency = rawCurrency.trim().toUpperCase();
      }
    }

    final supplier = json['supplierPrice'];
    double? supplierAmount;
    String? supplierCurrency;
    if (supplier is Map<String, dynamic>) {
      final rawAmount = supplier['amount'];
      if (rawAmount is num) {
        supplierAmount = rawAmount.toDouble();
      }
      final rawCurrency = supplier['currency'];
      if (rawCurrency is String && rawCurrency.trim().isNotEmpty) {
        supplierCurrency = rawCurrency.trim().toUpperCase();
      }
    }

    return DomainSuggestion(
      name: (json['domain'] as String? ?? '').trim().toLowerCase(),
      available: json['available'] == true,
      status: (json['status'] as String? ?? 'unknown').trim().toLowerCase(),
      priceAmount: amount,
      priceCurrency: currency,
      supplierPriceAmount: supplierAmount,
      supplierPriceCurrency: supplierCurrency,
      isPremium: json['isPremium'] == true,
      error: json['error'] as String?,
    );
  }
}

/// Standard TLDs shown first when available.
const standardDomainExtensions = <String>[
  'com',
  'in',
  'org',
  'co',
  'ai',
  'io',
  'net',
];

/// Extra popular TLDs checked after the standard set.
const extraDomainExtensions = <String>[
  'co.in',
  'info',
  'biz',
  'online',
  'site',
  'store',
  'xyz',
  'me',
  'app',
  'dev',
  'tech',
  'live',
  'world',
  'club',
  'shop',
  'blog',
];

const defaultDomainExtensions = <String>[
  ...standardDomainExtensions,
  ...extraDomainExtensions,
];

/// Keeps letters and digits so "Arjun Verma" becomes "arjunverma".
String? domainSlug(String query) {
  final slug = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
  final cleaned = slug.replaceAll(RegExp(r'^-+|-+$'), '');
  if (cleaned.isEmpty || cleaned.length > 63) {
    return null;
  }
  if (!RegExp(r'^(?:[a-z0-9]|[a-z0-9][a-z0-9-]{0,61}[a-z0-9])$').hasMatch(cleaned)) {
    return null;
  }
  return cleaned;
}

List<DomainSuggestion> availableDomainsFirst(List<DomainSuggestion> results) {
  String extensionOf(String domain) {
    final parts = domain.toLowerCase().split('.');
    if (parts.length < 2) {
      return '';
    }
    return parts.sublist(1).join('.');
  }

  final available = results.where((item) => item.available).toList();
  available.sort((a, b) {
    final aExt = extensionOf(a.name);
    final bExt = extensionOf(b.name);
    final aStandard = standardDomainExtensions.indexOf(aExt);
    final bStandard = standardDomainExtensions.indexOf(bExt);
    final aIsStandard = aStandard != -1;
    final bIsStandard = bStandard != -1;

    if (aIsStandard != bIsStandard) {
      return aIsStandard ? -1 : 1;
    }
    if (aIsStandard && bIsStandard && aStandard != bStandard) {
      return aStandard.compareTo(bStandard);
    }
    if (a.isPremium != b.isPremium) {
      return a.isPremium ? 1 : -1;
    }
    final extCompare = aExt.compareTo(bExt);
    if (extCompare != 0) {
      return extCompare;
    }
    return a.name.compareTo(b.name);
  });
  return available;
}
