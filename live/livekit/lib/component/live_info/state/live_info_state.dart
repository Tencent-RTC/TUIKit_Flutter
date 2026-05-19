import 'package:flutter/material.dart';

class LiveInfoState {
  String selfUserId = '';
  String roomId = '';
  final ValueNotifier<String> ownerId = ValueNotifier('');
  final ValueNotifier<String> ownerName = ValueNotifier('');
  final ValueNotifier<String> ownerAvatarUrl = ValueNotifier('');
  final ValueNotifier<int> fansNumber = ValueNotifier(0);
  final ValueNotifier<Set<String>> followingList = ValueNotifier({});

  void dispose() {

  }
}
