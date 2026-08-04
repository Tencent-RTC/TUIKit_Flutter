import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { dataSharePredicates } from '@kit.ArkData';
import { image } from '@kit.ImageKit';
import { media } from '@kit.MediaKit';

/**
 * OHOS 端 album picker 核心工具类。
 *
 * 视频缩略图为什么走 photoAccessHelper.asset.getThumbnail() 优先(与 VideoRecorderHelper 一致):
 *   仅用 AVMetadataExtractor + AVImageGenerator 时,存储侧宽高不含 orientation。
 *   竖持拍摄的视频 metadata 的 videoWidth/videoHeight = 1920x1080(横的),
 *   AVImageGenerator.fetchFrameByTime 内部会做 orientation 修正、输出"正立"竖屏帧,
 *   若我们仍按 storage 宽高传 pixelParams(width=1920,height=1080),
 *   系统被要求把 1080x1920 的正立帧压进 1920x1080 目标 -> 缩略图被横向拉伸(bug#161206638)。
 *
 * 双路径策略:
 *   1) 首选  resolveVideoMetadataFromAsset  ——  拷贝到沙盒 *前* 用原始 media URI 查 asset,
 *      duration/orientation/thumbnail 全交给系统统一处理,方向永远正确、比例永远正确。
 *   2) 兜底  resolveVideoMetadataFromFile   ——  拷贝后从沙盒文件读,
 *      通过 AVMetadataExtractor 拿 videoOrientation,把存储宽高 swap 为显示宽高,
 *      再把"显示宽高"作为 pixelParams 传给 AVImageGenerator,规避拉伸。
 */

export enum AlbumPickMode {
  IMAGE = 0,   // AlbumPickerMediaFilter.imageOnly / AlbumMediaType.image
  VIDEO = 1,   // AlbumPickerMediaFilter.videoOnly / AlbumMediaType.video
  IMAGE_AND_VIDEO = 2,
}

export interface AlbumPickResult {
  filePath: string;       // 拷贝到沙盒后的绝对路径
  fileName: string;
  fileSize: number;
  extension: string;
  /** 0=image, 1=video */
  mediaTypeIndex: number;
  /** video 专用:时长(毫秒),image 恒为 0。 */
  durationMs: number;
  /** video 专用:缩略图沙盒 jpg 绝对路径,image 恒为空串。 */
  videoThumbnailPath: string;
}

/** resolveVideoMetadataFromAsset 内部返回。 */
interface VideoAssetMeta {
  durationMs: number;
  thumbnailPath: string;
}

/**
 * extractVideoInfo 返回:含存储宽高 + orientation。
 * orientation ∈ {0, 90, 180, 270}:顺时针旋转多少度才是"正立"方向,
 * 0/180 表示存储方向就是显示方向,90/270 表示需要 swap 宽高。
 */
interface VideoInfoOut {
  durationMs: number;
  width: number;
  height: number;
  orientation: number;
}

/** 缩略图目标尺寸(显示侧)。 */
interface ThumbSize {
  width: number;
  height: number;
}

const IMAGE_EXT: string[] = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'svg', 'heic', 'heif'];
const VIDEO_EXT: string[] = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', '3gp', 'webm', 'm4v'];

export default class AlbumPickerHelper {
  private static readonly TAG = 'AtomicX.AlbumPickerHelper';
  private static readonly SANDBOX_SUBDIR = 'album_picker';

  static async pickMedia(
    pickMode: number,
    maxCount: number,
    cacheDir: string | null,
    ctx: common.Context | null,   // photoAccessHelper.getPhotoAccessHelper() 用,可为 null 时走 fallback
  ): Promise<AlbumPickResult[]> {
    const max = Math.max(1, maxCount);
    const options = new photoAccessHelper.PhotoSelectOptions();
    switch (pickMode) {
      case AlbumPickMode.IMAGE:
        options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
        break;
      case AlbumPickMode.VIDEO:
        options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
        break;
      case AlbumPickMode.IMAGE_AND_VIDEO:
      default:
        options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE;
        break;
    }
    options.maxSelectNumber = max;

    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const selectResult = await picker.select(options);
      if (!selectResult || !selectResult.photoUris || selectResult.photoUris.length === 0) {
        return [];
      }

      const sandboxDir = await AlbumPickerHelper.ensureSandboxDir(cacheDir);
      if (sandboxDir === null) {
        console.error(`${AlbumPickerHelper.TAG} no cacheDir available, aborting`);
        return [];
      }

      const results: AlbumPickResult[] = [];
      for (const uri of selectResult.photoUris) {
        const fileName = AlbumPickerHelper.getFileNameFromPath(uri);
        const ext = AlbumPickerHelper.getFileExtension(fileName);
        const mediaTypeIndex = AlbumPickerHelper.resolveMediaTypeIndex(ext);

        // 视频分支:必须在拷贝到沙盒 *之前* 用原 media library URI 拿 asset,
        // 因为 asset 只认 file://media/... 这类系统 URI。拷贝到沙盒之后原 URI 就丢了。
        // 拿不到 asset(权限缺失 / 非 media URI / ctx 空)时返回 {0, ''},由拷贝后 fallback 兜底。
        let assetMeta: VideoAssetMeta = { durationMs: 0, thumbnailPath: '' };
        if (mediaTypeIndex === AlbumPickMode.VIDEO && ctx !== null) {
          assetMeta = await AlbumPickerHelper.resolveVideoMetadataFromAsset(uri, sandboxDir, ctx);
        }

        const sandboxPath = await AlbumPickerHelper.copyToSandbox(uri, sandboxDir, fileName);
        if (sandboxPath === null) {
          console.warn(`${AlbumPickerHelper.TAG} skip media: copy failed for ${uri}`);
          continue;
        }

        let size = 0;
        try {
          const stat = await fs.stat(sandboxPath);
          size = stat.size;
        } catch (statErr) {
          console.warn(`${AlbumPickerHelper.TAG} stat failed for ${sandboxPath}`,
            (statErr as BusinessError).message);
        }

        // 视频必须补齐 duration + 缩略图,否则:
        //   1) VideoMessagePayload.videoDuration=0 -> bubble 显示 00:00
        //   2) videoSnapshotPath 为空 -> Dart 侧只能用黑图占位,且部分场景 IMSDK
        //      createVideoMessage 因 snapshot 缺失导致发送失败(bug#161206638)。
        let durationMs = assetMeta.durationMs;
        let videoThumbnailPath = assetMeta.thumbnailPath;
        if (mediaTypeIndex === AlbumPickMode.VIDEO
          && (durationMs === 0 || videoThumbnailPath.length === 0)) {
          console.info(`${AlbumPickerHelper.TAG} asset path incomplete ` +
            `(duration=${durationMs}, thumb='${videoThumbnailPath}'), fallback to AVMetadataExtractor`);
          const fb = await AlbumPickerHelper.resolveVideoMetadataFromFile(sandboxPath, sandboxDir);
          if (durationMs === 0) {
            durationMs = fb.durationMs;
          }
          if (videoThumbnailPath.length === 0) {
            videoThumbnailPath = fb.thumbnailPath;
          }
        }
        // 双路径都拿不到缩略图 -> 兜底黑图,保证 IMSDK createVideoMessage 不会因缺 snapshot 失败
        if (mediaTypeIndex === AlbumPickMode.VIDEO && videoThumbnailPath.length === 0) {
          videoThumbnailPath = await AlbumPickerHelper.generateBlackThumbnail(sandboxDir);
          console.info(`${AlbumPickerHelper.TAG} both paths failed, fallback black thumb=${videoThumbnailPath}`);
        }
        if (mediaTypeIndex === AlbumPickMode.VIDEO) {
          console.info(`${AlbumPickerHelper.TAG} video meta durationMs=${durationMs} ` +
            `thumb=${videoThumbnailPath.length > 0 ? 'ok' : 'empty'} path=${sandboxPath}`);
        }

        results.push({
          filePath: sandboxPath,
          fileName: fileName,
          fileSize: size,
          extension: ext,
          mediaTypeIndex: mediaTypeIndex,
          durationMs: durationMs,
          videoThumbnailPath: videoThumbnailPath,
        });
      }
      return results;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`${AlbumPickerHelper.TAG} pickMedia failed code=${err.code}, msg=${err.message}`);
      return [];
    }
  }

  /** 确保 ${cacheDir}/album_picker 存在,返回子目录绝对路径。 */
  private static async ensureSandboxDir(cacheDir: string | null): Promise<string | null> {
    if (cacheDir === null || cacheDir.length === 0) {
      return null;
    }
    const subDir = `${cacheDir}/${AlbumPickerHelper.SANDBOX_SUBDIR}`;
    try {
      const exists = await fs.access(subDir);
      if (!exists) {
        await fs.mkdir(subDir, true);
      }
      return subDir;
    } catch (e) {
      console.error(`${AlbumPickerHelper.TAG} ensureSandboxDir failed ${subDir}`,
        (e as BusinessError).message);
      return null;
    }
  }

  /**
   * 把 photoAccessHelper 返回的 file://media/... URI 拷贝到沙盒。
   * 用 fd 方式,兼容跨应用授权 URI(参考 filepicker 同名函数)。
   */
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
      console.error(`${AlbumPickerHelper.TAG} copyToSandbox failed src=${srcUri}`,
        (e as BusinessError).message);
      return null;
    } finally {
      if (srcFile !== null) {
        try {
          await fs.close(srcFile);
        } catch (closeErr) {
          console.warn(`${AlbumPickerHelper.TAG} close(src) failed`,
            (closeErr as BusinessError).message);
        }
      }
      if (dstFile !== null) {
        try {
          await fs.close(dstFile);
        } catch (closeErr) {
          console.warn(`${AlbumPickerHelper.TAG} close(dst) failed`,
            (closeErr as BusinessError).message);
        }
      }
    }
  }

  /**
   * 兜底路径:走沙盒文件,用 AVMetadataExtractor 读 duration + orientation,
   * 用 AVImageGenerator 抓首帧生成缩略图。
   *
   * 关键点(bug#161206638 修复):
   *   extractor 里读到的 videoWidth/videoHeight 是"存储侧"(编码尺寸,不含 orientation),
   *   竖持拍摄的视频存的是 1920x1080,orientation=90 说明"顺时针旋转 90° 才是正立"。
   *   AVImageGenerator.fetchFrameByTime 内部会做 orientation 修正,输出"正立"竖屏帧。
   *   我们必须把 pixelParams 也传"显示侧"宽高(swap 后的 1080x1920),
   *   否则系统会把 1080x1920 的正立帧压进 1920x1080 目标,导致横向拉伸。
   *
   * 缩略图返回空串时不再当场兜底黑图,由上层 pickMedia 统一在 asset+file 双路径都失败后兜底。
   */
  private static async resolveVideoMetadataFromFile(
    videoPath: string,
    sandboxDir: string,
  ): Promise<VideoAssetMeta> {
    const info = await AlbumPickerHelper.extractVideoInfo(videoPath);
    // orientation ∈ {90, 270} 时,把存储宽高交换成显示宽高
    const isRotated = info.orientation === 90 || info.orientation === 270;
    const displayW = isRotated ? info.height : info.width;
    const displayH = isRotated ? info.width : info.height;
    const thumbSize = AlbumPickerHelper.pickThumbSize(displayW, displayH);
    const thumbnailPath = await AlbumPickerHelper.extractThumbnail(videoPath, sandboxDir, thumbSize);
    console.info(
      `${AlbumPickerHelper.TAG} [fallback] durationMs=${info.durationMs} ` +
      `stored=${info.width}x${info.height} orientation=${info.orientation} ` +
      `display=${displayW}x${displayH} ` +
      `target=${thumbSize === null ? 'null' : `${thumbSize.width}x${thumbSize.height}`}`,
    );
    return { durationMs: info.durationMs, thumbnailPath: thumbnailPath };
  }

  /**
   * 生成一张 32x32 全黑 JPEG 到 sandboxDir,作为 extractThumbnail 失败时的兜底,
   * 保证 IMSDK createVideoMessage 拿到的 snapshotPath 一定在 cacheDir 下且真实存在。
   * 任何步骤失败都返回空串(此时上层视频消息仍会发送失败,但至少不会因误挑 tempDir 而失败)。
   */
  private static async generateBlackThumbnail(sandboxDir: string): Promise<string> {
    const SIDE = 32;
    let pixelMap: image.PixelMap | null = null;
    let packer: image.ImagePacker | null = null;
    let thumbFile: fs.File | null = null;
    try {
      // RGBA_8888,全 0 即黑色(alpha=0,但 JPEG 不含 alpha,pack 出来就是纯黑)
      const buffer = new ArrayBuffer(SIDE * SIDE * 4);
      const opts: image.InitializationOptions = {
        editable: false,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        size: { width: SIDE, height: SIDE },
      };
      pixelMap = await image.createPixelMap(buffer, opts);
      packer = image.createImagePacker();
      const packOpt: image.PackingOption = { format: 'image/jpeg', quality: 85 };
      const jpegBuffer = await packer.packing(pixelMap, packOpt);
      const rand = Math.floor(Math.random() * 1e6);
      const dstPath = `${sandboxDir}/thumb_fallback_${Date.now()}_${rand}.jpg`;
      thumbFile = await fs.open(dstPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(thumbFile.fd, jpegBuffer);
      return dstPath;
    } catch (e) {
      console.error(`${AlbumPickerHelper.TAG} generateBlackThumbnail failed`, (e as BusinessError).message);
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
    }
  }

  private static async extractVideoInfo(videoPath: string): Promise<VideoInfoOut> {
    const fallback: VideoInfoOut = { durationMs: 0, width: 0, height: 0, orientation: 0 };
    let file: fs.File | null = null;
    let extractor: media.AVMetadataExtractor | null = null;
    try {
      file = await fs.open(videoPath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(videoPath);
      extractor = await media.createAVMetadataExtractor();
      const fdSrc: media.AVFileDescriptor = { fd: file.fd, offset: 0, length: stat.size };
      extractor.fdSrc = fdSrc;
      const meta = await extractor.fetchMetadata();
      return {
        durationMs: AlbumPickerHelper.parsePositiveInt(meta.duration),
        width: AlbumPickerHelper.parsePositiveInt(meta.videoWidth),
        height: AlbumPickerHelper.parsePositiveInt(meta.videoHeight),
        orientation: AlbumPickerHelper.parsePositiveInt(meta.videoOrientation),
      };
    } catch (e) {
      console.warn(`${AlbumPickerHelper.TAG} extractVideoInfo failed`, (e as BusinessError).message);
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
      const fdSrc: media.AVFileDescriptor = { fd: file.fd, offset: 0, length: stat.size };
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
      const packOpt: image.PackingOption = { format: 'image/jpeg', quality: 85 };
      const jpegBuffer = await packer.packing(pixelMap, packOpt);
      const rand = Math.floor(Math.random() * 1e6);
      const dstPath = `${sandboxDir}/thumb_${Date.now()}_${rand}.jpg`;
      thumbFile = await fs.open(dstPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(thumbFile.fd, jpegBuffer);
      return dstPath;
    } catch (e) {
      console.warn(`${AlbumPickerHelper.TAG} extractThumbnail failed`, (e as BusinessError).message);
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

  /**
   * 缩略图目标尺寸:保持 aspect,长边缩到 720;拿不到宽高返回 null(生成器用原始帧尺寸)。
   * 输入必须是"显示侧"宽高(orientation 已 swap 过),否则会拉伸,详见 resolveVideoMetadataFromFile 注释。
   */
  private static pickThumbSize(displayW: number, displayH: number): ThumbSize | null {
    const MAX_EDGE = 720;
    if (displayW <= 0 || displayH <= 0) {
      return null;
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
   * 首选路径:走 photoAccessHelper。仅当 srcUri 是 media library URI(file://media/...) 且
   * ctx 能查到 asset 时才成功。
   *   - duration    -> asset.get(PhotoKeys.DURATION)  单位:毫秒
   *   - width/height/orientation -> asset.get(...)    存储侧尺寸 + 顺时针需旋转角度
   *   - thumbnail   -> asset.getThumbnail(size)       系统直接生成"正立的" PixelMap,方向永远正确
   *
   * 必须传 size:asset.getThumbnail() 不传 size 时,华为返回 256x256 相册小图 + 自动 crop 成方形,
   * 消息 bubble 里会看到"方向对了但比例是方的"。传 size 后,系统按目标比例生成,不做方形裁切。
   * size 用"显示宽高"(把存储宽高按 orientation 交换),长边缩到 720 控制 JPEG 大小。
   *
   * 拿不到 asset(fetchResult 空 / 权限缺失 / 非 media URI)时返回 {0, ''},由上层走 fallback。
   */
  private static async resolveVideoMetadataFromAsset(
    srcUri: string,
    sandboxDir: string,
    ctx: common.Context,
  ): Promise<VideoAssetMeta> {
    const empty: VideoAssetMeta = { durationMs: 0, thumbnailPath: '' };
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
        console.warn(`${AlbumPickerHelper.TAG} no asset for uri=${srcUri}`);
        return empty;
      }
      const asset = await fetchResult.getFirstObject();

      const durationMs = AlbumPickerHelper.readPositiveNumber(
        asset.get(photoAccessHelper.PhotoKeys.DURATION));
      const storedW = AlbumPickerHelper.readPositiveNumber(
        asset.get(photoAccessHelper.PhotoKeys.WIDTH));
      const storedH = AlbumPickerHelper.readPositiveNumber(
        asset.get(photoAccessHelper.PhotoKeys.HEIGHT));
      const orientation = AlbumPickerHelper.readPositiveNumber(
        asset.get(photoAccessHelper.PhotoKeys.ORIENTATION));

      const isRotated = orientation === 90 || orientation === 270;
      const displayW = isRotated ? storedH : storedW;
      const displayH = isRotated ? storedW : storedH;
      const targetSize: image.Size = AlbumPickerHelper.pickAssetThumbSize(displayW, displayH);
      console.info(
        `${AlbumPickerHelper.TAG} asset meta durationMs=${durationMs} ` +
        `stored=${storedW}x${storedH} orientation=${orientation} ` +
        `display=${displayW}x${displayH} target=${targetSize.width}x${targetSize.height}`,
      );

      thumbnail = await asset.getThumbnail(targetSize);
      packer = image.createImagePacker();
      const packOpt: image.PackingOption = { format: 'image/jpeg', quality: 85 };
      const jpegBuffer = await packer.packing(thumbnail, packOpt);
      const rand = Math.floor(Math.random() * 1e6);
      const dstPath = `${sandboxDir}/thumb_${Date.now()}_${rand}.jpg`;
      thumbFile = await fs.open(dstPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(thumbFile.fd, jpegBuffer);
      return { durationMs: durationMs, thumbnailPath: dstPath };
    } catch (e) {
      console.warn(`${AlbumPickerHelper.TAG} resolveVideoMetadataFromAsset failed`,
        (e as BusinessError).message);
      return empty;
    } finally {
      if (thumbFile !== null) {
        try { await fs.close(thumbFile); } catch (_) { /* ignore */ }
      }
      if (packer !== null) {
        try { await packer.release(); } catch (_) { /* ignore */ }
      }
      if (thumbnail !== null) {
        try { await thumbnail.release(); } catch (_) { /* ignore */ }
      }
      if (fetchResult !== null) {
        try { fetchResult.close(); } catch (_) { /* ignore */ }
      }
    }
  }

  /**
   * asset.getThumbnail(size) 的目标尺寸:
   *   - 有显示宽高 -> 保持 aspect,长边缩到 720
   *   - 拿不到    -> 默认 720x1280(消息缩略图绝大多数是竖屏视频)
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

  /** asset.get(key) 返回 MemberType(number|string|boolean|null),这里安全解析成正整数,失败为 0。 */
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

  private static resolveMediaTypeIndex(ext: string): number {
    const lower = ext.toLowerCase();
    if (VIDEO_EXT.includes(lower)) {
      return AlbumPickMode.VIDEO; // 1
    }
    return AlbumPickMode.IMAGE;
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
