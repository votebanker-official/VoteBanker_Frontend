import 'package:flutter/material.dart';

import '../models/website_builder_draft.dart';
import 'leader_portfolio_site.dart';

/// Renders the unified political-leader website from saved draft data only.
class WebsiteBuilderPreview extends StatelessWidget {
  const WebsiteBuilderPreview({
    required this.draft,
    this.isPreviewBanner = true,
    this.compact = false,
    this.fullBleed = false,
    super.key,
  });

  final WebsiteBuilderDraft draft;
  final bool isPreviewBanner;
  final bool compact;

  /// Lets the site use the width it is given and grow with its content.
  final bool fullBleed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey('builder-preview-${draft.templateId}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          width: double.infinity,
          height: fullBleed ? null : (compact ? 360 : 560),
          child: Column(
            mainAxisSize: fullBleed ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (isPreviewBanner)
                const ColoredBox(
                  color: Color(0xFFFEF3C7),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Preview only — not published yet',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (fullBleed)
                LeaderPortfolioSite(
                  draft: draft,
                  compact: compact,
                  scrollBody: false,
                )
              else
                Expanded(
                  child: LeaderPortfolioSite(draft: draft, compact: compact),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
