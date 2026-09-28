import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/message/message_list_store.dart';
import 'package:atomic_x_core/impl/message/message_input_store_impl.dart';
import 'package:flutter/foundation.dart';

sealed class SendMessagePayload {
  const SendMessagePayload();
}

class TextSendMessagePayload extends SendMessagePayload {
  final String text;

  const TextSendMessagePayload({required this.text});
}

class CustomSendMessagePayload extends SendMessagePayload {
  final String customData;
  final String? description;
  final String? extensionInfo;

  const CustomSendMessagePayload({required this.customData, this.description, this.extensionInfo});
}

class ImageSendMessagePayload extends SendMessagePayload {
  final String imagePath;
  final int imageWidth;
  final int imageHeight;

  const ImageSendMessagePayload({required this.imagePath, this.imageWidth = 0, this.imageHeight = 0});
}

class AudioSendMessagePayload extends SendMessagePayload {
  final String audioFilePath;
  final int duration;

  const AudioSendMessagePayload({required this.audioFilePath, required this.duration});
}

class VideoSendMessagePayload extends SendMessagePayload {
  final String videoFilePath;
  final String videoType;
  final int duration;
  final String snapshotPath;
  final int snapshotWidth;
  final int snapshotHeight;

  const VideoSendMessagePayload({
    required this.videoFilePath,
    required this.videoType,
    required this.duration,
    required this.snapshotPath,
    this.snapshotWidth = 0,
    this.snapshotHeight = 0,
  });
}

class FileSendMessagePayload extends SendMessagePayload {
  final String filePath;
  final String fileName;
  final int fileSize;

  const FileSendMessagePayload({required this.filePath, required this.fileName, this.fileSize = 0});
}

class FaceSendMessagePayload extends SendMessagePayload {
  final int index;
  final String data;

  const FaceSendMessagePayload({required this.index, required this.data});
}

class SendMessageOption {
  List<String>? atUserList;
  MessageInfo? quotedMessage;

  bool needReadReceipt;
  bool isExtensionEnabled;
  bool onlineUserOnly;

  OfflinePushInfo? offlinePushInfo;

  SendMessageOption({
    this.atUserList,
    this.quotedMessage,
    this.needReadReceipt = false,
    this.isExtensionEnabled = false,
    this.onlineUserOnly = false,
    this.offlinePushInfo,
  });
}

abstract class MessageInputStore extends ChangeNotifier {
  static MessageInputStore create({required String conversationID}) {
    return MessageInputStoreImpl(conversationID);
  }

  Future<CompletionHandler> sendMessage({
    required SendMessagePayload payload,
    SendMessageOption? option,
  });

  Future<CompletionHandler> insertLocalMessage({
    required SendMessagePayload payload,
    String? sender,
  });
}
