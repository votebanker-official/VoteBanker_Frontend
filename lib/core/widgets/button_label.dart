import 'package:flutter/material.dart';

class ButtonLabel extends StatelessWidget {
  const ButtonLabel({
    required this.label,
    required this.style,
    this.icon,
    super.key,
  });

  final String label;
  final TextStyle style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
