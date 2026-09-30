// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

part of 'package:atomic_x_core/api/view/live/live_core_widget.dart';

class _LiveCoreWidgetState extends State<LiveCoreWidget> {
  late final LiveCoreControllerImpl controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller as LiveCoreControllerImpl;
    controller.init();
    final currentLive = LiveListStore.shared.liveState.currentLive;
    if (currentLive.value.liveID.isEmpty) return;
    if (currentLive is TriggerableValueNotifier) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) (currentLive as TriggerableValueNotifier).notify();
      });
    }
  }

  @override
  void dispose() {
    controller.unInit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AtomicPlatform.isDesktop) {
      return const MediaMixingCanvas();
    }
    return SizedBox(
      child: Stack(children: [
        LiveStreamWidgetContainer(controller: controller, videoWidgetBuilder: widget.videoWidgetBuilder),
      ]),
    );
  }
}
