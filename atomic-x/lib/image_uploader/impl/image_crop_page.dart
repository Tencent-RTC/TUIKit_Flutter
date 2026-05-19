import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tuikit_atomic_x/atomicx.dart';

class ImageCropPage extends StatefulWidget {
  final String imagePath;
  final CropOverlayShape cropShape;
  final Function(String? croppedPath) onCropCompleted;

  const ImageCropPage({
    super.key,
    required this.imagePath,
    required this.cropShape,
    required this.onCropCompleted,
  });

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  // Image info
  ui.Image? _image;
  int _imageWidth = 0;
  int _imageHeight = 0;

  // Transform state
  double _zoomScale = 1.0;
  double _minZoomScale = 1.0;
  double _offsetX = 0;
  double _offsetY = 0;

  // Crop area
  Rect _cropRect = Rect.zero;

  // Gesture state
  int _lastPointerCount = 0;
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;
  bool _isPanning = false;
  bool _isScaling = false;

  // Mask opacity
  double _maskOpacity = 0.85;
  Timer? _maskRestoreTimer;

  // Loading state
  bool _isLoading = true;
  bool _isCropping = false;

  // Constants
  static const double _cropSizeRatio = 0.9;
  static const double _maxZoom = 5.0;
  static const int _maxCanvasSize = 1024;
  static const double _maskOpacityNormal = 0.85;
  static const double _maskOpacityActive = 0.2;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _maskRestoreTimer?.cancel();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      if (!mounted) {
        image.dispose();
        return;
      }

      setState(() {
        _image = image;
        _imageWidth = image.width;
        _imageHeight = image.height;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeTransform();
      });
    } catch (e) {
      debugPrint('ImageCropPage: Failed to load image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateCropRect() {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final containerWidth = screenSize.width;
    final containerHeight = screenSize.height - padding.top;

    final cropWidth = min(containerWidth, containerHeight) * _cropSizeRatio;

    if (widget.cropShape == CropOverlayShape.circle ||
        widget.cropShape == CropOverlayShape.rectangle1_1) {
      final size = cropWidth;
      final left = (containerWidth - size) / 2;
      final top = (containerHeight - size) / 2;
      _cropRect = Rect.fromLTWH(left, top, size, size);
    } else {
      final aspectRatio = _getAspectRatio();
      var cropHeight = cropWidth / aspectRatio;
      final maxHeight = containerHeight * _cropSizeRatio;

      if (cropHeight > maxHeight) {
        cropHeight = maxHeight;
        final adjustedWidth = min(maxHeight * aspectRatio, containerWidth);
        final left = (containerWidth - adjustedWidth) / 2;
        final top = (containerHeight - cropHeight) / 2;
        _cropRect = Rect.fromLTWH(left, top, adjustedWidth, cropHeight);
      } else {
        final left = (containerWidth - cropWidth) / 2;
        final top = (containerHeight - cropHeight) / 2;
        _cropRect = Rect.fromLTWH(left, top, cropWidth, cropHeight);
      }
    }
  }

  double _getAspectRatio() {
    switch (widget.cropShape) {
      case CropOverlayShape.circle:
      case CropOverlayShape.rectangle1_1:
        return 1.0;
      case CropOverlayShape.rectangle4_3:
        return 4.0 / 3.0;
      case CropOverlayShape.rectangle3_4:
        return 3.0 / 4.0;
      case CropOverlayShape.rectangle16_9:
        return 16.0 / 9.0;
      case CropOverlayShape.rectangle9_16:
        return 9.0 / 16.0;
    }
  }

  void _initializeTransform() {
    if (_imageWidth == 0 || _imageHeight == 0) return;

    _calculateCropRect();

    final zoomToFitWidth = _cropRect.width / _imageWidth;
    final zoomToFitHeight = _cropRect.height / _imageHeight;
    _minZoomScale = max(zoomToFitWidth, zoomToFitHeight);
    _zoomScale = _minZoomScale;

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final containerHeight = screenSize.height - padding.top;
    final scaledWidth = _imageWidth * _zoomScale;
    final scaledHeight = _imageHeight * _zoomScale;

    setState(() {
      _offsetX = (screenSize.width - scaledWidth) / 2;
      _offsetY = (containerHeight - scaledHeight) / 2;
    });
  }

  void _constrainOffset() {
    if (_imageWidth == 0 || _imageHeight == 0) return;

    final scaledWidth = _imageWidth * _zoomScale;
    final scaledHeight = _imageHeight * _zoomScale;

    final minOffsetX = _cropRect.left + _cropRect.width - scaledWidth;
    final maxOffsetX = _cropRect.left;
    final minOffsetY = _cropRect.top + _cropRect.height - scaledHeight;
    final maxOffsetY = _cropRect.top;

    if (minOffsetX <= maxOffsetX) {
      _offsetX = _offsetX.clamp(minOffsetX, maxOffsetX);
    } else {
      _offsetX = (_cropRect.left + _cropRect.left + _cropRect.width - scaledWidth) / 2;
    }

    if (minOffsetY <= maxOffsetY) {
      _offsetY = _offsetY.clamp(minOffsetY, maxOffsetY);
    } else {
      _offsetY = (_cropRect.top + _cropRect.top + _cropRect.height - scaledHeight) / 2;
    }
  }

  // --- Gesture Handlers ---

  void _onTapDown() {
    _maskRestoreTimer?.cancel();
    setState(() {
      _maskOpacity = _maskOpacityActive;
    });
  }

  void _onTapUp() {
    _scheduleMaskRestore();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _maskRestoreTimer?.cancel();
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = _zoomScale;
    _lastPointerCount = details.pointerCount;

    if (details.pointerCount == 1) {
      _isPanning = true;
      _isScaling = false;
    } else {
      _isPanning = false;
      _isScaling = true;
    }

    setState(() {
      _maskOpacity = _maskOpacityActive;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount == 1 && _isPanning && !_isScaling) {
        final dx = details.localFocalPoint.dx - _lastFocalPoint.dx;
        final dy = details.localFocalPoint.dy - _lastFocalPoint.dy;
        _offsetX += dx;
        _offsetY += dy;
        _constrainOffset();
      } else if (details.pointerCount >= 2) {
        // Pan
        final dx = details.localFocalPoint.dx - _lastFocalPoint.dx;
        final dy = details.localFocalPoint.dy - _lastFocalPoint.dy;
        _offsetX += dx;
        _offsetY += dy;

        // Scale
        final newZoom = (_lastScale * details.scale).clamp(_minZoomScale, _maxZoom);
        if (newZoom != _zoomScale) {
          final focalX = details.localFocalPoint.dx;
          final focalY = details.localFocalPoint.dy;
          final zoomRatio = newZoom / _zoomScale;
          _offsetX = focalX - (focalX - _offsetX) * zoomRatio;
          _offsetY = focalY - (focalY - _offsetY) * zoomRatio;
          _zoomScale = newZoom;
        }
        _constrainOffset();
      }

      _lastFocalPoint = details.localFocalPoint;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isPanning = false;
    _isScaling = false;
    _scheduleMaskRestore();
  }

  void _scheduleMaskRestore() {
    _maskRestoreTimer?.cancel();
    _maskRestoreTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _maskOpacity = _maskOpacityNormal;
        });
      }
    });
  }

  // --- Crop Logic ---

  Future<void> _onConfirm() async {
    if (_isCropping) return;
    setState(() => _isCropping = true);

    try {
      final croppedPath = await _performCrop();
      _deleteOriginalImage();
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCropCompleted(croppedPath);
      }
    } catch (e) {
      debugPrint('ImageCropPage: Crop failed: $e');
      if (mounted) {
        setState(() => _isCropping = false);
      }
    }
  }

  void _onCancel() {
    _deleteOriginalImage();
    Navigator.of(context).pop();
    widget.onCropCompleted(null);
  }

  void _deleteOriginalImage() {
    try {
      final file = File(widget.imagePath);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint('ImageCropPage: Failed to delete original image: $e');
    }
  }

  Future<String?> _performCrop() async {
    if (_image == null) return null;

    final rectInContentX = _cropRect.left - _offsetX;
    final rectInContentY = _cropRect.top - _offsetY;

    final rectInImageX = (rectInContentX / _zoomScale).floor();
    final rectInImageY = (rectInContentY / _zoomScale).floor();
    final rectInImageWidth = (_cropRect.width / _zoomScale).floor();
    final rectInImageHeight = (_cropRect.height / _zoomScale).floor();

    final clampedX = rectInImageX.clamp(0, _imageWidth - 1);
    final clampedY = rectInImageY.clamp(0, _imageHeight - 1);
    final clampedWidth = rectInImageWidth.clamp(1, _imageWidth - clampedX);
    final clampedHeight = rectInImageHeight.clamp(1, _imageHeight - clampedY);

    var outputWidth = clampedWidth;
    var outputHeight = clampedHeight;
    if (clampedWidth > _maxCanvasSize || clampedHeight > _maxCanvasSize) {
      final scale = min(_maxCanvasSize / clampedWidth, _maxCanvasSize / clampedHeight);
      outputWidth = (clampedWidth * scale).floor();
      outputHeight = (clampedHeight * scale).floor();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final srcRect = Rect.fromLTWH(
      clampedX.toDouble(),
      clampedY.toDouble(),
      clampedWidth.toDouble(),
      clampedHeight.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble());

    canvas.drawImageRect(_image!, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(outputWidth, outputHeight);
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    croppedImage.dispose();
    picture.dispose();

    if (byteData == null) return null;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/cropped_$timestamp.png';
    final file = File(filePath);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return filePath;
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Stack(
                children: [
                  // Image layer with gesture detection
                  Positioned.fill(
                    child: GestureDetector(
                      onTapDown: (_) => _onTapDown(),
                      onTapUp: (_) => _onTapUp(),
                      onTapCancel: _onTapUp,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      onScaleEnd: _onScaleEnd,
                      child: _buildImageLayer(),
                    ),
                  ),
                  // Crop overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CropOverlayPainter(
                          cropRect: _cropRect,
                          isCircle: widget.cropShape == CropOverlayShape.circle,
                          maskOpacity: _maskOpacity,
                        ),
                      ),
                    ),
                  ),
                  // Bottom bar
                  _buildBottomBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildImageLayer() {
    if (_image == null) return const SizedBox.shrink();

    final displayWidth = _imageWidth * _zoomScale;
    final displayHeight = _imageHeight * _zoomScale;

    return Stack(
      children: [
        Positioned(
          left: _offsetX,
          top: _offsetY,
          width: displayWidth,
          height: displayHeight,
          child: RawImage(image: _image, fit: BoxFit.fill, filterQuality: FilterQuality.low),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding),
        height: 56 + bottomPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _onCancel,
              child: Text(
                AtomicLocalizations.of(context).cancel,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            GestureDetector(
              onTap: _isCropping ? null : _onConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isCropping
                      ? Colors.grey
                      : BaseThemeProvider.of(context).colors.buttonColorPrimaryDefault,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _isCropping
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        AtomicLocalizations.of(context).confirm,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the crop overlay mask and frame
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final bool isCircle;
  final double maskOpacity;

  _CropOverlayPainter({required this.cropRect, required this.isCircle, required this.maskOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (cropRect == Rect.zero) return;

    // Draw mask
    final maskPaint = Paint()..color = Colors.black.withOpacity(maskOpacity);

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addRect(fullRect);

    if (isCircle) {
      final center = cropRect.center;
      final radius = cropRect.width / 2;
      path.addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      path.addRect(cropRect);
    }

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, maskPaint);

    // Draw crop frame border
    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (isCircle) {
      final center = cropRect.center;
      final radius = cropRect.width / 2;
      canvas.drawCircle(center, radius, framePaint);
    } else {
      canvas.drawRect(cropRect, framePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return cropRect != oldDelegate.cropRect ||
        isCircle != oldDelegate.isCircle ||
        maskOpacity != oldDelegate.maskOpacity;
  }
}
