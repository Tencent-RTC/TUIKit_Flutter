import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_conference_uikit/base/index.dart';

import '../repository/ai_transcriber_repository.dart';
import 'ai_transcription_picker_widget.dart';

/// Setting row type.
enum AITranscriptionSettingRowType { alertSheet, toggle }

/// Setting row data model.
class AITranscriptionSettingRowData {
  final String title;
  String detail;
  final AITranscriptionSettingRowType type;
  bool isOn;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;

  AITranscriptionSettingRowData({
    required this.title,
    this.detail = '',
    required this.type,
    this.isOn = false,
    this.onTap,
    this.onToggle,
  });
}

/// AI subtitle settings widget with source language, translation language, and bilingual toggle.
class AITranscriptionSettingWidget extends StatefulWidget {
  final AITranscriberRepository repository;
  final VoidCallback? onBackTap;

  const AITranscriptionSettingWidget({
    super.key,
    required this.repository,
    this.onBackTap,
  });

  @override
  State<AITranscriptionSettingWidget> createState() => _AITranscriptionSettingWidgetState();
}

class _AITranscriptionSettingWidgetState extends State<AITranscriptionSettingWidget> {
  List<AITranscriptionSettingRowData> _rows = [];
  VoidCallback? _repositoryListener;
  VoidCallback? _roomListener;
  bool _isOwner = false;

  AITranscriberRepository get _repository => widget.repository;

  @override
  void initState() {
    super.initState();
    _repositoryListener = () {
      _refreshRows();
    };
    _repository.addListener(_repositoryListener!);
    _roomListener = () {
      _updateOwnerStatus();
    };
    RoomStore.shared.state.currentRoom.addListener(_roomListener!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateOwnerStatus();
    _buildRows();
  }

  @override
  void didUpdateWidget(covariant AITranscriptionSettingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_repositoryListener!);
      _repository.addListener(_repositoryListener!);
      _buildRows();
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_repositoryListener!);
    RoomStore.shared.state.currentRoom.removeListener(_roomListener!);
    super.dispose();
  }

  void _updateOwnerStatus() {
    final roomInfo = RoomStore.shared.state.currentRoom.value;
    final ownerID = roomInfo?.roomOwner.userID;
    final selfUserID = LoginStore.shared.loginState.loginUserInfo?.userID;
    final newIsOwner = ownerID != null && ownerID == selfUserID;
    if (newIsOwner != _isOwner) {
      _isOwner = newIsOwner;
      _buildRows();
    }
  }

  void _buildRows() {
    if (_isOwner) {
      _rows = [
        AITranscriptionSettingRowData(
          title: RoomLocalizations.of(context)!.roomkit_transcription_identify_language,
          detail: _repository.displayNameForSource(context, _repository.selectedSourceLanguage),
          type: AITranscriptionSettingRowType.alertSheet,
          onTap: () => _showSourceLanguagePicker(),
        ),
        AITranscriptionSettingRowData(
          title: RoomLocalizations.of(context)!.roomkit_transcription_translate_language,
          detail: _repository.displayNameForTranslation(context, _repository.selectedTranslationLanguage),
          type: AITranscriptionSettingRowType.alertSheet,
          onTap: () => _showTranslationLanguagePicker(),
        ),
        AITranscriptionSettingRowData(
          title: RoomLocalizations.of(context)!.roomkit_transcription_bilingual_subtitle,
          type: AITranscriptionSettingRowType.toggle,
          isOn: _repository.isBilingualEnabled,
          onToggle: (isOn) {
            _repository.isBilingualEnabled = isOn;
          },
        ),
      ];
    } else {
      _rows = [
        AITranscriptionSettingRowData(
          title: RoomLocalizations.of(context)!.roomkit_transcription_bilingual_subtitle,
          type: AITranscriptionSettingRowType.toggle,
          isOn: _repository.isBilingualEnabled,
          onToggle: (isOn) {
            _repository.isBilingualEnabled = isOn;
          },
        ),
      ];
    }
    if (mounted) setState(() {});
  }

  void _refreshRows() {
    setState(() {
      if (_isOwner && _rows.length >= 3) {
        _rows[0].detail = _repository.displayNameForSource(context, _repository.selectedSourceLanguage);
        _rows[1].detail = _repository.displayNameForTranslation(context, _repository.selectedTranslationLanguage);
        _rows[2].isOn = _repository.isBilingualEnabled;
      } else if (!_isOwner && _rows.isNotEmpty) {
        _rows[0].isOn = _repository.isBilingualEnabled;
      }
    });
  }

  void _showSourceLanguagePicker() {
    final items = _repository.sourceLanguageList.map((lang) {
      return AITranscriptionPickerItem(
        title: _repository.displayNameForSource(context, lang),
        isSelected: lang == _repository.selectedSourceLanguage,
      );
    }).toList();

    AITranscriptionPickerWidget.show(
      context: context,
      title: RoomLocalizations.of(context)!.roomkit_transcription_select_recognition_language,
      items: items,
      onSelect: (index, _) {
        final selectedLanguage = _repository.sourceLanguageList[index];
        _repository.updateSourceLanguage(selectedLanguage);
      },
    );
  }

  void _showTranslationLanguagePicker() {
    final items = _repository.translationLanguageList.map((lang) {
      return AITranscriptionPickerItem(
        title: _repository.displayNameForTranslation(context, lang),
        isSelected: lang == _repository.selectedTranslationLanguage,
      );
    }).toList();

    AITranscriptionPickerWidget.show(
      context: context,
      title: RoomLocalizations.of(context)!.roomkit_transcription_select_translation_language,
      items: items,
      onSelect: (index, _) {
        final selectedLanguage = _repository.translationLanguageList[index];
        _repository.updateTranslationLanguage(selectedLanguage);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RoomColors.settingBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                RoomLocalizations.of(context)!.roomkit_transcription_recognition_and_translation,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: RoomColors.secondaryLabel,
                ),
              ),
            ),
            _buildSettingsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: widget.onBackTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Image.asset(
                RoomImages.backArrow,
                package: RoomConstants.pluginName,
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              RoomLocalizations.of(context)!.roomkit_transcription_ai_subtitle_settings,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: RoomColors.g2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: RoomColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _rows.length; i++) ...[
              _SettingCellWidget(
                data: _rows[i],
                isLastRow: i == _rows.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingCellWidget extends StatelessWidget {
  final AITranscriptionSettingRowData data;
  final bool isLastRow;

  const _SettingCellWidget({required this.data, required this.isLastRow});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.type == AITranscriptionSettingRowType.alertSheet ? data.onTap : null,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: isLastRow
              ? null
              : Border(
                  bottom: BorderSide(
                    color: RoomColors.separator,
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                data.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: RoomColors.black,
                ),
              ),
            ),
            if (data.type == AITranscriptionSettingRowType.alertSheet) ...[
              Text(
                data.detail,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: RoomColors.aiRecordBorder,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset(
                RoomImages.aiRightArrow,
                package: RoomConstants.pluginName,
                width: 8,
                height: 14,
                color: RoomColors.buttonGrey,
              ),
            ],
            if (data.type == AITranscriptionSettingRowType.toggle)
              SizedBox(
                height: 24,
                width: 42,
                child: CupertinoSwitch(
                  value: data.isOn,
                  onChanged: data.onToggle,
                  activeTrackColor: RoomColors.b1,
                  inactiveTrackColor: RoomColors.g7,
                  inactiveThumbColor: RoomColors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
