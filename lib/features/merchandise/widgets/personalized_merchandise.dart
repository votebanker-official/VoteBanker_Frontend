import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/merchandise_design.dart';

/// Product mockup. A saved profile photo replaces the product's own print.
class PersonalizedMerchandiseView extends StatelessWidget {
  const PersonalizedMerchandiseView({
    required this.slug,
    required this.design,
    this.photo,
    this.partyName = '',
    this.interactive = false,
    this.selected = PrintTarget.photo,
    this.onSelect,
    this.onChanged,
    super.key,
  });

  final String slug;
  final ProductDesign design;
  final Uint8List? photo;
  final String partyName;
  final bool interactive;
  final PrintTarget selected;
  final ValueChanged<PrintTarget>? onSelect;
  final ValueChanged<ProductDesign>? onChanged;

  bool get _hasPhoto => photo != null && photo!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final canvas = Size(side, side);
        final slot = artworkSlotFor(slug);
        final bounds = slot.boundsOn(canvas);
        final artwork = slot.artworkOn(canvas);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              children: [
                Image.asset(
                  merchandiseAssetFor(slug),
                  width: side,
                  height: side,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                if (_hasPhoto) ...[
                  _ArtworkCover(rect: artwork, circular: slot.circular),
                  _Layer(
                    canvas: canvas,
                    area: bounds,
                    layer: design.photo,
                    slug: slug,
                    selected: interactive && selected == PrintTarget.photo,
                    interactive: interactive,
                    onTap: () => onSelect?.call(PrintTarget.photo),
                    onMoved: (next) {
                      onChanged?.call(design.copyWith(photo: next));
                    },
                    child: _PrintPhoto(bytes: photo!, circular: slot.circular),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hides the original Chakra or Vote India print. It does not move.
class _ArtworkCover extends StatelessWidget {
  const _ArtworkCover({required this.rect, required this.circular});

  final Rect rect;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F6),
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _PrintPhoto extends StatelessWidget {
  const _PrintPhoto({required this.bytes, required this.circular});

  final Uint8List bytes;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final image = Image.memory(
      bytes,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      gaplessPlayback: true,
      width: double.infinity,
      height: double.infinity,
    );
    final clipped =
        circular
            ? ClipOval(child: image)
            : ClipRRect(borderRadius: BorderRadius.circular(8), child: image);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(8),
      ),
      child: clipped,
    );
  }
}

enum PrintTarget { photo, symbol }

class _Layer extends StatelessWidget {
  const _Layer({
    required this.canvas,
    required this.area,
    required this.layer,
    required this.slug,
    required this.selected,
    required this.interactive,
    required this.onTap,
    required this.onMoved,
    required this.child,
  });

  final Size canvas;
  final Rect area;
  final PrintLayer layer;
  final String slug;
  final bool selected;
  final bool interactive;
  final VoidCallback onTap;
  final ValueChanged<PrintLayer> onMoved;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = merchandiseLayerSize(
      canvas: canvas,
      slug: slug,
      scale: layer.scale,
    );
    final placed = clampLayer(layer: layer, area: area, footprint: size);
    final left = area.left + placed.cx * area.width - size.width / 2;
    final top = area.top + placed.cy * area.height - size.height / 2;
    return Positioned(
      left: left,
      top: top,
      width: size.width,
      height: size.height,
      child: GestureDetector(
        onTap: interactive ? onTap : null,
        onPanUpdate:
            interactive
                ? (details) {
                  final next = clampLayer(
                    layer: placed.copyWith(
                      cx: placed.cx + details.delta.dx / area.width,
                      cy: placed.cy + details.delta.dy / area.height,
                    ),
                    area: area,
                    footprint: size,
                  );
                  onMoved(next);
                }
                : null,
        child: DecoratedBox(
          decoration:
              selected
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1D4ED8),
                      width: 1.5,
                    ),
                  )
                  : const BoxDecoration(),
          child: child,
        ),
      ),
    );
  }
}

/// Move, resize, and reset controls for the open product.
class MerchandiseDesignControls extends StatelessWidget {
  const MerchandiseDesignControls({
    required this.slug,
    required this.selected,
    required this.onSelect,
    required this.design,
    required this.onChanged,
    required this.onReset,
    super.key,
  });

  final String slug;
  final PrintTarget selected;
  final ValueChanged<PrintTarget> onSelect;
  final ProductDesign design;
  final ValueChanged<ProductDesign> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final layer = design.photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Drag the photo inside the print area.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Move photo'),
              selected: selected == PrintTarget.photo,
              onSelected: (_) => onSelect(PrintTarget.photo),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Reset to Default'),
            ),
          ],
        ),
        Row(
          children: [
            const Text('Resize', style: TextStyle(fontWeight: FontWeight.w700)),
            Expanded(
              child: Slider(
                value: layer.scale,
                min: PrintLayer.minScale,
                max: PrintLayer.maxScale,
                onChanged: (value) {
                  onChanged(
                    design.copyWith(photo: layer.copyWith(scale: value)),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
