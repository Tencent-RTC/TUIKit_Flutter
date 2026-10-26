import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../../component/float_window/global_float_window_manager.dart';
import '../../../../common/widget/float_window/float_window_mode.dart';
import '../../../../live_navigator_observer.dart';
import '../../../../common/logger/logger.dart';

abstract class PauseResumeStrategy {
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const PauseResumeStrategy({this.onPause, this.onResume});

  void start(BuildContext context);

  void stop();
}

@Deprecated('deprecated')
class PauseResumeStrategyOnStandardRoute extends PauseResumeStrategy with RouteAware {
  ModalRoute<dynamic>? _subscribedRoute;

  PauseResumeStrategyOnStandardRoute({super.onPause, super.onResume});

  @override
  void didPushNext() {
    onPause?.call();
  }

  @override
  void didPopNext() {
    onResume?.call();
  }

  @override
  void start(BuildContext context) {
    if (_subscribedRoute != null) return;
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null) {
      TUILiveKitNavigatorObserver.instance.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void stop() {
    if (_subscribedRoute == null) return;
    TUILiveKitNavigatorObserver.instance.unsubscribe(this);
    _subscribedRoute = null;
  }
}

class PauseResumeStrategyOnOverlay extends PauseResumeStrategy {
  StreamSubscription<OverlayEvent>? _overlayEventSubscription;
  late final VoidCallback _floatWindowModeListener = _onFloatWindowModeChanged;

  PauseResumeStrategyOnOverlay({super.onPause, super.onResume});

  @override
  void start(BuildContext context) {
    if (_overlayEventSubscription != null) return;
    final OverlayManager overlayManager = GlobalFloatWindowManager.instance.overlayManager;
    _overlayEventSubscription = overlayManager.eventStream.listen((event) {
      LiveKitLogger.info("overlayEvent:$event");
      if (event == OverlayEvent.inserted) {
        onPause?.call();
        _startFloatWindowModeListening();
      } else if (event == OverlayEvent.removed) {
        _stopFloatWindowModeListening();
        onResume?.call();
      }
    });
    if (overlayManager.isShowing) {
      _startFloatWindowModeListening();
    }
  }

  void _startFloatWindowModeListening() {
    GlobalFloatWindowManager.instance.state.floatWindowMode.removeListener(_floatWindowModeListener);
    GlobalFloatWindowManager.instance.state.floatWindowMode.addListener(_floatWindowModeListener);
  }

  void _stopFloatWindowModeListening() {
    GlobalFloatWindowManager.instance.state.floatWindowMode.removeListener(_floatWindowModeListener);
  }

  void _onFloatWindowModeChanged() {
    final mode = GlobalFloatWindowManager.instance.state.floatWindowMode.value;
    LiveKitLogger.info("floatWindowMode:$mode");
    if (mode == FloatWindowMode.inApp) {
      onResume?.call();
    } else if (mode == FloatWindowMode.none) {
      onPause?.call();
    }
  }

  @override
  void stop() {
    _overlayEventSubscription?.cancel();
    _stopFloatWindowModeListening();
  }
}
