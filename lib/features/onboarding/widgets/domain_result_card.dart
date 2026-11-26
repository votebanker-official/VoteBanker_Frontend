import 'package:flutter/material.dart';

/// Visual colors for the domain picker. They follow the domain-selection
/// reference: VoteBanker blue, white cards, and a light blue page.
abstract final class DomainPickerColors {
  static const blue = Color(0xFF0969DA);
  static const bluePressed = Color(0xFF0757B8);
  static const background = Color(0xFFF2F7FF);
  static const cardBorder = Color(0xFFD9E7F8);
  static const available = Color(0xFF1F9D55);
  static const text = Color(0xFF0E1B2E);
  static const muted = Color(0xFF5C6B80);
  static const radius = 14.0;
}

class DomainResultCard extends StatelessWidget {
  const DomainResultCard({
    required this.domain,
    required this.availability,
    required this.availabilityColor,
    required this.registrationLabel,
    required this.registrationPrice,
    required this.renewalLabel,
    required this.renewalPrice,
    required this.actionLabel,
    required this.selected,
    required this.onAdd,
    this.premiumLabel,
    this.canSelect = true,
    this.compact = false,
    super.key,
  });

  final String domain;
  final String availability;
  final Color availabilityColor;
  final String registrationLabel;
  final String registrationPrice;
  final String renewalLabel;
  final String renewalPrice;
  final String actionLabel;
  final bool selected;
  final VoidCallback? onAdd;
  final String? premiumLabel;
  final bool canSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final sideAction = compact;
        final borderColor =
            selected ? DomainPickerColors.blue : DomainPickerColors.cardBorder;
        final prices = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (registrationPrice.isNotEmpty)
              _PriceRow(label: registrationLabel, value: registrationPrice),
            if (registrationPrice.isNotEmpty && renewalPrice.isNotEmpty)
              const SizedBox(height: 6),
            if (renewalPrice.isNotEmpty)
              _PriceRow(label: renewalLabel, value: renewalPrice),
          ],
        );
        final button = _SelectButton(
          label: actionLabel,
          onPressed: onAdd,
          expand: !sideAction,
        );

        return Semantics(
          selected: selected,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(DomainPickerColors.radius),
              border: Border.all(color: borderColor, width: selected ? 2 : 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140969DA),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            domain,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DomainPickerColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          const _SelectedMark(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: availabilityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            availability,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: availabilityColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (premiumLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        premiumLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DomainPickerColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (sideAction)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: prices),
                          if (canSelect) ...[
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 124),
                              child: button,
                            ),
                          ],
                        ],
                      )
                    else ...[
                      prices,
                      if (canSelect) ...[const SizedBox(height: 14), button],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: DomainPickerColors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DomainPickerColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: DomainPickerColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    required this.label,
    required this.onPressed,
    required this.expand,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return DomainPickerColors.blue.withValues(alpha: 0.4);
            }
            if (states.contains(WidgetState.pressed)) {
              return DomainPickerColors.bluePressed;
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return const Color(0xFF0860C8);
            }
            return DomainPickerColors.blue;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          overlayColor: const WidgetStatePropertyAll(Color(0x22FFFFFF)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: expand ? 12 : 14, vertical: 8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
