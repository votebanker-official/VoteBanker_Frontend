import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../models/merchandise_pricing.dart';

class MerchandiseQuantitySelector extends StatelessWidget {
  const MerchandiseQuantitySelector({
    required this.quantity,
    required this.priceSlabs,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  final int quantity;
  final List<MerchandisePriceSlab> priceSlabs;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected =
        merchandisePresetQuantities.contains(quantity)
            ? quantity
            : merchandiseMinimumQuantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            color: palette.isDark ? palette.textMuted : const Color(0xFF64748B),
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          key: ValueKey('merchQuantity-$selected'),
          value: selected,
          isExpanded: true,
          style: TextStyle(color: palette.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.isDark ? palette.surface : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 8 : 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    palette.isDark ? palette.border : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    palette.isDark ? palette.border : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    palette.isDark ? palette.accent : const Color(0xFFE2E8F0),
                width: palette.isDark ? 1.4 : 1,
              ),
            ),
          ),
          items: [
            for (final option in merchandisePresetQuantities)
              DropdownMenuItem(
                value: option,
                child: Text(
                  merchandiseQuantityLabel(option, priceSlabs),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.text),
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}
