# Flutter Live Code Map

本文维护当前代码位置、SDK 调用链、状态与生命周期边界。构建与依赖见 [README](README.md)，稳定职责见 [跨端映射](../../docs/live/CROSS_PLATFORM_MAP.md)。

Flutter Live 公开入口由 AtomicXCore Store 提供直播业务事实；接入验证 App 的依赖覆盖和原生 SDK 配置见 [README](README.md)。

## Pusher 连麦布局类型

布局状态、选择回调与视频展示直接使用 SDK `CoGuestLayoutTemplate`，不再定义重复布局枚举。UI 名称、图标、嘉宾容量和空席位规则留在现有 CoGuest Store 文件的扩展配置中；默认 `dynamicLayout`，选项顺序为 `floatLayout / dynamicLayout / columnLayout / gridLayout`，SDK 模板 ID 仍为 601 / 600 / 801 / 800，容量为 6 / 8 / 6 / 8。未知模板不进入选择流程，布局失败回退、阶段背景、席位挂件与评论避让保持原调用链。

`pusher_coguest_store.dart` 保留 Dart 扩展与固定选项列表，SettingsView 继续使用原两行顺序；SDK 调用直接传入选中的常量。Pusher 席位 Adapter 与 Player 视频 Adapter 的 `onUpdateUnitView` 接受未使用的 `Object?`，兼容托管 SDK 的 `Key?` 和本机 SDK 的 `Widget?` 签名，更新仍只按 `UnitInfo.index` 寻址。

## 入口和接入层

Dart 包名与 iOS podspec 名称统一为 `tencent_live_uikit`，目录保持 `tui_live_kit/`。公开导出集中在 `tui_live_kit/lib/tencent_live_uikit.dart`；三个入口为 `LiveListView`、`PlayerView`、`PusherView`，同时保留 `PlayerVideoView`、控制器等现有导出。以下路径相对 `tui_live_kit/lib/src/`。

| 入口 | 当前文件与职责 |
|---|---|
| LiveListView | `live_list/live_list_view.dart` 是薄壳；`view_pager/pager_view.dart` 持有 Controller、分页/滑动策略和缓存；`view_pager/page_cell.dart` 持有单页 Player 控制器，闭环预览、进退房与资料更新。 |
| PlayerView | `player/player_view.dart` 持有页面及私有控制器实现；`player_controller.dart` 作为 part 声明接口/factory，负责预览/进退房/状态；`videoview/player_video_view.dart` 持有 AtomicPlayer/AtomicLiveController，`player_unit_view.dart` 的 `PlayerUnitView` 适配公共 LiveSeat 渲染席位。 |
| PusherView | `pusher/pusher_view.dart` 根 State 持有 AtomicPusher、设备/设置、预览、CoGuest 和 Prepare/Living/Summary 流程；Living 自持阶段能力。 |

Flutter 组件 LiveListView 是 Feed。两列直播选择页位于接入工程 `live_kit_access/lib/live_list`，由接入层调用 LiveListStore 拉取、刷新、分页和选择直播；不在 Feed 中重复实现选择网格。

```text
live_kit_access/lib/main.dart
→ LiveKitAccessApp → MainPage（通过 LoginStore 编排登录）
  ├── 未登录：LoginPage
  └── 已登录：WaterfallPage
      ├── LiveSelectListView → PlayerPage → LiveListView → PageCell → PlayerView
      └── PusherPage → PusherView
```

接入层负责登录、配置、导航、方向与系统壳；`pusher_page.dart` 和 `player_page.dart` 的 `Scaffold.resizeToAvoidBottomInset` 为 false，键盘由组件内部处理。公开接口不因 UI 同步自动更改。

接入App的`effect_license.dart`通过`FTCMediaXBase.setLicense`提交MP4特效授权，使用既有配置；`main.dart`在绑定初始化后非阻塞提交，`MainPage`成功登录后再提交一次，覆盖首次启动未获联网许可的情况。提交完成不表示授权成功，最终结果由License回调记录；配置留在接入层，公共礼物组件不持有凭证。其他宿主需同样初始化特效License。MP4原生播放错误由`onPlayError`判定并记录错误码，iOS插件的`startPlay`返回0只表示调用已提交。

接入App的iOS身份由`live_kit_access/ios/Runner.xcodeproj/project.pbxproj`的Runner构建配置维护，`Runner/Info.plist`通过`$(PRODUCT_BUNDLE_IDENTIFIER)`读取；License授权需与实际构建身份一致。具体Bundle ID及安装共存约束见README。

Android 应用身份由 `live_kit_access/android/app/build.gradle` 的 `applicationId` 决定，与源码 `namespace` 分开；当前使用 `com.trtc.uikit.livekit.example`。`generate_test_user_sig.dart` 的完整 License URL 和 Key 与原生 iOS、Android 共用，不按平台分支。原生授权错误 `3015` 表示应用身份不匹配，播放层随后返回 `-10009`；授权回调 `-12` 表示下载及本地授权文件读取失败。下载成功或 iOS 授权通过不能证明 Android 已获授权。

MP4 与高级美颜共用 TencentEffect 的授权实现。插件 podspec / Gradle 声明 TEBeautyKit 与 TencentEffect，Access Podfile 固定腾讯官方来源；`effect_license.dart` 防重并先等待 TEBeautyKit 授权回调，再提交 FTCMediaXBase 授权，避免同时调用共用授权库。`flutter_effect_player` 保持 NoXMagic；不要再引入独立授权库。版本和接入步骤见 README。

## Pusher：阶段与状态持有方

| 目录 / 文件 | 当前职责与状态来源 |
|---|---|
| `pusher_view.dart` | 根编排开播/结束、权限/预览、设备、标题封面、暂停/计时、设置及 CoGuest；SDK 业务事实来自 AtomicPusher / DeviceStore 等，阶段为本地 UI 状态。会话内监听、计时与订阅统一由 `_releaseSession` 释放，`dispose` 只额外销毁控制器与通知器。根部 `DefaultTextStyle.merge` 统一去掉无 Material 祖先时的文字下划线，Pusher 子树内的 `Text` 不再逐处声明 `decoration`。 |
| `video/pusher_video_view.dart`、`video/pusher_unit_view.dart` | `PusherVideoController` / `PusherUnitAdapter` 编排 AtomicLiveWidget 舞台、席位 Adapter 与几何查询；`PusherUnitView` 是 LiveSeat 薄壳。`PusherUnitAdapter` 为 public，供 `test/pusher_coguest_provider_test.dart` 直接构造验证音量与几何；Player 侧 `_PlayerUnitAdapter` 保持库私有。 |
| `prepare/pusher_prepare_gradient_overlay_view.dart` | Prepare 编辑态顶部与底部渐变遮罩；倒计时期间随编辑内容隐藏，取消后恢复。 |
| `prepare/pusher_prepare_view.dart`、`pusher_live_info_editor_view.dart`、`pusher_cover_picker_view.dart` | 开播前标题封面、入口动作、封面列表；`countdown_view.dart` 是 Prepare 内部倒计时。 |
| `prepare/prepare_more_settings_view.dart`、`settings/` | Prepare 更多与两阶段共用条目、音效、动作接口；清晰度入口与选择页已移除，根仅初始化720P；不再保留清晰度枚举、切换动作、目标画质状态或设备订阅。 |
| `living/pusher_living_view.dart` | 阶段宿主；持有观众、点赞、公共 `common/barrage/barrage_ui_store.dart` 普通/礼物评论时间线、礼物评论/展示及各浮层控制器；接收根设备/设置与 CoGuest 投影。 |
| `living/live_header_view.dart`、`live_bottom_toolbar_view.dart` | 顶部主播资料/在线/点赞/网络/计时和底部操作入口。 |
| `living/audience/` | `pusher_audience_store.dart` 持有观众能力；在线头像、列表与管理窗分别展示。 |
| `living/coguest/pusher_coguest_store.dart`、`control_panel/` | 连麦申请/布局/成员状态与 SDK 操作；控制面板及成员管理消费状态。 |
| `living/status/pusher_live_status_view.dart` | 抽屉宿主；`pusher_live_statistics_view.dart` 与 `pusher_device_status_view.dart` 在同一 library 中分别承载统计/设备展示；显示期订阅累计统计，分辨率取真实宽度。 |
| `living/music/pusher_music_view.dart` | 音乐选择/播放及其功能状态；Living 合并手动暂停/后台原因，初始挂载即接收暂停/后台合并状态，功能仅恢复由本次挂起暂停的同一曲目。 |
| `living/end_confirm/`、`living/pause/` | 结束确认和暂停覆盖层。 |
| `summary/pusher_summary_view.dart` | 主播总结展示，生产链读取根传入的 PusherSummary 最终事件快照，未知值显示 --；起止时间/暂停上下文及中断原因由根传入。仅显式注入时保留测试 Store 兼容入口。 |

`settings/audio_effect_view.dart` 中的 `buildAudioEffectPage` 只复用两抽屉音效子页的定位装配，标题与466高度共用；`AudioEffectView` 仍自持 `AudioEffectStore` 的显示期订阅与耳返、变声、混响写操作，直接使用 SDK 枚举，保留各 5 个产品选项及其他值的原声/无混响选中兜底。根 `PusherSettingsState` 与动作接口不再投影音效状态或转发音效操作；采集音量仍由根读取、写入并传入面板，面板保留测试 Store 注入。Prepare/Living各持Widget实例，关闭开始传入非激活状态；重开主页面、Prepare的initialPage兼容入口、Living关闭后动作与代次校验均保留。音乐播放状态直接使用 SDK `MusicPlayStatus`，后台恢复意图仍留在 Music 功能内。

`living/live_header_view.dart` 已有的 `LiveHeaderView.formatDuration` 作为Pusher共用纯时长格式入口，LiveStatus静态入口直接转发；Summary专属自然时长格式留在自身文件并先做负数归零；不新增时长文件，也不让子页反向依赖根Widget。`pusher_view.dart` 同文件保留内部 `PusherBackNavigation` 返回适配，只转发系统返回；阶段持有方关闭浮层/取消倒计时，Living/暂停时阻止路由退出，ending期间忽略返回，不公开导出。设备状态直接使用 Common 的 `LiveThermalState` / `LiveNetworkType`，平台订阅仍归根；设备页按媒体、温度、网络状态一次生成同文件私有展示描述，再交给行控件，Header 的网络分档独立保留。

根订阅登录资料，开播进入 Living 后调用 startPush；首次连接前请求失败回 Prepare，保留预览和草稿。networkState 与 pusherInfo 都监听以兼容回调先后顺序；每次开播建立独立监听身份。主动结束显示阻挡遮罩并等待 liveEnded，终止事件携带最终统计后进入 Summary 并清理会话。运行错误、被踢和主动结束分别处理；返回防重。

根初始化读取当前Flutter生命周期；首次预览在打开摄像头前将镜像设为 `auto`（前置镜像、后置不镜像）并发布UI意愿。翻转镜头时切后置强制 `disable`、切回前置强制 `enable`；后置镜像按钮保留但置灰禁用，前置恢复可操作，根 `toggleMirror` 同样禁止后置调用。Prepare → Living、重试和后台恢复不重复初始化。会话释放即停止阶段功能和计时、取消登录/推流/设备/平台订阅，Summary存留不继续监听上一场。

暂停时长使用 Duration 累积，有效直播计时暂停冻结。前后台保留摄像头方向与设备意愿，临时挂起仅关闭摄像头/静音，最终清理关闭麦克风；取消静音请求防重且失败回滚。

Pusher CoGuest 当前默认 grid2；首次连接后由功能Store锁存连接状态至deactivate，短暂断网不退回未连接阶段。舞台背景和工具栏按Living且有观众或布局非floating显示，与空席开关分开；已确认布局、人数与实际 SDK 席位驱动舞台。席位 Adapter 的 RenderBox 几何用于评论避让：默认评论宽上限 `min(容器宽×0.8, 容器宽−24)`，相交小窗左侧保留间距；不重算 SDK 布局。成员管理保留远端麦克风与断开两项，按实际锁定/关闭状态调用解禁、提示手动开启或关闭，不增加摄像头管理。管理用 `PusherCoGuestUser` 只投影身份和麦克风状态，不再复制未消费的摄像头状态/许可；席位显示仍直接读取SDK UnitInfo。Store的停用与销毁共用解绑和请求代次失效，只有停用清空展示状态并通知，销毁不发通知。

观众、入场欢迎、普通/礼物评论等级直接来自当前SDK发送者/观众快照，0为有效等级；未知只保留于明确未提供等级的兼容DTO。主播评论身份取当前登录用户。封面编辑器以私有视图保留最后成功帧，按请求身份隔离迟到图片，卸载释放监听和图像。

Android Living 顶部保留用户指定的 `max(viewPadding.top, 页面高度×46/844)`；iOS 分支为 `padding.top−1`。这只移动 Header，不缩放内部控件。

Pusher底栏依次为连线、连麦、翻转镜头、背景音乐、更多。连线通过onCoHost进入主播连线；未提供时兼容onPK回调；flip/music从更多设置迁出，仍经Living宿主接原设备/音乐功能。左距18、连线与连麦距14，右侧间距12/右距12；每项最小34，按真实可用宽度分配标签的额外宽度，文案在16高标签槽内局部等比缩小以完整显示，不整屏缩放。连线/连麦46×38（top−6）、flip/music26×26（top0.5）、更多27×27（top0），后三项各用底栏专属Ardot资源，不覆盖设置或其他页面共用图标；标签11/常规、top30/h16，测量/渲染共用合并宿主字距、字体的TextStyle与locale，单行FittedBox仅在空间不足时缩小，不加省略号。点赞起点仍取更多Key，Toolbar总高68+真实安全区。

连麦控制面板只生成非空connected/applicant/candidate分区；空connected同时隐藏endAll。自然高度为78+162+Σ(12+section.preferredHeight)+16+safeBottom，上限min(654,可用高−80)，超出滚动；请求与成员状态仍由原CoGuest Store闭环。

Summary用真实SafeArea内的44高页头（top8）固定返回箭头与24半粗标题，下方8间距进入单一滚动列。页面边距20、卡内24、卡间24、底部24；收益主卡280高，以48半粗收益、32礼物/送礼人数并排展示，互动卡三等宽列26数值。时间范围与总计时长同14字级，暂停大于0与结束原因按需增加同字级行。文字仅primary/secondary/income三类；数字完整分组→紧凑3位有效数字→科学计数候选缓存，局部缩至50%，无障碍保留完整值。生产直接读取根最终PusherSummary，不再复制LiveSummaryData；仅显式注入测试Store时保留只读订阅，换绑和dispose解绑。默认字形采用目标平台字体，系统TextScaler保留。

Prepare封面继续58×58、圆角14，底部叠18高黑40%“修改封面”，两处提示均75%灰；“修改主题”去掉前置字符。标题20、封面提示10、主题提示12与底部快捷尺寸均保持，标题相对位置58+32=90未变，不同步iOS放大/宽度缩放。空白收键盘的GestureDetector仅包Prepare编辑内容层，子按钮与输入按原手势优先级处理，倒计时和浮层在其外；标题草稿/图片请求代次和SDK链不变。

## Player：预览、进退房与房内功能

`_PlayerViewControllerImpl` 持有 `PlayerStatus`、进房中标记、liveInfo、AtomicPlayer 监听和 PlayerVideoViewController。`startPlay` 发起静音预览并解除 end；入口点击调用 joinChannel，成功后转 inRoom、恢复播放音量并通知 Feed；关闭入口防重复并等待 leaveChannel 的清理编排后通知 Feed、复位策略。当前进房用 liveID 检查重复/迟到结果，不能等同于完整会话代次保护。

`PlayerView` 根据状态选择房外 `preview/preview_view.dart`、房内 `living/living_view.dart` 或 `summary/summary_view.dart`。这里的 SummaryView 是观众直播结束占位，不承担主播结算。SDK liveEnded/kicked 都经根 `_showEnded` 终止预览、清理连麦意愿并进入 end，被踢原因通过公共 Toast 提示；Living回传提示时校验宿主仍挂载、房间ID一致且状态仍在房内，避免退房/换房到下一帧卸载之间的旧错误覆盖新提示。后台连麦仅静音麦克风，保留采集。

| 功能 | 当前落点 / 边界 |
|---|---|
| 房内整体、清屏、评论输入、礼物/点赞 | `player/living/living_view.dart`；仅房内挂载，随 State 建立和释放阶段资源。底栏当前固定离底40/按钮36，评论胶囊含文字与直接表情两个入口，普通评论区域宽度为屏宽×`BarrageStreamView.defaultWidthRatio`（0.8）。 |
| 主播资料 | `living/hostinfo/host_info_view.dart`；关注状态辅助为 `living/follow_service.dart`，订阅实际关系并对点击防重。 |
| 在线、观众列表、资料 | `living/audience/audience_view.dart`、`audience_list_panel.dart`、`audience_profile_panel.dart`；列表当前按 liveID 复用所持 Store。 |
| 连麦入口及申请 | `living/coguest/co_guest_icon.dart`、`requesting_panel.dart`；消费 CoGuest 状态并切换空闲/申请/接通。当前接通显示 `livekit_coguest_wave.gif`。 |
| 视频申请预览/设备设置 | `living/coguest/settings_panel.dart`；引用 Common BeautyPanelController；视频申请先进入设置预览，仅点击申请才发起请求，关闭/销毁停止预览并过滤迟到启动。 |
| 已连麦操作 | `living/coguest/co_guesting_panel.dart`；控制设备与下麦，状态取实际 SDK。旧 `player_co_guest_device_store.dart` 已不存在，不能按旧文档恢复另一套持有方。 |

普通评论与礼物评论的业务合并、排序及最近 100 条上限已归 `common/barrage/barrage_ui_store.dart`。Living 直接复用公共 `BarrageComment`（继承 `LiveMessage`），不再复制成 Pusher 专用评论模型或转换回展示模型。该时间线只在真实消息、本人资料更新、礼物评论结算与评论生命周期同步时合并；显示列表只在这些事件时生成，计时、设备、点赞、观众和布局更新复用原消息列表。`common/barrage/emoji/barrage_emoji_converter.dart` 维护 62 项 token、资源和内部单字符映射，负责归一化、序列化、可见长度、截断与内联 spans；`barrage_emoji_panel_view.dart` 负责网格、翻页、删除发送、渐变遮罩、安全区和空白触摸拦截；删除按钮不使用独立底色，保留原热区、图标和禁用透明度。共用输入框最多 200 个可见字，有效表情按一个字且不拆分；输入胶囊最小高 32、外条上下各留 10，内容最多 4 行后框内滚动，14 字号、1.2 行高。图文输入保留 IME composing 文本、选区和编辑保护，超限显示品牌 Toast。两个入口的输入组件均常驻当前 Living，隐藏保留草稿、发送后清空；Player 评论胶囊右侧可直接以表情模式打开，普通评论入口仍先弹系统键盘。普通展示消息超过 200 可见字截断并加省略号，有效 token 与内联图片共用测量，未知编码保留原文，系统公告完整显示。输入条由键盘、表情面板与底部安全区共同定位，评论区位于输入条上方 6；输入条与键盘/表情面板均不保留额外间距。普通键盘几何直接消费 Flutter 实时 inset，收到高度后输入条当帧完整显示，不叠加额外汇入动画。表情切键盘从等待到中间 inset 上升全过程保留输入条当前位置，仅在实时 inset 达到原位置后恢复跟随，不先回落或闪隐；中间值也不覆盖最终键盘高度缓存。直接表情展示不播放面板高度/输入条位移动画，仅保留占位层渐变。组件只在键盘模式记录最近一次有效键盘总高度供后续表情面板复用，避免固定 274 与键盘高度、动态安全区之间产生切换跳动；表情模式忽略关闭过程中的中间 inset，不覆盖该高度。表情模式下点击文本框会同步切回键盘模式；每次重新展示输入组件时表情面板回到首页。表情加载中与加载失败均使用现有 size 的固定尺寸 token 兜底，保持评论测量与渲染尺寸一致。`onInputBarHeightChanged` 和 `onInputBarBottomChanged` 在布局完成后报告实际几何，重复展示会重新上报，输入态评论区捕获打开前可见高度。

Living 组合层依次放置渐暗、Header、评论、Welcome、Toolbar、点赞、礼物展示、设置、评论输入、音乐、暂停、观众列表/管理、结束确认、CoGuest 设置、直播状态和席位管理。抽屉阻断舞台点赞；舞台命中真实席位后进入成员操作。离开阶段释放订阅，退后台清理入场/点赞动画。

根 CoGuest 背景与 Living 席位管理层的 `Positioned.fill` 固定包在局部监听器外侧，显示和空态均保留定位约束。根 Stack 对阶段子树传入松约束，Living 依靠定位子层铺满可用空间；监听器返回的空控件不能变成参与 Stack 尺寸计算的非定位子节点，否则 Prepare 隐藏后整个舞台会收缩为零尺寸。

设备投影类型与派生状态在 `living/status/pusher_live_status_view.dart`：根只采集 SDK 原始设备状态、错误、网络与 AV 字段，展示模型计算关闭/设备异常/推流异常优先级。

礼物浮层挂载/移除激活与取消监听，activationID 过滤迟到事件；与礼物评论订阅独立，不发送自定义礼物消息。送礼只调用 SDK `sendGift`，展示纯靠 SDK 收礼回声，不再做本地发送预约与对账；清屏、暂停和后台均清空当前展示及队列，恢复只接收新礼物。`GiftSendPanelView` 内的目录刷新校验会话代次。胶囊默认评论偏移86，特效底部 inset 默认0。

GiftAnimationController 只准备当前及队首下一份，同 URL 复用已解析 SVGA；下载/解析/播放有超时与迟到隔离，失败日志只记录准备阶段/类型或原生播放码，不输出资源URL；资源在队列和渲染持有方均释放后销毁。SVGA 透明画布铺满、素材等比居中；MP4 使用 alpha-right。旧 `preload` / `preloadEffects` 入口已移除，不下载未入队的目录资源。礼物评论图片异步成功/失败改变行高时通知父列表更新高度及贴底位置，浏览历史时保持当前位置。礼物面板保留348+安全区、四列/行104基准，短屏报告实际高度，大字体只扩文字所需行高。选中态价格固定在赠送按钮上方4逻辑像素。

点赞SDK Store、门禁与总数订阅仍归各入口 Living；两入口各持 `common/like/like_animation_view.dart` 同文件 `LikeSender` 的独立发送器，首次即时、单调时钟满6秒合并，窗口内复用一次计时。普通停用/切房补发一次，首次开播失败丢弃；发送与停用均失效旧任务，同房重激活也不串批。Common 动画与收赞只读监听保持原样。监听/数据流更换或视图移除时取消延迟动画，以代次隔离旧回调；控制器更换时各动画保持独立身份。

资源通过 `LiveKitResources.image` 从组件 package 的 `assets/`、`2.0x/`、`3.0x/` 加载。Ardot 导出来源与资源校验记录见 `assets/source/ardot_*.json`；除 `assets/source/ios_emoji_sync.json` 记录的 62 个表情经用户明确授权复用 iOS PNG 外，各页面直接使用组件自身资源，不转换或复用 iOS 图标。评论控制图标和发送底图的 Ardot 来源与校验记录见 `assets/source/ardot_pusher_ui_sync.json`。图标的 UI 状态由对应页面或 SDK 状态驱动，Code Map 不维护像素尺寸和导出批次。

## 平台边界

Pusher Debug 模拟面板已移除（与 Android 一致）：不再有 `debug/` 目录、`PusherView.isDebugSimulationEnabled` 参数和顶层 `pusherDebugPanelEnabled` 导出，`TUILIVEKIT_DEBUG_PANEL` 对 Flutter 不再生效。Living、Status、Summary 只展示 AtomicXCore 数据。

权限由 Flutter 既有 permission_handler 与原生配置配合；热状态与网络类型从 Common 平台桥读入，最后一个订阅取消时透传到原生释放，通道事件错误分别回退 normal/unknown；AV/网络质量来自 AtomicXCore。具体依赖版本、最低系统与构建参数只在 README 维护。Swift 与 Dart SDK API 不可根据同名方法推断完全等价。
`PusherCoGuestUserSectionView` 按 userID 缓存行 Widget，显示字段比较只包含身份、昵称、头像、操作标题/样式、pending 和 enabled；设备更新不重建相同行。排序移动 keyed Element，头像 URL 相同沿用 Image 的图像流，昵称/按钮变化原位更新。`PusherCoGuestSettingsView` 为无状态Widget，四类成员行通过同一生成方法投影标题/样式/pending/容量门禁，四个布局按钮按固定两行配置生成；原顺序、48高度与8间距保持。继续以实际内容高度驱动 BottomSheet，高度未变时无新高度过渡。

席位昵称距左、右和底部6，9字号、14行高、左对齐截尾；静音是左上6的20×14胶囊（黑色32%、圆角7），内置12图标。无视频头像使用下文统一尺寸策略，按真实席位居中。管理操作文案用 control 角色（11常规），16行高居中。两项新图标均从 Ardot 导出为组件资产三倍率，不修改 SDK 席位几何。

## Common 和礼物展示

`common/theme` 提供 LiveTheme/LiveText 的 12 个文字角色、4 级文字色、LiveSlider、LiveTextInputView、Toast、BottomSheet 及背景。`common/debounced_click.dart` 按按钮标识独立记录点击时间；Player CoGuest 的 `SettingsPanel` 五个按钮调用其默认 1 秒防连点方法。`LiveTheme` 集中品牌蓝/深蓝/青色、画布底色、视频覆盖底色、昵称/观众礼物值强调色及抽屉遮罩；旧 `LiveKitPalette` 已移除。Flutter 保留既有 8-bit 色值和各调用点透明度精度，不按数值相同把不同功能语义合并。

`live_theme.dart` 中的 `LiveVideoOverlayStyle`、`LiveAudienceRowStyle` 承担两入口共享视频胶囊和观众行配方。Flutter Player Header保留现有视觉，Pusher独用的 `_LiveHeaderStyle` 留在 `pusher/living/live_header_view.dart`，不提前提升到Common。`LiveCommentRowStyle` 留在 `common/barrage/barrage_stream_view.dart`，普通行和礼物行共用背景/圆角；`BeautyStyle` 留在 `common/beauty/beauty_view.dart`；`GiftPanelStyle` 留在 `common/gift/send/gift_send_panel_view.dart`，供礼物单元格、分类下划线和连击按钮消费。美颜蓝和礼物蓝保留功能语义，未并入品牌色。

`PusherSettingsSelectionStyle` 在 `pusher/settings/pusher_settings_item_view.dart` 供音效条目和设置控件复用；`PusherCoGuestGroupStyle` 留在连麦 ControlPanel；`PlayerLayout` 留在 Player Overlay。其余阶段、评论、礼物展示、状态卡等配方由原文件私有持有，已有文字角色与功能专属 TextStyle 保留，不新增主题切换状态或公开导出。

Living 更多的麦克风两态都使用 Ardot 导出的完整 44×44 圆底 PNG，经组件 package 资源机制加载；槽位保持 44 逻辑像素，条目统一 `showsIconBackground: false`，不重复绘制背景。两态文案、映射与 SDK 回调保持原链路。

Pusher 的 `BottomSheetTheme` 启用当前背景，Player 默认背景保持；抽屉支持可选标准标题、隐藏保留 State、动态限高及关闭完成回调。权限和系统能力封装位于 `common/platform`。

BottomSheet 光晕按 iOS `CAGradientLayer` 的椭圆定义映射：起点 `(0.5, 0.5)`、终点 `(1, 1)` 对应单位方形半径 `0.5`，再按光晕实际宽高分别缩放；不能使用起终点的欧氏距离作为半径，否则光晕在矩形边缘仍不透明而被截断。

`common/theme/live_text_input_view.dart` 独立承载两处输入的多行布局、字符簇 formatter、组合输入和限长 Toast；调用方持有 controller/focusNode，可选 `onTap` 仅透传给 TextField 供输入壳同步模式，输入控件持有短期 OverlayEntry/ToastController 并在 dispose 清理，不持有 SDK。

`common/gift` 按发送、展示和礼物弹幕组织。按用户要求，当前只有 Player 使用的 Send 仍留在 Common；播放仅服务展示，放在 `display/playback`，不新增 package 或原生 Kit。

| 位置 | 职责与状态归属 |
|---|---|
| `gift_barrage_store.dart` | Pusher / Player Living 各自持有 GiftBarrageStore；订阅 SDK 收礼，按用户与礼物合并2秒后生成同文件 LiveGiftBarrage，交给 BarrageUIStore；无本地累计业务统计。 |
| `send/gift_send_panel_view.dart` | 对外唯一送礼组件：`present(liveID)` 内聚目录加载与发送、悬浮连击、面板/分类/选中几何；点击分类时保持目标选中，分页动画中间页不回写Tab，用户拖动接管后恢复同步；标题按普通/加粗最大宽度固定几何。私有分类栏及 GiftPanelStyle 同文件。 |
| `send/gift_grid_page_view.dart` | 礼物网格和私有礼物格子；价格直接取 SDK coins。 |
| `send/gift_send_combo_button.dart` | 赠送/连击按钮及控制器，面板与浮动连击共用。 |
| `display/gift_display_view.dart` | GiftDisplayView / Controller 收礼订阅、通知和动画分发、面板/评论避让；同文件 GiftDisplayItem 保存展示快照。 |
| `display/gift_notice_view.dart` | 双槽通知条、头像与计数展示，控制器及私有子组件同文件。 |
| `display/gift_animation_view.dart` | 动画队列、当前及下一份准备、超时和失败切换；不持有第三方播放器类型。 |
| `display/playback/gift_player.dart` | 统一单次播放及渲染，内部选择 SVGA / MP4；play / stop / dispose，无暂停恢复。 |
| `display/playback/gift_resource_loader.dart`、`gift_svga_decoder.dart` | 下载缓存/取消、SVGA逐张解码及资源释放；既有库继续承载渲染及原生特效播放。 |

通知头像使用组件默认头像作为空值、加载中及失败回退，保持38逻辑像素圆形裁剪和描边。Display Stack 先画通知、后画动画；播放器铺满动画容器，显式预览 bottom inset 时保留避让。Loader 沿用应用缓存 `TUILiveKit/PusherGiftEffects`，临时目录下载并原子落盘，清队列取消准备任务，资源在队列与渲染均释放后销毁。

```text
Living → GiftBarrageStore → LiveGiftBarrage → BarrageUIStore → 评论时间线
Player Living → `GiftSendPanelView.present(liveID)` → SDK sendGift → SDK 收礼回声 → GiftDisplayView 展示
Living → GiftDisplayView 挂载 → GiftDisplayController 只读收礼订阅
→ GiftDisplayItem → GiftNoticeController + GiftAnimationController
→ GiftPlayer → svgaplayer_flutter / flutter_effect_player
```

礼物语言映射合入 `LiveKitResources.giftLanguageCode`。旧 GiftUIStore / PusherGiftStore、GiftListView / GiftPlayView、旧 panel/player 目录与预加载兼容入口全部移除。Gift 类型仅供组件内部使用，没有新增顶层导出。

## Store 访问约定

只删除直接绑定固定 `shared` 的成员：Pusher 根、PlayerBeautyStore、Player 的 CoGuestIcon/CoGuestingPanel/SettingsPanel 直接访问 SDK 单例；Player 进退房和列表监听原已直接访问，保持不变。AtomicXCore 5.0.2 `StoreFactory.getStore` 将 Device/AudioEffect/BaseBeauty/LiveList 返回固定实例；Music、Seat、Summary、CoGuest、Audience、Like、Barrage、Gift 均按 roomID/liveID 获取，必须保留原持有和解绑边界。

`PusherCoGuestStore` 构造注入的 LiveList/Seat、`PlayerCoGuestDeviceStore` 注入的 Device/Seat factory、礼物注入依赖继续保留。根 `_deviceListeners`、设备授权待处理意图、请求代次、迟到成功清理和销毁解绑均保持原链路。

## SDK 和平台差异

- SDK 依赖与覆盖方式见本文开头及 README；当前等级来源见 Pusher / Player 段落，不以旧版 SDK 字段限制推断当前能力。
- SDK 字段以 ValueListenable 暴露，回调在主 isolate 更新；异步方法返回 CompletionHandler 的 isSuccess/errorCode/errorMessage，调用方也处理可能的异常和迟到结果。
- 视频层使用 `AtomicLiveWidget` / `AtomicLiveController`，Pusher 通过 `AtomicLiveViewType.pushView` 创建，Player 通过 `playView` 创建；Pusher 渲染器跨阶段保留，席位挂件由 `PusherUnitAdapter` 持有，使用实际 RenderBox 命中，不复算 SDK 席位布局。
- 系统热状态：iOS ProcessInfo.thermalState，Android PowerManager（API 29 以下正常）；网络类型：iOS NWPathMonitor，Android ConnectivityManager（API 23 以下未知）。UI 只消费 common/platform，网络质量与 AV 数据仍来自 AtomicXCore。
- 摄像头/麦克风权限由根通过 permission_handler 申请；原生宏、EffectPlayer NoXMagic 和 Android TencentEffect 共用授权配置见 README。
- Flutter 与 UIKit 原生文字断行、字体和调试菜单存在平台表现差异；不用截图或像素差异反推实现。

## Player 保护范围

Player 顶部安全区取 `max(MediaQuery.padding.top, contentSafeAreaInsets.top)`，不相加。Feed 的 LiveListView 从同一 MediaQuery 读取并透传 contentSafeAreaInsets，重复相加会多留一整段状态栏高度。独立 Player 未传入时仍用系统安全区；宿主传更大保护区时取更大值。HostInfo 顶部在该基线上加 10（高 36），Audience 与其垂直居中，关闭按钮加 13，与 iOS `layoutMarginsGuide` 一致。

房内浮层的布局与控件配方集中在 `player/living/living_view.dart` 的 `PlayerLayout`：底栏 `bottom = 安全区底 + 3`、高 39、左右 12、间距 8.5、控件 39×39、圆底 `0x2E0A0A0F` 与白 6% 描边；评论列表 `left 12`、`bottom = 底栏顶 - 14`、宽 `容器 × BarrageStreamView.defaultWidthRatio`、默认高184，输入态保留点击前可见高度；清屏恢复按钮 `right 18`、`bottom = 安全区底 + 10`；浮动连击 `right 16`、`bottom = 底栏顶 + 30`、宽72，高度随按钮内容及文字缩放确定。HostInfo 胶囊高 36、圆角 18、四段横向渐变加白 6% 描边、头像 32、关注按钮高 28；Audience 与 HostInfo 垂直居中、`right 42`。观众头像堆叠用月牙挖空 `ClipPath`（`_AudienceAvatarCutoutClipper`），不使用描边圆环。

`live_list` 的公开 Widget 位于 `live_list_view.dart`；`view_pager/pager_view.dart` 持有 `LiveListViewController`、数据合并、滑动状态、PageCell 缓存和销毁清理；`view_pager/page_cell.dart` 持有单页 `PlayerViewController`，负责资料更新、Preview、进退房和 PlayerView 宿主。Player Overlay 组合 Feed、房外 Preview、房内播放、礼物、点赞、评论和 CoGuest UI；业务状态由对应功能 Store 或 AtomicXCore 提供。

观众端评论由 `common/barrage/barrage_ui_store.dart` 的 `BarrageUIStore` 承担，对应 iOS `Common/Barrage/BarrageStore.swift`：它创建并订阅 room-scoped `BarrageStore`、负责发送、个人禁言校验、发送失败按错误码映射 `tuilivekit.comment.*` 文案、把已结算的本地礼物评论与普通文本按时间合并为最近 100 条时间线。`LivingView` 私有持有并在挂载期间激活/停用，经 `onToast` 把失败文案交给根 `PlayerViewController` 的 `LiveToastController` 展示；评论视图只消费 `LiveMessage`，不持有 SDK。

房外进房入口卡位于 `player/preview/preview_view.dart`（`PreviewView`），由 `_PlayerViewState` 直接持有。`build` 按 `PlayerStatus` 唯一收口互斥显示：`end` 显示 `SummaryView` 并不再渲染 `VideoView` 与页面底图；`inRoom` / `coGuest` 显示 `LivingView` 与关闭按钮；其余状态在 `PlayerViewController.joinLiveEntranceEnabled` 为真时显示入口卡。`end` 是终态，只能由 `startPlay` 解除；`leaveChannel` 回到 `playing` 或 `idle`，`close` 不调 `stopPlay`。进房失败进入 `end`，不回调任何事件；入口卡发起的进房成功后回调 `onJoinLiveClicked`。页面底图与结束页背景都按 `backgroundURL → coverURL → LiveKitResources.defaultBackgroundURL` 取值并做 80 模糊，与 iOS `PlayerVideoView.setBackground` / `SummaryView.setBackground` 一致。`_PlayerViewControllerImpl` 在构造时把 `_status` 变化同步到 `PlayerVideoViewController.playerStatus`（`ValueNotifier<PlayerStatus>`）；视频层 Adapter 在 `onCreateUnitView` 中嵌套 `ValueListenableBuilder<PlayerStatus>` 把当前阶段作为 `PlayerUnitView.playerStatus` 下发，`PlayerUnitView` 用 `!isOwner && (status == inRoom || status == coGuest)` 组合 `showsOverlay`，其他阶段隐藏席位挂件，三端对齐。

`LivingView` 不再接收 `joined` / `onJoin` / `showJoinLiveEntrance`，只在房内状态挂载，房内评论、礼物与点赞 Store 随 `initState` / `dispose` 建立与释放，对应 Android、iOS 常驻实例上的 `setJoinedChannel` 激活与停用。点赞委托与Pusher共用的内部 `LikeSender` 实现，各持实例；等待期间连续点击复用同一个Timer，停用前发送余量。礼物浮层在清屏时 `setSuspended(true)` 清空展示，保持挂载以消费回声；面板层级移动通过稳定 GlobalKey 保留同一展示实例，礼物面板展开时提升到最上层、收起后回到评论输入之下；评论输入常驻挂载并以 `isPresented` 控制显隐，关闭保留草稿，换房/离房由 `LivingView` 卸载清空。

根 `PlayerViewController` 的 `showToast` 走 `common/theme/live_toast_view.dart` 的 `LiveToastController`，与 Pusher 共用同一品牌 Toast；`LiveToastView` 挂在 `PlayerView` 的 Stack 顶层，`LiveToastController.dismiss()` 只取消当前提示。被踢下线按 `KickedOutReason` 映射 `tuilivekit.player.interruption.*` 文案，同时作为结束原因交给 `SummaryView`。关闭点击先 `await leaveChannel()` 再回调 `onCloseClicked`，并用 `_isClosing` 防重；换房时 `setLiveInfo` 会 dismiss 当前提示、复位 `idle`、清除结束原因与后台采集意图；`liveEnded` / `kickedOut` 进入 `end` 时清掉待入房请求与 joinInProgress。

观众端前后台采集由 `_PlayerViewState` 的 `WidgetsBindingObserver` 驱动：暂停时 `suspendCapture` 记录摄像头前后方向、`LiveSeatStore.muteMicrophone()` 并关闭摄像头（含 CoGuestIcon 正在进行的开启请求），恢复时 `restoreCaptureIfNeeded` / `restoreMicrophoneIfNeeded` 用请求 ID 过滤迟到结果，只为仍在本场麦位上、且仍被允许开麦的本人恢复；恢复失败或已不在麦位会重新关闭设备。

`PlayerViewController` 的启播与音量是两套独立入口，与 iOS `PlayerView.startPlay` / `setVolume` 对齐：`startPlay()` 只负责按当前 liveID 发起静音预览并解除 `end`，不再接受静音参数；`setVolume(int)` 由入口显式调用，音量保存在 `PlayerVideoViewController.volume` 并在 `startPreview` 时恢复，因此停播重播不会丢掉当前设置。取值常量 `PlayerViewController.previewVolume`（0）与 `roomVolume`（100）对应 iOS `PageCell.startPreview` 的 `setVolume(0)` 和 `joinChannel` 的 `setVolume(100)`：`PageCell.startPreview` 先设预览音量再启播，`_performJoin` 在发起进房前设房内音量（不等成功回调），`leaveChannel` 恢复预览音量。独立接入 `PlayerView` 时若需要出声，宿主需自行调用 `setVolume`。

`_SwipeBehavior` 归 `_PagerViewState`，初值 `previewOnly`，只由 `PageCell` 持有的 `PlayerViewController.onJoinLiveClicked`（入口卡点击发起的进房成功后回调，切 `autoEnterRoom`）与 `_handleClose` / `onCloseClicked`（回滚 `previewOnly`）迁移，不从状态名字符串反推；进房失败不改策略。关闭点击的离房在 `PlayerViewController._handleCloseClick → leaveChannel` 内完成，`PagerView._handleClose` 只复位策略，不调用整体清理；全部 PageCell 的停播与离房只留给 `PagerView.dispose`。策略变化时把 `joinLiveEntranceEnabled` 下发给全部缓存 PageCell；状态判断继续使用 `PlayerStatus` 枚举。`LiveListViewController` 保留 `setData`、`appendData`、`isAttached` 及挂载前数据暂存，具体 attach/detach 目标改为 PagerView。对齐 Android `PagerView.handleCloseClicked`，关闭事件在组件内闭环，`LiveListView` 与 `PagerView` 均不再暴露 `onClose`。

观众设备控制链位于 `player/living/coguest/player_co_guest_device_store.dart`，由 `CoGuestIcon` 按房间持有和绑定；`CoGuestingPanel` 只转发开关/下麦操作并渲染实际席位状态，没有增加公开入口或 barrel 导出。

```text
PlayerViewController._adminDeviceRequestsEnabled
→ PlayerViewImpl → LivingView → CoGuestIcon → PlayerCoGuestDeviceStore
→ LiveSeatStore.seatList 实际 allowOpen / 设备状态
├── 主播锁定：Toast；重复点击被锁设备继续 Toast
└── 锁转解禁：按本次连麦原开启意愿恢复
    ├── 麦克风：系统权限 → unmuteMicrophone
    └── 摄像头：系统权限 → openLocalCamera(当前前后摄像头)
```

首次上麦使用 `openLocalMicrophone`；语音申请不打开摄像头，视频申请在麦克风开启完成后继续开摄像头。`RequestingPanel` 的「视频连麦」只在 `idle` 时调用 `onRequestSettings` 先打开 `SettingsPanel(preview)`，由面板的「申请连麦」按钮再发起 `applyForSeat(true)`，「语音连麦」仍直接申请，与 iOS `RequestingPanel.videoButton` / Android `showVideoDetailDialog()` 一致；`SettingsPanel` 收起（返回键、点击外部或已申请）时先 `stopCameraTest()` 再交回宿主，使摄像头测试预览不在视频连麦前残留，与 iOS `sheetWillDismiss` 及 Android `SettingsPanel.dismiss` 对齐。`CoGuestIcon` 为麦克风与摄像头各自维护请求 ID：权限与 SDK 操作串行完成后用请求 ID 过滤迟到结果，非 resumed、`liveInfo` 为空或状态已离开 `coGuesting` 时回滚关闭对应设备；`invalidateCameraRequests(allowRestore:)` / `invalidateMicrophoneRequests()` 由根的前后台链路调用。`coGuesting → idle` 迁移会关麦；被踢下麦先失效麦克风请求再关麦关摄像头。Store 自持席位 ValueNotifier 订阅、每种设备的开启意愿和操作身份、房间激活身份及下麦阻断。所有提示经 `onToast` 交给根 `PlayerViewController`，不再使用第三方 Toast。

`player/living/follow_service.dart` 的 `PlayerFollowService` 除缓存关注状态外，还注册 `V2TimFriendshipListener.onMyFollowingListChanged`，变化后按 userID 重新 `checkFollowType` 并通知，对应 iOS `HostInfoView.registerFriendshipListener`；监听随 `HostInfoView` 的挂载生命周期建立与移除，拉取失败保留上次展示。

根 `PlayerViewController` 在离房调用之前、换房、结束和销毁时同步停用设备控制，不等待页面帧或 leaveLive Future。`CoGuestingPanel` 下麦开始及踢下麦事件调用 `beginSeatExit`；下麦失败只能解除同一次退出阻断，已取消的恢复意愿不重放。

`PusherCoGuestStore` 只提供远端麦克风管理与断开，管理面板移除摄像头项。当前席位被锁定则 `openRemoteMicrophone(unlockOnly)`，未锁且关闭时提示观众手动开启，否则调用 `closeRemoteMicrophone`。关闭/解禁成功后提示目标昵称；昵称合并空白，空值回退 userID，按 `characters` 保留前 8 个完整字符后追加省略号，请求发起时捕获名称。结果通过原激活身份过滤迟到回调后，经根 PusherView 转发 Living Toast。观众 Store 仅在允许开麦由 false 转 true 时提示解禁，初始/重复快照不提示，设备恢复继续取决于原开启意愿。管理面板用等宽 Expanded 两列、40 间距及 200 总宽上限，保持原安全区与面板关闭生命周期。观众自身摄像头控制、系统权限与 AtomicXCore 5.0.2 依赖保持原样。

这里只描述接入链路；本地图不记录端上运行验证结果。

连麦入口：Pusher 的 LiveBottomToolbarView 使用 L1-C 与米白新申请消息气泡；Player 的 CoGuestIcon 以默认/已接通资源切换，接通时显示冰蓝实底，不再绘制波形动画。状态和设备持有方保持上述链路。Pusher 资源为组件 assets 根目录中 `livekit_living_coguest`、`livekit_living_coguest_unread` 的 PNG；Player 保留 `livekit_coguest_idle` / `livekit_coguest_connected` 完整圆底 PNG（同样位于 assets 根目录），使用 39×39 逻辑像素的圆底外壳（背景 `0x2E0A0A0F` + 白 6% 描边），与底栏其他控件一致。

席位公共视觉收口到 `common/theme/live_seat.dart`，对应 iOS `Common/Theme/LiveSeat.swift`：`LiveSeat` 是声明式 `StatelessWidget`，公开入参 `emptyTitle` + `(name, avatarURL, microphoneOn)` + `(isEmpty, showsNoVideo, showsOverlay)` 与 iOS 两个方法 `updateContent` / `updateVisibility` 的全集对等；三层私有子视图（空位内缩 1pt 半透明填充 + 邀请文案、对角线渐变加按短边自适应的居中头像（尺寸按下文统一策略连续适配）、左上 6 的 20×14 麦克风胶囊 + 底部 14 行高 10pt 昵称 + 透明到 40% 黑压暗）与 iOS 子视图逐一对齐。基类只消费展示输入，不读取任何 Store。 音量以声明式入参 `volume` 提供（对应 iOS / Android 的 `updateVolume`），达到 `LiveSeat.volumeWaveThreshold` 时无视频头像外圈显示音浪：`_LiveSeatSpeakingWave` 用 1400ms `AnimationController` + `Cubic(0.16, 0.5, 0.4, 1)` 驱动双层圆环，第二层取 `(value + 0.5) % 1` 错开半个周期，`MediaQuery.disableAnimations` 时退化为单层静态圆环；阈值单独成常量，Pusher 与 Player 的席位 Adapter 均已实现当前 SDK 的 onVolumeChanged，将真实回调音量投影到同一 LiveSeat。Player `player/videoview/player_unit_view.dart` 与 Pusher `pusher/video/pusher_unit_view.dart` 都是薄壳：各自把 `UnitInfo` + 身份/后台/本地摄像头/布局模式投影成 `LiveSeat` 入参。观众端主播席位不显示挂件；观众 `userSuspendStatus == .inBackground` 与摄像头关闭同样显示无视频占位。

Pusher Living 顶部仅在 Android 使用 `max(MediaQuery.viewPadding.top, LayoutBuilder页面高度 × 46 / 844)`，对应用户指定的 iOS 顶部视觉留白比例与 Ardot `77:405` 的y46/页面高844；iOS分支保持`MediaQuery.padding.top−1`。仅移动完整Header，不缩放62高Header、36高胶囊或内部间距。系统保护区独立读取并与比例位置取max；尺寸变化自动重建，宿主不随键盘缩小页面。

### 共享美颜

`common/beauty/beauty_panel.dart` 的 `BeautyPanelController` 是 Prepare / Living / Player 设置共同使用的展示入口。先刷新原生使用期并请求 SDK 面板；授权或 GL 初始化中时等待就绪通知再展示，确定不可用或等待超时后显示 `beauty_view.dart` 基础美颜，不嵌套旧抽屉。两条路径均不压暗预览。presentation 通知 Pusher 根隐藏整个 Prepare（包含渐变与控件），关闭再恢复；根 Stack 使用 expand 约束，Prepare 隐藏不能使 Positioned 视频层缩成零尺寸。请求 ID 与 generation 过滤迟到关闭、销毁后的展示结果；请求 ID 以时间戳起步并使用 64 位传输，避免 Dart 热重启后与仍存活的原生已关闭编号重复。

同文件 `AdvancedBeautySession` 由挂载的 Player / Pusher 根 acquire/release，订阅 AtomicXCore 登录及 cameraStatus，编排前后台和账户切换；只保存处理器使用期，不持有直播业务状态。高级处理确认可用后将 BaseBeautyStore 三项归零，避免叠加；不可用时由 `BeautyPreferences` 按账户恢复基础参数。基础偏好继续保存在 application-support 下，高级参数由原生按 SDKAppID / userID 键保存，关闭面板仍保留效果。

`common/platform/advanced_beauty_channel.dart` 是唯一美颜 MethodChannel 接口。插件 [`AdvancedBeautyPlugin.kt`](tui_live_kit/android/src/main/kotlin/com/tencent/livekit/tui_live_kit/AdvancedBeautyPlugin.kt) / [`AdvancedBeautyPlugin.swift`](tui_live_kit/ios/Classes/AdvancedBeautyPlugin.swift) 注册共享 TRTC 本地帧回调、原生面板和关闭通知；同目录 `BeautyProcessor` 持有 TEBeautyKit、SDK 分类配置和参数持久化。Android 只在 TRTC GL 回调创建/销毁纹理处理器；iOS 处理 CVPixelBuffer 并用锁保护停用。视频帧不经过 Dart。SDK 面板与 Dialog 各自使用平台原生视图承载。

根移除、停用相机、账号切换和后台均解除处理或释放 SDK；inactive 不视为后台，避免原生 Dialog 获取焦点时误关美颜。鸿蒙等不支持平台保持基础面板。

Pusher State 在进入 Living、阶段回退、前后台、activate/deactivate 和 releaseSession 时按需调用 `common/platform/screen_awake_channel.dart`。Android/iOS 由组件原生 TUILiveKitPlugin 以 owner 租约保存并恢复 Window.FLAG_KEEP_SCREEN_ON / UIApplication.isIdleTimerDisabled；暂停及结束等待保持，最后租约退出或 engine/activity detach 恢复。Android 配置变化重新挂载后只恢复仍有效租约。无该插件桥的平台保留系统默认行为，不声明亮屏已生效。

### 评论与通知的布局边界

`common/barrage/barrage_stream_view.dart` 内的 `LiveInteractionLayout` 由两端 Living 复用：常态滚动容器底边固定，入场预留28+4、礼物按实际44/92+4仅裁剪评论顶部，不抬底边；完整内容高度独立回传。普通行、礼物行和本地公告保持13字号、自然行高、水平6/垂直3内距、行距2，行内等级徽章18、主播35×18、礼物22居中；全局等级徽章仍15。列表以稳定消息ID保留历史锚点，只在新到的主播消息强制贴底，取消320ms再次滚动。

Pusher `SeatViewProvider` 记录主播、空席与观众的真实全局矩形，经Video/根入口交给Living；九宫格及有观众的动态布局以最大底边+8为顶部边界，几何缺失时预留整个舞台，小窗继续只限制宽度。Player Video用`liveID:index`隔离Unit，渲染时记录实际矩形，经根入口交给Living；常态底边至席位底部+8的可用高度>=184才动态扩展，否则保持默认184。该门槛独立于通知、键盘和礼物面板；礼物面板只约束正常评论底边。

两端输入只移动评论，打开时分别捕获当前可见高度和正常内容高度，通知继续消费正常布局。`GiftDisplayView`仅接收显式`noticeBottom/noticeTopBoundary`，不再持有评论、入场或礼物面板的位置计算；胶囊裁剪和高级特效画布分开。Pusher由根入口首次CONNECTED注入本地公告，Player在房内Living挂载时显示；文案为组件中英资源，退出/复用随宿主清理，不发送SDK消息。直播状态入口13字号、高24、箭头高9；实时提示卡按内容自然增高，图标34居中、文字左61，背景透明。

## 连麦头像尺寸策略

头像尺寸由各端公共 LiveSeat 统一计算，Pusher / Player 不单独覆盖：`target = clamp(min(width, height) × 0.44, 42, 67)`，`fit = max(0, max(0, min(width−16, height−32)) / 1.38 − 6)`，最终直径 `min(target, fit)`。均为平台逻辑单位；6 = 圆环两侧各外扩2 + 描边2，按最大缩放1.38保守预留。头像居中，左右至少8、上下至少16留白；空间不足时可低于42。Android 只在最终输出转换为整数px，其余平台保留逻辑小数。相同席位几何得到相同逻辑尺寸，不依赖主播/观众身份或模板ID。

### 音浪初始状态与静音

LiveSeat 在麦克风关闭时将传给无视频层的音量投影为0；无音量时 `_LiveSeatSpeakingWave.build` 直接返回头像，不创建圆环。有音量时在 `didChangeDependencies` 而非 `initState` 读取 MediaQuery 并同步动画，避免首次挂载就有音量时依赖尚未初始化的异常，同时响应减少动态效果设置。静音、空席和视频开启后圆环不参与渲染；减少动态效果时仅在讲话期间显示静态圈。

### 席位音量数据接入

`PusherUnitAdapter` 与 PlayerVideoView 的 `_PlayerUnitAdapter` 在原有席位 notifier 中保存 `(UnitInfo快照, 最新音量)`，SDK onVolumeChanged 按房间/席位/用户身份匹配后更新，UI 下发至 `PusherUnitView` / `PlayerUnitView` 的 volume。回调只改变音量时也会通知重绘，不等待 SDK 再建席位。SDK UnitInfo 可变，因此先复制八个展示字段，防止原对象复用掩盖换人。麦克风关闭、清空或换人归零，音量限制0～100；Pusher退出Living清零并在dispose移除阶段listener，Player退出房内状态、停止预览、换房或dispose清理音量/席位。释放后及显式旧房间/用户回调被忽略。无新SDK订阅、Timer或公开UI接口。

## Player 播放期间屏幕常亮

Player 根实现根据 playing / inRoom / coGuest 状态持有系统常亮；idle / end、页面移除和进入后台时释放，回到前台有效播放时重新获取。房外播放也适用，不以是否进房作为门槛。常亮只影响系统自动息屏，不改 SDK 播放与设备状态。Pusher/Player State 各持 common/platform/screen_awake_channel.dart 中的 ScreenAwakeLease，共用前台与挂载资格、owner 和重复启停过滤；入口只提供各自业务请求及生命周期。ScreenAwakeChannel 继续调用现有原生桥，最后一个租约释放时恢复原值，未注册桥的平台保留系统默认行为。

## Player 主播连线展示

视频 Adapter 允许当前播放会话中的跨房主播席位，以实际挂载的 RenderBox 投影连线状态与全局几何；`player_view.dart` 向 Living 提供状态查询和几何通知。Living 在席位上缘上方22逻辑像素显示「连线中」，清屏时随业务内容隐藏；不建立本地时长。离房/换房、RenderBox detach 清除投影，旧会话几何回调被隔离。连线舞台背景与 Pusher 复用 Ardot 874:194 直接导出的资源；本房主播在连线期间也显示席位昵称和麦克风挂件。

## Pusher 主播连线

`pusher_view.dart` 根持有 `living/cohost/pusher_cohost_store.dart`，进入Living启用，回退/结束/释放停用并取消监听；根与Living分别消费视频/舞台状态和弹层展示。Store 的 SDK ValueListenables、CoHostListener、IM关注监听、分页与写操作都在本文件闭环，响应和超时用激活代次、请求身份过滤迟到结果；退出先串行取消外邀，失败时保留未确认项并停止退出。

CoHost 目录的 Actions、IncomingInvite、CandidateList、RandomConnection 四个独立Widget分别对应同名iOS职责；公共 BottomSheetController 关闭完成后切换连线弹层。CandidateList 的关注/互关与推荐分组和随机卡同滚；追加列表隐藏随机卡。Incoming 禁止蒙层点击关闭，接受/拒绝期间停止Store本地超时，失败且仍是同一邀请时按原截止时间恢复。Living复用根elapsedSeconds监听更新Pusher连线计时，Player只显示状态文字。

RandomConnection 的扫描4.8秒、双波纹2.8秒；头像位置随机且避开中心与相邻头像，按角度显示。关闭、滚出、后台及TickerMode停用时停止动画，减少动画设置保留静态头像；按钮只显示开发中Toast。资源直接导自Ardot并按1/2/3x保留画布，扫光136×142画布在112×112旋转容器中偏移−12/−18并裁掉中心41直径区域。

Pusher视频状态增加内部连线投影；连线时隐藏空席位、使用宫格几何、停用观众管理命中，并保持本地设备状态优先。席位缓存按源liveID和index组合寻址，避免跨房索引相同导致设备状态互相覆盖。入口公开API不变。

公共 `LivingScrimView` 和方向类型与 LiveSeat 同处 `common/theme/live_seat.dart`，承担两端状态行以及 Pusher 上下渐变；布局与状态判断仍归各自宿主。

## 宿主准备附加内容

`PusherView.prepareAccessory` 是可选的宿主 Widget，转发到 `prepare/pusher_prepare_view.dart` 的编辑内容 Stack；safeArea 内左右60、顶部4、高48，仅 Prepare 编辑时显示，倒计时、Living、Summary及设置/封面浮层沿原阶段可见性管理。综合 App 用于显示视频/语音/游戏类型栏，组件不拥有 App 类型状态或跳转，未传入时行为不变。
