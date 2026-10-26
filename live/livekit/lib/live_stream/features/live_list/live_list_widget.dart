import 'package:atomic_x_core/api/live/live_list_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/component/float_window/global_float_window_manager.dart';
import 'package:tencent_live_uikit/live_stream/features/live_list/store/pause_resume_strategy.dart';
import 'package:tencent_live_uikit/live_stream/features/live_list/widget/double_column/double_column_list_widget.dart';
import 'package:tencent_live_uikit/live_stream/features/live_list/widget/single_column/single_column_list_widget.dart';

import '../../../common/logger/logger.dart';
import '../../../common/reporter/key_metrics.dart';
import '../../../live_identity_generator.dart';
import '../../../live_navigator_observer.dart';
import 'live_list_define.dart';
import 'store/live_info_list_store.dart';

class LiveListWidgetController {
  LiveListWidgetController({
    this.dataSource,
    LiveListViewStyle initialStyle = LiveListViewStyle.doubleColumn,
  }) : style = ValueNotifier(initialStyle);

  final LiveListDataSource? dataSource;
  final ValueListenable<LiveListViewStyle> style;

  void setColumnStyle(LiveListViewStyle newStyle) {
    (style as ValueNotifier).value = newStyle;
  }

  void dispose() {
    (style as ValueNotifier).dispose();
  }
}

class LiveListWidget extends StatefulWidget {
  final LiveListWidgetController? controller;

  const LiveListWidget({super.key, this.controller});

  @override
  State<StatefulWidget> createState() {
    return _LiveListWidgetState();
  }
}

class _LiveListWidgetState extends State<LiveListWidget> {
  late final LiveListWidgetController _controller;
  late final LiveInfoListStore _liveInfoListStore;
  final GlobalKey<SingleColumnListWidgetState> _singleColumnListKey = GlobalKey<SingleColumnListWidgetState>();
  final GlobalKey<DoubleColumnListWidgetState> _doubleColumnListKey = GlobalKey<DoubleColumnListWidgetState>();

  final bool _useOverlay = GlobalFloatWindowManager.instance.isEnableFloatWindowFeature();
  late final PauseResumeStrategy _pauseResumeStrategy;

  @override
  void initState() {
    super.initState();
    KeyMetrics.reportComponent(LiveComponentType.liveRoom);
    _controller = widget.controller ?? LiveListWidgetController();
    _liveInfoListStore = LiveInfoListStore(dataSource: _controller.dataSource);
    _liveInfoListStore.fetchLiveList(true);
    if (_useOverlay) {
      _pauseResumeStrategy = PauseResumeStrategyOnOverlay(onPause: _pausePreload, onResume: _resumePreload);
      _pauseResumeStrategy.start(context);
    } else {
      _pauseResumeStrategy = PauseResumeStrategyOnStandardRoute(onPause: _pausePreload, onResume: _resumePreload);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pauseResumeStrategy is PauseResumeStrategyOnStandardRoute) _pauseResumeStrategy.start(context);
  }

  @override
  void dispose() {
    _liveInfoListStore.dispose();
    _pauseResumeStrategy.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return ValueListenableBuilder<LiveListViewStyle>(
      valueListenable: _controller.style,
      builder: (context, style, _) {
        if (style == LiveListViewStyle.singleColumn) {
          return SingleColumnListWidget(
            key: _singleColumnListKey,
            liveInfoListStore: _liveInfoListStore,
            onItemClick: (liveInfo) {
              _onClickItem(liveInfo);
            },
          );
        } else {
          return DoubleColumnListWidget(
            key: _doubleColumnListKey,
            liveInfoListStore: _liveInfoListStore,
            onItemClick: (liveInfo) {
              _onClickItem(liveInfo);
            },
          );
        }
      },
    );
  }

  void _onClickItem(LiveInfo liveInfo) async {
    LiveKitLogger.info('onClickItem: liveID=${liveInfo.liveID}');
    final roomType = LiveIdentityGenerator.instance.getIDType(liveInfo.liveID);
    if (roomType == RoomType.voice) {
      await TUILiveKitNavigatorObserver.instance.enterVoiceRoomPage(context, liveInfo);
    } else {
      await TUILiveKitNavigatorObserver.instance.enterLiveRoomPage(context, liveInfo);
    }
  }

  void _pausePreload() {
    LiveKitLogger.info('LiveListWidget, pausePreload');
    _doubleColumnListKey.currentState?.pausePreload();
    _singleColumnListKey.currentState?.pausePreload();
  }

  void _resumePreload() {
    LiveKitLogger.info('LiveListWidget, resumePreload');
    _doubleColumnListKey.currentState?.resumePreload();
    _singleColumnListKey.currentState?.resumePreload();
  }
}
