// Copyright (c) 2026 Tencent. All rights reserved.
// Author: jackyixue

import 'package:atomic_x_core/impl/view/live/layer/local_preview_layer.dart';
import 'package:atomic_x_core/impl/view/live/live_core_controller_impl.dart';
import 'package:flutter/material.dart';

import 'package:atomic_x_core/api/view/live/live_core_widget.dart';
import 'package:atomic_x_core/impl/view/live/layer/index.dart';

class LiveStreamWidgetContainer extends StatefulWidget {
  final LiveCoreControllerImpl controller;
  final VideoWidgetBuilder? videoWidgetBuilder;

  const LiveStreamWidgetContainer({super.key, required this.controller, this.videoWidgetBuilder});

  @override
  State<LiveStreamWidgetContainer> createState() => _LiveStreamWidgetContainerState();
}

class _LiveStreamWidgetContainerState extends State<LiveStreamWidgetContainer> {
  @override
  Widget build(BuildContext context) {
    final LiveCoreControllerImpl controller = widget.controller;
    final bool hasLiveID = controller.getLiveID().isNotEmpty;
    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final screenHeight = constraints.maxHeight;
      final Size layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
      final widgetBuilder = widget.videoWidgetBuilder;
      return SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(children: [
          MixStreamLayer(controller: controller, layoutSize: layoutSize),
          if (hasLiveID) LocalPreviewLayer(controller: controller),
          if (hasLiveID) MultiStreamLayer(controller: controller, layoutSize: layoutSize),
          if (hasLiveID) BackgroundWidgetLayer(controller: controller, videoWidgetBuilder: widgetBuilder, layoutSize: layoutSize),
          if (hasLiveID) ForegroundWidgetLayer(controller: controller, videoWidgetBuilder: widgetBuilder, layoutSize: layoutSize),
          if (hasLiveID) FillScreenLayer(controller: controller, videoWidgetBuilder: widgetBuilder, layoutSize: layoutSize)
        ]),
      );
    });
  }
}
