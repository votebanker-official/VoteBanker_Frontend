import 'package:flutter/foundation.dart';

import '../../core/services/auth_service.dart';
import 'admin_service.dart';

/// Admin navigation visibility for the signed-in account.
class AdminAccess extends ChangeNotifier {
  AdminAccess._() {
    AuthService.instance.onSessionCleared(reset);
  }

  static final AdminAccess instance = AdminAccess._();
  static const designatedAdminEmail = 'votebanker.com@gmail.com';

  bool isAdmin = false;
  String? _userId;
  Future<void>? _pending;

  /// Shows the link for the designated account immediately; admin APIs still
  /// authorize every request on the server.
  bool get showInSidebar {
    if (isAdmin) return true;
    final email = AuthService.instance.signedInEmail.trim().toLowerCase();
    return email == designatedAdminEmail;
  }

  Future<void> ensureLoaded() {
    final id = AuthService.instance.session?.userId;
    if (_userId != id) {
      _userId = id;
      isAdmin = false;
      _pending = _load();
    }
    return _pending ??= _load();
  }

  Future<void> reload() {
    _userId = AuthService.instance.session?.userId;
    _pending = _load();
    return _pending!;
  }

  void reset() {
    _userId = null;
    _pending = null;
    isAdmin = false;
    notifyListeners();
  }

  Future<void> _load() async {
    final session = AuthService.instance.session;
    if (session == null) {
      isAdmin = false;
      notifyListeners();
      return;
    }
    await AuthService.instance.refreshIfExpired();
    if (AuthService.instance.session?.userId != _userId) return;
    var allowed = false;
    try {
      final body = await AdminService.instance.getJson('/api/auth/me');
      allowed = body['role'] == 'admin';
    } catch (_) {
      allowed = false;
    }
    final currentId = AuthService.instance.session?.userId;
    if (currentId == null || currentId != _userId) return;
    isAdmin = allowed;
    notifyListeners();
  }
}
