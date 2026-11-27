import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'live_text.dart';
import 'live_theme.dart';

class LiveToastController extends ChangeNotifier {
  String? _text;
  int _request = 0;
  Duration _duration = const Duration(seconds: 2);
  bool _disposed = false;

  bool get isShowing => _text != null;

  void show(String text, {Duration duration = const Duration(seconds: 2)}) {
    if (_disposed || text.trim().isEmpty) return;
    _text = text;
    _duration =
        duration > Duration.zero ? duration : const Duration(seconds: 2);
    _request++;
    notifyListeners();
  }

  /// 对应 iOS `LiveToast.dismiss()`：只取消当前提示，不影响后续新提示。
  void dismiss() {
    if (_disposed || _text == null) return;
    _request++;
    _text = null;
    notifyListeners();
  }

  void _clear(int request) {
    if (_disposed || request != _request) return;
    _text = null;
    notifyListeners();
  }

  @override
  void dispose() {
    dismiss();
    _disposed = true;
    super.dispose();
  }
}

class LiveToastView extends StatefulWidget {
  const LiveToastView({super.key, required this.controller});
  final LiveToastController controller;

  // UI presentation only: separate root overlays represent separate windows.
  static final _presentations = Expando<_LiveToastViewState>();

  /// Keeps component sheets below an already visible, non-interactive toast.
  /// This is internal to LiveKit; Overlay itself has no z-order property.
  static void insertBelowToast(OverlayState overlay, OverlayEntry entry) {
    overlay.insert(entry, below: _presentations[overlay]?._entry);
  }

  @override
  State<LiveToastView> createState() => _LiveToastViewState();
}

class _LiveToastViewState extends State<LiveToastView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _fade;
  Timer? _timer;
  OverlayState? _overlay;
  OverlayEntry? _entry;
  bool _updateScheduled = false;
  LiveToastController? _shownController;
  int? _shownRequest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    widget.controller.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (_overlay != overlay) {
      _removePresentation();
      _overlay = overlay;
    }
    _changed();
  }

  @override
  void didUpdateWidget(LiveToastView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_changed);
    _removePresentation();
    widget.controller.addListener(_changed);
    _changed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) widget.controller.dismiss();
  }

  void _changed() {
    // Initial mounting and controller swaps can happen during a parent build.
    // Overlay insertion must wait until that frame has finished building.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_updateScheduled) return;
      _updateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScheduled = false;
        if (mounted) _updatePresentation();
      });
    } else {
      _updatePresentation();
    }
  }

  void _removePresentation() {
    _timer?.cancel();
    _timer = null;
    _fade.stop();
    final overlay = _overlay;
    if (overlay != null && LiveToastView._presentations[overlay] == this) {
      LiveToastView._presentations[overlay] = null;
    }
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _shownController = null;
    _shownRequest = null;
  }

  void _updatePresentation() {
    final LiveToastController controller = widget.controller;
    if (controller._text == null) {
      _removePresentation();
      if (_overlay == null) setState(() {});
      return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      controller._clear(controller._request);
      return;
    }
    // MediaQuery/TickerMode changes must not extend an existing request.
    if (_shownController == controller &&
        _shownRequest == controller._request) {
      if (_entry != null) {
        _entry!.markNeedsBuild();
      } else if (_overlay == null) {
        setState(() {});
      }
      return;
    }
    _timer?.cancel();
    final overlay = _overlay;
    if (overlay != null) {
      final previous = LiveToastView._presentations[overlay];
      if (previous != null && previous != this) {
        previous._removePresentation();
        if (previous.widget.controller != controller) {
          previous.widget.controller.dismiss();
        }
      }
      LiveToastView._presentations[overlay] = this;
      if (_entry == null) {
        _entry = OverlayEntry(
            builder: (context) => Positioned.fill(child: _buildToast(context)));
        overlay.insert(_entry!);
      } else {
        _entry!.markNeedsBuild();
        overlay.rearrange([_entry!], below: _entry);
      }
    } else {
      setState(() {});
    }
    final int request = controller._request;
    _shownController = controller;
    _shownRequest = request;
    _fade.forward(from: 0);
    _timer = Timer(controller._duration, () async {
      if (!mounted ||
          controller != widget.controller ||
          request != controller._request) {
        return;
      }
      try {
        await _fade.reverse().orCancel;
      } on TickerCanceled {
        return;
      }
      if (mounted && controller == widget.controller) {
        controller._clear(request);
      }
    });
  }

  @override
  void dispose() {
    _removePresentation();
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_changed);
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _overlay == null ? _buildToast(context) : const SizedBox.shrink();
  }

  Widget _buildToast(BuildContext context) {
    final String? text = widget.controller._text;
    if (text == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Container(
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _ToastStyle.border),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _ToastStyle.gradientStart,
                    _ToastStyle.gradientMiddle,
                    _ToastStyle.gradientEnd
                  ],
                  stops: [0, .5, 1],
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x660052D9),
                      offset: Offset(0, 8),
                      blurRadius: 24)
                ],
              ),
              child: LiveText(LiveTextRole.sectionTitle,
                  text: text,
                  alignment: TextAlign.center,
                  lineHeight: 16,
                  maxLines: null,
                  overflow: TextOverflow.clip),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _ToastStyle {
  static const gradientStart = Color(0xEB052963);
  static const gradientMiddle = Color(0xE61A477D);
  static const gradientEnd = Color(0xE0336380);
  static const border = Color(0x14FFFFFF);
}
