import 'package:flutter/material.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' hide CompletionHandler;
// Direct src import: SwipeActionCell is the ChatKit swipe component (same as the
// conversation list). It can't be re-exported from the barrel because its
// `CompletionHandler` clashes with the one from atomic_x_core.
// ignore: implementation_imports
import 'package:tencent_chat_uikit/src/third_party/flutter_swipe_action_cell/core/cell.dart';

/// Voice selection page: pick the TTS voice used by read-aloud and
/// listen-from-here. Default voices + cloned custom voices (swipe to delete).
class VoiceSelectPage extends StatefulWidget {
  const VoiceSelectPage({super.key});

  @override
  State<VoiceSelectPage> createState() => _VoiceSelectPageState();
}

class _VoiceSelectPageState extends State<VoiceSelectPage> {
  List<CustomVoiceItem> _customVoices = [];
  bool _loading = true;
  String _selectedId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await VoiceMessageConfig.instance.load();
    final result = await AiMediaProcessManager.shared.getCustomVoiceList();
    if (!mounted) return;
    setState(() {
      _selectedId = VoiceMessageConfig.instance.selectedVoiceId;
      _customVoices = result.success ? result.voices : [];
      _loading = false;
    });
  }

  Future<void> _select(CustomVoiceItem item) async {
    await VoiceMessageConfig.instance
        .setSelectedVoice(voiceId: item.voiceId, name: item.name);
    if (mounted) setState(() => _selectedId = item.voiceId);
  }

  Future<bool> _delete(CustomVoiceItem item) async {
    final chatLocale = ChatLocalizations.of(context);
    final ok =
        await AiMediaProcessManager.shared.deleteCustomVoice(voiceId: item.voiceId);
    if (!mounted) return ok;
    if (ok) {
      setState(() => _customVoices.removeWhere((e) => e.voiceId == item.voiceId));
      // Deleting the currently selected voice falls back to the default.
      if (_selectedId == item.voiceId) {
        await VoiceMessageConfig.instance
            .setSelectedVoice(voiceId: '', name: '');
        if (mounted) setState(() => _selectedId = '');
      }
    } else {
      Toast.error(context, chatLocale.voiceDeleteFailed);
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final chatLocale = ChatLocalizations.of(context);
    final defaults = defaultVoiceList(chatLocale);

    return Scaffold(
      backgroundColor: colors.bgColorOperate,
      appBar: SettingWidgets.buildAppBar(
        context: context,
        title: chatLocale.voiceSelect,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionHeader(colors, chatLocale.voiceSelectDefaultGroup),
                ...defaults.map((v) => _voiceRow(colors, v)),
                // Always show the custom section header (even when empty).
                _sectionHeader(colors, chatLocale.voiceSelectCustomGroup),
                if (_customVoices.isEmpty)
                  _emptyCustomRow(colors, chatLocale.voiceSelectEmptyCustom)
                else
                  ..._customVoices.map(
                    (v) => SwipeActionCell(
                      key: ValueKey(v.voiceId),
                      backgroundColor: colors.clearColor,
                      trailingActions: [
                        SwipeAction(
                          title: chatLocale.voiceDelete,
                          color: colors.textColorError,
                          style: FontScheme.caption3Regular.copyWith(
                            color: colors.textColorButton,
                          ),
                          onTap: (handler) async {
                            final ok = await _delete(v);
                            await handler(ok);
                          },
                        ),
                      ],
                      child: _voiceRow(colors, v, custom: true),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _emptyCustomRow(SemanticColorScheme colors, String text) {
    return Container(
      color: colors.bgColorOperate,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      alignment: Alignment.center,
      child: Text(
        text,
        style: FontScheme.caption2Regular.copyWith(
          color: colors.textColorTertiary,
        ),
      ),
    );
  }

  Widget _sectionHeader(SemanticColorScheme colors, String title) {
    return Container(
      width: double.infinity,
      color: colors.bgColorDefault,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: FontScheme.caption2Regular.copyWith(
          color: colors.textColorSecondary,
        ),
      ),
    );
  }

  Widget _voiceRow(SemanticColorScheme colors, CustomVoiceItem item,
      {bool custom = false}) {
    final selected = item.voiceId == _selectedId;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _select(item),
      child: Container(
        color: colors.bgColorOperate,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (!custom)
              Expanded(
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: FontScheme.caption1Regular.copyWith(
                    color: colors.textColorPrimary,
                  ),
                ),
              )
            else ...[
              Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: FontScheme.caption1Regular.copyWith(
                  color: colors.textColorPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.buttonColorPrimaryDefault,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ChatLocalizations.of(context).voiceCustomBadge,
                  style: FontScheme.caption4Regular.copyWith(
                    color: colors.textColorButton,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // The voiceId uses all remaining space (including the area before
              // the check mark) with the smallest font, to show as much as
              // possible.
              Expanded(
                child: Text(
                  item.voiceId,
                  overflow: TextOverflow.ellipsis,
                  style: FontScheme.caption4Regular.copyWith(
                    color: colors.textColorTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (selected)
              Icon(Icons.check, color: colors.textColorLink, size: 20),
          ],
        ),
      ),
    );
  }
}
