# Flutter App-UIKit

以 iOS application `75d8550e` 为模版的五 Tab 综合 App。

- 直播：双列列表、预览、真实进房及上下翻房、视频开播。
- 消息：复用仓库 Chat 的会话、聊天、搜索、联系人和群资料流程，关闭音视频通话入口。
- 我的：资料展示、头像/昵称修改、语言、实际 SDK 日志分享与退出登录。
- 会议、通话保留占位；开播类型栏中的语音、游戏保留占位。

代码职责见 [CODE_MAP](CODE_MAP.md)。本工程引用相邻 Live/Chat 组件，AtomicXCore 使用 pub.dev 5.3.0；没有仓库外 SDK path 依赖。

## 环境

已使用 Flutter 3.41.10-ohos-1.0.0 / Dart 3.11.5 的 Android、iOS 工具构建。原生 App 使用 Flutter 3.41 的 SceneDelegate / implicit engine 接入，最低 Flutter 3.41。

Android：API 24+，compile/target SDK 随 Flutter（当前36），NDK 28.2.13676358，JDK17+，Gradle8.14 / AGP8.11.1。iOS：15+，Xcode、CocoaPods；真机安装需自行配置签名。

Android Studio 安装 Flutter/Dart 插件后打开本目录 `flutter/application`，选择 `lib/main.dart` 运行。原生 Gradle 根工程是 `android/`，不要把 `android/app` 当根工程执行 wrapper。

Android 主 Activity 使用 `adjustResize` 向 Flutter 提供键盘 inset；页面 `Scaffold` 保持 `resizeToAvoidBottomInset: false`，由评论输入组件自行避让，不让系统重复压缩或平移页面。

## 配置与运行

从本目录执行：

```sh
flutter pub get
flutter run
```

统一配置文件为 [`lib/debug/generate_test_user_sig.dart`](lib/debug/generate_test_user_sig.dart)，Android、iOS 共用。后续修改 SDKAppID、测试 SecretKey、UserSig、签名有效期、特效 License URL / Key 都在此文件进行，登录和授权适配只读取配置。职责和GenerateTestUserSig类/genTestUserSig方法与原生iOS对应；目录和文件按Flutter规范使用小写下划线，测试签名生成也在此文件。修改后重新运行App即可。

默认 SDKAppID、测试签名密钥与特效 License 复用现有 `../live/live_kit_access/lib/generate_test_user_sig.dart` 的配置，可直接从 Android Studio 运行 `lib/main.dart`，无需先填写配置文件。

需要覆盖时可复制 `config.example.json` 到被忽略的 `config.local.json`，填写后使用 `--dart-define-from-file=config.local.json`。`APP_SDKAPPID` / `APP_SECRETKEY` / `APP_USERSIG` 优先于现有接入工程使用的 `LIVEKIT_SDKAPPID` / `LIVEKIT_SECRETKEY` / `LIVEKIT_USERSIG`，未指定时使用复用的默认值；显式传入空 SecretKey 可关闭客户端签名，再使用服务端签发的 UserSig。默认测试密钥沿用接入工程的开发用途。

`APP_EFFECT_LICENSE_URL` / `APP_EFFECT_LICENSE_KEY` 可覆盖高级美颜和 MP4 特效授权；显式传空则不提交授权。提交先等待 TEBeautyKit，再调用 FTCMediaXBase；调用完成不代表授权成功，结果仅记录状态码。启动和登录成功后各提交一次。

当前 Android applicationId 为 `com.trtc.uikit.livekit.example`，iOS bundle ID 为 `com.tencent.mrtc`，便于使用同一组匹配授权。它们与现有原生/Flutter接入 App 身份相同，设备安装会覆盖同身份 App（签名不同时会拒绝安装）；如需共存，修改身份并配置匹配的 License。

首次 iOS 构建如果提示没有 AtomicXCore 5.3 的 podspec，进入 `ios` 执行 `pod install --repo-update` 后重试。Podfile 使用腾讯官方远程 podspec，不要求本地引擎源码。

## 检查与构建

```sh
flutter analyze
flutter test
flutter build apk --debug --split-per-abi --target-platform android-arm64
flutter build ios --debug --no-codesign
```

Android 各构建模式仅支持 arm64-v8a：上面的命令产出 `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`；直接运行不带参数的 `flutter build apk` 或 `flutter run` 时，Gradle 也会排除非 arm64 的原生库，x86/x86_64 模拟器不可用。iOS 无签名 App 位于 `build/ios/iphoneos/Runner.app`。无签名 iOS 产物不能直接安装。构建产物、Pods、工具缓存和本机签名均不入库；根目录 `build/flutter/application/` 用于复制验证产物。

从仓库根目录可用统一构建入口生成综合 App 的可归档测试产物（不影响原 `scripts/build_flutter.sh android|ios|all` 的 Live Access 构建）：

```sh
scripts/build_flutter.sh application android debug
scripts/build_flutter.sh application ios debug
scripts/build_flutter.sh application mobile release
```

蓝盾构建号可通过 `APP_BUILD_NAME=5.3.0 APP_BUILD_NUMBER=4600` 传给脚本（两个变量必须一起传）；它们会透传至 Flutter 的 `--build-name` / `--build-number`，不再修改已跟踪的 `pubspec.yaml`、Gradle 或 IPA 内 Info.plist。综合 App 的两个 Flutter job 应各自 checkout `atomic_uikit`，在对应 macOS / Android 构建机执行：

```sh
set -euo pipefail
cd "${WORKSPACE}/atomic_uikit"
export APP_BUILD_NAME="${BK_CI_MAJOR_VERSION}.${BK_CI_MINOR_VERSION}.${BK_CI_FIX_VERSION}"
export APP_BUILD_NUMBER="${BK_CI_BUILD_NUM}"
./scripts/build_flutter.sh application android debug  # Android job
# ./scripts/build_flutter.sh application ios debug     # iOS job
```

综合 App 的 Android/iOS job 分别校验并归档 `app_flutter_android_<三段版本>.apk` 和 `app_flutter_ios_<三段版本>_unsigned.ipa`。Android 当前使用调试证书；iOS 的 `_unsigned` 包不可安装，只有企业签步骤对真实 IPA 签名成功并验证后，才能归档不带 `_unsigned` 的交付包。首次远端执行发现 macOS runner 是 Flutter 3.38.3 / Dart 3.10.1，不能解析本工程要求的 Dart >=3.11.0。Flutter HAP 仍需 OHOS 工程和插件适配；综合 App 最低要求 Flutter 3.41、Dart 3.11，并须核对构建机的 Android SDK/NDK、Xcode 和 CocoaPods。

[`scripts/atomic_app_uikit_flutter.pipeline.yml`](../../scripts/atomic_app_uikit_flutter.pipeline.yml) 现为独立的 **`Atomic-AppUIKit-Flutter-Validate` 隔离验证编排**，仅手动触发两个 Flutter 综合应用 job，不含主流水线的原生/Live Access job，不能用于覆盖蓝盾主流水线（以远端完整模型为准）。参考旧任务增加限定工作区的清理、`atomic_engine` 和 `atomic_uikit` checkout、iOS 证书安装；优先选已有 Flutter 3.41.9，否则在任务工作区获取官方 Flutter 3.41.9 / Dart 3.11.5，避免改变构建机的默认工具链。当前综合 App 将 `atomic_x_core` 锁定为 pub.dev 5.3.0，不能直接复用旧任务注入本地引擎 SDK 构件的做法；证书安装也不会令本轮 `--no-codesign` IPA 自动签名。隔离流水线验证成功后，需单独审核并将新 job 的修复合入主流水线。

Android Debug、Release 和 `application mobile` 中的 Android 构建默认都使用 `--split-per-abi --target-platform android-arm64`，仅校验并复制 arm64-v8a APK 到 `build/flutter/application/android/app_flutter_android_<三段版本>.apk`；旧 `--arm64-only` 参数仍可传，但不再改变默认行为。当前 Debug 和 Release 都使用工程配置的调试证书，仅用于测试，正式发布须改用受保护的签名配置。iOS 真机 App 被封装到 `build/flutter/application/ios/app_flutter_ios_<三段版本>_unsigned.ipa`，只是未签名编译产物；蓝盾必须对主 App、Frameworks 和 native assets 完成有效签名后才能作为可安装 IPA 交付，不能仅重命名或直接归档 unsigned IPA。

**Flutter HarmonyOS HAP 尚不能出包。** 尽管 Flutter OHOS 工具链提供 `flutter build hap`，本工程目前没有 `ohos/` 平台工程，`atomic_x_core: 5.3.0`、`tencent_live_uikit` 及 `flutter_effect_player` 均未声明 OHOS 原生插件。需先完成对应插件的 OHOS 实现、工程适配和构建验证，才能加入 Flutter HAP 任务；原生 `harmony/live/livekitaccess` 的 HAP 不属于这个 Flutter 综合 App。

本轮仅完成静态检查、测试和编译，未安装或运行设备；真实登录、播放、开播、消息收发、日志路径、PlatformView 透明/转场效果与权限需使用实际账号验证。

## 素材与依赖

`home_live_start.png`（54×54→18×18）与 `home_live_close.png`（45×45→15×15）从 Ardot 文件709144137533935的5074:2435、83:598直接导出。品牌Logo、个人页装饰/图标与原生启动图标按用户授权复用指定 iOS 模版素材；组件自己的 Live/Chat 素材由对应 package 提供。

模版引用的 `mine_profilepop_close`、`icon_avatar_selected` 在 Assets 中缺失，本端保留图形缺口；昵称抽屉可点外部/返回关闭，头像仍有选中描边。

App 固定 AtomicXCore5.3.0 和 IM9.1.7822，覆盖 Chat 旧本地 SDK 路径；SVGA 与 Chat 的 http 依赖统一到1.x，已检查使用的 get/Client API兼容并参与双端编译。其他接入工程的依赖配置未更改。

## iOS 真机签名排查

若安装提示 `objective_c.framework` 的 `0xe8008014`，先核对主 App 与该框架是否都由同一个有效开发证书签名。只签主 App，而框架仍显示 `Signature=adhoc` / `TeamIdentifier=not set`，真机会拒绝安装。此前做过 `--no-codesign` 构建时，增量构建可能复用 native assets 的无签名缓存。

在当前 Xcode 证书/描述文件配置正确的情况下，运行 `flutter clean`、`flutter pub get`，再运行 `flutter build ios --debug`（不加 `--no-codesign`），或打开 `ios/Runner.xcworkspace` 重新运行。`--no-codesign` 产物只用于编译验证，不能直接用于真机安装。

使用本机现有证书验证后的签名版另存为根 `build/flutter/application/ios/App-UIKit-Flutter-signed.app`；文件名带 `unsigned` 的旧编译验证产物仍不能直接安装。
