import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rtc_room_engine/rtc_room_engine.dart';
import 'package:tencent_live_uikit/common/index.dart';
import 'package:tencent_live_uikit/voice_room/manager/voice_room_prepare_store.dart';
import 'package:tencent_live_uikit/voice_room/widget/panel/live_cover_select_panel_widget.dart';

class LivePrepareInfoEditWidget extends StatefulWidget {
  final VoiceRoomPrepareStore prepareStore;

  const LivePrepareInfoEditWidget({super.key, required this.prepareStore});

  @override
  State<LivePrepareInfoEditWidget> createState() => _LivePrepareInfoEditWidgetState();
}

class _LivePrepareInfoEditWidgetState extends State<LivePrepareInfoEditWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final roomName = TUIRoomEngine.getSelfInfo().userName ?? '';
    _controller.text = roomName;
    widget.prepareStore.onSetRoomName(roomName);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [_initBackgroundWidget(), _initLiveCoverWidget(), _initLiveNameWidget(), _initLiveModeWidget()],
    );
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _initBackgroundWidget() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: LiveColors.notStandard40G1,
          borderRadius: BorderRadius.circular(16.radius),
        ),
      ),
    );
  }

  Widget _initLiveCoverWidget() {
    return Positioned(
      left: 8.width,
      top: 8.height,
      bottom: 8.height,
      child: GestureDetector(
        onTap: () {
          _showCoverSelectPanel();
        },
        child: Stack(
          children: [
            SizedBox(
              width: 72.width,
              height: 96.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.radius),
                child: ValueListenableBuilder(
                  valueListenable: ValueSelector(widget.prepareStore.state.liveInfo, (liveInfo) => liveInfo.coverURL),
                  builder: (context, coverURL, _) {
                    return CachedNetworkImage(
                        imageUrl: coverURL,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          return Image.asset(
                            LiveImages.streamDefaultCover,
                            package: Constants.pluginName,
                          );
                        });
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                    color: LiveColors.notStandardBlack80Transparency,
                    borderRadius:
                        BorderRadius.only(bottomLeft: Radius.circular(8.width), bottomRight: Radius.circular(8.width))),
                child: Text(
                  LiveKitLocalizations.of(Global.appContext())!.common_set_cover,
                  style: const TextStyle(color: LiveColors.designStandardG7, fontSize: 14),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _initLiveNameWidget() {
    return Positioned(
      left: 92.width,
      right: 18.width,
      height: 48.height,
      child: Column(
        children: [
          Expanded(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ValueListenableBuilder(
                    valueListenable: ValueSelector(widget.prepareStore.state.liveInfo, (liveInfo) => liveInfo.liveName),
                    builder: (context, liveName, child) {
                      return SizedBox(
                        width: 185.width,
                        child: TextField(
                            controller: _controller,
                            inputFormatters: [_Utf8ByteLengthLimitingTextInputFormatter(100)],
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                              border: InputBorder.none,
                            ),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 16, color: LiveColors.designStandardG7, fontWeight: FontWeight.w500),
                            onChanged: (value) {
                              widget.prepareStore.onSetRoomName(value);
                            }),
                      );
                    },
                  ),
                  SizedBox(
                    width: 16.radius,
                    height: 16.radius,
                    child: Image.asset(
                      LiveImages.streamEditIcon,
                      package: Constants.pluginName,
                    ),
                  ),
                ]),
          ),
          Container(
            width: 235.width,
            height: 1.height,
            color: LiveColors.designStandardFlowkitWhite.withAlpha(0x4D),
          )
        ],
      ),
    );
  }

  Widget _initLiveModeWidget() {
    return Positioned(
      left: 92.width,
      top: 56.height,
      child: GestureDetector(
        onTap: () {
          _showLiveModeSelectPanel();
        },
        child:
            Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 16.radius,
            height: 16.radius,
            child: Image.asset(
              LiveImages.streamPrivacyMode,
              package: Constants.pluginName,
            ),
          ),
          SizedBox(
            width: 8.width,
          ),
          Text(
            LiveKitLocalizations.of(Global.appContext())!.common_stream_privacy_status,
            style: const TextStyle(
              fontSize: 14,
              color: LiveColors.designStandardG7,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          ValueListenableBuilder(
            valueListenable: ValueSelector(widget.prepareStore.state.liveInfo, (liveInfo) => liveInfo.isPublicVisible),
            builder: (context, isPublicVisible, child) {
              return Text(
                _getPrivacyStatus(isPublicVisible ? PrivacyStatus.public : PrivacyStatus.privacy),
                style: const TextStyle(
                  fontSize: 14,
                  color: LiveColors.designStandardG7,
                ),
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          SizedBox(
            width: 20.radius,
            height: 20.radius,
            child: Image.asset(
              LiveImages.streamEditArrow,
              package: Constants.pluginName,
            ),
          ),
        ]),
      ),
    );
  }
}

extension on _LivePrepareInfoEditWidgetState {
  void _showCoverSelectPanel() {
    popupWidget(LiveCoverSelectPanelWidget(
        prepareStore: widget.prepareStore,
        coverUrls: Constants.coverUrlList,
        initialCoverUrl: widget.prepareStore.state.liveInfo.value.coverURL));
  }

  void _showLiveModeSelectPanel() {
    List<ActionSheetModel> list = [
      ActionSheetModel(
          isCenter: true,
          text: LiveKitLocalizations.of(Global.appContext())!.common_stream_privacy_status_default,
          bingData: 1),
      ActionSheetModel(
          isCenter: true,
          text: LiveKitLocalizations.of(Global.appContext())!.common_stream_privacy_status_privacy,
          bingData: 2),
    ];
    ActionSheet.show(list, (ActionSheetModel model) async {
      final mode = model.bingData == 1 ? PrivacyStatus.public : PrivacyStatus.privacy;
      widget.prepareStore.onSetRoomPrivacy(mode);
    });
  }

  String _getPrivacyStatus(PrivacyStatus status) {
    switch (status) {
      case PrivacyStatus.public:
        return LiveKitLocalizations.of(Global.appContext())!.common_stream_privacy_status_default;
      case PrivacyStatus.privacy:
        return LiveKitLocalizations.of(Global.appContext())!.common_stream_privacy_status_privacy;
      default:
        return LiveKitLocalizations.of(Global.appContext())!.common_stream_privacy_status_default;
    }
  }
}

class _Utf8ByteLengthLimitingTextInputFormatter extends TextInputFormatter {
  final int maxBytes;

  _Utf8ByteLengthLimitingTextInputFormatter(this.maxBytes);

  @override
  TextEditingValue formatEditUpdate(_, TextEditingValue newValue) {
    if (newValue.composing.isValid) return newValue;

    final bytes = utf8.encode(newValue.text);
    if (bytes.length <= maxBytes) return newValue;

    final safeText = _safeTruncate(newValue.text);
    if (safeText == newValue.text) return newValue;

    return TextEditingValue(
      text: safeText,
      selection: TextSelection.collapsed(offset: safeText.length),
    );
  }

  String _safeTruncate(String text) {
    final bytes = utf8.encode(text);
    if (bytes.length <= maxBytes) return text;

    final safeBytes = utf8.encode(text).sublist(0, maxBytes);

    int length = safeBytes.length;
    while (length > 0) {
      try {
        return utf8.decode(safeBytes.sublist(0, length), allowMalformed: false);
      } catch (_) {
        length--;
      }
    }

    return '';
  }
}
