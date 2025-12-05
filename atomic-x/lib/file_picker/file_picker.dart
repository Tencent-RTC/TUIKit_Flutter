import 'dart:io';

import 'package:tuikit_atomic_x/base_component/base_component.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/permission/permission.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PickerResult {
  final String filePath;
  final String fileName;
  final int fileSize;
  final String extension;

  const PickerResult({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.extension,
  });

  @override
  String toString() {
    return 'FilePickerResult(filePath: $filePath, fileName: $fileName, fileSize: $fileSize, extension: $extension)';
  }
}

enum FileType {
  any,
  media,
  image,
  video,
  audio,
}

class FilePickerConfig {
  final int? maxCount;
  final FileType? fileType;

  FilePickerConfig({
    this.fileType,
    this.maxCount,
  });
}

class FilePicker {
  static const int maxFileCount = 9;

  static final FilePicker instance = FilePicker._internal();

  FilePicker._internal();

  static Future<List<PickerResult>> pickFiles({
    required BuildContext context,
    FilePickerConfig? config,
  }) async {
    try {
      if (!await _checkAndRequestPermission(context)) {
        return [];
      }

      final file_picker.FilePickerResult? result = await file_picker.FilePicker.platform.pickFiles(
        type: config?.fileType != null ? _convertFileType(config!.fileType!) : file_picker.FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      int maxCount = config?.maxCount ?? maxFileCount;
      List<file_picker.PlatformFile> files = result.files;

      if (files.length > maxCount) {
        if (context.mounted) {
          AtomicLocalizations atomicLocal = AtomicLocalizations.of(context);
          _showErrorDialog(context, atomicLocal.maxCountFile(maxCount));
        }
        files = files.take(maxCount).toList();
      }

      List<PickerResult> results = [];

      for (final file in files) {
        String finalPath = file.path ?? '';

        if (finalPath.isNotEmpty) {
          results.add(PickerResult(
            filePath: finalPath,
            fileName: file.name,
            fileSize: file.size,
            extension: path.extension(file.name).toLowerCase().replaceFirst('.', ''),
          ));
        }
      }

      return results;
    } catch (e) {
      debugPrint('FilePickerService.pickMultipleFiles error: $e');
      return [];
    }
  }

  static file_picker.FileType _convertFileType(FileType type) {
    switch (type) {
      case FileType.any:
        return file_picker.FileType.any;
      case FileType.media:
        return file_picker.FileType.media;
      case FileType.image:
        return file_picker.FileType.image;
      case FileType.video:
        return file_picker.FileType.video;
      case FileType.audio:
        return file_picker.FileType.audio;
    }
  }

  static Future<bool> _checkAndRequestPermission(BuildContext context) async {
    if (kIsWeb) {
      return true;
    }

    PermissionType permissionType;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        permissionType = PermissionType.photos;
      } else {
        permissionType = PermissionType.storage;
      }
    } else if (Platform.isIOS) {
      permissionType = PermissionType.photos;
    } else {
      return true;
    }

    Map<PermissionType, PermissionStatus> statusMap =  await Permission.request([permissionType]);
    PermissionStatus status = statusMap[permissionType] ?? PermissionStatus.denied;

    if (status == PermissionStatus.granted) {
      return true;
    }

    if (status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied) {
      if (context.mounted) {
        final bool shouldOpenSettings = await _showPermissionDialog(context);
        if (shouldOpenSettings) {
          await Permission.openAppSettings();
        }
      }
      return false;
    }

    return status == PermissionStatus.granted || status == PermissionStatus.limited;
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    AtomicLocalizations atomicLocal = AtomicLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(atomicLocal.permissionNeeded),
              content: Text(atomicLocal.permissionDeniedContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(atomicLocal.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(atomicLocal.confirm),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static void _showErrorDialog(BuildContext context, String message) {
    AtomicLocalizations atomicLocal = AtomicLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(atomicLocal.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(atomicLocal.confirm),
            ),
          ],
        );
      },
    );
  }

  static Future<String> _copyFileToSandbox(file_picker.PlatformFile file) async {
    try {
      if (file.path == null) {
        debugPrint('_copyFileToSandbox, file path is empty');
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filesDir = path.join(appDocDir.path, 'files');

      final Directory filesDirObj = Directory(filesDir);
      if (!await filesDirObj.exists()) {
        await filesDirObj.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = '${timestamp}_${file.name}';
      final String newFilePath = path.join(filesDir, newFileName);

      final File sourceFile = File(file.path!);
      final File targetFile = await sourceFile.copy(newFilePath);

      return targetFile.path;
    } catch (e) {
      debugPrint('_copyFileToSandbox failed: $e');
      return file.path ?? '';
    }
  }
}
