package io.trtc.tuikit.atomicxcore.view;

import android.view.View;

import io.trtc.tuikit.atomicxcore.engine.EngineBridge;

final class EngineBridgeJniHelper {

  private EngineBridgeJniHelper() {}

  static long nativeViewToPointer(View view) {
    return EngineBridge.nativeViewToPointer(view);
  }

  static void nativeReleaseViewPointer(long pointer) {
    EngineBridge.nativeReleaseViewPointer(pointer);
  }
}
