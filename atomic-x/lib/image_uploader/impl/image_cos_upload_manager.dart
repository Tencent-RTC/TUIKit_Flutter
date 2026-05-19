import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageCosUploadManager {
  static const int _maxRetryCount = 3;
  static const int _retryDelayMs = 500;
  static const int _timeoutSeconds = 60;
  static const int _maxUploadSize = 100 * 1024 * 1024; // 100MB

  /// Upload file to COS
  /// Returns HTTP status code, or -1 on failure
  Future<int> uploadFile(String localPath, String cosUploadURL) async {
    if (localPath.isEmpty || cosUploadURL.isEmpty) {
      debugPrint('ImageCosUploadManager: Invalid parameters');
      return -1;
    }

    final uri = Uri.tryParse(cosUploadURL);
    if (uri == null || !uri.hasScheme) {
      debugPrint('ImageCosUploadManager: Invalid cosUploadURL: $cosUploadURL');
      return -1;
    }

    return await _uploadFileWithRetry(localPath, cosUploadURL, _maxRetryCount);
  }

  Future<int> _uploadFileWithRetry(String localPath, String cosUploadURL, int maxRetryCount) async {
    int currentRetry = 0;

    while (currentRetry <= maxRetryCount) {
      try {
        final statusCode = await _performUpload(localPath, cosUploadURL);

        if (statusCode >= 200 && statusCode < 300) {
          return statusCode;
        } else if (_shouldRetry(statusCode) && currentRetry < maxRetryCount) {
          currentRetry++;
          await Future.delayed(Duration(milliseconds: _retryDelayMs * currentRetry));
        } else {
          return statusCode;
        }
      } catch (e) {
        if (_shouldRetryOnError(e) && currentRetry < maxRetryCount) {
          currentRetry++;
          await Future.delayed(Duration(milliseconds: _retryDelayMs * currentRetry));
        } else {
          debugPrint('ImageCosUploadManager: Upload failed with error: $e');
          return -1;
        }
      }
    }

    return -1;
  }

  Future<int> _performUpload(String localPath, String cosUploadURL) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('File not found: $localPath');
    }

    final fileLength = await file.length();
    if (fileLength > _maxUploadSize) {
      throw Exception('File size ${fileLength} exceeds maximum upload size $_maxUploadSize');
    }
    final uri = Uri.parse(cosUploadURL);

    final request = http.StreamedRequest('PUT', uri);
    request.headers['Content-Type'] = 'application/octet-stream';
    request.contentLength = fileLength;

    file.openRead().listen(
      request.sink.add,
      onDone: request.sink.close,
      onError: request.sink.addError,
    );

    final streamedResponse = await request.send().timeout(const Duration(seconds: _timeoutSeconds));
    return streamedResponse.statusCode;
  }

  bool _shouldRetry(int statusCode) {
    return statusCode >= 500 || statusCode == 408 || statusCode == 429;
  }

  bool _shouldRetryOnError(dynamic error) {
    if (error == null) return false;

    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is TlsException) {
      return true;
    }

    return false;
  }
}
