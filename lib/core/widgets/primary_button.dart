import 'package:flutter/material.dart';

import '../../app/theme/app_text_styles.dart';
import 'button_label.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: ButtonLabel(
          label: label,
          icon: icon,
          style: AppTextStyles.button(context),
        ),
      ),
    );
  }
}
