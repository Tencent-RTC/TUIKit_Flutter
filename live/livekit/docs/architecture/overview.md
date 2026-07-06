# Architecture Overview

> 给「人」看的高层架构文档。Agent 路由请用 `.codebuddy/rules/project.md`。

## 1. 项目定位

`tencent_live_uikit` 是腾讯云直播 UIKit 的 Flutter 实现，基于 `TUIRoomEngine`（底层 TRTC + IM）。

它提供两个主场景的开箱即用 UI：

- **视频直播**（`live_stream`）：主播开播、观众观看、连麦、跨房 PK
- **语音聊天室**（`voice_room`）：多人语音、麦位管理、礼物互动

## 2. 技术栈

| 层 | 技术 |
|---|---|
| UI | Flutter Widget + `ValueListenableBuilder` |
| 状态 | `ValueNotifier<T>` / `StreamController.broadcast()` |
| 业务编排 | Manager + Dart Extension |
| 引擎接入 | Service 封装 `TUIRoomEngine` |
| i18n | Flutter `intl` + ARB |
| 主题 | `tuikit_atomic_x` 原子设计 |

## 3. 三层架构

```
┌────────────────────────────────────────────────────┐
│                    Widget (UI)                      │
│         ValueListenableBuilder / StreamBuilder      │
└──────────────────────┬─────────────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────────────┐
│                Manager (Business Logic)             │
│      LiveStreamManager / VoiceRoomManager / ...     │
│  - 编排 State 更新                                  │
│  - 调用 Service                                     │
│  - 通过 Context 与子 Manager 通信（WeakReference）   │
│  - 大类按角色拆为多个 Extension                     │
└──────────────────────┬─────────────────────────────┘
                       │
              ┌────────┴────────┐
              ▼                 ▼
┌──────────────────────┐  ┌──────────────────────┐
│  State (Reactive)    │  │  Service (API Wrap)  │
│  ValueNotifier<T>    │  │  Wraps TUIRoomEngine │
│  Stream broadcast    │  │  Per-domain split    │
└──────────────────────┘  └──────────┬───────────┘
                                     │
                                     ▼
                          ┌──────────────────────┐
                          │  TUIRoomEngine        │
                          │  (TRTC + IM)          │
                          └──────────────────────┘
```

### 关键约束

1. **Widget 不写业务逻辑**，只负责渲染和事件转发
2. **Manager 不直接调引擎**，必须经 Service
3. **跨 Manager 通信走 Context**，引用必须 `WeakReference`
4. **Engine 事件**通过 Observer 接收 → 分发给对应 Manager → 更新 State → UI 重建

## 4. 引擎事件流

```
TUIRoomEngine event
       │
       ▼
RoomEngineObserver / LiveConnectionObserver / LiveBattleObserver
       │
       ▼
Dispatch to Manager
       │
       ▼
Update State (ValueNotifier.value = ...)
       │
       ▼
ValueListenableBuilder rebuilds Widget
```

Observer 文件位于 `lib/{module}/manager/observer/`。

## 5. 依赖关系

```
tencent_live_uikit (本包)
   │
   ├── tuikit_atomic_x       ← 颜色、主题、字体
   ├── atomic_x_core         ← 通用工具、基础类
   ├── live_uikit_barrage    ← 弹幕组件
   ├── live_uikit_gift       ← 礼物组件
   ├── te_beauty_kit         ← 美颜
   │
   ├── tencent_rtc_sdk       ← RTC 引擎
   ├── tencent_cloud_chat_sdk← IM 信令
   └── tencent_cloud_uikit_core
```

⚠️ 上方 5 个本地依赖通过 `path:` 引用，**不要替换为 pub.dev 版本**。

## 6. 模块速览

| 模块 | 简介 |
|---|---|
| `live_stream/` | 视频直播全流程 |
| `voice_room/` | 语音聊天室 |
| `seat_grid_widget/` | 麦位网格通用组件 |
| `component/` | 跨场景共享组件（礼物、悬浮窗、网络信息等） |
| `common/` | 基础设施（i18n / 日志 / 平台桥接 / 资源 / 适配） |

详细文件级导航见 [`module-map.md`](./module-map.md)。

## 7. 入口文件

```dart
// lib/tencent_live_uikit.dart
export 'live_stream/...';
export 'voice_room/...';
export 'seat_grid_widget/...';
// ...
```

只有从此处导出的符号才属于 Public API。

## 8. 多语言

- 模板：`lib/common/language/intl_en.arb`
- 支持：英 / 简中 / 繁中 / 日 / 韩
- 每个 key 必须 5 个文件同步

详见 `.codebuddy/rules/i18n.md`。

## 9. 进一步阅读

| 主题 | 文档 |
|---|---|
| 文件级导航 | `module-map.md` |
| 状态管理细节 | `.codebuddy/skills/tencent-live-uikit/references/state_management.md` |
| 颜色主题用法 | `.codebuddy/skills/tencent-live-uikit/references/tuikit_atomic_x.md` |
