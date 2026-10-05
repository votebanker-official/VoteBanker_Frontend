import 'dart:typed_data';

/// In-memory onboarding values for the current session.
/// A profile repository can replace this when the API exists.
class OnboardingDraft {
  String selectedLanguage = 'en';
  String fullName = '';
  Uint8List? photoBytes;

  /// Assembly constituency. Older call sites still read this as [designation].
  String assemblyConstituency = '';

  /// Role collected after Party. Kept separate from [assemblyConstituency].
  String designation = '';
  String organization = '';
  String country = '';
  String stateRegion = '';
  String constituency = '';
  String publicContact = '';
  String partNo = '';
  String partName = '';
  String preferredLanguage = '';

  String get leaderName => fullName;
  set leaderName(String value) => fullName = value;

  String get party => organization;
  set party(String value) => organization = value;

  String get boothNumber => partNo;
  set boothNumber(String value) => partNo = value;

  String get boothName => partName;
  set boothName(String value) => partName = value;

  String get state => stateRegion;
  set state(String value) => stateRegion = value;

  String get district => constituency;
  set district(String value) => constituency = value;

  String get contactNumber => publicContact;
  set contactNumber(String value) => publicContact = value;
  String domainQuery = '';
  String? selectedDomain;
  String? websiteTemplate;
  final Set<String> socialChannels = <String>{};
  bool vrmRequested = false;
}
