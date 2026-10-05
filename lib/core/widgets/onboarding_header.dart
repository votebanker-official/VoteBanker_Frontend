import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_text_styles.dart';
import '../constants/app_assets.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    required this.title,
    this.description,
    this.compact = false,
    super.key,
  });

  final String title;
  final String? description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logoSize = compact ? 40.0 : 84.0;
    final logo = ClipOval(
      child: Image.asset(
        AppAssets.logo,
        width: logoSize,
        height: logoSize,
        fit: BoxFit.cover,
        semanticLabel: l10n.appName,
        filterQuality: FilterQuality.high,
      ),
    );

    final titleText = Semantics(
      header: true,
      child: Text(
        title,
        textAlign: compact ? TextAlign.start : TextAlign.center,
        style: AppTextStyles.headline(context),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              logo,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appName,
                      style: AppTextStyles.wordmark(
                        context,
                      ).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.descriptor,
                      style: AppTextStyles.descriptor(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          titleText,
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(description!, style: AppTextStyles.muted(context)),
          ],
        ],
      );
    }

    return Column(
      children: [
        logo,
        const SizedBox(height: 16),
        Text(
          l10n.appName,
          textAlign: TextAlign.center,
          style: AppTextStyles.wordmark(context),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.descriptor,
          textAlign: TextAlign.center,
          style: AppTextStyles.descriptor(context),
        ),
        const SizedBox(height: 22),
        titleText,
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: AppTextStyles.muted(context),
          ),
        ],
      ],
    );
  }
}
