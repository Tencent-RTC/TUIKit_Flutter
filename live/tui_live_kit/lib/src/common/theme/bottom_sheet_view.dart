import 'package:flutter/widgets.dart';

import 'bottom_sheet_background_view.dart';
import 'live_text.dart';
import 'live_theme.dart';

class BottomSheetController {
  Future<void> Function()? _dismiss;

  Future<void> dismiss() async {
    await _dismiss?.call();
  }
}

class BottomSheetView extends StatefulWidget {
  const BottomSheetView({
    super.key,
    required this.sheetHeight,
    required this.onDismiss,
    required this.child,
    this.controller,
    this.sheetTitle,
    this.isPresented = true,
    this.onWillDismiss,
    this.isDismissibleByTappingOutside = true,
    this.dimsBackground = true,
  });

  final String? sheetTitle;
  final bool isPresented;
  final VoidCallback? onWillDismiss;
  final double sheetHeight;
  final VoidCallback onDismiss;
  final Widget child;
  final BottomSheetController? controller;
  final bool isDismissibleByTappingOutside;
  final bool dimsBackground;

  @override
  State<BottomSheetView> createState() => _BottomSheetViewState();
}

class _BottomSheetViewState extends State<BottomSheetView> with SingleTickerProviderStateMixin {
  static const Color _dimmingColor = LiveTheme.sheetScrim;

  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _slideAnimation;
  bool _isDismissing = false;
  bool _animateHeightChanges = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _attachController(widget.controller);
    if (widget.isPresented) _animationController.forward();
  }

  @override
  void didUpdateWidget(BottomSheetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reopening resets the page before presenting, as UIKit's nonanimated
    // updateSheetHeight does. Do not interpolate from the hidden page height.
    _animateHeightChanges = oldWidget.isPresented && widget.isPresented;
    if (!oldWidget.isPresented && widget.isPresented) {
      _isDismissing = false;
      _animationController.forward(from: 0);
    } else if (oldWidget.isPresented && !widget.isPresented) {
      _animationController.stop(canceled: true);
    }
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController(widget.controller);
    }
  }

  @override
  void dispose() {
    _detachController(widget.controller);
    _animationController.dispose();
    super.dispose();
  }

  void _attachController(BottomSheetController? controller) {
    controller?._dismiss = _dismiss;
  }

  void _detachController(BottomSheetController? controller) {
    if (controller?._dismiss == _dismiss) {
      controller?._dismiss = null;
    }
  }

  Future<void> _dismiss() async {
    if (_isDismissing) {
      return;
    }
    _isDismissing = true;
    widget.onWillDismiss?.call();
    try {
      await _animationController.reverse().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) {
      return;
    }
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final themed = BottomSheetTheme.isEnabled(context);
      final media = MediaQuery.of(context);
      final bottomInset = themed ? media.viewInsets.bottom : 0.0;
      final availableHeight =
          (constraints.maxHeight - (themed ? media.padding.top : 0.0) - bottomInset).clamp(0.0, double.infinity);
      final height = themed ? widget.sheetHeight.clamp(0.0, availableHeight) : widget.sheetHeight;
      final content = Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (widget.sheetTitle?.isNotEmpty == true)
            Positioned(
              left: 16,
              right: 16,
              top: 30,
              height: 18,
              child: IgnorePointer(
                child: LiveText(LiveTextRole.sheetTitle,
                    text: widget.sheetTitle, alignment: TextAlign.center, lineHeight: 18),
              ),
            ),
        ],
      );
      // Preserve each feature's layout and internal scroll viewport. Only when
      // the available height is smaller, expose the full sheet by scrolling.
      final boundedContent = height < widget.sheetHeight
          ? SingleChildScrollView(child: SizedBox(height: widget.sheetHeight, child: content))
          : content;
      return Offstage(
          offstage: !widget.isPresented,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.isDismissibleByTappingOutside ? _dismiss : null,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: ColoredBox(
                      color: widget.dimsBackground ? _dimmingColor : const Color(0x00000000),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                child: AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (BuildContext context, Widget? child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        height * (1 - _slideAnimation.value),
                      ),
                      child: child,
                    );
                  },
                  child: AnimatedContainer(
                    duration: _animateHeightChanges ? const Duration(milliseconds: 220) : Duration.zero,
                    curve: Curves.easeInOut,
                    height: height,
                    child: BottomSheetBackgroundView(child: boundedContent),
                  ),
                ),
              ),
            ],
          ));
    });
  }
}
