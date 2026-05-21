import 'package:flutter/material.dart';

import 'config/ai_minutes_config.dart';
import 'minutes/ai_minutes_widget.dart';
import 'repository/ai_transcriber_repository.dart';

/// Container page widget for AI minutes list.
class AIMinutesPageWidget extends StatelessWidget {
  final AITranscriberRepository repository;
  final AIMinutesConfig? config;

  const AIMinutesPageWidget({
    super.key,
    required this.repository,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AIMinutesWidget(
        repository: repository,
        config: config,
        onBackTap: () => Navigator.of(context).pop(),
      ),
    );
  }
}
