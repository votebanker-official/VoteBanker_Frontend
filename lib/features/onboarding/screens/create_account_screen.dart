import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/language_selector.dart';
import '../screens/otp_login_screen.dart';
import '../state/onboarding_controller.dart';

const _bg = Color(0xFFEAF4FF);
const _navy = Color(0xFF102B50);
const _blue = Color(0xFF1677F2);
const _fieldBorder = Color(0xFF9EC7FF);
const _waveLight = Color(0xFFD9ECFF);
const _waveMid = Color(0xFFCFE6FF);

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  bool _busy = false;
  bool _autoValidate = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    for (final c in [_email, _mobile, _password, _confirmPassword]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_email, _mobile, _password, _confirmPassword]) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your email address.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    if (!ok) return 'Enter a valid email address.';
    return null;
  }

  String? _validateMobile(String? value) {
    final phone = AuthService.normalizePhone((value ?? '').trim());
    if (phone == null) return 'Enter a valid mobile number.';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password.';
    if (v.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Include at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return 'Include at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number.';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/\[\]`~+=;]').hasMatch(v)) {
      return 'Include at least one special character.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirm your password.';
    if (value != _password.text) return 'Passwords do not match.';
    return null;
  }

  bool get _formReady {
    return _validateEmail(_email.text) == null &&
        _validateMobile(_mobile.text) == null &&
        _validatePassword(_password.text) == null &&
        _validateConfirm(_confirmPassword.text) == null &&
        _termsAccepted;
  }

  Future<void> _createAccount() async {
    setState(() {
      _autoValidate = true;
      _submitError = null;
    });
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || !_termsAccepted) {
      if (!_termsAccepted) {
        setState(() => _submitError = 'Please accept the Terms & Conditions.');
      }
      return;
    }
    final phone = AuthService.normalizePhone(_mobile.text.trim());
    if (phone == null) {
      setState(() => _submitError = 'Enter a valid mobile number.');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.instance.sendOtp(phone);
      if (!mounted) return;
      final draft = OnboardingScope.of(context).draft;
      draft.email = _email.text.trim();
      draft.contactNumber = phone;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.otp,
        arguments: OtpLoginArgs(
          phone: phone,
          codeSent: true,
          signupEmail: _email.text.trim(),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _submitError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _submitError =
                  'Could not send verification code. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF4FF), Color(0xFFEAF4FF)],
              ),
            ),
          ),
          const Positioned.fill(child: _BottomWave()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final isMobile = w < 600;
                final isTablet = w >= 600 && w < 1024;
                final horizontal = isMobile ? 16.0 : 24.0;
                final cardMaxWidth =
                    isMobile
                        ? (w - 40).clamp(280.0, 360.0)
                        : (isTablet ? 430.0 : 470.0);
                final logoSize = isMobile ? 64.0 : (isTablet ? 74.0 : 82.0);
                final titleSize = isMobile ? 18.0 : 22.0;
                final headingSize = isMobile ? 24.0 : 30.0;
                final subtitleSize = isMobile ? 13.5 : 15.0;
                final topGap = isMobile ? 8.0 : 14.0;
                final fieldWidthFactor = 1.0;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        8,
                        horizontal,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BackButton(
                            onPressed:
                                _busy
                                    ? null
                                    : () => AppRouter.back(
                                      context,
                                      AppRoutes.login,
                                    ),
                          ),
                          const Spacer(),
                          const LanguageSelector(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16 : horizontal,
                          topGap,
                          isMobile ? 16 : horizontal,
                          isMobile ? 20 : 28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BrandLockup(
                                  logoSize: logoSize,
                                  titleSize: titleSize,
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                _FormCard(
                                  isMobile: isMobile,
                                  child: Form(
                                    key: _formKey,
                                    autovalidateMode:
                                        _autoValidate
                                            ? AutovalidateMode.onUserInteraction
                                            : AutovalidateMode.disabled,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Create Your Account',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _blue,
                                            fontSize: headingSize,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Join Vote Banker today',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: const Color(0xFF5E7391),
                                            fontSize: subtitleSize,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: isMobile ? 16 : 20),
                                        Center(
                                          child: FractionallySizedBox(
                                            widthFactor: fieldWidthFactor,
                                            child: _SignupField(
                                              controller: _email,
                                              hint: 'Email Address',
                                              icon: Icons.mail_outline_rounded,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: _validateEmail,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: FractionallySizedBox(
                                            widthFactor: fieldWidthFactor,
                                            child: _SignupField(
                                              controller: _mobile,
                                              hint: 'Mobile Number',
                                              icon: Icons.phone_outlined,
                                              keyboardType: TextInputType.phone,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: _validateMobile,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: FractionallySizedBox(
                                            widthFactor: fieldWidthFactor,
                                            child: _SignupField(
                                              controller: _password,
                                              hint: 'Password',
                                              icon: Icons.lock_outline_rounded,
                                              obscureText: _obscurePassword,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: _validatePassword,
                                              suffix: IconButton(
                                                onPressed:
                                                    () => setState(
                                                      () =>
                                                          _obscurePassword =
                                                              !_obscurePassword,
                                                    ),
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: const Color(
                                                    0xFF4A78C9,
                                                  ),
                                                ),
                                                tooltip:
                                                    _obscurePassword
                                                        ? 'Show password'
                                                        : 'Hide password',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: FractionallySizedBox(
                                            widthFactor: fieldWidthFactor,
                                            child: _SignupField(
                                              controller: _confirmPassword,
                                              hint: 'Confirm Password',
                                              icon: Icons.lock_outline_rounded,
                                              obscureText: _obscureConfirm,
                                              textInputAction:
                                                  TextInputAction.done,
                                              validator: _validateConfirm,
                                              onFieldSubmitted: (_) {
                                                if (_formReady && !_busy) {
                                                  _createAccount();
                                                }
                                              },
                                              suffix: IconButton(
                                                onPressed:
                                                    () => setState(
                                                      () =>
                                                          _obscureConfirm =
                                                              !_obscureConfirm,
                                                    ),
                                                icon: Icon(
                                                  _obscureConfirm
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: const Color(
                                                    0xFF4A78C9,
                                                  ),
                                                ),
                                                tooltip:
                                                    _obscureConfirm
                                                        ? 'Show password'
                                                        : 'Hide password',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: Checkbox(
                                                value: _termsAccepted,
                                                onChanged:
                                                    _busy
                                                        ? null
                                                        : (v) => setState(
                                                          () =>
                                                              _termsAccepted =
                                                                  v ?? false,
                                                        ),
                                                activeColor: _blue,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                side: const BorderSide(
                                                  color: Color(0xFF8FB8F0),
                                                  width: 1.3,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap:
                                                    _busy
                                                        ? null
                                                        : () => setState(
                                                          () =>
                                                              _termsAccepted =
                                                                  !_termsAccepted,
                                                        ),
                                                child: RichText(
                                                  text: const TextSpan(
                                                    style: TextStyle(
                                                      color: _navy,
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.3,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: 'I agree to ',
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            'Terms & Conditions',
                                                        style: TextStyle(
                                                          color: _blue,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_submitError != null) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            _submitError!,
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        SizedBox(height: isMobile ? 14 : 16),
                                        Center(
                                          child: FractionallySizedBox(
                                            widthFactor: fieldWidthFactor,
                                            child: _CreateAccountButton(
                                              label:
                                                  _busy
                                                      ? 'Please wait...'
                                                      : 'Create Account',
                                              enabled: _formReady && !_busy,
                                              busy: _busy,
                                              onPressed:
                                                  _busy ? null : _createAccount,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: FractionallySizedBox(
                                            widthFactor: fieldWidthFactor,
                                            child: Row(
                                              children: [
                                                const Expanded(
                                                  child: Divider(
                                                    color: Color(0xFFD7E6F7),
                                                    thickness: 1,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                      ),
                                                  child: Text(
                                                    'Or',
                                                    style: TextStyle(
                                                      color: _navy.withValues(
                                                        alpha: 0.55,
                                                      ),
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const Expanded(
                                                  child: Divider(
                                                    color: Color(0xFFD7E6F7),
                                                    thickness: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              'Already have an account? ',
                                              style: TextStyle(
                                                color: _navy.withValues(
                                                  alpha: 0.78,
                                                ),
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap:
                                                  _busy
                                                      ? null
                                                      : () => AppRouter.back(
                                                        context,
                                                        AppRoutes.login,
                                                      ),
                                              child: const Text(
                                                'Login',
                                                style: TextStyle(
                                                  color: _blue,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_busy)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: _blue,
                  backgroundColor: Color(0xFFDCEBFF),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomWave extends StatelessWidget {
  const _BottomWave();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _BottomWavePainter()));
  }
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(0, size.height * 0.80)
          ..quadraticBezierTo(
            size.width * 0.22,
            size.height * 0.70,
            size.width * 0.48,
            size.height * 0.82,
          )
          ..quadraticBezierTo(
            size.width * 0.76,
            size.height * 0.95,
            size.width,
            size.height * 0.84,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    final fill =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_waveLight, _waveMid],
          ).createShader(
            Rect.fromLTWH(
              0,
              size.height * 0.65,
              size.width,
              size.height * 0.35,
            ),
          );
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.logoSize, required this.titleSize});

  final double logoSize;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          AppAssets.logo,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 8),
        Text(
          'VOTE BANKER',
          style: TextStyle(
            color: const Color(0xFF0F5EDB),
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child, required this.isMobile});

  final Widget child;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 22,
        isMobile ? 18 : 22,
        isMobile ? 16 : 22,
        isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2B6CB0),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x0D1E5AA8),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back, color: Color(0xFF1677F2), size: 28),
      splashRadius: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.suffix,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
    );
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: _navy,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: _navy.withValues(alpha: 0.42),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: _blue, size: 22),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF7FBFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        isDense: true,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton({
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final gradient =
        enabled
            ? const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF2196F3), Color(0xFF0875F5)],
            )
            : const LinearGradient(
              colors: [Color(0xFF8EC5F7), Color(0xFF7BB6F3)],
            );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow:
            enabled
                ? const [
                  BoxShadow(
                    color: Color(0x332774E8),
                    blurRadius: 14,
                    offset: Offset(0, 7),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            height: 52,
            child: Center(
              child:
                  busy
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
