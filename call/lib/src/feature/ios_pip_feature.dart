import 'dart:io';
import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:atomic_x_core/impl/common/log.dart';

class IosPipRegion {
  final String userId;
  final String userName;
  final double width;
  final double height;
  final double x;
  final double y;
  final int fillMode;
  final String streamType;
  final String backgroundColor;
  final String? backgroundImage;

  const IosPipRegion({
    required this.userId,
    required this.userName,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.fillMode,
    required this.streamType,
    required this.backgroundColor,
    this.backgroundImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'width': width,
      'height': height,
      'x': x,
      'y': y,
      'fillMode': fillMode,
      'streamType': streamType,
      'backgroundColor': backgroundColor,
      'backgroundImage': backgroundImage,
    };
  }

  IosPipRegion copyWith({
    String? userId,
    String? userName,
    double? width,
    double? height,
    double? x,
    double? y,
    int? fillMode,
    String? streamType,
    String? backgroundColor,
    String? backgroundImage,
  }) {
    return IosPipRegion(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      width: width ?? this.width,
      height: height ?? this.height,
      x: x ?? this.x,
      y: y ?? this.y,
      fillMode: fillMode ?? this.fillMode,
      streamType: streamType ?? this.streamType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImage: backgroundImage ?? this.backgroundImage,
    );
  }
}

class IosPipCanvas {
  final int width;
  final int height;
  final String backgroundColor;

  const IosPipCanvas({
    required this.width,
    required this.height,
    required this.backgroundColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'backgroundColor': backgroundColor,
    };
  }
}

class IosPipParams {
  final bool enable;
  final bool? cameraBackgroundCapture;
  final IosPipCanvas? canvas;
  final List<IosPipRegion>? regions;

  const IosPipParams({
    required this.enable,
    this.cameraBackgroundCapture,
    this.canvas,
    this.regions,
  });

  IosPipParams copyWith({
    bool? enable,
    bool? cameraBackgroundCapture,
    IosPipCanvas? canvas,
    List<IosPipRegion>? regions,
  }) {
    return IosPipParams(
      enable: enable ?? this.enable,
      cameraBackgroundCapture:
          cameraBackgroundCapture ?? this.cameraBackgroundCapture,
      canvas: canvas ?? this.canvas,
      regions: regions ?? this.regions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable': enable,
      'cameraBackgroundCapture': cameraBackgroundCapture,
      'canvas': canvas?.toJson(),
      'regions': regions?.map((region) => region.toJson()).toList(),
    };
  }
}

class IosPipRequest {
  final String api;
  IosPipParams params;

  IosPipRequest({
    required this.api,
    required this.params,
  });

  Map<String, dynamic> toJson() {
    return {
      'api': api,
      'params': params.toJson(),
    };
  }
}

class _IosPipConfiguration {
  static const String backgroundColor = "#111111";
  static const int canvasWidth = 720;
  static const int canvasHeight = 1280;
  static const String apiName = "configPictureInPicture";
  static const int maxGridUsers = 9;
  static const String streamType = "high";
  static const int fillMode = 0;
  static const double gridSize = 1.0 / 3.0;
  static const double halfSize = 0.5;
  static const double fullSize = 1.0;
  static const double smallWindowSize = 1.0 / 3.0;
  static const double smallWindowX = 0.65;
  static const double smallWindowY = 0.05;
  static const double threeParticipantsBottomX = 0.25;

  static const IosPipCanvas defaultCanvas = IosPipCanvas(
    width: canvasWidth,
    height: canvasHeight,
    backgroundColor: backgroundColor,
  );
}

class IosPipFeature {
  IosPipRequest? _currentRequest;
  late final VoidCallback _allParticipantsListener;
  late final VoidCallback _selfInfoListener;
  late final Log _log;

  final Set<String> _downloadedAvatars = <String>{};
  final Map<String, String> _avatarPaths = <String, String>{};
  String? _defaultAvatarPath;

  IosPipFeature() {
    _log = Log.getCallLog("PictureInPictureFeature");
    IosPipParams params = const IosPipParams(enable: true, cameraBackgroundCapture: true);
    _sendPictureInPictureRequest(params);
    _registerObservers();
    _getDefaultAvatarFilePath();
  }

  void dispose() {
    _unregisterObservers();
  }

  Future<void> _getDefaultAvatarFilePath() async {
    try {
      final byteData = await rootBundle.load('packages/tencent_calls_uikit/assets/images/user_icon.png');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/default_avatar.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      _defaultAvatarPath = "file://${file.path}";
      _log.info("Default avatar file path: $_defaultAvatarPath");
    } catch (e) {
      _log.error("Failed to get default avatar file path: $e");
    }
  }

  void _registerObservers() {
    _allParticipantsListener = () => _handleParticipantsChange();
    _selfInfoListener = () => _handleParticipantsChange();

    CallParticipantStore.shared.state.allParticipants
        .addListener(_allParticipantsListener);
    CallParticipantStore.shared.state.selfInfo.addListener(_selfInfoListener);
  }

  void _handleParticipantsChange() {
    final participants =
        CallParticipantStore.shared.state.allParticipants.value;

    if (participants.isEmpty) {
      if (_currentRequest?.params.enable == true) {
        closePictureInPicture();
      }
      return;
    }

    final activeCall = CallStore.shared.state.activeCall.value;

    if (activeCall.mediaType == CallMediaType.video ||
        participants.length > 2 ||
        activeCall.chatGroupId.isNotEmpty) {
      updatePictureInPicture(participants);
    }
  }

  void _unregisterObservers() {
    CallParticipantStore.shared.state.allParticipants
        .removeListener(_allParticipantsListener);
    CallParticipantStore.shared.state.selfInfo
        .removeListener(_selfInfoListener);
  }

  Future<void> updatePictureInPicture(
      List<CallParticipantInfo> participants) async {
    final userList = List<CallParticipantInfo>.from(participants);
    final selfInfo = CallParticipantStore.shared.state.selfInfo.value;

    if (!userList.any((p) => p.id == selfInfo.id)) {
      userList.add(selfInfo);
    }

    if (userList.isEmpty) return;

    final regions = _calculateLayout(userList);
    if (regions.isEmpty) return;

    const params = IosPipParams(
      enable: true,
      cameraBackgroundCapture: true,
      canvas: _IosPipConfiguration.defaultCanvas,
    );

    _sendPictureInPictureRequest(params.copyWith(regions: regions));
    _downloadAvatars(userList);
  }

  Future<void> closePictureInPicture() async {
    const params = IosPipParams(enable: false);
    await _sendPictureInPictureRequest(params);
  }

  void _downloadAvatars(List<CallParticipantInfo> participants) {
    final contactListStore = ContactListStore.create();

    for (final participant in participants) {
      contactListStore.fetchUserInfo(userID: participant.id);

      final avatarUrl = participant.avatarURL;
      if (avatarUrl.isEmpty) continue;

      if (_downloadedAvatars.contains(participant.id)) {
        final cachedPath = _avatarPaths[participant.id];
        if (cachedPath != null) {
          final filePath = cachedPath.replaceFirst('file://', '');
          File(filePath).exists().then((exists) {
            if (!exists) {
              _downloadedAvatars.remove(participant.id);
              _avatarPaths.remove(participant.id);
              _downloadParticipantAvatar(participant);
            }
          });
        } else {
          _downloadParticipantAvatar(participant);
        }
      } else {
        _downloadParticipantAvatar(participant);
      }
    }
  }

  Future<void> _downloadParticipantAvatar(
      CallParticipantInfo participant) async {
    try {
      final avatarUrl = participant.avatarURL;
      if (avatarUrl.isEmpty) return;

      final uri = Uri.tryParse(avatarUrl);
      if (uri == null) {
        _log.error("Invalid avatar URL for ${participant.id}: $avatarUrl");
        return;
      }

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        _log.error("HTTP ${response.statusCode} for ${participant.id}");
        return;
      }
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/avatar_${participant.id}.jpg');
      await file.writeAsBytes(response.bodyBytes);

      final fileUrl = "file://${file.path}";
      _avatarPaths[participant.id] = fileUrl;
      _downloadedAvatars.add(participant.id);

      await _setBackgroundImage(participant.id, fileUrl);
    } catch (e) {
      _log.error("Avatar download failed for ${participant.id}: $e");
    }
  }

  Future<void> _setBackgroundImage(
      String userId, String backgroundImage) async {
    final currentRequest = _currentRequest;
    final regions = currentRequest?.params.regions;

    if (regions == null || !currentRequest!.params.enable) {
      return;
    }

    final updatedRegions = regions.map((region) {
      if (region.userId == userId) {
        return region.copyWith(backgroundImage: backgroundImage);
      }
      return region;
    }).toList();

    final updatedParams =
        currentRequest.params.copyWith(regions: updatedRegions);
    await _sendPictureInPictureRequest(updatedParams);
  }

  List<IosPipRegion> _calculateLayout(List<CallParticipantInfo> participants) {
    if (participants.isEmpty) return [];

    return switch (participants.length) {
      2 => _createTwoParticipantsLayout(participants),
      3 => _createThreeParticipantsLayout(participants),
      4 => _createFourParticipantsLayout(participants),
      _ => _createGridLayout(participants),
    };
  }

  IosPipRegion _createFullScreenRegion(CallParticipantInfo participant) {
    return _createRegion(
      participant,
      _IosPipConfiguration.fullSize,
      _IosPipConfiguration.fullSize,
      0.0,
      0.0,
    );
  }

  List<IosPipRegion> _createTwoParticipantsLayout(
      List<CallParticipantInfo> participants) {
    final selfUserId = CallParticipantStore.shared.state.selfInfo.value.id;
    final regions = <IosPipRegion>[];

    for (final participant in participants) {
      if (participant.id == selfUserId) {
        continue;
      } else {
        regions.add(_createFullScreenRegion(participant));
      }
    }

    regions.add(_createRegion(
      CallParticipantStore.shared.state.selfInfo.value,
      _IosPipConfiguration.smallWindowSize,
      _IosPipConfiguration.smallWindowSize,
      _IosPipConfiguration.smallWindowX,
      _IosPipConfiguration.smallWindowY,
    ));

    return regions;
  }

  List<IosPipRegion> _createThreeParticipantsLayout(
      List<CallParticipantInfo> participants) {
    final regions = <IosPipRegion>[];

    for (int i = 0; i < participants.length; i++) {
      final participant = participants[i];
      double x, y;

      if (i < 2) {
        x = i == 0 ? 0.0 : _IosPipConfiguration.halfSize;
        y = 0.0;
      } else {
        x = _IosPipConfiguration.threeParticipantsBottomX;
        y = _IosPipConfiguration.halfSize;
      }

      regions.add(_createRegion(
        participant,
        _IosPipConfiguration.halfSize,
        _IosPipConfiguration.halfSize,
        x,
        y,
      ));
    }

    return regions;
  }

  List<IosPipRegion> _createFourParticipantsLayout(
      List<CallParticipantInfo> participants) {
    final regions = <IosPipRegion>[];

    for (int i = 0; i < participants.length; i++) {
      final participant = participants[i];
      final row = i ~/ 2;
      final col = i % 2;

      regions.add(_createRegion(
        participant,
        _IosPipConfiguration.halfSize,
        _IosPipConfiguration.halfSize,
        col * _IosPipConfiguration.halfSize,
        row * _IosPipConfiguration.halfSize,
      ));
    }

    return regions;
  }

  List<IosPipRegion> _createGridLayout(List<CallParticipantInfo> participants) {
    const maxUsers = _IosPipConfiguration.maxGridUsers;
    final usersToLayout = participants.take(maxUsers).toList();
    final regions = <IosPipRegion>[];

    for (int i = 0; i < usersToLayout.length; i++) {
      final participant = usersToLayout[i];
      final row = i ~/ 3;
      final col = i % 3;

      regions.add(_createRegion(
        participant,
        _IosPipConfiguration.gridSize,
        _IosPipConfiguration.gridSize,
        col * _IosPipConfiguration.gridSize,
        row * _IosPipConfiguration.gridSize,
      ));
    }

    return regions;
  }

  IosPipRegion _createRegion(
    CallParticipantInfo participant,
    double width,
    double height,
    double x,
    double y,
  ) {
    final backgroundImage = _avatarPaths[participant.id] ?? _defaultAvatarPath;

    return IosPipRegion(
      userId: participant.id,
      userName: "",
      width: width,
      height: height,
      x: x,
      y: y,
      fillMode: _IosPipConfiguration.fillMode,
      streamType: _IosPipConfiguration.streamType,
      backgroundColor: _IosPipConfiguration.backgroundColor,
      backgroundImage: backgroundImage,
    );
  }

  Future<void> _sendPictureInPictureRequest(IosPipParams params) async {
    final request = IosPipRequest(
      api: _IosPipConfiguration.apiName,
      params: params,
    );
    _currentRequest = request;

    final requestJson = request.toJson();

    try {
      await CallStore.shared.callExperimentalAPI(requestJson);
    } catch (e) {
      _log.error("Send PIP request fail. Error message: $e");
    }
  }
}
