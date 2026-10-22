import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_actions.dart';
import '../widgets/onboarding_frame.dart';
import 'vrm_setup_agent_log.dart';

class VrmSetupScreen extends StatelessWidget {
  const VrmSetupScreen({super.key});

  void _continue(BuildContext context) {
    OnboardingScope.of(context).draft.vrmRequested = true;
    AppRouter.open(context, AppRoutes.ready);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = <(IconData, String)>[
      (Icons.contacts_outlined, l10n.vrmPointContacts),
      (Icons.groups_outlined, l10n.vrmPointTeam),
      (Icons.assignment_outlined, l10n.vrmPointIssues),
    ];

    return OnboardingFrame(
      centerChild: true,
      child: _VrmCardProbe(
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingHeader(
                compact: true,
                centerTitle: true,
                title: l10n.vrmTitle,
                description: '${l10n.optionalLabel}. ${l10n.vrmBody}',
              ),
              const SizedBox(height: 18),
              for (final point in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(point.$1, color: context.palette.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(point.$2, style: AppTextStyles.body(context)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              OnboardingActions(
                backLabel: l10n.back,
                onBack: () => AppRouter.back(context, AppRoutes.social),
                primaryLabel: l10n.vrmSetup,
                onPrimary: () => _continue(context),
                skipLabel: l10n.skipForNow,
                onSkip: () => AppRouter.open(context, AppRoutes.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// #region agent log
class _VrmCardProbe extends StatefulWidget {
  const _VrmCardProbe({required this.child});

  final Widget child;

  @override
  State<_VrmCardProbe> createState() => _VrmCardProbeState();
}

class _VrmCardProbeState extends State<_VrmCardProbe> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_logPosition);
  }

  void _logPosition(_) {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final origin = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context);
    final cardBottom = origin.dy + box.size.height;
    final scrollable = Scrollable.maybeOf(context);
    final position = scrollable?.position;
    final maxScroll = position != null && position.hasContentDimensions
        ? position.maxScrollExtent
        : -1.0;
    vrmAgentLog('A', 'card position versus viewport', {
      'cardTop': origin.dy,
      'cardLeft': origin.dx,
      'cardWidth': box.size.width,
      'cardHeight': box.size.height,
      'cardCenterX': origin.dx + box.size.width / 2,
      'cardCenterY': origin.dy + box.size.height / 2,
      'screenWidth': screen.width,
      'screenHeight': screen.height,
      'screenCenterX': screen.width / 2,
      'screenCenterY': screen.height / 2,
      'gapAbove': origin.dy,
      'gapBelow': screen.height - cardBottom,
      'maxScrollExtent': maxScroll,
    });
    _logControls(screen);
  }

  void _logControls(Size screen) {
    Element? root;
    context.visitAncestorElements((element) {
      root = element;
      return true;
    });
    if (root == null) return;
    RenderBox? languageBox;
    RenderBox? themeBox;
    void walk(Element element) {
      final widget = element.widget;
      final render = element.renderObject;
      if (render is RenderBox && render.hasSize && render.attached) {
        if (widget is LanguageSelector) languageBox = render;
        if (widget is ThemeToggle) themeBox = render;
      }
      element.visitChildren(walk);
    }

    walk(root!);
    final language = languageBox;
    final theme = themeBox;
    if (language == null || theme == null) return;
    final languageOrigin = language.localToGlobal(Offset.zero);
    final themeOrigin = theme.localToGlobal(Offset.zero);
    vrmAgentLog('C', 'theme and language control position', {
      'themeTop': themeOrigin.dy,
      'themeLeft': themeOrigin.dx,
      'themeWidth': theme.size.width,
      'themeHeight': theme.size.height,
      'languageTop': languageOrigin.dy,
      'languageLeft': languageOrigin.dx,
      'languageRight': languageOrigin.dx + language.size.width,
      'languageHeight': language.size.height,
      'screenWidth': screen.width,
      'screenHeight': screen.height,
      'sameRow': (themeOrigin.dy - languageOrigin.dy).abs() < 2,
      'themeIsLeftOfLanguage': themeOrigin.dx + theme.size.width <= languageOrigin.dx + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        vrmAgentLog('B', 'constraints passed to the setup card', {
          'minWidth': constraints.minWidth,
          'maxWidth': constraints.hasBoundedWidth ? constraints.maxWidth : -1,
          'minHeight': constraints.minHeight,
          'maxHeight': constraints.hasBoundedHeight ? constraints.maxHeight : -1,
          'heightBounded': constraints.hasBoundedHeight,
        });
        return widget.child;
      },
    );
  }
}
// #endregion
