import 'package:flutter/material.dart';

class BottomSheetHandler {
  BuildContext? _context;

  BottomSheetHandler();

  void _setContext(BuildContext? context) {
    _context = context;
  }

  bool isShowing() {
    return _context != null && _context!.mounted;
  }

  void close() {
    if (isShowing() && Navigator.canPop(_context!)) {
      Navigator.pop(_context!);
    }
  }
}

class BaseBottomSheet {
  static BottomSheetHandler showModalSheet({
    required WidgetBuilder builder,
    required BuildContext context,
    RouteSettings? routeSettings,
    VoidCallback? onDismiss,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool isScrollControlled = false,
    Color? barrierColor,
    Color? backgroundColor,
  }) {
    final handler = BottomSheetHandler();
    showModalBottomSheet(
        context: context,
        routeSettings: routeSettings,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        isScrollControlled: isScrollControlled,
        barrierColor: barrierColor,
        backgroundColor: backgroundColor,
        builder: (builderContext) {
          handler._setContext(builderContext);
          return builder.call(builderContext);
        }).whenComplete(() {
      handler._setContext(null);
      onDismiss?.call();
    });
    return handler;
  }
}
