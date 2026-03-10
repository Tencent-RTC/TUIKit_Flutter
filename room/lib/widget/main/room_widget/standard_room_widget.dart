import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';
import 'package:atomic_x_core/atomicxcore.dart';

import 'participant_layout_widget.dart';

class StandardRoomWidget extends StatefulWidget {
  final String roomId;

  const StandardRoomWidget({super.key, required this.roomId});

  @override
  State<StandardRoomWidget> createState() => _StandardRoomWidgetState();
}

class _StandardRoomWidgetState extends State<StandardRoomWidget> {
  static const int _itemsPerPage = 6;

  late final RoomParticipantStore _participantStore;
  late final PageController _pageController;

  final ValueNotifier<int> _currentPageIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isScrolling = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _participantStore = RoomParticipantStore.create(widget.roomId);
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_pageController.hasClients) {
          _pageController.position.isScrollingNotifier.addListener(_handleScrolling);
        }
      }
    });
  }

  @override
  void dispose() {
    if (_pageController.hasClients) {
      _pageController.position.isScrollingNotifier.removeListener(_handleScrolling);
    }
    _pageController.dispose();
    _currentPageIndex.dispose();
    _isScrolling.dispose();
    super.dispose();
  }

  void _handleScrolling() {
    if (!mounted || !_pageController.hasClients) return;

    final isScrolling = _pageController.position.isScrollingNotifier.value;
    _isScrolling.value = !isScrolling;
  }

  int _getTotalPageCount(List<RoomParticipant> participants, bool hasScreenShare) {
    final count = hasScreenShare
        ? (participants.length / _itemsPerPage).ceil() + 1
        : (participants.length / _itemsPerPage).ceil();
    return count > 0 ? count : 1;
  }

  int _getPageStartIndex(int pageIndex, bool hasScreenShare) {
    if (hasScreenShare) {
      return pageIndex == 0 ? 0 : (pageIndex - 1) * _itemsPerPage;
    }
    return pageIndex * _itemsPerPage;
  }

  int _getPageEndIndex(int pageIndex, int totalParticipants, bool hasScreenShare) {
    final startIndex = _getPageStartIndex(pageIndex, hasScreenShare);
    final endIndex = startIndex + _itemsPerPage - 1;
    return endIndex < totalParticipants ? endIndex : totalParticipants - 1;
  }

  bool _isTwoUserLayout(List<RoomParticipant> participants, bool hasScreenShare) {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return _buildContent(orientation);
      },
    );
  }

  Widget _buildContent(Orientation orientation) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _participantStore.state.participantList,
        _participantStore.state.participantWithScreen,
      ]),
      builder: (context, _) {
        final allParticipants = _participantStore.state.participantList.value;
        final screenParticipant = _participantStore.state.participantWithScreen.value;
        final hasScreenShare = screenParticipant != null;
        final participants = allParticipants.isNotEmpty ? allParticipants : <RoomParticipant>[];
        final totalPages = _getTotalPageCount(participants, hasScreenShare);
        return Stack(
          children: [
            SizedBox(
              height: orientation == Orientation.portrait ? 665.height : MediaQuery.of(context).size.height,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  _currentPageIndex.value = index;
                },
                itemCount: totalPages,
                itemBuilder: (context, pageIndex) {
                  final isScreenLayout = hasScreenShare && pageIndex == 0;
                  final startIndex = _getPageStartIndex(pageIndex, hasScreenShare);
                  final endIndex = _getPageEndIndex(pageIndex, participants.length, hasScreenShare);
                  final isTwoUser = _isTwoUserLayout(participants, hasScreenShare);
                  return ParticipantLayoutWidget(
                    roomId: widget.roomId,
                    participants: participants,
                    startIndex: startIndex,
                    endIndex: endIndex,
                    currentPageIndex: pageIndex,
                    isScreenLayout: isScreenLayout,
                    isTwoUserLayout: isTwoUser,
                    screenParticipant: screenParticipant,
                    isScrolling: _isScrolling,
                  );
                },
              ),
            ),
            Center(child: _buildNavigationArrows(totalPages)),
          ],
        );
      },
    );
  }

  Widget _buildNavigationArrows(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: _currentPageIndex,
      builder: (context, currentIndex, _) {
        final actualIndex =
            _pageController.hasClients && _pageController.page != null ? _pageController.page!.round() : currentIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildLeftArrow(actualIndex), _buildRightArrow(actualIndex, totalPages)],
          ),
        );
      },
    );
  }

  Widget _buildLeftArrow(int currentIndex) {
    final isVisible = currentIndex > 0;

    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: 24.radius,
        height: 24.radius,
        child: Center(
          child: Image.asset(
            RoomImages.arrowLeft,
            width: 24.radius,
            height: 24.radius,
            package: RoomConstants.pluginName,
          ),
        ),
      ),
    );
  }

  Widget _buildRightArrow(int currentIndex, int totalPages) {
    final isVisible = currentIndex < totalPages - 1;

    return Visibility(
      visible: isVisible,
      child: SizedBox(
        width: 24.radius,
        height: 24.radius,
        child: Center(
          child: Image.asset(
            RoomImages.arrowRight,
            width: 24.radius,
            height: 24.radius,
            package: RoomConstants.pluginName,
          ),
        ),
      ),
    );
  }
}
