import 'dart:typed_data';

/// In-memory onboarding values for the current session.
/// A profile repository can replace this when the API exists.
class OnboardingDraft {
  String selectedLanguage = 'en';
  String fullName = '';
  Uint8List? photoBytes;
  String designation = '';
  String organization = '';
  String country = '';
  String stateRegion = '';
  String constituency = '';
  String publicContact = '';
  String preferredLanguage = '';
  String domainQuery = '';
  String? selectedDomain;
  String? websiteTemplate;
  final Set<String> socialChannels = <String>{};
  bool vrmRequested = false;
}
