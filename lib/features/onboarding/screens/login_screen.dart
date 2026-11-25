import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/services/auth_browser.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/onboarding_progress_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/utils/person_name.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../website/services/portfolio_store.dart';
import '../../website/services/website_builder_store.dart';
import '../../merchandise/merchandise_intent.dart';
import '../blue_tik/blue_tik_models.dart';
import '../../privacy/legal_consent_line.dart';
import '../state/onboarding_controller.dart';

const _navy = Color(0xFF102B50);
const _blue = Color(0xFF1677F2);
const _page = Color(0xFFEDF6FF);
const _field = Color(0xFFDCEEFF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSocialReturn());
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _finishSocialReturn() async {
    final pending = AuthService.instance.takeSocialReturn();
    final error =
        pending.error ??
        AuthService.instance.socialLaunchError ??
        takeSessionValue('vb_auth_error');
    final ticket =
        (pending.ticket != null && pending.ticket!.isNotEmpty)
            ? pending.ticket
            : takeSessionValue('vb_auth_ticket');
    AuthService.instance.socialLaunchError = null;
    if ((error == null || error.isEmpty) &&
        (ticket == null || ticket.isEmpty)) {
      return;
    }
    clearAuthQuery();
    if (!mounted) return;
    if (error != null && error.isNotEmpty) {
      _showMessage(_messageFor(AppLocalizations.of(context), error));
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthService.instance.exchangeSocialTicket(ticket!);
      if (!mounted) return;
      final draft = OnboardingScope.of(context).draft;
      final savedProfile = await ProfileService.instance.fetchProfile();
      if (!mounted) return;
      if (savedProfile != null) {
        ProfileService.applyProfile(draft, savedProfile);
      }
      final fullName = formatPersonName(
        AuthService.instance.session?.fullName ?? '',
      );
      if (draft.fullName.trim().isEmpty && fullName.isNotEmpty) {
        draft.fullName = fullName;
        await ProfileService.instance.saveDraft(draft);
      }
      if (!mounted) return;
      final resume =
          await OnboardingProgressService.instance.resolveResumeRoute();
      final next = await routeAfterBlueTikSignIn(resume);
      if (!mounted) return;
      replaceBrowserPath(next);
      Navigator.of(context).pushReplacementNamed(next);
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(AppLocalizations l10n, String code) {
    switch (code) {
      case 'social_not_configured':
        return l10n.socialNotConfigured;
      case 'social_denied':
        return l10n.socialDenied;
      case 'google_secret_invalid':
        return 'Google rejected the sign-in before your name and email could be saved. '
            'In Google Cloud Console, copy the OAuth client secret into GOOGLE_CLIENT_SECRET. '
            'It must be different from the client id. Restart the API, then try again.';
      case 'social_failed':
        return l10n.socialFailed;
      default:
        return l10n.socialFailed;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startSocial(AppLocalizations l10n, String provider) async {
    if (_busy) return;
    if (!kIsWeb) {
      _showMessage(l10n.socialWebOnly);
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.startSocial(provider);
    } on AuthException catch (e) {
      if (mounted) setState(() => _busy = false);
      _showMessage(e.message);
    }
  }

  /// Guest path: drop any restored session and cached drafts so onboarding
  /// cannot fetch or reuse another account's profile, including a name that
  /// Facebook filled in before the user chose Skip for now.
  void _skipForNow() {
    if (_busy) return;
    final hadSession = AuthService.instance.isSignedIn;
    final onboarding = OnboardingScope.of(context);
    final socialName = formatPersonName(
      AuthService.instance.session?.fullName ?? '',
    );
    if (socialName.isNotEmpty &&
        formatPersonName(onboarding.draft.leaderName) == socialName) {
      onboarding.draft.leaderName = '';
    }
    AuthService.instance.openProfileAfterLogin = false;
    AuthService.instance.session = null;
    if (hadSession) {
      onboarding.clearForGuestSkip();
    } else {
      onboarding.ignoreStoredWebsiteDrafts = true;
      onboarding.resetWebsiteFromProfile();
    }
    unawaited(BlueTikIntent.clear());
    unawaited(MerchandiseIntent.clear());
    unawaited(AuthService.instance.signOut());
    unawaited(WebsiteBuilderStore.instance.clearLocal());
    unawaited(PortfolioStore.instance.clear());
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.profile, (route) => false);
  }

  void _openOtp({String? phone}) {
    if (_busy) return;
    AppRouter.open(context, AppRoutes.otp, arguments: phone ?? 'whatsapp');
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (_busy) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final raw = _identifier.text.trim();
    final password = _password.text;
    if (password.isEmpty) {
      setState(() => _formError = 'Enter your password.');
      return;
    }

    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      await AuthService.instance.login(identifier: raw, password: password);
      if (!mounted) return;
      final draft = OnboardingScope.of(context).draft;
      final savedProfile = await ProfileService.instance.fetchProfile();
      if (!mounted) return;
      if (savedProfile != null) {
        ProfileService.applyProfile(draft, savedProfile);
      }
      final email = AuthService.instance.signedInEmail;
      if (email.isNotEmpty) draft.email = email;
      final phone = AuthService.instance.session?.phone ?? '';
      if (phone.trim().isNotEmpty) draft.contactNumber = phone.trim();
      if (savedProfile != null) {
        await ProfileService.instance.saveDraft(draft);
      }
      if (!mounted) return;
      final resume =
          await OnboardingProgressService.instance.resolveResumeRoute();
      final next = await routeAfterBlueTikSignIn(resume);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(next);
    } on AuthException catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _formError = 'Could not sign in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mobileShell = MediaQuery.sizeOf(context).width < 601;

    return Scaffold(
      backgroundColor: mobileShell ? const Color(0xFFF4F9FE) : _page,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 48 || constraints.maxHeight < 48) {
              return const SizedBox.shrink();
            }
            final width = constraints.maxWidth;
            final desktop = width > 1024;
            final tablet = width >= 601 && width <= 1024;
            if (!desktop && !tablet) {
              return _MobileLoginBody(busy: _busy, child: _mobileForm(l10n));
            }
            return Stack(
              children: [
                const Positioned.fill(child: _WaveBackground()),
                Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ThemeToggle(),
                            SizedBox(width: 8),
                            LanguageSelector(),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          desktop
                              ? _DesktopLogin(
                                form: _form(
                                  l10n,
                                  compact: false,
                                  showBrand: false,
                                ),
                                l10n: l10n,
                              )
                              : _TabletLogin(
                                form: _form(
                                  l10n,
                                  compact: false,
                                  showBrand: false,
                                ),
                                l10n: l10n,
                              ),
                    ),
                  ],
                ),
                if (_busy)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: _blue,
                      backgroundColor: _field,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _form(
    AppLocalizations l10n, {
    required bool compact,
    bool showBrand = true,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBrand) ...[
            const _BrandLockup(),
            SizedBox(height: compact ? 16 : 22),
          ],
          Text(
            l10n.loginWelcome,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _blue,
              fontSize: compact ? 22 : 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.loginJourney,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 16 : 22),
          _LoginField(
            controller: _identifier,
            hint: l10n.loginIdentifier,
            icon: Icons.mail_outline_rounded,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email or mobile number.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _LoginField(
            controller: _password,
            hint: l10n.loginPassword,
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(l10n),
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF7E93AD),
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your password.';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  _busy
                      ? null
                      : () => AppRouter.open(context, AppRoutes.forgotPassword),
              child: Text(
                l10n.loginForgot,
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (_formError != null) ...[
            Text(
              _formError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD92D3F), fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B8BFF), Color(0xFF1677F2)],
                ),
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _busy ? null : () => _submit(l10n),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.loginAction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFD5E4F4))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Color(0xFF8AA0B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFD5E4F4))),
            ],
          ),
          const SizedBox(height: 12),
          _SocialButton(
            label: l10n.continueFacebook,
            leading: const _FacebookMark(),
            onPressed: _busy ? null : () => _startSocial(l10n, 'facebook'),
          ),
          const SizedBox(height: 10),
          _SocialButton(
            label: l10n.continueWhatsApp,
            leading: const _WhatsAppMark(),
            onPressed: _busy ? null : () => _openOtp(),
          ),
          const SizedBox(height: 10),
          _SocialButton(
            label: l10n.continueGoogle,
            leading: const _GoogleMark(),
            onPressed: _busy ? null : () => _startSocial(l10n, 'google'),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.loginSignUpPrompt,
                style: const TextStyle(color: _navy, fontSize: 13.5),
              ),
              TextButton(
                onPressed:
                    _busy
                        ? null
                        : () => AppRouter.open(context, AppRoutes.signUp),
                child: Text(
                  l10n.loginSignUp,
                  style: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const LegalConsentLine(),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _busy ? null : _skipForNow,
            child: Text(l10n.skipForNow),
          ),
        ],
      ),
    );
  }

  Widget _mobileForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Welcome to Vote Banker!',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: Color(0xFF16325C),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Login to continue your journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1A3A66),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          const _CurveUnderline(),
          const SizedBox(height: 18),
          _LoginField(
            controller: _identifier,
            hint: 'Username',
            icon: Icons.person_outline_rounded,
            iconColor: _blue,
            divided: true,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email or mobile number.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _LoginField(
            controller: _password,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            iconColor: _blue,
            divided: true,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(l10n),
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9AADC2),
                size: 22,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your password.';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  _busy
                      ? null
                      : () => AppRouter.open(context, AppRoutes.forgotPassword),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.loginForgot,
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 6),
            Text(
              _formError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD92D3F), fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C9BFF), Color(0xFF1677F2)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x401677F2),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _busy ? null : () => _submit(l10n),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE3EDF6), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Or',
                  style: TextStyle(
                    color: Color(0xFF8AA0B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE3EDF6), thickness: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundSocial(
                onPressed: _busy ? null : () => _startSocial(l10n, 'facebook'),
                child: const _FacebookMark(size: 48),
              ),
              const SizedBox(width: 22),
              _RoundSocial(
                onPressed: _busy ? null : () => _openOtp(),
                child: const _WhatsAppMark(size: 48),
              ),
              const SizedBox(width: 22),
              _RoundSocial(
                onPressed: _busy ? null : () => _startSocial(l10n, 'google'),
                child: const _GoogleMark(size: 48),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${l10n.loginSignUpPrompt} ',
                style: const TextStyle(
                  color: Color(0xFF1A3A66),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap:
                    _busy
                        ? null
                        : () => AppRouter.open(context, AppRoutes.signUp),
                child: Text(
                  l10n.loginSignUp,
                  style: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _busy ? null : _skipForNow,
            child: Text(
              l10n.skipForNow,
              style: const TextStyle(
                color: _blue,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopLogin extends StatelessWidget {
  const _DesktopLogin({required this.form, required this.l10n});

  final Widget form;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 36, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: const Alignment(0, -0.72),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: _BrandHero(l10n: l10n, large: true),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _LoginCard(child: form),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletLogin extends StatelessWidget {
  const _TabletLogin({required this.form, required this.l10n});

  final Widget form;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: const Alignment(0, -0.72),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: _BrandHero(l10n: l10n, large: true),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _LoginCard(child: form),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.l10n, required this.large});

  final AppLocalizations l10n;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final lines = l10n.loginHeroTitle.split('\n');
    final first = lines.first;
    final second = lines.length > 1 ? lines.last : '';
    final titleSize = large ? 40.0 : 28.0;
    return Column(
      children: [
        _BrandLockup(large: large),
        SizedBox(height: large ? 28 : 16),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$first\n', style: const TextStyle(color: _navy)),
              TextSpan(text: second, style: const TextStyle(color: _blue)),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        const _CurveUnderline(),
        SizedBox(height: large ? 22 : 16),
        const _CompanyPill(),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1677F2),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
        child: child,
      ),
    );
  }
}

class _CurveUnderline extends StatelessWidget {
  const _CurveUnderline();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 108,
      height: 14,
      child: CustomPaint(painter: _UnderlinePainter()),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  const _UnderlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF2F7CFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;
    final path =
        Path()
          ..moveTo(size.width * 0.06, size.height * 0.35)
          ..quadraticBezierTo(
            size.width * 0.5,
            size.height * 1.05,
            size.width * 0.94,
            size.height * 0.28,
          );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompanyPill extends StatelessWidget {
  const _CompanyPill();

  static const _name = 'Voter Relationship Management Private Limited';

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFD9ECFF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_rounded, color: _blue, size: 22),
              Container(
                width: 1.2,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: const Color(0xFF7EB6F5),
              ),
              Flexible(
                child: Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 84.0 : 64.0;
    return Column(
      children: [
        Image.asset(
          AppAssets.logo,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).appName,
          style: TextStyle(
            color: _navy,
            fontSize: large ? 22 : 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.iconColor = const Color(0xFF8AA0B8),
    this.divided = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Color iconColor;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(color: _navy, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8AA0B8)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon:
            divided
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 14),
                    Icon(icon, color: iconColor, size: 22),
                    Container(
                      width: 1,
                      height: 22,
                      margin: const EdgeInsets.only(left: 10),
                      color: const Color(0xFFD7E6F5),
                    ),
                  ],
                )
                : Icon(icon, color: iconColor, size: 20),
        prefixIconConstraints:
            divided ? const BoxConstraints(minWidth: 58, minHeight: 48) : null,
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(vertical: divided ? 16 : 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _field),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _blue, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD92D3F)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD92D3F)),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onPressed,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: _navy,
          side: const BorderSide(color: Color(0xFFD7E8F8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            SizedBox(width: 22, height: 22, child: leading),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}

class _FacebookMark extends StatelessWidget {
  const _FacebookMark({this.size = 22});

  final double size;

  static const _svg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="12" fill="#1877F2"/>
  <path fill="#fff" d="M13.3 19v-5.9h2l.3-2.3h-2.3V9.3c0-.7.2-1.1 1.2-1.1h1.3V6.1c-.2 0-.9-.1-1.6-.1-1.6 0-2.7 1-2.7 2.8v1.9H9.2v2.3h2.2V19h1.9z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

class _WhatsAppMark extends StatelessWidget {
  const _WhatsAppMark({this.size = 22});

  final double size;

  static const _svg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="12" fill="#25D366"/>
  <path fill="#fff" d="M12 5.4c-3.6 0-6.5 2.9-6.5 6.5 0 1.1.3 2.2.9 3.2L5.6 18.6l3.6-1.1c.9.5 1.9.8 2.8.8 3.6 0 6.5-2.9 6.5-6.5S15.6 5.4 12 5.4zm3.7 9c-.2.4-.9.8-1.2.8-.3.1-.6.1-1.9-.4-1.6-.6-2.7-2.1-2.8-2.2-.1-.1-.6-.8-.6-1.6s.4-1.2.6-1.4c.1-.2.3-.2.5-.2h.3c.1 0 .3 0 .4.3.2.4.5 1.3.6 1.4.1.1.1.2 0 .4-.1.1-.1.2-.2.3l-.2.3c0 .1 0 .2.1.3.1.2.4.7.9 1.2.6.5 1.2.8 1.4.9.2.1.3.1.4-.1.1-.1.4-.5.5-.7.1-.2.3-.1.4-.1.2 0 1 .5 1.2.6.2.1.3.1.3.2 0 .2 0 .4-.2.8z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({this.size = 20});

  final double size;

  static const _svg = '''
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
  <path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
  <path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238C29.211 35.091 26.715 36 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
  <path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571.001-.001.002-.001.003-.002l6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

class _RoundSocial extends StatelessWidget {
  const _RoundSocial({required this.child, required this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkResponse(onTap: onPressed, radius: 28, child: child);
  }
}

class _MobileLoginBody extends StatelessWidget {
  const _MobileLoginBody({required this.child, required this.busy});

  final Widget child;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _MobileWavePainter()),
        ),
        Column(
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThemeToggle(),
                    SizedBox(width: 8),
                    LanguageSelector(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                child: Column(
                  children: [
                    const _BrandLockup(),
                    const SizedBox(height: 16),
                    const _MobileCompanyBanner(),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x141677F2),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (busy)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: _blue,
              backgroundColor: _field,
            ),
          ),
      ],
    );
  }
}

class _MobileCompanyBanner extends StatelessWidget {
  const _MobileCompanyBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F3FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.groups_rounded, color: _blue, size: 26),
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: SizedBox(
                width: 1.2,
                height: 26,
                child: ColoredBox(color: Color(0xFF8EC0F6)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Voter Relationship Management Private Limited',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _navy,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileWavePainter extends CustomPainter {
  const _MobileWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF5FAFE),
    );
    final sky = Paint()..color = const Color(0xFFD7EEFF);
    final path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(0, size.height * 0.20)
          ..quadraticBezierTo(
            size.width * 0.62,
            size.height * 0.34,
            size.width,
            size.height * 0.12,
          )
          ..lineTo(size.width, 0)
          ..close();
    canvas.drawPath(path, sky);

    final bottom =
        Path()
          ..moveTo(0, size.height * 0.78)
          ..quadraticBezierTo(
            size.width * 0.28,
            size.height * 0.64,
            size.width * 0.55,
            size.height * 0.84,
          )
          ..quadraticBezierTo(
            size.width * 0.82,
            size.height,
            size.width,
            size.height * 0.86,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    canvas.drawPath(bottom, Paint()..color = const Color(0xFFD4EAFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveBackground extends StatelessWidget {
  const _WaveBackground();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _WavePainter());
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()..color = const Color(0xFFD7ECFF);
    final top =
        Path()
          ..moveTo(0, size.height * 0.16)
          ..quadraticBezierTo(
            size.width * 0.22,
            size.height * 0.02,
            size.width * 0.48,
            size.height * 0.1,
          )
          ..quadraticBezierTo(
            size.width * 0.78,
            size.height * 0.2,
            size.width,
            size.height * 0.04,
          )
          ..lineTo(size.width, 0)
          ..lineTo(0, 0)
          ..close();
    canvas.drawPath(top, soft);

    final bottom =
        Path()
          ..moveTo(0, size.height * 0.72)
          ..quadraticBezierTo(
            size.width * 0.28,
            size.height * 0.58,
            size.width * 0.55,
            size.height * 0.78,
          )
          ..quadraticBezierTo(
            size.width * 0.82,
            size.height * 0.98,
            size.width,
            size.height * 0.82,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    canvas.drawPath(bottom, soft..color = const Color(0xFFD4EAFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
