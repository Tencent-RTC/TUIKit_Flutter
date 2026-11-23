import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../style/constants.dart';
import '../style/live_kit_style.dart';

Future<T?> showMenuPanel<T>({
  required BuildContext context,
  required Size estimatedSize,
  double padding = 4,
  bool captureFocus = true,
  required Widget Function(void Function(T? result) close) builder,
}) {
  final anchor = context.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final anchorTopRight = anchor.localToGlobal(
    anchor.size.topRight(Offset.zero),
    ancestor: overlay,
  );
  final overlaySize = overlay.size;
  // 锚点右侧偏移 4px；clamp 到窗口内，避免浮层贴边溢出。
  final left = (anchorTopRight.dx + 4).clamp(
    8.0,
    (overlaySize.width - estimatedSize.width - 8).clamp(8.0, double.infinity),
  );
  final top = (anchorTopRight.dy).clamp(
    8.0,
    (overlaySize.height - estimatedSize.height - 8).clamp(8.0, double.infinity),
  );

  final completer = Completer<T?>();
  late final OverlayEntry entry;
  void close([T? result]) {
    entry.remove();
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  entry = OverlayEntry(
    builder:
        (context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => close(),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape):
                      () => close(),
                },
                child: Focus(
                  // 捕获焦点以支持 ESC 关闭（纯菜单浮层）；含输入框的浮层
                  // 传 captureFocus: false，把焦点让给输入框的 autofocus。
                  autofocus: captureFocus,
                  child: Material(
                    type: MaterialType.transparency,
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        fontFamilyFallback: getTargetPlatformTextFont,
                      ),
                      child: Container(
                        // Overlay 中 Positioned 只给 left/top 时宽度无界，
                        // 必须定宽，否则内部 Column(stretch) 会拿到无限宽崩溃。
                        width: estimatedSize.width,
                        padding: EdgeInsets.all(padding),
                        decoration: LiveKitStyle.menuSurface(),
                        child: builder((result) => close(result)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
  );
  Overlay.of(context).insert(entry);
  return completer.future;
}
