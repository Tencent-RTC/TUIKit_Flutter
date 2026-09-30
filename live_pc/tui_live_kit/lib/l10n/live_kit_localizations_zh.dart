// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'live_kit_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LiveKitLocalizationsZh extends LiveKitLocalizations {
  LiveKitLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get barrageEmpty => '暂无消息';

  @override
  String get barrageLatest => '最新消息';

  @override
  String get barrageBackToBottom => '回到底部';

  @override
  String get barrageInputHint => '发条弹幕互动一下...';

  @override
  String get interactionTitle => '互动消息';

  @override
  String get giftEmpty => '暂无礼物';

  @override
  String get giftSent => '送出';

  @override
  String get audienceTitle => '观众';

  @override
  String get audienceEmpty => '暂无观众';

  @override
  String get audienceMute => '禁言';

  @override
  String get audienceUnmute => '取消禁言';

  @override
  String get audienceKick => '踢出';

  @override
  String get audienceMutedTag => '已禁言';

  @override
  String get loginBrandTitle => '直播推流助手';

  @override
  String get loginTabUsername => '用户名登录';

  @override
  String get loginUsernameHint => '请输入用户名';

  @override
  String get loginButton => '登录';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonAdd => '添加';

  @override
  String get commonClose => '关闭';

  @override
  String get commonConfirm => '知道了';

  @override
  String get errorDialogTitle => '操作失败';

  @override
  String get sceneGame => '游戏直播';

  @override
  String get sceneMovie => '观影陪伴';

  @override
  String get sceneChat => '连麦聊天';

  @override
  String get sceneTalk => '日常唠嗑';

  @override
  String get sceneRest => '休息中';

  @override
  String get sceneDefault => '场景一';

  @override
  String sceneCustomSuggestion(Object index) {
    return '自定义$index';
  }

  @override
  String sceneCopySuffix(Object name) {
    return '$name 副本';
  }

  @override
  String get sceneMenuRename => '重命名';

  @override
  String get sceneMenuDuplicate => '复制';

  @override
  String get sceneMenuDelete => '删除';

  @override
  String get sceneRenameTitle => '重命名场景';

  @override
  String get sceneNameHint => '场景名称';

  @override
  String get sceneAddTitle => '添加预设场景';

  @override
  String get sceneIconPick => '选择图标';

  @override
  String get sceneGroupLandscape => '横屏场景';

  @override
  String get sceneGroupPortrait => '竖屏场景';

  @override
  String get sourceAddTitle => '添加画面源';

  @override
  String get sourceTypeCamera => '摄像头';

  @override
  String get sourceTypeCameraDesc => '采集摄像头画面';

  @override
  String get sourceTypeScreen => '屏幕';

  @override
  String get sourceTypeScreenDesc => '屏幕 / 窗口捕获';

  @override
  String get sourceTypeImage => '图片';

  @override
  String get sourceTypeImageDesc => '静态图片素材';

  @override
  String get sourceTypeOnlineVideo => '在线视频';

  @override
  String get sourceTypeOnlineVideoDesc => '网络视频流地址';

  @override
  String get sourceTypeVideoFile => '视频文件';

  @override
  String get sourceTypeVideoFileDesc => '本地视频文件';

  @override
  String get sourceNameCamera => '摄像头画面';

  @override
  String get sourceNameScreen => '屏幕共享';

  @override
  String get sourceListEmpty => '当前场景暂无画面源\n点击右上角 + 添加';

  @override
  String get errorStartMixing => '启动混流失败';

  @override
  String get errorSourceNotFound => '画面源不存在';

  @override
  String errorAddSource(Object code) {
    return '添加画面源失败（错误码 $code）';
  }

  @override
  String get cameraEditTitle => '编辑摄像头';

  @override
  String get cameraAddTitle => '添加摄像头';

  @override
  String get cameraDeviceLabel => '选择可用摄像头';

  @override
  String get cameraDeviceHint => '选择摄像头';

  @override
  String get cameraNotFound => '未检测到摄像头设备';

  @override
  String get cameraResolutionLabel => '采集分辨率';

  @override
  String get cameraMirrorLabel => '镜像';

  @override
  String get imageEditTitle => '编辑图片';

  @override
  String get imageAddTitle => '添加图片';

  @override
  String get imageFileLabel => '图片文件';

  @override
  String get imagePickPlaceholder => '选择本地图片';

  @override
  String get imagePickButton => '选择图片';

  @override
  String get imageFormatsHint => '支持 BMP / JPG / PNG / GIF 格式';

  @override
  String get videoFileEditTitle => '编辑视频文件';

  @override
  String get videoFileAddTitle => '添加视频文件';

  @override
  String get videoFileLabel => '视频文件';

  @override
  String get videoPickPlaceholder => '选择本地视频';

  @override
  String get videoPickButton => '选择视频';

  @override
  String get videoFileFormatsHint =>
      '支持 MP4 / MOV / M4V / MKV / AVI / FLV / WMV 格式';

  @override
  String get onlineVideoEditTitle => '编辑在线视频';

  @override
  String get onlineVideoAddTitle => '添加在线视频';

  @override
  String get onlineVideoUrlLabel => '视频地址';

  @override
  String get onlineVideoUrlHint => 'http:// 或 https:// 开头的视频地址';

  @override
  String get onlineVideoProtocolHint => '仅支持 HTTP / HTTPS 协议';

  @override
  String get onlineVideoUrlInvalid => '请输入合法的 http / https 视频地址';

  @override
  String get onlineVideoCacheLabel => '网络缓存';

  @override
  String get onlineVideoCacheAuto => '自动';

  @override
  String get onlineVideoCacheAutoScale => '0（自动）';

  @override
  String get screenEditTitle => '编辑屏幕共享';

  @override
  String get screenAddTitle => '添加屏幕共享';

  @override
  String get screenTabWindow => '窗口';

  @override
  String screenEmpty(Object kind) {
    return '未发现可共享的$kind\n请检查「系统设置 → 隐私与安全性 → 屏幕录制」权限';
  }

  @override
  String get screenEnumFailed => '枚举共享源失败';

  @override
  String filePickRequired(Object label) {
    return '请选择$label文件';
  }

  @override
  String fileFormatUnsupported(Object label, Object ext) {
    return '不支持的$label格式：.$ext';
  }

  @override
  String get fileNotReadable => '文件不存在或不可读';

  @override
  String get playbackVolume => '播放音量';

  @override
  String get tabSources => '画面源';

  @override
  String get tabBeauty => '美颜';

  @override
  String get tabMore => '更多能力';

  @override
  String get featureInDevelopment => '功能开发中';

  @override
  String get featureComingSoon => '敬请期待';

  @override
  String get beautyNoCamera => '当前场景下未添加摄像头';

  @override
  String get beautyFilterTitle => '美颜滤镜';

  @override
  String get beautySkinSmooth => '磨皮';

  @override
  String get beautyWhiteness => '美白';

  @override
  String get beautySharpen => '锐化';

  @override
  String get beautyRuddy => '红润';

  @override
  String get orientationLandscape => '横屏';

  @override
  String get orientationPortrait => '竖屏';

  @override
  String get liveStart => '开始直播';

  @override
  String get liveEnd => '结束直播';

  @override
  String get liveInfoEditTitle => '修改直播间信息';

  @override
  String get liveInfoNameLabel => '直播间名称';

  @override
  String get liveInfoVisibilityLabel => '可见范围';

  @override
  String get liveInfoVisibilityPublic => '公开';

  @override
  String get liveInfoVisibilityPrivate => '隐私';

  @override
  String get liveInfoSave => '保存设置';

  @override
  String liveDefaultName(Object name) {
    return '$name的房间';
  }

  @override
  String liveStatsGiftSenders(Object count) {
    return '$count 人送礼';
  }

  @override
  String get liveSummaryTitle => '直播已结束';

  @override
  String get liveSummarySubtitle => '本场直播数据一览';

  @override
  String get liveSummaryDuration => '直播时长';

  @override
  String get liveSummaryViewers => '累计观看';

  @override
  String get liveSummaryLikes => '点赞总数';

  @override
  String get liveSummaryGiftSenders => '送礼人数';

  @override
  String get liveSummaryDone => '完成';

  @override
  String get languageSwitch => '语言';

  @override
  String get languageFollowSystem => '跟随系统';
}
