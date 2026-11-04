/// 直播状态抽屉：实时数据与设备状态两个页签。
library;

import '../live_header_view.dart' show LiveHeaderView;

import '../../../common/theme/live_theme.dart';
import '../../settings/pusher_settings_action_handling.dart';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../common/live_kit_resources.dart';
import '../../../common/platform/live_network_type_channel.dart';
import '../../../common/platform/live_thermal_state_channel.dart';
import '../../../common/theme/bottom_sheet_view.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import '../../../common/theme/live_slider.dart';

part 'pusher_live_statistics_view.dart';
part 'pusher_device_status_view.dart';

enum _LiveStatusPage { metrics, device }

class PusherLiveStatusView extends StatefulWidget {
  const PusherLiveStatusView({
    super.key,
    required this.elapsedSeconds,
    required this.viewerCount,
    required this.likeCount,
    required this.liveID,
    this.summaryStore,
    required this.settings,
    required this.deviceStatus,
    this.onSetCaptureVolume,
    required this.onDismiss,
  });

  final int elapsedSeconds;
  final int viewerCount;
  final int likeCount;
  final String liveID;
  final LiveSummaryStore? summaryStore;
  final PusherSettingsState settings;
  final PusherDeviceStatusState deviceStatus;

  final void Function(int volume)? onSetCaptureVolume;

  /// 抽屉关闭。
  final VoidCallback onDismiss;

  static String formatDuration(int seconds) => LiveHeaderView.formatDuration(seconds);

  @override
  State<PusherLiveStatusView> createState() => _PusherLiveStatusViewState();
}

class _PusherLiveStatusViewState extends State<PusherLiveStatusView> {
  static const double _sheetHeight = 656;

  /// 抽屉高度 656 减去顶部 141 的标题与页签区。
  static const double _contentHeight = _sheetHeight - 141;

  /// 656 是首选高度；短屏收缩到顶部安全区以下的可用高度，抽屉内容随之滚动。
  static double _resolvedSheetHeight(BuildContext context, double height) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double available = height - mediaQuery.padding.top;
    return available < _sheetHeight ? math.max(0, available) : _sheetHeight;
  }

  _LiveStatusPage _page = _LiveStatusPage.metrics;
  late final LiveSummaryStore _summaryStore;
  LiveSummaryData _summary = LiveSummaryData();
  bool _observing = false;
  Widget? _duration;
  Widget? _title;
  Widget? _tabs;
  Widget? _content;
  late Widget _metrics;
  late Widget _device;
  (int, int, int, int, int, int)? _metricValues;
  (bool, int)? _deviceSettings;
  PusherDeviceStatusState? _renderedDeviceStatus;
  bool? _captureVolumeEnabled;

  void _refreshMetrics() {
    final summary = _summary;
    final values = (
      math.max(0, summary.totalGiftCoins),
      math.max(0, summary.totalGiftUniqueSenders),
      math.max(0, summary.totalGiftsSent),
      math.max(0, widget.viewerCount),
      math.max(0, widget.likeCount),
      math.max(0, summary.totalMessageSent),
    );
    if (_metricValues == values) return;
    _metricValues = values;
    _metrics = PusherLiveStatisticsView(values: [
      values.$1,
      values.$2,
      values.$3,
      values.$4,
      values.$5,
      values.$6,
    ]);
    if (_page == _LiveStatusPage.metrics) _content = null;
  }

  void _refreshDevice() {
    final settings = (
      widget.settings.isMuted,
      widget.settings.captureVolume,
    );
    final captureVolumeEnabled = widget.onSetCaptureVolume != null;
    if (_deviceSettings == settings &&
        _captureVolumeEnabled == captureVolumeEnabled &&
        _renderedDeviceStatus?.isSameAs(widget.deviceStatus) == true) {
      return;
    }
    _deviceSettings = settings;
    _captureVolumeEnabled = captureVolumeEnabled;
    // 输入可原位改变；保存独立快照，不能与上一 Widget 的对象身份比较。
    final status = widget.deviceStatus.copy();
    _renderedDeviceStatus = status;
    _device = PusherDeviceStatusView(
      isMuted: settings.$1,
      captureVolume: settings.$2,
      status: status,
      onSetCaptureVolume: captureVolumeEnabled ? (volume) => widget.onSetCaptureVolume?.call(volume) : null,
    );
    if (_page == _LiveStatusPage.device) _content = null;
  }

  void _selectPage(_LiveStatusPage page) {
    if (_page == page) return;
    setState(() {
      _page = page;
      _tabs = null;
      _content = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _summaryStore = widget.summaryStore ?? LiveSummaryStore.create(widget.liveID);
    _summary = _summaryStore.liveSummaryState.summaryData.value;
    _observing = true;
    _summaryStore.liveSummaryState.summaryData.addListener(_onSummaryChanged);
    _refreshMetrics();
    _refreshDevice();
  }

  @override
  void didUpdateWidget(PusherLiveStatusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elapsedSeconds != widget.elapsedSeconds) _duration = null;
    _refreshDevice();
    if (oldWidget.viewerCount != widget.viewerCount || oldWidget.likeCount != widget.likeCount) {
      _refreshMetrics();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Localizations.maybeLocaleOf(context);
    _title = null;
  }

  void _onSummaryChanged() {
    if (!mounted || !_observing) return;
    setState(() {
      _summary = _summaryStore.liveSummaryState.summaryData.value;
      _refreshMetrics();
    });
  }

  void _stopObserving() {
    if (!_observing) return;
    _observing = false;
    _summaryStore.liveSummaryState.summaryData.removeListener(_onSummaryChanged);
  }

  @override
  void dispose() {
    _stopObserving();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return BottomSheetView(
        sheetHeight: _resolvedSheetHeight(context, constraints.maxHeight),
        onDismiss: widget.onDismiss,
        onWillDismiss: _stopObserving,
        child: Stack(
          children: <Widget>[
            _title ??= Positioned(
              left: 26,
              top: 40,
              height: 28,
              child: Text(
                LiveKitResources.localizedString('tuilivekit.pusher.status.title'),
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              right: 16 + 79 - 3,
              top: 41 + (24 - 6) / 2,
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: LiveTheme.brandBlue,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            _duration ??= Positioned(
              right: 16,
              top: 41,
              width: 79,
              height: 24,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  PusherLiveStatusView.formatDuration(widget.elapsedSeconds),
                  style: const TextStyle(
                    // UIColor(white: 0.9, alpha: 1)
                    color: _LiveStatusStyle.durationForeground,
                    fontSize: 12,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            _tabs ??= Positioned(
              left: 18,
              right: 18,
              top: 81,
              height: 46,
              child: _LiveStatusTabView(
                isMetricsSelected: _page == _LiveStatusPage.metrics,
                onSelectMetrics: () => _selectPage(_LiveStatusPage.metrics),
                onSelectDevice: () => _selectPage(_LiveStatusPage.device),
              ),
            ),
            _content ??= Positioned(
              left: 0,
              right: 0,
              top: 141,
              bottom: 0,
              //
              // 内容保持 515pt 固有高度，抽屉被压缩时滚动而不是挤压内容。
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _contentHeight),
                  child: _page == _LiveStatusPage.metrics ? _metrics : _device,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _LiveStatusTabView extends StatelessWidget {
  const _LiveStatusTabView({
    required this.isMetricsSelected,
    required this.onSelectMetrics,
    required this.onSelectDevice,
  });

  final bool isMetricsSelected;
  final VoidCallback onSelectMetrics;
  final VoidCallback onSelectDevice;

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double itemWidth = (constraints.maxWidth - 12) / 2;

        return DecoratedBox(
          decoration: BoxDecoration(
            // UIColor.white.withAlphaComponent(0.06)
            color: _LiveStatusStyle.tabsBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: isMetricsSelected ? 4 : itemWidth + 8,
                top: 4,
                width: itemWidth,
                height: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // UIColor(red: 0.413, green: 0.686, blue: 1, alpha: 0.303)
                    color: _LiveStatusStyle.selectedTabBackground,
                    borderRadius: BorderRadius.circular(11),
                    // UIColor(red: 0.29, green: 0.62, blue: 1, alpha: 0.35)
                    border: Border.all(color: _LiveStatusStyle.selectedTabBorder, width: 1),
                  ),
                ),
              ),
              Positioned(
                left: 4,
                top: 4,
                width: itemWidth,
                height: 38,
                child: _buildTabButton(LiveKitResources.localizedString('tuilivekit.pusher.status.realtime'),
                    isMetricsSelected, onSelectMetrics),
              ),
              Positioned(
                left: itemWidth + 8,
                top: 4,
                width: itemWidth,
                height: 38,
                child: _buildTabButton(LiveKitResources.localizedString('tuilivekit.pusher.status.device'),
                    !isMetricsSelected, onSelectDevice),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String title, bool isSelected, VoidCallback onPressed) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFFFFF) : const Color(0x80FFFFFF),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // UIColor.white.withAlphaComponent(0.02)
        color: _LiveStatusStyle.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        // UIColor.white.withAlphaComponent(0.07)
        border: Border.all(color: _LiveStatusStyle.cardBorder, width: 1),
      ),
      child: child,
    );
  }
}

abstract final class _LiveStatusStyle {
  static const durationForeground = Color(0xFFE6E6E6);
  static const tabsBackground = Color(0x0FFFFFFF);
  static const selectedTabBackground = Color(0x4D69AFFF);
  static const selectedTabBorder = Color(0x594A9EFF);
  static const separator = Color(0x11FFFFFF);
  static const statValue = Color(0xF5FFFFFF);
  static const fieldTitle = Color(0xD1FFFFFF);
  static const fieldDescription = Color(0x57FFFFFF);
  static const fieldValue = Color(0xADFFFFFF);
  static const metricTitle = Color(0x6BFFFFFF);
  static const cardBackground = Color(0x05FFFFFF);
  static const cardBorder = Color(0x12FFFFFF);
}
