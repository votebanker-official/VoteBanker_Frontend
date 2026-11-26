import 'package:flutter/material.dart';

import '../models/merchandise_pricing.dart';
import '../models/merchandise_product.dart';

class MerchandisePriceDetails extends StatelessWidget {
  const MerchandisePriceDetails({
    required this.product,
    required this.quantity,
    this.quote,
    this.compact = false,
    this.totalOnly = false,
    super.key,
  });

  final MerchandiseProduct product;
  final int quantity;
  final MerchandiseQuote? quote;
  final bool compact;

  /// Preview summary: total only. Order dialogs keep the full breakdown.
  final bool totalOnly;

  @override
  Widget build(BuildContext context) {
    final resolved = quote ?? quoteMerchandise(product.priceSlabs, quantity);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 8 : 12,
        ),
        child:
            totalOnly
                ? _TotalOnly(
                  quote: resolved.configured ? resolved : null,
                  compact: compact,
                )
                : resolved.configured
                ? _Configured(quote: resolved, compact: compact)
                : _Missing(quantity: quantity, compact: compact),
      ),
    );
  }
}

class _TotalOnly extends StatelessWidget {
  const _TotalOnly({required this.quote, required this.compact});

  final MerchandiseQuote? quote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final configured = quote != null && quote!.lineTotalPaise != null;
    return Row(
      children: [
        Text(
          'Total Price',
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            configured
                ? formatMerchandisePrice(quote!.lineTotalPaise!)
                : 'Price is not configured',
            key: configured ? const ValueKey('merchPriceTotal') : null,
            textAlign: TextAlign.end,
            style: TextStyle(
              color:
                  configured
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFF9A3412),
              fontSize: configured ? (compact ? 22 : 28) : (compact ? 13 : 15),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _Configured extends StatelessWidget {
  const _Configured({required this.quote, required this.compact});

  final MerchandiseQuote quote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _line('Quantity', '${quote.quantity} pieces', compact),
        _line(
          'Price per piece',
          formatMerchandisePrice(quote.unitPricePaise!),
          compact,
        ),
        const SizedBox(height: 6),
        Text(
          formatMerchandisePrice(quote.lineTotalPaise!),
          key: const ValueKey('merchPriceTotal'),
          textAlign: TextAlign.end,
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: compact ? 22 : 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.quantity, required this.compact});

  final int quantity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line('Quantity', '$quantity pieces', compact),
        const SizedBox(height: 4),
        Text(
          'Price is not configured',
          style: TextStyle(
            color: const Color(0xFF9A3412),
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

Widget _line(String label, String value, bool compact) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
