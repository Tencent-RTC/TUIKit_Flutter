import 'package:atomic_x_core/api/barrage/barrage_store.dart';
import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

import '../../common/index.dart';
import '../../state/store.dart';
import '../send/index.dart';
import '../emoji/index.dart';


class BarrageInputPanelWidget extends StatefulWidget {
  final BarrageSendController controller;

  const BarrageInputPanelWidget({super.key, required this.controller});

  @override
  State<BarrageInputPanelWidget> createState() => _BarrageInputPanelWidgetState();
}

class _BarrageInputPanelWidgetState extends State<BarrageInputPanelWidget> {
  ValueNotifier<bool> _isValidBarrageContent = ValueNotifier(false);
  late final VoidCallback _inputListener = _textInputListener;

  @override
  void initState() {
    super.initState();
    widget.controller.textEditingController.addListener(_textInputListener);
  }

  @override
  void dispose() {
    widget.controller.textEditingController.removeListener(_textInputListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.setInputKeyboardHeight(MediaQuery
        .viewInsetsOf(context)
        .bottom);
    return SizedBox(
      width: MediaQuery
          .sizeOf(context)
          .width,
      height: widget.controller.getInputKeyboardHeight(context) + 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildTopBarWidget(context),
          _buildPanelWidget(context),
        ],
      ),
    );
  }

  Widget _buildTopBarWidget(BuildContext context) {
    Orientation orientation = MediaQuery.orientationOf(context);
    return Container(
      width: MediaQuery
          .sizeOf(context)
          .width,
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: orientation == Orientation.portrait ? 16 : 52, vertical: 12),
      color: BarrageColors.barrageG2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildEmojiButton(),
          const SizedBox(width: 10),
          _buildTextField(context),
          const SizedBox(width: 10),
          _buildSendButton(context),
        ],
      ),
    );
  }

  Widget _buildPanelWidget(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.controller.showEmojiPanel,
        builder: (BuildContext context, bool value, Widget? child) {
          return widget.controller.showEmojiPanel.value
              ? EmojiPanelWidget(controller: widget.controller)
              : Container(
            color: BarrageColors.barrageColorDark,
            height: widget.controller.getInputKeyboardHeight(context),
          );
        });
  }

  Widget _buildEmojiButton() {
    return GestureDetector(
      onTap: () {
        widget.controller.toggleEmojiType();
      },
      child: ValueListenableBuilder(
        valueListenable: widget.controller.showEmojiPanel,
        builder: (BuildContext context, bool value, Widget? child) {
          return Image.asset(
            widget.controller.showEmojiPanel.value ? BarrageImages.keyboardIcon : BarrageImages.emojiIcon,
            width: 24,
            height: 24,
            fit: BoxFit.fill,
            package: Constants.pluginName,
          );
        },
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: ExtendedTextField(
          key: widget.controller.textFieldKey,
          controller: widget.controller.textEditingController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          autofocus: true,
          maxLines: null,
          specialTextSpanBuilder: EmojiTextSpanBuilder(context: context),
          cursorColor: BarrageColors.barrageFlowkitGreen,
          textInputAction: TextInputAction.send,
          focusNode: widget.controller.focusNode,
          decoration: InputDecoration(
            hintText: BarrageLocalizations.of(context)!.barrage_let_us_chat,
            hintStyle: const TextStyle(
              color: BarrageColors.barrageTextGrey,
              fontSize: 12,
            ),
            fillColor: BarrageColors.barrage40G1,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          ),
          onTap: () {
            widget.controller.showEmojiPanel.value = false;
          },
          onSubmitted: (value) {
            _sendBarrage();
          },
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 36,
      child: ValueListenableBuilder(
          valueListenable: _isValidBarrageContent, builder: (context, isValidBarageContet, _) {
        return ElevatedButton(
          onPressed: () => _sendBarrage(),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                isValidBarageContet ? BarrageColors.barrageButtonColorPrimaryDefault : BarrageColors
                    .barrageButtonColorPrimaryDefaultDisabled),
            padding: WidgetStateProperty.all(EdgeInsets.zero),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          child: Text(
            BarrageLocalizations.of(context)!.barrage_send,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      }),
    );
  }

  Barrage _generateSendBarrage() {
    LiveUserInfo sender = LiveUserInfo();
    sender.userID = Store().selfUserId;
    sender.userName = Store().selfName;

    Barrage barrage = Barrage();
    barrage.textContent = widget.controller.textEditingController.text;
    barrage.sender = sender;
    return barrage;
  }

  void _sendBarrage() {
    if (!_isValidBarrageContent.value) {
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    widget.controller.sendBarrage(_generateSendBarrage()).then((result) {
      if (true == result) {
        widget.controller.textEditingController.clear();
      }
    });
  }

  void _textInputListener() {
    _isValidBarrageContent.value = widget.controller.textEditingController.text.isNotEmpty;
  }
}