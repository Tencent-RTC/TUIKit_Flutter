import 'package:atomic_x_core/impl/view/call/call_participant_view.dart';
import 'package:flutter/material.dart';

import '../../../../api/call/call_store.dart';
import '../../../../api/device/device_store.dart';
import '../../../../api/view/call/call_core_view.dart';

class CallGridCellView extends StatelessWidget {
  static const double _loadingAnimationSize = 100.0;
  static const double _userInfoLeftPadding = 5.0;
  static const double _userInfoBottomPadding = 5.0;
  static const double _userInfoHeight = 24.0;
  static const double _spacingBetweenElements = 10.0;
  static const double _userNameFontSize = 16.0;
  static const double _muteIconBorderRadius = 12.0;

  final String userId;
  final bool isLarge;
  final Widget? loadingAnimation;
  final Widget? defaultAvatar;
  final Map<VolumeLevel, Widget> volumeIcons;
  final Map<NetworkQuality, Widget> networkQualityIcons;
  final bool enableZoom;

  const CallGridCellView({
    super.key,
    required this.userId,
    required this.isLarge,
    this.loadingAnimation,
    this.defaultAvatar,
    this.volumeIcons = const {},
    this.networkQualityIcons = const {},
    this.enableZoom = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLocalUser = userId == CallStore.shared.state.selfInfo.value.id;
    
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.allParticipants,
      builder: (context, allParticipants, child) {
        CallParticipantInfo? info;
        for (var participant in allParticipants) {
          if (participant.id == userId) {
            info = participant;
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            CallParticipantView(
              participantId: userId,
              enableZoom: isLocalUser && isLarge && enableZoom,
            ),
            _buildBackgroundView(info),
            _buildForegroundView(info, context),
          ],
        );
      },
    );
  }

  _buildBackgroundView(CallParticipantInfo? info) {
    return Visibility(
      visible: _isShowBackgroundImage(info),
      child: Positioned.fill(
        child: Container(
          child: _getUserAvatar(info),
        ),
      ),
    );
  }

  Widget _buildForegroundView(CallParticipantInfo? info, BuildContext context) {
    final selfInfo = CallStore.shared.state.selfInfo.value;
    final bool isRemoteUserWaiting = info?.status == CallParticipantStatus.waiting
        && info?.id != selfInfo.id;
    final bool isShowLoadingAnimation = info == null || isRemoteUserWaiting;
    
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        if (isShowLoadingAnimation && loadingAnimation != null)
          Positioned(
            width: _loadingAnimationSize,
            height: _loadingAnimationSize,
            child: loadingAnimation!,
          ),
        _getUserInfoDisplay(info, selfInfo),
      ],
    );
  }

  Widget _getUserInfoDisplay(CallParticipantInfo? info, CallParticipantInfo selfInfo) {
    return Positioned(
      left: _userInfoLeftPadding,
      bottom: _userInfoBottomPadding,
      height: _userInfoHeight,
      child: Row(
        children: [
          if (isLarge) ...[
            Text(
              _getUserDisplayName(info),
              style: const TextStyle(
                color: Colors.white,
                fontSize: _userNameFontSize,
              ),
            ),
            const SizedBox(width: _spacingBetweenElements),
          ],
          _buildVolumeIndicator(info, selfInfo),
          const SizedBox(width: _spacingBetweenElements),
          _buildNetworkQualityIndicator(info),
        ],
      ),
    );
  }

  Widget _buildVolumeIndicator(CallParticipantInfo? info, CallParticipantInfo selfInfo) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ValueListenableBuilder(
          valueListenable: CallStore.shared.state.speakerVolumes,
          builder: (context, speakerVolumes, child) {
            if (info == null) {
              return const SizedBox.shrink();
            }

            final int volume = speakerVolumes[info.id] ?? 0;
            final Widget? volumeIcon = _getVolumeIcon(volume);
            return volumeIcon ?? const SizedBox.shrink();
          },
        ),
        if (selfInfo.id == userId && !selfInfo.isMicrophoneOpened)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(_muteIconBorderRadius),
            ),
            child: volumeIcons[VolumeLevel.mute] ?? const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildNetworkQualityIndicator(CallParticipantInfo? info) {
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.networkQualities,
      builder: (context, networkQualities, child) {
        if (info == null) {
          return networkQualityIcons[NetworkQuality.unknown] ?? const SizedBox.shrink();
        }

        final NetworkQuality? quality = networkQualities[info.id];
        return networkQualityIcons[quality] ?? const SizedBox.shrink();
      },
    );
  }

  Widget? _getVolumeIcon(int volume) {
    if (volume < 25) return volumeIcons[VolumeLevel.low];
    if (volume < 50) return volumeIcons[VolumeLevel.medium];
    if (volume < 75) return volumeIcons[VolumeLevel.high];
    return volumeIcons[VolumeLevel.peak];
  }

  Widget _getUserAvatar(CallParticipantInfo? info) {
    if (info != null && info.avatarURL.isNotEmpty) {
      return Image.network(
        info.avatarURL,
        fit: BoxFit.cover,
        errorBuilder:(context, error, stackTrace) {
          return defaultAvatar ?? Container();
        },
      );
    }

    return defaultAvatar ?? Container();
  }

  bool _isShowBackgroundImage(CallParticipantInfo? info) {
    if (info == null) {
      return false;
    }

    return info.id == CallStore.shared.state.selfInfo.value.id
        ? DeviceStore.shared.state.cameraStatus.value == DeviceStatus.off
        : !info.isCameraOpened;
  }

  String _getUserDisplayName(CallParticipantInfo? info) {
    if (info == null) {
      return userId;
    }

    if (info.remark.isNotEmpty) {
      return info.remark;
    } else if (info.name.isNotEmpty) {
      return info.name;
    } else {
      return info.id;
    }
  }
}
