import 'dart:async';
import 'dart:convert';
import 'package:atomic_x_core/impl/common/log.dart';
import 'package:flutter/material.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_rtc_sdk/bindings/trtc_cloud_struct.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';
import 'package:tuikit_atomic_x/call/common/utils/logger.dart';

class AISubtitle extends StatefulWidget {
  final String userId;

  const AISubtitle({
    super.key,
    required this.userId,
  });

  @override
  State<AISubtitle> createState() => _AISubtitleState();
}

class _AISubtitleState extends State<AISubtitle> {
  final List<TranslationInfo> _translationInfos = [];
  Timer? _hideTimer;
  bool _isVisible = false;
  final int _showDuration = 8;
  final ScrollController _scrollController = ScrollController();
  
  static const List<String> _languageOrder = [
    "zh", "en", "es", "pt", "fr", "de", "ru", "ar", 
    "ja", "ko", "vi", "ms", "id", "it", "th"
  ];
  
  late var trtcCloudListener = TRTCCloudListener(
    onRecvCustomCmdMsg: (userId, cmdId, seq, message) {
      if (userId.isEmpty || message.isEmpty) {
        return;
      }
      
      try {
        Map messageMap = jsonDecode(message);
        if (messageMap['type'] == AI_MESSAGE_TYPE) {
          String sender = messageMap['sender'];
          Map payload = messageMap['payload'];
          String text = payload['text'];
          String? translationText = payload['translation_text'];
          String roundId = payload['roundid'] ?? '';
          String translationLanguage = payload['translation_language'] ?? '';

          if (roundId.isNotEmpty) {
            _updateTranslationInfo(roundId, sender, text, translationLanguage, translationText);
          }
        }
      } catch(e) {
        Log.getCommonLog("CallAISubtitle").error("Parse custom message failed: ${e.toString()}");
      }
    },
  );

  void _updateTranslationInfo(String roundId, String sender, String text, String translationLanguage, String? translationText) {
    final index = _translationInfos.indexWhere((info) => info.roundId == roundId);
    
    if (index != -1) {
      final existingInfo = _translationInfos[index];
      existingInfo.sender = sender.contains(AI_TRANSLATION_ROBOT) ? existingInfo.sender : sender;
      existingInfo.text = text.isEmpty ? existingInfo.text : text;
      if (translationLanguage.isNotEmpty && translationText != null && translationText.isNotEmpty) {
        existingInfo.translation[translationLanguage] = translationText;
      }
    } else {
      final translationInfo = TranslationInfo(
        roundId: roundId,
        sender: sender.contains(AI_TRANSLATION_ROBOT) ? '' : sender,
        text: text,
        translation: {},
      );
      if (translationLanguage.isNotEmpty && translationText != null && translationText.isNotEmpty) {
        translationInfo.translation[translationLanguage] = translationText;
      }
      _translationInfos.add(translationInfo);
    }
    
    _updateView();
  }

  void _updateView() {
    setState(() {
      _isVisible = true;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: _showDuration), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  String _sortLanguageType(TranslationInfo message) {
    final translationText = StringBuffer();
    
    for (final language in _languageOrder) {
      if (message.translation.containsKey(language)) {
        translationText.write("[$language]: ${message.translation[language]}\n");
      }
    }
    
    return translationText.toString();
  }

  @override
  void initState() {
    super.initState();
    _startMessageListener();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scrollController.dispose();
    _stopMessageListener();
    super.dispose();
  }

  void _startMessageListener() {
    TRTCCloud.sharedInstance().then((trtcCloud) {
      trtcCloud.registerListener(trtcCloudListener);
    });
  }

  void _stopMessageListener() {
    TRTCCloud.sharedInstance().then((trtcCloud) {
      trtcCloud.unRegisterListener(trtcCloudListener);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _isVisible,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Material(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _translationInfos.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _translationInfos.length,
                    itemBuilder: (context, index) {
                      final info = _translationInfos[index];
                      return FutureBuilder<String?>(
                        future: _getUserDisplayName(info.sender),
                        builder: (context, snapshot) {
                          final displayName = snapshot.data ?? info.sender;
                          final translationText = _sortLanguageType(info);
                          
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _translationInfos.length - 1 ? 0 : 8,
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$displayName:',
                                    style: const TextStyle(
                                      color: Color(0xFFD9CC66),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '\n${info.text}\n$translationText',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<String?> _getUserDisplayName(String userId) async {
    try {
      final allParticipants = CallStore.shared.state.allParticipants.value;
      for (final participant in allParticipants) {
        if (participant.id == userId) {
          return _getDisplayName(participant);
        }
      }
      return userId;
    } catch (e) {
      Log.getCommonLog("CallAISubtitle").error('get user name failed: $e');
      return userId;
    }
  }

  String _getDisplayName(CallParticipantInfo info) {
    if (info.remark.isNotEmpty) {
      return info.remark;
    } else if (info.name.isNotEmpty) {
      return info.name;
    } else {
      return info.id;
    }
  }
}

class TranslationInfo {
  String roundId;
  String sender;
  String text;
  Map<String, String> translation;

  TranslationInfo({
    required this.roundId,
    required this.sender,
    required this.text,
    required this.translation,
  });
}

const int AI_MESSAGE_TYPE = 10000;
const String AI_TRANSLATION_ROBOT = "TAI_Robot";