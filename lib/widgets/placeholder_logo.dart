import 'package:flutter/material.dart';
import '../utils/logo_util.dart';

/// A logo widget that displays the Nigerian Army Signals logo
class PlaceholderLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const PlaceholderLogo({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LogoUtil.getSquareLogo(size),
    );
  }
}
