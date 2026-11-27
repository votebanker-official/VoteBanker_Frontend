import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/onboarding/data/profile_languages.dart';
import '../../features/onboarding/state/onboarding_controller.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    this.maxWidth = 168,
    this.compact = false,
    this.horizontalPadding,
    super.key,
  });

  final double maxWidth;

  final bool compact;

  /// Overrides the pill's side inset. Null keeps the shared default.
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = OnboardingScope.of(context);
    final code = Localizations.localeOf(context).languageCode;
    final palette = context.palette;
    final current = _languageFor(code);
    final labelStyle = AppTextStyles.label(context).copyWith(fontSize: 13);
    final arrowSize = compact ? 16.0 : 18.0;
    final sideInset = horizontalPadding ?? (compact ? 10.0 : 12.0);
    final textBudget = (maxWidth - sideInset * 2 - arrowSize - 6).clamp(
      72.0,
      maxWidth,
    );

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
        constraints: BoxConstraints(
          minHeight: compact ? 36 : 48,
          maxWidth: maxWidth,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: sideInset,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceSecondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: textBudget),
              child: Text(
                current.nativeName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: arrowSize, color: palette.textMuted),
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
