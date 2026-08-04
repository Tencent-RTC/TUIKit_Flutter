import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { BusinessError } from '@kit.BasicServicesKit';
import { common, wantConstant } from '@kit.AbilityKit';
import Want from '@ohos.app.ability.Want';
import { fileUri } from '@kit.CoreFileKit';
import FilePickerHelper, { PickerResult } from './FilePickerHelper';

/**
 * OHOS 端 file_picker channel bridge。
 * Dart 契约(见 file_picker_platform.dart):
 *   MethodChannel : 'tencent_chat_uikit/file_picker'
 *     - pickFiles({ maxCount, allowedMimeTypes })  -> List<{filePath,fileName,fileSize,extension}>
 *       (鸿蒙 DocumentViewPicker 不支持按 mime 过滤,allowedMimeTypes 目前忽略)
 *     - openFile({ filePath })                    -> bool
 *
 * openFile 通过 startAbility + implicit want 触发系统里可打开该文件的 App。
 * 需要 UIAbilityContext,通过 AbilityAware 生命周期注入。
 */
export default class FilePicker implements MethodCallHandler {
  private static readonly TAG = 'ChatUiKit.FilePicker';
  private static readonly CHANNEL_NAME = 'tencent_chat_uikit/file_picker';

  private channel: MethodChannel | null = null;
  private uiAbilityContext: common.UIAbilityContext | null = null;
  /**
   * 应用沙盒缓存目录绝对路径,onAttachedToEngine 里从 ApplicationContext 拿。
   * FilePickerHelper 用它把选中的 file://docs/... URI 拷贝到本沙盒,
   * IMSDK 的 FFI 读文件才不会受跨应用授权限制(6017 错误)。
   */
  private cacheDir: string | null = null;

  constructor(binding: FlutterPluginBinding) {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), FilePicker.CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    try {
      this.cacheDir = binding.getApplicationContext().cacheDir;
    } catch (e) {
      console.warn(`${FilePicker.TAG} read cacheDir failed`, (e as Error).message);
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.uiAbilityContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.uiAbilityContext = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'pickFiles': {
        this.handlePickFiles(call, result);
        return;
      }
      case 'openFile': {
        this.handleOpenFile(call, result);
        return;
      }
      default:
        result.notImplemented();
    }
  }

  private handlePickFiles(call: MethodCall, result: MethodResult): void {
    const maxCountRaw = call.argument('maxCount') as number | null;
    const maxCount = (maxCountRaw === null || maxCountRaw === undefined) ? 1 : maxCountRaw;
    FilePickerHelper.pickFiles(maxCount, this.cacheDir).then((items: PickerResult[]) => {
      const payload: Record<string, ESObject>[] = items.map((it: PickerResult) => {
        const r: Record<string, ESObject> = {
          'filePath': it.filePath,
          'fileName': it.fileName,
          'fileSize': it.fileSize,
          'extension': it.extension,
        };
        return r;
      });
      result.success(payload);
    }).catch((e: Error) => {
      console.error(`${FilePicker.TAG} pickFiles failed`, e.message);
      result.success([] as Record<string, ESObject>[]);
    });
  }

  private handleOpenFile(call: MethodCall, result: MethodResult): void {
    const filePath = call.argument('filePath') as string | null;
    if (filePath === null || filePath === undefined || filePath.length === 0) {
      result.success(false);
      return;
    }
    const ctx = this.uiAbilityContext;
    if (ctx === null) {
      console.warn(`${FilePicker.TAG} openFile called but no UIAbilityContext`);
      result.success(false);
      return;
    }

    // 三个关键点(缺一不可,否则接收方 App 打开后无法读取沙盒里的文件):
    //   1. URI 必须带 scheme:fileUri.getUriFromPath 把绝对路径转成
    //      `file://<bundleName>/<path>`,系统才认。
    //   2. flags: FLAG_AUTH_READ_URI_PERMISSION 把当前应用沙盒里这个文件的
    //      读权限临时授予接收 App(比如系统视频播放器),否则播放器 UI 起来了
    //      也读不到文件,表现为时长 00:00 + 播放键无响应。
    //   3. type: MIME 类型 帮助系统精准匹配 handler(视频 -> 视频播放器,
    //      而不是 通用文件预览),提升打开体验。
    const uri = fileUri.getUriFromPath(filePath);
    const mime = FilePicker.guessMimeType(filePath);
    console.info(`${FilePicker.TAG} openFile path=${filePath} uri=${uri} mime=${mime}`);

    this.startAbilityWithFallback(ctx, uri, mime).then((ok: boolean) => {
      result.success(ok);
    }).catch((e: Error) => {
      console.warn(`${FilePicker.TAG} openFile chain failed`, e.message);
      result.success(false);
    });
  }

  /**
   * 尝试多种 want 组合拉起匹配的 App,任意一种成功就返回。
   * 不同鸿蒙设备/版本对隐式 want 的匹配策略不同,单一 want 可能匹配不到 handler。
   * 顺序:
   *   1. viewData + uri + mime + read flag  (标准,应该覆盖大多数视频/图片播放器)
   *   2. viewData + uri +        read flag  (去掉 mime,让系统自己按扩展名/URI 猜)
   *   3. viewData + uri + mime + read+write flag  (某些播放器/编辑器需要写权限)
   */
  private async startAbilityWithFallback(
    ctx: common.UIAbilityContext,
    uri: string,
    mime: string,
  ): Promise<boolean> {
    const attempts: Want[] = [];

    // attempt #1: 标准
    const w1: Want = {
      action: 'ohos.want.action.viewData',
      uri: uri,
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
    };
    if (mime.length > 0) {
      w1.type = mime;
    }
    attempts.push(w1);

    // attempt #2: 去掉 mime
    const w2: Want = {
      action: 'ohos.want.action.viewData',
      uri: uri,
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
    };
    attempts.push(w2);

    // attempt #3: read + write flag,某些视频播放器起播时会尝试写状态
    const w3: Want = {
      action: 'ohos.want.action.viewData',
      uri: uri,
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
        | wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION,
    };
    if (mime.length > 0) {
      w3.type = mime;
    }
    attempts.push(w3);

    for (let i = 0; i < attempts.length; i++) {
      const w = attempts[i];
      try {
        await ctx.startAbility(w);
        console.info(`${FilePicker.TAG} openFile attempt #${i + 1} success`);
        return true;
      } catch (e) {
        const err = e as BusinessError;
        console.warn(
          `${FilePicker.TAG} openFile attempt #${i + 1} failed code=${err.code}, msg=${err.message}`,
        );
      }
    }
    return false;
  }

  /**
   * 按扩展名映射常用 MIME。列表参考华为 Media/File 相关文档,
   * 覆盖聊天消息里可能出现的视频/图片/音频/文档。查不到返回空串,让系统自己按 URI 猜。
   */
  private static guessMimeType(filePath: string): string {
    const idx = filePath.lastIndexOf('.');
    if (idx < 0 || idx === filePath.length - 1) {
      return '';
    }
    const ext = filePath.substring(idx + 1).toLowerCase();
    switch (ext) {
      // video
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case '3gp': return 'video/3gpp';
      case 'mkv': return 'video/x-matroska';
      case 'avi': return 'video/x-msvideo';
      case 'webm': return 'video/webm';
      // image
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'bmp': return 'image/bmp';
      case 'heic': return 'image/heic';
      // audio
      case 'mp3': return 'audio/mpeg';
      case 'm4a': return 'audio/mp4';
      case 'wav': return 'audio/wav';
      case 'aac': return 'audio/aac';
      case 'ogg': return 'audio/ogg';
      // document
      case 'pdf': return 'application/pdf';
      case 'txt': return 'text/plain';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'zip': return 'application/zip';
      case 'rar': return 'application/vnd.rar';
      case '7z': return 'application/x-7z-compressed';
      default: return '';
    }
  }

  dispose(): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.uiAbilityContext = null;
  }
}
