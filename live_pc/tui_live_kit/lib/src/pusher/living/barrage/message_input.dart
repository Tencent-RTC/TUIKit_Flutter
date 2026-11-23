import 'package:flutter/material.dart';

import '../../../common/style/live_kit_style.dart';
import '../../../l10n/live_kit_localizations.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool enabled;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    const Color accent = LiveKitStyle.brand;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: LiveKitStyle.white8,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: focused ? accent : LiveKitStyle.white10,
                  width: focused ? 1.2 : 0.8,
                ),
              ),
              child: Center(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    focusColor: LiveKitStyle.transparent,
                    hoverColor: LiveKitStyle.transparent,
                    splashColor: LiveKitStyle.transparent,
                    highlightColor: LiveKitStyle.transparent,
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    style: const TextStyle(color: LiveKitStyle.whitePure, fontSize: 12),
                    cursorColor: LiveKitStyle.brand,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      fillColor: LiveKitStyle.transparent,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: LiveKitLocalizations.of(context).barrageInputHint,
                      hintStyle: const TextStyle(
                        color: LiveKitStyle.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: LiveKitStyle.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: LiveKitStyle.whitePure.withAlpha(enabled ? 235 : 100),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
