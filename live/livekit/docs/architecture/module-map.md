# Module Map — `lib/` 文件级导航

> 给「人」和「Agent」找文件用。约 219 个 dart + 5 个 arb，按场景定位最快。

## 总览

```
lib/
├── tencent_live_uikit.dart        ← Public API 入口（仅这里 export 的才是公开 API）
├── live_identity_generator.dart   ← 用户身份生成工具
├── live_info_utils.dart           ← 直播信息工具
├── live_navigator_observer.dart   ← 路由观察者
│
├── live_stream/        ← 视频直播
├── voice_room/         ← 语音聊天室
├── seat_grid_widget/   ← 通用麦位网格
├── component/          ← 跨场景共享组件
└── common/             ← 基础设施
```

---

## 1. `live_stream/` — 视频直播

```
live_stream/
├── live_define.dart      ← 模块内类型定义
├── api/                  ← 对外 API
├── manager/              ← 业务管理（11 文件，按角色拆 Extension）
│   └── observer/         ← TUIRoomEngine 事件接收
├── state/                ← 响应式状态（RoomState / UserState / MediaState / ...）
└── features/             ← 子功能（72 文件，按交互能力拆分）
    ├── live_room_anchor_widget.dart    ← 主播端入口（普通版）
    ├── live_room_anchor_overlay.dart   ← 主播端入口（悬浮窗版）
    ├── live_room_audience_widget.dart  ← 观众端入口（普通版）
    └── live_room_audience_overlay.dart ← 观众端入口（悬浮窗版）
```

**关键查询**：

| 你在找... | 去这里 |
|---|---|
| 主播/观众对外入口 Widget | `features/live_room_{anchor,audience}_{widget,overlay}.dart` |
| 主播开播逻辑 | `manager/live_stream_manager_anchor.dart`（或 `_with_anchor.dart`） |
| 观众观看逻辑 | `manager/live_stream_manager_audience.dart` |
| 房间/媒体/用户状态 | `state/` |
| 连麦 / PK 实现 | `features/`（按子功能浏览） |
| Engine 事件分发 | `manager/observer/` |
| 对外暴露的接口 | `api/` |

**业务流程**：

- **主播流程**：`AnchorPrepareWidget`（预览/设置/美颜） → `AnchorBroadcastWidget`（直播中） → `EndStatisticsWidget`（结束统计）
- **观众流程**：`LiveListWidget`（列表） → `AudienceWidget`（观看/弹幕/礼物/申请连麦）

**互动功能对照**：

| 功能 | Manager | State |
|---|---|---|
| 连麦 | `CoGuestManager` | `CoGuestState` |
| 跨房连线 | `CoHostManager` | `CoHostState` |
| PK 对战 | `BattleManager` | `BattleState` |
| 悬浮窗 | `FloatWindowManager` | `FloatWindowState` |

---

## 2. `voice_room/` — 语音聊天室

```
voice_room/
├── voice_room_widget.dart      ← 主入口 Widget（普通版）
├── voice_room_overlay.dart     ← 主入口 Widget（悬浮窗版）
├── manager/                    ← 业务管理
├── widget/                     ← 子 Widget（22 个）
└── index.dart                  ← 对外导出
```

**关键查询**：

| 你在找... | 去这里 |
|---|---|
| 进入语音房（普通/悬浮） | `voice_room_widget.dart` / `voice_room_overlay.dart` |
| 麦位 UI | `widget/`（搭配 `seat_grid_widget/`） |
| 业务逻辑 | `manager/` |

---

## 3. `seat_grid_widget/` — 麦位网格通用组件

被 `voice_room` 复用，也可独立使用。常见 N 种布局（1v1、3 麦、6 麦、9 麦…）。

修改注意：保持向后兼容，避免破坏现有调用方。

---

## 4. `component/` — 跨场景共享组件

```
component/
├── audience_list/      ← 观众列表
├── audio_effect/       ← 音效
├── beauty/             ← 美颜面板（依赖 te_beauty_kit）
├── bgm/                ← 背景音乐面板
├── float_window/       ← 悬浮窗
├── gift_access/        ← 礼物入口（依赖 live_uikit_gift）
├── live_info/          ← 直播间信息卡
├── network_info/       ← 网络状态展示
└── index.dart
```

**判断要点**：

- 同一组件被 `live_stream` 和 `voice_room` 都用 → 放 `component/`
- 仅一个场景用 → 放该场景的 `widget/` 下

---

## 5. `common/` — 基础设施

```
common/
├── boot/         ← 启动 / 初始化
├── constants/    ← 常量（颜色 key、尺寸、超时等）
├── error/        ← 错误码与处理
├── language/     ← i18n（5 个 arb + 生成的 dart）
├── logger/       ← 日志封装（替代 print）
├── platform/     ← 平台桥接（method channel）
├── reporter/     ← 数据埋点
├── resources/    ← 图片 / 字体资源加载
├── screen/       ← 屏幕适配
├── selector/     ← 通用选择器
├── widget/       ← 通用 Widget（11 个，如按钮、对话框）
└── index.dart
```

**关键查询**：

| 你在找... | 去这里 |
|---|---|
| 加日志 | `logger/` 下的 `Logger` 类 |
| 新增错误码 | `error/` |
| 新增 i18n 文案 | `language/intl_*.arb`（5 个都要改） |
| 加图片资源 | `resources/`（同时更新 `assets/images/` 与 `pubspec.yaml`） |
| 屏幕尺寸适配 | `screen/` |
| 通用按钮 / 对话框 | `widget/` |

---

## 6. 入口文件 `tencent_live_uikit.dart`

**判断 Public API 的唯一标准**：

```dart
// lib/tencent_live_uikit.dart
export 'live_stream/api/...';
export 'voice_room/index.dart';
export 'component/index.dart';
// ...
```

只要这里没 export，就属于内部实现，**可以自由重构**。

新增公开 API 时务必同步更新此文件，并阅读 `.codebuddy/rules/api-design.md`。

---

## 7. 文件命名速查

| 看到这种文件名 | 含义 |
|---|---|
| `xxx_manager.dart` | 业务编排类 |
| `xxx_manager_with_yyy.dart` | Manager 的 Extension（按角色拆分） |
| `xxx_state.dart` | 响应式状态类 |
| `xxx_service.dart` | Engine API 封装 |
| `xxx_observer.dart` | Engine 事件接收者 |
| `xxx_widget.dart` | UI 组件 |
| `xxx_overlay.dart` | 悬浮窗形态 |
| `index.dart` | 目录导出聚合 |
| `intl_*.arb` | i18n 文案 |

---

## 8. 找文件的推荐路径

1. **先想场景**：直播 → `live_stream/`，语音房 → `voice_room/`，跨场景 → `component/`，基础设施 → `common/`
2. **再想角色**：UI → `widget/`，状态 → `state/`，业务 → `manager/`，引擎 → `service/` 或 `manager/observer/`
3. **找不到**：用 IDE 全局搜索文件名片段，或搜索类名
