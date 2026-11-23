import 'package:atomic_x_core_media_mixing/api/media_mixing_store.dart';
import 'package:atomic_x_core_media_mixing/impl/media_mixing_canvas.dart';
import 'package:flutter/material.dart';

import '../common/style/live_kit_style.dart';
import 'capabilities/scene/source/empty_source_guide.dart';
import 'package:atomic_x_core_media_mixing/impl/scene/scene_controller.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_store_view.dart';

class PusherStreamMixerView extends StatelessWidget {
  const PusherStreamMixerView({super.key, required this.store, required this.controller});

  final SceneStoreView store;
  final SceneController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<MediaMixingParams>(
        valueListenable: MediaMixingStore.shared.state.params,
        builder: (context, params, _) {
          final isLandscape = params.videoEncoderParams.resolutionMode == VideoResolutionMode.landscape;
          return AspectRatio(
            aspectRatio: isLandscape ? 16 / 9 : 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: LiveKitStyle.white10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 32, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const MediaMixingCanvas(),
                    ValueListenableBuilder<bool>(
                      valueListenable: store.hasSources,
                      builder: (context, hasSources, _) {
                        if (hasSources) {
                          return const SizedBox.shrink();
                        }
                        return EmptySourceGuide(controller: controller, portrait: !isLandscape);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
