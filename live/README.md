# TUILiveKit Flutter

`flutter/live` 使用一套 Dart 实现覆盖 iOS 与 Android。组件声明 `atomic_x_core: ^5.2.2`，接入 App 固定使用 pub.dev 的 `atomic_x_core: 5.2.2`，原生依赖由 CocoaPods / Maven 解析，构建机不需要仓库外的本地 SDK。

接入 App、Flutter App framework 与 Pods 的最低部署版本统一为 iOS 15。`ios/Flutter/Debug.xcconfig` 将 Debug 模拟器架构限定为本机 `NATIVE_ARCH_ACTUAL`，避开 Flutter 3.22 在新 Xcode 下同时校验 arm64/x86_64 的问题；真机架构不受影响。Android App 显式依赖 `LiteAVSDK_Professional:13.5.0.20670`，保证本地 AtomicEngine 联调所需的 TRTC native 符号，不回落到旧13.2。

本机联调可在 `tui_live_kit/` 和 `live_kit_access/` 各自创建被忽略的 `pubspec_overrides.yaml`，例如：

```yaml
dependency_overrides:
  atomic_x_core:
    path: /path/to/atomicengine
  meta: 1.12.0
```

iOS 如需与仓库内原生工程共用 SDK，再创建被忽略的 `live_kit_access/ios/SDKConfig.local.yml`：

```yaml
atomic_x_core_path: ../../../../ios/live/SDK/AtomicXCore
```

该目录必须包含 `AtomicXCore.podspec` 和支持目标架构的 `AtomicXCore.xcframework`。没有此配置文件时使用线上依赖。历史联调组合为 Dart 包 5.1.0 与原生包 5.2.0.110；切回线上模式后不保留本地绑定，版本号与路径以实际覆盖配置为准。Android本地插件如使用flatDir依赖，应将配套 `atomicengine-release.aar` 放在被忽略的 `live_kit_access/android/app/libs/`。不提交SDK二进制或机器路径。

切换后重新执行两处 `flutter pub get`，iOS再执行 `pod install`。本机覆盖会改变Access的依赖锁文件，提交时应以无覆盖配置的线上解析结果为准。恢复线上模式时移走上述忽略配置、重新解析依赖并构建。

`tui_live_kit` 是 Flutter plugin：除 Dart 实现外自带 `android/`、`ios/` 承载层，只封装 AtomicXCore 未覆盖、且产品范围实际需要的系统能力（当前为系统热状态和网络类型）。接入方无需额外配置；改动承载层后需要重新 `flutter pub get`，iOS 还要 `pod install`。Dart 包名为 `tencent_live_uikit`，iOS podspec 文件名与 `s.name` 必须同为 `tencent_live_uikit`；目录仍为 `tui_live_kit/`。

## 工程组成

```text
flutter/live/
├── tui_live_kit/      # 直播 UI 组件 Package
└── live_kit_access/   # 接入验证 App
```

图标与矢量素材从 Ardot「LiveKit视觉交互」按节点直接导出，代码统一用 `assets/<name>.png` 引用，不再使用 `assets/images/` 子目录。Common/Pusher 已核对的原图保留 `tui_live_kit/assets/` 下的 1x、`2.0x/`、`3.0x/` 资源，由 Flutter 按屏幕密度选择；`assets/source/` 的导出清单记录节点、像素与 SHA256。其余上游资源沿用整理后的根目录位置，接入 App 仅声明 `assets/`。显示槽位按当前 iOS 实现核对，保留素材原始画布和宽高比；不从 iOS 资源转换、不重新绘制近似素材。

`package:tencent_live_uikit/tencent_live_uikit.dart` 公开导出 `LiveListView`、`PlayerView`、`PusherView` 三个入口。`LiveListView` 和 `PlayerView` 均采用 Widget + Controller：前者负责编排 Feed、分页、预加载与滑动进房，后者可单独承载一个直播间，也被 Feed 内部复用。接入层的两列直播选择列表位于 `live_kit_access/lib/live_list/live_select_list_view.dart`（`LiveSelectListView`）。内部代码位置与调用链见 [CODE_MAP.md](CODE_MAP.md)，当前复刻任务见 [跨端复刻计划](../../docs/task/flutter/cross-platform-ui-plan-flutter.md)。

## 环境与依赖

- Dart SDK `>=3.4.3 <4.0.0`；`tui_live_kit` 要求 Flutter `>=3.10.0`
- 直播能力：组件 `atomic_x_core: ^5.3.0`，接入 App `atomic_x_core: 5.3.0`；本机SDK联调通过上述忽略配置覆盖
- 观众关注关系：`tencent_cloud_chat_sdk: ^9.0.7652`（当前解析 `9.0.7652+1`）
- 摄像头 / 麦克风权限：`permission_handler: ^11.3.1`
- 入口 userID 持久化：`shared_preferences: ^2.3.2`（首次启动生成 7 位随机值，用户修改后下次启动复用）
- `tui_live_kit` 只以仓库内相对 path 被 `live_kit_access` 引用

当前本机与构建机使用 Flutter 3.22.2（Dart 3.4.3）。该版本把 `meta` 钉在 1.12.0，而 `atomic_x_core` 5.x 声明 `meta ^1.15.0`，因此两个 pubspec 都带一条 `dependency_overrides: meta: 1.12.0`（实际只用到 1.12 已有的注解，Android 与 iOS 均已编译通过）。构建机升级到 Flutter `>=3.24` 后可以直接删除该 override。颜色透明度使用 `withOpacity`，CupertinoSwitch 使用 `activeColor`，兼容当前 Flutter 3.22。

Dart 插件升级后，若 CocoaPods 报 `TXIMSDK_Plus_iOS_XCFramework` 与锁文件不兼容，应在 `live_kit_access/ios` 执行 `pod update TXIMSDK_Plus_iOS_XCFramework --no-repo-update`，同步插件实际声明的原生版本；Dart 与原生版本号不一定相同。

原生依赖仍走各自的包管理器：iOS 由 CocoaPods 解析 `AtomicXCore` 及其 `TXLiteAVSDK_Professional`、`TXIMSDK_Plus_iOS_XCFramework` 依赖；Android 由 Gradle 从 Maven 拉对应 AAR。

礼物发送与展示位于组件内部 `common/gift/send`、`common/gift/display`，统一播放器位于 `display/playback`：SVGA 使用 `svgaplayer_flutter ^2.2.0`，MP4 使用 `flutter_effect_player ^3.4.1`。不新增独立 package 或原生 Kit；礼物相关类型不从顶层导出。旧 GiftListView、GiftPlayView、GiftUIStore 等内部入口已移除，调用方统一通过现有 PlayerView / PusherView 使用礼物功能。

高级美颜在 Flutter Android / iOS 使用插件自带的 TEBeautyKit 原生面板和 TRTC 视频帧处理。宿主在启动和登录成功后调用 `live_kit_access/lib/effect_license.dart` 中的初始化：经 `common/platform/advanced_beauty_channel.dart` 提交美颜 License，等待回调后再提交 FTCMediaXBase 的礼物授权，重复初始化合并。License 必须覆盖实际包名 / Bundle ID 与所用美颜套餐；不在组件库保存密钥。授权未就绪、处理器不可用或平台不支持时使用基础美颜。

依赖由插件与宿主声明，可在构建机下载：Android 为 `TEBeautyKit 4.1.0.14` / `TencentEffect_S1-07 4.1.0.13`（Maven）；iOS 为 `TEBeautyKit/S1-07 4.2.0.21` / `TencentEffect_S1-07 4.3.0.25`（宿主 Podfile 中的腾讯官方 podspec URL）。iOS plugin 为静态 framework；资源随插件打包，效果模型由 SDK 依赖提供，不引用相邻原生工程。Android 21+、iOS SDK 12+；Access 当前仍要求 iOS 15。

透明 MP4 礼物保留 `TCEffectPlayer / TCMediaX` 原版本。`EffectPlayer.sub_spec: NoXMagic` 必须保留，让美颜与礼物共用 TencentEffect 提供的授权库；不要再添加独立 `YTCommonXMagic` Pod 或 `TCXMagicAuth` AAR。修改原生依赖后执行 `flutter pub get` / `pod install` 并完整重编译，Hot Reload 不会更新原生库。鸿蒙 Flutter 本次保持基础美颜，不调用美颜平台桥。


`live_kit_access/ios/Podfile` 必须纳入版本管理：`permission_handler_apple` 的各权限策略由预处理宏开关控制，宏未定义时相关代码整段不参与编译，`Permission.camera.request()` 会直接返回 denied 且不弹系统弹窗，表现为摄像头始终不开、预览黑屏。Podfile 的 `post_install` 已显式打开 `PERMISSION_CAMERA=1`、`PERMISSION_MICROPHONE=1` 并关闭其余权限。同时 iOS 模拟器没有摄像头，本地预览必须用真机验证。

接入验证 App 全部页面固定正向竖屏：启动前设置 Flutter preferred orientations，Android Activity 声明 portrait，iOS/iPad 仅声明 Portrait 并要求全屏。将组件接入其他 App 时，应由宿主统一配置方向策略。

Android 评论输入要求宿主使用 `adjustResize`，页面 `Scaffold` 保持 `resizeToAvoidBottomInset: false`，由组件消费 Flutter 实时键盘 inset；不支持通过 `adjustNothing` 获取键盘高度。

## 登录凭证

`generate_test_user_sig.dart` 对应 iOS `GenerateTestUserSig.swift`、Android `GenerateTestUserSig.java` 的接入配置：`SDKAppID`、`EXPIRETIME`、`SECRETKEY`、`TENCENT_EFFECT_LICENSE_URL`、`TENCENT_EFFECT_LICENSE_KEY`。两端共用同一完整特效 License URL 和 Key；原生 Android 的 URL 是两段 Java 字符串拼接，核对配置时需取完整值。

MP4礼物需要单独初始化特效License。接入App在启动时通过`effect_license.dart`调用`FTCMediaXBase.instance.setLicense`，登录成功后再提交一次以覆盖首次联网前的失败；不等待鉴权结果才展示首页。其他App接入组件时也必须在播放前用自己的License完成此步骤，仅填写常量或完成AtomicXCore登录不会自动授权特效播放器。最终鉴权结果看日志`[LiveKitAccess][EffectLicense] result=0`；非0表示失败，MP4播放错误另记录为`[TUILiveKit][GiftMP4] playback error=...`。日志不输出License URL或Key。启动授权改动需完整停止并重新运行App，Hot Reload不会重跑`main()`。

接入App的iOS Bundle ID在`ios/Runner.xcodeproj/project.pbxproj`中统一为`com.tencent.mrtc`（Debug/Profile/Release），与当前原生iOS接入工程一致；安装时会替换设备上同ID的App。特效License必须授权实际Bundle ID，iOS回调`3015`表示Bundle ID不匹配，播放器`-10009`表示License不合法。若要让两个接入App共存，需要为独立Bundle ID配置匹配的License并重新构建安装；Hot Reload无法改变App身份。

Android 的 `android/app/build.gradle` 使用 `applicationId = "com.trtc.uikit.livekit.example"`，与原生 Android 接入 App 的包名及 License 配套；源码 `namespace` 仍为 `com.tencent.livekit.live_kit_access`。原生鉴权日志 `3015 App Identifier not match` 表示授权包名不匹配，随后 MP4 播放返回 `-10009`。修改包名或 License 后需重新构建安装；相同包名的原生与 Flutter App 不能共存，签名相同时覆盖安装，签名不同时安装会被拒绝。

签名同样只适合本地调试，正式包必须由服务端下发 UserSig。无需改代码时可用 `--dart-define` 覆盖：

| 参数 | 说明 |
|---|---|
| `LIVEKIT_SDKAPPID` | 腾讯云 SDKAppID |
| `LIVEKIT_USERSIG` | 服务端下发的 UserSig，配置后优先使用，客户端不再计算签名 |
| `LIVEKIT_SECRETKEY` | 覆盖本地调试密钥；正式包传空串以关闭客户端计算 |

`SDKAppID`、`SECRETKEY` 与 UserSig 全部为空时，启动页会提示补充配置，不会发起登录。

## 构建与检查

从仓库根目录构建并收集产物：

```bash
scripts/build_flutter.sh android debug
scripts/build_flutter.sh ios debug
scripts/build_flutter.sh all release
```

Pusher 模拟面板已移除，`TUILIVEKIT_DEBUG_PANEL` 对 Flutter 不再生效；接入方需删除原有 `PusherView.isDebugSimulationEnabled` 参数及 `pusherDebugPanelEnabled` 的使用。产物复制到 `build/flutter/`。底层 Flutter 命令如下：

```bash
cd flutter/live/live_kit_access
flutter pub get
flutter analyze
flutter build apk --debug
flutter build ios --debug --no-codesign
cd ../tui_live_kit
flutter analyze
```

iOS 真机 Debug 包需要通过 Flutter 工具或 Xcode 启动；停止调试后从桌面启动请使用 Profile 或 Release 包（例如 `flutter run --profile` 或 `flutter run --release`），并配置有效签名。无签名编译产物不能直接安装。

需要分别说明 Android 与 iOS 的实际构建结果。涉及系统栏、键盘、权限或平台渲染时，还需要在对应平台运行冒烟。

## 连麦设备控制语义

当前 Flutter AtomicXCore 使用 `unlockOnly` 解禁观众麦克风。主播管理面板只保留麦克风与断开连麦，不提供观众摄像头控制。关闭与解禁成功时，主播 Toast 带目标昵称（最多 8 个完整字符，超出追加省略号）；观众收到解禁状态时显示提示，只恢复本次连麦原本开启的麦克风。主动关闭时需要观众手动开启。观众自己的摄像头操作保留，语音连麦不会自动开启摄像头。

已移除旧摄像头业务授权弹窗，系统权限保留。后台延后开启并在前台重新校验，离席和离房清除恢复意愿并取消待处理请求。主播和观众图标同时跟随 SDK 锁定标记与实际设备状态。真实系统权限及双真机联调的验证状态见任务计划。

## 文档

- [跨端总览](../../docs/live/README.md)
- [跨端职责映射](../../docs/live/CROSS_PLATFORM_MAP.md)
- [Flutter Code Map](CODE_MAP.md)
- [Flutter 当前任务计划](../../docs/task/flutter/cross-platform-ui-plan-flutter.md)
- [仓库开发规则](../../AGENTS.md)

主播定向连线通过真实 AtomicXCore CoHostStore 接入：从 Living「连线」进入候选列表，支持邀请、取消、接受/拒绝、追加邀请和退出。随机连线入口展示雷达及开发中提示，尚不发起匹配。观众连线标识只显示「连线中」，不展示本地估算时长。多账号与真机验证状态见本平台任务计划。

### 综合 App 的准备页附加内容

`PusherView(liveID: liveID, prepareAccessory: hostWidget, onExit: onExit)` 可嵌入宿主拥有的类型栏。插槽高48、位于顶部安全区下4、左右各60；只在 Prepare 编辑态显示，倒计时与后续阶段隐藏。宿主不能借插槽改变 SDK 生命周期；未传入时原接入方式不变。`flutter/application` 只接入视频，语音和游戏点击提示占位。
