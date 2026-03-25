import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

const kTUIKitReplay = 'TUIKitReplay';

class ScreenShareGuideDialog {
  OverlayEntry? _entry;

  void show({
    required BuildContext context,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    _entry = OverlayEntry(builder: (_) {
      return _ScreenShareGuideWidget(
        onCancel: () {
          dismiss();
          onCancel();
        },
        onConfirm: () {
          onConfirm();
        },
      );
    });
    Overlay.of(context).insert(_entry!);
  }

  void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  bool get isShowing => _entry != null;
}

class _ScreenShareGuideWidget extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ScreenShareGuideWidget({
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LiveColors.black6,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 60),
          decoration: BoxDecoration(
            color: LiveColors.designStandardG2,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(
                LiveKitLocalizations.of(Global.appContext())!.common_select_app_to_live,
                style: const TextStyle(
                  color: LiveColors.designStandardFlowkitWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const _SystemPickerMock(),
              const SizedBox(height: 10),
              Container(height: 0.5, color: LiveColors.designStandardG3Divider),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onCancel,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: Text(
                              LiveKitLocalizations.of(Global.appContext())!.common_cancel,
                              style: const TextStyle(
                                color: LiveColors.designStandardG5,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 0.5, color: LiveColors.designStandardG3Divider),
                    Expanded(
                      child: GestureDetector(
                        onTap: onConfirm,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: Text(
                              LiveKitLocalizations.of(Global.appContext())!.common_go_to_enable,
                              style: const TextStyle(
                                color: LiveColors.designStandardB1,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemPickerMock extends StatelessWidget {
  const _SystemPickerMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: LiveColors.notStandard40G1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CustomPaint(
                    painter: _RecordIconPainter(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  LiveKitLocalizations.of(Global.appContext())!.common_live_screen,
                  style: const TextStyle(
                    color: LiveColors.designStandardFlowkitWhite,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: LiveColors.designStandardG3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [LiveColors.designStandardB1d, LiveColors.designStandardB1d],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    kTUIKitReplay,
                    style: TextStyle(
                      color: LiveColors.designStandardFlowkitWhite,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.check,
                  color: LiveColors.designStandardFlowkitWhite,
                  size: 18,
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: LiveColors.designStandardG3),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  LiveKitLocalizations.of(Global.appContext())!.common_start_live,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LiveColors.designStandardFlowkitWhite,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = size.width * 0.22;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, outerRadius - 1.5, paint);

    paint
      ..style = PaintingStyle.fill
      ..strokeWidth = 0;
    canvas.drawCircle(center, innerRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}