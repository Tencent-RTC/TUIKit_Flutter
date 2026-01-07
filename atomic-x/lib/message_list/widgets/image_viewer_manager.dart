import 'dart:io';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/image_viewer/image_element.dart';

class ImageViewerManager {
  bool _isShowingImageViewer = false;
  List<ImageElement> _initialImageElements = [];
  int _initialImageIndex = 0;
  bool _isLoadingImageData = false;
  String _conversationID = '';

  ImageViewerDataManager? _imageViewerDataManager;
  final MessageListStore _messageListStore;
  final MessageInfo _currentMessage;

  ImageViewerManager({
    required String conversationID,
    required MessageInfo currentMessage,
    required BuildContext context,
  })  : _messageListStore =
            MessageListStore.create(conversationID: conversationID, messageListType: MessageListType.history),
        _conversationID = conversationID,
        _currentMessage = currentMessage;

  // Getters
  bool get isShowingImageViewer => _isShowingImageViewer;

  List<ImageElement> get initialImageElements => _initialImageElements;

  int get initialImageIndex => _initialImageIndex;

  bool get isLoadingImageData => _isLoadingImageData;

  Future<void> showImageViewerIfAvailable() async {
    if (_isLoadingImageData) return;

    _isLoadingImageData = true;
    _initialImageElements = [];
    _initialImageIndex = 0;

    final dataManager = ImageViewerDataManager(
      conversationID: _conversationID,
      currentMessage: _currentMessage,
      messageListStore: _messageListStore,
    );
    _imageViewerDataManager = dataManager;

    final result = await dataManager.loadInitialData();
    _initialImageElements = result.mediaElements;
    _initialImageIndex = result.currentIndex;
    _isLoadingImageData = false;
    _isShowingImageViewer = true;
  }

  void hideImageViewer() {
    _isShowingImageViewer = false;
  }

  void handleImageViewerEvent(Map<String, dynamic> eventData, Function(dynamic) callback) {
    final event = eventData['event'] as String;

    switch (event) {
      case 'onImageTap':
        hideImageViewer();
        callback(null);
        break;

      case 'onLoadMore':
        final param = eventData['param'] as Map<String, dynamic>;
        final isOlder = param['isOlder'] as bool;
        _handleLoadMore(isOlder, callback);
        break;

      case 'onDownloadVideo':
        final param = eventData['param'] as Map<String, dynamic>;
        final imagePath = param['path'] as String;
        _handleDownloadVideo(imagePath, callback);
        break;

      default:
        callback(null);
    }
  }

  Future<void> _handleLoadMore(bool isOlder, Function(dynamic) callback) async {
    try {
      final result = await _imageViewerDataManager?.loadMoreData(isOlder: isOlder) ??
          (elements: <ImageElement>[], hasMoreData: false);
      callback({
        'elements': result.elements,
        'hasMoreData': result.hasMoreData,
      });
    } catch (e) {
      callback({
        'elements': <ImageElement>[],
        'hasMoreData': false,
      });
    }
  }

  Future<void> _handleDownloadVideo(String imagePath, Function(dynamic) callback) async {
    final targetMessage = _imageViewerDataManager?.findMessage(byImagePath: imagePath);
    if (targetMessage == null) {
      callback([]);
      return;
    }

    final messageBody = targetMessage.messageBody;
    if (messageBody?.videoPath != null && messageBody!.videoPath!.isNotEmpty) {
      final file = File(messageBody.videoPath!);
      if (await file.exists()) {
        callback([messageBody.videoPath!]);
        return;
      }
    }

    await _messageListStore.downloadMessageResource(
      message: targetMessage,
      resourceType: MessageMediaFileType.video,
    );

    final updatedMessage = _messageListStore.messageListState.messageList.firstWhere(
      (message) => message.msgID == targetMessage.msgID,
      orElse: () => targetMessage,
    );

    final newVideoPath = updatedMessage.messageBody?.videoPath;
    if (newVideoPath != null && newVideoPath.isNotEmpty) {
      final newFile = File(newVideoPath);
      if (await newFile.exists()) {
        callback([newVideoPath]);
      } else {
        callback([]);
      }
    } else {
      callback([]);
    }
  }

  void dispose() {
    _imageViewerDataManager?.dispose();
    _messageListStore.dispose();
  }
}

class ImageViewerDataManager {
  final String conversationID;
  final MessageInfo currentMessage;
  final MessageListStore messageListStore;

  bool _isLoadingOlder = false;
  bool _isLoadingNewer = false;

  ImageViewerDataManager({
    required this.conversationID,
    required this.currentMessage,
    required this.messageListStore,
  });

  List<MessageInfo> get _mediaMessages {
    return messageListStore.messageListState.messageList
        .where((msg) => msg.messageType == MessageType.image || msg.messageType == MessageType.video)
        .toList();
  }

  Future<({List<ImageElement> mediaElements, int currentIndex})> loadInitialData() async {
    var option = MessageFetchOption();
    option.direction = MessageFetchDirection.both;
    option.pageCount = 5;
    option.message = currentMessage;
    option.filterType = MessageFilterType.image | MessageFilterType.video;

    final mediaElements = await _loadMediaMessages(option: option, isInitialLoad: true);
    final currentIndex = _findCurrentMessageIndex();
    return (mediaElements: mediaElements, currentIndex: currentIndex);
  }

  Future<({List<ImageElement> elements, bool hasMoreData})> loadMoreData({required bool isOlder}) async {
    bool hasMoreData = isOlder
        ? messageListStore.messageListState.hasMoreOlderMessage
        : messageListStore.messageListState.hasMoreNewerMessage;
    if (!hasMoreData) {
      return (elements: <ImageElement>[], hasMoreData: false);
    }

    final isCurrentlyLoading = isOlder ? _isLoadingOlder : _isLoadingNewer;
    if (isCurrentlyLoading) {
      return (elements: <ImageElement>[], hasMoreData: hasMoreData);
    }

    if (_mediaMessages.isEmpty) {
      return (elements: <ImageElement>[], hasMoreData: hasMoreData);
    }

    if (isOlder) {
      _isLoadingOlder = true;
    } else {
      _isLoadingNewer = true;
    }

    try {
      final anchorMessage = isOlder ? _mediaMessages.first : _mediaMessages.last;

      var option = MessageFetchOption();
      option.direction = isOlder ? MessageFetchDirection.older : MessageFetchDirection.newer;
      option.pageCount = 5;
      option.message = anchorMessage;
      option.filterType = MessageFilterType.image | MessageFilterType.video;

      final allElements = await _loadMediaMessages(option: option, isInitialLoad: false);
      hasMoreData = isOlder
          ? messageListStore.messageListState.hasMoreOlderMessage
          : messageListStore.messageListState.hasMoreNewerMessage;

      return (elements: allElements, hasMoreData: hasMoreData);
    } catch (e) {
      return (elements: <ImageElement>[], hasMoreData: hasMoreData);
    } finally {
      if (isOlder) {
        _isLoadingOlder = false;
      } else {
        _isLoadingNewer = false;
      }
    }
  }

  int _findCurrentMessageIndex() {
    int index = _mediaMessages.indexWhere((msg) => msg.msgID == currentMessage.msgID);
    if (index >= 0) {
      return index;
    }

    if (currentMessage.rawMessage?.msgID != null) {
      index = _mediaMessages.indexWhere((msg) => msg.rawMessage?.msgID == currentMessage.rawMessage?.msgID);
      if (index >= 0) {
        return index;
      }
    }

    return 0;
  }

  MessageInfo? findMessage({required String byImagePath}) {
    return _mediaMessages.firstWhere((message) {
      if (message.messageType == MessageType.image) {
        final originalImagePath = message.messageBody?.originalImagePath;
        final largeImagePath = message.messageBody?.largeImagePath;
        return originalImagePath == byImagePath || largeImagePath == byImagePath;
      } else if (message.messageType == MessageType.video) {
        final videoSnapshotPath = message.messageBody?.videoSnapshotPath;
        final thumbImagePath = message.messageBody?.thumbImagePath;
        return videoSnapshotPath == byImagePath || thumbImagePath == byImagePath;
      }
      return false;
    });
  }

  Future<List<ImageElement>> _loadMediaMessages({
    required MessageFetchOption option,
    required bool isInitialLoad,
  }) async {
    final result = await messageListStore.fetchMessageList(option: option);
    if (!result.isSuccess) {
      throw Exception('fetchMessages failed');
    }

    final fetchedMediaMessages = _mediaMessages;

    final List<ImageElement> resultElements = [];

    for (int i = 0; i < fetchedMediaMessages.length; i++) {
      final msg = fetchedMediaMessages[i];

      try {
        final element = await _processMediaMessage(msg);
        resultElements.add(element);
      } catch (e) {
        final isVideo = msg.messageType == MessageType.video;
        resultElements.add(ImageElement(
          type: isVideo ? 1 : 0,
          imagePath: '',
          videoPath: '',
        ));
      }
    }

    return resultElements;
  }

  Future<ImageElement> _processMediaMessage(MessageInfo msg) async {
    if (msg.messageType == MessageType.image) {
      return await _processImageMessage(msg);
    } else if (msg.messageType == MessageType.video) {
      return await _processVideoMessage(msg);
    } else {
      throw Exception('not support message type');
    }
  }

  Future<ImageElement> _processImageMessage(MessageInfo msg) async {
    final messageBody = msg.messageBody;
    String imagePath = '';

    if (messageBody?.largeImagePath != null && messageBody!.largeImagePath!.isNotEmpty) {
      final file = File(messageBody.largeImagePath!);
      if (await file.exists()) {
        imagePath = messageBody.largeImagePath!;
      }
    }

    if (imagePath.isEmpty && messageBody?.originalImagePath != null && messageBody!.originalImagePath!.isNotEmpty) {
      final file = File(messageBody.originalImagePath!);
      if (await file.exists()) {
        imagePath = messageBody.originalImagePath!;
      }
    }

    if (imagePath.isEmpty) {
      await messageListStore.downloadMessageResource(message: msg, resourceType: MessageMediaFileType.largeImage);

      final updatedMessage = messageListStore.messageListState.messageList.firstWhere(
        (message) => message.msgID == msg.msgID,
        orElse: () => msg,
      );

      imagePath = updatedMessage.messageBody?.largeImagePath ?? updatedMessage.messageBody?.originalImagePath ?? '';
    }

    return ImageElement(
      type: 0,
      imagePath: imagePath,
    );
  }

  Future<ImageElement> _processVideoMessage(MessageInfo msg) async {
    final messageBody = msg.messageBody;
    String imagePath = '';

    if (messageBody?.videoSnapshotPath != null && messageBody!.videoSnapshotPath!.isNotEmpty) {
      final file = File(messageBody.videoSnapshotPath!);
      if (await file.exists()) {
        imagePath = messageBody.videoSnapshotPath!;
      }
    }

    if (imagePath.isEmpty && messageBody?.thumbImagePath != null && messageBody!.thumbImagePath!.isNotEmpty) {
      final file = File(messageBody.thumbImagePath!);
      if (await file.exists()) {
        imagePath = messageBody.thumbImagePath!;
      }
    }

    if (imagePath.isEmpty) {
      await messageListStore.downloadMessageResource(message: msg, resourceType: MessageMediaFileType.videoSnapshot);

      final updatedMessage = messageListStore.messageListState.messageList.firstWhere(
        (message) => message.msgID == msg.msgID,
        orElse: () => msg,
      );

      imagePath = updatedMessage.messageBody?.videoSnapshotPath ?? updatedMessage.messageBody?.thumbImagePath ?? '';
    }

    return ImageElement(
      type: 1,
      imagePath: imagePath,
      videoPath: messageBody?.videoPath,
    );
  }

  void dispose() {}
}
