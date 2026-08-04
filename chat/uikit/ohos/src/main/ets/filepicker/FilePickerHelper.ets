import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';

/**
 * OHOS 端 file picker 核心工具类。
 * 与 harmony/atomic_x/filepicker/components/FilePicker.ets 逻辑一致(直接复用),
 * 额外增加:选完后把 file://docs/... URI 拷贝到应用沙盒 cacheDir 再返回绝对路径。
 *
 * 【为什么必须拷贝到沙盒】
 * 鸿蒙 DocumentViewPicker 返回的是跨应用授权的 URI(file://docs/...),
 * 授权只对当前 ArkTS 进程内的 @ohos.file.fs 生效;
 * IMSDK 底层通过 FFI(C++)读文件时拿不到 ArkTS 层的授权 context,
 * 直接把 URI 塞给 IMSDK 会返回 6017 Failed to create im message。
 * 所以要在这里 fs.copyFile 把内容复制到 context.cacheDir 下,
 * 交给 FFI 一个普通的沙盒绝对路径即可自由读。
 */

export interface PickerResult {
  filePath: string;
  fileName: string;
  fileSize: number;
  extension: string;
}

export default class FilePickerHelper {
  private static readonly TAG = 'ChatUiKit.FilePickerHelper';
  private static readonly DEFAULT_MAX_COUNT = 9;
  private static readonly SANDBOX_SUBDIR = 'file_picker';

  static async pickFiles(maxCount: number, cacheDir: string | null): Promise<PickerResult[]> {
    const max = maxCount > 0 ? maxCount : FilePickerHelper.DEFAULT_MAX_COUNT;
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const options: picker.DocumentSelectOptions = { maxSelectNumber: max };
      const uris = await documentPicker.select(options);
      if (!uris || uris.length === 0) {
        return [];
      }
      const trimmed = uris.length > max ? uris.slice(0, max) : uris;

      const sandboxDir = await FilePickerHelper.ensureSandboxDir(cacheDir);
      if (sandboxDir === null) {
        console.error(`${FilePickerHelper.TAG} no cacheDir available, aborting`);
        return [];
      }

      const results: PickerResult[] = [];
      for (const uri of trimmed) {
        const fileName = FilePickerHelper.getFileNameFromPath(uri);
        const extension = FilePickerHelper.getFileExtension(fileName);

        const sandboxPath = await FilePickerHelper.copyToSandbox(uri, sandboxDir, fileName);
        if (sandboxPath === null) {
          console.warn(`${FilePickerHelper.TAG} skip file: copy failed for ${uri}`);
          continue;
        }

        let size = 0;
        try {
          const stat = await fs.stat(sandboxPath);
          size = stat.size;
        } catch (statErr) {
          console.warn(`${FilePickerHelper.TAG} stat failed for ${sandboxPath}`,
            (statErr as BusinessError).message);
        }
        results.push({
          filePath: sandboxPath,
          fileName: fileName,
          fileSize: size,
          extension: extension,
        });
      }
      return results;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`${FilePickerHelper.TAG} pickFiles failed code=${err.code}, msg=${err.message}`);
      return [];
    }
  }

  /** 确保 ${cacheDir}/file_picker 存在,返回子目录绝对路径。 */
  private static async ensureSandboxDir(cacheDir: string | null): Promise<string | null> {
    if (cacheDir === null || cacheDir.length === 0) {
      return null;
    }
    const subDir = `${cacheDir}/${FilePickerHelper.SANDBOX_SUBDIR}`;
    try {
      const exists = await fs.access(subDir);
      if (!exists) {
        await fs.mkdir(subDir, true);
      }
      return subDir;
    } catch (e) {
      console.error(`${FilePickerHelper.TAG} ensureSandboxDir failed ${subDir}`,
        (e as BusinessError).message);
      return null;
    }
  }

  /**
   * 把 SAF URI 内容拷贝到沙盒。用 fd 方式,兼容 file://docs/... URI:
   *   1. fs.open(srcUri, READ_ONLY) 借当前 ArkTS 授权拿到 fd
   *   2. fs.open(dstPath, CREATE|WRITE_ONLY|TRUNC) 拿目标 fd
   *   3. fs.copyFile(srcFd, dstFd) 走 fd → fd 拷贝
   * 目标文件名前缀 timestamp+rand,避免同 App 多次选中同名文件冲突。
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
      console.error(`${FilePickerHelper.TAG} copyToSandbox failed src=${srcUri}`,
        (e as BusinessError).message);
      return null;
    } finally {
      if (srcFile !== null) {
        try {
          await fs.close(srcFile);
        } catch (closeErr) {
          console.warn(`${FilePickerHelper.TAG} close(src) failed`,
            (closeErr as BusinessError).message);
        }
      }
      if (dstFile !== null) {
        try {
          await fs.close(dstFile);
        } catch (closeErr) {
          console.warn(`${FilePickerHelper.TAG} close(dst) failed`,
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
