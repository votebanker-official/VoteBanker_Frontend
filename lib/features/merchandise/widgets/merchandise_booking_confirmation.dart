import 'package:flutter/material.dart';

import '../models/merchandise_pricing.dart';

/// Shared confirmation after an Order now action succeeds.
class MerchandiseBookingConfirmation extends StatelessWidget {
  const MerchandiseBookingConfirmation({
    required this.productName,
    required this.quantity,
    this.totalPaise,
    super.key,
  });

  final String productName;
  final int quantity;
  final int? totalPaise;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Your product is booked, and our VoteBanker team will contact you soon.',
        style: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('$quantity pieces', style: text.bodyMedium),
          if (totalPaise != null) ...[
            const SizedBox(height: 4),
            Text(
              formatMerchandisePrice(totalPaise!),
              style: text.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

Future<void> showMerchandiseBookingConfirmation(
  BuildContext context, {
  required String productName,
  required int quantity,
  int? totalPaise,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return MerchandiseBookingConfirmation(
        productName: productName,
        quantity: quantity,
        totalPaise: totalPaise,
      );
    },
  );
}
