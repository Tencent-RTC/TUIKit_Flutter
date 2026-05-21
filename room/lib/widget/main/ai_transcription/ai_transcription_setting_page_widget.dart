import 'package:flutter/material.dart';

import 'repository/ai_transcriber_repository.dart';
import 'setting/ai_transcription_setting_widget.dart';

/// Container page widget for AI transcription settings.
class AITranscriptionSettingPageWidget extends StatelessWidget {
  final AITranscriberRepository repository;

  const AITranscriptionSettingPageWidget({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AITranscriptionSettingWidget(
        repository: repository,
        onBackTap: () => Navigator.of(context).pop(),
      ),
    );
  }
}
