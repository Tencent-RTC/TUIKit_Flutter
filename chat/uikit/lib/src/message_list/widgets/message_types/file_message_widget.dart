import 'package:atomic_x_core/api/message/message_action_store.dart';
import 'dart:io';

import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/device_info/device.dart';
import 'package:tencent_chat_uikit/src/file_picker/file_picker.dart';
import 'package:tencent_chat_uikit/src/message_list/message_list_config.dart';
import 'package:tencent_chat_uikit/src/message_list/utils/message_utils.dart';
import 'package:tencent_chat_uikit/src/message_list/widgets/message_status_mixin.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';
import '../../../common/language/gen/chat_localizations.dart';

class FileMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final VoidCallback? onLongPress;
  final MessageListStore? messageListStore;
  final GlobalKey? bubbleKey;
  final MessageListConfigProtocol config;
  final bool isInMergedDetailView;
  /// Optional override for bubble background color (used for highlight animation)
  final Color? bubbleColor;

  const FileMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onLongPress,
    this.messageListStore,
    this.bubbleKey,
    this.isInMergedDetailView = false,
    this.bubbleColor,
  });

  @override
  State<FileMessageWidget> createState() => _FileMessageWidgetState();
}

class _FileMessageWidgetState extends State<FileMessageWidget> with MessageStatusMixin {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
  }

  void _startDownload() {
    if (widget.messageListStore == null || widget.message.rawMessage == null) {
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    MessageActionStore.create(widget.message)
        .downloadMedia()
        .then((_) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
      debugPrint('downloadMessageResource failed: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    final statusAndTimeWidgets = buildStatusAndTimeWidgets(
      message: widget.message,
      isSelf: widget.isSelf,
      colors: colors,
      isShowTimeInBubble: widget.config.isShowTimeInBubble,
      enableReadReceipt: widget.config.enableReadReceipt,
      isInMergedDetailView: widget.isInMergedDetailView,
    );

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: Container(
        key: widget.bubbleKey,
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
        ),
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: _getBubbleColor(colors),
          borderRadius: _getBubbleBorderRadius(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: widget.isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildFileContent(colors),
            if (statusAndTimeWidgets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: statusAndTimeWidgets,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap() async {
    final String? filePath = (widget.message.messagePayload as FileMessagePayload?)?.filePath;
    final bool isFileAvailable = filePath != null && filePath.isNotEmpty && File(filePath).existsSync();

    if (!isFileAvailable && !_isDownloading) {
      _startDownload();
      return;
    }

    if (_isDownloading) {
      return;
    }

    if (Platform.isAndroid) {
      final int? sdkInt = await Device.sdkInt;
      if (sdkInt != null && sdkInt <= 32) {
        if (!mounted) return;
        final bool granted = await Permission.checkAndRequest(context, [PermissionType.storage]);
        if (!granted) return;
      }
    }

    if (isFileAvailable) {
      final bool success = await FilePicker.openFile(filePath);
      if (!success && mounted) {
        _showErrorDialog(context, 'Failed to open file');
      }
    }
  }


  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    ChatLocalizations chatLocal = ChatLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(chatLocal.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(chatLocal.confirm),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFileContent(SemanticColorScheme colorsTheme) {
    final String fileName = (widget.message.messagePayload as FileMessagePayload?)?.fileName ?? '';
    final int fileSize = (widget.message.messagePayload as FileMessagePayload?)?.fileSize ?? 0;
    final String? filePath = (widget.message.messagePayload as FileMessagePayload?)?.filePath;
    final String? fileExt = _getFileExtension(fileName);

    final bool isFileAvailable = filePath != null && filePath.isNotEmpty && File(filePath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: widget.isSelf
            ? colorsTheme.buttonColorPrimaryDefault.withOpacity(0.1)
            : colorsTheme.bgColorDefault.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getFileTypeColor(context, fileExt),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: _isDownloading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colorsTheme.textColorAntiPrimary),
                      ),
                    )
                  : !isFileAvailable
                      ? Icon(
                          Icons.download,
                          color: colorsTheme.textColorAntiPrimary,
                          size: 20,
                        )
                      : Text(
                          fileExt?.toUpperCase() ?? '?',
                          style: FontScheme.caption2Medium.copyWith(
                            color: colorsTheme.textColorAntiPrimary,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: FontScheme.caption2Medium.copyWith(
                    color: widget.isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _isDownloading
                      ? 'Downloading...'
                      : !isFileAvailable
                          ? 'Tap to download'
                          : _formatFileSize(fileSize),
                  style: FontScheme.caption3Regular.copyWith(
                    color: widget.isSelf ? colorsTheme.textColorAntiSecondary : colorsTheme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      double kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      double mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      double gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }

  String? _getFileExtension(String? fileName) {
    if (fileName == null || fileName.isEmpty || !fileName.contains('.')) {
      return null;
    }

    return fileName.split('.').last.toLowerCase();
  }

  Color _getFileTypeColor(BuildContext context, String? fileExt) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    return colorsTheme.buttonColorSecondaryHover;
  }

  Color _getBubbleColor(SemanticColorScheme colorsTheme) {
    if (widget.bubbleColor != null) return widget.bubbleColor!;
    if (widget.isSelf) {
      return colorsTheme.bgColorBubbleOwn;
    } else {
      return colorsTheme.bgColorBubbleReciprocal;
    }
  }

  BorderRadius _getBubbleBorderRadius() => MessageUtil.bubbleBorderRadius(
        alignment: widget.config.alignment,
        isSelf: widget.isSelf,
        radius: widget.config.textBubbleCornerRadius,
      );
}
