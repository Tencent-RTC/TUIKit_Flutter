import 'dart:math' as math;

import 'package:atomic_x_core/api/media_mixing/media_mixing_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:remixicon/remixicon.dart';

import '../../l10n/language_store.dart';
import '../../l10n/live_kit_localizations.dart';

/// 场景适用的横竖屏模式。
enum SceneMode { landscape, portrait }

/// 画面源类型（对应「添加画面源」弹窗的类型卡片）。
enum MediaSourceKind { camera, screen, image, onlineVideo, videoFile }

/// 摄像头美颜参数（UI 口径，0 ~ 100）。
///
/// 底层引擎值域为 [0.0, 1.0]（TXCameraBeautyParam），下发时由
/// SceneEngineSync 按 /100 映射；存在 CameraSourceConfig（随场景
/// 持久化），切场景重建引擎源后在 _applyPostAddTweaks 中恢复下发。
class CameraBeautySettings {
  const CameraBeautySettings({
    this.enabled = false,
    this.skinSmooth = 0,
    this.whiteness = 0,
    this.sharpen = 0,
    this.ruddy = 0,
  })  : assert(skinSmooth >= 0 && skinSmooth <= 100),
        assert(whiteness >= 0 && whiteness <= 100),
        assert(sharpen >= 0 && sharpen <= 100),
        assert(ruddy >= 0 && ruddy <= 100);

  /// 美颜总开关；关闭时向引擎下发全 0（效果关闭），滑杆值保留。
  final bool enabled;

  /// 磨皮（skinSmoothingLevel）。
  final int skinSmooth;

  /// 美白（whitenessLevel）。
  final int whiteness;

  /// 锐化（sharpenLevel）。
  final int sharpen;

  /// 红润（ruddyLevel）。
  final int ruddy;

  CameraBeautySettings copyWith({
    bool? enabled,
    int? skinSmooth,
    int? whiteness,
    int? sharpen,
    int? ruddy,
  }) {
    return CameraBeautySettings(
      enabled: enabled ?? this.enabled,
      skinSmooth: skinSmooth ?? this.skinSmooth,
      whiteness: whiteness ?? this.whiteness,
      sharpen: sharpen ?? this.sharpen,
      ruddy: ruddy ?? this.ruddy,
    );
  }
}

/// 摄像头画面源的采集配置（设备 + 采集分辨率）。
///
/// 引擎（MediaMixingStore）的摄像头源以 [deviceId] 为标识；[width]/[height]/
/// [fps] 通过 setCameraCaptureParam 下发（底层 TRTC 为 TXCameraCaptureManual
/// 模式，fps 当前不生效，SDK 结构体无该字段）。
class CameraSourceConfig {
  const CameraSourceConfig({
    required this.deviceId,
    required this.deviceName,
    this.width = 1920,
    this.height = 1080,
    this.fps = 30,
    this.mirror = false,
    this.beauty = const CameraBeautySettings(),
  });

  final String deviceId;
  final String deviceName;
  final int width;
  final int height;
  final int fps;

  /// 是否镜像（对应引擎 MirrorType.enable / disable）。
  final bool mirror;

  /// 美颜参数（随场景存储；引擎侧源重建后归零，需恢复下发）。
  final CameraBeautySettings beauty;

  CameraSourceConfig copyWith({
    String? deviceId,
    String? deviceName,
    int? width,
    int? height,
    int? fps,
    bool? mirror,
    CameraBeautySettings? beauty,
  }) {
    return CameraSourceConfig(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      mirror: mirror ?? this.mirror,
      beauty: beauty ?? this.beauty,
    );
  }
}

/// 添加 / 编辑摄像头弹窗提供的预设采集分辨率档位。
///
/// 引擎与底层 TRTC SDK 均不提供「枚举摄像头支持的采集分辨率」能力，
/// 因此采用预设档位（默认选中 1920x1080）。
const List<({int width, int height})> kCameraCapturePresets = [
  (width: 640, height: 360),
  (width: 960, height: 540),
  (width: 1280, height: 720),
  (width: 1920, height: 1080),
];

/// 屏幕 / 窗口共享画面源配置。
class ScreenSourceConfig {
  const ScreenSourceConfig({
    required this.sourceId,
    required this.sourceName,
    required this.isScreen,
    this.width,
    this.height,
  });

  /// 运行时句柄（HWND / CGWindowID 字符串化）。易失，不可持久化：
  /// 窗口关闭 / 系统重启后会失效，届时需重新选择。
  final String sourceId;

  /// 共享源名称（枚举时刻的窗口标题 / 屏幕名）。
  final String sourceName;

  /// true = 整块屏幕；false = 应用窗口。
  final bool isScreen;

  /// 源像素尺寸（枚举时刻）。底层 TRTC C API 枚举时返回 x/y/width/height，
  /// 但引擎 C++ 包装层（trtc_adapter_wrapper_cpp.cc）当前未透传，
  /// 故为 null；引擎补齐后由选择弹窗填入，用于推导画面源默认宽高比。
  final int? width;
  final int? height;

  /// 源宽高比；尺寸未知时返回 null（回退模板比例）。
  double? get aspectRatio {
    final w = width, h = height;
    if (w == null || h == null || w <= 0 || h <= 0) {
      return null;
    }
    return w / h;
  }

  ScreenSourceConfig copyWith({
    String? sourceId,
    String? sourceName,
    bool? isScreen,
    int? width,
    int? height,
  }) {
    return ScreenSourceConfig(
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      isScreen: isScreen ?? this.isScreen,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

/// 图片画面源配置。
class ImageSourceConfig {
  const ImageSourceConfig({required this.path});

  final String path;

  ImageSourceConfig copyWith({String? path}) {
    return ImageSourceConfig(path: path ?? this.path);
  }
}

/// 本地视频文件画面源配置。
class VideoFileSourceConfig {
  const VideoFileSourceConfig({required this.path, this.volume = 100});

  final String path;

  /// 播放音量（0-100）。
  final int volume;

  VideoFileSourceConfig copyWith({String? path, int? volume}) {
    return VideoFileSourceConfig(
      path: path ?? this.path,
      volume: volume ?? this.volume,
    );
  }
}

/// 在线视频画面源配置。
class OnlineVideoSourceConfig {
  const OnlineVideoSourceConfig({
    required this.url,
    this.volume = 100,
    this.networkCacheSizeKB = 1024,
  });

  final String url;

  /// 播放音量（0-100）。
  final int volume;

  /// 网络缓存大小（KB），范围 [0, 16384]，0 表示自动。
  final int networkCacheSizeKB;

  OnlineVideoSourceConfig copyWith({
    String? url,
    int? volume,
    int? networkCacheSizeKB,
  }) {
    return OnlineVideoSourceConfig(
      url: url ?? this.url,
      volume: volume ?? this.volume,
      networkCacheSizeKB: networkCacheSizeKB ?? this.networkCacheSizeKB,
    );
  }
}

/// SDK 支持的图片格式（ITXLocalMediaTranscoding.h：BMP / JPG / PNG / GIF）。
const Set<String> kImageFileExtensions = {'bmp', 'jpg', 'jpeg', 'png', 'gif'};

/// 客户端校验的本地视频格式白名单（引擎侧另有 -9 错误兜底）。
const Set<String> kVideoFileExtensions = {
  'mp4',
  'mov',
  'm4v',
  'mkv',
  'avi',
  'flv',
  'wmv',
};

/// 在线视频网络缓存上限（KB），对应 SDK OnlineVideoParam 的 [0, 16*1024]。
const int kMaxNetworkCacheSizeKB = 16 * 1024;

/// 预设场景定义。
class SceneConfig {
  const SceneConfig({
    required this.key,
    required this.name,
    required this.icon,
    required this.modes,
    this.customName = false,
  });

  final String key;
  final String name;
  final IconData icon;
  final SceneMode modes;

  /// 名称是否为用户自定义（重命名 / 复制 / 新建后为 true）。
  /// false（预置场景未改名）时显示名按 key 本地化，见 [sceneDisplayName]。
  final bool customName;
}

/// 默认场景 key → 本地化名称；其他 key 返回 null。
String? _presetSceneName(LiveKitLocalizations s, String key) {
  return switch (key) {
    'default-landscape' || 'default-portrait' => s.sceneDefault,
    _ => null,
  };
}

/// 场景显示名：预置且未改名的场景按 key 本地化；
/// 自定义 / 已重命名场景显示存储名（用户输入不翻译）。
String sceneDisplayName(BuildContext context, SceneConfig scene) {
  if (scene.customName) {
    return scene.name;
  }
  return _presetSceneName(LiveKitLocalizations.of(context), scene.key) ??
      scene.name;
}

/// 无 context 版本（SceneStore 内部复制场景等场景使用）。
String _sceneDisplayNameCurrent(SceneConfig scene) {
  if (scene.customName) {
    return scene.name;
  }
  return _presetSceneName(currentLiveKitStrings(), scene.key) ?? scene.name;
}

/// 单个画面源配置。
///
/// [left]/[top]/[width] 为相对预览画布的百分比，[ratio] 为宽高比；
/// [fit] 为 true 时铺满画布，忽略位置字段。
class MediaSourceConfig {
  const MediaSourceConfig({
    required this.id,
    required this.kind,
    required this.name,
    required this.icon,
    this.visible = true,
    this.fit = false,
    this.left = 0,
    this.top = 0,
    this.width = 50,
    this.ratio = 16 / 9,
    this.tag,
    this.camera,
    this.screen,
    this.image,
    this.videoFile,
    this.onlineVideo,
    this.pendingAutoLayout = false,
  });

  final String id;
  final MediaSourceKind kind;
  final String name;
  final IconData icon;
  final bool visible;
  final bool fit;
  final double left;
  final double top;
  final double width;
  final double ratio;
  final String? tag;

  /// 摄像头采集配置；非空表示该画面源已绑定引擎摄像头源
  /// （引擎源 key 与画面源 [id] 一致）。
  final CameraSourceConfig? camera;

  /// 屏幕 / 窗口共享源配置（非空表示已绑定引擎屏幕源）。
  final ScreenSourceConfig? screen;

  /// 图片源配置（非空表示已绑定引擎图片源）。
  final ImageSourceConfig? image;

  /// 本地视频文件源配置（非空表示已绑定引擎视频文件源）。
  final VideoFileSourceConfig? videoFile;

  /// 在线视频源配置（非空表示已绑定引擎在线视频源）。
  final OnlineVideoSourceConfig? onlineVideo;

  /// 视频源：等待引擎 contentSize 回投后按默认尺寸规则自动布局；
  /// 自动应用或用户手动编辑（画布拖 / 缩）后清除。
  final bool pendingAutoLayout;

  /// 是否已绑定引擎源（任一类型配置非空）。
  bool get isEngineBound =>
      camera != null ||
      screen != null ||
      image != null ||
      videoFile != null ||
      onlineVideo != null;

  MediaSourceConfig copyWith({
    String? id,
    String? name,
    bool? visible,
    bool? fit,
    double? left,
    double? top,
    double? width,
    double? ratio,
    CameraSourceConfig? camera,
    ScreenSourceConfig? screen,
    ImageSourceConfig? image,
    VideoFileSourceConfig? videoFile,
    OnlineVideoSourceConfig? onlineVideo,
    bool? pendingAutoLayout,
  }) {
    return MediaSourceConfig(
      id: id ?? this.id,
      kind: kind,
      name: name ?? this.name,
      icon: icon,
      visible: visible ?? this.visible,
      fit: fit ?? this.fit,
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      ratio: ratio ?? this.ratio,
      tag: tag,
      camera: camera ?? this.camera,
      screen: screen ?? this.screen,
      image: image ?? this.image,
      videoFile: videoFile ?? this.videoFile,
      onlineVideo: onlineVideo ?? this.onlineVideo,
      pendingAutoLayout: pendingAutoLayout ?? this.pendingAutoLayout,
    );
  }
}

/// 场景与画面源的本地状态（ChangeNotifier）。
///
/// 预置场景初始无画面源；摄像头源经 SceneEngineSync 真实接入引擎
/// （AtomicXCore MediaMixingStore），其余类型暂为 UI 假数据占位。
class SceneStore extends ChangeNotifier {
  SceneStore({
    List<SceneConfig>? scenes,
    Map<String, List<MediaSourceConfig>>? sources,
    String? currentSceneKey,
  }) : // defaultScenes 是 const 列表（不可变），必须拷贝为可变列表，
       // 否则 addScene / renameScene / deleteScene 等增删改会抛
       // "Cannot add to an unmodifiable list"。
       _scenes = List.of(scenes ?? defaultScenes),
       _sources = sources ?? defaultSources(),
       currentSceneKey = currentSceneKey ?? '' {
    // 横竖屏状态的唯一数据源在引擎（MediaMixingState.params）：
    // 此处订阅并派生 isLandscape，驱动场景过滤联动。
    _engineMediaMixingParams = MediaMixingStore.shared.state.params;
    _isLandscape = _deriveLandscape(_engineMediaMixingParams.value);
    _engineMediaMixingParams.addListener(_onEngineParamsChanged);
    if (_scenes.isEmpty) {
      this.currentSceneKey = '';
    } else if (sceneOf(this.currentSceneKey) == null) {
      final mode = _isLandscape ? SceneMode.landscape : SceneMode.portrait;
      SceneConfig? fallback;
      for (final scene in _scenes) {
        if (scene.modes == mode) {
          fallback = scene;
          break;
        }
      }
      this.currentSceneKey = (fallback ?? _scenes.first).key;
    }
    _selectTopmostSource();
  }

  /// 默认场景：横竖屏各一个「场景一」，key 独立、画面源布局互不共享。
  /// 预设布局场景的产品规则未定，暂不内置（后续需要时再扩展预置列表）。
  static const List<SceneConfig> defaultScenes = [
    SceneConfig(
      key: 'default-landscape',
      name: '场景一',
      icon: RemixIcons.live_line,
      modes: SceneMode.landscape,
    ),
    SceneConfig(
      key: 'default-portrait',
      name: '场景一',
      icon: RemixIcons.live_line,
      modes: SceneMode.portrait,
    ),
  ];

  /// 每个场景独立的画面源布局，初始为空（画面源由用户真实添加）。
  static Map<String, List<MediaSourceConfig>> defaultSources() {
    return {};
  }

  final List<SceneConfig> _scenes;
  final Map<String, List<MediaSourceConfig>> _sources;
  String currentSceneKey;

  /// 当前选中的画面源 id（列表高亮联动，后续预览画布选中态同源）。
  String? selectedSourceId;

  /// 引擎合流参数（横竖屏状态的唯一数据源）。
  late final ValueListenable<MediaMixingParams> _engineMediaMixingParams;

  /// 当前横竖屏模式（从引擎 params 派生，只读；切换请调
  /// MediaMixingStore.updateVideoEncoderParams）。
  late bool _isLandscape;
  int _idSeed = 0;

  bool get isLandscape => _isLandscape;

  static bool _deriveLandscape(MediaMixingParams params) {
    return params.videoEncoderParams.resolutionMode ==
        VideoResolutionMode.landscape;
  }

  /// 媒体源默认布局规则（产品定义）。
  ///
  /// 源真实尺寸 w×h 与混流分辨率 W×H 逐项比较：
  /// - 均不超出：按真实尺寸；
  /// - 任一维度超出：等比缩放 s = min(W/w, H/h)（高度超限时缩放后
  ///   高度正好占满混流分辨率高度）；
  /// 位置统一左上角（left=0, top=0）。
  ///
  /// 返回 MediaSourceConfig 布局四字段；尺寸未知 / 非法时返回 null
  /// （调用方回退模板布局）。
  ({double left, double top, double width, double ratio})?
      defaultLayoutForSource(double? srcW, double? srcH) {
    if (srcW == null || srcH == null || srcW <= 0 || srcH <= 0) {
      return null;
    }
    final enc = _engineMediaMixingParams.value.videoEncoderParams;
    final canvasW = enc.width.toDouble();
    final canvasH = enc.height.toDouble();
    if (canvasW <= 0 || canvasH <= 0) {
      return null;
    }
    final scale = (srcW <= canvasW && srcH <= canvasH)
        ? 1.0
        : math.min(canvasW / srcW, canvasH / srcH);
    return (
      left: 0.0,
      top: 0.0,
      width: srcW * scale / canvasW * 100,
      ratio: srcW / srcH,
    );
  }

  /// 引擎 params 变化 → 派生横竖屏模式变化 → 场景过滤联动。
  void _onEngineParamsChanged() {
    final derived = _deriveLandscape(_engineMediaMixingParams.value);
    if (derived == _isLandscape) {
      return;
    }
    _isLandscape = derived;
    // 当前场景在新模式下不可见时，切到第一个可见场景。
    if (visibleScenes.isNotEmpty &&
        visibleScenes.every((s) => s.key != currentSceneKey)) {
      currentSceneKey = visibleScenes.first.key;
      _selectTopmostSource();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _engineMediaMixingParams.removeListener(_onEngineParamsChanged);
    super.dispose();
  }

  List<SceneConfig> get scenes => List.unmodifiable(_scenes);

  /// 当前模式下可见的场景（modes 过滤）。
  List<SceneConfig> get visibleScenes {
    final mode = isLandscape ? SceneMode.landscape : SceneMode.portrait;
    return _scenes.where((s) => s.modes == mode).toList();
  }

  SceneConfig? sceneOf(String key) {
    for (final scene in _scenes) {
      if (scene.key == key) {
        return scene;
      }
    }
    return null;
  }

  SceneConfig? get currentScene => sceneOf(currentSceneKey);

  /// 当前场景画面源（数组顺序即叠放次序，末尾为最上层）。
  List<MediaSourceConfig> get currentSources =>
      List.unmodifiable(_sources[currentSceneKey] ?? const []);

  /// 列表展示顺序：倒序，最上层显示在列表顶部（OBS/PS 惯例）。
  List<MediaSourceConfig> get currentSourcesForDisplay =>
      currentSources.reversed.toList();

  void setCurrentScene(String key) {
    if (key == currentSceneKey || sceneOf(key) == null) {
      return;
    }
    currentSceneKey = key;
    _selectTopmostSource();
    notifyListeners();
  }

  /// 选中指定画面源（点击列表行 / 预览画布画面源）。
  void selectSource(String? id) {
    if (selectedSourceId == id) {
      return;
    }
    selectedSourceId = id;
    notifyListeners();
  }

  /// 选中当前场景最上层的可见画面源；无可见画面源时清空选中。
  void _selectTopmostSource() {
    final sources = _sources[currentSceneKey] ?? const <MediaSourceConfig>[];
    for (final source in sources.reversed) {
      if (source.visible) {
        selectedSourceId = source.id;
        return;
      }
    }
    selectedSourceId = null;
  }

  /// 选中项不在当前画面源列表中时，回退选中顶层可见项。
  void _ensureSelectionValid() {
    final sources = _sources[currentSceneKey] ?? const <MediaSourceConfig>[];
    if (sources.every((l) => l.id != selectedSourceId)) {
      _selectTopmostSource();
    }
  }

  void toggleSourceVisible(String id) {
    _mutateCurrentSources((sources) {
      final index = sources.indexWhere((l) => l.id == id);
      if (index >= 0) {
        sources[index] = sources[index].copyWith(visible: !sources[index].visible);
      }
    });
  }

  void removeSource(String id) {
    _mutateCurrentSources((sources) => sources.removeWhere((l) => l.id == id));
    _ensureSelectionValid();
    notifyListeners();
  }

  /// 列表拖拽排序（display 空间索引：列表顶部 = 最上层）。
  ///
  /// [newIndex] 遵循 ReorderableListView.onReorderItem 语义，
  /// 已按移除 [oldIndex] 项后的列表位置计算。
  void reorderDisplaySources(int oldIndex, int newIndex) {
    final sources = _sources[currentSceneKey];
    if (sources == null || sources.isEmpty) {
      return;
    }
    final display = sources.reversed.toList();
    final item = display.removeAt(oldIndex);
    display.insert(newIndex.clamp(0, display.length), item);
    sources
      ..clear()
      ..addAll(display.reversed);
    notifyListeners();
  }

  /// 添加画面源（假数据，纯 UI 联动，追加为最上层并选中）。
  void addSource(MediaSourceKind kind) {
    final sources = _sources.putIfAbsent(currentSceneKey, () => []);
    final source = _sourceTemplate(kind, sources);
    sources.add(source);
    selectedSourceId = source.id;
    notifyListeners();
  }

  /// 添加真实摄像头画面源（携带采集配置，追加为最上层并选中）。
  ///
  /// 返回新建的画面源，供 SceneEngineSync 以画面源 id 为 key 添加引擎源；
  /// 引擎添加失败时调用方通过 [removeSource] 回滚。
  MediaSourceConfig addCameraSource(CameraSourceConfig config) {
    final sources = _sources.putIfAbsent(currentSceneKey, () => []);
    final template = _sourceTemplate(MediaSourceKind.camera, sources);
    // 默认布局按采集分辨率套用默认尺寸规则（见 defaultLayoutForSource）。
    final layout = defaultLayoutForSource(
      config.width.toDouble(),
      config.height.toDouble(),
    );
    final source = MediaSourceConfig(
      id: template.id,
      kind: template.kind,
      name: config.deviceName.isEmpty ? template.name : config.deviceName,
      icon: template.icon,
      left: layout?.left ?? template.left,
      top: layout?.top ?? template.top,
      width: layout?.width ?? template.width,
      ratio: layout?.ratio ?? template.ratio,
      camera: config,
    );
    sources.add(source);
    selectedSourceId = source.id;
    notifyListeners();
    return source;
  }

  /// 更新摄像头画面源的美颜参数（美颜面板滑杆 / 开关实时回调）。
  void updateCameraBeauty(String id, CameraBeautySettings beauty) {
    _mutateCurrentSources((sources) {
      final index = sources.indexWhere((l) => l.id == id);
      if (index >= 0 && sources[index].camera != null) {
        sources[index] = sources[index].copyWith(
          camera: sources[index].camera!.copyWith(beauty: beauty),
        );
      }
    });
  }

  /// 更新摄像头画面源的采集配置（编辑弹窗保存）。
  void updateSourceCamera(String id, CameraSourceConfig config) {
    _mutateCurrentSources((sources) {
      final index = sources.indexWhere((l) => l.id == id);
      if (index >= 0) {
        sources[index] = sources[index].copyWith(
          name: config.deviceName.isEmpty ? sources[index].name : config.deviceName,
          camera: config,
        );
      }
    });
  }

  /// 添加屏幕 / 窗口共享画面源（默认布局按源真实尺寸套用规则）。
  MediaSourceConfig addScreenSource(ScreenSourceConfig config) {
    return _addConfiguredSource(
      MediaSourceKind.screen,
      config.sourceName,
      screen: config,
      sourceWidth: config.width?.toDouble(),
      sourceHeight: config.height?.toDouble(),
    );
  }

  /// 更新屏幕 / 窗口共享源配置（编辑弹窗保存）。
  void updateSourceScreen(String id, ScreenSourceConfig config) {
    _mutateCurrentSources((sources) {
      final index = sources.indexWhere((l) => l.id == id);
      if (index >= 0) {
        sources[index] = sources[index].copyWith(
          name: config.sourceName.isEmpty ? sources[index].name : config.sourceName,
          screen: config,
        );
      }
    });
  }

  /// 添加图片画面源（[sourceSize] 为图片真实像素尺寸，缺省回退模板）。
  MediaSourceConfig addImageSource(ImageSourceConfig config, {Size? sourceSize}) {
    return _addConfiguredSource(
      MediaSourceKind.image,
      _fileBaseName(config.path),
      image: config,
      sourceWidth: sourceSize?.width,
      sourceHeight: sourceSize?.height,
    );
  }

  /// 添加本地视频文件画面源。
  ///
  /// 真实分辨率要等引擎 contentSize 回投（TRTC onMediaSourceSizeChanged
  /// 链路），先用 640x360 占位并标记 [MediaSourceConfig.pendingAutoLayout]。
  MediaSourceConfig addVideoFileSource(VideoFileSourceConfig config) {
    return _addConfiguredSource(
      MediaSourceKind.videoFile,
      _fileBaseName(config.path),
      videoFile: config,
      sourceWidth: 640,
      sourceHeight: 360,
      pendingAutoLayout: true,
    );
  }

  /// 添加在线视频画面源（占位与自动布局同 [addVideoFileSource]）。
  MediaSourceConfig addOnlineVideoSource(OnlineVideoSourceConfig config) {
    return _addConfiguredSource(
      MediaSourceKind.onlineVideo,
      _onlineVideoName(config.url),
      onlineVideo: config,
      sourceWidth: 640,
      sourceHeight: 360,
      pendingAutoLayout: true,
    );
  }

  /// 更新图片源配置（编辑弹窗保存）。
  void updateSourceImage(String id, ImageSourceConfig config, {double? ratio}) {
    _mutateCurrentSources((sources) {
      final index = sources.indexWhere((l) => l.id == id);
      if (index >= 0) {
        sources[index] = sources[index].copyWith(
          name: _fileBaseName(config.path),
          ratio: ratio,
          image: config,
        );
      }
    });
  }

  /// 更新本地视频源配置（编辑弹窗保存）。
  void updateSourceVideoFile(String id, VideoFileSourceConfig config) {
    _mutateCurrentSources((sources) {
      final index = sources.indexWhere((l) => l.id == id);
      if (index >= 0) {
        sources[index] = sources[index].copyWith(
          name: _fileBaseName(config.path),
          videoFile: config,
        );
      }
    });
  }

  /// 画布编辑回写：更新画面源布局四字段（引擎 → UI 方向，
  /// 由 SceneEngineSync 监听 state.sources 调用）。
  ///
  /// fit（铺满画布）画面源被手动拖 / 缩后自动退出 fit，变为普通画面源
  /// （所见即所得）；同时清除 [MediaSourceConfig.pendingAutoLayout]（布局已
  /// 确定，视频源 contentSize 就绪后不再自动调整）。
  void updateSourceLayoutFromEngine(
    String id, {
    required double left,
    required double top,
    required double width,
    required double ratio,
  }) {
    _mutateCurrentSources((sources) {
      final index = sources.indexWhere((l) => l.id == id);
      if (index >= 0) {
        sources[index] = sources[index].copyWith(
          fit: false,
          left: left,
          top: top,
          width: width,
          ratio: ratio,
          pendingAutoLayout: false,
        );
      }
    });
  }

  /// 更新在线视频源配置（编辑弹窗保存）。
  void updateSourceOnlineVideo(String id, OnlineVideoSourceConfig config) {
    _mutateCurrentSources((sources) {
      final index = sources.indexWhere((l) => l.id == id);
      if (index >= 0) {
        sources[index] = sources[index].copyWith(
          name: _onlineVideoName(config.url),
          onlineVideo: config,
        );
      }
    });
  }

  /// 按类型模板创建一个携带引擎配置的画面源，追加为最上层并选中。
  ///
  /// [sourceWidth]/[sourceHeight] 为源真实像素尺寸（可为空），
  /// 用于按默认尺寸规则计算初始布局（见 [defaultLayoutForSource]）。
  MediaSourceConfig _addConfiguredSource(
    MediaSourceKind kind,
    String name, {
    ScreenSourceConfig? screen,
    ImageSourceConfig? image,
    VideoFileSourceConfig? videoFile,
    OnlineVideoSourceConfig? onlineVideo,
    double? sourceWidth,
    double? sourceHeight,
    bool pendingAutoLayout = false,
  }) {
    final sources = _sources.putIfAbsent(currentSceneKey, () => []);
    final template = _sourceTemplate(kind, sources);
    final layout = defaultLayoutForSource(sourceWidth, sourceHeight);
    final source = MediaSourceConfig(
      id: template.id,
      kind: template.kind,
      name: name.isEmpty ? template.name : name,
      icon: template.icon,
      fit: template.fit,
      left: layout?.left ?? template.left,
      top: layout?.top ?? template.top,
      width: layout?.width ?? template.width,
      ratio: layout?.ratio ?? template.ratio,
      screen: screen,
      image: image,
      videoFile: videoFile,
      onlineVideo: onlineVideo,
      pendingAutoLayout: pendingAutoLayout,
    );
    sources.add(source);
    selectedSourceId = source.id;
    notifyListeners();
    return source;
  }

  /// 文件路径 → 不含扩展名的文件名（画面源命名）。
  static String _fileBaseName(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  /// 在线视频 URL → 画面源名（路径末段，缺省用域名）。
  static String _onlineVideoName(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return '';
    }
    final segments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      return segments.last;
    }
    return uri.host;
  }

  /// 下一个可用的「自定义N」场景名（添加弹窗的默认名称建议）。
  String nextCustomSceneName() {
    final names = _scenes.map((s) => s.name).toSet();
    final strings = currentLiveKitStrings();
    var index = 1;
    while (names.contains(strings.sceneCustomSuggestion(index))) {
      index++;
    }
    return strings.sceneCustomSuggestion(index);
  }

  /// 添加自定义预设场景（modes 取当前横竖屏模式，初始无画面源）。
  void addScene(String name, IconData icon) {
    final key = 'scene-${_idSeed++}';
    _scenes.add(
      SceneConfig(
        key: key,
        name: name,
        icon: icon,
        modes: isLandscape ? SceneMode.landscape : SceneMode.portrait,
        customName: true,
      ),
    );
    _sources[key] = [];
    currentSceneKey = key;
    _selectTopmostSource();
    notifyListeners();
  }

  void renameScene(String key, String name) {
    final trimmed = name.trim();
    final index = _scenes.indexWhere((s) => s.key == key);
    if (index < 0 || trimmed.isEmpty) {
      return;
    }
    final source = _scenes[index];
    _scenes[index] = SceneConfig(
      key: source.key,
      name: trimmed,
      icon: source.icon,
      modes: source.modes,
      customName: true,
    );
    notifyListeners();
  }

  void duplicateScene(String key) {
    final index = _scenes.indexWhere((s) => s.key == key);
    if (index < 0) {
      return;
    }
    final source = _scenes[index];
    final newKey = 'scene-${_idSeed++}';
    _scenes.insert(
      index + 1,
      SceneConfig(
        key: newKey,
        name: currentLiveKitStrings()
            .sceneCopySuffix(_sceneDisplayNameCurrent(source)),
        icon: source.icon,
        modes: source.modes,
        customName: true,
      ),
    );
    _sources[newKey] = (_sources[key] ?? const [])
        .map((l) => l.copyWith(id: 'source-${_idSeed++}'))
        .toList();
    notifyListeners();
  }

  void deleteScene(String key) {
    // 产品规则：当前模式下至少保留一个场景——删掉最后一个可见场景会让
    // 场景区只剩「+」按钮（与 UI 层菜单项禁用联动，此处为兜底）。
    if (visibleScenes.length <= 1) {
      return;
    }
    _scenes.removeWhere((s) => s.key == key);
    _sources.remove(key);
    if (currentSceneKey == key) {
      if (visibleScenes.isNotEmpty) {
        currentSceneKey = visibleScenes.first.key;
      } else if (_scenes.isNotEmpty) {
        currentSceneKey = _scenes.first.key;
      }
      _selectTopmostSource();
    }
    notifyListeners();
  }

  MediaSourceConfig _sourceTemplate(MediaSourceKind kind, List<MediaSourceConfig> existing) {
    final strings = currentLiveKitStrings();
    final MediaSourceConfig template;
    switch (kind) {
      case MediaSourceKind.camera:
        template = MediaSourceConfig(
          id: '',
          kind: MediaSourceKind.camera,
          name: strings.sourceNameCamera,
          icon: RemixIcons.webcam_line,
          left: 66,
          top: 62,
          width: 26,
          ratio: 16 / 9,
        );
      case MediaSourceKind.screen:
        // 默认全宽置顶（非 fit：位置尺寸可编辑）；宽高比优先取源真实尺寸。
        template = MediaSourceConfig(
          id: '',
          kind: MediaSourceKind.screen,
          name: strings.sourceNameScreen,
          icon: RemixIcons.computer_line,
          left: 0,
          top: 0,
          width: 100,
          ratio: 16 / 9,
        );
      case MediaSourceKind.image:
        template = MediaSourceConfig(
          id: '',
          kind: MediaSourceKind.image,
          name: strings.sourceTypeImage,
          icon: RemixIcons.image_line,
          left: 8,
          top: 8,
          width: 16,
          ratio: 1,
        );
      case MediaSourceKind.onlineVideo:
        template = MediaSourceConfig(
          id: '',
          kind: MediaSourceKind.onlineVideo,
          name: strings.sourceTypeOnlineVideo,
          icon: RemixIcons.global_line,
          left: 30,
          top: 30,
          width: 40,
          ratio: 16 / 9,
        );
      case MediaSourceKind.videoFile:
        template = MediaSourceConfig(
          id: '',
          kind: MediaSourceKind.videoFile,
          name: strings.sourceTypeVideoFile,
          icon: RemixIcons.file_video_line,
          left: 30,
          top: 30,
          width: 40,
          ratio: 16 / 9,
        );
    }
    final sameNameCount = existing.where((l) => l.name == template.name).length;
    return template.copyWith(
      id: 'source-${_idSeed++}',
      name: sameNameCount == 0
          ? template.name
          : '${template.name} ${sameNameCount + 1}',
    );
  }

  void _mutateCurrentSources(void Function(List<MediaSourceConfig>) action) {
    final sources = _sources[currentSceneKey];
    if (sources == null) {
      return;
    }
    action(sources);
    notifyListeners();
  }
}
