# Video Player 组件使用说明

## 概述

Video Player 组件提供了两种视频播放方式：
1. **全屏原生播放器** - 使用 `VideoPlayer.play()` 启动原生全屏播放
2. **内嵌播放器 Widget** - 使用 `VideoPlayerWidget` 在 Flutter UI 中嵌入播放

## 技术架构

```
┌─────────────────────────────────────────────────────┐
│                    Flutter Dart                      │
├─────────────────────────────────────────────────────┤
│  VideoPlayer.play()    │   VideoPlayerWidget        │
│  (MethodChannel)       │   (PlatformView)           │
└──────────┬─────────────┴───────────┬────────────────┘
           │                         │
           ▼                         ▼
┌──────────────────────┐   ┌─────────────────────────┐
│  Android Platform    │   │   iOS Platform          │
├──────────────────────┤   ├─────────────────────────┤
│ VideoPlayerActivity  │   │ AVPlayerViewController  │
│ (ExoPlayer)          │   │ (AVKit)                 │
│                      │   │                         │
│ VideoView.kt         │   │ VideoPlayerPlatformView │
│ (Compose UI)         │   │ (UIKit + AVPlayer)      │
└──────────────────────┘   └─────────────────────────┘
```

## 场景 1: 全屏原生播放

### 用法

```dart
import 'package:tuikit_atomic_x/video_player/video_player.dart';

// 创建视频数据
final video = VideoData(
  localPath: '/path/to/video.mp4',
  width: 1920,
  height: 1080,
  duration: 120, // 可选，单位：秒
);

// 播放视频
await VideoPlayer.play(
  context,
  video: video,
);
```

### 特点

- ✅ 原生性能，流畅播放
- ✅ 自动适配屏幕尺寸
- ✅ 完整的播放控制（播放/暂停/进度条/时间显示）
- ✅ 自动生命周期管理
- ✅ Android 使用 ExoPlayer，iOS 使用 AVPlayerViewController

### 适用场景

- 消息列表中点击视频消息
- 需要全屏沉浸式播放体验
- 不需要与其他 UI 元素混合

## 场景 2: 内嵌播放器 Widget

### 用法

```dart
import 'package:tuikit_atomic_x/video_player/video_player.dart';
import 'package:tuikit_atomic_x/video_player/video_player_widget.dart';

// 在 PageView 或其他容器中使用
PageView.builder(
  itemCount: mediaItems.length,
  itemBuilder: (context, index) {
    final item = mediaItems[index];
    
    if (item.isVideo) {
      return VideoPlayerWidget(
        video: VideoData(
          localPath: item.videoPath,
          width: item.width,
          height: item.height,
        ),
        onClose: () {
          // 处理关闭事件
          Navigator.pop(context);
        },
      );
    } else {
      return Image.file(File(item.imagePath));
    }
  },
);
```

### 特点

- ✅ 支持嵌入任何 Flutter Widget 树
- ✅ 使用原生平台视图（PlatformView）
- ✅ Android 使用 Compose VideoView，iOS 使用 AVPlayer
- ✅ 完整的播放控制
- ✅ 可与图片等元素混合在 PageView 中

### 适用场景

- ImageViewer 的 PageView 中混合图片和视频
- 需要在 Flutter UI 中嵌入视频
- 与其他 Widget 组合使用

## VideoData 数据结构

```dart
class VideoData {
  final String? localPath;       // 本地文件路径
  final String? url;              // 网络 URL（可选）
  final String? snapshotLocalPath; // 缩略图本地路径（可选）
  final String? snapshotUrl;      // 缩略图 URL（可选）
  final int duration;             // 视频时长（秒）
  final int width;                // 视频宽度
  final int height;               // 视频高度
}
```

### 关键属性

- `videoPath` - 自动选择 `localPath` 或 `url`
- `hasLocalFile` - 检查本地文件是否存在

## 平台实现细节

### Android

#### 全屏播放器

**文件**: `VideoPlayerActivity.kt`

- 使用 Jetpack Compose + ExoPlayer
- 全屏 Activity，沉浸式体验
- 自动处理生命周期

#### 内嵌播放器

**文件**: `VideoView.kt` + `VideoPlayerViewFactory.kt`

- Compose UI 组件
- 注册为 PlatformView: `io.trtc.tuikit.atomicx/video_player_view`
- 完整的播放控制（播放/暂停/进度条/拖拽）
- 自动适配宽高比

### iOS

#### 全屏播放器

**文件**: `VideoPlayer.swift`

- 使用 AVPlayerViewController
- 模态全屏展示
- 原生播放控制

#### 内嵌播放器

**文件**: `VideoPlayerViewFactory.swift` + `VideoPlayerPlatformView`

- 使用 AVPlayer + AVPlayerLayer
- 注册为 PlatformView: `io.trtc.tuikit.atomicx/video_player_view`
- 自定义播放控制

## 与第三方 video_player 的对比

| 特性 | 自实现 VideoPlayer | 第三方 video_player |
|------|-------------------|---------------------|
| 全屏播放 | ✅ 原生 Activity/ViewController | ❌ 需要自己实现全屏逻辑 |
| 内嵌播放 | ✅ PlatformView | ✅ Texture |
| 包大小 | ✅ 无额外依赖 | ❌ 增加包大小 |
| 性能 | ✅ 100% 原生 | ⚠️ 经过 Flutter 渲染层 |
| 自定义 UI | ✅ 直接修改原生代码 | ❌ 受限于 Flutter UI |
| 生命周期管理 | ✅ 原生自动管理 | ⚠️ 需要手动管理 |

## 注意事项

### 1. 文件路径格式

Android 和 iOS 都使用**绝对路径**：

```dart
// ✅ 正确
localPath: '/data/user/0/com.example/files/video.mp4'

// ❌ 错误
localPath: 'file:///data/user/0/com.example/files/video.mp4'
```

平台层会自动处理 URI 转换。

### 2. 视频格式支持

- **Android**: MP4, MKV, WebM (ExoPlayer 支持)
- **iOS**: MP4, MOV, M4V (AVPlayer 支持)

建议使用 **MP4 (H.264)** 以获得最佳兼容性。

### 3. 权限要求

**无需额外权限**，因为：
- 视频文件位于应用私有目录
- Android 不需要 `READ_EXTERNAL_STORAGE`
- iOS 不需要相册权限

### 4. 内存管理

- 全屏播放器：Activity/ViewController 销毁时自动释放
- 内嵌播放器：Widget dispose 时自动释放
- 无需手动调用清理方法

## 调试

### Android

查看 ExoPlayer 日志：

```bash
adb logcat | grep "ExoPlayer\|VideoPlayer"
```

### iOS

查看 AVPlayer 日志：

```bash
# Xcode Console 中搜索 "VideoPlayer"
```

### Flutter

启用详细日志：

```dart
debugPrint('VideoPlayer.play: $videoPath');
```

## 常见问题

### Q: VideoPlayerWidget 显示黑屏？

A: 检查：
1. 视频文件是否存在：`video.hasLocalFile`
2. 视频路径格式是否正确（绝对路径）
3. 视频格式是否支持

### Q: 视频播放卡顿？

A: 原因可能是：
1. 视频分辨率过高（建议 1080p 以下）
2. 视频码率过高（建议 < 5Mbps）
3. 设备性能不足

### Q: PageView 滑动时视频继续播放？

A: 这是正常行为。如需暂停，监听 PageView 的 `onPageChanged`：

```dart
PageView.builder(
  onPageChanged: (index) {
    // 切换页面时，VideoPlayerWidget 会自动 dispose
  },
)
```

## 示例代码

完整示例请参考：

- `image_viewer_widget.dart` - 图片/视频混合 PageView
- `video_message_widget.dart` - 消息列表中的视频消息

## 版本历史

- v1.0.0 (2025-11-28)
  - 初始版本
  - 支持全屏和内嵌两种播放模式
  - 100% 使用原生平台实现，移除第三方依赖
