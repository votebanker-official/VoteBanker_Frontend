import 'package:flutter/material.dart';

import '../../app/localization/app_languages.dart';
import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/onboarding/state/onboarding_controller.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final code = Localizations.localeOf(context).languageCode;

    return PopupMenuButton<String>(
      tooltip: l10n.language,
      initialValue: code,
      position: PopupMenuPosition.under,
      onSelected: session.setLanguageCode,
      itemBuilder: (context) {
        return [
          for (final language in AppLanguages.all)
            PopupMenuItem<String>(
              value: language.code,
              child: Text(
                language.nativeName,
                style: AppTextStyles.body(context).copyWith(
                  color: language.code == code
                      ? AppColors.primary
                      : AppColors.text,
                  fontWeight: language.code == code
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
        ];
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, maxWidth: 168),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppLanguages.nativeName(code),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(context).copyWith(fontSize: 13),
              ),
            ),
            const Icon(Icons.expand_more, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
