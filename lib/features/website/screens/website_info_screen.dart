import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/onboarding_actions.dart';
import '../../onboarding/widgets/onboarding_frame.dart';
import '../widgets/website_language_field.dart';

class WebsiteInfoScreen extends StatefulWidget {
  const WebsiteInfoScreen({super.key});

  @override
  State<WebsiteInfoScreen> createState() => _WebsiteInfoScreenState();
}

class _WebsiteInfoScreenState extends State<WebsiteInfoScreen> {
  final _description = TextEditingController();
  final _focus = FocusNode();
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) {
      return;
    }
    final session = OnboardingScope.of(context);
    session.website.seedFromProfile(session.draft);
    _description.text = session.website.description;
    _ready = true;
  }

  @override
  void dispose() {
    _description.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    final session = OnboardingScope.of(context);
    final l10n = AppLocalizations.of(context);
    session.website.description = _description.text;
    final result = await session.websiteServices.speech.listen(
      languageCode: session.website.inputLanguage,
    );
    if (!mounted) {
      return;
    }
    if (result.connected && result.transcript != null) {
      setState(() {
        final current = _description.text.trim();
        _description.text = current.isEmpty
            ? result.transcript!
            : '$current ${result.transcript!}';
        session.website.description = _description.text;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.line('voiceUnavailable'))),
    );
    _focus.requestFocus();
  }

  void _continue() {
    OnboardingScope.of(context).website.description = _description.text.trim();
    AppRouter.open(context, AppRoutes.websiteQuestions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final website = OnboardingScope.of(context).website;

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.line('websiteInfoTitle'),
              description: l10n.line('websiteInfoBody'),
            ),
            const SizedBox(height: 18),
            WebsiteLanguageField(
              label: l10n.line('inputLanguageLabel'),
              value: website.inputLanguage,
              onChanged: (code) => setState(() {
                website.inputLanguage = code;
                website.languagesReady = true;
              }),
            ),
            const SizedBox(height: 14),
            WebsiteLanguageField(
              label: l10n.line('websiteLanguageLabel'),
              value: website.websiteLanguage,
              onChanged: (code) => setState(() {
                website.websiteLanguage = code;
                website.languagesReady = true;
              }),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.line('websiteDescribeHint'),
              style: AppTextStyles.muted(context),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _description,
                    focusNode: _focus,
                    minLines: 6,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.body(context),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: l10n.line('websiteDescribeHint'),
                    ),
                    onChanged: (value) => website.description = value,
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: l10n.line('voiceInput'),
                  child: Material(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: _listen,
                      iconSize: 32,
                      icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
                      tooltip: l10n.line('voiceInput'),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _focus.requestFocus,
                child: Text(l10n.line('typeInstead')),
              ),
            ),
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () {
                website.description = _description.text.trim();
                AppRouter.back(context, AppRoutes.website);
              },
              primaryLabel: l10n.line('continueAction'),
              onPrimary: _continue,
              skipLabel: l10n.skipForNow,
              onSkip: () => AppRouter.open(context, AppRoutes.social),
            ),
          ],
        ),
      ),
    );
  }
}
