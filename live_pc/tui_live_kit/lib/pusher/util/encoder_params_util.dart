import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/media_mixing/media_mixing_store.dart';

class EncoderParamsUtil {
  EncoderParamsUtil._();

  static void switchOrientation(bool landscape) {
    final current =
        MediaMixingStore.shared.state.params.value.videoEncoderParams;
    MediaMixingStore.shared.updateVideoEncoderParams(
      VideoEncParam(
        width: current.height,
        height: current.width,
        fps: current.fps,
        bitrateKbps: current.bitrateKbps,
        resolutionMode: landscape
            ? VideoResolutionMode.landscape
            : VideoResolutionMode.portrait,
      ),
    );
    syncEncoderQuality(MediaMixingStore.shared.state.params.value
        .videoEncoderParams);
  }

  static void syncEncoderQuality(VideoEncParam enc) {
    final quality = qualityFromCanvas(enc.width, enc.height);
    final orientation = enc.width >= enc.height
        ? VideoOrientation.landscape
        : VideoOrientation.portrait;
    DeviceStore.shared.updateVideoQuality(quality, orientation: orientation);
  }

  static VideoQuality qualityFromCanvas(int width, int height) {
    final long = width >= height ? width : height;
    final short = width >= height ? height : width;
    if (long >= 1920 && short >= 1080) return VideoQuality.quality1080P;
    if (long >= 1280 && short >= 720) return VideoQuality.quality720P;
    if (long >= 960 && short >= 540) return VideoQuality.quality540P;
    return VideoQuality.quality360P;
  }
}
