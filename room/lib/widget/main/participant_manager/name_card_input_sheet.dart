import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

class NameCardInputSheet extends StatefulWidget {
  final String currentNameCard;
  const NameCardInputSheet({super.key, required this.currentNameCard});

  @override
  State<NameCardInputSheet> createState() => _NameCardInputSheetState();
}

class _NameCardInputSheetState extends State<NameCardInputSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentNameCard);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.width,
        right: 16.width,
        top: 12.height,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12.height,
      ),
      decoration: BoxDecoration(color: RoomColors.g2),
      child: Row(
        children: [
          Expanded(child: _buildInputField()),
          SizedBox(width: 12.width),
          _buildConfirmButton(),
        ],
      ),
    );
  }
}

extension _NameCardInputSheetStatePrivate on _NameCardInputSheetState {
  Widget _buildInputField() {
    return Container(
      height: 40.height,
      decoration: BoxDecoration(color: RoomColors.lightGrey, borderRadius: BorderRadius.circular(20.height)),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: TextStyle(fontSize: 14.width, color: RoomColors.white),
        decoration: InputDecoration(
          hintText: RoomLocalizations.of(context)!.roomkit_enter_nickname,
          hintStyle: TextStyle(fontSize: 14.width, color: RoomColors.g6),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.width),
        ),
        maxLength: 20,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleConfirm(),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _handleConfirm,
      child: Container(
        width: 60.width,
        height: 40.height,
        decoration: BoxDecoration(color: RoomColors.brandBlue, borderRadius: BorderRadius.circular(20.height)),
        alignment: Alignment.center,
        child: Text(
          RoomLocalizations.of(context)!.roomkit_confirm,
          style: TextStyle(fontSize: 14.width, color: RoomColors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _handleConfirm() {
    final nameCard = _controller.text.trim();
    Navigator.of(context).pop(nameCard);
  }
}
