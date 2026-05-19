import 'dart:math';

import 'package:application/src/utils/app_navigator_observer.dart';
import 'package:flutter/material.dart';

class ScreenAdapter {
  final BuildContext _context;
  static const double designWidth = 375.0;
  static const double designHeight = 812.0;

  ScreenAdapter(this._context);

  double getWidth(double dp) {
    return MediaQuery.sizeOf(_context).width * dp / designWidth;
  }

  double getHeight(double dp) {
    return MediaQuery.sizeOf(_context).height * dp / designHeight;
  }

  static double getWidthSupportedLandscape(BuildContext context, num dp) {
    final width = MediaQuery.sizeOf(context).width < MediaQuery.sizeOf(context).height
        ? MediaQuery.sizeOf(context).width
        : MediaQuery.sizeOf(context).height;
    return width / designWidth * dp;
  }

  static double getHeightSupportedLandscape(BuildContext context, num dp) {
    final height = MediaQuery.sizeOf(context).width < MediaQuery.sizeOf(context).height
        ? MediaQuery.sizeOf(context).height
        : MediaQuery.sizeOf(context).width;
    return height / designHeight * dp;
  }
}

extension BuildContextWithScreenAdapter on BuildContext {
  ScreenAdapter get adapter => ScreenAdapter(this);
}

extension NumWithScreenAdapter on num {
  BuildContext getAppContext() {
    return AppNavigatorObserver.instance.navigator!.context;
  }

  double get width => ScreenAdapter.getWidthSupportedLandscape(getAppContext(), this);

  double get height => ScreenAdapter.getHeightSupportedLandscape(getAppContext(), this);

  double get radius => min(width, height);

  double get screenWidth => MediaQuery.sizeOf(getAppContext()).width * this;

  double get screenHeight => MediaQuery.sizeOf(getAppContext()).height * this;
}
