import { camera, cameraPicker } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { image } from '@kit.ImageKit';
import { media } from '@kit.MediaKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { dataSharePredicates } from '@kit.ArkData';

/**
 * OHOS 端 video/photo 拍摄核心工具类。
 * 复用 harmony/atomic_x/videorecorder/components/VideoRecorder.ets 的 cameraPicker.pick 骨架,
 * 关键改进:
 *   1. cameraPicker 返回的 resultUri 是 `file://media/...` 跨应用 URI,
 *      IMSDK FFI 直接读会 6017 错误,必须先拷贝到应用沙盒 cacheDir 里再交给 Dart 侧。
 *      同样的坑之前在 file_picker / album_picker 已经踩过。
 *   2. video 的 duration / thumbnailPath 必须由 native 侧计算并返回。
 *      Dart 上层 (message_input._onTakeVideo) 直接把 result.durationMs / result.thumbnailPath
 *      塞进 VideoMessagePayload -> VideoSendMessagePayload,IMSDK 不做二次解析,
 *      缺失的话消息 bubble 会显示 "00:00" + 没缩略图。
 *
 * 缩略图为什么走 photoAccessHelper.asset.getThumbnail() (harmony 端同做法):
 *   曾经尝试过 media.AVImageGenerator.fetchFrameByTime + PixelMap.rotate(360 - videoOrientation),
 *   实机(华为 CLS-AL00,OpenHarmony 6.1)结果:
 *     - 不 rotate      -> 缩略图是横的(视频存储方向)
 *     - rotate(90/180/270) -> 尺寸 W/H 交换正确,但像素旋转方向与 videoOrientation 语义
 *                             不能自洽,用户仍然看到"画面被旋转"
 *   官方推荐:如果 URI 来自 media library(cameraPicker.pick 的 resultUri 就是),
 *   走 photoAccessHelper 拿 asset,再 asset.getThumbnail() —— 系统直接生成"正立的"缩略图,
 *   orientation 由系统统一处理,永远方向正确。
 *   拿不到 asset 的兜底路径(比如权限缺失)才回退到 AVImageGenerator。
 */

export enum VideoRecordMode {
  MIXED = 0,
  PHOTO_ONLY = 1,
  VIDEO_ONLY = 2,
}

/** kMediaTypePhoto / kMediaTypeVideo / kMediaTypeCancel */
export enum VideoRecordMediaKind {
  PHOTO,
  VIDEO,
  CANCEL,
}

export interface VideoRecordResult {
  mediaKind: VideoRecordMediaKind;
  filePath: string;       // 沙盒里的绝对路径;cancel 时为空串
  durationMs: number;     // video 时由 asset.PhotoKeys.DURATION 解析;失败退化为 0
  thumbnailPath: string;  // video 时由 asset.getThumbnail() 生成的 jpg 沙盒路径;失败退化为 ''
}

/** resolveVideoMetadata 内部返回结构,不 export。 */
interface VideoMetaOut {
  durationMs: number;
  thumbnailPath: string;
}

/** extractVideoInfo 内部返回(fallback 路径用),含原始视频宽高。 */
interface VideoInfoOut {
  durationMs: number;
  width: number;         // 存储宽度;0 表示拿不到
  height: number;        // 存储高度;0 表示拿不到
}

/** 缩略图目标尺寸(存储侧)。 */
interface ThumbSize {
  width: number;
  height: number;
}

const PHOTO_EXT: string[] = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'];

export default class VideoRecorderHelper {
  private static readonly TAG = 'ChatUiKit.VideoRecorderHelper';
  private static readonly SANDBOX_SUBDIR = 'video_recorder';

  /**
   * 拉起系统相机,返回单次拍摄结果。
   * @param recordMode 0=mixed(照片+视频), 1=photoOnly, 2=videoOnly
   * @param defaultFrontCamera 是否默认前置
   * @param ctx UIAbilityContext,cameraPicker.pick + photoAccessHelper 都必需
   * @param cacheDir 沙盒 cacheDir,拷贝目标目录
   */
  static async takeMedia(
    recordMode: number,
    defaultFrontCamera: boolean,
    ctx: common.UIAbilityContext,
    cacheDir: string | null,
  ): Promise<VideoRecordResult> {
    const cancel: VideoRecordResult = {
      mediaKind: VideoRecordMediaKind.CANCEL,
      filePath: '',
      durationMs: 0,
      thumbnailPath: '',
    };

    try {
      const cameraPosition = defaultFrontCamera
        ? camera.CameraPosition.CAMERA_POSITION_FRONT
        : camera.CameraPosition.CAMERA_POSITION_BACK;
      const pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: cameraPosition,
      };
      const mediaTypes = VideoRecorderHelper.resolveMediaTypes(recordMode);

      const pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(
        ctx,
        mediaTypes,
        pickerProfile,
      );

      if (!pickerResult || !pickerResult.resultUri || pickerResult.resultUri.length === 0) {
        return cancel;
      }

      const srcUri = pickerResult.resultUri;
      const fileName = VideoRecorderHelper.getFileNameFromPath(srcUri);
      const ext = VideoRecorderHelper.getFileExtension(fileName);
      const isPhoto = VideoRecorderHelper.isPhotoResult(ext, mediaTypes);

      const sandboxDir = await VideoRecorderHelper.ensureSandboxDir(cacheDir);
      if (sandboxDir === null) {
        console.error(`${VideoRecorderHelper.TAG} no cacheDir available, aborting`);
        return cancel;
      }

      // 视频分支:必须在拷贝到沙盒 *之前* 用原 media library URI 拿 asset,
      // 因为 asset 只认 file://media/... 这类系统 URI。拷贝到沙盒之后原 URI 就丢了。
      let metaFromAsset: VideoMetaOut = { durationMs: 0, thumbnailPath: '' };
      if (!isPhoto) {
        metaFromAsset = await VideoRecorderHelper.resolveVideoMetadataFromAsset(
          srcUri, sandboxDir, ctx,
        );
      }

      const sandboxPath = await VideoRecorderHelper.copyToSandbox(srcUri, sandboxDir, fileName);
      if (sandboxPath === null) {
        console.warn(`${VideoRecorderHelper.TAG} copy failed for ${srcUri}`);
        return cancel;
      }

      if (isPhoto) {
        return {
          mediaKind: VideoRecordMediaKind.PHOTO,
          filePath: sandboxPath,
          durationMs: 0,
          thumbnailPath: '',
        };
      }

      // 缺 duration 或缩略图 -> fallback 到 AVMetadataExtractor + AVImageGenerator(不 rotate,
      // 至少能出一张横躺的缩略图,不阻塞发送)
      let durationMs = metaFromAsset.durationMs;
      let thumbnailPath = metaFromAsset.thumbnailPath;
      if (durationMs === 0 || thumbnailPath.length === 0) {
        console.info(`${VideoRecorderHelper.TAG} asset path incomplete ` +
          `(duration=${durationMs}, thumb='${thumbnailPath}'), fallback to AVMetadataExtractor`);
        const fb = await VideoRecorderHelper.resolveVideoMetadataFromFile(sandboxPath, sandboxDir);
        if (durationMs === 0) {
          durationMs = fb.durationMs;
        }
        if (thumbnailPath.length === 0) {
          thumbnailPath = fb.thumbnailPath;
        }
      }

      return {
        mediaKind: VideoRecordMediaKind.VIDEO,
        filePath: sandboxPath,
        durationMs: durationMs,
        thumbnailPath: thumbnailPath,
      };
    } catch (e) {
      const err = e as BusinessError;
      console.error(`${VideoRecorderHelper.TAG} takeMedia failed code=${err.code}, msg=${err.message}`);
      // cameraPicker 抛异常通常也是用户强退相机之类,一并按 cancel 处理,和 harmony 端行为一致
      return cancel;
    }
  }

  /**
   * 首选路径:走 photoAccessHelper。仅当 srcUri 是 media library URI(file://media/...) 且
   * 有 READ_IMAGEVIDEO 权限时才能成功。
   *   - duration    -> asset.get(PhotoKeys.DURATION)  单位:毫秒
   *   - width/height/orientation -> asset.get(...)    存储侧尺寸 + 顺时针需旋转角度
   *   - thumbnail   -> asset.getThumbnail(size)       系统直接生成"正立的" PixelMap,方向永远正确
   *
   * 为什么必须传 size:
   *   asset.getThumbnail() 不传 size 时,华为返回的是给相册列表用的 256x256 小缩略图,
   *   系统会自动 crop 成接近正方形 —— 消息 bubble 里就看到"方向对了但比例不对"。
   *   传 size 后,系统按目标宽高比生成,不做方形裁切。
   *   size 用"显示宽高"(把存储宽高按 orientation 交换),长边缩到 720 控制 JPEG 大小。
   *
   * 拿不到 asset (fetchResult 空 / 权限缺失 / 非 media URI) 时返回 {0, ''},由上层走 fallback。
   */
  private static async resolveVideoMetadataFromAsset(
    srcUri: string,
    sandboxDir: string,
    ctx: common.UIAbilityContext,
  ): Promise<VideoMetaOut> {
    const empty: VideoMetaOut = { durationMs: 0, thumbnailPath: '' };
    let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | null = null;
    let thumbnail: image.PixelMap | null = null;
    let packer: image.ImagePacker | null = null;
    let thumbFile: fs.File | null = null;
    try {
      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('uri', srcUri);
      fetchResult = await photoAccessHelper.getPhotoAccessHelper(ctx).getAssets({
        fetchColumns: [
          photoAccessHelper.PhotoKeys.DURATION,
          photoAccessHelper.PhotoKeys.WIDTH,
          photoAccessHelper.PhotoKeys.HEIGHT,
          photoAccessHelper.PhotoKeys.ORIENTATION,
        ],
        predicates: predicates,
      });
      if (fetchResult === null || fetchResult.getCount() <= 0) {
        console.warn(`${VideoRecorderHelper.TAG} no asset for uri=${srcUri}`);
        return empty;
      }
      const asset = await fetchResult.getFirstObject();

      // PhotoKeys.DURATION 是毫秒(和 harmony 端一致,业务侧再除 1000 转秒)
      const durationMs = VideoRecorderHelper.readPositiveNumber(
        asset.get(photoAccessHelper.PhotoKeys.DURATION));
      const storedW = VideoRecorderHelper.readPositiveNumber(
        asset.get(photoAccessHelper.PhotoKeys.WIDTH));
      const storedH = VideoRecorderHelper.readPositiveNumber(
        asset.get(photoAccessHelper.PhotoKeys.HEIGHT));
      const orientation = VideoRecorderHelper.readPositiveNumber(
        asset.get(photoAccessHelper.PhotoKeys.ORIENTATION));

      // orientation=90/270 表示相对存储方向要顺时针旋转 90/270 度才正立,
      // 所以"显示尺寸"和"存储尺寸"是宽高交换的关系
      const isRotated = orientation === 90 || orientation === 270;
      const displayW = isRotated ? storedH : storedW;
      const displayH = isRotated ? storedW : storedH;

      const targetSize = VideoRecorderHelper.pickAssetThumbSize(displayW, displayH);
      console.info(
        `${VideoRecorderHelper.TAG} asset meta durationMs=${durationMs} ` +
        `stored=${storedW}x${storedH} orientation=${orientation} ` +
        `display=${displayW}x${displayH} target=${targetSize.width}x${targetSize.height}`,
      );

      thumbnail = await asset.getThumbnail(targetSize);
      const info = thumbnail.getImageInfoSync();
      console.info(
        `${VideoRecorderHelper.TAG} asset thumbnail actual=${info.size.width}x${info.size.height}`,
      );

      packer = image.createImagePacker();
      const packOpt: image.PackingOption = {
        format: 'image/jpeg',
        quality: 85,
      };
      const jpegBuffer = await packer.packing(thumbnail, packOpt);
      const rand = Math.floor(Math.random() * 1e6);
      const dstPath = `${sandboxDir}/thumb_${Date.now()}_${rand}.jpg`;
      thumbFile = await fs.open(
        dstPath,
        fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC,
      );
      await fs.write(thumbFile.fd, jpegBuffer);
      return { durationMs: durationMs, thumbnailPath: dstPath };
    } catch (e) {
      console.warn(`${VideoRecorderHelper.TAG} resolveVideoMetadataFromAsset failed`,
        (e as BusinessError).message);
      return empty;
    } finally {
      if (thumbFile !== null) {
        try {
          await fs.close(thumbFile);
        } catch (_) {
          // ignore
        }
      }
      if (packer !== null) {
        try {
          await packer.release();
        } catch (_) {
          // ignore
        }
      }
      if (thumbnail !== null) {
        try {
          await thumbnail.release();
        } catch (_) {
          // ignore
        }
      }
      if (fetchResult !== null) {
        try {
          fetchResult.close();
        } catch (_) {
          // ignore
        }
      }
    }
  }

  /**
   * 兜底路径:用 AVMetadataExtractor 拿 duration,AVImageGenerator 抓帧生成缩略图。
   * 已知缺陷:不做 rotate(rotate 语义在华为设备上不可控,详见文件头注释),
   * 竖持拍出的视频拿到的会是横的缩略图 —— 但至少能出图不阻塞发送,只有 asset 路径彻底失败时才会走到这里。
   */
  private static async resolveVideoMetadataFromFile(
    videoPath: string,
    sandboxDir: string,
  ): Promise<VideoMetaOut> {
    const info = await VideoRecorderHelper.extractVideoInfo(videoPath);
    const thumbSize = VideoRecorderHelper.pickThumbSize(info.width, info.height);
    const thumbnailPath = await VideoRecorderHelper.extractThumbnail(
      videoPath, sandboxDir, thumbSize,
    );
    return {
      durationMs: info.durationMs,
      thumbnailPath: thumbnailPath,
    };
  }

  private static async extractVideoInfo(videoPath: string): Promise<VideoInfoOut> {
    const fallback: VideoInfoOut = { durationMs: 0, width: 0, height: 0 };
    let file: fs.File | null = null;
    let extractor: media.AVMetadataExtractor | null = null;
    try {
      file = await fs.open(videoPath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(videoPath);
      extractor = await media.createAVMetadataExtractor();
      const fdSrc: media.AVFileDescriptor = {
        fd: file.fd,
        offset: 0,
        length: stat.size,
      };
      extractor.fdSrc = fdSrc;
      const meta = await extractor.fetchMetadata();
      const durationMs = VideoRecorderHelper.parsePositiveInt(meta.duration);
      const width = VideoRecorderHelper.parsePositiveInt(meta.videoWidth);
      const height = VideoRecorderHelper.parsePositiveInt(meta.videoHeight);
      console.info(
        `${VideoRecorderHelper.TAG} [fallback] video meta durationMs=${durationMs} ` +
        `storageWxH=${width}x${height}`,
      );
      return { durationMs: durationMs, width: width, height: height };
    } catch (e) {
      console.warn(`${VideoRecorderHelper.TAG} extractVideoInfo failed`,
        (e as BusinessError).message);
      return fallback;
    } finally {
      if (extractor !== null) {
        try {
          await extractor.release();
        } catch (_) {
          // ignore
        }
      }
      if (file !== null) {
        try {
          await fs.close(file);
        } catch (_) {
          // ignore
        }
      }
    }
  }

  private static pickThumbSize(w: number, h: number): ThumbSize | null {
    const MAX_EDGE = 640;
    if (w <= 0 || h <= 0) {
      return null;
    }
    const longEdge = Math.max(w, h);
    if (longEdge <= MAX_EDGE) {
      return { width: w, height: h };
    }
    const scale = MAX_EDGE / longEdge;
    return {
      width: Math.max(1, Math.round(w * scale)),
      height: Math.max(1, Math.round(h * scale)),
    };
  }

  /**
   * asset.getThumbnail(size) 的目标尺寸:
   *   - 有显示宽高 -> 保持 aspect,长边缩到 MAX_EDGE(720)
   *   - 拿不到    -> 用一个 9:16 的默认 720x1280(消息缩略图绝大多数是竖屏视频)
   *
   * MAX_EDGE=720 是权衡:再大 JPEG 文件也会变大,消息 bubble 只有 240px 宽,浪费带宽。
   */
  private static pickAssetThumbSize(displayW: number, displayH: number): image.Size {
    const MAX_EDGE = 720;
    if (displayW <= 0 || displayH <= 0) {
      return { width: 720, height: 1280 };
    }
    const longEdge = Math.max(displayW, displayH);
    if (longEdge <= MAX_EDGE) {
      return { width: displayW, height: displayH };
    }
    const scale = MAX_EDGE / longEdge;
    return {
      width: Math.max(1, Math.round(displayW * scale)),
      height: Math.max(1, Math.round(displayH * scale)),
    };
  }

  /**
   * asset.get(key) 官方返回类型是 MemberType(number|string|boolean|null),
   * 实际是 number 时可以直接用,但要防 null/undefined。
   */
  private static readPositiveNumber(v: photoAccessHelper.MemberType | undefined): number {
    if (typeof v === 'number' && Number.isFinite(v) && v > 0) {
      return Math.floor(v);
    }
    if (typeof v === 'string' && v.length > 0) {
      const n = Number.parseInt(v, 10);
      if (!Number.isNaN(n) && n > 0) {
        return n;
      }
    }
    return 0;
  }

  private static parsePositiveInt(s: string | undefined): number {
    if (s === undefined || s === null || s.length === 0) {
      return 0;
    }
    const n = Number.parseInt(s, 10);
    if (Number.isNaN(n) || n <= 0) {
      return 0;
    }
    return n;
  }

  private static async extractThumbnail(
    videoPath: string,
    sandboxDir: string,
    size: ThumbSize | null,
  ): Promise<string> {
    let file: fs.File | null = null;
    let generator: media.AVImageGenerator | null = null;
    let pixelMap: image.PixelMap | null = null;
    let packer: image.ImagePacker | null = null;
    let thumbFile: fs.File | null = null;
    try {
      file = await fs.open(videoPath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(videoPath);
      generator = await media.createAVImageGenerator();
      const fdSrc: media.AVFileDescriptor = {
        fd: file.fd,
        offset: 0,
        length: stat.size,
      };
      generator.fdSrc = fdSrc;
      const pixelParams: media.PixelMapParams = {};
      if (size !== null) {
        pixelParams.width = size.width;
        pixelParams.height = size.height;
      }
      pixelMap = await generator.fetchFrameByTime(
        0,
        media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC,
        pixelParams,
      );
      packer = image.createImagePacker();
      const packOpt: image.PackingOption = {
        format: 'image/jpeg',
        quality: 85,
      };
      const jpegBuffer = await packer.packing(pixelMap, packOpt);
      const rand = Math.floor(Math.random() * 1e6);
      const dstPath = `${sandboxDir}/thumb_${Date.now()}_${rand}.jpg`;
      thumbFile = await fs.open(
        dstPath,
        fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC,
      );
      await fs.write(thumbFile.fd, jpegBuffer);
      return dstPath;
    } catch (e) {
      console.warn(`${VideoRecorderHelper.TAG} extractThumbnail failed`,
        (e as BusinessError).message);
      return '';
    } finally {
      if (thumbFile !== null) {
        try {
          await fs.close(thumbFile);
        } catch (_) {
          // ignore
        }
      }
      if (packer !== null) {
        try {
          await packer.release();
        } catch (_) {
          // ignore
        }
      }
      if (pixelMap !== null) {
        try {
          await pixelMap.release();
        } catch (_) {
          // ignore
        }
      }
      if (generator !== null) {
        try {
          await generator.release();
        } catch (_) {
          // ignore
        }
      }
      if (file !== null) {
        try {
          await fs.close(file);
        } catch (_) {
          // ignore
        }
      }
    }
  }

  private static resolveMediaTypes(recordMode: number): cameraPicker.PickerMediaType[] {
    switch (recordMode) {
      case VideoRecordMode.PHOTO_ONLY:
        return [cameraPicker.PickerMediaType.PHOTO];
      case VideoRecordMode.VIDEO_ONLY:
        return [cameraPicker.PickerMediaType.VIDEO];
      case VideoRecordMode.MIXED:
      default:
        return [cameraPicker.PickerMediaType.PHOTO, cameraPicker.PickerMediaType.VIDEO];
    }
  }

  private static isPhotoResult(ext: string, mediaTypes: cameraPicker.PickerMediaType[]): boolean {
    if (mediaTypes.length === 1 && mediaTypes[0] === cameraPicker.PickerMediaType.PHOTO) {
      return true;
    }
    if (mediaTypes.length === 1 && mediaTypes[0] === cameraPicker.PickerMediaType.VIDEO) {
      return false;
    }
    return PHOTO_EXT.includes(ext.toLowerCase());
  }

  private static async ensureSandboxDir(cacheDir: string | null): Promise<string | null> {
    if (cacheDir === null || cacheDir.length === 0) {
      return null;
    }
    const subDir = `${cacheDir}/${VideoRecorderHelper.SANDBOX_SUBDIR}`;
    try {
      const exists = await fs.access(subDir);
      if (!exists) {
        await fs.mkdir(subDir, true);
      }
      return subDir;
    } catch (e) {
      console.error(`${VideoRecorderHelper.TAG} ensureSandboxDir failed ${subDir}`,
        (e as BusinessError).message);
      return null;
    }
  }

  private static async copyToSandbox(
    srcUri: string,
    sandboxDir: string,
    fileName: string,
  ): Promise<string | null> {
    const suffix = `${Date.now()}_${Math.floor(Math.random() * 1e6)}`;
    const dstPath = `${sandboxDir}/${suffix}_${fileName}`;
    let srcFile: fs.File | null = null;
    let dstFile: fs.File | null = null;
    try {
      srcFile = await fs.open(srcUri, fs.OpenMode.READ_ONLY);
      dstFile = await fs.open(
        dstPath,
        fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC,
      );
      await fs.copyFile(srcFile.fd, dstFile.fd);
      return dstPath;
    } catch (e) {
      console.error(`${VideoRecorderHelper.TAG} copyToSandbox failed src=${srcUri}`,
        (e as BusinessError).message);
      return null;
    } finally {
      if (srcFile !== null) {
        try {
          await fs.close(srcFile);
        } catch (closeErr) {
          console.warn(`${VideoRecorderHelper.TAG} close(src) failed`,
            (closeErr as BusinessError).message);
        }
      }
      if (dstFile !== null) {
        try {
          await fs.close(dstFile);
        } catch (closeErr) {
          console.warn(`${VideoRecorderHelper.TAG} close(dst) failed`,
            (closeErr as BusinessError).message);
        }
      }
    }
  }

  private static getFileNameFromPath(filePath: string): string {
    const idx = filePath.lastIndexOf('/');
    return idx >= 0 ? filePath.substring(idx + 1) : filePath;
  }

  private static getFileExtension(fileName: string): string {
    const idx = fileName.lastIndexOf('.');
    if (idx > 0 && idx < fileName.length - 1) {
      return fileName.substring(idx + 1).toLowerCase();
    }
    return '';
  }
}
