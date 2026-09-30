import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/device/device_store.dart';
import 'package:atomic_x_core/api/device/screen_share_store.dart';
import 'package:atomic_x_core/api/media_mixing/media_mixing_store.dart';

import '../../l10n/language_store.dart';
import '../util/encoder_params_util.dart';
import 'scene_store.dart';

/// SceneStore（按场景隔离的 UI 状态）与引擎唯一合流画布
/// （MediaMixingStore）之间的同步桥。
///
/// 引擎只有一个合流画布，多场景隔离通过 diff 同步实现：监听
/// SceneStore 变更，把「当前场景的引擎托管画面源」与引擎侧源集合做
/// 增删对齐（切场景即全量重建：移除旧场景源、添加新场景源）。
///
/// 引擎托管画面源：摄像头 / 图片 / 本地视频 / 在线视频
/// （source.isEngineBound == true）；屏幕共享后续期次接入。
class SceneEngineSync {
  SceneEngineSync(this._store) {
    _store.addListener(_onStoreChanged);
    // 引擎合流参数（含横竖屏）变化时重推布局：归一化高度依赖
    // 画布宽高比，params 变化后必须用新比例重算。
    MediaMixingStore.shared.state.params.addListener(_onStoreChanged);
    // 引擎 → UI 回写：画布拖拽 / 缩放的结果持久化到 MediaSourceConfig，
    // 否则切场景重建时会回到添加时的初始位置。
    MediaMixingStore.shared.state.sources.addListener(_onEngineSourcesChanged);
    // 选中态双向同步的引擎 → UI 方向（画布点选 → 列表高亮）。
    MediaMixingStore.shared.state.selectedSourceKey
        .addListener(_onEngineSelectionChanged);
  }

  final SceneStore _store;

  bool _mixingStarted = false;

  /// 是否向引擎下发手动采集分辨率（TXCameraCaptureManual）。
  /// 曾用于排查混流 Metal 转码崩溃（已坐实为 TRTC 13.5 SDK 回归，
  /// 与本开关无关），保持开启。
  static const bool _enableManualCaptureParam = true;

  /// 当前已镜像到引擎的源 key（与画面源 id 一致）。
  final Set<String> _engineSourceKeys = {};

  /// 序列化引擎增删操作，避免并发的 store 通知交错调用引擎。
  Future<void> _queue = Future.value();

  /// addXxxSource / updateXxxSource 内部自行驱动引擎，
  /// 期间挂起 diff 同步，避免重复添加。
  bool _suspendSync = false;

  void dispose() {
    _store.removeListener(_onStoreChanged);
    MediaMixingStore.shared.state.params.removeListener(_onStoreChanged);
    MediaMixingStore.shared.state.sources
        .removeListener(_onEngineSourcesChanged);
    MediaMixingStore.shared.state.selectedSourceKey
        .removeListener(_onEngineSelectionChanged);
    if (_mixingStarted) {
      MediaMixingStore.shared.stopMixing();
      _mixingStarted = false;
    }
  }

  // ========== 添加 ==========

  /// 向当前场景添加摄像头画面源并镜像到引擎。
  ///
  /// 成功返回 null；失败返回用户可读的错误信息（UI 层负责提示）。
  Future<String?> addCameraSource(CameraSourceConfig config) {
    return _addSource(() => _store.addCameraSource(config));
  }

  /// 添加图片画面源（自动读取图片真实像素尺寸，按默认尺寸规则布局）。
  Future<String?> addImageSource(ImageSourceConfig config) async {
    final size = await _decodeImageSize(config.path);
    return _addSource(() => _store.addImageSource(config, sourceSize: size));
  }

  /// 添加屏幕 / 窗口共享画面源。
  Future<String?> addScreenSource(ScreenSourceConfig config) {
    return _addSource(() => _store.addScreenSource(config));
  }

  /// 添加本地视频文件画面源。
  Future<String?> addVideoFileSource(VideoFileSourceConfig config) {
    return _addSource(() => _store.addVideoFileSource(config));
  }

  /// 添加在线视频画面源。
  Future<String?> addOnlineVideoSource(OnlineVideoSourceConfig config) {
    return _addSource(() => _store.addOnlineVideoSource(config));
  }

  /// 添加流程模板：启动混流 → 写 UI 层 → 添加引擎源 → 失败回滚。
  Future<String?> _addSource(MediaSourceConfig Function() addToStore) async {
    if (!await _ensureMixingStarted()) {
      return currentLiveKitStrings().errorStartMixing;
    }
    _suspendSync = true;
    late final MediaSourceConfig source;
    try {
      source = addToStore();
    } finally {
      _suspendSync = false;
    }
    final error = await _addEngineSource(source);
    if (error != null) {
      // 引擎拒绝（无权限 / 格式不支持等）时回滚 UI 画面源。
      _suspendSync = true;
      try {
        _store.removeSource(source.id);
      } finally {
        _suspendSync = false;
      }
      return error;
    }
    return null;
  }

  // ========== 编辑 ==========

  /// 更新已有摄像头画面源的设备 / 采集配置（编辑弹窗保存）。
  ///
  /// 引擎不支持给已有源换绑设备：deviceId 变化时 remove + re-add；
  /// 仅分辨率变化时走 setCameraCaptureParam。
  Future<String?> updateCameraSource(
    String sourceId,
    CameraSourceConfig config,
  ) async {
    final oldConfig = _sourceOf(sourceId)?.camera;
    if (oldConfig == null) {
      return currentLiveKitStrings().errorSourceNotFound;
    }
    _suspendStore(() => _store.updateSourceCamera(sourceId, config));
    // 画面源当前不在引擎中（隐藏态）：仅更新本地配置即可。
    if (!_engineSourceKeys.contains(sourceId)) {
      return null;
    }
    if (oldConfig.deviceId != config.deviceId) {
      return _reAddEngineSource(sourceId);
    }
    if (_enableManualCaptureParam &&
        (oldConfig.width != config.width ||
            oldConfig.height != config.height ||
            oldConfig.fps != config.fps)) {
      MediaMixingStore.shared.setCameraCaptureParam(
        sourceId,
        CameraCaptureParam(
          width: config.width,
          height: config.height,
          fps: config.fps,
        ),
      );
    }
    if (oldConfig.mirror != config.mirror) {
      MediaMixingStore.shared.setMirror(
        sourceId,
        config.mirror ? MirrorType.enable : MirrorType.disable,
      );
    }
    return null;
  }

  /// 更新屏幕 / 窗口共享源配置：换源 remove + re-add（引擎不支持
  /// 给已有源换绑共享目标）。
  Future<String?> updateScreenSource(
    String sourceId,
    ScreenSourceConfig config,
  ) async {
    final oldConfig = _sourceOf(sourceId)?.screen;
    if (oldConfig == null) {
      return currentLiveKitStrings().errorSourceNotFound;
    }
    _suspendStore(() => _store.updateSourceScreen(sourceId, config));
    if (!_engineSourceKeys.contains(sourceId)) {
      return null;
    }
    if (oldConfig.sourceId != config.sourceId ||
        oldConfig.isScreen != config.isScreen) {
      return _reAddEngineSource(sourceId);
    }
    return null;
  }

  /// 更新图片源配置：路径变化 remove + re-add（并重读宽高比）。
  Future<String?> updateImageSource(
    String sourceId,
    ImageSourceConfig config,
  ) async {
    final oldConfig = _sourceOf(sourceId)?.image;
    if (oldConfig == null) {
      return currentLiveKitStrings().errorSourceNotFound;
    }
    final pathChanged = oldConfig.path != config.path;
    // 编辑换图：只更新宽高比（位置 / 尺寸保持用户调整后的值）。
    final size = pathChanged ? await _decodeImageSize(config.path) : null;
    final ratio =
        size == null ? null : size.width / size.height;
    _suspendStore(
      () => _store.updateSourceImage(sourceId, config, ratio: ratio),
    );
    if (!_engineSourceKeys.contains(sourceId)) {
      return null;
    }
    if (pathChanged) {
      return _reAddEngineSource(sourceId);
    }
    return null;
  }

  /// 更新本地视频源配置：路径变化 remove + re-add；仅音量变化
  /// 走 setSourceVolume。
  Future<String?> updateVideoFileSource(
    String sourceId,
    VideoFileSourceConfig config,
  ) async {
    final oldConfig = _sourceOf(sourceId)?.videoFile;
    if (oldConfig == null) {
      return currentLiveKitStrings().errorSourceNotFound;
    }
    _suspendStore(() => _store.updateSourceVideoFile(sourceId, config));
    if (!_engineSourceKeys.contains(sourceId)) {
      return null;
    }
    if (oldConfig.path != config.path) {
      return _reAddEngineSource(sourceId);
    }
    if (oldConfig.volume != config.volume) {
      MediaMixingStore.shared.setSourceVolume(sourceId, config.volume);
    }
    return null;
  }

  /// 更新在线视频源配置：URL / 缓存变化 remove + re-add（引擎无
  /// 在线视频参数更新接口）；仅音量变化走 setSourceVolume。
  Future<String?> updateOnlineVideoSource(
    String sourceId,
    OnlineVideoSourceConfig config,
  ) async {
    final oldConfig = _sourceOf(sourceId)?.onlineVideo;
    if (oldConfig == null) {
      return currentLiveKitStrings().errorSourceNotFound;
    }
    _suspendStore(() => _store.updateSourceOnlineVideo(sourceId, config));
    if (!_engineSourceKeys.contains(sourceId)) {
      return null;
    }
    if (oldConfig.url != config.url ||
        oldConfig.networkCacheSizeKB != config.networkCacheSizeKB) {
      return _reAddEngineSource(sourceId);
    }
    if (oldConfig.volume != config.volume) {
      MediaMixingStore.shared.setSourceVolume(sourceId, config.volume);
    }
    return null;
  }

  /// 在挂起 diff 同步期间执行 store 变更。
  void _suspendStore(void Function() action) {
    _suspendSync = true;
    try {
      action();
    } finally {
      _suspendSync = false;
    }
  }

  /// 移除并重新添加引擎源（换绑设备 / 换文件 / 换 URL）。
  Future<String?> _reAddEngineSource(String sourceId) {
    MediaMixingStore.shared.removeSource(sourceId);
    _engineSourceKeys.remove(sourceId);
    final source = _sourceOf(sourceId);
    if (source == null) {
      return Future.value(currentLiveKitStrings().errorSourceNotFound);
    }
    return _addEngineSource(source);
  }

  /// 更新摄像头美颜参数（美颜面板实时回调，fire-and-forget）。
  ///
  /// UI 值域 0-100，引擎值域 [0.0, 1.0]；开关关闭时下发全 0
  /// （效果关闭），滑杆值保留在 store 中。
  void updateCameraBeauty(String sourceId, CameraBeautySettings beauty) {
    final source = _sourceOf(sourceId);
    if (source?.camera == null) {
      return;
    }
    MediaMixingStore.shared.setCameraBeauty(
      sourceId,
      CameraBeautyParam(
        skinSmoothingLevel: beauty.enabled ? beauty.skinSmooth / 100 : 0,
        whitenessLevel: beauty.enabled ? beauty.whiteness / 100 : 0,
        sharpenLevel: beauty.enabled ? beauty.sharpen / 100 : 0,
        ruddyLevel: beauty.enabled ? beauty.ruddy / 100 : 0,
      ),
    );
  }

  // ========== diff 同步 ==========

  void _onStoreChanged() {
    if (_suspendSync) {
      return;
    }
    _queue = _queue.then((_) => _diffSync());
  }

  // ========== 引擎 → UI 回写 ==========

  /// 布局回写容差：百分比字段 0.05、宽高比 0.01（防浮点回环抖动）。
  static const double _kLayoutEpsilon = 0.05;
  static const double _kRatioEpsilon = 0.01;

  /// 画布编辑（拖拽 / 缩放）结果回写 MediaSourceConfig。
  ///
  /// 自身 diff sync 推上去的布局回投后算出的值与原值在容差内一致，
  /// 不会触发写回，因此不会形成循环。
  void _onEngineSourcesChanged() {
    final sources = MediaMixingStore.shared.state.sources.value;
    if (sources.isEmpty) {
      return;
    }
    final enc =
        MediaMixingStore.shared.state.params.value.videoEncoderParams;
    final canvasAspect = enc.height > 0 ? enc.width / enc.height : 16 / 9;
    for (final src in sources) {
      final source = _sourceOf(src.key);
      if (source == null || !source.isEngineBound) {
        continue;
      }
      // 视频源自动布局：contentSize 首次就绪（TRTC onMediaSourceSizeChanged
      // 链路回投）且用户尚未手动编辑时，按默认尺寸规则重算并推给引擎；
      // updateSourceLayoutFromEngine 会清除 pendingAutoLayout 标记。
      if (source.pendingAutoLayout) {
        final size = src.contentSize;
        if (size == null) {
          continue;
        }
        final layout =
            _store.defaultLayoutForSource(size.width, size.height);
        if (layout == null) {
          continue;
        }
        _suspendStore(
          () => _store.updateSourceLayoutFromEngine(
            src.key,
            left: layout.left,
            top: layout.top,
            width: layout.width,
            ratio: layout.ratio,
          ),
        );
        final updated = _sourceOf(src.key);
        if (updated != null) {
          unawaited(
            MediaMixingStore.shared.updateSourceLayout(
              src.key,
              _layoutFor(updated, zOrder: src.layout.zOrder),
            ),
          );
        }
        continue;
      }
      final rect = src.layout.rect;
      if (rect.width <= 0 || rect.height <= 0) {
        continue;
      }
      // fit 画面源被自身推为全画布：非用户编辑，跳过（用户拖 / 缩后
      // rect 不再是全画布，走写回并自动退出 fit）。
      if (source.fit && _isFullCanvas(rect)) {
        continue;
      }
      final left = rect.x * 100;
      final top = rect.y * 100;
      final width = rect.width * 100;
      // 归一化高度 = width × 画布宽高比 / ratio 的逆运算。
      final ratio = rect.width * canvasAspect / rect.height;
      final noChange = !source.fit &&
          (left - source.left).abs() < _kLayoutEpsilon &&
          (top - source.top).abs() < _kLayoutEpsilon &&
          (width - source.width).abs() < _kLayoutEpsilon &&
          (ratio - source.ratio).abs() < _kRatioEpsilon;
      if (noChange) {
        continue;
      }
      _suspendStore(
        () => _store.updateSourceLayoutFromEngine(
          src.key,
          left: left,
          top: top,
          width: width,
          ratio: ratio,
        ),
      );
    }
  }

  static bool _isFullCanvas(MixingRect rect) {
    const e = 1e-3;
    return rect.x.abs() < e &&
        rect.y.abs() < e &&
        (rect.width - 1).abs() < e &&
        (rect.height - 1).abs() < e;
  }

  /// 画布点选 → 列表选中（选中态同步的引擎 → UI 方向）。
  void _onEngineSelectionChanged() {
    final key = MediaMixingStore.shared.state.selectedSourceKey.value;
    if (key == _store.selectedSourceId) {
      return;
    }
    _suspendStore(() => _store.selectSource(key));
  }

  /// 把引擎侧源集合对齐到当前场景的引擎托管画面源。
  Future<void> _diffSync() async {
    final sources = _store.currentSources;
    final desired = <String, MediaSourceConfig>{
      for (final source in sources)
        if (_isEngineManaged(source)) source.id: source,
    };
    // 移除不再需要的源（删除 / 隐藏 / 切场景）。
    final stale =
        _engineSourceKeys.where((key) => !desired.containsKey(key)).toList();
    for (final key in stale) {
      MediaMixingStore.shared.removeSource(key);
      _engineSourceKeys.remove(key);
    }
    // 选中态对齐（UI → 引擎方向；反向由 selectedSourceKey 监听完成）。
    // 选中项不在引擎中（隐藏 / 未镜像）时清空引擎选中。
    final uiSelected = _store.selectedSourceId;
    final effectiveSelected =
        uiSelected != null && _engineSourceKeys.contains(uiSelected)
            ? uiSelected
            : null;
    if (MediaMixingStore.shared.state.selectedSourceKey.value !=
        effectiveSelected) {
      MediaMixingStore.shared.selectSource(effectiveSelected);
    }
    if (desired.isEmpty) {
      return;
    }
    if (!await _ensureMixingStarted()) {
      return;
    }
    for (var i = 0; i < sources.length; i++) {
      final source = sources[i];
      if (!_isEngineManaged(source)) {
        continue;
      }
      if (!_engineSourceKeys.contains(source.id)) {
        // 新增（含切场景重建 / 隐藏后重新显示）。失败保持不在集合中，
        // 下次 store 变更时重试。
        await _addEngineSource(source);
      } else {
        // 层级 / 布局对齐（拖拽排序、后续画布编辑）。
        unawaited(
          MediaMixingStore.shared.updateSourceLayout(
            source.id,
            _layoutFor(source, zOrder: i),
          ),
        );
      }
    }
  }

  // ========== 引擎源操作 ==========

  Future<String?> _addEngineSource(MediaSourceConfig source) async {
    final layout = _layoutFor(source, zOrder: _zOrderOf(source.id));
    final store = MediaMixingStore.shared;
    final CompletionHandler result;
    switch (source.kind) {
      case MediaSourceKind.camera:
        result = await store.addCameraSource(
          key: source.id,
          deviceId: source.camera!.deviceId,
          layout: layout,
        );
      case MediaSourceKind.screen:
        final config = source.screen!;
        result = await store.addScreenSource(
          key: source.id,
          source: ShareSource(
            type: config.isScreen
                ? ShareSourceType.screen
                : ShareSourceType.window,
            sourceId: config.sourceId,
            sourceName: config.sourceName,
          ),
          layout: layout,
        );
      case MediaSourceKind.image:
        result = await store.addImageSource(
          key: source.id,
          imagePath: source.image!.path,
          layout: layout,
        );
      case MediaSourceKind.videoFile:
        result = await store.addVideoFileSource(
          key: source.id,
          filePath: source.videoFile!.path,
          layout: layout,
          playoutVolume: source.videoFile!.volume,
        );
      case MediaSourceKind.onlineVideo:
        result = await store.addOnlineVideoSource(
          key: source.id,
          url: source.onlineVideo!.url,
          layout: layout,
          playoutVolume: source.onlineVideo!.volume,
          networkCacheSizeKB: source.onlineVideo!.networkCacheSizeKB,
        );
    }
    if (!result.isSuccess) {
      return result.errorMessage?.isNotEmpty == true
          ? result.errorMessage!
          : currentLiveKitStrings().errorAddSource('${result.errorCode}');
    }
    _engineSourceKeys.add(source.id);
    _applyPostAddTweaks(source);
    return null;
  }

  /// 添加成功后的类型化收尾（采集参数 / 填充模式）。
  void _applyPostAddTweaks(MediaSourceConfig source) {
    final store = MediaMixingStore.shared;
    switch (source.kind) {
      case MediaSourceKind.camera:
        final config = source.camera!;
        if (_enableManualCaptureParam) {
          store.setCameraCaptureParam(
            source.id,
            CameraCaptureParam(
              width: config.width,
              height: config.height,
              fps: config.fps,
            ),
          );
        }
        store.setMirror(
          source.id,
          config.mirror ? MirrorType.enable : MirrorType.disable,
        );
        // 美颜恢复：引擎侧源每次重建（切场景 / 隐藏重显 / 编辑换设备）
        // 后美颜归零，按场景存储的配置重新下发。
        if (config.beauty.enabled) {
          store.setCameraBeauty(
            source.id,
            CameraBeautyParam(
              skinSmoothingLevel: config.beauty.skinSmooth / 100,
              whitenessLevel: config.beauty.whiteness / 100,
              sharpenLevel: config.beauty.sharpen / 100,
              ruddyLevel: config.beauty.ruddy / 100,
            ),
          );
        }
      case MediaSourceKind.screen:
      case MediaSourceKind.image:
      case MediaSourceKind.videoFile:
      case MediaSourceKind.onlineVideo:
        // 保持内容原始宽高比（画布区域内留边），避免拉伸变形。
        store.setFillMode(source.id, VideoFillMode.fit);
    }
  }

  /// 首次添加媒体源时才启动混流（本地预览无需登录）。
  /// 启动参数直接取引擎响应式 params（横竖屏 / 分辨率 / 帧率的
  /// 唯一数据源，由顶部工具条或 M3 推流参数弹窗维护）。
  Future<bool> _ensureMixingStarted() async {
    if (_mixingStarted) {
      return true;
    }
    final params = MediaMixingStore.shared.state.params.value;
    EncoderParamsUtil.syncEncoderQuality(params.videoEncoderParams);
    final result = await MediaMixingStore.shared.startMixing(params);
    if (!result.isSuccess) {
      return false;
    }
    _mixingStarted = true;
    return true;
  }

  // ========== 工具 ==========

  bool _isEngineManaged(MediaSourceConfig source) {
    return source.isEngineBound && source.visible;
  }

  int _zOrderOf(String sourceId) {
    final sources = _store.currentSources;
    final index = sources.indexWhere((l) => l.id == sourceId);
    return index < 0 ? 0 : index;
  }

  /// MediaSourceConfig（画布百分比 + 宽高比）→ 引擎归一化 MixingRect。
  MixingLayout _layoutFor(MediaSourceConfig source, {required int zOrder}) {
    if (source.fit) {
      return MixingLayout(rect: const MixingRect(), zOrder: zOrder);
    }
    final enc =
        MediaMixingStore.shared.state.params.value.videoEncoderParams;
    final canvasAspect = enc.width / enc.height;
    final width = source.width / 100;
    // width 为画布宽度百分比，ratio 为画面源宽高比，
    // 归一化高度 = width * 画布宽高比 / ratio（clamp 防御极端比例溢出）。
    final height =
        (width * canvasAspect / source.ratio).clamp(0.0, 1.0).toDouble();
    return MixingLayout(
      rect: MixingRect(
        x: source.left / 100,
        y: source.top / 100,
        width: width,
        height: height,
      ),
      zOrder: zOrder,
    );
  }

  /// 解码图片文件获取真实像素尺寸；失败（含 BMP 解码不支持等）返回
  /// null，调用方回退到模板布局 / 比例。
  Future<ui.Size?> _decodeImageSize(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = ui.Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      image.dispose();
      codec.dispose();
      return size.width > 0 && size.height > 0 ? size : null;
    } catch (_) {
      return null;
    }
  }

  MediaSourceConfig? _sourceOf(String sourceId) {
    for (final source in _store.currentSources) {
      if (source.id == sourceId) {
        return source;
      }
    }
    return null;
  }
}
