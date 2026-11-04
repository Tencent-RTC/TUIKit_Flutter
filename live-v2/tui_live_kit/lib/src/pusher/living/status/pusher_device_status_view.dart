part of 'pusher_live_status_view.dart';

enum MediaStatus { normal, off, deviceError, streamError }

class PusherDeviceStatusState {
  PusherDeviceStatusState({
    this.cameraStatus = DeviceStatus.off,
    this.microphoneStatus = DeviceStatus.off,
    this.cameraError = DeviceError.noError,
    this.microphoneError = DeviceError.noError,
    this.temperatureStatus = LiveThermalState.normal,
    this.networkKind = LiveNetworkType.unknown,
    this.networkQuality = 0,
    this.delay = 0,
    this.downLoss = 0,
    this.upLoss = 0,
    this.videoBitrate = 0,
    this.videoWidth = 0,
    this.videoHeight = 0,
    this.frameRate = 0,
    this.audioSampleRate = 0,
    this.audioBitrate = 0,
    this.hasAVStatistics = false,
  });

  DeviceStatus cameraStatus;
  DeviceStatus microphoneStatus;
  DeviceError cameraError;
  DeviceError microphoneError;

  MediaStatus get videoStatus => _mediaStatus(
      cameraStatus, cameraError, networkQuality == NetworkQuality.down.value || (hasAVStatistics && frameRate < 15));
  MediaStatus get audioStatus =>
      _mediaStatus(microphoneStatus, microphoneError, hasAVStatistics && (audioSampleRate == 0 || audioBitrate == 0));
  static MediaStatus _mediaStatus(DeviceStatus status, DeviceError error, bool abnormal) {
    if (error != DeviceError.noError) return MediaStatus.deviceError;
    if (status != DeviceStatus.on) return MediaStatus.off;
    return abnormal ? MediaStatus.streamError : MediaStatus.normal;
  }

  LiveThermalState temperatureStatus;
  LiveNetworkType networkKind;
  int networkQuality;
  int delay;
  int downLoss;
  int upLoss;
  int videoBitrate;
  int videoWidth;
  int videoHeight;
  int frameRate;
  int audioSampleRate;
  int audioBitrate;
  bool hasAVStatistics;

  PusherDeviceStatusState copy() {
    return PusherDeviceStatusState(
      cameraStatus: cameraStatus,
      microphoneStatus: microphoneStatus,
      cameraError: cameraError,
      microphoneError: microphoneError,
      temperatureStatus: temperatureStatus,
      networkKind: networkKind,
      networkQuality: networkQuality,
      delay: delay,
      downLoss: downLoss,
      upLoss: upLoss,
      videoBitrate: videoBitrate,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
      frameRate: frameRate,
      audioSampleRate: audioSampleRate,
      audioBitrate: audioBitrate,
      hasAVStatistics: hasAVStatistics,
    );
  }

  bool isSameAs(PusherDeviceStatusState other) {
    return cameraStatus == other.cameraStatus &&
        microphoneStatus == other.microphoneStatus &&
        cameraError == other.cameraError &&
        microphoneError == other.microphoneError &&
        temperatureStatus == other.temperatureStatus &&
        networkKind == other.networkKind &&
        networkQuality == other.networkQuality &&
        delay == other.delay &&
        downLoss == other.downLoss &&
        upLoss == other.upLoss &&
        videoBitrate == other.videoBitrate &&
        videoWidth == other.videoWidth &&
        videoHeight == other.videoHeight &&
        frameRate == other.frameRate &&
        audioSampleRate == other.audioSampleRate &&
        audioBitrate == other.audioBitrate &&
        hasAVStatistics == other.hasAVStatistics;
  }
}

class PusherDeviceStatusView extends StatelessWidget {
  const PusherDeviceStatusView({
    super.key,
    required this.isMuted,
    required this.captureVolume,
    required this.status,
    this.onSetCaptureVolume,
  });

  final bool isMuted;
  final int captureVolume;
  final PusherDeviceStatusState status;
  final void Function(int volume)? onSetCaptureVolume;

  @override
  Widget build(BuildContext context) {
    final volume = captureVolume.clamp(0, 100);
    final video = _DeviceStatusDescription.media(status.videoStatus, isVideo: true);
    final audio =
        _DeviceStatusDescription.media(isMuted || volume == 0 ? MediaStatus.off : status.audioStatus, isVideo: false);
    final temperature = _DeviceStatusDescription.temperature(status.temperatureStatus);
    final network = _DeviceStatusDescription.network(status);
    final separator = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 21),
        child: SizedBox(
            height: 1 / MediaQuery.devicePixelRatioOf(context),
            child: const ColoredBox(color: _LiveStatusStyle.separator)));
    Widget row(_LiveStatusDeviceRow child) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: 21), child: child);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 14),
      row(_LiveStatusDeviceRow(
          assetName: 'livekit_status_video',
          description: video,
          trailing: status.hasAVStatistics && status.videoWidth > 0 ? '${status.videoWidth}P' : '--')),
      const SizedBox(height: 12), separator, const SizedBox(height: 12),
      row(_LiveStatusDeviceRow(assetName: 'livekit_status_audio', description: audio)),
      // The visual track remains 23 high; its 44 high hit target overlaps only
      // the row's trailing padding, matching UIKit's expanded slider hit area.
      SizedBox(
          height: 35,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
                left: 64,
                right: 64,
                top: -(44 - 23) / 2,
                height: 44,
                child: LiveSlider(
                    value: volume.toDouble(),
                    min: 0,
                    max: 100,
                    semanticLabel: LiveKitResources.localizedString('tuilivekit.pusher.status.voice_volume'),
                    onChanged: onSetCaptureVolume == null ? null : (value) => onSetCaptureVolume!(value.round()))),
            Positioned(
                right: 23,
                top: 3,
                width: 28,
                height: 15,
                child: Text('$volume',
                    textAlign: TextAlign.right, style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11))),
          ])),
      separator, const SizedBox(height: 12),
      row(_LiveStatusDeviceRow(assetName: 'livekit_status_temperature', description: temperature)),
      const SizedBox(height: 12), separator, const SizedBox(height: 12),
      row(_LiveStatusDeviceRow(assetName: 'livekit_status_network', description: network)),
      const SizedBox(height: 12),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _LiveStatusThreeColumnCard(
              values: ['${status.delay}ms', '${status.downLoss}%', '${status.upLoss}%'],
              titles: ['rtt', 'down_loss', 'up_loss']
                  .map((key) => LiveKitResources.localizedString('tuilivekit.pusher.status.$key'))
                  .toList())),
      const SizedBox(height: 9),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SizedBox(
              height: 112,
              child: _StatusCard(
                  radius: 15,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(children: [
                        Expanded(
                            child: _CodingCardColumn(
                                title: LiveKitResources.localizedString('tuilivekit.pusher.status.video_info'),
                                fields: LiveKitResources.localizedString('tuilivekit.pusher.status.video_fields'),
                                fieldsWidth: 55,
                                contentHeight: 57,
                                values: status.videoInformation)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _CodingCardColumn(
                                title: LiveKitResources.localizedString('tuilivekit.pusher.status.audio_info'),
                                fields: LiveKitResources.localizedString('tuilivekit.pusher.status.audio_fields'),
                                fieldsWidth: 52,
                                valueSpacing: 7,
                                contentHeight: 38,
                                values: status.audioInformation)),
                      ]))))),
      SizedBox(height: math.max(26, MediaQuery.viewPaddingOf(context).bottom)),
    ]);
  }
}

class _LiveStatusDeviceRow extends StatelessWidget {
  const _LiveStatusDeviceRow({required this.assetName, required this.description, this.trailing});
  final String assetName;
  final _DeviceStatusDescription description;
  final String? trailing;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: Stack(children: [
        Positioned(
            left: 0,
            top: 4,
            width: 30,
            height: 30,
            child: Image(
                image: LiveKitResources.image(description.iconName ?? assetName),
                fit: BoxFit.contain,
                color: description.usesOriginalColors ? null : description.tintColor)),
        Padding(
            padding: const EdgeInsets.only(left: 43),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                  padding: EdgeInsets.only(right: trailing == null ? 0 : 57),
                  child: Text(description.title,
                      style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 14, fontWeight: FontWeight.w600))),
              const SizedBox(height: 4),
              Text(description.detail, style: const TextStyle(color: Color(0x61FFFFFF), fontSize: 11)),
            ])),
        if (trailing != null)
          Positioned(
              right: 2,
              top: 2,
              width: 49,
              child: Text(trailing!,
                  textAlign: TextAlign.right, style: const TextStyle(color: Color(0x7AFFFFFF), fontSize: 12))),
      ]));
}

class _LiveStatusThreeColumnCard extends StatelessWidget {
  const _LiveStatusThreeColumnCard({required this.values, required this.titles});

  final List<String> values;
  final List<String> titles;

  @override
  Widget build(BuildContext context) => _StatusCard(
      radius: 15,
      child: Padding(
          padding: const EdgeInsets.only(top: 11, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
                values.length,
                (index) => Expanded(
                        child: Column(children: [
                      SizedBox(
                          height: 25,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(values[index],
                                  style: const TextStyle(
                                      color: LiveTheme.brandBlue, fontSize: 20, fontWeight: FontWeight.w600)))),
                      const SizedBox(height: 6),
                      Text(titles[index],
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _LiveStatusStyle.metricTitle, fontSize: 10)),
                    ]))),
          )));
}

/// 列内标题占满列宽；字段名固定 55pt（组件固有规格），取值区占据剩余宽度。
class _CodingCardColumn extends StatelessWidget {
  const _CodingCardColumn({
    required this.title,
    required this.fields,
    required this.fieldsWidth,
    this.valueSpacing = 8,
    required this.contentHeight,
    required this.values,
  });

  final String title;
  final String fields;
  final double fieldsWidth;
  final double valueSpacing;
  final double contentHeight;
  final String values;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final painter = TextPainter(
            text: TextSpan(text: fields, style: const TextStyle(fontSize: 10)),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context))
          ..layout();
        final width = math.min(math.max(fieldsWidth, painter.width.ceilToDouble()),
            math.max(0.0, constraints.maxWidth - valueSpacing - 24));
        painter.dispose();
        return Stack(children: [
          Positioned(left: 0, right: 0, top: 14, height: 16, child: _CodingCardTitle(title)),
          Positioned(
              left: 0,
              top: 44,
              width: width,
              height: contentHeight,
              child: _CodingCardText(fields, color: _LiveStatusStyle.fieldDescription)),
          Positioned(
              left: width + valueSpacing,
              right: 0,
              top: 44,
              height: contentHeight,
              child: _CodingCardText(values, color: _LiveStatusStyle.fieldValue)),
        ]);
      });
}

class _CodingCardTitle extends StatelessWidget {
  const _CodingCardTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _LiveStatusStyle.fieldTitle,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// UIKit shrinks encoding labels down to 75%; keep each field on its own
/// 19-point line rather than letting Flutter wrap a value onto the next field.
class _CodingCardText extends StatelessWidget {
  const _CodingCardText(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final painter = TextPainter(
            text: TextSpan(text: text, style: const TextStyle(fontSize: 10)),
            textDirection: Directionality.of(context),
            textScaler: scaler)
          ..layout();
        final ratio = painter.width == 0 ? 1.0 : (constraints.maxWidth / painter.width).clamp(0.75, 1.0);
        painter.dispose();
        final fontSize = 10 * ratio;
        return Text(text,
            maxLines: text.split('\n').length,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: fontSize, height: 19 / scaler.scale(fontSize)));
      });
}

String _deviceStatusText(String key) => LiveKitResources.localizedString('tuilivekit.pusher.status.$key');

class _DeviceStatusDescription {
  const _DeviceStatusDescription({required this.title, required this.detail, required this.tintColor, this.iconName});

  final String title;
  final String detail;
  final Color tintColor;
  final String? iconName;
  bool get usesOriginalColors => iconName != null;

  factory _DeviceStatusDescription.media(MediaStatus status, {required bool isVideo}) {
    final kind = isVideo ? 'video' : 'audio';
    final (title, detail, color) = switch (status) {
      MediaStatus.normal => ('normal', 'normal', _liveStatusNormalColor),
      MediaStatus.off => ('off', 'off', _liveStatusWarningColor),
      MediaStatus.deviceError => ('error', 'device_error', _liveStatusWarningColor),
      MediaStatus.streamError => ('error', 'stream_error', _liveStatusCriticalColor),
    };
    return _DeviceStatusDescription(
        title: _deviceStatusText('$kind.$title.title'),
        detail: _deviceStatusText('$kind.$detail.detail'),
        tintColor: color);
  }

  factory _DeviceStatusDescription.temperature(LiveThermalState status) {
    final color = switch (status) {
      LiveThermalState.normal => _liveStatusNormalColor,
      LiveThermalState.fair => _liveStatusWarningColor,
      LiveThermalState.serious => _liveStatusCriticalColor,
    };
    return _DeviceStatusDescription(
        title: _deviceStatusText('temperature.${status.name}.title'),
        detail: _deviceStatusText('temperature.${status.name}.detail'),
        tintColor: color);
  }

  factory _DeviceStatusDescription.network(PusherDeviceStatusState status) {
    final (quality, detail, color, icon) = switch (status.networkQuality) {
      1 => ('excellent', 'keep', _liveStatusNormalColor, null),
      2 => ('good', 'keep', _liveStatusNormalColor, null),
      3 => ('poor', 'fluctuating', _liveStatusWarningColor, 'livekit_status_network_poor'),
      4 => ('bad', 'switch', _liveStatusCriticalColor, 'livekit_status_network_bad'),
      5 => ('very_bad', 'switch', _liveStatusCriticalColor, 'livekit_status_network_bad'),
      6 => ('disconnected', 'disconnected_detail', _liveStatusCriticalColor, 'livekit_status_network_down'),
      _ => ('checking', 'checking_detail', _liveStatusUnknownColor, null),
    };
    return _DeviceStatusDescription(
        title: _deviceStatusText('network.title')
            .replaceFirst('%@', _deviceStatusText('network.${status.networkKind.name}'))
            .replaceFirst('%@', _deviceStatusText('network.$quality')),
        detail: _deviceStatusText('network.$detail'),
        tintColor: color,
        iconName: icon);
  }
}

/// UIColor(red: 0.29, green: 0.62, blue: 1, alpha: 1)
const Color _liveStatusNormalColor = LiveTheme.brandBlue;

/// UIColor(red: 1, green: 0.54, blue: 0.24, alpha: 1)
const Color _liveStatusWarningColor = Color(0xFFFF8A3D);

/// UIColor(red: 1, green: 0.36, blue: 0.38, alpha: 1)
const Color _liveStatusCriticalColor = Color(0xFFFF5C61);

/// UIColor(red: 0.54, green: 0.58, blue: 0.66, alpha: 1)
const Color _liveStatusUnknownColor = Color(0xFF8A94A8);

extension _DeviceStatusText on PusherDeviceStatusState {
  String get videoInformation {
    if (!hasAVStatistics) {
      return '--\n--\n--';
    }
    final String resolution = videoWidth > 0 && videoHeight > 0 ? '$videoWidth×$videoHeight' : '--';
    final String bitrate = videoBitrate > 0 ? '$videoBitrate kbps' : '--';
    final String fps = frameRate > 0 ? '$frameRate FPS' : '--';
    return '$resolution\n$bitrate\n$fps';
  }

  String get audioInformation {
    if (!hasAVStatistics) {
      return '--\n--';
    }
    final String sampleRate = audioSampleRate > 0 ? '$audioSampleRate Hz' : '--';
    final String bitrate = audioBitrate > 0 ? '$audioBitrate kbps' : '--';
    return '$sampleRate\n$bitrate';
  }
}
