import 'package:flutter/material.dart';
import '../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import '../scene_store.dart';
import 'source_dialog.dart';

/// 添加 / 编辑图片画面源弹窗：选择本地图片文件。
///
/// 返回用户确认后的 [ImageSourceConfig]；取消返回 null。
/// [initial] 非空时为编辑模式（预填现有配置）。
Future<ImageSourceConfig?> showImageSourceDialog(
  BuildContext context, {
  ImageSourceConfig? initial,
}) {
  return showSourceConfigDialog<ImageSourceConfig>(
    context,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    child: _ImageSourceDialog(initial: initial),
  );
}

class _ImageSourceDialog extends StatefulWidget {
  const _ImageSourceDialog({this.initial});

  final ImageSourceConfig? initial;

  @override
  State<_ImageSourceDialog> createState() => _ImageSourceDialogState();
}

class _ImageSourceDialogState extends State<_ImageSourceDialog> {
  String? _path;
  String? _errorText;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _path = widget.initial?.path;
  }

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    return SourceDialogShell(
      icon: RemixIcons.image_line,
      title: _isEdit ? strings.imageEditTitle : strings.imageAddTitle,
      errorText: _errorText,
      confirmLabel: _isEdit ? strings.commonSave : strings.commonAdd,
      confirmEnabled: _path != null,
      onConfirm: _confirm,
      children: [
        SourceFieldLabel(strings.imageFileLabel),
        const SizedBox(height: 8),
        SourceFilePickerRow(
          path: _path,
          placeholder: strings.imagePickPlaceholder,
          pickerLabel: strings.imagePickButton,
          extensions: kImageFileExtensions,
          onPicked: (path) => setState(() {
            _path = path;
            _errorText = null;
          }),
        ),
        const SizedBox(height: 8),
        SourceHintText(strings.imageFormatsHint),
      ],
    );
  }

  void _confirm() {
    final path = _path;
    final error = validateSourceFile(
      path,
      kImageFileExtensions,
      LiveKitLocalizations.of(context).sourceTypeImage,
    );
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(context, ImageSourceConfig(path: path!));
  }
}
