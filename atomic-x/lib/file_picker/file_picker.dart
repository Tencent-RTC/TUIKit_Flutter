import 'dart:io';

import 'package:tuikit_atomic_x/base_component/base_component.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/device_info/device.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'file_picker_platform.dart';

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
    return 'PickerResult(filePath: $filePath, fileName: $fileName, fileSize: $fileSize, extension: $extension)';
  }
}

class FilePickerConfig {
  final int? maxCount;

  FilePickerConfig({
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
      // FilePicker uses SAF (Storage Access Framework) which doesn't require permissions
      // The system handles permission through the document picker UI
      if (!await _checkAndRequestPermission(context)) {
        return [];
      }

      if (Platform.isAndroid || Platform.isIOS) {
        int maxCount = config?.maxCount ?? maxFileCount;

        final List<PickerResult> results = await FilePickerPlatform.pickFiles(
          maxCount: maxCount,
          allowedMimeTypes: [],
        );

        if (results.isEmpty) {
          return [];
        }

        if (results.length > maxCount) {
          if (context.mounted) {
            AtomicLocalizations atomicLocal = AtomicLocalizations.of(context);
            _showErrorDialog(context, atomicLocal.maxCountFile(maxCount));
          }
          return results.take(maxCount).toList();
        }

        return results;
      } else {
        throw UnsupportedError('FilePicker only supports Android and iOS');
      }
    } catch (e) {
      debugPrint('FilePicker.pickFiles error: $e');
      return [];
    }
  }

  static Future<bool> _checkAndRequestPermission(BuildContext context) async {
    if (kIsWeb) {
      return true;
    }

    PermissionType permissionType;
    if (Platform.isAndroid) {
      final sdkInt = await Device.sdkInt;
      if (sdkInt! >= 33) {
        permissionType = PermissionType.photos;
      } else {
        permissionType = PermissionType.storage;
      }
    } else if (Platform.isIOS) {
      permissionType = PermissionType.photos;
    } else {
      return true;
    }

    Map<PermissionType, PermissionStatus> statusMap = await Permission.request([permissionType]);
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

  /// Open file with system default application
  ///
  /// Returns true if the file was successfully opened, false otherwise.
  /// On Android, uses Intent.ACTION_VIEW to open the file.
  /// On iOS, uses UIDocumentInteractionController to open the file.
  static Future<bool> openFile(String filePath) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        throw UnsupportedError('File opening only supports Android and iOS');
      }

      // Check if file exists
      final file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('FilePicker.openFile: File does not exist: $filePath');
        return false;
      }

      return await FilePickerPlatform.openFile(filePath);
    } catch (e) {
      debugPrint('FilePicker.openFile error: $e');
      return false;
    }
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
}
