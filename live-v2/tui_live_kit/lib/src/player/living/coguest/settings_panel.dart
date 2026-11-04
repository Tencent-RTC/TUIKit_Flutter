import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../common/beauty/beauty_panel.dart';
import '../../../common/debounced_click.dart';
import '../../../common/live_kit_resources.dart';
import '../../../common/theme/bottom_sheet_view.dart';

enum SettingsPanelMode { preview, connected }

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.mode,
    required this.onDismiss,
    this.onRequestCoGuest,
  });

  final SettingsPanelMode mode;
  final VoidCallback onDismiss;
  final VoidCallback? onRequestCoGuest;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final _beautyPanel = BeautyPanelController();
  final DebouncedClick _debouncedClick = DebouncedClick();
  bool _openedPreviewCamera = false;
  int _previewViewID = 0;
  int _previewRequestID = 0;
  bool _previewStarting = false;

  @override
  void initState() {
    super.initState();
    DeviceStore.shared.state.localMirrorType.addListener(_refresh);
    if (widget.mode == SettingsPanelMode.preview) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startPreview());
    }
  }

  @override
  void didUpdateWidget(covariant SettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode) return;
    if (widget.mode == SettingsPanelMode.preview) {
      _startPreview();
    } else {
      _stopPreview();
    }
  }

  @override
  void dispose() {
    DeviceStore.shared.state.localMirrorType.removeListener(_refresh);
    _stopPreview();
    _beautyPanel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool showsPreview = widget.mode == SettingsPanelMode.preview;
    final double height =
        (showsPreview ? media.size.width + 152 : 190) + media.padding.bottom;
    return BottomSheetView(
      sheetHeight: height,
      onDismiss: () {
        _stopPreview();
        widget.onDismiss();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: media.padding.bottom),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 16,
              top: 20,
              width: 36,
              height: 36,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _debouncedClick.perform('back', widget.onDismiss),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: _CoGuestSettingsStyle.idleBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CustomPaint(painter: _BackPainter()),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 64,
              right: 64,
              top: 24,
              child: Column(
                children: <Widget>[
                  Text(
                    _text('调整视频连麦画面', 'Adjust Co-host Video'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _text('观众将实时看到效果', 'Viewers see changes in real time'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _CoGuestSettingsStyle.detailForeground,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            if (showsPreview)
              Positioned(
                left: 64,
                right: 64,
                top: 84,
                height: media.size.width - 128,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: _CoGuestSettingsStyle.panelBackground,
                    child: CameraView(
                      onViewCreated: _onPreviewViewCreated,
                      onViewDisposed: _onPreviewViewDisposed,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 56,
              right: 56,
              top: showsPreview ? media.size.width - 24 : 84,
              height: 76,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _SettingCap(
                    assetName: 'livekit_living_setting_beauty',
                    title: _text('美化', 'Beauty'),
                    onTap: () => _debouncedClick.perform('beauty', () => _beautyPanel.show(context)),
                  ),
                  _SettingCap(
                    assetName: DeviceStore.shared.state.localMirrorType.value ==
                            MirrorType.disable
                        ? 'livekit_settings_mirror_off'
                        : 'livekit_settings_mirror_on',
                    title: _text('镜像', 'Mirror'),
                    selected: DeviceStore.shared.state.localMirrorType.value !=
                        MirrorType.disable,
                    onTap: () => _debouncedClick.perform('mirror', _toggleMirror),
                  ),
                  _SettingCap(
                    assetName: 'livekit_living_setting_flip',
                    title: _text('翻转镜头', 'Flip camera'),
                    onTap: () => _debouncedClick.perform('flip', _flipCamera),
                  ),
                ],
              ),
            ),
            if (showsPreview)
              Positioned(
                left: 20,
                right: 20,
                top: media.size.width + 76,
                height: 44,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _debouncedClick.perform('apply', widget.onRequestCoGuest),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B7BFF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      _text('申请连麦', 'Apply'),
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPreview() async {
    if (!mounted || widget.mode != SettingsPanelMode.preview ||
        _previewViewID == 0 || _openedPreviewCamera || _previewStarting) {
      return;
    }
    _previewStarting = true;
    final int requestID = ++_previewRequestID;
    final PermissionStatus permission = await Permission.camera.request();
    if (!mounted || requestID != _previewRequestID ||
        widget.mode != SettingsPanelMode.preview || !permission.isGranted) {
      if (requestID == _previewRequestID) _previewStarting = false;
      return;
    }
    DeviceStore.shared.switchCamera(true);
    DeviceStore.shared.switchMirror(MirrorType.enable);
    final CompletionHandler result = await DeviceStore.shared.startCameraTest(_previewViewID);
    if (requestID != _previewRequestID || !mounted ||
        widget.mode != SettingsPanelMode.preview) {
      if (result.isSuccess) DeviceStore.shared.stopCameraTest();
      return;
    }
    _previewStarting = false;
    _openedPreviewCamera = result.isSuccess;
  }

  void _onPreviewViewCreated(int viewID) {
    _previewViewID = viewID;
    _startPreview();
  }

  void _onPreviewViewDisposed(int viewID) {
    if (_previewViewID != viewID) return;
    _previewViewID = 0;
    _stopPreview();
  }

  void _stopPreview() {
    _previewRequestID++;
    _previewStarting = false;
    if (!_openedPreviewCamera) return;
    _openedPreviewCamera = false;
    DeviceStore.shared.stopCameraTest();
  }

  void _toggleMirror() {
    final bool enabled =
        DeviceStore.shared.state.localMirrorType.value != MirrorType.disable;
    DeviceStore.shared
        .switchMirror(enabled ? MirrorType.disable : MirrorType.enable);
  }

  void _flipCamera() {
    DeviceStore.shared
        .switchCamera(!DeviceStore.shared.state.isFrontCamera.value);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}

class _SettingCap extends StatefulWidget {
  const _SettingCap({
    required this.assetName,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  final String assetName;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_SettingCap> createState() => _SettingCapState();
}

class _SettingCapState extends State<_SettingCap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: SizedBox(
        width: 60,
        height: 76,
        child: Column(
          children: <Widget>[
            AnimatedScale(
              scale: _pressed ? 0.92 : 1,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? _CoGuestSettingsStyle.selectedBackground
                      : _CoGuestSettingsStyle.idleBackground,
                  shape: BoxShape.circle,
                ),
                child: Image(
                  image: LiveKitResources.image(widget.assetName),
                  width: 21,
                  height: 21,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackPainter extends CustomPainter {
  const _BackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path path = Path()
      ..moveTo(size.width * 0.62, size.height * 0.24)
      ..lineTo(size.width * 0.36, size.height * 0.5)
      ..lineTo(size.width * 0.62, size.height * 0.76);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _text(String zh, String en) {
  return WidgetsBinding.instance.platformDispatcher.locale.languageCode
              .toLowerCase() ==
          'zh'
      ? zh
      : en;
}

abstract final class _CoGuestSettingsStyle {
  static const idleBackground = Color(0x17FFFFFF);
  static const detailForeground = Color(0x99FFFFFF);
  static const panelBackground = Color(0xFF0E1932);
  static const selectedBackground = Color(0x52558BFF);
}
