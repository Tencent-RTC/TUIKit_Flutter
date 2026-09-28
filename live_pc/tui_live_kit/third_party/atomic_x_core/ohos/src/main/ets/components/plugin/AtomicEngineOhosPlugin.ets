import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LiteAVBase } from '@tencentcloud/liteavsdk_professional';
import { TextureRegistry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import JSTimer from '@tencentcloud/atomicxcore/src/main/ets/engine/base/timer';
import SystemInfo from '@tencentcloud/atomicxcore/src/main/ets/engine/base/systemInfo';

/** AtomicEngineOhosPlugin **/
export default class AtomicEngineOhosPlugin implements FlutterPlugin, MethodCallHandler {
  private static isLiteAVInitialized: boolean = false;
  private channel: MethodChannel | null = null;
  private videoViewChannel: MethodChannel | null = null;
  private textureRegistry: TextureRegistry | null = null;
  private textureToSurfaceMap: Map<number, number> = new Map();

  constructor() {
  }

  getUniqueClassName(): string {
    return "AtomicEngineOhosPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "atomic_engine");
    this.channel.setMethodCallHandler(this);
    this.videoViewChannel = new MethodChannel(binding.getBinaryMessenger(), "atomic_engine_video_view");
    this.videoViewChannel.setMethodCallHandler(this);
    this.textureRegistry = binding.getTextureRegistry();
  }

  private ensureLiteAVContext(): void {
    if (AtomicEngineOhosPlugin.isLiteAVInitialized) {
      return;
    }
    const appCtx = getContext()?.getApplicationContext();
    if (appCtx == null) {
      hilog.error(0, "AtomicEngineOhosPlugin",
        "LiteAVBase.setContext skipped: application context unavailable");
      return;
    }
    AtomicEngineOhosPlugin.isLiteAVInitialized = true;
    LiteAVBase.setContext(appCtx);
    hilog.info(0, "AtomicEngineOhosPlugin", "LiteAVBase.setContext done (lazy)");
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    if (this.videoViewChannel != null) {
      this.videoViewChannel.setMethodCallHandler(null);
      this.videoViewChannel = null;
    }
    this.textureToSurfaceMap.clear();
    this.textureRegistry = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.ensureLiteAVContext();
    if (call.method == "ensureNativeReady") {
      JSTimer.bindNative();
      SystemInfo.bindNative();
      result.success(null);
    } else if (call.method == "getPlatformVersion") {
      result.success("ohos");
    } else if (call.method == "getTextureId") {
      result.success(this.textureRegistry!.getTextureId());
    } else if (call.method == "getSurfaceId") {
      const textureId: number = call.argument("textureId");
      if (!this.textureToSurfaceMap.has(textureId)) {
        const surfaceId = this.textureRegistry!.registerTexture(textureId).getSurfaceId();
        this.textureToSurfaceMap.set(textureId, surfaceId);
        hilog.info(0, "AtomicEngineOhosPlugin", "getSurfaceId (new), textureId: %{public}d, surfaceId: %{public}d", textureId, surfaceId);
      }
      result.success(this.textureToSurfaceMap.get(textureId));
    } else if (call.method == "setRenderSize") {
      const textureId: number = call.argument("textureId");
      const width: number = call.argument("width");
      const height: number = call.argument("height");
      this.textureRegistry!.setTextureBufferSize(textureId, width, height);
      result.success(null);
    } else if (call.method == "unregisterTexture") {
      const textureId: number = call.argument("textureId");
      this.textureToSurfaceMap.delete(textureId);
      this.textureRegistry!.unregisterTexture(textureId);
      result.success(null);
    } else {
      result.notImplemented();
    }
  }
}
