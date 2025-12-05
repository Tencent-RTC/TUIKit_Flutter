import 'package:tuikit_atomic_x/call/call_view.dart';
import 'package:tuikit_atomic_x/call/component/stream_widget/multi_call_stream_layout_widget.dart';
import 'package:tuikit_atomic_x/call/component/stream_widget/stream_view/participant_stream_view.dart';
import 'package:tuikit_atomic_x/call/component/stream_widget/stream_view/stream_view_factory.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/call/common/constants.dart';
import 'package:tuikit_atomic_x/call/common/i18n/i18n_utils.dart';
import 'package:tuikit_atomic_x/call/common/utils/utils.dart';

class MultiCallStreamWidget extends StatefulWidget {
  final List<CallFeature> disableFeatures;

  const MultiCallStreamWidget({
    super.key,
    required this.disableFeatures,
  });

  @override
  State<MultiCallStreamWidget> createState() => _MultiCallStreamWidgetState();
}

class _MultiCallStreamWidgetState extends State<MultiCallStreamWidget> {
  late List<ParticipantStreamView> _userViewWidgets = [];

  @override
  void initState() {
    MultiCallUserWidgetData.initBlockBigger();
    super.initState();
  }

  @override
  void dispose() {
    StreamViewFactory.instance.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallParticipantStore.shared.state.selfInfo,
      builder: (context, selfInfo, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: NetworkImage(
                  StringStream.makeNull(selfInfo.avatarURL, Constants.defaultAvatar),
                ),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stackTrace) => Image.asset(
                  'call_assets/user_icon.png',
                  package: 'tuikit_atomic_x',
                ),
              ),
            ),
            Opacity(
              opacity: 1,
              child: Container(
                color: const Color.fromRGBO(45, 45, 45, 0.9),
              ),
            ),
            selfInfo.id != CallStore.shared.state.activeCall.value.inviterId
                && selfInfo.status == CallParticipantStatus.waiting
                ? _buildReceivedGroupCallWaiting()
                : _buildGroupCallView(),
          ],
        );
      },
    );
  }

  Widget _buildGroupCallView() {
    return ValueListenableBuilder(
      valueListenable: CallParticipantStore.shared.state.allParticipants,
      builder: (context, value, child) {
        _initUsersViewWidget();
        return Container(
          margin: const EdgeInsets.only(top: 90),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 4 / 3,
          child: MultiCallStreamLayoutWidget(
            participantViews: _userViewWidgets,
          ),
        );
      },
    );
  }

  Widget _buildReceivedGroupCallWaiting() {
    return Positioned(
      top: 0,
      left: 0,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _getCallerInfoDisplay(),
          Text(
            CallKit_t("invitedToGroupCall"),
            textScaleFactor: 1.0,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(
            height: 50,
          ),
          _getInviteeListView(),
        ],
      ),
    );
  }

  _getCallerInfoDisplay() {
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.activeCall,
      builder: (context, activeCall, child) {
        return _CallerInfoWidget(userId: activeCall.inviterId);
      },
    );
  }

  _getInviteeListView() {
    return ValueListenableBuilder(
      valueListenable: CallParticipantStore.shared.state.allParticipants,
      builder: (context, allParticipants, child) {
        List<String> inviteeAvatarList = [];
        for (var participant in allParticipants) {
          if (participant.id != CallParticipantStore.shared.state.selfInfo.value.id
              && participant.id != CallStore.shared.state.activeCall.value.inviterId) {
            inviteeAvatarList.add(participant.avatarURL);
          }
        }
        if (inviteeAvatarList.isNotEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                CallKit_t("theyAreAlsoThere"),
                textScaleFactor: 1.0,
                style: const TextStyle(color: Colors.white),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: List.generate(inviteeAvatarList.length, ((index) {
                    return Container(
                      height: 30,
                      width: 30,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      child: Image(
                        image: NetworkImage(
                          StringStream.makeNull(
                            inviteeAvatarList[index],
                            Constants.defaultAvatar,
                          ),
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stackTrace) => Image.asset(
                          'call_assets/user_icon.png',
                          package: 'tuikit_atomic_x',
                        ),
                      ),
                    );
                  })),
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  _initUsersViewWidget() {
    int userCount = CallParticipantStore.shared.state.allParticipants.value.length;
    MultiCallUserWidgetData.updateBlockBigger(userCount);
    MultiCallUserWidgetData.initCanPlaceSquare(userCount);
    _userViewWidgets.clear();

    _userViewWidgets = StreamViewFactory.instance.createStreamViewList(config: ViewConfig(disableFeatures: widget.disableFeatures));
  }

  String _getCallerDisplayName(List<CallParticipantInfo> allParticipants, String userId) {
    for (var participant in allParticipants) {
      if (participant.id == userId) {
        return _getUserDisplayName(participant);
      }
    }
    return "";
  }

  String? _getUserAvatarUrl(List<CallParticipantInfo> allParticipants, String userId) {
    for (var participant in allParticipants) {
      if (participant.id == userId) {
        return participant.avatarURL;
      }
    }
    return null;
  }

  String _getUserDisplayName(CallParticipantInfo info) {
    if (info.remark.isNotEmpty) {
      return info.remark;
    } else if (info.name.isNotEmpty) {
      return info.name;
    } else {
      return info.id;
    }
  }
}

class _CallerInfoWidget extends StatefulWidget {
  final String userId;

  const _CallerInfoWidget({Key? key, required this.userId}) : super(key: key);

  @override
  State<_CallerInfoWidget> createState() => _CallerInfoWidgetState();
}

class _CallerInfoWidgetState extends State<_CallerInfoWidget> {
  String displayName = "";
  String avatarUrl = Constants.defaultAvatar;
  ContactListStore contactListStore = ContactListStore.create();

  @override
  void initState() {
    contactListStore.addListener(() {
      displayName = contactListStore.contactListState.addFriendInfo?.title ?? "";
      avatarUrl = contactListStore.contactListState.addFriendInfo?.avatarURL ?? Constants.defaultAvatar;
      if (mounted) setState(() {});
    });
    contactListStore.fetchUserInfo(userID: widget.userId);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    contactListStore.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 150),
          height: 120,
          width: 120,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          child: Image(
            image: NetworkImage(
              StringStream.makeNull(
                avatarUrl,
                Constants.defaultAvatar,
              ),
            ),
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stackTrace) => Image.asset(
              'call_assets/user_icon.png',
              package: 'tuikit_atomic_x',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            displayName,
            textScaleFactor: 1.0,
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ],
    );
  }

}

class MultiCallUserWidgetData {
  static ValueNotifier<Map<int, bool>> blockBigger = ValueNotifier({
    1: false,
    2: false,
    3: false,
    4: false,
    5: false,
    6: false,
    7: false,
    8: false,
    9: false
  });

  static int blockCount = 0;

  static List<List<bool>> canPlaceSquare = [
    [true, true, true],
    [true, true, true],
    [true, true, true],
    [true, true, true]
  ];

  static initBlockBigger() {
    blockBigger.value = {
      1: false,
      2: false,
      3: false,
      4: false,
      5: false,
      6: false,
      7: false,
      8: false,
      9: false
    };
  }

  static updateBlockBigger(int blockCount) {
    // Settings for the exit of the big picture
    blockBigger.value.forEach((key, value) {
      if (value == true && key > blockCount) {
        blockBigger.value = {
          1: false,
          2: false,
          3: false,
          4: false,
          5: false,
          6: false,
          7: false,
          8: false,
          9: false
        };
      }
    });
  }

  static bool hasBiggerSquare() {
    bool has = false;
    blockBigger.value.forEach((key, value) {
      if (value == true) {
        has = true;
      }
    });
    return has;
  }

// Mark the large position. False is placed, small pieces cannot be placed directly on it, and large pieces can be placed directly on it.
// Be initialized by BlockBigger and BlockCount Canplacesquare
  static initCanPlaceSquare(int blockCount) {
    canPlaceSquare = [
      [true, true, true],
      [true, true, true],
      [true, true, true],
      [true, true, true]
    ];

    bool has = false;
    int biggerSquareIndex = 0;
    blockBigger.value.forEach((key, value) {
      if (value == true) {
        has = true;
        biggerSquareIndex = key;
      }
    });

    if (!has) return;

    if (blockCount <= 4) {
      canPlaceSquare = [
        [false, false, false],
        [false, false, false],
        [false, false, false],
        [true, true, true]
      ];
      return;
    }
    int i = (biggerSquareIndex - 1) ~/ 3;
    int j = (biggerSquareIndex - 1) % 3;

    j = (j > 1) ? 1 : j;

    canPlaceSquare[i][j] = false;
    canPlaceSquare[i][j + 1] = false;
    canPlaceSquare[i + 1][j] = false;
    canPlaceSquare[i + 1][j + 1] = false;
  }
}