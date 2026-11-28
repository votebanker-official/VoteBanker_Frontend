import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
import 'models/merchandise_design.dart';

/// The signed-in leader's print sources. Cleared when the account changes.
class MerchandiseIdentityController extends ChangeNotifier {
  MerchandiseIdentityController._();

  static final MerchandiseIdentityController instance =
      MerchandiseIdentityController._();

  String? userId;
  Uint8List? photo;
  String partyName = '';
  bool loaded = false;
  int _token = 0;

  bool get signedIn => userId != null;

  bool get hasPhoto => photo != null && photo!.isNotEmpty;

  bool get hasParty => partyName.trim().isNotEmpty;

  bool get complete => hasPhoto && hasParty;

  Future<void> refresh() async {
    final session = AuthService.instance.session;
    final token = ++_token;
    if (session == null) {
      userId = null;
      photo = null;
      partyName = '';
      loaded = true;
      MerchandiseDesignStore.instance.bindUser(null);
      notifyListeners();
      return;
    }
    if (userId != session.userId) {
      photo = null;
      partyName = '';
      loaded = false;
      userId = session.userId;
      MerchandiseDesignStore.instance.bindUser(session.userId);
      notifyListeners();
    }
    final profile = await ProfileService.instance.fetchProfile();
    if (token != _token ||
        AuthService.instance.session?.userId != session.userId) {
      return;
    }
    final organization =
        profile == null ? '' : '${profile['organization'] ?? ''}'.trim();
    Uint8List? bytes;
    final url =
        profile == null ? null : ProfileService.photoUrlFromProfile(profile);
    if (url != null) {
      bytes = await ProfileService.instance.downloadPhoto(url);
    }
    if (token != _token ||
        AuthService.instance.session?.userId != session.userId) {
      return;
    }
    partyName = organization;
    photo = bytes;
    loaded = true;
    notifyListeners();
  }
}
