import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BackgroundImageWidget extends StatelessWidget {
  final String backgroundURL;
  final Color backgroundColor;

  const BackgroundImageWidget({
    super.key,
    required this.backgroundURL,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    if (backgroundURL.isEmpty) return buildEmptyImageWidget(context);
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          CachedNetworkImage(
            imageUrl: backgroundURL,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            fit: BoxFit.cover,
            errorWidget: (BuildContext context, String url, Object error) {
              return buildEmptyImageWidget(context);
            },
          ),
          Positioned.fill(
              child: ClipRect(
                  child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(color: Colors.white.withAlpha(50)))))
        ],
      );
    });
  }

  Widget buildEmptyImageWidget(BuildContext context) {
    return Container(color: backgroundColor);
  }
}
