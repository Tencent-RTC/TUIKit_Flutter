import 'dart:async';

import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:flutter/material.dart';

import '../../common/call_colors.dart';

class _HintDisplayTracker {
  static String? _currentCallId;
  static bool _hadShowAcceptText = false;
  
  static bool shouldShowAcceptText(String callId) {
    if (_currentCallId != callId) {
      _currentCallId = callId;
      _hadShowAcceptText = false;
    }
    return !_hadShowAcceptText;
  }
  
  static void markAcceptTextShown(String callId) {
    if (_currentCallId == callId) {
      _hadShowAcceptText = true;
    }
  }
}

class HintWidget extends StatefulWidget {
  const HintWidget({super.key});

  @override
  State<StatefulWidget> createState() => _HintWidgetState();
}

class _HintWidgetState extends State<HintWidget> {
  final _acceptTextDisplayDuration = const Duration(seconds: 1);
  Timer? _acceptTextTimer;

  @override
  void dispose() {
    _acceptTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AtomicLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.selfInfo,
      builder: (context, selfInfo, child) {
        return _buildConnectionHint(selfInfo, l10n) ??
            _buildStatusHint(selfInfo, l10n) ??
            _buildNetworkQualityHint(selfInfo, l10n) ??
            const SizedBox.shrink();
      },
    );
  }

  Widget? _buildConnectionHint(CallParticipantInfo selfInfo, AtomicLocalizations l10n) {
    final activeCall = CallStore.shared.state.activeCall.value;
    final callId = activeCall.callId;
    
    if (selfInfo.status != CallParticipantStatus.accept || 
        !_HintDisplayTracker.shouldShowAcceptText(callId)) {
      return null;
    }

    _acceptTextTimer?.cancel();
    _acceptTextTimer = Timer(_acceptTextDisplayDuration, () {
      if (mounted) {
        _HintDisplayTracker.markAcceptTextShown(callId);
        setState(() {});
      }
    });

    return Text(
      l10n.callConnected,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: CallColors.colorG7,
      ),
    );
  }

  Widget? _buildStatusHint(CallParticipantInfo selfInfo, AtomicLocalizations l10n) {
    if (selfInfo.status != CallParticipantStatus.waiting) {
      return null;
    }

    final activeCall = CallStore.shared.state.activeCall.value;
    
    if (selfInfo.id == activeCall.inviterId) {
      return Text(
        l10n.callWaitingForInvitationAcceptance,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getHintTextColor(),
        ),
      );
    } else {
      final hintText = activeCall.mediaType == CallMediaType.audio
          ? l10n.callInvitedToAudioCall
          : l10n.callInvitedToVideoCall;

      return Text(
        hintText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getHintTextColor(),
        ),
      );
    }
  }

  Widget? _buildNetworkQualityHint(CallParticipantInfo selfInfo, AtomicLocalizations l10n) {
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.networkQualities,
      builder: (context, networkQualities, child) {
        final hintText = _getNetworkQualityHintText(selfInfo, networkQualities, l10n);
        return hintText.isNotEmpty
            ? Text(
          hintText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getHintTextColor(),
          ),
        )
            : const SizedBox();
      },
    );
  }

  String _getNetworkQualityHintText(
      CallParticipantInfo selfInfo,
      Map<String, NetworkQuality> networkQualities,
      AtomicLocalizations l10n,
      ) {
    final selfNetwork = networkQualities[selfInfo.id];
    if (selfNetwork != null && _isBadNetwork(selfNetwork)) {
      return l10n.callSelfNetworkLowQuality;
    }

    for (var entry in networkQualities.entries) {
      if (entry.key != selfInfo.id && _isBadNetwork(entry.value)) {
        return l10n.callOtherPartyNetworkLowQuality;
      }
    }

    return '';
  }

  bool _isBadNetwork(NetworkQuality? network) {
    return network == NetworkQuality.bad ||
        network == NetworkQuality.veryBad ||
        network == NetworkQuality.down;
  }

  Color _getHintTextColor() {
    if (CallStore.shared.state.activeCall.value.mediaType == CallMediaType.video) {
      return CallColors.colorWhite;
    }
    return CallColors.colorG7;
  }
}