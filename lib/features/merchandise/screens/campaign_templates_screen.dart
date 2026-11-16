import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../onboarding/data/political_party.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/party_symbol.dart';
import '../models/merchandise_product.dart';
import '../services/merchandise_service.dart';
import 'merchandise_design_screen.dart';

/// Catalog page that follows social setup. Product art uses the leader's
/// party symbol and profile photo when those were saved on the profile.
class CampaignTemplatesScreen extends StatefulWidget {
  const CampaignTemplatesScreen({this.service, super.key});

  final MerchandiseService? service;

  @override
  State<CampaignTemplatesScreen> createState() => _CampaignTemplatesScreenState();
}

class _CampaignTemplatesScreenState extends State<CampaignTemplatesScreen> {
  late final MerchandiseService _service = widget.service ?? MerchandiseService();
  List<MerchandiseProduct> _products = campaignTemplateProducts;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final catalog = await _service.loadCatalog();
      if (!mounted || catalog.products.isEmpty) return;
      setState(() => _products = catalog.products);
    } catch (_) {
      // The built-in list stays on screen when the API cannot be reached.
    }
  }

  void _open(MerchandiseProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MerchandiseDesignScreen(
          product: product,
          service: _service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = OnboardingScope.maybeOf(context)?.draft;
    final party = PartyOption.findByName(draft?.party ?? '');
    final photo = draft?.photoBytes;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => AppRouter.back(context, AppRoutes.social),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  const ThemeToggle(),
                  const SizedBox(width: 8),
                  const LanguageSelector(),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    children: [
                      const _HeroBanner(),
                      const SizedBox(height: 16),
                      Text(
                        'Campaign Templates',
                        style: AppTextStyles.headline(context).copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 720 ? 2 : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _products.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              mainAxisExtent: 148,
                            ),
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return _TemplateCard(
                                product: product,
                                party: party,
                                photo: photo,
                                onOrder: () => _open(product),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      const _FooterBanner(),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => AppRouter.open(context, AppRoutes.vrm),
                        child: const Text('Skip for now'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const campaignTemplateProducts = <MerchandiseProduct>[
  MerchandiseProduct(
    slug: 't-shirt',
    name: 'T-Shirt',
    description: 'Wear Your Support',
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'scarf',
    name: 'Scarf',
    description: 'Wrap the Spirit',
    sizes: ['One size'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'flag',
    name: 'Flag',
    description: 'Wave Your Support',
    sizes: ['Small', 'Medium', 'Large'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'badge',
    name: 'Badge',
    description: 'Show Your Pride',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'cap',
    name: 'Cap',
    description: 'Wear It Proudly',
    sizes: ['Free size'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'mug',
    name: 'Mug',
    description: 'Sip the Support',
    sizes: ['330 ml'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'poster',
    name: 'Poster',
    description: 'Spread the Message',
    sizes: ['A4', 'A3', 'A2'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'sticker',
    name: 'Sticker',
    description: 'Stick the Support',
    sizes: ['Small', 'Sheet'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'keychain',
    name: 'Keychain',
    description: 'Carry the Change',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'pen',
    name: 'Pen',
    description: 'Write for a Better India',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'bag',
    name: 'Bag',
    description: 'Carry the Campaign',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
  MerchandiseProduct(
    slug: 'gift-box',
    name: 'Gift box',
    description: 'Share the Support',
    sizes: ['Standard'],
    colors: ['White', 'Black', 'Navy', 'Saffron', 'Green', 'Red'],
  ),
];

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFFFF), Color(0xFFECFDF3)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
              children: [
                TextSpan(text: 'Create Your\n'),
                TextSpan(text: 'Campaign ', style: TextStyle(color: Color(0xFFF97316))),
                TextSpan(text: 'Merchandise'),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Show your support with pride!',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.product,
    required this.onOrder,
    this.party,
    this.photo,
  });

  final MerchandiseProduct product;
  final PartyOption? party;
  final Uint8List? photo;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onOrder,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _ProductArt(slug: product.slug, party: party, photo: photo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tagline(product),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: onOrder,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Design & Order'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tagline(MerchandiseProduct product) {
    const lines = {
      't-shirt': 'Wear Your Support',
      'scarf': 'Wrap the Spirit',
      'flag': 'Wave Your Support',
      'badge': 'Show Your Pride',
      'cap': 'Wear It Proudly',
      'mug': 'Sip the Support',
      'poster': 'Spread the Message',
      'sticker': 'Stick the Support',
      'keychain': 'Carry the Change',
      'pen': 'Write for a Better India',
      'bag': 'Carry the Campaign',
      'gift-box': 'Share the Support',
    };
    return lines[product.slug] ?? product.description;
  }
}

class _ProductArt extends StatelessWidget {
  const _ProductArt({required this.slug, this.party, this.photo});

  final String slug;
  final PartyOption? party;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFFFF), Color(0xFFECFDF3)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              _asset(slug),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          if (party != null)
            Positioned(
              left: 6,
              top: 6,
              child: PartySymbol(party!.name, diameter: 28),
            ),
          if (photo != null && photo!.isNotEmpty)
            Positioned(
              right: 6,
              bottom: 6,
              child: ClipOval(
                child: Image.memory(photo!, width: 32, height: 32, fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }

  String _asset(String slug) {
    const files = {
      't-shirt': 'assets/images/merchandise/merch-tshirt.jpg',
      'scarf': 'assets/images/merchandise/merch-scarf.jpg',
      'flag': 'assets/images/merchandise/merch-flag.jpg',
      'badge': 'assets/images/merchandise/merch-badge.jpg',
      'cap': 'assets/images/merchandise/merch-cap.jpg',
      'mug': 'assets/images/merchandise/merch-mug.jpg',
      'poster': 'assets/images/merchandise/merch-poster.jpg',
      'sticker': 'assets/images/merchandise/merch-sticker.jpg',
      'keychain': 'assets/images/merchandise/merch-keychain.jpg',
      'pen': 'assets/images/merchandise/merch-pen.jpg',
      'bag': 'assets/images/merchandise/merch-bag.jpg',
      'gift-box': 'assets/images/merchandise/merch-gift.jpg',
    };
    return files[slug] ?? 'assets/images/merchandise/merch-tshirt.jpg';
  }
}

class _FooterBanner extends StatelessWidget {
  const _FooterBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFFFF), Color(0xFFECFDF3)],
        ),
      ),
      child: const Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
          children: [
            TextSpan(text: 'Together for a\n', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
            TextSpan(text: 'Better ', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w800)),
            TextSpan(text: 'India', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
