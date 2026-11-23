import 'package:flutter/material.dart';
import '../../../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';
import 'source_dialog_shell.dart';
import '../../../../../common/widget/form_controls.dart';
import '../../../../../common/widget/form_file_picker.dart';
import '../../../../../common/widget/form_slider.dart';

Future<VideoFileSourceConfig?> showVideoFileSourceDialog(BuildContext context, {VideoFileSourceConfig? initial}) {
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
  State<_VideoFileSourceDialog> createState() => _VideoFileSourceDialogState();
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
        FormFieldLabel(strings.videoFileLabel),
        const SizedBox(height: 8),
        FormFilePickerRow(
          path: _path,
          placeholder: strings.videoPickPlaceholder,
          pickerLabel: strings.videoPickButton,
          extensions: kVideoFileExtensions,
          onPicked:
              (path) => setState(() {
                _path = path;
                _errorText = null;
              }),
        ),
        const SizedBox(height: 8),
        FormHintText(strings.videoFileFormatsHint),
        const SizedBox(height: 16),
        VolumeSliderGroup(volume: _volume, onChanged: (value) => setState(() => _volume = value)),
      ],
    );
  }

  void _confirm() {
    final path = _path;
    final error = validatePickedFile(path, kVideoFileExtensions, LiveKitLocalizations.of(context).sourceTypeVideoFile);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(context, VideoFileSourceConfig(path: path!, volume: _volume));
  }
}
