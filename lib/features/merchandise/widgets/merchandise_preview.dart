import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/merchandise_design.dart';
import '../models/merchandise_product.dart';
import 'personalized_merchandise.dart';

/// The product beside the form, with the typed line printed on it.
class MerchandiseLivePreview extends StatelessWidget {
  const MerchandiseLivePreview({
    required this.product,
    required this.line,
    required this.hint,
    required this.size,
    required this.color,
    required this.quantity,
    required this.previewLabel,
    required this.standardLabel,
    required this.qtyLabel,
    this.partyName = '',
    this.profilePhoto,
    this.design,
    this.interactive = false,
    this.selected = PrintTarget.photo,
    this.onSelect,
    this.onChanged,
    this.onReset,
    super.key,
  });

  final MerchandiseProduct product;
  final String line;
  final String hint;
  final String size;
  final String color;
  final int quantity;
  final String previewLabel;
  final String standardLabel;
  final String qtyLabel;
  final String partyName;
  final Uint8List? profilePhoto;
  final ProductDesign? design;
  final bool interactive;
  final PrintTarget selected;
  final ValueChanged<PrintTarget>? onSelect;
  final ValueChanged<ProductDesign>? onChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typed = line.trim();
    final shown = typed.isEmpty ? hint : typed;
    final fill = merchandiseFill(color);
    final ink =
        fill.computeLuminance() < 0.45 ? Colors.white : const Color(0xFF1C2430);
    final colorLabel = color.isEmpty ? standardLabel : color;
    final placement = design ?? ProductDesign.defaultsFor(product.slug);

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            palette.isDark ? palette.surfaceSecondary : const Color(0xFFF3F7FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          children: [
            Text(
              previewLabel,
              style: AppTextStyles.muted(context).copyWith(
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: PersonalizedMerchandiseView(
                slug: product.slug,
                photo: profilePhoto,
                partyName: partyName,
                design: placement,
                interactive: interactive,
                selected: selected,
                onSelect: onSelect,
                onChanged: onChanged,
              ),
            ),
            if (interactive && onChanged != null && onReset != null) ...[
              const SizedBox(height: 10),
              MerchandiseDesignControls(
                slug: product.slug,
                selected: selected,
                onSelect: onSelect ?? (_) {},
                design: placement,
                onChanged: onChanged!,
                onReset: onReset!,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              shown,
              key: const Key('merchPreviewLine'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink.withValues(alpha: typed.isEmpty ? 0.72 : 1),
                fontSize: 14,
                height: 1.25,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (size.isNotEmpty) _MetaChip(label: '[ $size ]'),
                _MetaChip(label: '[ $colorLabel ]'),
                _MetaChip(label: '[ $qtyLabel: $quantity ]'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.muted(context).copyWith(fontSize: 12),
      ),
    );
  }
}

Color merchandiseFill(String color) {
  return switch (color.toLowerCase()) {
    'black' => const Color(0xFF2C3138),
    'navy' => const Color(0xFF1E3A5F),
    'saffron' => const Color(0xFFFF9933),
    'green' => const Color(0xFF1F8A4C),
    'red' => const Color(0xFFD64545),
    'white' => const Color(0xFFF7F8FA),
    'cyan' => const Color(0xFF5EC8E8),
    'magenta' => const Color(0xFFE85CAD),
    'yellow' => const Color(0xFFF6D34D),
    _ => const Color(0xFFF4F6F8),
  };
}
