import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';

class DomainResultCard extends StatelessWidget {
  const DomainResultCard({
    required this.domain,
    required this.availability,
    required this.price,
    required this.perYear,
    required this.actionLabel,
    required this.selected,
    required this.onAdd,
    super.key,
  });

  final String domain;
  final String availability;
  final String price;
  final String perYear;
  final String actionLabel;
  final bool selected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
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
                    decoration: const BoxDecoration(
                      color: AppColors.success,
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
                        color: AppColors.success,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          final priceBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(context),
              ),
              Text(
                perYear,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.muted(context).copyWith(fontSize: 12),
              ),
            ],
          );

          final action = Semantics(
            selected: selected,
            button: true,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: selected ? const Color(0xFF04221E) : AppColors.primary,
                backgroundColor: selected ? AppColors.secondary : Colors.transparent,
                side: BorderSide(
                  color: selected ? AppColors.secondary : AppColors.primary,
                ),
                minimumSize: const Size(76, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: priceBlock),
                    const SizedBox(width: 8),
                    action,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 8),
              priceBlock,
              const SizedBox(width: 8),
              action,
            ],
          );
        },
      ),
    );
  }
}
