import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

enum GiftResourceLoaderError { invalidURL, invalidResponse, downloadFailed }

class GiftResourceLoaderException implements Exception {
  const GiftResourceLoaderException(this.error);
  final GiftResourceLoaderError error;
  @override
  String toString() => 'GiftResourceLoaderException($error)';
}

/// 按 URL 摘要缓存特效资源；并发下载独立落盘，完整文件才可作为缓存。
class GiftResourceLoader {
  GiftResourceLoader({HttpClient? httpClient, Directory? cacheDirectory})
      : _httpClient = httpClient ?? HttpClient(),
        _ownsClient = httpClient == null,
        _cacheDirectory = cacheDirectory;

  final HttpClient _httpClient;
  final bool _ownsClient;
  static const String _cacheSubPath = 'TUILiveKit/PusherGiftEffects';
  Directory? _cacheDirectory;
  bool _disposed = false;
  final Set<_Download> _downloads = {};

  Future<String> load(String resourceURL) async {
    final uri = Uri.tryParse(resourceURL);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const GiftResourceLoaderException(
          GiftResourceLoaderError.invalidURL);
    }
    if (_disposed) {
      throw const GiftResourceLoaderException(
          GiftResourceLoaderError.downloadFailed);
    }
    final download = _Download(resourceURL);
    _downloads.add(download);
    Directory? temporaryDirectory;
    IOSink? sink;
    try {
      final file = await _cacheFile(uri);
      download.checkActive();
      if (await file.exists()) {
        download.checkActive();
        return file.path;
      }
      final request = await _httpClient.getUrl(uri);
      download.request = request;
      download.checkActive();
      final response = await request.close();
      final iterator = StreamIterator<List<int>>(response);
      download.iterator = iterator;
      download.checkActive();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await iterator.cancel();
        throw const GiftResourceLoaderException(
            GiftResourceLoaderError.invalidResponse);
      }
      await file.parent.create(recursive: true);
      temporaryDirectory = await file.parent.createTemp('download-');
      final temporaryFile = File('${temporaryDirectory.path}/resource');
      sink = temporaryFile.openWrite();
      download.checkActive();
      while (await iterator.moveNext()) {
        download.checkActive();
        sink.add(iterator.current);
        await sink.flush();
      }
      await sink.flush();
      await sink.close();
      sink = null;
      download.checkActive();
      // 另一个下载可能已完成；不删除它，也不让半截文件覆盖有效缓存。
      if (!await file.exists()) {
        download.checkActive();
        try {
          await temporaryFile.rename(file.path);
        } on FileSystemException {
          // 两个请求可在同一时间结束；另一份完整缓存已落盘时复用它。
          if (!await file.exists()) rethrow;
        }
      }
      download.checkActive();
      return file.path;
    } on GiftResourceLoaderException {
      rethrow;
    } on Object {
      throw const GiftResourceLoaderException(
          GiftResourceLoaderError.downloadFailed);
    } finally {
      _downloads.remove(download);
      await download.iterator?.cancel();
      await sink?.close();
      if (temporaryDirectory != null && await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  void cancel(String resourceURL) {
    for (final download
        in _downloads.where((item) => item.resourceURL == resourceURL)) {
      download.cancel();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final download in _downloads) {
      download.cancel();
    }
    if (_ownsClient) _httpClient.close(force: true);
  }

  Future<File> _cacheFile(Uri remoteURL) async {
    final directory = _cacheDirectory ??= Directory(
        '${(await getApplicationCacheDirectory()).path}/$_cacheSubPath');
    final digest = sha256.convert(utf8.encode(remoteURL.toString())).toString();
    final extension = _pathExtension(remoteURL);
    return File(
        '${directory.path}/$digest${extension.isEmpty ? '' : '.$extension'}');
  }

  static String _pathExtension(Uri url) {
    final path = url.path;
    final dotIndex = path.lastIndexOf('.');
    final slashIndex = path.lastIndexOf('/');
    if (dotIndex <= slashIndex + 1) return '';
    return path.substring(dotIndex + 1).toLowerCase();
  }
}

class _Download {
  _Download(this.resourceURL);
  final String resourceURL;
  HttpClientRequest? request;
  StreamIterator<List<int>>? iterator;
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    request?.abort();
    iterator?.cancel().ignore();
  }

  void checkActive() {
    if (!_cancelled) return;
    request?.abort();
    throw const GiftResourceLoaderException(
        GiftResourceLoaderError.downloadFailed);
  }
}
