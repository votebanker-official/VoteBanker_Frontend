import 'package:flutter/material.dart';

import 'public_info_page.dart';

class RefundShippingScreen extends StatelessWidget {
  const RefundShippingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicDocument(
      title: 'Refund & Shipping Policy',
      description:
          'Shipping, returns, and refunds for VoteBanker merchandise and any paid campaign service. There is no subscription plan page.',
      sections: [
        PublicSection('1. No subscription plans', [
          'VoteBanker does not publish a pricing or plans page, and the site has no subscription catalogue. This policy does not describe a monthly plan, because none is offered here. If a paid transaction exists, it is a merchandise order or a specific service shown to you before you pay.',
        ]),
        PublicSection('2. Merchandise orders', [
          'A merchandise order is a physical campaign item, such as printed material, placed from the Merchandise area. The order is confirmed when the workspace shows an order reference and the payment gateway accepts the payment. Card numbers and UPI credentials are handled by that gateway. VoteBanker stores the order and a transaction reference, not the raw payment credential.',
          'Check the item, quantity, artwork, and delivery address before you pay. Custom printing uses the artwork and text you approved. A mistake in the artwork you submitted is not a defect in the print.',
        ]),
        PublicSection('3. Dispatch and delivery', [
          'Dispatch starts after the order is confirmed and the artwork is accepted. The time to ship depends on the item and on whether the delivery address is serviceable. Serviceable locations are addresses in India that the checkout or the supplier can deliver to. If an address cannot be served, we will tell you and return the payment for the goods that were not sent.',
          'A delivery date shown before payment is an estimate from the carrier, not a guarantee. Risk in ordinary transit follows the carrier’s terms once the item has been handed over with a tracking reference.',
        ]),
        PublicSection('4. Damaged, defective, or incorrect items', [
          'Tell us within 7 days of delivery if an item arrives damaged, is defective, or is not the item you ordered. Write from the email or phone on the account, include the order reference, and attach a photograph of the item and the packing. Contact details are on the Contact Support page, under Merchandise & Shipping.',
          'After we confirm the report, we will replace the item or refund the price of the affected goods. The replacement ships to the same address unless you give a corrected serviceable address. We may ask for the damaged item to be held until the carrier collects it.',
        ]),
        PublicSection('5. Paid services and cancellations', [
          'A refund or cancellation applies only where the service has not yet been performed. You may cancel a merchandise order before it is dispatched, and the payment for the unshipped goods is returned. Once printing has started on custom goods, or a digital file, website change, or other custom deliverable has been completed and made available to you, that work is not refundable.',
          'There is no refund of a completed custom or digital item because the plan changed, because an election date moved, or because a draft was not edited before you used it. AI drafts and downloaded files are digital items. Review them before you rely on them.',
        ]),
        PublicSection('6. How a refund is paid', [
          'An approved refund is sent back through the same payment gateway, to the original method of payment. Banks and UPI providers commonly take 5 to 10 working days after we submit the refund to show it on your statement. We do not refund to a different account unless the original method cannot receive it and the gateway allows another route.',
        ]),
      ],
    );
  }
}
