import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';

class OnboardingActions extends StatelessWidget {
  const OnboardingActions({
    required this.primaryLabel,
    required this.onPrimary,
    this.skipLabel,
    this.onSkip,
    this.backLabel,
    this.onBack,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? skipLabel;
  final VoidCallback? onSkip;
  final String? backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final backButton =
        onBack == null
            ? null
            : SecondaryButton(label: backLabel ?? '', onPressed: onBack!);
    final primaryButton = PrimaryButton(
      label: primaryLabel,
      onPressed: onPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide =
                backButton != null && constraints.maxWidth >= 460;
            if (sideBySide) {
              return Row(
                children: [
                  Expanded(child: backButton),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: primaryButton),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (backButton != null) ...[
                  backButton,
                  const SizedBox(height: 10),
                ],
                primaryButton,
              ],
            );
          },
        ),
        if (onSkip != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(skipLabel ?? ''),
            ),
          ),
      ],
    );
  }
}
