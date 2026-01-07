// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_trtc => '腾讯云音视频';

  @override
  String get app_user_id => '用户ID';

  @override
  String get app_enter_user_id => '请输入您的UserID';

  @override
  String get app_login => '登录';

  @override
  String get app_logout => '退出登录';

  @override
  String get app_confirm => '确定';

  @override
  String get app_cancel => '取消';

  @override
  String get app_enter_nickname => '请输入你的用户昵称';

  @override
  String get app_tencent_cloud => '腾讯云';

  @override
  String get app_login_fail => '登录失败';

  @override
  String get app_next => '继续';

  @override
  String get app_nick_name => '昵称';

  @override
  String get app_room_id => '房间ID';

  @override
  String get app_anchor => '主播';

  @override
  String get app_audience => '观众';

  @override
  String get app_me => '我';

  @override
  String get app_live => '直播';

  @override
  String get app_follow_count => '关注';

  @override
  String get app_fans_count => '粉丝';

  @override
  String get app_set_nickname => '设置昵称';

  @override
  String get app_save => '保存';

  @override
  String get app_video => '在线直播';

  @override
  String get app_video_description => '开播预览·智能美颜·连麦PK';

  @override
  String get app_voice => '语聊房';

  @override
  String get app_voice_description => '高音质·大房间·平滑上下麦';

  @override
  String app_broadcast(Object xxx) {
    return '$xxx 开直播';
  }

  @override
  String get app_self_center => '个人中心';

  @override
  String get app_log => '日志';

  @override
  String get app_live_content => '通过 Live API 构建互动视频直播，为您带来清晰流畅的直播体验。';

  @override
  String get app_voice_content => '通过 Live API 搭建互动语音聊天室，为您带来低延迟高音质的体验。';

  @override
  String get app_conference => '会议';

  @override
  String get app_conference_description => '快速会议·邀请入会·会中管控·共享屏幕';

  @override
  String get app_call => '通话';

  @override
  String get app_call_description => '响铃通知·通话悬浮窗·通话卡顿优化';

  @override
  String get app_call_user_ids => '通话列表';

  @override
  String get app_call_media_type => '媒体类型';

  @override
  String get app_call_optional_params => '可选参数';

  @override
  String get app_call_group_id => '群组ID';

  @override
  String get app_call_initiate => '发起通话';

  @override
  String get app_call_media_type_audio => '语音';

  @override
  String get app_call_media_type_video => '视频';

  @override
  String get app_call_user_ids_separated => 'ID 使用\',\'隔开';

  @override
  String get app_call_enable_floating_window => '开启悬浮窗功能';

  @override
  String get app_call_enable_incoming_banner => '开启来电横幅功能';

  @override
  String get app_call_enable_mute_mode => '开启静音模式';
}
