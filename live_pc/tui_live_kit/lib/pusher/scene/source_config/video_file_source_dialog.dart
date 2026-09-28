import 'package:flutter/material.dart';
import '../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import '../scene_store.dart';
import 'source_dialog.dart';

/// 添加 / 编辑本地视频画面源弹窗：选择本地视频文件 + 播放音量。
///
/// 返回用户确认后的 [VideoFileSourceConfig]；取消返回 null。
/// [initial] 非空时为编辑模式（预填现有配置）。
Future<VideoFileSourceConfig?> showVideoFileSourceDialog(
  BuildContext context, {
  VideoFileSourceConfig? initial,
}) {
  return showSourceConfigDialog<VideoFileSourceConfig>(
    context,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    child: _VideoFileSourceDialog(initial: initial),
  );
}

class _VideoFileSourceDialog extends StatefulWidget {
  const _VideoFileSourceDialog({this.initial});

  final VideoFileSourceConfig? initial;

  @override
  State<_VideoFileSourceDialog> createState() =>
      _VideoFileSourceDialogState();
}

class _VideoFileSourceDialogState extends State<_VideoFileSourceDialog> {
  String? _path;
  late int _volume;
  String? _errorText;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _path = widget.initial?.path;
    _volume = widget.initial?.volume ?? 100;
  }

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    return SourceDialogShell(
      icon: RemixIcons.file_video_line,
      title: _isEdit ? strings.videoFileEditTitle : strings.videoFileAddTitle,
      errorText: _errorText,
      confirmLabel: _isEdit ? strings.commonSave : strings.commonAdd,
      confirmEnabled: _path != null,
      onConfirm: _confirm,
      children: [
        SourceFieldLabel(strings.videoFileLabel),
        const SizedBox(height: 8),
        SourceFilePickerRow(
          path: _path,
          placeholder: strings.videoPickPlaceholder,
          pickerLabel: strings.videoPickButton,
          extensions: kVideoFileExtensions,
          onPicked: (path) => setState(() {
            _path = path;
            _errorText = null;
          }),
        ),
        const SizedBox(height: 8),
        SourceHintText(strings.videoFileFormatsHint),
        const SizedBox(height: 16),
        VolumeSliderGroup(
          volume: _volume,
          onChanged: (value) => setState(() => _volume = value),
        ),
      ],
    );
  }

  void _confirm() {
    final path = _path;
    final error = validateSourceFile(
      path,
      kVideoFileExtensions,
      LiveKitLocalizations.of(context).sourceTypeVideoFile,
    );
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(
      context,
      VideoFileSourceConfig(path: path!, volume: _volume),
    );
  }
}
