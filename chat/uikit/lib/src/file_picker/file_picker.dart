import 'dart:io';

import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/device_info/device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'file_picker_platform.dart';
import '../common/language/gen/chat_localizations.dart';

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

  /// HarmonyOS detection. `Platform.isOhos` only exists in the Flutter-OH SDK,
  /// so we compare the OS string to stay compilable under standard Flutter.
  static bool get _isOhos => Platform.operatingSystem == 'ohos';

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

      if (Platform.isAndroid || Platform.isIOS || _isOhos) {
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
            ChatLocalizations chatLocal = ChatLocalizations.of(context);
            _showErrorDialog(context, chatLocal.maxCountFile(maxCount));
          }
          return results.take(maxCount).toList();
        }

        return results;
      } else {
        throw UnsupportedError(
            'FilePicker only supports Android, iOS and HarmonyOS');
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

    return Permission.checkAndRequest(context, [permissionType]);
  }

  /// Open file with system default application
  ///
  /// Returns true if the file was successfully opened, false otherwise.
  /// On Android, uses Intent.ACTION_VIEW to open the file.
  /// On iOS, uses UIDocumentInteractionController to open the file.
  /// On HarmonyOS, uses startAbility with implicit want (viewData).
  static Future<bool> openFile(String filePath) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS && !_isOhos) {
        throw UnsupportedError(
            'File opening only supports Android, iOS and HarmonyOS');
      }

      // On Android/iOS `filePath` is an absolute sandbox path, so dart:io File
      // can pre-validate existence cheaply. On HarmonyOS `filePath` is typically
      // a `file://docs/...` URI returned by DocumentViewPicker — dart:io File
      // cannot resolve such URIs, so we skip the check and let the native layer
      // decide.
      if (!_isOhos) {
        final file = File(filePath);
        if (!file.existsSync()) {
          debugPrint('FilePicker.openFile: File does not exist: $filePath');
          return false;
        }
      }

      return await FilePickerPlatform.openFile(filePath);
    } catch (e) {
      debugPrint('FilePicker.openFile error: $e');
      return false;
    }
  }

  static void _showErrorDialog(BuildContext context, String message) {
    ChatLocalizations chatLocal = ChatLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(chatLocal.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(chatLocal.confirm),
            ),
          ],
        );
      },
    );
  }
}
