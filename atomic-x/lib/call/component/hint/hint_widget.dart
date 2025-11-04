import 'dart:async';

import 'package:atomic_x/atomicx.dart';
import 'package:atomic_x/call/common/i18n/i18n_utils.dart';
import 'package:flutter/material.dart';

class HintWidget extends StatefulWidget {
  const HintWidget({super.key});

  @override
  State<StatefulWidget> createState() => _HintWidgetState();
}

class _HintWidgetState extends State<HintWidget> {
  final _acceptTextDisplayDuration = const Duration(seconds: 1);
  Timer? _acceptTextTimer;
  bool _hadShowAcceptText = false;

  final _defaultTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Colors.white
  );

  final _boldTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white
  );

  @override
  void dispose() {
    _acceptTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallParticipantStore.shared.state.selfInfo,
      builder: (context, selfInfo, child) {
        return _buildConnectionHint(selfInfo) ??
            _buildStatusHint(selfInfo) ??
            _buildNetworkQualityHint(selfInfo) ??
            const SizedBox.shrink();
      },
    );
  }

  Widget? _buildConnectionHint(CallParticipantInfo selfInfo) {
    if (selfInfo.status != TUICallStatus.accept || _hadShowAcceptText) {
      return null;
    }

    _acceptTextTimer?.cancel();
    _acceptTextTimer = Timer(_acceptTextDisplayDuration, () {
      if (mounted) {
        setState(() => _hadShowAcceptText = true);
      }
    });

    return Text(
      CallKit_t('connected'),
      style: _boldTextStyle,
    );
  }

  Widget? _buildStatusHint(CallParticipantInfo selfInfo) {
    if (selfInfo.status != TUICallStatus.waiting) {
      return null;
    }

    if (selfInfo.id == CallListStore.shared.state.activeCall.value.inviterId) {
      return Text(
        CallKit_t('waitingForInvitationAcceptance'),
        style: _defaultTextStyle,
      );
    }

    if (selfInfo.id != CallListStore.shared.state.activeCall.value.inviterId) {
      final mediaType = CallListStore.shared.state.activeCall.value.mediaType;
      final hintText = mediaType == TUICallMediaType.audio
          ? CallKit_t("invitedToAudioCall")
          : CallKit_t("invitedToVideoCall");

      return Text(hintText, style: _defaultTextStyle);
    }

    return null;
  }

  Widget? _buildNetworkQualityHint(CallParticipantInfo selfInfo) {
    return ValueListenableBuilder(
      valueListenable: CallParticipantStore.shared.state.networkQualities,
      builder: (context, networkQualities, child) {
        final hintText = _getNetworkQualityHintText(selfInfo, networkQualities);
        return hintText.isNotEmpty
            ? Text(hintText, style: _defaultTextStyle)
            : const SizedBox();
      },
    );
  }

  String _getNetworkQualityHintText(
      CallParticipantInfo selfInfo,
      Map<String, TUINetworkQuality> networkQualities
      ) {
    final selfNetwork = networkQualities[selfInfo.id];
    if (selfNetwork != null && _isBadNetwork(selfNetwork)) {
      return CallKit_t("selfNetworkLowQuality");
    }

    for (var entry in networkQualities.entries) {
      if (entry.key != selfInfo.id && _isBadNetwork(entry.value)) {
        return CallKit_t("otherPartyNetworkLowQuality");
      }
    }

    return '';
  }

  bool _isBadNetwork(TUINetworkQuality? network) {
    return network == TUINetworkQuality.qualityBad ||
        network == TUINetworkQuality.qualityVeryBad ||
        network == TUINetworkQuality.qualityDown;
  }
}