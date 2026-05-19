
import 'package:flutter/material.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';
import '../utils/index.dart';
import 'call_settings_widget.dart';

class CallMainWidget extends StatefulWidget {
  const CallMainWidget({Key? key}) : super(key: key);

  @override
  State<CallMainWidget> createState() => _CallMainWidgetState();
}

class _CallMainWidgetState extends State<CallMainWidget> {
  String _groupId = '';
  String _userIDsStr = '';
  List<String> _userIDs = [];
  bool _isAudioCall = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(l10n.app_call),
        leading: IconButton(
          onPressed: () => _goBack(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
      ),
      body: Stack(
        children: [
          _getCallParamsWidget(),
          _getBtnWidget(),
        ],
      ),
    );
  }

  Widget _getCallParamsWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildUserIdRow(l10n),
                _buildDivider(),
                _buildMediaTypeRow(l10n),
                _buildDivider(),
                _buildOptionalParams(l10n),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsEntry(l10n),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }

  Widget _buildUserIdRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.app_call_user_ids,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
          SizedBox(
            width: 200,
            child: TextField(
              autofocus: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: l10n.app_call_user_ids_separated,
                border: InputBorder.none,
              ),
              onChanged: ((value) => _userIDsStr = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.app_call_media_type,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
          Row(
            children: [
              _buildRadio(
                label: l10n.app_call_media_type_video,
                selected: !_isAudioCall,
                onTap: () {
                  setState(() {
                    _isAudioCall = false;
                  });
                },
              ),
              const SizedBox(width: 16),
              _buildRadio(
                label: l10n.app_call_media_type_audio,
                selected: _isAudioCall,
                onTap: () {
                  setState(() {
                    _isAudioCall = true;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadio({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? const Color(0xff056DF6) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalParams(AppLocalizations l10n) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          l10n.app_call_optional_params,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.app_call_group_id,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: _groupId.isNotEmpty
                          ? _groupId
                          : l10n.app_call_group_id,
                      border: InputBorder.none,
                    ),
                    onChanged: ((value) => _groupId = value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsEntry(AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CallSettingsWidget(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.app_call_settings,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBtnWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      left: 0,
      bottom: 50,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 52,
            width: MediaQuery.of(context).size.width * 5 / 6,
            child: ElevatedButton(
              onPressed: () => _call(),
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(const Color(0xff056DF6)),
                shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.call),
                  const SizedBox(width: 10),
                  Text(
                    l10n.app_call_initiate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _goBack() {
    Navigator.of(context).pop();
  }

  _call() {
    _userIDs = _userIDsStr.split(',').where((id) => id.trim().isNotEmpty).toList();
    if (_userIDs.isEmpty) {
      return;
    }
    TUICallKit.instance
        .calls(_userIDs, _isAudioCall ? CallMediaType.audio : CallMediaType.video)
        .then((handler) {
      if (!handler.isSuccess) {
        final errorMessage = _getCallErrorMessage(handler.errorCode);
        if (errorMessage != null) {
          TUIToast.show(content: errorMessage);
        }
      }
    });
  }

  String? _getCallErrorMessage(int? errorCode) {
    if (errorCode == null) return null;
    switch (errorCode) {
      case -1202:
        return AppLocalizations.of(context)!.app_call_error_call_self;
      case 6017:
        return AppLocalizations.of(context)!.app_call_error_user_not_exist;
      default:
        return null;
    }
  }
}
