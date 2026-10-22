/// Domain availability result from POST /api/domains/search.
class DomainSuggestion {
  const DomainSuggestion({
    required this.name,
    required this.available,
    required this.status,
    this.priceAmount,
    this.priceCurrency,
    this.renewalPriceAmount,
    this.renewalPriceCurrency,
    this.isPremium = false,
    this.error,
  });

  final String name;
  final bool available;
  final String status;
  final double? priceAmount;
  final String? priceCurrency;
  final double? renewalPriceAmount;
  final String? renewalPriceCurrency;
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

    final renewal = json['renewalPrice'];
    double? renewalAmount;
    String? renewalCurrency;
    if (renewal is Map<String, dynamic>) {
      final rawAmount = renewal['amount'];
      if (rawAmount is num) {
        renewalAmount = rawAmount.toDouble();
      }
      final rawCurrency = renewal['currency'];
      if (rawCurrency is String && rawCurrency.trim().isNotEmpty) {
        renewalCurrency = rawCurrency.trim().toUpperCase();
      }
    }

    return DomainSuggestion(
      name: (json['domain'] as String? ?? '').trim().toLowerCase(),
      available: json['available'] == true,
      status: (json['status'] as String? ?? 'unknown').trim().toLowerCase(),
      priceAmount: amount,
      priceCurrency: currency,
      renewalPriceAmount: renewalAmount,
      renewalPriceCurrency: renewalCurrency,
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

/// Politician-related TLDs. The API drops any Openprovider does not sell.
const politicalDomainExtensions = <String>[
  'leader',
  'captain',
  'page',
  'boss',
  'neta',
  'vote',
  'voto',
  'voting',
  'democrat',
  'republican',
  'gop',
  'party',
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
  ...politicalDomainExtensions,
  ...extraDomainExtensions,
];

/// Openprovider INR amounts stay exact. Anything under ₹1500 is shown as 1500.
double? customerFacingAmount(double? amount, String? currency) {
  if (amount == null) {
    return null;
  }
  if ((currency ?? '').trim().toUpperCase() == 'INR' && amount < 1500) {
    return 1500;
  }
  return amount;
}

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
    final aPolitical = politicalDomainExtensions.indexOf(aExt);
    final bPolitical = politicalDomainExtensions.indexOf(bExt);
    final aRank = aStandard != -1
        ? aStandard
        : aPolitical != -1
            ? standardDomainExtensions.length + aPolitical
            : standardDomainExtensions.length + politicalDomainExtensions.length;
    final bRank = bStandard != -1
        ? bStandard
        : bPolitical != -1
            ? standardDomainExtensions.length + bPolitical
            : standardDomainExtensions.length + politicalDomainExtensions.length;

    if (aRank != bRank) {
      return aRank.compareTo(bRank);
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
