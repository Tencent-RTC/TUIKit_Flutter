import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';

/// Barrage interaction widget
///
/// Related APIs:
/// - `BarrageStore.create(liveID)` - Create the barrage management instance (positional parameter)
/// - `BarrageStore.sendTextMessage(text:, extensionInfo:)` - Send a text barrage (named parameters, returns `Future`)
/// - `BarrageStore.appendLocalTip(barrage)` - Insert a local tip message (positional parameter)
/// - `BarrageStore.barrageState` - Barrage state (`BarrageState`)
/// - `GiftStore.create(liveID)` - Create the gift management instance (positional parameter)
/// - `GiftStore.addGiftListener / removeGiftListener` - Gift event listeners (`Listener` pattern)
///
/// Fields in `BarrageState` (`ValueListenable`):
/// - `messageList`: `ValueListenable` of `List<Barrage>`
///
/// Features:
/// - Display the barrage message list and auto-scroll to the bottom
/// - Send text barrages from the bottom input field
/// - Listen to gift events and automatically insert gift-sending messages into the barrage list
class BarrageWidget extends StatefulWidget {
  final String liveID;

  const BarrageWidget({super.key, required this.liveID});

  @override
  State<BarrageWidget> createState() => _BarrageWidgetState();
}

class _BarrageWidgetState extends State<BarrageWidget> {

  // MARK: - Properties

  late final BarrageStore _barrageStore;
  late final GiftStore _giftStore;
  late final GiftListener _giftListener;
  List<Barrage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayInputEntry;

  @override
  void initState() {
    super.initState();
    _barrageStore = BarrageStore.create(widget.liveID);
    _giftStore = GiftStore.create(widget.liveID);
    _setupBindings();
  }

  @override
  void dispose() {
    _barrageStore.barrageState.messageList.removeListener(_onBarrageStateChanged);
    _giftStore.removeGiftListener(_giftListener);
    _scrollController.dispose();
    _removeOverlayInput();
    super.dispose();
  }

  // MARK: - Setup

  void _setupBindings() {
    // Use `addListener` to listen for changes in the barrage message list (side effect: `scrollToBottom`)
    _barrageStore.barrageState.messageList.addListener(_onBarrageStateChanged);

    // Use `GiftListener` to listen for gift events
    _giftListener = GiftListener(
      onReceiveGift: (liveID, gift, count, sender) {
        if (!mounted) return;
        _insertGiftBarrage(
          gift: gift,
          count: count,
          sender: sender,
        );
      },
    );
    _giftStore.addGiftListener(_giftListener);
  }

  /// Callback when the barrage list changes
  void _onBarrageStateChanged() {
    if (!mounted) return;
    setState(() {
      _messages = _barrageStore.barrageState.messageList.value;
    });
    _scrollToBottom();
  }

  // MARK: - Gift Barrage

  /// Insert a gift-sending message into the barrage list
  void _insertGiftBarrage({required Gift gift, required int count, required LiveUserInfo sender}) {
    final l10n = AppLocalizations.of(context);
    final senderName = sender.userName.isEmpty ? sender.userID : sender.userName;
    final barrage = Barrage();
    barrage.textContent = '$senderName ${l10n?.interactiveGiftSent ?? "sent"} ${gift.name} x$count';
    _barrageStore.appendLocalTip(barrage);
  }

  // MARK: - Overlay Input

  /// Tap the placeholder button to show the overlay input view
  void _showOverlayInput() {
    if (_overlayInputEntry != null) return;

    _overlayInputEntry = OverlayEntry(
      builder: (context) => _BarrageOverlayInputView(
        onSend: (text) {
          _sendBarrage(text);
        },
        onDismiss: () {
          _removeOverlayInput();
        },
      ),
    );
    Overlay.of(context).insert(_overlayInputEntry!);
  }

  void _removeOverlayInput() {
    _overlayInputEntry?.remove();
    _overlayInputEntry = null;
  }

  // MARK: - Actions

  /// Send a text barrage
  void _sendBarrage(String text) {
    if (text.isEmpty) return;
    _barrageStore.sendTextMessage(text: text);
  }

  // MARK: - Helpers

  void _scrollToBottom() {
    if (_messages.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Barrage message list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                return _BarrageCell(barrage: _messages[index]);
              },
            ),
          ),
        ),
        // Bottom placeholder input button (tap to show the overlay input view)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GestureDetector(
            onTap: _showOverlayInput,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.interactiveBarragePlaceholder,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// MARK: - BarrageCell

/// Barrage message cell - semi-transparent background showing the sender nickname and message content
class _BarrageCell extends StatelessWidget {
  final Barrage barrage;

  const _BarrageCell({required this.barrage});

  @override
  Widget build(BuildContext context) {
    final senderName = barrage.sender.userName.isEmpty ? barrage.sender.userID : barrage.sender.userName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 60 - 12,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: RichText(
            text: TextSpan(
              children: [
                // Sender name (highlight color)
                TextSpan(
                  text: '$senderName: ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.cyanAccent,
                  ),
                ),
                // Message content
                TextSpan(
                  text: barrage.textContent,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - BarrageOverlayInputView

/// Full-screen barrage input view (semi-transparent mask + input bar above the keyboard)
class _BarrageOverlayInputView extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback onDismiss;

  const _BarrageOverlayInputView({
    required this.onSend,
    required this.onDismiss,
  });

  @override
  State<_BarrageOverlayInputView> createState() => _BarrageOverlayInputViewState();
}

class _BarrageOverlayInputViewState extends State<_BarrageOverlayInputView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Show the keyboard automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    // Listen for focus changes and close automatically when the keyboard is dismissed
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Keyboard dismissed -> remove the overlay
      widget.onDismiss();
    }
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.isEmpty) return;
    widget.onSend(text);
    _textController.clear();
  }

  void _dismiss() {
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent mask (tap to close)
          GestureDetector(
            onTap: _dismiss,
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          // Input bar above the keyboard
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: Container(
              height: 52,
              color: const Color.fromRGBO(38, 38, 38, 0.95),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  // Input field
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: InputDecoration(
                          hintText: l10n.interactiveBarragePlaceholder,
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  SizedBox(
                    width: 44,
                    child: IconButton(
                      onPressed: _handleSend,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
