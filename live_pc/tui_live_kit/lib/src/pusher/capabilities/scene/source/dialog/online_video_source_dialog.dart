import 'package:flutter/material.dart';
import '../../../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../common/style/live_kit_style.dart';
import 'package:atomic_x_core_media_mixing/api/scene/scene_models.dart';
import 'source_dialog_shell.dart';
import '../../../../../common/widget/form_controls.dart';
import '../../../../../common/widget/form_slider.dart';

Future<OnlineVideoSourceConfig?> showOnlineVideoSourceDialog(BuildContext context, {OnlineVideoSourceConfig? initial}) {
  return showSourceConfigDialog<OnlineVideoSourceConfig>(
    context,
    barrierLabel: LiveKitLocalizations.of(context).commonClose,
    child: _OnlineVideoSourceDialog(initial: initial),
  );
}

class _OnlineVideoSourceDialog extends StatefulWidget {
  const _OnlineVideoSourceDialog({this.initial});

  final OnlineVideoSourceConfig? initial;

  @override
  State<_OnlineVideoSourceDialog> createState() => _OnlineVideoSourceDialogState();
}

class _OnlineVideoSourceDialogState extends State<_OnlineVideoSourceDialog> {
  late final TextEditingController _urlController;
  late int _volume;
  late int _cacheKB;
  String? _errorText;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initial?.url ?? '');
    _volume = widget.initial?.volume ?? 100;
    _cacheKB = widget.initial?.networkCacheSizeKB ?? 2048;
    _urlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LiveKitLocalizations.of(context);
    return SourceDialogShell(
      icon: RemixIcons.global_line,
      title: _isEdit ? strings.onlineVideoEditTitle : strings.onlineVideoAddTitle,
      width: 600,
      confirmLabel: _isEdit ? strings.commonSave : strings.commonAdd,
      confirmEnabled: _urlController.text.trim().isNotEmpty,
      onConfirm: _confirm,
      children: [
        FormFieldLabel(strings.onlineVideoUrlLabel),
        const SizedBox(height: 8),
        FormTextField(controller: _urlController, hint: strings.onlineVideoUrlHint),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(fontSize: 12, color: LiveKitStyle.danger)),
        ],
        const SizedBox(height: 16),
        VolumeSliderGroup(volume: _volume, onChanged: (value) => setState(() => _volume = value)),
        const SizedBox(height: 16),
        _CacheSliderGroup(cacheKB: _cacheKB, onChanged: (value) => setState(() => _cacheKB = value)),
      ],
    );
  }

  void _confirm() {
    final url = _urlController.text.trim();
    if (!_isValidStreamUrl(url)) {
      setState(() => _errorText = LiveKitLocalizations.of(context).onlineVideoUrlInvalid);
      return;
    }
    Navigator.pop(context, OnlineVideoSourceConfig(url: url, volume: _volume, networkCacheSizeKB: _cacheKB));
  }

  bool _isValidStreamUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'rtmp') {
      return true;
    }
    if (scheme != 'http' && scheme != 'https') {
      return false;
    }
    final path = uri.path.toLowerCase();
    return kOnlineVideoUrlExtensions.any(path.endsWith);
  }
}

class _CacheSliderGroup extends StatelessWidget {
  const _CacheSliderGroup({required this.cacheKB, required this.onChanged});

  /// Current cache in KB (must be a multiple of 1024, or 0).
  final int cacheKB;
  final ValueChanged<int> onChanged;

  static const int _maxCacheMB = 10;

  @override
  Widget build(BuildContext context) {
    final cacheMB = cacheKB ~/ 1024;
    return Column(
      children: [
        LabeledSliderGroup(
          label: LiveKitLocalizations.of(context).onlineVideoCacheLabel,
          value: cacheMB.toDouble(),
          max: _maxCacheMB.toDouble(),
          divisions: _maxCacheMB,
          display: '$cacheMB M',
          onChanged: (value) => onChanged(value.round() * 1024),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [FormHintText('0'), FormHintText('10 M')],
        ),
      ],
    );
  }
}
