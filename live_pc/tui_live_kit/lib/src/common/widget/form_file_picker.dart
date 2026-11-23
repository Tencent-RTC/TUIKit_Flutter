import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../style/live_kit_style.dart';
import 'hover_clickable.dart';
import '../../l10n/language_store.dart';
import '../../l10n/live_kit_localizations.dart';

String? validatePickedFile(String? path, Set<String> extensions, String label) {
  final strings = currentLiveKitStrings();
  if (path == null || path.isEmpty) {
    return strings.filePickRequired(label);
  }
  final dot = path.lastIndexOf('.');
  final ext = dot >= 0 ? path.substring(dot + 1).toLowerCase() : '';
  if (!extensions.contains(ext)) {
    return strings.fileFormatUnsupported(label, ext);
  }
  if (!File(path).existsSync()) {
    return strings.fileNotReadable;
  }
  return null;
}

class FormFilePickerRow extends StatelessWidget {
  const FormFilePickerRow({
    super.key,
    required this.path,
    required this.placeholder,
    required this.pickerLabel,
    required this.extensions,
    required this.onPicked,
  });

  final String? path;
  final String placeholder;
  final String pickerLabel;
  final Set<String> extensions;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 4, right: 10),
      decoration: LiveKitStyle.softPanel(),
      child: Row(
        children: [
          HoverClickable(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: LiveKitStyle.softPanel(radius: 6),
              child: Text(pickerLabel, style: const TextStyle(fontSize: 12, color: LiveKitStyle.textPrimary)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path ?? placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: path == null ? LiveKitStyle.textTertiary : LiveKitStyle.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick() async {
    final file = await openFile(acceptedTypeGroups: [XTypeGroup(label: pickerLabel, extensions: extensions.toList())]);
    if (file != null) {
      onPicked(file.path);
    }
  }
}
