import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_colors.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/screens/login_screen.dart';
import 'package:votebanker/features/onboarding/password_reset/password_reset_request.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('parses email and mobile identifiers', () {
    final email = PasswordResetRequest.parse('sushma@vote.banker');
    expect(email?.isEmail, isTrue);
    expect(email?.maskedEmail, 's***a@vote.banker');

    final mobile = PasswordResetRequest.parse('+91 98765 43210');
    expect(mobile?.isEmail, isFalse);
    expect(mobile?.identifier, '9876543210');
    expect(PasswordResetRequest.parse('123'), isNull);
    expect(PasswordResetRequest.parse('not-an-email'), isNull);
  });

  test(
    'recovery link credentials are submitted and cleared after reset',
    () async {
      const accessToken = 'recovery-access-token';
      const refreshToken = 'recovery-refresh-token';
      final fragment =
          Uri(
            queryParameters: {
              'access_token': accessToken,
              'refresh_token': refreshToken,
              'type': 'recovery',
            },
          ).query;
      AuthService.instance.capturePasswordRecovery(
        location: Uri.parse('http://localhost/forgot-password/new#$fragment'),
      );
      expect(AuthService.instance.hasPendingPasswordRecovery, isTrue);

      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"status":"reset"}', 200);
      });
      await http.runWithClient(
        () => AuthService.instance.completePasswordReset(
          password: 'SecurePass123',
          confirmPassword: 'SecurePass123',
        ),
        () => client,
      );

      expect(AuthService.instance.hasPendingPasswordRecovery, isFalse);
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/api/auth/password-reset/complete');
      expect(jsonDecode(requests.single.body), {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'password': 'SecurePass123',
        'confirm_password': 'SecurePass123',
      });
      expect(AuthService.instance.passwordResetAuthSyncPending, isFalse);
    },
  );

  test('phone reset exposes an authentication sync warning', () async {
    final phoneResetToken = List.filled(64, 'b').join();
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/otp/verify') {
        return http.Response(
          jsonEncode({'status': 'verified', 'reset_token': phoneResetToken}),
          200,
        );
      }
      if (request.url.path == '/api/auth/password-reset/complete') {
        return http.Response(
          '{"status":"reset","auth_sync_pending":true}',
          200,
        );
      }
      return http.Response('{"error":"unexpected_request"}', 404);
    });

    await http.runWithClient(() async {
      await AuthService.instance.verifyPasswordResetOtp(
        phone: '+919876543210',
        code: '123456',
      );
      await AuthService.instance.completePasswordReset(
        password: 'SecurePass123',
        confirmPassword: 'SecurePass123',
      );
    }, () => client);

    expect(AuthService.instance.passwordResetAuthSyncPending, isTrue);
    expect(AuthService.instance.hasPendingPasswordReset, isFalse);
  });

  testWidgets('new password is submitted and success screen is shown', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final fragment =
        Uri(
          queryParameters: {
            'access_token': 'recovery-access-token',
            'refresh_token': 'recovery-refresh-token',
            'type': 'recovery',
          },
        ).query;
    AuthService.instance.capturePasswordRecovery(
      location: Uri.parse('http://localhost/forgot-password/new#$fragment'),
    );
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('{"status":"reset"}', 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(_resetTestApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'SecurePass123');
      await tester.enterText(find.byType(TextField).last, 'SecurePass123');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password Reset Successfully!'), findsOneWidget);
      expect(requests, hasLength(1));
      expect(jsonDecode(requests.single.body), {
        'access_token': 'recovery-access-token',
        'refresh_token': 'recovery-refresh-token',
        'password': 'SecurePass123',
        'confirm_password': 'SecurePass123',
      });
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    }, () => client);
  });

  testWidgets('forgot password validates email and requests a reset link', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('{"status":"requested"}', 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const VoteBankerApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        AppPalette.dark.background,
      );
      expect(
        find.text('Enter your registered Email or Mobile Number'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).first, 'not-an-email');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(requests, isEmpty);

      await tester.enterText(
        find.byType(TextField).first,
        'person@example.com',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('If an account exists'), findsOneWidget);
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/api/auth/password-reset/request');
      expect(jsonDecode(requests.single.body), {'email': 'person@example.com'});
    }, () => client);
  });

  testWidgets('phone recovery sends and verifies a real SMS OTP', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final requests = <http.Request>[];
    final phoneResetToken = List.filled(64, 'a').join();
    final client = MockClient((request) async {
      requests.add(request);
      switch (request.url.path) {
        case '/api/auth/otp/send':
          return http.Response('{"status":"sent","channel":"sms"}', 200);
        case '/api/auth/otp/verify':
          return http.Response(
            jsonEncode({'status': 'verified', 'reset_token': phoneResetToken}),
            200,
          );
        case '/api/auth/password-reset/complete':
          return http.Response('{"status":"reset"}', 200);
        default:
          return http.Response('{"error":"unexpected_request"}', 404);
      }
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const VoteBankerApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phone Number'));
      await tester.pumpAndSettle();

      final phoneField = tester.widget<TextField>(find.byType(TextField).first);
      expect(phoneField.decoration?.prefixText, '+91 ');
      await tester.enterText(find.byType(TextField).first, '9876543210');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Verify OTP'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.text('Create New Password'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'SecurePass123');
      await tester.enterText(find.byType(TextField).last, 'SecurePass123');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password Reset Successfully!'), findsOneWidget);
      expect(requests, hasLength(3));
      expect(requests[0].url.path, '/api/auth/otp/send');
      expect(jsonDecode(requests[0].body), {
        'phone': '+919876543210',
        'channel': 'sms',
        'purpose': 'password_reset',
      });
      expect(requests[1].url.path, '/api/auth/otp/verify');
      expect(jsonDecode(requests[1].body), {
        'phone': '+919876543210',
        'code': '123456',
        'purpose': 'password_reset',
      });
      expect(requests[2].url.path, '/api/auth/password-reset/complete');
      expect(jsonDecode(requests[2].body), {
        'reset_token': phoneResetToken,
        'password': 'SecurePass123',
        'confirm_password': 'SecurePass123',
      });
    }, () => client);
  });

  testWidgets('failed email request does not show a success message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final client = MockClient(
      (_) async => http.Response('{"error":"password_reset_unavailable"}', 503),
    );

    await http.runWithClient(() async {
      await tester.pumpWidget(const VoteBankerApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'person@example.com',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Password reset is temporarily unavailable. Please try again later.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('If an account exists for this email'),
        findsNothing,
      );
    }, () => client);
  });
}

Widget _resetTestApp() {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: AppRoutes.resetPassword,
        onGenerateRoute: AppRouter.onGenerateRoute,
        onGenerateInitialRoutes:
            (initialRoute) => [
              AppRouter.onGenerateRoute(RouteSettings(name: initialRoute)),
            ],
      ),
    ),
  );
}
