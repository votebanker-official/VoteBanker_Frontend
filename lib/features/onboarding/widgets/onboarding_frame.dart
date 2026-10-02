import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/language_selector.dart';

class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = AppBreakpoints.isWide(constraints.maxWidth);
              final horizontal = wide ? 28.0 : 16.0;
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageSelector(),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.onboardingMaxWidth,
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 280),
                          builder: (context, value, child) {
                            return Opacity(opacity: value, child: child);
                          },
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              16,
                              horizontal,
                              28,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

