// Copyright (c) 2026 Tencent. All rights reserved.

import 'dart:math' as math;

import 'package:atomic_x_core/api/media_mixing/media_mixing_store.dart';
import 'package:atomic_x_core/impl/common/log.dart';
import 'package:atomic_x_core/impl/view/live/media_mixing/media_mixing_render_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class MediaMixingCanvas extends StatefulWidget {
  const MediaMixingCanvas({super.key});

  @override
  State<MediaMixingCanvas> createState() => _MediaMixingCanvasState();
}

const double _kHandleSize = 10.0;
const double _kHandleHitSize = 18.0;
const double _kMinSize = 0.08;

const double _kSnapEnterThreshold = 0.015;
const double _kSnapExitThreshold = 0.025;

const Color _kSelectionColor = Color(0xFF2196F3);
const Color _kIdleBorderColor = Color(0x4DFFFFFF);
const Color _kLabelBackgroundColor = Color(0x8A000000);

const Color _kCenterGuideColor = Color(0x8C2196F3);

class _MediaMixingCanvasState extends State<MediaMixingCanvas> {
  _DragState? _drag;
  int? _renderPtr;

  final Log _logger = Log.getLiveLog("MediaMixingCanvas");

  MediaMixingStore get _store => MediaMixingStore.shared;

  @override
  void initState() {
    super.initState();
    _store.setMixedFillMode(VideoFillMode.fit);
    _store.state.sources.addListener(_onStoreChanged);
    _store.state.selectedSourceKey.addListener(_onStoreChanged);
    _store.state.status.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _store.state.sources.removeListener(_onStoreChanged);
    _store.state.selectedSourceKey.removeListener(_onStoreChanged);
    _store.state.status.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _onStatusChanged() {
    if (_store.state.status.value != MixingStatus.running) return;
    final ptr = _renderPtr;
    if (ptr != null && ptr != 0) {
      _store.setMixedRenderView(ptr);
    }
    _store.setMixedFillMode(VideoFillMode.fit);
    _logger.info('re-applied fit render mode after start');
  }

  List<MixingSourceInfo> get _sortedSources {
    final list = List<MixingSourceInfo>.of(_store.state.sources.value);
    list.sort((a, b) => a.layout.zOrder.compareTo(b.layout.zOrder));
    return list;
  }

  void _onViewCreated(int ptr) {
    _renderPtr = ptr;
    _store.setMixedRenderView(ptr);
    _logger.info('render view created (ptr=$ptr)');
  }

  void _onViewDisposed(int _) {
    _renderPtr = null;
    _store.setMixedRenderView(0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaMixingRenderView(
          onViewCreated: _onViewCreated,
          onViewDisposed: _onViewDisposed,
        ),
        _buildEditor(),
      ],
    );
  }

  Rect _contentRect(Size viewSize) {
    final canvas = _store.state.canvasSize.value;
    if (canvas.width <= 0 || canvas.height <= 0) {
      return Offset.zero & viewSize;
    }
    final fill = _store.state.mixedFillMode.value == VideoFillMode.fill;
    final scale = fill
        ? math.max(
            viewSize.width / canvas.width,
            viewSize.height / canvas.height,
          )
        : math.min(
            viewSize.width / canvas.width,
            viewSize.height / canvas.height,
          );
    final width = canvas.width * scale;
    final height = canvas.height * scale;
    return Rect.fromLTWH(
      (viewSize.width - width) / 2,
      (viewSize.height - height) / 2,
      width,
      height,
    );
  }

  Widget _buildEditor() {
    final selectedKey = _store.state.selectedSourceKey.value;
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
          final content = _contentRect(viewSize);
          MixingSourceInfo? selected;
          Rect? selectedRect;
          for (final src in _sortedSources) {
            if (src.key == selectedKey) {
              selected = src;
              selectedRect = _normalizedToPixel(_effectiveRect(src), content);
            }
          }
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (_) => _store.selectSource(null),
                ),
              ),
              if (selected != null && selectedRect != null)
                CustomPaint(
                  size: viewSize,
                  painter: _CenterGuidesPainter(
                    sourceRect: selectedRect,
                    contentRect: content,
                  ),
                ),
              for (final src in _sortedSources) _buildSourceBox(src, selectedKey, content),
              if (selected != null && selectedRect != null) ..._buildHandleLayer(selected, selectedRect, content),
            ],
          );
        },
      ),
    );
  }

  MixingRect _effectiveRect(MixingSourceInfo src) {
    final drag = _drag;
    if (drag != null && drag.key == src.key) {
      return drag.currentRect;
    }
    return src.layout.rect;
  }

  Widget _buildSourceBox(
    MixingSourceInfo src,
    String? selectedKey,
    Rect content,
  ) {
    final isDragging = _drag?.key == src.key;
    final rect = isDragging ? _drag!.currentRect : src.layout.rect;
    final pixelRect = _normalizedToPixel(rect, content);
    final isSelected = selectedKey == src.key;

    return Positioned(
      left: pixelRect.left,
      top: pixelRect.top,
      width: pixelRect.width,
      height: pixelRect.height,
      child: MouseRegion(
        cursor: isSelected ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _cycleSelection(
            pixelRect.topLeft + d.localPosition,
            content,
          ),
          onPanStart: (d) => _onPanStart(
            src,
            content,
            _DragMode.move,
            pixelRect.topLeft + d.localPosition,
          ),
          onPanUpdate: (d) => _onPanUpdate(d, content),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: _onPanCancel,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? _kSelectionColor : _kIdleBorderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  color: _kLabelBackgroundColor,
                  child: Text(
                    '${src.sourceType.name}:${src.key}',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHandleLayer(
    MixingSourceInfo src,
    Rect pixelRect,
    Rect content,
  ) {
    return [
      for (final pos in _HandlePos.values) _buildHandle(pos, src, pixelRect, content),
    ];
  }

  Widget _buildHandle(
    _HandlePos pos,
    MixingSourceInfo src,
    Rect pixelRect,
    Rect content,
  ) {
    const half = _kHandleHitSize / 2;
    final center = _handleCenter(pos, pixelRect);
    return Positioned(
      left: center.dx - half,
      top: center.dy - half,
      width: _kHandleHitSize,
      height: _kHandleHitSize,
      child: MouseRegion(
        cursor: _cursorForHandle(pos),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => _onPanStart(
            src,
            content,
            _modeForHandle(pos),
            center,
          ),
          onPanUpdate: (d) => _onPanUpdate(d, content),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: _onPanCancel,
          child: Center(child: _handleBox()),
        ),
      ),
    );
  }

  Offset _handleCenter(_HandlePos pos, Rect rect) {
    switch (pos) {
      case _HandlePos.topLeft:
        return rect.topLeft;
      case _HandlePos.topRight:
        return rect.topRight;
      case _HandlePos.bottomLeft:
        return rect.bottomLeft;
      case _HandlePos.bottomRight:
        return rect.bottomRight;
      case _HandlePos.topCenter:
        return rect.topCenter;
      case _HandlePos.bottomCenter:
        return rect.bottomCenter;
      case _HandlePos.middleLeft:
        return rect.centerLeft;
      case _HandlePos.middleRight:
        return rect.centerRight;
    }
  }

  Widget _handleBox() {
    return Container(
      width: _kHandleSize,
      height: _kHandleSize,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: _kSelectionColor, width: 1.5),
      ),
    );
  }

  void _cycleSelection(Offset point, Rect content) {
    final hits = [
      for (final src in _sortedSources.reversed)
        if (_normalizedToPixel(_effectiveRect(src), content).contains(point)) src,
    ];
    if (hits.isEmpty) return;
    final current = _store.state.selectedSourceKey.value;
    final index = hits.indexWhere((s) => s.key == current);
    final next = index >= 0 && index + 1 < hits.length ? hits[index + 1] : hits.first;
    _store.selectSource(next.key);
  }

  void _onPanStart(
    MixingSourceInfo src,
    Rect content,
    _DragMode mode,
    Offset point,
  ) {
    var target = src;
    final selectedKey = _store.state.selectedSourceKey.value;
    if (selectedKey != null && selectedKey != src.key) {
      for (final candidate in _sortedSources) {
        final rect = _normalizedToPixel(_effectiveRect(candidate), content);
        if (candidate.key == selectedKey && rect.contains(point)) {
          target = candidate;
        }
      }
    }
    _store.selectSource(target.key);
    _drag = _DragState(
      key: target.key,
      zOrder: target.layout.zOrder,
      startRect: target.layout.rect,
      currentRect: target.layout.rect,
      mode: mode,
      freeX: target.layout.rect.x,
      freeY: target.layout.rect.y,
    );
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d, Rect content) {
    final drag = _drag;
    if (drag == null) return;

    final dx = d.delta.dx / content.width;
    final dy = d.delta.dy / content.height;
    final r = drag.currentRect;
    final MixingRect newRect;

    switch (drag.mode) {
      case _DragMode.move:
        final freeX = drag.freeX + dx;
        final freeY = drag.freeY + dy;
        final axisX = _snapAxis(freeX, r.width, drag.snappedX);
        final axisY = _snapAxis(freeY, r.height, drag.snappedY);
        newRect = MixingRect(
          x: axisX.position,
          y: axisY.position,
          width: r.width,
          height: r.height,
        );
        _drag = drag.copyWith(
          currentRect: newRect,
          freeX: freeX,
          freeY: freeY,
          snappedX: axisX.snapped,
          snappedY: axisY.snapped,
        );
        break;

      case _DragMode.edgeLeft:
        final left = (r.x + dx).clamp(0.0, r.x + r.width - _kMinSize);
        newRect = MixingRect(
          x: left,
          y: r.y,
          width: r.x + r.width - left,
          height: r.height,
        );
        _drag = drag.copyWith(currentRect: newRect);
        break;

      case _DragMode.edgeRight:
        final width = (r.width + dx).clamp(_kMinSize, 1.0 - r.x);
        newRect = MixingRect(x: r.x, y: r.y, width: width, height: r.height);
        _drag = drag.copyWith(currentRect: newRect);
        break;

      case _DragMode.edgeTop:
        final top = (r.y + dy).clamp(0.0, r.y + r.height - _kMinSize);
        newRect = MixingRect(
          x: r.x,
          y: top,
          width: r.width,
          height: r.y + r.height - top,
        );
        _drag = drag.copyWith(currentRect: newRect);
        break;

      case _DragMode.edgeBottom:
        final height = (r.height + dy).clamp(_kMinSize, 1.0 - r.y);
        newRect = MixingRect(x: r.x, y: r.y, width: r.width, height: height);
        _drag = drag.copyWith(currentRect: newRect);
        break;

      case _DragMode.cornerBottomRight:
        final width = (r.width + dx).clamp(_kMinSize, 1.0 - r.x);
        final height = (r.height + dy).clamp(_kMinSize, 1.0 - r.y);
        newRect = MixingRect(x: r.x, y: r.y, width: width, height: height);
        _drag = drag.copyWith(currentRect: newRect);
        break;

      case _DragMode.cornerTopLeft:
        final right = r.x + r.width;
        final bottom = r.y + r.height;
        final left = (r.x + dx).clamp(0.0, right - _kMinSize);
        final top = (r.y + dy).clamp(0.0, bottom - _kMinSize);
        newRect = MixingRect(
          x: left,
          y: top,
          width: right - left,
          height: bottom - top,
        );
        _drag = drag.copyWith(currentRect: newRect);
        break;

      case _DragMode.cornerTopRight:
        final bottom = r.y + r.height;
        final width = (r.width + dx).clamp(_kMinSize, 1.0 - r.x);
        final top = (r.y + dy).clamp(0.0, bottom - _kMinSize);
        newRect = MixingRect(
          x: r.x,
          y: top,
          width: width,
          height: bottom - top,
        );
        _drag = drag.copyWith(currentRect: newRect);
        break;

      case _DragMode.cornerBottomLeft:
        final right = r.x + r.width;
        final left = (r.x + dx).clamp(0.0, right - _kMinSize);
        final height = (r.height + dy).clamp(_kMinSize, 1.0 - r.y);
        newRect = MixingRect(
          x: left,
          y: r.y,
          width: right - left,
          height: height,
        );
        _drag = drag.copyWith(currentRect: newRect);
        break;
    }

    setState(() {});
    _store.updateSourceLayout(
      _drag!.key,
      MixingLayout(rect: _drag!.currentRect, zOrder: _drag!.zOrder),
    );
  }

  void _onPanEnd() {
    final drag = _drag;
    if (drag == null) return;
    _store.updateSourceLayout(
      drag.key,
      MixingLayout(rect: drag.currentRect, zOrder: drag.zOrder),
    );
    _logger.info('Layout updated: ${drag.key} -> '
        '(${drag.currentRect.x.toStringAsFixed(3)}, '
        '${drag.currentRect.y.toStringAsFixed(3)}, '
        '${drag.currentRect.width.toStringAsFixed(3)}, '
        '${drag.currentRect.height.toStringAsFixed(3)})');
    setState(() => _drag = null);
  }

  void _onPanCancel() {
    if (_drag == null) return;
    setState(() => _drag = null);
  }

  ({double position, bool snapped}) _snapAxis(
    double value,
    double size,
    bool wasSnapped,
  ) {
    final clamped = value.clamp(0.0, 1.0 - size);
    var position = clamped;
    var snapped = false;
    var best = wasSnapped ? _kSnapExitThreshold : _kSnapEnterThreshold;

    void consider(double candidate, double distance) {
      if (distance < best) {
        best = distance;
        position = candidate;
        snapped = true;
      }
    }

    consider(0.0, clamped.abs());
    consider(1.0 - size, (clamped + size - 1.0).abs());

    return (position: position, snapped: snapped);
  }

  _DragMode _modeForHandle(_HandlePos pos) {
    switch (pos) {
      case _HandlePos.topLeft:
        return _DragMode.cornerTopLeft;
      case _HandlePos.topRight:
        return _DragMode.cornerTopRight;
      case _HandlePos.bottomLeft:
        return _DragMode.cornerBottomLeft;
      case _HandlePos.bottomRight:
        return _DragMode.cornerBottomRight;
      case _HandlePos.topCenter:
        return _DragMode.edgeTop;
      case _HandlePos.bottomCenter:
        return _DragMode.edgeBottom;
      case _HandlePos.middleLeft:
        return _DragMode.edgeLeft;
      case _HandlePos.middleRight:
        return _DragMode.edgeRight;
    }
  }

  MouseCursor _cursorForHandle(_HandlePos pos) {
    final useMacOSFallback = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    switch (pos) {
      case _HandlePos.topLeft:
      case _HandlePos.bottomRight:
        return useMacOSFallback ? SystemMouseCursors.resizeLeftRight : SystemMouseCursors.resizeUpLeftDownRight;
      case _HandlePos.topRight:
      case _HandlePos.bottomLeft:
        return useMacOSFallback ? SystemMouseCursors.resizeLeftRight : SystemMouseCursors.resizeUpRightDownLeft;
      case _HandlePos.topCenter:
      case _HandlePos.bottomCenter:
        return SystemMouseCursors.resizeUpDown;
      case _HandlePos.middleLeft:
      case _HandlePos.middleRight:
        return SystemMouseCursors.resizeLeftRight;
    }
  }

  Rect _normalizedToPixel(MixingRect r, Rect content) {
    return Rect.fromLTWH(
      content.left + r.x * content.width,
      content.top + r.y * content.height,
      r.width * content.width,
      r.height * content.height,
    );
  }
}

enum _DragMode {
  move,
  edgeLeft,
  edgeRight,
  edgeTop,
  edgeBottom,
  cornerTopLeft,
  cornerTopRight,
  cornerBottomLeft,
  cornerBottomRight,
}

enum _HandlePos {
  topLeft,
  topCenter,
  topRight,
  middleLeft,
  middleRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class _DragState {
  const _DragState({
    required this.key,
    required this.zOrder,
    required this.startRect,
    required this.currentRect,
    required this.mode,
    required this.freeX,
    required this.freeY,
    this.snappedX = false,
    this.snappedY = false,
  });

  final String key;

  final int zOrder;
  final MixingRect startRect;
  final MixingRect currentRect;
  final _DragMode mode;

  final double freeX;
  final double freeY;

  final bool snappedX;
  final bool snappedY;

  _DragState copyWith({
    MixingRect? currentRect,
    double? freeX,
    double? freeY,
    bool? snappedX,
    bool? snappedY,
  }) {
    return _DragState(
      key: key,
      zOrder: zOrder,
      startRect: startRect,
      currentRect: currentRect ?? this.currentRect,
      mode: mode,
      freeX: freeX ?? this.freeX,
      freeY: freeY ?? this.freeY,
      snappedX: snappedX ?? this.snappedX,
      snappedY: snappedY ?? this.snappedY,
    );
  }
}

class _CenterGuidesPainter extends CustomPainter {
  const _CenterGuidesPainter({
    required this.sourceRect,
    required this.contentRect,
  });

  final Rect sourceRect;

  final Rect contentRect;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kCenterGuideColor
      ..strokeWidth = 1.0;

    final cx = sourceRect.center.dx;
    final cy = sourceRect.center.dy;
    _drawDashedLine(canvas, Offset(cx, 0), Offset(cx, sourceRect.top), paint);
    _drawDashedLine(
      canvas,
      Offset(cx, sourceRect.bottom),
      Offset(cx, size.height),
      paint,
    );
    _drawDashedLine(canvas, Offset(0, cy), Offset(sourceRect.left, cy), paint);
    _drawDashedLine(
      canvas,
      Offset(sourceRect.right, cy),
      Offset(size.width, cy),
      paint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 4.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;
    var d = 0.0;
    while (d < len) {
      final end = math.min(d + dashLen, len);
      canvas.drawLine(
        Offset(from.dx + ux * d, from.dy + uy * d),
        Offset(from.dx + ux * end, from.dy + uy * end),
        paint,
      );
      d += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _CenterGuidesPainter oldDelegate) {
    return oldDelegate.sourceRect != sourceRect || oldDelegate.contentRect != contentRect;
  }
}
