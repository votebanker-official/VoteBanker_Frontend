import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/onboarding_frame.dart';

class WebsiteGeneratingScreen extends StatefulWidget {
  const WebsiteGeneratingScreen({super.key});

  @override
  State<WebsiteGeneratingScreen> createState() => _WebsiteGeneratingScreenState();
}

class _WebsiteGeneratingScreenState extends State<WebsiteGeneratingScreen> {
  static const _stages = <String>[
    'genStyle',
    'genInfo',
    'genLanguage',
    'genContent',
    'genPreview',
  ];

  var _done = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    for (var step = 1; step <= _stages.length; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) {
        return;
      }
      setState(() => _done = step);
    }
    final session = OnboardingScope.of(context);
    final preview = await session.websiteServices.generation.generate(session.website);
    if (!mounted) {
      return;
    }
    session.website.preview = preview;
    AppRouter.replace(context, AppRoutes.websitePreview);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.line('generatingTitle'),
              description: l10n.line('generatingBody'),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < _stages.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      i < _done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: i < _done ? AppColors.secondary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.line(_stages[i]),
                        style: AppTextStyles.body(context),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
