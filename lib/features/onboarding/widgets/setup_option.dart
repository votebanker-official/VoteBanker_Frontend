import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class SetupOption extends StatelessWidget {
  const SetupOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.accent : palette.border;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surfaceSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: palette.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.label(context)),
                    const SizedBox(height: 4),
                    Text(body, style: AppTextStyles.muted(context)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: palette.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
