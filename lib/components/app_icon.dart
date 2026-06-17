import 'dart:typed_data';

import 'package:flutter/material.dart';

class AppIconImage extends StatelessWidget {
  final Uint8List? bytes;
  final double width;
  final double height;
  final BoxFit fit;

  const AppIconImage({
    super.key,
    required this.bytes,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes == null || bytes!.isEmpty) {
      return Icon(Icons.android, size: width * 0.75);
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (width * dpr).round();
    final cacheHeight = (height * dpr).round();

    return Image.memory(
      bytes!,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}
