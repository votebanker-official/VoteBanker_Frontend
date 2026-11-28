String formatPersonName(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(_capitalizeNamePart)
      .join(' ');
}

final RegExp _letter = RegExp(r'\p{L}', unicode: true);

/// First name for the website-builder heading, or null when [value] is not a
/// usable person name. Emails and placeholder values are rejected.
String? websiteFirstName(String? value, {String? accountEmail}) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.contains('@')) return null;
  final email = (accountEmail ?? '').trim().toLowerCase();
  if (email.isNotEmpty && trimmed.toLowerCase() == email) return null;

  final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  if (parts.isEmpty) return null;
  final first = parts.first;
  if (!_letter.hasMatch(first.substring(0, 1))) return null;
  if (_blockedFirstName.contains(first.toLowerCase())) return null;

  final shown = _presentFirstName(first);
  if (shown.isEmpty || _blockedFirstName.contains(shown.toLowerCase())) {
    return null;
  }
  return shown;
}

/// `Firstname.com` for a usable person name. Null when the name cannot be shown.
String? formatWebsiteHeading(String? value, {String? accountEmail}) {
  final first = websiteFirstName(value, accountEmail: accountEmail);
  if (first == null || first.isEmpty) return null;
  return '$first.com';
}

/// Signed-in website heading. [profileName] is null until the profile has loaded.
/// A loaded empty profile falls through to the authenticated session name.
String websiteBuilderHeading({
  required bool signedIn,
  String? profileName,
  String? sessionName,
  String? accountEmail,
  required String fallback,
}) {
  if (!signedIn) return fallback;
  if (profileName != null) {
    final fromProfile = formatWebsiteHeading(
      profileName,
      accountEmail: accountEmail,
    );
    if (fromProfile != null) return fromProfile;
  }
  final fromSession = formatWebsiteHeading(
    sessionName,
    accountEmail: accountEmail,
  );
  if (fromSession != null) return fromSession;
  return fallback;
}

const Set<String> _blockedFirstName = {
  'null',
  'undefined',
  'user',
  'guest',
  'none',
  'com',
};

String _presentFirstName(String part) {
  final first = part.substring(0, 1).toUpperCase();
  final rest = part.substring(1);
  final shouting =
      _letter.hasMatch(part) &&
      part == part.toUpperCase() &&
      part != part.toLowerCase();
  return '$first${shouting ? rest.toLowerCase() : rest}';
}

String _capitalizeNamePart(String part) {
  return part.splitMapJoin(
    RegExp(r"([-'])"),
    onMatch: (match) => match.group(0)!,
    onNonMatch: (segment) {
      if (segment.isEmpty) return segment;
      final lower = segment.toLowerCase();
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    },
  );
}
