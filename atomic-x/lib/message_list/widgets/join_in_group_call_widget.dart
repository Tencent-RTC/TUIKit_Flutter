import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/basic_controls/avatar.dart';
import 'package:tuikit_atomic_x/base_component/localizations/atomic_localizations.dart';
import 'package:tuikit_atomic_x/base_component/theme/color_scheme.dart';
import 'package:tuikit_atomic_x/base_component/theme/theme_state.dart';
import 'package:tuikit_atomic_x/base_component/utils/tui_event_bus.dart';

class JoinInGroupCallWidget extends StatefulWidget {
  final List<String> userIDs;
  final String? roomId;
  final CallMediaType mediaType;
  final String groupId;
  final String? callId;

  const JoinInGroupCallWidget(
      {required this.userIDs,
      required this.roomId,
      required this.mediaType,
      required this.groupId,
      required this.callId,
      Key? key})
      : super(key: key);

  @override
  State<JoinInGroupCallWidget> createState() => _JoinInGroupCallWidgetState();
}

class _JoinInGroupCallWidgetState extends State<JoinInGroupCallWidget> {
  bool _isExpand = false;
  final List<String> _userAvatars = [];
  late AtomicLocalizations _atomicLocale;
  late SemanticColorScheme _colorsTheme;

  @override
  void initState() {
    super.initState();
    _updateUserAvatars();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atomicLocale = AtomicLocalizations.of(context);
    _colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  void didUpdateWidget(covariant JoinInGroupCallWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.userIDs, oldWidget.userIDs)) {
      _updateUserAvatars();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: _colorsTheme.bgColorOperate,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _colorsTheme.bgColorInput,
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: GestureDetector(
            onTap: () => _changeExpand(),
            child: Container(
                width: MediaQuery.of(context).size.width - 10,
                height: _isExpand ? 260 : 40,
                child: Column(
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 5)),
                    Row(
                      children: [
                        const Padding(padding: EdgeInsets.only(left: 15)),
                        Image.asset(
                          'call_assets/join_group_call.png',
                          package: 'tuikit_atomic_x',
                          width: 20,
                          height: 20,
                        ),
                        const Padding(padding: EdgeInsets.only(left: 15)),
                        Text(
                          _atomicLocale.peopleOnCall(widget.userIDs.length),
                          textScaleFactor: 1.0,
                        ),
                        const Spacer(),
                        Image.asset(
                          _isExpand ? 'call_assets/join_group_compress.png' : 'call_assets/join_group_expand.png',
                          package: 'tuikit_atomic_x',
                        ),
                        const Padding(padding: EdgeInsets.only(left: 15)),
                      ],
                    ),
                    _isExpand ? const Padding(padding: EdgeInsets.only(top: 10)) : const SizedBox(),
                    _isExpand
                        ? Container(
                            width: MediaQuery.of(context).size.width - 30,
                            height: 200,
                            decoration: BoxDecoration(
                              color: _colorsTheme.bgColorEntryCard,
                              borderRadius: BorderRadius.circular(5), // Set the corner radius
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width - 40,
                                    height: 150,
                                    child: Center(
                                        child: ListView.builder(
                                      itemCount: _userAvatars.length,
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (BuildContext context, int index) {
                                        return Padding(
                                            padding: const EdgeInsets.only(left: 2.5, right: 2.5, top: 35, bottom: 35),
                                            child: Container(
                                              height: 80,
                                              width: 80,
                                              clipBehavior: Clip.hardEdge,
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                              ),
                                              child: Avatar.image(
                                                name: widget.userIDs[index],
                                                url: _userAvatars[index],
                                                size: AvatarSize.xl,
                                              ),
                                            ));
                                      },
                                      padding: EdgeInsets.only(
                                          left: _computeEdge(
                                              MediaQuery.of(context).size.width - 40, 85, _userAvatars.length),
                                          right: _computeEdge(
                                              MediaQuery.of(context).size.width - 40, 85, _userAvatars.length)),
                                    ))),
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    color: _colorsTheme.strokeColorPrimary,
                                  ),
                                ),
                                InkWell(
                                    onTap: () => _joinInGroupCallAction(),
                                    child: Container(
                                      height: 49,
                                      alignment: Alignment.center,
                                      child: Text(
                                        _atomicLocale.join,
                                        textScaleFactor: 1.0,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                    ))
                              ],
                            ),
                          )
                        : const SizedBox(),
                  ],
                ))));
  }

  _computeEdge(double maxWidth, int imageWidth, int count) {
    int maxNeedCompute = maxWidth ~/ imageWidth;
    if (maxNeedCompute >= count) {
      return (maxWidth - imageWidth * count) / 2;
    } else {
      return 0.0;
    }
  }

  _changeExpand() {
    _isExpand = !_isExpand;
    setState(() {});
  }

  _joinInGroupCallAction() {
    PublishParams params = PublishParams();
    params.isSticky = false;
    params.data = {"callId": widget.callId};
    TUIEventBus.shared.publish("call.startJoin", null, params);
  }

  _updateUserAvatars() async {
    _userAvatars.clear();
    GroupSettingStore groupSettingStore = GroupSettingStore.create(groupID: widget.groupId);
    final completionHandler = await groupSettingStore.fetchGroupMembersInfo(userIDList: widget.userIDs);
    if (completionHandler.isSuccess && groupSettingStore.groupSettingState.membersInfo != null) {
      for (var memberInfo in groupSettingStore.groupSettingState.membersInfo!) {
        if (memberInfo.avatarURL == null || memberInfo.avatarURL!.isEmpty) {
          _userAvatars.add('');
        } else {
          _userAvatars.add(memberInfo.avatarURL!);
        }
      }
      setState(() {});
    }
  }
}
