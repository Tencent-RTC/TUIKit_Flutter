import 'dart:io';
import 'dart:ui' as ui;

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/src/message_input/utils/image_size_reader.dart';
import 'package:tuikit_atomic_x/album_picker/album_picker.dart';

abstract class AlbumPickerMediaSendListener {
  void onSendMessage(MessageInfo messageInfo);

  void onSendPlaceholderMessage(MessageInfo placeholder);

  void onRemovePlaceholderMessage(MessageInfo placeholder);
}

class AlbumPickerMediaSendManager {
  static final AlbumPickerMediaSendManager shared = AlbumPickerMediaSendManager._();

  AlbumPickerMediaSendManager._();

  final Map<String, _PickerSession> _pickerSessions = {};

  Future<void> pickAlbumMedia({
    required String conversationID,
    required AlbumPickerMediaSendListener listener,
    AlbumPickerConfig? config,
    AlbumPickerTheme? theme,
  }) async {
    final sessionKey = '${DateTime.now().millisecondsSinceEpoch}_${conversationID.hashCode}';
    final session = _PickerSession(
      sessionKey: sessionKey,
      conversationID: conversationID,
      listener: listener,
    );
    _pickerSessions[sessionKey] = session;

    debugPrint("[MediaSendManager] pickAlbumMedia: session=$sessionKey, conversationID=$conversationID");

    await AlbumPicker.pickMedia(
      config: config,
      theme: theme,
      onPickConfirm: (pickedAlbumMedias, textMessage) {
        debugPrint("[MediaSendManager] onPickConfirm: ${pickedAlbumMedias.length} items, session=$sessionKey");
        _handlePickConfirm(pickedAlbumMedias: pickedAlbumMedias, session: session);
      },
      onMediaProcessing: (albumMedia, progress, error) {
        _handleMediaProcessing(media: albumMedia, progress: progress, error: error, session: session);
      },
      onMediaProcessed: () {
        debugPrint("[MediaSendManager] onMediaProcessed: session=$sessionKey");
        _pickerSessions.remove(sessionKey);
      },
      onCancel: () {
        debugPrint("[MediaSendManager] onCancel: session=$sessionKey");
        _pickerSessions.remove(sessionKey);
      },
    );
  }

  void _handlePickConfirm({
    required List<AlbumMedia> pickedAlbumMedias,
    required _PickerSession session,
  }) async {
    String? blackSnapshotPath;

    for (final media in pickedAlbumMedias) {
      if (session.processedMediaIds.contains(media.id)) continue;

      final state = _MediaState();
      state.mediaType = media.mediaType;
      session.mediaStates[media.id] = state;

      String thumbnailPath = media.videoThumbnailPath ?? '';
      if (thumbnailPath.isEmpty) {
        blackSnapshotPath ??= await _generateBlackSnapshot();
        thumbnailPath = blackSnapshotPath;
      }

      if (!session.mediaStates.containsKey(media.id)) continue;

      state.thumbnailPath = thumbnailPath;

      if (thumbnailPath.isNotEmpty) {
        final placeholder = await _createPlaceholderMessage(
          thumbnailPath: thumbnailPath,
          mediaType: media.mediaType,
        );

        if (state.processed) {
          session.mediaStates.remove(media.id);
          continue;
        }

        state.placeholder = placeholder;
        session.listener.onSendPlaceholderMessage(placeholder);
      }
    }
  }

  void restorePlaceholders({
    required String conversationID,
    required AlbumPickerMediaSendListener listener,
  }) {
    for (final session in _pickerSessions.values) {
      if (session.conversationID != conversationID) continue;
      session.listener = listener;

      for (final state in session.mediaStates.values) {
        if (state.progress >= 1.0 || state.thumbnailPath == null) continue;
        state.placeholder = null;

        _createPlaceholderMessage(
          thumbnailPath: state.thumbnailPath!,
          mediaType: state.mediaType,
        ).then((placeholder) {
          placeholder.uploadMediaProgress = (state.progress * 100).toInt();
          state.placeholder = placeholder;
          listener.onSendPlaceholderMessage(placeholder);
        });
      }
    }
  }

  void _handleMediaProcessing({
    required AlbumMedia media,
    required double progress,
    required bool error,
    required _PickerSession session,
  }) {
    if (error) return;

    switch (media.mediaType) {
      case AlbumMediaType.image:
        _handleImageProcessing(media: media, progress: progress, session: session);
        break;
      case AlbumMediaType.video:
        _handleVideoProcessing(media: media, progress: progress, session: session);
        break;
    }
  }

  Future<void> _handleImageProcessing({
    required AlbumMedia media,
    required double progress,
    required _PickerSession session,
  }) async {
    if (progress < 1.0 || media.mediaPath.isEmpty) return;

    final state = session.mediaStates[media.id];

    if (state == null) {
      session.processedMediaIds.add(media.id);
    } else {
      state.processed = true;
    }

    final placeholderToRemove = state?.placeholder;
    if (placeholderToRemove != null) {
      placeholderToRemove.uploadMediaProgress = 100;
      session.listener.onRemovePlaceholderMessage(placeholderToRemove);
    }

    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.image;
    final size = await ImageSizeReader.read(media.mediaPath);
    messageInfo.messagePayload = ImageMessagePayload(
      originalImagePath: media.mediaPath,
      originalImageWidth: size?.width ?? 0,
      originalImageHeight: size?.height ?? 0,
    );

    session.listener.onSendMessage(messageInfo);

    if (state?.placeholder != null) {
      session.mediaStates.remove(media.id);
    }
  }

  void _handleVideoProcessing({
    required AlbumMedia media,
    required double progress,
    required _PickerSession session,
  }) {
    final state = session.mediaStates[media.id];

    if (state == null) {
      if (progress >= 1.0 && media.mediaPath.isNotEmpty) {
        session.processedMediaIds.add(media.id);
        _sendVideo(media: media, state: _MediaState(), session: session);
      }
      return;
    }

    state.progress = progress;

    if (state.placeholder != null && progress < 1.0) {
      state.placeholder!.uploadMediaProgress = (progress * 100).toInt();
    }

    if (progress >= 1.0 && media.mediaPath.isNotEmpty) {
      _sendVideo(media: media, state: state, session: session);
    }
  }

  Future<MessageInfo> _createPlaceholderMessage({
    required String thumbnailPath,
    required AlbumMediaType mediaType,
  }) async {
    final placeholder = MessageInfo();
    placeholder.msgID = 'placeholder_${DateTime.now().millisecondsSinceEpoch}_${thumbnailPath.hashCode}';
    placeholder.messageType = mediaType == AlbumMediaType.video ? MessageType.video : MessageType.image;
    placeholder.status = MessageStatus.sending;
    placeholder.isSentBySelf = true;
    placeholder.timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final userInfo = LoginStore.shared.loginState.loginUserInfo;
    if (userInfo != null) {
      placeholder.from = MessageSenderInfo(
        userID: userInfo.userID,
        avatarURL: userInfo.avatarURL,
        nickname: userInfo.nickname,
      );
    }

    if (mediaType == AlbumMediaType.video) {
      placeholder.messagePayload = VideoMessagePayload(
        videoSnapshotPath: thumbnailPath,
      );
    } else {
      final size = await ImageSizeReader.read(thumbnailPath);
      placeholder.messagePayload = ImageMessagePayload(
        originalImagePath: thumbnailPath,
        originalImageWidth: size?.width ?? 0,
        originalImageHeight: size?.height ?? 0,
      );
    }

    return placeholder;
  }

  void _sendVideo({
    required AlbumMedia media,
    required _MediaState state,
    required _PickerSession session,
  }) async {
    final placeholderToRemove = state.placeholder;
    if (placeholderToRemove != null) {
      placeholderToRemove.uploadMediaProgress = 100;
      session.listener.onRemovePlaceholderMessage(placeholderToRemove);
    }

    String snapshotPath = media.videoThumbnailPath ?? '';
    if (snapshotPath.isEmpty) {
      snapshotPath = await _generateBlackSnapshot();
    }

    final messageInfo = MessageInfo();
    messageInfo.messageType = MessageType.video;
    // videoType 用于 IMSDK createVideoMessage 的 type 入参,不能为空。
    // 鸿蒙相册返回的沙盒文件名有时不带扩展名(media URI 无后缀),
    // split('.').last 会拿到整段文件名 -> 非法 type 导致发送失败,这里兜底为 mp4。
    final ext = media.mediaPath.contains('.') ? media.mediaPath.split('.').last : '';
    final videoType = (ext.isEmpty || ext.length > 5) ? 'mp4' : ext;

    messageInfo.messagePayload = VideoMessagePayload(
      videoPath: media.mediaPath,
      videoSnapshotPath: snapshotPath,
      videoDuration: (media.duration / 1000).round(),
      videoType: videoType,
    );

    session.listener.onSendMessage(messageInfo);
    session.mediaStates.remove(media.id);
  }

  String? _cachedBlackSnapshotPath;

  Future<String> _generateBlackSnapshot() async {
    if (_cachedBlackSnapshotPath != null && File(_cachedBlackSnapshotPath!).existsSync()) {
      return _cachedBlackSnapshotPath!;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 320, 240),
      Paint()..color = Colors.black,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(320, 240);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return '';
    final bytes = byteData.buffer.asUint8List();
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/album_picker_black_snapshot.png');
    await file.writeAsBytes(bytes);
    _cachedBlackSnapshotPath = file.path;
    return file.path;
  }
}

class _PickerSession {
  final String sessionKey;
  final String conversationID;
  AlbumPickerMediaSendListener listener;
  final Map<int, _MediaState> mediaStates = {};
  final Set<int> processedMediaIds = {};

  _PickerSession({
    required this.sessionKey,
    required this.conversationID,
    required this.listener,
  });
}

class _MediaState {
  MessageInfo? placeholder;
  String? thumbnailPath;
  AlbumMediaType mediaType;
  double progress = 0;
  bool processed = false;

  _MediaState({this.mediaType = AlbumMediaType.image});
}
