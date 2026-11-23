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
  String barrageNewMessages(Object count) {
    return '$count 条新消息';
  }

  @override
  String get barrageInputHint => '发条弹幕互动一下...';

  @override
  String get barrageErrorMuted => '你已被禁言，暂时无法发送评论';

  @override
  String get barrageErrorAllMuted => '当前直播间已开启全员禁言';

  @override
  String get barrageErrorTooFrequent => '发送太快了，请稍后再试';

  @override
  String get barrageErrorContentRejected => '评论内容不符合规范，请修改后重试';

  @override
  String get barrageErrorTooLong => '评论内容过长，请缩短后发送';

  @override
  String get barrageErrorLoginExpired => '登录已失效，请重新登录';

  @override
  String get barrageErrorLoginElsewhere => '账号已在其他设备登录，请重新登录';

  @override
  String get barrageErrorNotJoined => '尚未进入直播间，暂时无法发送评论';

  @override
  String get barrageErrorRoomUnavailable => '直播间已不可用，无法发送评论';

  @override
  String get barrageErrorNoPermission => '暂时无法在当前直播间发送评论';

  @override
  String get barrageErrorNetwork => '网络连接异常，请检查网络后重试';

  @override
  String get barrageErrorTimeout => '评论发送超时，请稍后重试';

  @override
  String get barrageErrorSendRejected => '评论未能发送，请稍后重试';

  @override
  String get barrageErrorSendFailed => '评论发送失败，请稍后重试';

  @override
  String get interactionTitle => '互动消息';

  @override
  String get barrageHostTag => '主播';

  @override
  String get giftEmpty => '暂无礼物';

  @override
  String giftNewItems(Object count) {
    return '$count 件新礼物';
  }

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
  String audienceMutedToast(Object name) {
    return '已禁言「$name」';
  }

  @override
  String audienceUnmutedToast(Object name) {
    return '已解除对「$name」的禁言';
  }

  @override
  String audienceKickedToast(Object name) {
    return '已将「$name」踢出直播间';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonAdd => '添加';

  @override
  String get commonClose => '关闭';

  @override
  String get sceneDefault => '场景';

  @override
  String sceneCustomSuggestion(Object index) {
    return '场景 $index';
  }

  @override
  String sceneCopySuffix(Object name, Object index) {
    return '$name $index';
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
  String get sceneNameLimit => '名称不能超过 20 个字符';

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
  String get errorStartMixing => '启动混流失败';

  @override
  String get errorSourceNotFound => '画面源不存在';

  @override
  String get errorSourceDuplicated => '相同的内容已在当前场景中添加，不能重复添加';

  @override
  String get liveShareCopied => '直播间 ID 已复制';

  @override
  String get liveShareTooltip => '分享直播间（复制房间 ID）';

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
  String get imageFormatsHintNoGif => '支持 BMP / JPG / PNG 格式';

  @override
  String get imageSizeTooLarge => '图片尺寸不能超过 8192×8192';

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
  String get videoFileFormatsHint => '支持 MOV / MP4 / MKV 格式';

  @override
  String get onlineVideoEditTitle => '编辑在线视频';

  @override
  String get onlineVideoAddTitle => '添加在线视频';

  @override
  String get onlineVideoUrlLabel => '视频地址';

  @override
  String get onlineVideoUrlHint =>
      'rtmp:// 直播流，或 .m3u8 / .flv / .mov / .mp4 / .mkv 格式的 http(s) 媒体地址';

  @override
  String get onlineVideoUrlInvalid =>
      '请输入合法的 RTMP 直播流地址或 HTTP(S) 媒体地址\nHTTP(S) 媒体地址支持 .m3u8 / .flv / .mov / .mp4 / .mkv 格式';

  @override
  String get onlineVideoCacheLabel => '网络缓存';

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
  String get featureComingSoon => '敬请期待';

  @override
  String get beautyNoCamera => '当前场景下未添加摄像头';

  @override
  String get beautyAllCamerasHidden => '摄像头已屏蔽，取消屏蔽后可设置美颜';

  @override
  String get beautyFilterTitle => '美颜滤镜';

  @override
  String get beautySkinSmooth => '磨皮';

  @override
  String get beautyWhiteness => '美白';

  @override
  String get beautyRuddy => '红润';

  @override
  String runtimeSourceError(Object sourceName, Object reason) {
    return '画面源\"$sourceName\"：$reason';
  }

  @override
  String get errorImageLoadFailed => '图片加载失败';

  @override
  String get errorCameraNotAuthorized => '摄像头未授权';

  @override
  String get errorCameraIsOccupied => '摄像头被占用';

  @override
  String get errorCameraDisconnected => '摄像头已断开';

  @override
  String get errorVideoFileNotExist => '视频文件不存在';

  @override
  String get errorOnlineVideoProtocol => '在线视频协议不支持';

  @override
  String get errorLocalVideoFormat => '本地视频格式不支持';

  @override
  String get errorHevcDecoder => '无可用解码器';

  @override
  String get errorInvalidParams => '参数错误';

  @override
  String get errorUnknown => '未知错误';

  @override
  String get errorOperationFailed => '操作失败，请重试';

  @override
  String get errorOnlineVideoConnectFailed => '在线视频连接失败';

  @override
  String get errorOnlineVideoConnectionLost => '在线视频连接中断';

  @override
  String get errorScreenSourceClosed => '分享的窗口或屏幕已关闭';

  @override
  String get errorScreenDisplayChanged => '显示器已断开或发生变更';

  @override
  String get errorCameraRunFailed => '摄像头运行失败';

  @override
  String get errorScreenRunFailed => '屏幕采集失败';

  @override
  String get errorImageRunFailed => '图片显示失败';

  @override
  String get errorVideoFilePlayFailed => '视频文件播放失败';

  @override
  String get errorOnlineVideoPlayFailed => '在线视频播放失败';

  @override
  String get mixingStoppedSourceLost => '画面源丢失，混流已停止';

  @override
  String get orientationLandscape => '横屏';

  @override
  String get orientationPortrait => '竖屏';

  @override
  String get liveStart => '开始直播';

  @override
  String get liveStarting => '开播中…';

  @override
  String liveStartFailed(Object code, Object message) {
    return '开播失败，错误码：$code；错误信息：$message';
  }

  @override
  String get liveStartFailedSensitiveInfo => '开播失败：直播间名称等信息包含敏感内容，请修改后重试';

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
  String get liveSummaryDuration => '直播时长';

  @override
  String get liveSummaryGiftsSent => '收到礼物';

  @override
  String get liveSummaryViewers => '观看人次';

  @override
  String get liveSummaryMessages => '评论数';

  @override
  String get liveSummaryLikes => '点赞次数';

  @override
  String get liveSummaryGiftSenders => '送礼人数';

  @override
  String get liveSummaryGiftIncome => '礼物收益';

  @override
  String get liveSummaryUnitPiece => '件';

  @override
  String get liveSummaryUnitCoin => '币';

  @override
  String get liveSummaryUnitPerson => '人';

  @override
  String get liveSummaryUnitMessage => '条';

  @override
  String get liveSummaryUnitTime => '次';

  @override
  String get liveSummaryDone => '完成';
}
