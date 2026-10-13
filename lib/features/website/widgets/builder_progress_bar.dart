import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class BuilderProgressBar extends StatelessWidget {
  const BuilderProgressBar({
    required this.step,
    required this.total,
    required this.labels,
    super.key,
  });

  final int step;
  final int total;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Step $step of $total',
          style: AppTextStyles.muted(context),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= total; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: i <= step ? palette.accent : palette.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const SizedBox(height: 6, width: double.infinity),
                    ),
                    if (i - 1 < labels.length) ...[
                      const SizedBox(height: 6),
                      Text(
                        labels[i - 1],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.muted(context).copyWith(
                          fontSize: 10,
                          color: i <= step ? palette.text : palette.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (i != total) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }
}
