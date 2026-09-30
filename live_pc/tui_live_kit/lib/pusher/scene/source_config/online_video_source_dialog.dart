import 'package:flutter/material.dart';
import '../../../l10n/live_kit_localizations.dart';
import 'package:remixicon/remixicon.dart';

import '../scene_store.dart';
import 'source_dialog.dart';

/// 添加 / 编辑在线视频画面源弹窗：视频地址 + 播放音量 + 网络缓存。
///
/// 返回用户确认后的 [OnlineVideoSourceConfig]；取消返回 null。
/// [initial] 非空时为编辑模式（预填现有配置）。
Future<OnlineVideoSourceConfig?> showOnlineVideoSourceDialog(
  BuildContext context, {
  OnlineVideoSourceConfig? initial,
}) {
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
  State<_OnlineVideoSourceDialog> createState() =>
      _OnlineVideoSourceDialogState();
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
    _cacheKB = widget.initial?.networkCacheSizeKB ?? 1024;
    // 地址输入变化时刷新确认按钮禁用态。
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
      errorText: _errorText,
      confirmLabel: _isEdit ? strings.commonSave : strings.commonAdd,
      confirmEnabled: _urlController.text.trim().isNotEmpty,
      onConfirm: _confirm,
      children: [
        SourceFieldLabel(strings.onlineVideoUrlLabel),
        const SizedBox(height: 8),
        SourceDarkTextField(
          controller: _urlController,
          hint: strings.onlineVideoUrlHint,
        ),
        const SizedBox(height: 8),
        SourceHintText(strings.onlineVideoProtocolHint),
        const SizedBox(height: 16),
        VolumeSliderGroup(
          volume: _volume,
          onChanged: (value) => setState(() => _volume = value),
        ),
        const SizedBox(height: 16),
        _CacheSliderGroup(
          cacheKB: _cacheKB,
          onChanged: (value) => setState(() => _cacheKB = value),
        ),
      ],
    );
  }

  void _confirm() {
    final url = _urlController.text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      setState(() => _errorText = LiveKitLocalizations.of(context).onlineVideoUrlInvalid);
      return;
    }
    Navigator.pop(
      context,
      OnlineVideoSourceConfig(
        url: url,
        volume: _volume,
        networkCacheSizeKB: _cacheKB,
      ),
    );
  }
}

/// 网络缓存滑杆组（整兆档位：0 = 自动，1 ~ 10 M），下方带量程刻度。
class _CacheSliderGroup extends StatelessWidget {
  const _CacheSliderGroup({required this.cacheKB, required this.onChanged});

  /// 当前缓存（KB 为单位，须为 1024 的整数倍或 0）。
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
          display: cacheMB == 0 ? LiveKitLocalizations.of(context).onlineVideoCacheAuto : '$cacheMB M',
          onChanged: (value) => onChanged(value.round() * 1024),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SourceHintText(LiveKitLocalizations.of(context).onlineVideoCacheAutoScale),
            const SourceHintText('10 M'),
          ],
        ),
      ],
    );
  }
}
