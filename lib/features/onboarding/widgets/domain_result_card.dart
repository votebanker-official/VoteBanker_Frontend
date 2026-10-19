import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';

class DomainResultCard extends StatelessWidget {
  const DomainResultCard({
    required this.domain,
    required this.availability,
    required this.availabilityColor,
    required this.price,
    required this.perYear,
    required this.actionLabel,
    required this.selected,
    required this.onAdd,
    this.premiumLabel,
    this.canSelect = true,
    super.key,
  });

  final String domain;
  final String availability;
  final Color availabilityColor;
  final String price;
  final String perYear;
  final String actionLabel;
  final bool selected;
  final VoidCallback? onAdd;
  final String? premiumLabel;
  final bool canSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(domain, style: AppTextStyles.label(context)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: availabilityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      availability,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.muted(context).copyWith(
                        color: availabilityColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (premiumLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  premiumLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.muted(context).copyWith(
                    color: palette.accent,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );

          final priceBlock = price.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
              Text(
                price,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTextStyles.label(context),
              ),
              if (perYear.isNotEmpty)
                Text(
                  perYear,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.muted(context).copyWith(fontSize: 12),
                ),
                  ],
                );

          final action = !canSelect
              ? const SizedBox.shrink()
              : Semantics(
                  selected: selected,
                  button: true,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          selected ? const Color(0xFF04221E) : palette.accent,
                      backgroundColor:
                          selected ? palette.secondary : Colors.transparent,
                      side: BorderSide(
                        color: selected ? palette.secondary : palette.accent,
                      ),
                      minimumSize: const Size(76, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onAdd,
                    child: Text(
                      actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                if (price.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  priceBlock,
                ],
                if (canSelect) ...[
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              if (price.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: priceBlock,
                  ),
                ),
              ],
              if (canSelect) ...[
                const SizedBox(width: 8),
                action,
              ],
            ],
          );
        },
      ),
    );
  }
}
