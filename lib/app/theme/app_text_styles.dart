import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle headline(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: context.palette.text,
    );
  }

  static TextStyle wordmark(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: context.palette.text,
    );
  }

  static TextStyle descriptor(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      height: 1.35,
      color: context.palette.accent,
    );
  }

  static TextStyle principle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: context.palette.accent,
    );
  }

  static TextStyle body(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 15,
      height: 1.5,
      color: context.palette.text,
    );
  }

  static TextStyle muted(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      height: 1.45,
      color: context.palette.textMuted,
    );
  }

  static TextStyle label(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w600,
      color: context.palette.text,
    );
  }

  static TextStyle button(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.25,
    );
  }
}
