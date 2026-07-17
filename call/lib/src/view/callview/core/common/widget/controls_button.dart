import 'package:flutter/material.dart';

class ControlsButton extends StatelessWidget {
  const ControlsButton(
      {required this.imgUrl,
        this.tips = "",
        this.onTap,
        this.imgHeight = 0,
        this.imgOffsetX = 0,
        this.imgOffsetY = 0,
        this.imgColor,
        this.textColor,
        this.duration = const Duration(milliseconds: 200),
        this.useAnimation = false,
        this.isDisabled = false,
        super.key});
  final String imgUrl;
  final double imgHeight;
  final Color? imgColor;
  final double imgOffsetX;
  final double imgOffsetY;
  final String tips;
  final GestureTapCallback? onTap;
  final Color? textColor;
  final bool? useAnimation;
  final Duration duration;
  final bool isDisabled;

  Widget _buildImage() {
    return Image.asset(
      imgUrl,
      package: 'tuikit_atomic_x',
      color: imgColor,
    );
  }

  Widget _buildImageView() {
    final image = _buildImage();
    return useAnimation!
        ? AnimatedContainer(
      duration: duration,
      height: imgHeight > 0 ? imgHeight : 52.0,
      width: imgHeight > 0 ? imgHeight : 52.0,
      child: image,
    )
        : SizedBox(
      height: imgHeight > 0 ? imgHeight : 52.0,
      width: imgHeight > 0 ? imgHeight : 52.0,
      child: image,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isDisabled) {
      return const SizedBox();
    }
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () {
        onTap?.call();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(imgOffsetX, imgOffsetY),
            child: _buildImageView(),
          ),
          Container(
            width: 100,
            height: 15,
            margin: const EdgeInsets.only(top: 10),
            alignment: Alignment.center,
            child: Text(
              tips,
              textScaleFactor: 1.0,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
