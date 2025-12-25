import 'package:atomic_x_core/atomicxcore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/seat_grid_widget/seat_grid_controller.dart';
import 'package:tencent_live_uikit/seat_grid_widget/widget/animated/sound_wave_animated_widget.dart';


class DefaultSeatWidget extends StatelessWidget {
  final SeatWidgetState seatWidgetState;

  const DefaultSeatWidget({super.key, required this.seatWidgetState});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
            top: -(11.width), left: -(11.width), child: _BackgroundAnimatedWidget(seatWidgetState: seatWidgetState)),
        Positioned(
          top: 0,
          left: 0,
          child: _MainWidget(seatWidgetState: seatWidgetState),
        ),
        Positioned(top: 34.width, left: 34.width, child: _MicrophoneMutedWidget(seatWidgetState: seatWidgetState)),
        Positioned(top: 58.height, left: 0, child: _InformationWidget(seatWidgetState: seatWidgetState))
      ],
    );
  }
}

class _BackgroundAnimatedWidget extends StatelessWidget {
  final SeatWidgetState seatWidgetState;

  const _BackgroundAnimatedWidget({
    required this.seatWidgetState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([seatWidgetState.volumeNotifier, seatWidgetState.seatInfoNotifier]),
      builder: (context, _) {
        final isEmptySeat = seatWidgetState.seatInfoNotifier.value.userInfo.userID.isEmpty;
        final volume = seatWidgetState.volumeNotifier.value;
        return SizedBox(
          height: 72.width,
          width: 72.width,
          child: Center(
            child: Visibility(
                visible: !isEmptySeat && volume != 0,
                child: SoundWaveAnimatedWidget(
                  waveRadiusTween: Tween(begin: 25.width, end: 32.width),
                  waveColor: LiveColors.designStandardWhite7.withAlpha(0x24),
                  waveWidth: 2,
                )),
          ),
        );
      },
    );
  }
}

class _MainWidget extends StatelessWidget {
  final SeatWidgetState seatWidgetState;

  const _MainWidget({
    required this.seatWidgetState,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: seatWidgetState.seatInfoNotifier,
      builder: (context, seatInfo, _) {
        final isSeatLocked = seatInfo.isLocked;
        final hasAvatar = seatInfo.userInfo.avatarURL.isNotEmpty;
        return _buildMainContainer(
            context: context,
            child: isSeatLocked
                ? _buildLockedSeatImage(context: context)
                : (hasAvatar ? _buildAvatarImage(seatInfo.userInfo.avatarURL) : _buildEmptySeatImage(context: context)));
      },
    );
  }

  Widget _buildMainContainer({required BuildContext context, required Widget child}) {
    return SizedBox(
      width: 50.width,
      height: 50.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.width),
        child: Container(
          color: LiveColors.designStandardWhite7.withAlpha(0x1A),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLockedSeatImage({required BuildContext context}) {
    return Center(
      child: Image.asset(
        LiveImages.seatLockedIcon,
        width: 22.width,
        height: 22.width,
        package: Constants.pluginName,
      ),
    );
  }

  Widget _buildAvatarImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      placeholder: (_, __) => _buildPlaceholderAvatarImage(),
      errorWidget: (_, __, ___) => _buildPlaceholderAvatarImage(),
      fit: BoxFit.cover,
    );
  }

  Widget _buildPlaceholderAvatarImage() {
    return Image.asset(
      LiveImages.seatPlaceHolderAvatar,
      package: Constants.pluginName,
    );
  }

  Widget _buildEmptySeatImage({required BuildContext context}) {
    return Center(
      child: Image.asset(
        LiveImages.seatEmptyIcon,
        width: 22.width,
        height: 22.width,
        package: Constants.pluginName,
      ),
    );
  }
}

class _MicrophoneMutedWidget extends StatelessWidget {
  final SeatWidgetState seatWidgetState;

  const _MicrophoneMutedWidget({required this.seatWidgetState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([seatWidgetState.hasAudioNotifier, seatWidgetState.seatInfoNotifier]),
      builder: (context, _) {
        return Visibility(
          visible: !seatWidgetState.hasAudioNotifier.value && seatWidgetState.seatInfoNotifier.value.userInfo.userID.isNotEmpty,
          child: Image.asset(
              width: 16.width,
              height: 16.width,
              LiveImages.seatAudioLockedIcon,
              package: Constants.pluginName),
        );
      },
    );
  }
}

class _InformationWidget extends StatelessWidget {
  final SeatWidgetState seatWidgetState;

  const _InformationWidget({
    required this.seatWidgetState,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: seatWidgetState.seatInfoNotifier,
        builder: (context, seatInfo, _) {
          return SizedBox(
            width: 52.width,
            height: 18.height,
            child: seatInfo.userInfo.userID.isNotEmpty
                ? _buildUserOnSeatWidget(context: context, seatInfo: seatInfo, isOwner: seatWidgetState.isOwner)
                : _buildEmptySeatWidget(seatInfo: seatInfo),
          );
        });
  }

  Widget _buildUserOnSeatWidget({required BuildContext context, required SeatInfo seatInfo, required bool isOwner}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Visibility(
            visible: isOwner,
            child: Image.asset(
                width: 14.width,
                height: 14.width,
                LiveImages.seatOwner,
                package: Constants.pluginName)),
        Padding(
          padding: EdgeInsets.only(left: 2.width),
          child: Container(
            constraints: BoxConstraints(maxWidth: 36.width),
            height:18.height,
            child: Center(
              child: Text(
                seatInfo.userInfo.userName.isNotEmpty ? seatInfo.userInfo.userName : seatInfo.userInfo.userID,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: LiveColors.designStandardG7,
                    fontSize: 10,
                    decoration: TextDecoration.none),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildEmptySeatWidget({required SeatInfo seatInfo}) {
    return Text(
      '${seatInfo.index + 1}',
      textAlign: TextAlign.center,
      style: const TextStyle(
          overflow: TextOverflow.ellipsis,
          color: LiveColors.designStandardG7,
          fontSize: 10,
          decoration: TextDecoration.none),
    );
  }
}
