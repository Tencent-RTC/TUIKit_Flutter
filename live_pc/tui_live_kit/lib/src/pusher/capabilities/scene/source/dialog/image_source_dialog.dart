import 'package:flutter/material.dart';
import '../../../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';
import 'source_dialog_shell.dart';
import '../../../../../common/widget/form_controls.dart';
import '../../../../../common/widget/form_file_picker.dart';

Future<ImageSourceConfig?> showImageSourceDialog(BuildContext context, {ImageSourceConfig? initial}) {
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
    final imageFileExtensions = imageFileExtensionsForCurrentPlatform();
    return SourceDialogShell(
      icon: RemixIcons.image_line,
      title: _isEdit ? strings.imageEditTitle : strings.imageAddTitle,
      errorText: _errorText,
      confirmLabel: _isEdit ? strings.commonSave : strings.commonAdd,
      confirmEnabled: _path != null,
      onConfirm: _confirm,
      children: [
        FormFieldLabel(strings.imageFileLabel),
        const SizedBox(height: 8),
        FormFilePickerRow(
          path: _path,
          placeholder: strings.imagePickPlaceholder,
          pickerLabel: strings.imagePickButton,
          extensions: imageFileExtensions,
          onPicked:
              (path) => setState(() {
                _path = path;
                _errorText = null;
              }),
        ),
        const SizedBox(height: 8),
        FormHintText(
          isGifImageSupportedOnCurrentPlatform() ? strings.imageFormatsHint : strings.imageFormatsHintNoGif,
        ),
      ],
    );
  }

  void _confirm() {
    final path = _path;
    final error = validatePickedFile(
      path,
      imageFileExtensionsForCurrentPlatform(),
      LiveKitLocalizations.of(context).sourceTypeImage,
    );
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(context, ImageSourceConfig(path: path!));
  }
}
