import 'package:atomic_x_core/api/media_mixing/media_mixing_store.dart';
import 'package:atomic_x_core/impl/view/live/media_mixing/media_mixing_canvas.dart';
import 'package:flutter/material.dart';

import '../pusher_style.dart';

/// 中间中部预览区：居中画布渲染引擎合流画面。
///
/// 画面渲染、选中 / 拖拽 / 缩放由引擎自带的 [MediaMixingCanvas] 承担
/// （数据驱动自 MediaMixingStore，含渲染视图绑定与 fit 填充模式管理）；
/// 本组件只负责画布外壳：比例跟随引擎 MediaMixingState.params 的
/// resolutionMode（横屏 16:9 / 竖屏 9:16）、底色、描边、阴影。
class PusherStreamMixerView extends StatelessWidget {
  const PusherStreamMixerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<MediaMixingParams>(
        valueListenable: MediaMixingStore.shared.state.params,
        builder: (context, params, _) {
          final isLandscape = params.videoEncoderParams.resolutionMode ==
              VideoResolutionMode.landscape;
          return AspectRatio(
            aspectRatio: isLandscape ? 16 / 9 : 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: PusherStyle.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const ClipRect(child: MediaMixingCanvas()),
            ),
          );
        },
      ),
    );
  }
}
