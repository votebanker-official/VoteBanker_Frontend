import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

    final payload = profilePayload(draft);

    _inFlight = _inFlight.then((_) async {
      await _syncPhoto(session.accessToken, draft);
      return _put(session.accessToken, payload);
    });
    return _inFlight;
  }

  /// Saved profile for the signed-in user. Null when signed out or unreachable.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final session = AuthService.instance.session;
    if (session == null) return null;
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/profile'),
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final profile = decoded['profile'];
      if (profile is! Map<String, dynamic>) return null;
      return profile;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> downloadPhoto(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.bodyBytes.length > maxPhotoBytes) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  /// Fields that are actually filled in. Empty values are left out so a blank
  /// form cannot overwrite a saved profile. Assembly constituency is the typed
  /// label. A constituency id is never sent.
  static Map<String, dynamic> profilePayload(OnboardingDraft draft) {
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
      'booth_number': draft.boothNumber,
      'booth_name': draft.boothName,
    };
    return <String, dynamic>{
      for (final entry in text.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value,
      if (draft.socialChannels.isNotEmpty)
        'social_channels': draft.socialChannels.toList(),
    };
  }

  static const maxPhotoBytes = 2 * 1024 * 1024;

  /// JPEG, PNG, or WebP from the file bytes. Null for anything else.
  static String? photoContentType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  /// Fills only fields the user has not already typed in this session.
  static String? photoUrlFromProfile(Map<String, dynamic> profile) {
    final url = profile['profile_photo_url'];
    if (url is! String || url.trim().isEmpty) return null;
    return url.trim();
  }

  static void applyProfile(
    OnboardingDraft draft,
    Map<String, dynamic> profile,
  ) {
    void fill(String key, String current, void Function(String value) set) {
      final value = profile[key];
      if (current.trim().isNotEmpty ||
          value is! String ||
          value.trim().isEmpty) {
        return;
      }
      set(value.trim());
    }

    fill('full_name', draft.leaderName, (value) => draft.leaderName = value);
    fill(
      'designation',
      draft.assemblyConstituency,
      (value) => draft.assemblyConstituency = value,
    );
    fill('organization', draft.party, (value) => draft.party = value);
    fill('country', draft.country, (value) => draft.country = value);
    fill(
      'state_region',
      draft.stateRegion,
      (value) => draft.stateRegion = value,
    );
    fill(
      'constituency',
      draft.constituency,
      (value) => draft.constituency = value,
    );
    fill(
      'public_contact',
      draft.contactNumber,
      (value) => draft.contactNumber = value,
    );
    fill(
      'booth_number',
      draft.boothNumber,
      (value) => draft.boothNumber = value,
    );
    fill('booth_name', draft.boothName, (value) => draft.boothName = value);
    fill(
      'language',
      draft.preferredLanguage,
      (value) => draft.preferredLanguage = value,
    );
    final photoUrl = photoUrlFromProfile(profile);
    if (photoUrl != null &&
        draft.photoBytes == null &&
        !draft.photoRemoved &&
        draft.profilePhotoUrl.isEmpty) {
      draft.profilePhotoUrl = photoUrl;
    }
  }

  Future<void> _syncPhoto(String token, OnboardingDraft draft) async {
    if (draft.photoPendingUpload && draft.photoBytes != null) {
      final uploaded = await _uploadPhoto(token, draft.photoBytes!);
      if (uploaded != null) {
        draft
          ..profilePhotoUrl = uploaded
          ..photoPendingUpload = false
          ..photoRemoved = false;
      }
    } else if (draft.photoRemoved) {
      final removed = await _deletePhoto(token);
      if (removed) {
        draft
          ..profilePhotoUrl = ''
          ..photoRemoved = false;
      }
    }
  }

  Future<String?> _uploadPhoto(String token, Uint8List bytes) async {
    final type = photoContentType(bytes);
    if (type == null || bytes.length > maxPhotoBytes) return null;
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/profile/photo'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': type},
            body: bytes,
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return '';
      final profile = decoded['profile'];
      if (profile is! Map<String, dynamic>) return '';
      return photoUrlFromProfile(profile) ?? '';
    } catch (_) {
      return null;
    }
  }

  Future<bool> _deletePhoto(String token) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${AppConfig.apiBaseUrl}/api/profile/photo'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
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
