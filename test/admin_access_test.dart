import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/features/admin/admin_access.dart';

void main() {
  test('the designated admin always sees the sidebar link', () {
    final previous = AuthService.instance.session;
    addTearDown(() {
      AuthService.instance.session = previous;
      AdminAccess.instance.reset();
    });

    AdminAccess.instance.reset();
    final claims = base64Url
        .encode(utf8.encode(jsonEncode({'email': 'votebanker.com@gmail.com'})))
        .replaceAll('=', '');
    AuthService.instance.session = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      userId: 'client-user',
      phone: '',
      email: 'client@example.com',
    );
    expect(AdminAccess.instance.showInSidebar, isFalse);

    AuthService.instance.session = const AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      userId: 'admin-user',
      phone: '',
      email: '  VoteBanker.com@gmail.com ',
    );
    expect(AdminAccess.instance.showInSidebar, isTrue);

    AuthService.instance.session = AuthSession(
      accessToken: 'header.$claims.signature',
      refreshToken: 'refresh',
      userId: 'admin-user',
      phone: '',
      email: 'facebook.1@social.votebanker.app',
    );

    expect(AdminAccess.instance.showInSidebar, isTrue);
  });

  test('malformed access tokens do not yield an email', () {
    expect(AuthService.emailFromAccessToken('not-a-jwt'), isEmpty);
  });
}
