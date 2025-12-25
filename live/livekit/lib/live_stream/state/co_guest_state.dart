import 'package:flutter/cupertino.dart';

class LSCoGuestState {
  final ValueNotifier<Set<String>> lockAudioUserList = ValueNotifier({});
  final ValueNotifier<Set<String>> lockVideoUserList = ValueNotifier({});
  final ValueNotifier<CoGuestStatus> coGuestStatus = ValueNotifier(CoGuestStatus.none);
  final ValueNotifier<bool> openCameraAfterTakeSeat = ValueNotifier(false);
}

enum CoGuestStatus { none, applying, linking }
