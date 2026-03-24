import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:atomic_x_core_example/l10n/app_localizations.dart';

/// Co-host user list widget (half-screen panel)
///
/// Related APIs:
/// - `LiveListStore.shared.fetchLiveList(cursor:, count:)` - Fetch the live room list (named parameters, returns `Future`)
/// - `LiveListStore.shared.liveState` - Live list state (`LiveListState`)
///
/// Fields in `LiveListState` (all are `ValueListenable`):
/// - `liveList`: `ValueListenable` of `List<LiveInfo>`
/// - `liveListCursor`: `ValueListenable` of `String`
/// - `currentLive`: `ValueListenable` of `LiveInfo`
///
/// Features:
/// - Display the list of hosts currently available for co-hosting
/// - Show the host avatar, nickname, and live room ID
/// - Support pull-to-refresh
/// - Notify the caller through a callback after selection
class CoHostUserListWidget extends StatefulWidget {
  final String currentLiveID;

  /// Callback after a host is selected, passing the target live room's `LiveInfo`
  final void Function(LiveInfo liveInfo)? onSelectHost;

  /// Callback when the list is empty
  final VoidCallback? onEmptyList;

  /// Callback when loading fails
  final void Function(CompletionHandler error)? onLoadError;

  const CoHostUserListWidget({
    super.key,
    required this.currentLiveID,
    this.onSelectHost,
    this.onEmptyList,
    this.onLoadError,
  });

  @override
  State<CoHostUserListWidget> createState() => _CoHostUserListWidgetState();

  /// Show the widget as a half-screen panel in the given context
  static void show(
    BuildContext context, {
    required String currentLiveID,
    void Function(LiveInfo liveInfo)? onSelectHost,
    VoidCallback? onEmptyList,
    void Function(CompletionHandler error)? onLoadError,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.45,
          child: CoHostUserListWidget(
            currentLiveID: currentLiveID,
            onSelectHost: (liveInfo) {
              Navigator.of(context).pop();
              onSelectHost?.call(liveInfo);
            },
            onEmptyList: onEmptyList,
            onLoadError: onLoadError,
          ),
        );
      },
    );
  }
}

class _CoHostUserListWidgetState extends State<CoHostUserListWidget> {
  // MARK: - Properties

  List<LiveInfo> _liveList = [];

  /// Page size for each request
  static const int _pageSize = 20;

  /// Current pagination cursor
  String _cursor = '';

  /// Loading state
  bool _isLoading = true;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  /// Whitelist of seat layout templates that support cross-room co-hosting
  static bool _isCoHostSupported(SeatLayoutTemplate template) {
    return template is VideoDynamicGrid9Seats ||
        template is VideoDynamicFloat7Seats ||
        template is VideoFixedGrid9Seats ||
        template is VideoFixedFloat7Seats ||
        template is VideoLandscape4Seats;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadList();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // MARK: - Scroll Listener

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      _loadMore();
    }
  }

  // MARK: - Data Loading

  /// Load the list of live rooms available for co-hosting (initial load / pull to refresh)
  void _loadList() {
    setState(() {
      _isLoading = true;
      _cursor = '';
    });

    LiveListStore.shared.fetchLiveList(
      cursor: _cursor,
      count: _pageSize,
    ).then((result) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        // Success — read values from the `ValueListenable` fields in `liveState`
        final liveState = LiveListStore.shared.liveState;
        _cursor = liveState.liveListCursor.value;
        setState(() {
          _liveList =
              liveState.liveList.value
                  .where((info) => info.liveID != widget.currentLiveID)
                  .where((info) => _isCoHostSupported(info.seatTemplate))
                  .toList();
          _hasMore = _cursor.isNotEmpty;
        });

        if (_liveList.isEmpty) {
          widget.onEmptyList?.call();
        }
      } else {
        // Failure
        widget.onLoadError?.call(result);
      }
    });
  }

  /// Load more items when scrolling to the bottom
  void _loadMore() {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    LiveListStore.shared.fetchLiveList(
      cursor: _cursor,
      count: _pageSize,
    ).then((result) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        // Success
        final liveState = LiveListStore.shared.liveState;
        _cursor = liveState.liveListCursor.value;

        final newItems =
            liveState.liveList.value
                .where((info) => info.liveID != widget.currentLiveID)
                .where((info) => _isCoHostSupported(info.seatTemplate))
                .toList();

        // Append with deduplication
        final existingIDs = _liveList.map((info) => info.liveID).toSet();
        final uniqueNewItems = newItems.where((info) => !existingIDs.contains(info.liveID)).toList();
        setState(() {
          _liveList.addAll(uniqueNewItems);
          _hasMore = _cursor.isNotEmpty;
        });
      }
    });
  }

  // MARK: - Actions

  void _closeTapped() {
    Navigator.of(context).pop();
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(31, 31, 31, 1.0),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    l10n.livePKCoHostSelectHost,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _closeTapped,
                    child: Icon(Icons.close, size: 20, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 4),
          // List area
          Expanded(
            child:
                _isLoading && _liveList.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _liveList.isEmpty
                    ? Center(
                      child: Text(
                        l10n.livePKCoHostEmptyList,
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async {
                        _loadList();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _liveList.length,
                        itemExtent: 64,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final liveInfo = _liveList[index];
                          return _CoHostUserCell(
                            liveInfo: liveInfo,
                            onTap: () {
                              widget.onSelectHost?.call(liveInfo);
                            },
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// MARK: - CoHostUserCell

/// Co-host user cell - shows the host avatar, nickname, and live room ID
class _CoHostUserCell extends StatelessWidget {
  final LiveInfo liveInfo;
  final VoidCallback onTap;

  const _CoHostUserCell({required this.liveInfo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final owner = liveInfo.liveOwner;
    final displayName = owner.userName.isEmpty ? owner.userID : owner.userName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Avatar
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child:
                    owner.avatarURL.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: owner.avatarURL,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.white.withValues(alpha: 0.1),
                                child: Icon(Icons.account_circle, color: Colors.white.withValues(alpha: 0.3), size: 40),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.white.withValues(alpha: 0.1),
                                child: Icon(Icons.account_circle, color: Colors.white.withValues(alpha: 0.3), size: 40),
                              ),
                          fit: BoxFit.cover,
                        )
                        : Container(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: Icon(Icons.account_circle, color: Colors.white.withValues(alpha: 0.3), size: 40),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            // Nickname and live room ID
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${liveInfo.liveID}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Connect button (tapping the row triggers the action; this button is visual only)
            Container(
              width: 64,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.livePKCoHostConnect,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
