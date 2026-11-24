import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_browser.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';

class VoterListsScreen extends StatelessWidget {
  const VoterListsScreen({this.recordsUrl, this.redirect, super.key});

  /// Overrides [AppConfig.vrmRecordsUrl] in tests.
  final String? recordsUrl;

  /// Overrides the browser redirect in tests. The signed-in session is left as it is.
  final void Function(String url)? redirect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final page = palette.isDark ? palette.background : const Color(0xFFF5F8FC);
    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            return Column(
              children: [
                _TopBar(
                  wide: wide,
                  onSkip:
                      () =>
                          AppRouter.open(context, AppRoutes.campaignTemplates),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 40 : 20,
                      12,
                      wide ? 40 : 20,
                      28,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _IntroCard(
                          wide: wide,
                          onOpen: () {
                            final target =
                                recordsUrl ?? AppConfig.vrmRecordsUrl;
                            if (target.trim().isEmpty) {
                              AppRouter.open(context, AppRoutes.vrmRecords);
                            } else {
                              openVoterRecords(
                                context,
                                target,
                                redirect: redirect,
                              );
                            }
                          },
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
    );
  }
}

/// Opens the voter records application. A relative address is refused so a
/// local click cannot stay on the current dev port.
Future<void> openVoterRecords(
  BuildContext context,
  String target, {
  void Function(String url)? redirect,
}) async {
  final uri = Uri.tryParse(target.trim());
  final absolute = uri != null && uri.hasScheme && uri.host.isNotEmpty;
  if (!absolute) {
    _showOpenError(context);
    return;
  }
  try {
    (redirect ?? redirectBrowser)(uri.toString());
  } catch (_) {
    _showOpenError(context);
  }
}

void _showOpenError(BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'The voter records page could not be opened. Please try again.',
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.wide, required this.onSkip});

  final bool wide;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('voter-lists-back'),
            tooltip: 'Back',
            onPressed: () => AppRouter.back(context, AppRoutes.blueTik),
            icon: const Icon(Icons.arrow_back),
          ),
          if (wide)
            Expanded(
              child: Text(
                'Get Your Voter Lists',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
            )
          else
            const Spacer(),
          _SkipNowButton(onPressed: onSkip),
          const SizedBox(width: 8),
          SizedBox(
            width: wide ? 168 : 104,
            child: LanguageSelector(maxWidth: wide ? 168 : 104),
          ),
          const SizedBox(width: 8),
          const ThemeToggle(),
        ],
      ),
    );
  }
}

class _SkipNowButton extends StatelessWidget {
  const _SkipNowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground =
        palette.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E3A8A);
    return TextButton(
      key: const Key('voter-lists-skip'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor:
            palette.isDark ? palette.surfaceSecondary : const Color(0xFFEFF6FF),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        overlayColor: const Color(0x332563EB),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: palette.isDark ? palette.border : const Color(0xFFBFDBFE),
          ),
        ),
      ),
      child: const Text('Skip Now'),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.wide, required this.onOpen});

  final bool wide;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: palette.isDark ? palette.border : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color:
                palette.isDark ? palette.cardShadow : const Color(0x14102A56),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          wide ? 32 : 20,
          wide ? 32 : 22,
          wide ? 32 : 20,
          wide ? 28 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Get Your Voter Lists',
              key: const Key('voter-lists-title'),
              style: TextStyle(
                fontSize: wide ? 34 : 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: palette.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Access voter roll records organized by constituency and polling booth.',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            const _InfoRow(
              icon: Icons.account_balance_outlined,
              title: 'Constituency-wise Records',
              detail: 'Find the voter roll for a constituency.',
            ),
            const _InfoRow(
              icon: Icons.how_to_vote_outlined,
              title: 'Booth-wise Records',
              detail: 'Find the voter roll for a polling booth.',
            ),
            const _InfoRow(
              icon: Icons.badge_outlined,
              title: 'Voter Roll Details',
              detail: 'Open the roll details for the area you need.',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                key: const Key('voter-lists-open'),
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Get Your Voter Lists →'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Continue to the Voter Records section.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color:
                  palette.isDark
                      ? palette.surfaceSecondary
                      : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
