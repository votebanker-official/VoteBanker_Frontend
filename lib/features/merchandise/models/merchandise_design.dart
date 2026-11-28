import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Square product photograph used by the campaign and design previews.
String merchandiseAssetFor(String slug) {
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
  return files[slug] ?? files['t-shirt']!;
}

/// One printed layer. [cx] and [cy] are the center inside the product's
/// printable area, from 0 to 1. [scale] is relative to the default size.
@immutable
class PrintLayer {
  const PrintLayer({required this.cx, required this.cy, this.scale = 1});

  final double cx;
  final double cy;
  final double scale;

  static const minScale = 0.65;
  static const maxScale = 1.8;

  PrintLayer copyWith({double? cx, double? cy, double? scale}) {
    return PrintLayer(
      cx: cx ?? this.cx,
      cy: cy ?? this.cy,
      scale: (scale ?? this.scale).clamp(minScale, maxScale).toDouble(),
    );
  }

  String encode() =>
      '${cx.toStringAsFixed(3)},${cy.toStringAsFixed(3)},${scale.toStringAsFixed(3)}';
}

/// Photograph and party symbol stay separate so each can move on its own.
@immutable
class ProductDesign {
  const ProductDesign({required this.photo, required this.symbol});

  final PrintLayer photo;
  final PrintLayer symbol;

  static ProductDesign defaultsFor(String slug) {
    return ProductDesign(
      photo: artworkSlotFor(slug).defaultPhoto,
      // Kept so an existing order note still parses. It is not printed.
      symbol: const PrintLayer(cx: 0.5, cy: 0.5),
    );
  }

  ProductDesign copyWith({PrintLayer? photo, PrintLayer? symbol}) {
    return ProductDesign(
      photo: photo ?? this.photo,
      symbol: symbol ?? this.symbol,
    );
  }

  /// Short enough to ride along in the existing order notes field.
  String encode() =>
      'vbdesign photo=${photo.encode()} symbol=${symbol.encode()}';
}

/// Per-user, per-product placements. A different account starts empty.
class MerchandiseDesignStore extends ChangeNotifier {
  MerchandiseDesignStore._();

  static final MerchandiseDesignStore instance = MerchandiseDesignStore._();

  String? userId;
  final Map<String, ProductDesign> _designs = {};

  void bindUser(String? nextUserId) {
    if (nextUserId == userId) return;
    userId = nextUserId;
    _designs.clear();
    notifyListeners();
  }

  ProductDesign of(String slug) =>
      _designs[slug] ?? ProductDesign.defaultsFor(slug);

  bool isCustom(String slug) => _designs.containsKey(slug);

  void update(String slug, ProductDesign design) {
    _designs[slug] = design;
    notifyListeners();
  }

  void reset(String slug) {
    _designs.remove(slug);
    notifyListeners();
  }
}

/// Keeps a layer inside the printable rectangle.
PrintLayer clampLayer({
  required PrintLayer layer,
  required Rect area,
  required Size footprint,
}) {
  final halfW = footprint.width / 2;
  final halfH = footprint.height / 2;
  final minX = area.width <= footprint.width ? 0.5 : halfW / area.width;
  final maxX = area.width <= footprint.width ? 0.5 : 1 - halfW / area.width;
  final minY = area.height <= footprint.height ? 0.5 : halfH / area.height;
  final maxY = area.height <= footprint.height ? 0.5 : 1 - halfH / area.height;
  return layer.copyWith(
    cx: layer.cx.clamp(minX, maxX).toDouble(),
    cy: layer.cy.clamp(minY, maxY).toDouble(),
  );
}

/// How a product's existing print is replaced by the profile photo.
enum ArtworkKind { chakra, voteIndia }

/// Normalized rectangles on the square product photograph.
class ArtworkSlot {
  const ArtworkSlot({
    required this.kind,
    required this.artLeft,
    required this.artTop,
    required this.artWidth,
    required this.artHeight,
    required this.boundLeft,
    required this.boundTop,
    required this.boundWidth,
    required this.boundHeight,
    required this.circular,
  });

  final ArtworkKind kind;
  final double artLeft;
  final double artTop;
  final double artWidth;
  final double artHeight;
  final double boundLeft;
  final double boundTop;
  final double boundWidth;
  final double boundHeight;
  final bool circular;

  Rect artworkOn(Size size) => Rect.fromLTWH(
    size.width * artLeft,
    size.height * artTop,
    size.width * artWidth,
    size.height * artHeight,
  );

  Rect boundsOn(Size size) => Rect.fromLTWH(
    size.width * boundLeft,
    size.height * boundTop,
    size.width * boundWidth,
    size.height * boundHeight,
  );

  /// Center of the original artwork, expressed inside the drag bounds.
  PrintLayer get defaultPhoto => PrintLayer(
    cx:
        ((artLeft + artWidth / 2 - boundLeft) / boundWidth)
            .clamp(0.0, 1.0)
            .toDouble(),
    cy:
        ((artTop + artHeight / 2 - boundTop) / boundHeight)
            .clamp(0.0, 1.0)
            .toDouble(),
  );
}

/// Measured from the product photographs. Fractions of the square image.
ArtworkSlot artworkSlotFor(String slug) {
  return switch (slug) {
    't-shirt' => const ArtworkSlot(
      kind: ArtworkKind.chakra,
      artLeft: 0.431,
      artTop: 0.376,
      artWidth: 0.16,
      artHeight: 0.16,
      boundLeft: 0.30,
      boundTop: 0.30,
      boundWidth: 0.42,
      boundHeight: 0.40,
      circular: true,
    ),
    'scarf' => const ArtworkSlot(
      kind: ArtworkKind.chakra,
      artLeft: 0.335,
      artTop: 0.296,
      artWidth: 0.20,
      artHeight: 0.20,
      boundLeft: 0.22,
      boundTop: 0.24,
      boundWidth: 0.40,
      boundHeight: 0.32,
      circular: true,
    ),
    'flag' => const ArtworkSlot(
      kind: ArtworkKind.chakra,
      artLeft: 0.475,
      artTop: 0.285,
      artWidth: 0.155,
      artHeight: 0.155,
      boundLeft: 0.28,
      boundTop: 0.16,
      boundWidth: 0.55,
      boundHeight: 0.42,
      circular: true,
    ),
    'bag' => const ArtworkSlot(
      kind: ArtworkKind.chakra,
      artLeft: 0.468,
      artTop: 0.599,
      artWidth: 0.08,
      artHeight: 0.08,
      boundLeft: 0.28,
      boundTop: 0.40,
      boundWidth: 0.46,
      boundHeight: 0.40,
      circular: true,
    ),
    'cap' => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.33,
      artTop: 0.30,
      artWidth: 0.28,
      artHeight: 0.21,
      boundLeft: 0.30,
      boundTop: 0.26,
      boundWidth: 0.36,
      boundHeight: 0.28,
      circular: false,
    ),
    'mug' => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.26,
      artTop: 0.35,
      artWidth: 0.40,
      artHeight: 0.33,
      boundLeft: 0.20,
      boundTop: 0.30,
      boundWidth: 0.50,
      boundHeight: 0.42,
      circular: false,
    ),
    'badge' => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.28,
      artTop: 0.24,
      artWidth: 0.48,
      artHeight: 0.48,
      boundLeft: 0.28,
      boundTop: 0.24,
      boundWidth: 0.48,
      boundHeight: 0.48,
      circular: true,
    ),
    'sticker' => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.255,
      artTop: 0.22,
      artWidth: 0.52,
      artHeight: 0.52,
      boundLeft: 0.255,
      boundTop: 0.22,
      boundWidth: 0.52,
      boundHeight: 0.52,
      circular: true,
    ),
    'poster' => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.20,
      artTop: 0.21,
      artWidth: 0.54,
      artHeight: 0.40,
      boundLeft: 0.18,
      boundTop: 0.12,
      boundWidth: 0.64,
      boundHeight: 0.70,
      circular: false,
    ),
    'pen' => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.38,
      artTop: 0.40,
      artWidth: 0.25,
      artHeight: 0.22,
      boundLeft: 0.32,
      boundTop: 0.34,
      boundWidth: 0.40,
      boundHeight: 0.36,
      circular: false,
    ),
    'keychain' => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.35,
      artTop: 0.51,
      artWidth: 0.30,
      artHeight: 0.30,
      boundLeft: 0.32,
      boundTop: 0.48,
      boundWidth: 0.36,
      boundHeight: 0.36,
      circular: true,
    ),
    'gift-box' => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.26,
      artTop: 0.32,
      artWidth: 0.46,
      artHeight: 0.22,
      boundLeft: 0.22,
      boundTop: 0.24,
      boundWidth: 0.56,
      boundHeight: 0.36,
      circular: false,
    ),
    _ => const ArtworkSlot(
      kind: ArtworkKind.voteIndia,
      artLeft: 0.34,
      artTop: 0.36,
      artWidth: 0.32,
      artHeight: 0.24,
      boundLeft: 0.28,
      boundTop: 0.30,
      boundWidth: 0.44,
      boundHeight: 0.36,
      circular: false,
    ),
  };
}

/// Drag limits. Not drawn.
Rect merchandisePrintRect(String slug, Size size) =>
    artworkSlotFor(slug).boundsOn(size);

/// The original artwork rectangle. The default photo fills this exactly.
Rect merchandiseArtworkRect(String slug, Size size) =>
    artworkSlotFor(slug).artworkOn(size);

Size merchandiseLayerSize({
  required Size canvas,
  required String slug,
  required double scale,
}) {
  final slot = artworkSlotFor(slug);
  final clamped =
      scale.clamp(PrintLayer.minScale, PrintLayer.maxScale).toDouble();
  return Size(
    canvas.width * slot.artWidth * clamped,
    canvas.height * slot.artHeight * clamped,
  );
}
