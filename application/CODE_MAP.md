# Flutter application Code Map

五 Tab 综合 App，以用户指定的 iOS application 75d8550e 为模版。产品范围为直播、消息、我的；会议、通话、语聊为占位。接入与构建见 [README](README.md)。

复用 [Live](../live/CODE_MAP.md) 的公开 PlayerView/PusherView 与 Chat 现有页面。App 拥有根 Navigator、独立分支导航、登录接入、列表请求投影和 Feed 播放会话编排；SDK Store 为业务事实来源。

SDK 使用 pub.dev 托管包，不绑定仓库外本地 Atomic Engine。其他 Flutter 接入 App 不是本工程 UI 实现来源。

## 已接入调用链

- `lib/main.dart` 持有登录、Chat ThemeState 与 LocaleProvider；SDK 登录状态/资料决定登录、注册和 Home。语言改变重建 Home，默认直播。
- `lib/login/login_store.dart` 只编排请求、缓存和 5 秒资料等待，真实资料来自 `LoginStore.shared`；`login_view.dart` / `register/register_view.dart` 分别负责登录和首次昵称录入。
- `lib/home/home_view.dart` 持有分支 Navigator、未读数 Store 与导航可见性；`home_tab_bar.dart` 是五等分 56 高文字底栏。消息子页隐藏底栏，其他分支保留独立栈。
- `lib/live/home/live_home_list_store.dart` 将真实 `LiveListStore` 返回值投影为独立分页快照，游标、请求代次与可见性归 App；不修改 SDK 状态。
- `lib/mine/mine_view.dart` 订阅当前资料，设置入口→`settings/mine_settings_view.dart`→头像/昵称/语言独立页面。资料写操作仅设置宿主持有，SDK 是成功结果的事实来源。
- `lib/mine/settings/profile_image.dart` 与 `mine_page_header.dart` 提供本分支共用图片和导航栏；头像选择 20 个官方 URL，四列按剩余空间布局。
- `lib/mine/log/log_upload_view.dart` 选择真实日志，`lib/common/platform/log_share.dart` 封装原生通道。Android 私有日志经 FileProvider 限定缓存子目录分享，iOS 仅枚举 SDK log / IM cache 并使用系统分享；不上传文件、不包含媒体或凭证文件。

品牌/个人页素材按用户授权取自指定 iOS 模版；Live 新图标仍取 Ardot。系统 inset 使用 MediaQuery，Android 主 Activity 以 `adjustResize` 提供 IME inset，页面 Scaffold 不自动压缩，评论输入自行消费键盘高度；页面字号与控件尺寸不按整屏缩放。

## 正式直播首页

| 文件（lib/live/） | 职责与模版依据（75d8550e） |
|---|---|
| `home/live_home_view.dart` | LiveHomeViewController：共享列表投影、模式、活动性、路由、防重；列表与预览不再使用临时骨架。 |
| `home/live_home_header_view.dart` | LiveHomeHeaderView：双列/预览与开播入口，预览轻透明材质。 |
| `home/live_home_item_view.dart` / `home/live_home_list_view.dart` | LiveHomeItemView/LiveHomeListView：卡片、两列、刷新、分页、空错态与可见矩形。 |
| `home/live_home_preview_item_view.dart` | LiveHomePreviewItemView：封面/播放器槽、进房按钮与房外信息；不持业务 Store。 |
| `home/live_home_preview_view.dart` | LiveHomePreviewView：垂直 PageView、最多3个 Session、当前页声音、真实join/leave、CoGuest锁定、背景清理与迟到请求。 |
| `home/live_home_player_view.dart` | LiveHomePlayerViewController：双列直达房内宿主，持独立列表快照与关闭。 |
| `home/live_home_room_transition.dart` | LiveHomeRoomTransition：可见卡片矩形展开；封面与原尺寸文字分层，退场淡出，减少动态效果退化。 |
| `broadcast_type_bar_view.dart` / `pusher_view.dart` | BroadcastTypeBarView/PusherViewController：App类型栏与视频Pusher宿主；语音/游戏占位，不新增SDK能力。 |

首页视频画布始终占根内容全屏；预览 PageView 的视口扣除底栏56+实际viewPadding.bottom，但每页内视频通过OverflowBox保持原全屏尺寸，信息层也锚到同一底栏边界。进房后扩大视口，隐藏根头栏/底栏，不重建同页Player。当前页进房后后续翻页自动进房，退出预览重置该意图。双列直达页拥有独立游标，避免它的分页改变首页列表。

根Tab隐藏不销毁分支Navigator/滚动位置；Live通过active标记释放播放会话。后台停止房外预览，保留当前已进房页并交给原Player处理设备策略。当前没有Call业务订阅/通话打断接入，符合占位范围。

`common/platform/effect_license.dart` 仅提交授权配置，按既有Live原生命令→FTCMediaXBase顺序执行；启动/登录时防重，不进入公开Widget API。登录失效时根Navigator清栈；踢下线且正在Pusher时暂留其原结束/总结流程，退出后回登录，过期直接回登录。SDK Store始终是账号事实来源，App只延迟页面切换。

## 默认 SDK 配置

`lib/debug/generate_test_user_sig.dart` 的 `GenerateTestUserSig` 与原生iOS的Debug/GenerateTestUserSig.swift职责对应，目录/文件采用Flutter的小写下划线命名；统一持有 SDKAppID、SecretKey、UserSig、签名有效期和特效 License；`genTestUserSig(identifier:)` 同文件生成测试签名；LoginStore 与 AppEffectLicense 只引用配置，不再各自定义默认值。默认值复用现有 Flutter Live 接入工程 `live_kit_access/lib/generate_test_user_sig.dart` 的 SDKAppID、测试签名密钥和特效 License。登录参数覆盖顺序为 APP_* → LIVEKIT_* → 默认值；UserSig 非空时优先直接使用。特效授权支持 APP_EFFECT_LICENSE_URL / KEY 覆盖，显式留空可关闭授权提交。App 不依赖其他接入 App 的 Dart 源码或 UI。

目录/文件使用lower_snake_case，类型使用UpperCamelCase，方法/字段使用lowerCamelCase；不豁免Dart命名检查。
