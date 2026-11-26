import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/app/theme/app_colors.dart';
import 'package:votebanker/features/onboarding/password_reset/password_reset_request.dart';

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

  testWidgets('forgot password continues into channel selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
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
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Your Password'), findsOneWidget);
    expect(find.textContaining('+91 98'), findsWidgets);

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Verify OTP'), findsOneWidget);
  });
}
