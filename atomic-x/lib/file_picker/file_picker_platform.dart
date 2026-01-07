import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'file_picker.dart' show PickerResult;

class FilePickerPlatform {
  static const MethodChannel _methodChannel =
      MethodChannel('atomic_x/file_picker');

  /// Pick files using native implementation
  static Future<List<PickerResult>> pickFiles({
    int maxCount = 1,
    List<String> allowedMimeTypes = const [],
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
          'Native FilePicker is only supported on Android and iOS');
    }

    try {
      final result = await _methodChannel.invokeMethod('pickFiles', {
        'maxCount': maxCount,
        'allowedMimeTypes': allowedMimeTypes,
      });

      if (result == null || result is! List) {
        return [];
      }

      final List<PickerResult> pickerResults = [];
      for (final item in result) {
        if (item is Map) {
          pickerResults.add(PickerResult(
            filePath: item['filePath'] as String? ?? '',
            fileName: item['fileName'] as String? ?? '',
            fileSize: (item['fileSize'] as num?)?.toInt() ?? 0,
            extension: item['extension'] as String? ?? '',
          ));
        }
      }

      return pickerResults;
    } catch (e) {
      print('FilePickerPlatform.pickFiles error: $e');
      rethrow;
    }
  }

  /// Open file with system default application
  static Future<bool> openFile(String filePath) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
          'Native file opening is only supported on Android and iOS');
    }

    try {
      final result = await _methodChannel.invokeMethod<bool>('openFile', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      print('FilePickerPlatform.openFile error: $e');
      return false;
    }
  }
}
