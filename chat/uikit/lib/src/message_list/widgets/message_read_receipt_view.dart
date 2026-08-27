import 'dart:io';

import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter_svg/flutter_svg.dart';
import '../../common/language/gen/chat_localizations.dart';

class MessageReadReceiptView extends StatefulWidget {
  final MessageActionStore messageActionStore;
  final MessageListStore messageListStore;
  final MessageInfo message;

  const MessageReadReceiptView({
    super.key,
    required this.messageActionStore,
    required this.messageListStore,
    required this.message,
  });

  @override
  State<MessageReadReceiptView> createState() => _MessageReadReceiptViewState();
}

class _MessageReadReceiptViewState extends State<MessageReadReceiptView> {
  bool _isReadSectionExpanded = true;
  bool _isUnreadSectionExpanded = true;
  List<GroupMember> _readMemberList = [];
  bool _hasMoreReadMembers = true;
  List<GroupMember> _unReadMemberList = [];
  bool _hasMoreUnReadMembers = true;
  bool _isLoadingRead = false;
  bool _isLoadingUnread = false;

  late ChatLocalizations _chatLocale;

  @override
  void initState() {
    super.initState();
    _addStateListeners();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatLocale = ChatLocalizations.of(context);
  }

  @override
  void dispose() {
    _removeStateListeners();
    super.dispose();
  }

  void _addStateListeners() {
    final state = widget.messageActionStore.state;
    state.readMemberList.addListener(_onStateChanged);
    state.unreadMemberList.addListener(_onStateChanged);
    state.hasMoreReadMembers.addListener(_onStateChanged);
    state.hasMoreUnreadMembers.addListener(_onStateChanged);
  }

  void _removeStateListeners() {
    final state = widget.messageActionStore.state;
    state.readMemberList.removeListener(_onStateChanged);
    state.unreadMemberList.removeListener(_onStateChanged);
    state.hasMoreReadMembers.removeListener(_onStateChanged);
    state.hasMoreUnreadMembers.removeListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        final state = widget.messageActionStore.state;
        _readMemberList = state.readMemberList.value;
        _hasMoreReadMembers = state.hasMoreReadMembers.value;
        _unReadMemberList = state.unreadMemberList.value;
        _hasMoreUnReadMembers = state.hasMoreUnreadMembers.value;
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingRead = true;
      _isLoadingUnread = true;
    });

    await Future.wait([
      widget.messageActionStore.loadReadMembers(count: 20).then((_) {
        if (mounted) setState(() => _isLoadingRead = false);
      }),
      widget.messageActionStore.loadUnreadMembers(count: 20).then((_) {
        if (mounted) setState(() => _isLoadingUnread = false);
      }),
    ]);
  }

  Future<void> _loadMoreMembers({required bool isRead}) async {
    await widget.messageActionStore.loadMoreMembers(isRead: isRead);
  }

  String get _formattedDate {
    final timestamp = widget.message.timestamp;
    if (timestamp == null) return '';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);

    return Scaffold(
      backgroundColor: colorsTheme.bgColorDefault,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorDefault,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary),
          ),
        ),
        title: Text(
          _chatLocale.detail,
          style: FontScheme.body4Medium.copyWith(
            color: colorsTheme.textColorPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 日期标签
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Text(
                _formattedDate,
                style: FontScheme.caption2Medium.copyWith(
                  color: colorsTheme.textColorSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMessagePreview(colorsTheme),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildReadSection(colorsTheme),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildUnreadSection(colorsTheme),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagePreview(SemanticColorScheme colorsTheme) {
    return Align(
      alignment: Alignment.centerRight,
      child: _buildMessageContent(colorsTheme),
    );
  }

  Widget _buildMessageContent(SemanticColorScheme colorsTheme) {
    final payload = widget.message.messagePayload;
    if (payload == null) {
      return _buildDefaultMessagePreview(colorsTheme, '[${_chatLocale.message}]');
    }

    switch (payload) {
      case TextMessagePayload p:
        return _buildTextMessagePayloadPreview(colorsTheme, p);
      case ImageMessagePayload p:
        return _buildImageMessagePayloadPreview(colorsTheme, p);
      case VideoMessagePayload p:
        return _buildVideoMessagePayloadPreview(colorsTheme, p);
      case AudioMessagePayload p:
        return _buildAudioMessagePayloadPreview(colorsTheme, p);
      case FileMessagePayload p:
        return _buildFileMessagePayloadPreview(colorsTheme, p);
      default:
        return _buildDefaultMessagePreview(colorsTheme, '[${_chatLocale.message}]');
    }
  }

  Widget _buildTextMessagePayloadPreview(SemanticColorScheme colorsTheme, TextMessagePayload payload) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorsTheme.bgColorBubbleOwn,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Text(
        payload.text ?? '',
        style: FontScheme.caption2Medium.copyWith(
          color: colorsTheme.textColorAntiPrimary,
        ),
      ),
    );
  }

  Widget _buildImageMessagePayloadPreview(SemanticColorScheme colorsTheme, ImageMessagePayload payload) {
    String? imagePath = payload.originalImagePath ?? payload.largeImagePath ?? payload.thumbImagePath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 120,
        height: 120,
        child: imagePath != null && imagePath.isNotEmpty
            ? (imagePath.startsWith('http')
                ? Image.network(imagePath, fit: BoxFit.cover)
                : Image.file(File(imagePath), fit: BoxFit.cover))
            : Container(
                color: colorsTheme.bgColorTopBar,
                child: Icon(Icons.image, color: colorsTheme.textColorSecondary),
              ),
      ),
    );
  }

  Widget _buildVideoMessagePayloadPreview(SemanticColorScheme colorsTheme, VideoMessagePayload payload) {
    String? snapshotPath = payload.videoSnapshotPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: snapshotPath != null && snapshotPath.isNotEmpty
                ? (snapshotPath.startsWith('http')
                    ? Image.network(snapshotPath, fit: BoxFit.cover)
                    : Image.file(File(snapshotPath), fit: BoxFit.cover))
                : Container(
                    color: colorsTheme.bgColorTopBar,
                    child: Icon(Icons.videocam, color: colorsTheme.textColorSecondary),
                  ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMessagePayloadPreview(SemanticColorScheme colorsTheme, AudioMessagePayload payload) {
    final duration = payload.audioDuration;
    final displayText = _formatDuration(duration);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorsTheme.bgColorBubbleOwn,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow,
            size: 20,
            color: colorsTheme.textColorAntiPrimary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(8, (index) {
              final heights = [8.0, 16.0, 12.0, 20.0, 10.0, 14.0, 17.0, 8.0];
              return Container(
                width: 2,
                height: heights[index],
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: colorsTheme.textColorAntiPrimary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            displayText,
            style: FontScheme.caption3Regular.copyWith(
              color: colorsTheme.textColorAntiSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessagePayloadPreview(SemanticColorScheme colorsTheme, FileMessagePayload payload) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorsTheme.bgColorBubbleOwn,
        borderRadius: BorderRadius.circular(16),
      ),
      constraints: const BoxConstraints(maxWidth: 250),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 30,
            color: colorsTheme.textColorAntiPrimary,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  payload.fileName ?? _chatLocale.unknown,
                  style: FontScheme.caption2Medium.copyWith(
                    color: colorsTheme.textColorAntiPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(payload.fileSize),
                  style: FontScheme.caption3Regular.copyWith(
                    color: colorsTheme.textColorAntiSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultMessagePreview(SemanticColorScheme colorsTheme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorsTheme.bgColorBubbleOwn,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: FontScheme.caption2Medium.copyWith(
          color: colorsTheme.textColorAntiPrimary,
        ),
      ),
    );
  }

  Widget _buildReadSection(SemanticColorScheme colorsTheme) {
    final readCount = widget.message.readReceiptInfo?.readCount ?? _readMemberList.length;
    return Column(
      children: [
        _buildSectionHeader(
          title: '${_chatLocale.groupReadBy} ($readCount)',
          iconName: 'read_receipt_check_all_highlight',
          isExpanded: _isReadSectionExpanded,
          onTap: () => setState(() => _isReadSectionExpanded = !_isReadSectionExpanded),
          colorsTheme: colorsTheme,
        ),
        if (_isReadSectionExpanded) ...[
          const SizedBox(height: 12),
          if (_isLoadingRead)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else ...[
            ..._readMemberList.map((member) => _buildUserRow(member, colorsTheme)),
            if (_hasMoreReadMembers)
              _buildLoadMoreButton(
                isRead: true,
                colorsTheme: colorsTheme,
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildUnreadSection(SemanticColorScheme colorsTheme) {
    final unreadCount = widget.message.readReceiptInfo?.unreadCount ?? _unReadMemberList.length;
    return Column(
      children: [
        _buildSectionHeader(
          title: '${_chatLocale.groupDeliveredTo} ($unreadCount)',
          iconName: 'read_receipt_check',
          isExpanded: _isUnreadSectionExpanded,
          onTap: () => setState(() => _isUnreadSectionExpanded = !_isUnreadSectionExpanded),
          colorsTheme: colorsTheme,
        ),
        if (_isUnreadSectionExpanded) ...[
          const SizedBox(height: 12),
          if (_isLoadingUnread)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else ...[
            ..._unReadMemberList.map((member) => _buildUserRow(member, colorsTheme)),
            if (_hasMoreUnReadMembers)
              _buildLoadMoreButton(
                isRead: false,
                colorsTheme: colorsTheme,
              ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String iconName,
    required bool isExpanded,
    required VoidCallback onTap,
    required SemanticColorScheme colorsTheme,
  }) {
    final isHighlight = iconName == 'read_receipt_check_all_highlight';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: colorsTheme.bgColorOperate,
          borderRadius: BorderRadius.circular(isExpanded ? 40 : 30),
        ),
        child: Row(
          children: [
            isHighlight
                ? SvgPicture.asset(
                    'chat_assets/icon/$iconName.svg',
                    width: 14,
                    height: 14,
                    package: 'tencent_chat_uikit',
                    fit: BoxFit.contain,
                  )
                : SvgPicture.asset(
                    'chat_assets/icon/$iconName.svg',
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(colorsTheme.textColorPrimary, BlendMode.srcIn),
                    package: 'tencent_chat_uikit',
                    fit: BoxFit.contain,
                  ),
            const SizedBox(width: 8),
            Text(
              title,
              style: FontScheme.caption2Regular.copyWith(
                color: colorsTheme.textColorPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: colorsTheme.textColorSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRow(GroupMember member, SemanticColorScheme colorsTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Avatar.image(
            url: member.avatarURL,
            name: (member.nickname?.isNotEmpty ?? false) ? member.nickname! : member.userID,
            size: AvatarSize.s,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (member.nickname?.isNotEmpty ?? false) ? member.nickname! : member.userID,
              style: FontScheme.caption2Medium.copyWith(
                color: colorsTheme.textColorPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton({
    required bool isRead,
    required SemanticColorScheme colorsTheme,
  }) {
    return GestureDetector(
      onTap: () => _loadMoreMembers(isRead: isRead),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colorsTheme.bgColorOperate.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _chatLocale.more,
            style: FontScheme.caption2Regular.copyWith(
              color: colorsTheme.textColorLink,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int duration) {
    final seconds = duration % 60;
    final minutes = duration ~/ 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$seconds"';
    }
  }

  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
