import '../../../app/localization/app_localizations.dart';
import '../../../core/services/auth_service.dart';

/// A verification-assistance offer. Prices are VOTE BANKER charges only.
class BlueTikOffer {
  const BlueTikOffer({
    required this.id,
    required this.platforms,
    required this.priceInr,
  });

  final String id;
  final List<String> platforms;
  final int priceInr;

  bool get bundle => id == 'bundle';
}

abstract final class BlueTikCatalog {
  static const instagram = BlueTikOffer(
    id: 'instagram',
    platforms: ['instagram'],
    priceInr: 799,
  );
  static const facebook = BlueTikOffer(
    id: 'facebook',
    platforms: ['facebook'],
    priceInr: 799,
  );
  static const whatsapp = BlueTikOffer(
    id: 'whatsapp',
    platforms: ['whatsapp'],
    priceInr: 999,
  );
  static const bundle = BlueTikOffer(
    id: 'bundle',
    platforms: ['instagram', 'facebook', 'whatsapp'],
    priceInr: 1999,
  );

  static const individuals = <BlueTikOffer>[instagram, facebook, whatsapp];
}

String formatInr(int amount) {
  final text = amount.abs().toString();
  final sign = amount < 0 ? '-' : '';
  if (text.length <= 3) return '$sign₹$text';
  final head = text.substring(0, text.length - 3);
  final tail = text.substring(text.length - 3);
  return '$sign₹$head,$tail';
}

String blueTikPlatformName(AppLocalizations l10n, String id) {
  return switch (id) {
    'instagram' => l10n.socialInstagram,
    'facebook' => l10n.socialFacebook,
    'whatsapp' => l10n.socialWhatsApp,
    _ => id,
  };
}

String blueTikServiceTitle(AppLocalizations l10n, BlueTikOffer offer) {
  if (offer.bundle) return l10n.line('blueTikBundle');
  return blueTikPlatformName(l10n, offer.id);
}

String blueTikServiceDescription(AppLocalizations l10n, BlueTikOffer offer) {
  if (offer.bundle) return '';
  return l10n
      .line('blueTikVerifiedOn')
      .replaceAll('{platform}', blueTikServiceTitle(l10n, offer));
}

String blueTikProfileUrlLabel(AppLocalizations l10n, String platformId) {
  return l10n
      .line('blueTikProfileUrl')
      .replaceAll('{platform}', blueTikPlatformName(l10n, platformId));
}

/// A submitted assistance request.
///
/// There is no approved state. A platform has to confirm verification itself.
class BlueTikApplication {
  const BlueTikApplication({
    required this.offerId,
    required this.serviceName,
    required this.priceInr,
    required this.leaderName,
    required this.mobile,
    required this.email,
    required this.profileUrls,
    required this.submittedAt,
  });

  final String offerId;
  final String serviceName;
  final int priceInr;
  final String leaderName;
  final String mobile;
  final String email;
  final Map<String, String> profileUrls;
  final DateTime submittedAt;
}

/// Session list of assistance requests. Nothing here is sent to a platform.
class BlueTikApplicationStore {
  BlueTikApplicationStore._();

  static final BlueTikApplicationStore instance = BlueTikApplicationStore._();

  final List<BlueTikApplication> _items = <BlueTikApplication>[];

  List<BlueTikApplication> get items => List.unmodifiable(_items);

  void add(BlueTikApplication application) => _items.add(application);

  void clear() => _items.clear();
}

class BlueTikValidation {
  const BlueTikValidation({
    this.name,
    this.mobile,
    this.email,
    this.urls = const {},
  });

  final String? name;
  final String? mobile;
  final String? email;
  final Map<String, String> urls;

  bool get isValid =>
      name == null && mobile == null && email == null && urls.isEmpty;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

bool isProfileUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https') return false;
  return uri.host.contains('.');
}

BlueTikValidation validateBlueTikRequest({
  required String name,
  required String mobile,
  required String email,
  required Map<String, String> profileUrls,
}) {
  final urlErrors = <String, String>{};
  for (final entry in profileUrls.entries) {
    if (!isProfileUrl(entry.value)) {
      urlErrors[entry.key] = 'url_invalid';
    }
  }
  return BlueTikValidation(
    name: name.trim().length < 2 ? 'name_required' : null,
    mobile:
        AuthService.normalizePhone(mobile) == null ? 'mobile_invalid' : null,
    email: _emailPattern.hasMatch(email.trim()) ? null : 'email_invalid',
    urls: urlErrors,
  );
}
