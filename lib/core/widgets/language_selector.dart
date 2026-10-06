import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/onboarding/data/profile_languages.dart';
import '../../features/onboarding/state/onboarding_controller.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final saved = session.draft.preferredLanguage;
    final code =
        ProfileLanguages.supports(saved)
            ? saved
            : Localizations.localeOf(context).languageCode;
    final palette = context.palette;
    final current = _languageFor(code);

    return PopupMenuButton<String>(
      tooltip: l10n.language,
      initialValue: current.code,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(maxHeight: 360, minWidth: 240),
      onSelected: session.setLanguageCode,
      itemBuilder: (context) {
        return [
          for (final language in ProfileLanguages.all)
            PopupMenuItem<String>(
              value: language.code,
              child: Text(
                language.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: language.code == code ? palette.accent : palette.text,
                  fontWeight:
                      language.code == code ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
        ];
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, maxWidth: 168),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surfaceSecondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: palette.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                current.nativeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(context).copyWith(fontSize: 13),
              ),
            ),
            Icon(Icons.expand_more, size: 18, color: palette.textMuted),
          ],
        ),
      ),
    );
  }

  ProfileLanguage _languageFor(String code) {
    for (final language in ProfileLanguages.all) {
      if (language.code == code) {
        return language;
      }
    }
    return ProfileLanguages.all.first;
  }
}
