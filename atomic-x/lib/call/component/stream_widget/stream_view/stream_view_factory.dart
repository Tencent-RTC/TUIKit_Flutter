import 'package:tuikit_atomic_x/atomicx.dart';
import 'package:tuikit_atomic_x/call/component/stream_widget/stream_view/participant_stream_view.dart';
import 'package:flutter/material.dart';

class ViewConfig {
  final List<CallFeature> disableFeatures;

  const ViewConfig({
    this.disableFeatures = const [],
  });
}

class StreamViewFactory {
  static StreamViewFactory instance = StreamViewFactory._();
  static final Map<String, GlobalKey> _userKeyMap = {};

  StreamViewFactory._();

  ParticipantStreamView createSingleSelfStreamView({ViewConfig config = const ViewConfig()}) {
    String selfId = CallParticipantStore.shared.state.selfInfo.value.id;
    _userKeyMap.putIfAbsent(selfId, () => GlobalKey());
    return ParticipantStreamView(userId: selfId, index: 0, key: _userKeyMap[selfId], config: config,);
  }

  ParticipantStreamView createSingleRemoteStreamView({ViewConfig config = const ViewConfig()}) {
    CallInfo info = CallStore.shared.state.activeCall.value;
    String userId = info.inviterId == CallParticipantStore.shared.state.selfInfo.value.id
        ? info.inviteeIds[0]
        : info.inviterId;
    _userKeyMap.putIfAbsent(userId, () => GlobalKey());
    return ParticipantStreamView(userId: userId, index: 1, key: _userKeyMap[userId], config: config,);
  }

  List<ParticipantStreamView> createStreamViewList({ViewConfig config = const ViewConfig()}) {
    String selfId = CallParticipantStore.shared.state.selfInfo.value.id;
    List<ParticipantStreamView> viewList = [];
    List<CallParticipantInfo> infoList = CallParticipantStore.shared.state.allParticipants.value;

    _userKeyMap.putIfAbsent(selfId, () => GlobalKey());
    viewList.add(ParticipantStreamView(userId: selfId, index: 1, key: _userKeyMap[selfId], config: config,));

    int index = 2;
    for (var info in infoList) {
      if (info.id != selfId) {
        _userKeyMap.putIfAbsent(info.id, () => GlobalKey());
        viewList.add(ParticipantStreamView(userId: info.id, index: index++, key: _userKeyMap[info.id], config: config,));
      }
    }
    return viewList;
  }

  void remove(String userId) {
    _userKeyMap.remove(userId);
  }

  void clear() {
    _userKeyMap.clear();
  }
}