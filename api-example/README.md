# AtomicXCore API 示例 Demo — Flutter

[English](./README_EN.md) | 中文

## 项目简介

本项目是 **AtomicXCore SDK** 的 Flutter 端 API 示例 Demo，通过四个渐进式阶段完整展示了从基础推拉流到复杂互动直播的全部核心功能。项目基于 Flutter 原生 Widget 体系 + `ValueListenable` 响应式状态管理构建，支持 Android 和 iOS 双平台，适合开发人员快速了解和集成 AtomicXCore SDK。

## 功能概览

| 阶段 | 功能模块 | 说明 |
|:---:|:---|:---|
| 1 | **BasicStreaming** 基础推拉流 | 直播创建/加入、摄像头/麦克风管理、视频渲染 |
| 2 | **Interactive** 实时互动 | 弹幕消息、礼物系统（含 SVGA 动画）、点赞、美颜、音效 |
| 3 | **CoGuest** 观众连线 | 观众申请上麦、主播邀请连线、麦位管理、多人视频 |
| 4 | **LivePK** 直播 PK 对战 | 跨房连线、PK 对战、实时积分、倒计时、战斗结果展示 |

> 四个阶段层层递进，每个后续阶段都包含前一阶段的全部功能并增加新能力。

## 技术栈

| 类别 | 技术 | 版本 |
|:---:|:---|:---|
| 框架 | Flutter | 3.29.3 |
| 语言 | Dart | 3.7.2 |
| 核心 SDK | AtomicXCore (`atomic_x_core`) | ^4.0.0 |
| 状态管理 | Flutter 原生 ValueNotifier / ValueListenableBuilder | — |
| 动画引擎 | svgaplayer_flutter | ^2.2.0 |
| 图片缓存 | cached_network_image | ^3.3.1 |
| 权限管理 | permission_handler | ^11.3.1 |
| 本地存储 | shared_preferences | ^2.5.3 |
| 加密工具 | crypto | ^3.0.6 |
| 国际化 | Flutter Localizations + intl | — |
| 代码规范 | flutter_lints | ^5.0.0 |

## 项目架构

### 架构模式

项目采用 **Store + ValueListenable 响应式架构**（类似 MVVM/Flux 混合模式）：

- **Store 层**：由 `atomic_x_core` SDK 提供，包含 `LoginStore`、`LiveListStore`、`DeviceStore`、`BarrageStore`、`GiftStore` 等全局单例或实例化 Store
- **状态暴露**：各 Store 通过 `xxxState` 属性暴露状态对象，字段类型为 `ValueListenable<T>`（即 Flutter 原生 `ValueNotifier`）
- **UI 绑定**：使用 `ValueListenableBuilder<T>` 在 Widget Tree 中进行精确的局部重建
- **事件回调**：SDK 提供 Listener 回调模式（如 `GiftListener`、`BattleListener` 等），通过 `addXxxListener` / `removeXxxListener` 注册
- **无第三方状态管理依赖**：不使用 Provider、Riverpod、Bloc 等，完全基于 Flutter 原生能力

### 目录结构

```
flutter/lib/
├── main.dart                                  # 应用入口（MaterialApp + 语言切换监听）
├── components/                                # 可复用 UI 组件层
│   ├── components.dart                        # 统一导出桶文件
│   ├── audio_effect_setting_widget.dart        # 音效设置面板（变声/混响/耳返）
│   ├── barrage_widget.dart                     # 弹幕消息列表 + 输入框
│   ├── beauty_setting_widget.dart              # 美颜设置面板（磨皮/美白/红润）
│   ├── co_host_user_list_widget.dart           # 可连线主播列表（分页加载）
│   ├── device_setting_widget.dart              # 设备管理面板（摄像头/麦克风/镜像/清晰度）
│   ├── gift_animation_widget.dart              # 礼物动画展示（SVGA 全屏 + 弹幕滑动）
│   ├── gift_panel_widget.dart                  # 礼物选择面板（分页网格 + 发送）
│   ├── like_button.dart                        # 点赞按钮（爱心粒子贝塞尔曲线动效）
│   ├── localized_manager.dart                  # 本地化管理器（中英文切换 + 持久化）
│   ├── permission_helper.dart                  # 运行时权限封装（相机/麦克风）
│   ├── role.dart                               # 角色枚举（ANCHOR/AUDIENCE）
│   └── setting_panel_controller.dart           # 通用半屏浮层容器
├── debug/
│   └── generate_test_user_sig.dart             # 调试用 UserSig 本地生成工具
├── l10n/                                       # 国际化资源
│   ├── app_en.arb                              # 英文字符串（模板文件，355 条）
│   ├── app_zh.arb                              # 简体中文字符串（212 条）
│   ├── app_localizations.dart                  # 生成的 l10n 入口
│   ├── app_localizations_en.dart               # 生成的英文实现
│   └── app_localizations_zh.dart               # 生成的中文实现
└── scenes/                                     # 业务场景页面层
    ├── login/
    │   ├── login_page.dart                     # 用户登录页
    │   └── profile_setup_page.dart             # 资料完善页（昵称 + 头像选择）
    ├── feature_list/
    │   └── feature_list_page.dart              # 功能列表首页（4 个阶段入口卡片）
    ├── basic_streaming/
    │   └── basic_streaming_page.dart           # 阶段 1: 基础推拉流
    ├── interactive/
    │   └── interactive_page.dart               # 阶段 2: 实时互动
    ├── co_guest/
    │   └── co_guest_page.dart                  # 阶段 3: 观众连线
    └── live_pk/
        └── live_pk_page.dart                   # 阶段 4: 直播 PK 对战
```

### 应用流程

```
LoginPage (输入 UserID → SDK 登录)
  │
  ├─ 昵称为空 ──→ ProfileSetupPage (设置昵称 + 选择头像)
  │                    │
  │                    ▼
  └─ 昵称已设置 ──→ FeatureListPage (4 个阶段入口卡片)
                       │
                       ├─ 选择阶段 → 角色选择 BottomSheet
                       │   ├─ 主播 → 直接进入对应页面
                       │   └─ 观众 → 输入房间号 Dialog → 进入对应页面
                       │
                       ├──→ BasicStreamingPage  (阶段 1)
                       ├──→ InteractivePage     (阶段 2)
                       ├──→ CoGuestPage         (阶段 3)
                       └──→ LivePKPage          (阶段 4)
```

### Store 类型与生命周期

| Store | 类型 | 使用场景 |
|:---|:---|:---|
| `LoginStore.shared` | 全局单例 | 登录、用户信息设置 |
| `LiveListStore.shared` | 全局单例 | 直播房间生命周期管理 |
| `DeviceStore.shared` | 全局单例 | 摄像头/麦克风/视频质量 |
| `BaseBeautyStore.shared` | 全局单例 | 美颜调节 |
| `AudioEffectStore.shared` | 全局单例 | 音效/变声/耳返 |
| `BarrageStore.create(liveID)` | 按房间实例化 | 弹幕收发 |
| `GiftStore.create(liveID)` | 按房间实例化 | 礼物收发 |
| `LikeStore.create(liveID)` | 按房间实例化 | 点赞互动 |
| `CoGuestStore.create(liveID)` | 按房间实例化 | 观众连线管理 |
| `CoHostStore.create(liveID)` | 按房间实例化 | 跨房连线管理 |
| `BattleStore.create(liveID)` | 按房间实例化 | PK 对战管理 |
| `LiveAudienceStore.create(liveID)` | 按房间实例化 | 观众列表 |
| `LiveSeatStore.create(liveID)` | 按房间实例化 | 麦位管理 |

## AtomicXCore SDK API 使用说明

### 阶段 1：BasicStreaming — 基础推拉流

| Store | 关键 API | 功能 |
|:---|:---|:---|
| `LoginStore` | `login()`, `setSelfInfo()`, `loginState` | 用户登录与状态管理 |
| `LiveListStore` | `createLive()`, `joinLive()`, `endLive()`, `leaveLive()` | 直播房间生命周期管理 |
| `DeviceStore` | `openLocalCamera()`, `openLocalMicrophone()`, `switchCamera()` | 本地设备控制 |
| `LiveCoreWidget` | `LiveCoreController.create(CoreViewType)` | 视频渲染 Widget |

### 阶段 2：Interactive — 实时互动

| Store | 关键 API | 功能 |
|:---|:---|:---|
| `BarrageStore` | `sendTextMessage()`, `barrageState.messageList` | 弹幕消息收发 |
| `GiftStore` | `sendGift()`, `refreshUsableGifts()`, `setLanguage()` | 礼物系统 |
| `LikeStore` | `sendLike()`, `addLikeListener()` | 点赞互动 |
| `BaseBeautyStore` | `setSmoothLevel()`, `setWhitenessLevel()`, `setRuddyLevel()` | 美颜调节 |
| `AudioEffectStore` | `setAudioChangerType()`, `setAudioReverbType()`, `setVoiceEarMonitorEnable()` | 音效与耳返 |

### 阶段 3：CoGuest — 观众连线

| Store | 关键 API | 功能 |
|:---|:---|:---|
| `CoGuestStore` | `applyForSeat()`, `inviteToSeat()`, `acceptApplication()`, `disconnect()` | 连线请求管理 |
| `LiveSeatStore` | `openRemoteCamera()`, `kickUserOutOfSeat()` | 麦位与远端设备管理 |
| `LiveAudienceStore` | `fetchAudienceList()` | 观众列表 |
| `LiveCoreWidget` | `videoWidgetBuilder` | 自定义连线用户视频覆盖层 |

### 阶段 4：LivePK — 直播 PK 对战

| Store | 关键 API | 功能 |
|:---|:---|:---|
| `CoHostStore` | `requestHostConnection()`, `acceptHostConnection()`, `exitHostConnection()` | 跨房连线管理 |
| `BattleStore` | `requestBattle()`, `acceptBattle()`, `exitBattle()`, `battleState` | PK 对战管理与实时积分 |
| `LiveListStore` | `fetchLiveList()` | 获取可连线主播列表 |

## 环境要求

- **Flutter**: 3.29.3（Dart SDK 3.7.2）
- **Android**: minSdkVersion 21+
- **iOS**: iOS 12.0+
- **开发工具**: Android Studio / VS Code + Flutter 插件

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd atomic-api-example/flutter
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 配置 SDK 凭证

编辑 `lib/debug/generate_test_user_sig.dart`，填入你的腾讯云应用凭证：

```dart
const int SDKAPPID = 0;          // 替换为你的 SDKAPPID
const String SECRETKEY = '';      // 替换为你的 SECRETKEY
```

> ⚠️ **安全提示**: `SECRETKEY` 仅用于本地调试。生产环境中，UserSig 必须由后端服务生成，切勿将 SECRETKEY 嵌入客户端发布包中。

### 4. 运行

```bash
# Android
flutter run -d android

# iOS
cd ios && pod install && cd ..
flutter run -d ios
```

## 权限说明

### Android

| 权限 | 用途 |
|:---|:---|
| `CAMERA` | 摄像头采集 |
| `RECORD_AUDIO` | 麦克风采集 |
| `MODIFY_AUDIO_SETTINGS` | 音频设置调节 |

### iOS

| 权限 | 用途 |
|:---|:---|
| `NSCameraUsageDescription` | 直播视频采集 |
| `NSMicrophoneUsageDescription` | 直播音频采集 |

## 国际化支持

项目支持中英文双语切换，采用 Flutter 官方 `flutter_localizations` + ARB 方案：

| 文件 | 说明 |
|:---|:---|
| `lib/l10n/app_en.arb` | 英文字符串（模板文件，355 条） |
| `lib/l10n/app_zh.arb` | 简体中文字符串（212 条） |

- 默认跟随系统语言（中文系统 → zh，其他 → en）
- 用户可在功能列表页的设置菜单中手动切换语言
- 语言偏好通过 `SharedPreferences` 持久化保存
