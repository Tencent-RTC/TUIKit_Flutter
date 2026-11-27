import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'live_home_list_store.dart';
import 'live_home_preview_view.dart';

class LiveHomePlayerView extends StatefulWidget {
  const LiveHomePlayerView({super.key, required this.store, required this.liveID, required this.onJoiningChanged});
  final LiveHomeListStore store;
  final String liveID;
  final ValueChanged<bool> onJoiningChanged;
  @override
  State<LiveHomePlayerView> createState() => _LiveHomePlayerViewState();
}

class _LiveHomePlayerViewState extends State<LiveHomePlayerView> {
  bool _room = false;
  bool _closing = false;
  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing) return;
    setState(() => _closing = true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: const Color(0xff101116),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: LiveHomePreviewView(
                store: widget.store,
                active: !_closing,
                initialLiveID: widget.liveID,
                closesToGrid: true,
                onClose: _close,
                onRoomChanged: (value) {
                  if (mounted && _room != value) setState(() => _room = value);
                },
                onJoiningChanged: widget.onJoiningChanged,
              ),
            ),
            if (!_room)
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + 6,
                right: 3,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: SizedBox.square(
                    dimension: 44,
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x2e0a0c12),
                          border: Border.all(color: const Color(0x14ffffff)),
                        ),
                        child: Center(child: Image.asset('assets/home_live_close.png', width: 15, height: 15)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
