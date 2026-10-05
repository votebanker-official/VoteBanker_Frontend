import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/onboarding/models/onboarding_draft.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

/// Saves onboarding answers to the signed-in user's profile.
class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  Future<bool> _inFlight = Future.value(true);

  /// Best-effort save. Never throws, so onboarding is never blocked by it.
  /// Saves are queued so they reach the server in the order they were made.
  Future<bool> saveDraft(OnboardingDraft draft) {
    final session = AuthService.instance.session;
    if (session == null) return Future.value(false);

    // Only send values the user actually filled in, so a returning user with a
    // blank form cannot overwrite a saved profile.
    final text = <String, String?>{
      'full_name': draft.leaderName,
      'designation': draft.assemblyConstituency,
      'organization': draft.party,
      'country': draft.country,
      'state_region': draft.stateRegion,
      'constituency': draft.constituency,
      'public_contact': draft.publicContact,
      'language':
          draft.preferredLanguage.isNotEmpty
              ? draft.preferredLanguage
              : draft.selectedLanguage,
      'selected_domain': draft.selectedDomain,
      'website_template': draft.websiteTemplate,
    };
    final payload = <String, dynamic>{
      for (final entry in text.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value,
      if (draft.socialChannels.isNotEmpty)
        'social_channels': draft.socialChannels.toList(),
      if (draft.vrmRequested) 'vrm_requested': true,
    };

    _inFlight = _inFlight.then((_) => _put(session.accessToken, payload));
    return _inFlight;
  }

  Future<bool> _put(String token, Map<String, dynamic> payload) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/api/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
