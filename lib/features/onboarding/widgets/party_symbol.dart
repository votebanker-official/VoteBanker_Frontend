import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_colors.dart';
import '../data/political_party.dart';

/// One circular badge. The artwork itself has no outer circle.
class PartySymbol extends StatelessWidget {
  const PartySymbol(this.partyName, {super.key});

  final String partyName;

  static const double size = 40;
  static const double gap = 12;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final asset = PartyOption.symbolFor(partyName);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: palette.border),
      ),
      child:
          asset.endsWith('.svg')
              ? SvgPicture.asset(asset, fit: BoxFit.contain)
              : Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
    );
  }
}
