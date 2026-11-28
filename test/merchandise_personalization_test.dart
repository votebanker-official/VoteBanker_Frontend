import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/features/merchandise/models/merchandise_design.dart';
import 'package:votebanker/features/merchandise/widgets/personalized_merchandise.dart';

void main() {
  setUp(() {
    MerchandiseDesignStore.instance.bindUser(null);
  });

  test('each product has its own print area and default placement', () {
    const size = Size(400, 400);
    final shirt = merchandisePrintRect('t-shirt', size);
    final cap = merchandisePrintRect('cap', size);
    final mug = merchandisePrintRect('mug', size);
    expect(shirt, isNot(cap));
    expect(cap, isNot(mug));
    expect(shirt.center.dx, closeTo(200, 80));

    final shirtSlot = artworkSlotFor('t-shirt');
    final capSlot = artworkSlotFor('cap');
    final badgeSlot = artworkSlotFor('badge');
    expect(shirtSlot.kind, ArtworkKind.chakra);
    expect(shirtSlot.circular, isTrue);
    expect(shirtSlot.artWidth, closeTo(0.16, 0.02));
    expect(capSlot.kind, ArtworkKind.voteIndia);
    expect(capSlot.artWidth, greaterThan(shirtSlot.artWidth));
    expect(badgeSlot.circular, isTrue);
    expect(badgeSlot.artWidth, greaterThan(0.4));

    final shirtDesign = ProductDesign.defaultsFor('t-shirt');
    expect(shirtDesign.photo.cx, closeTo(shirtSlot.defaultPhoto.cx, 0.001));
    expect(shirtDesign.photo.cy, closeTo(shirtSlot.defaultPhoto.cy, 0.001));
    expect(shirtDesign.encode(), contains('vbdesign'));

    final artwork = merchandiseArtworkRect('t-shirt', size);
    final photoSize = merchandiseLayerSize(
      canvas: size,
      slug: 't-shirt',
      scale: 1,
    );
    final photo = Rect.fromCenter(
      center: Offset(
        shirt.left + shirtDesign.photo.cx * shirt.width,
        shirt.top + shirtDesign.photo.cy * shirt.height,
      ),
      width: photoSize.width,
      height: photoSize.height,
    );
    expect(shirt.contains(photo.center), isTrue);
    expect(photo.center.dx, closeTo(artwork.center.dx, 1));
    expect(photo.center.dy, closeTo(artwork.center.dy, 1));
    expect(photo.width, closeTo(artwork.width, 1));
  });

  test('a layer cannot leave the printable area', () {
    const area = Rect.fromLTWH(0, 0, 200, 120);
    const footprint = Size(40, 50);
    final parked = clampLayer(
      layer: const PrintLayer(cx: 4, cy: -2, scale: 1),
      area: area,
      footprint: footprint,
    );
    expect(parked.cx, lessThanOrEqualTo(1));
    expect(parked.cx, greaterThan(0));
    expect(parked.cy, greaterThanOrEqualTo(0));
    expect(parked.cy, lessThan(1));
  });

  test('switching accounts drops the previous design', () {
    MerchandiseDesignStore.instance.bindUser('vaishnavi');
    MerchandiseDesignStore.instance.update(
      't-shirt',
      ProductDesign.defaultsFor(
        't-shirt',
      ).copyWith(photo: const PrintLayer(cx: 0.2, cy: 0.2, scale: 1.4)),
    );
    expect(MerchandiseDesignStore.instance.isCustom('t-shirt'), isTrue);

    MerchandiseDesignStore.instance.bindUser('rahul');
    expect(MerchandiseDesignStore.instance.isCustom('t-shirt'), isFalse);
    expect(
      MerchandiseDesignStore.instance.of('t-shirt').photo.cx,
      ProductDesign.defaultsFor('t-shirt').photo.cx,
    );

    MerchandiseDesignStore.instance.update(
      'cap',
      ProductDesign.defaultsFor('cap'),
    );
    MerchandiseDesignStore.instance.reset('cap');
    expect(MerchandiseDesignStore.instance.isCustom('cap'), isFalse);
  });

  testWidgets('photo and symbol stay separate layers on a narrow preview', (
    tester,
  ) async {
    for (final width in [320.0, 375.0, 412.0, 440.0, 768.0, 1280.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 420,
              child: PersonalizedMerchandiseView(
                slug: 't-shirt',
                photo: _png,
                partyName: 'Indian National Congress',
                design: ProductDesign.defaultsFor('t-shirt'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsWidgets);
      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(ClipRRect), findsNothing);
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  testWidgets('resize and reset keep the product design editable', (
    tester,
  ) async {
    MerchandiseDesignStore.instance.bindUser('priya');
    var design = ProductDesign.defaultsFor('mug');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  SizedBox(
                    height: 280,
                    width: 360,
                    child: PersonalizedMerchandiseView(
                      slug: 'mug',
                      photo: _png,
                      partyName: 'Bharatiya Janata Party',
                      design: design,
                      interactive: true,
                      onChanged: (next) => setState(() => design = next),
                    ),
                  ),
                  MerchandiseDesignControls(
                    slug: 'mug',
                    selected: PrintTarget.photo,
                    onSelect: (_) {},
                    design: design,
                    onChanged: (next) => setState(() => design = next),
                    onReset: () {
                      setState(() {
                        design = ProductDesign.defaultsFor('mug');
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(Slider), const Offset(80, 0));
    await tester.pump();
    expect(design.photo.scale, greaterThan(1));

    await tester.tap(find.text('Reset to Default'));
    await tester.pump();
    expect(design.photo.scale, 1);
    expect(design.photo.cx, ProductDesign.defaultsFor('mug').photo.cx);
    expect(tester.takeException(), isNull);
  });
}

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);
