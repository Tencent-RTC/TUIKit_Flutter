import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/alert_dialog.dart';

class AlertInfo {
  final String description;
  bool isDestructive;

  final String? cancelText;
  final String? defaultText;
  final VoidCallback? cancelCallback;
  final VoidCallback? defaultCallback;
  final List<ButtonConfig> itemList;

  AlertInfo(
      {required this.description,
      this.defaultText,
      this.defaultCallback,
      this.isDestructive = false,
      this.cancelText = '',
      this.cancelCallback,
      this.itemList = const []});
}

class AlertHandler {
  NavigatorState? _navigatorState;
  Route? _route;
  final ValueNotifier<bool> _visible = ValueNotifier(true);
  final String? handID;

  AlertHandler({this.handID});

  bool isShowing() {
    if (handID != null) {
      return AtomicAlertDialog.exists(handID!);
    }
    return _route?.isActive ?? false;
  }

  void close() {
    if (handID != null) {
      AtomicAlertDialog.dismiss(handID!);
      return;
    }
    if (_navigatorState != null && _navigatorState!.mounted && _route != null && _route!.isActive) {
      _navigatorState!.removeRoute(_route!);
      _route = null;
    }
  }

  void setContentVisible(bool show) {
    if (handID != null) {
      AtomicAlertDialog.setVisable(handID!, show);
      return;
    }
    _visible.value = show;
  }
}

class Alert {
  static AlertHandler showAlert(
    AlertInfo info,
    BuildContext context, {
    Color? barrierColor,
    bool showContent = true,
    bool useRootNavigator = false,
  }) {
    final id = AtomicAlertDialog.showWithConfig(
      context,
      enableHide: true,
      rootOverlay: useRootNavigator,
      config: AlertDialogConfig(
        title: '',
        content: info.description,
        itemList: info.itemList,
        cancelConfig: info.cancelText?.isNotEmpty == true
            ? ButtonConfig(
                text: info.cancelText!,
                onClick: info.cancelCallback,
              )
            : null,
        confirmConfig: info.defaultText?.isNotEmpty == true
            ? ButtonConfig(
                text: info.defaultText!,
                type: info.isDestructive ? TextColorPreset.red : TextColorPreset.blue,
                onClick: info.defaultCallback,
              )
            : null,
      ),
    );
    AlertHandler alertHandler = AlertHandler(handID: id);
    alertHandler.setContentVisible(showContent);
    return alertHandler;
  }

  static AlertHandler showAlertWidget({
    required WidgetBuilder builder,
    required BuildContext context,
    Color? barrierColor,
    bool showContent = true,
    bool useRootNavigator = false,
  }) {
    final handler = AlertHandler();
    handler._visible.value = showContent;
    final barrierColor0 = barrierColor ?? Colors.black54;
    final route = _showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useRootNavigator: useRootNavigator,
      builder: (builderContext) {
        return ValueListenableBuilder<bool>(
          valueListenable: handler._visible,
          builder: (_, visible, __) {
            return Offstage(
              offstage: !visible,
              child: Stack(children: [
                ModalBarrier(
                  color: barrierColor0,
                  dismissible: false,
                ),
                builder.call(builderContext),
              ]),
            );
          },
        );
      },
    );
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    handler._navigatorState = navigator;
    handler._route = route;
    return handler;
  }

  // copy from system
  static DialogRoute<T> _showDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    TraversalEdgeBehavior? traversalEdgeBehavior,
  }) {
    final CapturedThemes themes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(
        context,
        rootNavigator: useRootNavigator,
      ).context,
    );
    final dialogRoute = DialogRoute<T>(
      context: context,
      builder: builder,
      barrierColor: barrierColor ??
          DialogTheme.of(context).barrierColor ??
          Theme.of(context).dialogTheme.barrierColor ??
          Colors.black54,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      settings: routeSettings,
      themes: themes,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior ?? TraversalEdgeBehavior.closedLoop,
    );
    Navigator.of(context, rootNavigator: useRootNavigator).push<T>(dialogRoute);
    return dialogRoute;
  }
}
