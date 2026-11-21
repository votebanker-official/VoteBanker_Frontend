import 'package:flutter/foundation.dart';

import '../../core/services/auth_service.dart';
import 'admin_service.dart';

/// Server-confirmed admin flag for the signed-in account.
class AdminAccess extends ChangeNotifier {
  AdminAccess._();

  static final AdminAccess instance = AdminAccess._();

  bool isAdmin = false;
  String? _userId;
  Future<void>? _pending;

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

  Future<void> _load() async {
    final allowed = AuthService.instance.session == null
        ? false
        : await AdminService.instance.isAdmin();
    if (AuthService.instance.session?.userId != _userId) return;
    isAdmin = allowed;
    notifyListeners();
  }
}
