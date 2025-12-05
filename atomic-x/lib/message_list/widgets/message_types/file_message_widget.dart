import 'dart:io';

import 'package:tuikit_atomic_x/base_component/base_component.dart' hide AlertDialog;
import 'package:tuikit_atomic_x/message_list/message_list_config.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:tuikit_atomic_x/permission/permission.dart';
import '../message_status_mixin.dart';

class FileMessageWidget extends StatefulWidget {
  final MessageInfo message;
  final bool isSelf;
  final double maxWidth;
  final VoidCallback? onLongPress;
  final MessageListStore? messageListStore;
  final GlobalKey? bubbleKey;
  final MessageListConfigProtocol config;

  const FileMessageWidget({
    super.key,
    required this.message,
    required this.isSelf,
    required this.maxWidth,
    required this.config,
    this.onLongPress,
    this.messageListStore,
    this.bubbleKey,
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

    widget.messageListStore!.downloadMessageResource(
      message: widget.message,
      resourceType: MessageMediaFileType.file,
    ).then((_) {
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

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: Container(
        key: widget.bubbleKey,
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth * 0.7,
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
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: buildStatusAndTimeWidgets(
                  message: widget.message,
                  isSelf: widget.isSelf,
                  colors: colors,
                  isShowTimeInBubble: widget.config.isShowTimeInBubble,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap() async {
    final String? filePath = widget.message.messageBody?.filePath;
    final bool isFileAvailable = filePath != null && filePath.isNotEmpty && File(filePath).existsSync();

    if (!isFileAvailable && !_isDownloading) {
      _startDownload();
      return;
    }

    if (_isDownloading) {
      return;
    }

    bool isGranted = false;
    if (Platform.isAndroid) {
      final DeviceInfoPlugin packageInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await packageInfo.androidInfo;
      if ((androidInfo.version.sdkInt) <= 32) {
        Map<PermissionType, PermissionStatus> statusMap =  await Permission.request([PermissionType.storage]);
        PermissionStatus status = statusMap[PermissionType.storage] ?? PermissionStatus.denied;
        if (status == PermissionStatus.granted) {
          isGranted = true;
        } else if (status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied) {
          if (mounted) {
            final bool shouldOpenSettings = await _showPermissionDialog(context);
            if (shouldOpenSettings) {
              await Permission.openAppSettings();
              return;
            }
          }
        }
      } else {
        isGranted = true;
      }
    } else {
      isGranted = true;
    }

    if (isGranted && isFileAvailable) {
      await OpenFile.open(filePath);
    }
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    AtomicLocalizations atomicLocal = AtomicLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(atomicLocal.permissionNeeded),
              content: Text(atomicLocal.permissionDeniedContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(atomicLocal.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(atomicLocal.confirm),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildFileContent(SemanticColorScheme colorsTheme) {
    final String fileName = widget.message.messageBody?.fileName ?? '';
    final int fileSize = widget.message.messageBody?.fileSize ?? 0;
    final String? filePath = widget.message.messageBody?.filePath;
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
                          style: TextStyle(
                            color: colorsTheme.textColorAntiPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
                  fileName!,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isSelf ? colorsTheme.textColorAntiPrimary : colorsTheme.textColorPrimary,
                    fontWeight: FontWeight.w500,
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
                  style: TextStyle(
                    fontSize: 12,
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
    if (widget.isSelf) {
      return colorsTheme.bgColorBubbleOwn;
    } else {
      return colorsTheme.bgColorBubbleReciprocal;
    }
  }

  BorderRadius _getBubbleBorderRadius() {
    if (widget.isSelf) {
      return const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(0),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(0),
        bottomRight: Radius.circular(18),
      );
    }
  }
}
