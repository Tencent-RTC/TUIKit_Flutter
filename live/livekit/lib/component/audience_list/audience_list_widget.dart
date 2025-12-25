import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';

import 'package:tencent_live_uikit/common/widget/base_bottom_sheet.dart';

import '../../../../common/index.dart';
import 'panel/audience_list_panel_widget.dart';

class AudienceListWidget extends StatefulWidget {
  final String roomId;
  final void Function(LiveUserInfo userInfo)? onClickUserItem;

  const AudienceListWidget({super.key, required this.roomId, this.onClickUserItem});

  @override
  State<AudienceListWidget> createState() => _AudienceListWidgetState();
}

class _AudienceListWidgetState extends State<AudienceListWidget> {
  late final LiveAudienceStore liveAudienceStore;
  late final LiveListListener _liveListListener;
  BottomSheetHandler? _bottomSheetHandler;

  @override
  void initState() {
    super.initState();
    liveAudienceStore = LiveAudienceStore.create(widget.roomId);
    _liveListListener = LiveListListener(onLiveEnded: (String liveID, LiveEndedReason reason, String message) {
      _bottomSheetHandler?.close();
    });
    LiveListStore.shared.addLiveListListener(_liveListListener);
  }

  @override
  void dispose() {
    _bottomSheetHandler?.close();
    LiveListStore.shared.removeLiveListListener(_liveListListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _audienceListViewClick(context);
      },
      child: ValueListenableBuilder(
        valueListenable: liveAudienceStore.liveAudienceState.audienceList,
        builder: (context, audienceList, child) {
          return Container(
            constraints: BoxConstraints(minWidth: 24.width, maxWidth: 126.width),
            height: 24.height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _initAudienceAvatarWidget(),
                SizedBox(width: audienceList.isNotEmpty ? 4.width : 0),
                _initAudienceCountWidget(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _initAudienceAvatarWidget() {
    return ValueListenableBuilder(
      valueListenable: liveAudienceStore.liveAudienceState.audienceList,
      builder: (context, audienceList, child) {
        return Container(
          constraints: BoxConstraints(maxWidth: 52.width),
          height: 24.height,
          color: Colors.transparent,
          child: Visibility(
            visible: audienceList.isNotEmpty,
            child: ListView.builder(
              shrinkWrap: true,
              reverse: true,
              scrollDirection: Axis.horizontal,
              itemCount: audienceList.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final user = audienceList[index];
                final double padding = index == 0 ? 0 : 4.width;
                return Padding(
                  padding: EdgeInsets.only(right: padding),
                  child: ClipOval(
                    child: SizedBox(
                      width: 24.radius,
                      height: 24.radius,
                      child: Image.network(
                        user.avatarURL,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            LiveImages.defaultAvatar,
                            package: Constants.pluginName,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _initAudienceCountWidget() {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [liveAudienceStore.liveAudienceState.audienceList, liveAudienceStore.liveAudienceState.audienceCount]),
      builder: (context, child) {
        var count = liveAudienceStore.liveAudienceState.audienceCount.value;
        if (liveAudienceStore.liveAudienceState.audienceList.value.length <= Constants.roomMaxShowUserCount) {
          count = liveAudienceStore.liveAudienceState.audienceList.value.length;
        }
        return ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(12.radius)),
          child: Container(
            color: LiveColors.black.withAlpha(0x40),
            constraints: BoxConstraints(minWidth: 24.width, maxWidth: 42.width),
            height: 24.height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$count",
                  style: const TextStyle(
                    color: LiveColors.designStandardFlowkitWhite,
                    fontWeight: FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
                Image.asset(
                  LiveImages.audienceListArrow,
                  width: 8.radius,
                  height: 8.radius,
                  package: Constants.pluginName,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension on _AudienceListWidgetState {
  void _audienceListViewClick(BuildContext context) {
    if (MediaQuery.orientationOf(context) != Orientation.portrait) return;
    liveAudienceStore.fetchAudienceList();
    _popupWidget(
        AudienceListPanelWidget(state: liveAudienceStore.liveAudienceState, onClickUserItem: widget.onClickUserItem));
  }

  void _popupWidget(Widget widget, {Color? barrierColor}) {
    _bottomSheetHandler = BaseBottomSheet.showModalSheet(
      barrierColor: barrierColor,
      isScrollControlled: true,
      context: Global.appContext(),
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.radius),
            topRight: Radius.circular(20.radius),
          ),
          color: LiveColors.designStandardG2,
        ),
        child: widget,
      ),
    );
  }
}
