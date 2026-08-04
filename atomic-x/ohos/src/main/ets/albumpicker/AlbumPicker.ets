import {
  EventChannel,
  EventSink,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import AlbumPickerHelper, { AlbumPickResult } from './AlbumPickerHelper';

/**
 * OHOS 端 album_picker channel bridge。
 * Dart 契约(见 album_picker_platform.dart):
 *   MethodChannel : 'atomic_x/album_picker'
 *     - pickMedia({ sessionId, pickMode, maxCount, ...theme/style 忽略 })
 *   EventChannel  : 'atomic_x/album_picker_events'
 *     - onPickConfirm     { sessionId, pickedAlbumMedias: [AlbumMedia], textMessage? }
 *     - onMediaProcessing { sessionId, data: AlbumMedia, progress, error }
 *     - onMediaProcessed  { sessionId }
 *     - onCancel          { sessionId }
 *
 * ⚠ Dart 上层 AlbumPickerMediaSendManager 是"两阶段发送"模型:
 *   1) onPickConfirm     -> 只创建黑图占位符消息(status=sending) 供 UI 立刻回显
 *   2) onMediaProcessing (progress==1.0) -> 移除占位符 & 真正发出图片/视频消息
 *   3) onMediaProcessed  -> cleanup session
 * 所以 onMediaProcessing 事件 MUST 触发,否则消息永远卡在 sending 状态。
 *
 * 鸿蒙 photoAccessHelper 拿到的是最终媒体文件,不做转码/压缩,
 * 因此为每一个已拷贝到沙盒的媒体直接 emit 一次 processing 100%,信息流:
 *   picker.select() -> 有结果 -> emit onPickConfirm
 *                                  -> for each media: emit onMediaProcessing(progress=1.0)
 *                                  -> emit onMediaProcessed
 *                    -> 空结果 -> emit onCancel
 */

/** onPickConfirm/onMediaProcessing 之间共享的 media 视图(id 必须一致)。 */
interface MediaWithId {
  id: number;
  item: AlbumPickResult;
}
export default class AlbumPicker implements MethodCallHandler, StreamHandler {
  private static readonly TAG = 'AtomicX.AlbumPicker';
  private static readonly METHOD_CHANNEL_NAME = 'atomic_x/album_picker';
  private static readonly EVENT_CHANNEL_NAME = 'atomic_x/album_picker_events';

  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;
  /**
   * 应用沙盒缓存目录绝对路径,onAttachedToEngine 里从 ApplicationContext 拿。
   * 参考 file_picker,选中的媒体必须先拷贝到本沙盒才能被 IMSDK FFI 读取。
   */
  private cacheDir: string | null = null;
  /**
   * ApplicationContext,photoAccessHelper.getPhotoAccessHelper() 用。
   * 从这个 context 拿 asset(duration/orientation/thumbnail),纯视频 metadata 快路径,
   * 详见 AlbumPickerHelper.resolveVideoMetadataFromAsset 注释。
   */
  private appContext: common.Context | null = null;

  // 单调递增,给 pickedAlbumMedias.id 用
  private mediaIdCounter: number = 0;

  constructor(binding: FlutterPluginBinding) {
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), AlbumPicker.METHOD_CHANNEL_NAME);
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), AlbumPicker.EVENT_CHANNEL_NAME);
    this.eventChannel.setStreamHandler(this);
    try {
      const appCtx = binding.getApplicationContext();
      this.cacheDir = appCtx.cacheDir;
      this.appContext = appCtx;
    } catch (e) {
      console.warn(`${AlbumPicker.TAG} read applicationContext failed`, (e as Error).message);
    }
  }

  // ----- StreamHandler -----
  onListen(args: ESObject, events: EventSink): void {
    this.eventSink = events;
  }

  onCancel(args: ESObject): void {
    this.eventSink = null;
  }

  // ----- MethodCallHandler -----
  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'pickMedia') {
      this.handlePickMedia(call, result);
      return;
    }
    result.notImplemented();
  }

  private handlePickMedia(call: MethodCall, result: MethodResult): void {
    const sessionId = call.argument('sessionId') as string | null;
    if (sessionId === null || sessionId === undefined) {
      result.error('INVALID_ARGUMENT', 'sessionId is required', null);
      return;
    }
    // Dart 侧 pickMode = AlbumPickerMediaFilter.index (imageOnly=0/videoOnly=1/imageAndVideo=2)
    const pickModeRaw = call.argument('pickMode') as number | null;
    const pickMode = (pickModeRaw === null || pickModeRaw === undefined) ? 2 : pickModeRaw;
    const maxCountRaw = call.argument('maxCount') as number | null;
    const maxCount = (maxCountRaw === null || maxCountRaw === undefined) ? 1 : maxCountRaw;

    // Dart 侧希望 pickMedia 立刻返回 void,结果通过 EventChannel 推回
    result.success(null);

    AlbumPickerHelper.pickMedia(pickMode, maxCount, this.cacheDir, this.appContext).then((items: AlbumPickResult[]) => {
      if (items.length === 0) {
        this.emitCancel(sessionId);
        return;
      }
      // 先给每个 item 分配 id — pickConfirm 和 onMediaProcessing 必须共享同一 id,
      // Dart 侧 mediaStates 是按 media.id 索引 placeholder 的。
      const medias: MediaWithId[] = items.map((it: AlbumPickResult) => {
        const m: MediaWithId = { id: ++this.mediaIdCounter, item: it };
        return m;
      });
      this.emitPickConfirm(sessionId, medias);
      // 鸿蒙不做转码,拷贝到沙盒的一刻就是"处理完成",直接报 progress=1.0
      // 触发 Dart 侧 _handleImageProcessing / _handleVideoProcessing 发真实消息
      for (const m of medias) {
        this.emitMediaProcessing(sessionId, m, 1.0, false);
      }
      this.emitProcessed(sessionId);
    }).catch((e: Error) => {
      console.error(`${AlbumPicker.TAG} pickMedia failed`, e.message);
      this.emitCancel(sessionId);
    });
  }

  /** 构造单个 AlbumMedia payload,pickConfirm/mediaProcessing 都用这个函数保证字段一致。 */
  private buildMediaPayload(m: MediaWithId): Record<string, ESObject> {
    // 视频的 duration/thumbnail 由 AlbumPickerHelper 用双路径提取:
    // 首选 photoAccessHelper.asset(方向永远正确),兜底 AVMetadataExtractor(swap 存储宽高)。
    // 图片恒为 0/空串。
    const thumb = m.item.videoThumbnailPath;
    const payload: Record<string, ESObject> = {
      'id': m.id,
      'uri': m.item.filePath,
      'mediaType': m.item.mediaTypeIndex,
      'mediaPath': m.item.filePath,
      'fileExtension': m.item.extension,
      'fileSize': m.item.fileSize,
      'videoThumbnailPath': (thumb !== undefined && thumb.length > 0) ? thumb : null,
      'duration': m.item.durationMs,
    };
    return payload;
  }

  private emitPickConfirm(sessionId: string, medias: MediaWithId[]): void {
    const sink = this.eventSink;
    if (sink === null) {
      console.warn(`${AlbumPicker.TAG} emitPickConfirm dropped: no listener`);
      return;
    }
    const list: Record<string, ESObject>[] = medias.map((m: MediaWithId) => this.buildMediaPayload(m));
    const payload: Record<string, ESObject> = {
      'type': 'onPickConfirm',
      'sessionId': sessionId,
      'pickedAlbumMedias': list,
      'textMessage': null,
    };
    sink.success(payload);
  }

  /**
   * emit 单个 media 的处理进度事件。
   * Dart 侧只在 progress==1.0 && mediaPath 非空时才真正发消息、移除 placeholder。
   */
  private emitMediaProcessing(
    sessionId: string,
    m: MediaWithId,
    progress: number,
    error: boolean,
  ): void {
    const sink = this.eventSink;
    if (sink === null) {
      console.warn(`${AlbumPicker.TAG} emitMediaProcessing dropped: no listener`);
      return;
    }
    const payload: Record<string, ESObject> = {
      'type': 'onMediaProcessing',
      'sessionId': sessionId,
      'data': this.buildMediaPayload(m),
      'progress': progress,
      'error': error,
    };
    sink.success(payload);
  }

  private emitProcessed(sessionId: string): void {
    const sink = this.eventSink;
    if (sink === null) {
      return;
    }
    const payload: Record<string, ESObject> = {
      'type': 'onMediaProcessed',
      'sessionId': sessionId,
    };
    sink.success(payload);
  }

  private emitCancel(sessionId: string): void {
    const sink = this.eventSink;
    if (sink === null) {
      return;
    }
    const payload: Record<string, ESObject> = {
      'type': 'onCancel',
      'sessionId': sessionId,
    };
    sink.success(payload);
  }

  dispose(): void {
    if (this.methodChannel !== null) {
      this.methodChannel.setMethodCallHandler(null);
      this.methodChannel = null;
    }
    // EventChannel.setStreamHandler 类型上不接受 null,而 engine 断开时
    // messenger 已回收,这里只需要清本地引用即可。
    this.eventChannel = null;
    this.eventSink = null;
  }
}
