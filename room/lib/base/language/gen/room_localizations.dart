import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'room_localizations_en.dart';
import 'room_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of RoomLocalizations
/// returned by `RoomLocalizations.of(context)`.
///
/// Applications need to include `RoomLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/room_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: RoomLocalizations.localizationsDelegates,
///   supportedLocales: RoomLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the RoomLocalizations.supportedLocales
/// property.
abstract class RoomLocalizations {
  RoomLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static RoomLocalizations? of(BuildContext context) {
    return Localizations.of<RoomLocalizations>(context, RoomLocalizations);
  }

  static const LocalizationsDelegate<RoomLocalizations> delegate =
      _RoomLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @roomkit_input_can_not_empty.
  ///
  /// In en, this message translates to:
  /// **'input can\'t be empty!'**
  String get roomkit_input_can_not_empty;

  /// No description provided for @roomkit_create_room.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get roomkit_create_room;

  /// No description provided for @roomkit_enter_room_id.
  ///
  /// In en, this message translates to:
  /// **'Enter roomID'**
  String get roomkit_enter_room_id;

  /// No description provided for @roomkit_room_type_freedom_speaker.
  ///
  /// In en, this message translates to:
  /// **'Freedom speaker room'**
  String get roomkit_room_type_freedom_speaker;

  /// No description provided for @roomkit_join_room.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get roomkit_join_room;

  /// No description provided for @roomkit_room_type_stage_speaker.
  ///
  /// In en, this message translates to:
  /// **'On-stage speaking room'**
  String get roomkit_room_type_stage_speaker;

  /// No description provided for @roomkit_room_id.
  ///
  /// In en, this message translates to:
  /// **'Room ID'**
  String get roomkit_room_id;

  /// No description provided for @roomkit_room_type.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get roomkit_room_type;

  /// No description provided for @roomkit_start_video.
  ///
  /// In en, this message translates to:
  /// **'Start video'**
  String get roomkit_start_video;

  /// No description provided for @roomkit_stop_video.
  ///
  /// In en, this message translates to:
  /// **'Stop video'**
  String get roomkit_stop_video;

  /// No description provided for @roomkit_your_name.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get roomkit_your_name;

  /// No description provided for @roomkit_enable_speaker.
  ///
  /// In en, this message translates to:
  /// **'Enable speaker'**
  String get roomkit_enable_speaker;

  /// No description provided for @roomkit_enable_audio.
  ///
  /// In en, this message translates to:
  /// **'Enable audio'**
  String get roomkit_enable_audio;

  /// No description provided for @roomkit_enable_video.
  ///
  /// In en, this message translates to:
  /// **'Enable video'**
  String get roomkit_enable_video;

  /// No description provided for @roomkit_mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get roomkit_mute;

  /// No description provided for @roomkit_unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get roomkit_unmute;

  /// No description provided for @roomkit_end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get roomkit_end;

  /// No description provided for @roomkit_member_count.
  ///
  /// In en, this message translates to:
  /// **'Members(xxx)'**
  String get roomkit_member_count;

  /// No description provided for @roomkit_expand.
  ///
  /// In en, this message translates to:
  /// **'Expansion'**
  String get roomkit_expand;

  /// No description provided for @roomkit_user_room.
  ///
  /// In en, this message translates to:
  /// **'xxx\'s room'**
  String get roomkit_user_room;

  /// No description provided for @roomkit_screen_share.
  ///
  /// In en, this message translates to:
  /// **'Screen share'**
  String get roomkit_screen_share;

  /// No description provided for @roomkit_mute_all_audio.
  ///
  /// In en, this message translates to:
  /// **'Mute all'**
  String get roomkit_mute_all_audio;

  /// No description provided for @roomkit_unmute_all_audio.
  ///
  /// In en, this message translates to:
  /// **'Unmute all'**
  String get roomkit_unmute_all_audio;

  /// No description provided for @roomkit_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get roomkit_more;

  /// No description provided for @roomkit_search_members.
  ///
  /// In en, this message translates to:
  /// **'Search members'**
  String get roomkit_search_members;

  /// No description provided for @roomkit_invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get roomkit_invite;

  /// No description provided for @roomkit_role_owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roomkit_role_owner;

  /// No description provided for @roomkit_role_admin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roomkit_role_admin;

  /// No description provided for @roomkit_me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get roomkit_me;

  /// No description provided for @roomkit_room_link.
  ///
  /// In en, this message translates to:
  /// **'Room link'**
  String get roomkit_room_link;

  /// No description provided for @roomkit_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get roomkit_copy;

  /// No description provided for @roomkit_copy_room_info.
  ///
  /// In en, this message translates to:
  /// **'Copy room info'**
  String get roomkit_copy_room_info;

  /// No description provided for @roomkit_msg_all_members_will_be_muted.
  ///
  /// In en, this message translates to:
  /// **'All current and incoming members will be muted'**
  String get roomkit_msg_all_members_will_be_muted;

  /// No description provided for @roomkit_msg_all_members_video_disabled.
  ///
  /// In en, this message translates to:
  /// **'All current and incoming members will be restricted from video'**
  String get roomkit_msg_all_members_video_disabled;

  /// No description provided for @roomkit_msg_members_cannot_unmute.
  ///
  /// In en, this message translates to:
  /// **'Members will unable to turn on the microphone'**
  String get roomkit_msg_members_cannot_unmute;

  /// No description provided for @roomkit_msg_members_cannot_start_video.
  ///
  /// In en, this message translates to:
  /// **'Members will unable to turn on video'**
  String get roomkit_msg_members_cannot_start_video;

  /// No description provided for @roomkit_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get roomkit_confirm;

  /// No description provided for @roomkit_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get roomkit_cancel;

  /// No description provided for @roomkit_disable_all_video.
  ///
  /// In en, this message translates to:
  /// **'Stop all video'**
  String get roomkit_disable_all_video;

  /// No description provided for @roomkit_enable_all_video.
  ///
  /// In en, this message translates to:
  /// **'Enable all video'**
  String get roomkit_enable_all_video;

  /// No description provided for @roomkit_msg_all_members_will_be_unmuted.
  ///
  /// In en, this message translates to:
  /// **'All members will be unmuted'**
  String get roomkit_msg_all_members_will_be_unmuted;

  /// No description provided for @roomkit_msg_members_can_unmute.
  ///
  /// In en, this message translates to:
  /// **'Members will be able to turn on the microphone'**
  String get roomkit_msg_members_can_unmute;

  /// No description provided for @roomkit_confirm_release.
  ///
  /// In en, this message translates to:
  /// **'Confirm release'**
  String get roomkit_confirm_release;

  /// No description provided for @roomkit_msg_all_members_video_enabled.
  ///
  /// In en, this message translates to:
  /// **'All members will not be restricted from video'**
  String get roomkit_msg_all_members_video_enabled;

  /// No description provided for @roomkit_msg_members_can_start_video.
  ///
  /// In en, this message translates to:
  /// **'Members will be able to turn on video'**
  String get roomkit_msg_members_can_start_video;

  /// No description provided for @roomkit_toast_all_video_disabled.
  ///
  /// In en, this message translates to:
  /// **'All videos disabled'**
  String get roomkit_toast_all_video_disabled;

  /// No description provided for @roomkit_toast_all_video_enabled.
  ///
  /// In en, this message translates to:
  /// **'All videos enabled'**
  String get roomkit_toast_all_video_enabled;

  /// No description provided for @roomkit_toast_all_audio_disabled.
  ///
  /// In en, this message translates to:
  /// **'All audios disabled'**
  String get roomkit_toast_all_audio_disabled;

  /// No description provided for @roomkit_toast_all_audio_enabled.
  ///
  /// In en, this message translates to:
  /// **'All audios enabled'**
  String get roomkit_toast_all_audio_enabled;

  /// No description provided for @roomkit_modify_name.
  ///
  /// In en, this message translates to:
  /// **'Modify the name'**
  String get roomkit_modify_name;

  /// No description provided for @roomkit_request_unmute_audio.
  ///
  /// In en, this message translates to:
  /// **'Ask to unmute'**
  String get roomkit_request_unmute_audio;

  /// No description provided for @roomkit_request_start_video.
  ///
  /// In en, this message translates to:
  /// **'Ask to start video'**
  String get roomkit_request_start_video;

  /// No description provided for @roomkit_transfer_owner.
  ///
  /// In en, this message translates to:
  /// **'Make host'**
  String get roomkit_transfer_owner;

  /// No description provided for @roomkit_set_admin.
  ///
  /// In en, this message translates to:
  /// **'Set as administrator'**
  String get roomkit_set_admin;

  /// No description provided for @roomkit_revoke_admin.
  ///
  /// In en, this message translates to:
  /// **'Undo administrator'**
  String get roomkit_revoke_admin;

  /// No description provided for @roomkit_mute_text_chat.
  ///
  /// In en, this message translates to:
  /// **'Mute message'**
  String get roomkit_mute_text_chat;

  /// No description provided for @roomkit_unmute_text_chat.
  ///
  /// In en, this message translates to:
  /// **'Unmute message'**
  String get roomkit_unmute_text_chat;

  /// No description provided for @roomkit_remove_member.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get roomkit_remove_member;

  /// No description provided for @roomkit_msg_transfer_owner_to.
  ///
  /// In en, this message translates to:
  /// **'Transfer the host to xxx'**
  String get roomkit_msg_transfer_owner_to;

  /// No description provided for @roomkit_msg_transfer_owner_tip.
  ///
  /// In en, this message translates to:
  /// **'After transfer the host you will become a general user'**
  String get roomkit_msg_transfer_owner_tip;

  /// No description provided for @roomkit_confirm_transfer.
  ///
  /// In en, this message translates to:
  /// **'Confirm transfer'**
  String get roomkit_confirm_transfer;

  /// No description provided for @roomkit_toast_you_are_owner.
  ///
  /// In en, this message translates to:
  /// **'You are now a host'**
  String get roomkit_toast_you_are_owner;

  /// No description provided for @roomkit_toast_owner_transferred.
  ///
  /// In en, this message translates to:
  /// **'The host has been transferred to xxx'**
  String get roomkit_toast_owner_transferred;

  /// No description provided for @roomkit_toast_you_are_admin.
  ///
  /// In en, this message translates to:
  /// **'You have become a conference admin'**
  String get roomkit_toast_you_are_admin;

  /// No description provided for @roomkit_toast_admin_set.
  ///
  /// In en, this message translates to:
  /// **'xxx has been set as conference admin'**
  String get roomkit_toast_admin_set;

  /// No description provided for @roomkit_toast_admin_revoked.
  ///
  /// In en, this message translates to:
  /// **'The conference admin status of xxx has been withdrawn'**
  String get roomkit_toast_admin_revoked;

  /// No description provided for @roomkit_toast_you_are_no_longer_admin.
  ///
  /// In en, this message translates to:
  /// **'Your conference admin status has been revoked'**
  String get roomkit_toast_you_are_no_longer_admin;

  /// No description provided for @roomkit_toast_room_id_copied.
  ///
  /// In en, this message translates to:
  /// **'Room ID copied'**
  String get roomkit_toast_room_id_copied;

  /// No description provided for @roomkit_toast_room_link_copied.
  ///
  /// In en, this message translates to:
  /// **'Room link copied'**
  String get roomkit_toast_room_link_copied;

  /// No description provided for @roomkit_toast_room_info_copied.
  ///
  /// In en, this message translates to:
  /// **'Room information copied successfully'**
  String get roomkit_toast_room_info_copied;

  /// No description provided for @roomkit_leave_room.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get roomkit_leave_room;

  /// No description provided for @roomkit_end_room.
  ///
  /// In en, this message translates to:
  /// **'End room'**
  String get roomkit_end_room;

  /// No description provided for @roomkit_toast_room_ended.
  ///
  /// In en, this message translates to:
  /// **'Room ended'**
  String get roomkit_toast_room_ended;

  /// No description provided for @roomkit_confirm_leave_room_by_genera_user.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave the room'**
  String get roomkit_confirm_leave_room_by_genera_user;

  /// No description provided for @roomkit_confirm_leave_room_by_owner.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t want to end the conference, please assign a new host before leaving the conference'**
  String get roomkit_confirm_leave_room_by_owner;

  /// No description provided for @roomkit_confirm_remove_member.
  ///
  /// In en, this message translates to:
  /// **'Do you want to move xxx out of the room?'**
  String get roomkit_confirm_remove_member;

  /// No description provided for @roomkit_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get roomkit_ok;

  /// No description provided for @roomkit_toast_room_closed.
  ///
  /// In en, this message translates to:
  /// **'The room was closed.'**
  String get roomkit_toast_room_closed;

  /// No description provided for @roomkit_toast_you_were_removed.
  ///
  /// In en, this message translates to:
  /// **'You were removed by the host.'**
  String get roomkit_toast_you_were_removed;

  /// No description provided for @roomkit_toast_audio_invite_sent.
  ///
  /// In en, this message translates to:
  /// **'The audience has been invited to open the audio'**
  String get roomkit_toast_audio_invite_sent;

  /// No description provided for @roomkit_toast_video_invite_sent.
  ///
  /// In en, this message translates to:
  /// **'The audience has been invited to open the video'**
  String get roomkit_toast_video_invite_sent;

  /// No description provided for @roomkit_toast_text_chat_disabled.
  ///
  /// In en, this message translates to:
  /// **'You have been banned from text chat'**
  String get roomkit_toast_text_chat_disabled;

  /// No description provided for @roomkit_toast_text_chat_enabled.
  ///
  /// In en, this message translates to:
  /// **'You are allowed to text chat'**
  String get roomkit_toast_text_chat_enabled;

  /// No description provided for @roomkit_msg_invite_unmute_audio.
  ///
  /// In en, this message translates to:
  /// **'xxx invites you to turn on the microphone'**
  String get roomkit_msg_invite_unmute_audio;

  /// No description provided for @roomkit_msg_invite_start_video.
  ///
  /// In en, this message translates to:
  /// **'xxx invites you to turn on the camera'**
  String get roomkit_msg_invite_start_video;

  /// No description provided for @roomkit_agree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get roomkit_agree;

  /// No description provided for @roomkit_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get roomkit_reject;

  /// No description provided for @roomkit_toast_camera_closed_by_host.
  ///
  /// In en, this message translates to:
  /// **'You were closed camera by the host.'**
  String get roomkit_toast_camera_closed_by_host;

  /// No description provided for @roomkit_toast_muted_by_host.
  ///
  /// In en, this message translates to:
  /// **'You were muted by the host.'**
  String get roomkit_toast_muted_by_host;

  /// No description provided for @roomkit_enter_nickname.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get roomkit_enter_nickname;

  /// No description provided for @roomkit_tip_all_muted_cannot_unmute.
  ///
  /// In en, this message translates to:
  /// **'All on mute audio unable to turn on microphone'**
  String get roomkit_tip_all_muted_cannot_unmute;

  /// No description provided for @roomkit_tip_all_video_off_cannot_start.
  ///
  /// In en, this message translates to:
  /// **'All on mute video unable to turn on camera'**
  String get roomkit_tip_all_video_off_cannot_start;

  /// No description provided for @roomkit_room_name.
  ///
  /// In en, this message translates to:
  /// **'Room name'**
  String get roomkit_room_name;

  /// No description provided for @roomkit_room_running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get roomkit_room_running;

  /// No description provided for @roomkit_err_0_success.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get roomkit_err_0_success;

  /// No description provided for @roomkit_err_general.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unclassified general error'**
  String get roomkit_err_general;

  /// No description provided for @roomkit_err_n2_request_rate_limited.
  ///
  /// In en, this message translates to:
  /// **'Request rate limited, please try again later'**
  String get roomkit_err_n2_request_rate_limited;

  /// No description provided for @roomkit_err_7008_request_rate_limited.
  ///
  /// In en, this message translates to:
  /// **'Request rate limited, please try again later'**
  String get roomkit_err_7008_request_rate_limited;

  /// No description provided for @roomkit_err_10017_muted_in_room.
  ///
  /// In en, this message translates to:
  /// **'You have been muted in the current room'**
  String get roomkit_err_10017_muted_in_room;

  /// No description provided for @roomkit_err_7015_sensitive_words.
  ///
  /// In en, this message translates to:
  /// **'Sensitive words are detected, please modify it and try again'**
  String get roomkit_err_7015_sensitive_words;

  /// No description provided for @roomkit_err_9522_content_too_long.
  ///
  /// In en, this message translates to:
  /// **'The content is too long, please reduce the content and try again'**
  String get roomkit_err_9522_content_too_long;

  /// No description provided for @roomkit_err_network_error.
  ///
  /// In en, this message translates to:
  /// **'The network is abnormal, please try again later'**
  String get roomkit_err_network_error;

  /// No description provided for @roomkit_err_n3_repeat_operation.
  ///
  /// In en, this message translates to:
  /// **'Repeat operation'**
  String get roomkit_err_n3_repeat_operation;

  /// No description provided for @roomkit_err_n4_roomID_not_match.
  ///
  /// In en, this message translates to:
  /// **'Room ID does not match, please check if you have checked out or changed rooms.'**
  String get roomkit_err_n4_roomID_not_match;

  /// No description provided for @roomkit_err_n1000_sdk_appid_not_found.
  ///
  /// In en, this message translates to:
  /// **'Not found sdkappid, please confirm application info in trtc console'**
  String get roomkit_err_n1000_sdk_appid_not_found;

  /// No description provided for @roomkit_err_n1001_invalid_parameter.
  ///
  /// In en, this message translates to:
  /// **'Passing illegal parameters when calling api, check if the parameters are legal'**
  String get roomkit_err_n1001_invalid_parameter;

  /// No description provided for @roomkit_err_n1002_not_logged_in.
  ///
  /// In en, this message translates to:
  /// **'Not logged in, please call login api'**
  String get roomkit_err_n1002_not_logged_in;

  /// No description provided for @roomkit_err_n1003_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Failed to obtain permission, unauthorized audio/video permission, please check if device permission is enabled'**
  String get roomkit_err_n1003_permission_denied;

  /// No description provided for @roomkit_err_n1004_package_required.
  ///
  /// In en, this message translates to:
  /// **'This feature requires an additional package. please activate the corresponding package as needed in the trtc console'**
  String get roomkit_err_n1004_package_required;

  /// No description provided for @roomkit_err_n1005_invalid_license.
  ///
  /// In en, this message translates to:
  /// **'License is invalid or expired, please check its validity period in the trtc console. please activate the corresponding package as needed in the trtc console.'**
  String get roomkit_err_n1005_invalid_license;

  /// No description provided for @roomkit_err_n1100_camera_open_failed.
  ///
  /// In en, this message translates to:
  /// **'System issue, failed to open camera. check if camera device is normal'**
  String get roomkit_err_n1100_camera_open_failed;

  /// No description provided for @roomkit_err_n1101_camera_no_permission.
  ///
  /// In en, this message translates to:
  /// **'Camera has no system authorization, check system authorization'**
  String get roomkit_err_n1101_camera_no_permission;

  /// No description provided for @roomkit_err_n1102_camera_occupied.
  ///
  /// In en, this message translates to:
  /// **'Camera is occupied, check if other process is using camera'**
  String get roomkit_err_n1102_camera_occupied;

  /// No description provided for @roomkit_err_n1103_camera_not_found.
  ///
  /// In en, this message translates to:
  /// **'No camera device currently, please insert camera device to solve the problem'**
  String get roomkit_err_n1103_camera_not_found;

  /// No description provided for @roomkit_err_n1104_mic_open_failed.
  ///
  /// In en, this message translates to:
  /// **'System issue, failed to open mic. check if mic device is normal'**
  String get roomkit_err_n1104_mic_open_failed;

  /// No description provided for @roomkit_err_n1105_mic_no_permission.
  ///
  /// In en, this message translates to:
  /// **'Mic has no system authorization, check system authorization'**
  String get roomkit_err_n1105_mic_no_permission;

  /// No description provided for @roomkit_err_n1106_mic_occupied.
  ///
  /// In en, this message translates to:
  /// **'Mic is occupied'**
  String get roomkit_err_n1106_mic_occupied;

  /// No description provided for @roomkit_err_n1107_mic_not_found.
  ///
  /// In en, this message translates to:
  /// **'No mic device currently'**
  String get roomkit_err_n1107_mic_not_found;

  /// No description provided for @roomkit_err_n1108_screen_share_get_source_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get screen sharing source (screen and window), check screen recording permissions'**
  String get roomkit_err_n1108_screen_share_get_source_failed;

  /// No description provided for @roomkit_err_n1109_screen_share_start_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable screen sharing, check if someone is already screen sharing in the room'**
  String get roomkit_err_n1109_screen_share_start_failed;

  /// No description provided for @roomkit_err_n2101_not_in_room.
  ///
  /// In en, this message translates to:
  /// **'This feature can only be used after entering the room'**
  String get roomkit_err_n2101_not_in_room;

  /// No description provided for @roomkit_err_n2102_owner_cannot_leave.
  ///
  /// In en, this message translates to:
  /// **'Room owner does not support leaving the room, room owner can only close the room'**
  String get roomkit_err_n2102_owner_cannot_leave;

  /// No description provided for @roomkit_err_n2103_unsupported_in_room_type.
  ///
  /// In en, this message translates to:
  /// **'This operation is not supported in the current room type'**
  String get roomkit_err_n2103_unsupported_in_room_type;

  /// No description provided for @roomkit_err_n2105_invalid_room_id.
  ///
  /// In en, this message translates to:
  /// **'Illegal custom room id, must be printable ascii characters (0x20–0x7e), up to 48 bytes long'**
  String get roomkit_err_n2105_invalid_room_id;

  /// No description provided for @roomkit_err_n2107_invalid_room_name.
  ///
  /// In en, this message translates to:
  /// **'Illegal room name, maximum 30 bytes, must be utf-8 encoding if contains chinese characters'**
  String get roomkit_err_n2107_invalid_room_name;

  /// No description provided for @roomkit_err_n2108_user_already_in_other_room.
  ///
  /// In en, this message translates to:
  /// **'User is already in another room, single roomengine instance only supports user entering one room, to enter different room, please leave the room or use new roomengine instance'**
  String get roomkit_err_n2108_user_already_in_other_room;

  /// No description provided for @roomkit_err_n2200_user_not_exist.
  ///
  /// In en, this message translates to:
  /// **'User is not exist'**
  String get roomkit_err_n2200_user_not_exist;

  /// No description provided for @roomkit_err_n2300_need_owner_permission.
  ///
  /// In en, this message translates to:
  /// **'Room owner permission required for operation'**
  String get roomkit_err_n2300_need_owner_permission;

  /// No description provided for @roomkit_err_n2301_need_admin_permission.
  ///
  /// In en, this message translates to:
  /// **'Room owner or administrator permission required for operation'**
  String get roomkit_err_n2301_need_admin_permission;

  /// No description provided for @roomkit_err_n2310_signal_no_permission.
  ///
  /// In en, this message translates to:
  /// **'No permission for signaling request, e.g. canceling an invite not initiated by yourself'**
  String get roomkit_err_n2310_signal_no_permission;

  /// No description provided for @roomkit_err_n2311_signal_invalid_request_id.
  ///
  /// In en, this message translates to:
  /// **'Signaling request id is invalid or has been processed'**
  String get roomkit_err_n2311_signal_invalid_request_id;

  /// No description provided for @roomkit_err_n2312_signal_request_duplicated.
  ///
  /// In en, this message translates to:
  /// **'Signal request repetition'**
  String get roomkit_err_n2312_signal_request_duplicated;

  /// No description provided for @roomkit_err_n2340_seat_count_limit_exceeded.
  ///
  /// In en, this message translates to:
  /// **'Maximum seat exceeds package quantity limit'**
  String get roomkit_err_n2340_seat_count_limit_exceeded;

  /// No description provided for @roomkit_err_n2344_seat_not_exist.
  ///
  /// In en, this message translates to:
  /// **'Seat serial number does not exist'**
  String get roomkit_err_n2344_seat_not_exist;

  /// No description provided for @roomkit_err_n2360_seat_audio_locked.
  ///
  /// In en, this message translates to:
  /// **'Current seat audio is locked'**
  String get roomkit_err_n2360_seat_audio_locked;

  /// No description provided for @roomkit_err_n2361_mic_need_request_permission.
  ///
  /// In en, this message translates to:
  /// **'Need to apply to room owner or administrator to open mic'**
  String get roomkit_err_n2361_mic_need_request_permission;

  /// No description provided for @roomkit_err_n2370_seat_video_locked.
  ///
  /// In en, this message translates to:
  /// **'Current seat video is locked, need room owner to unlock mic seat before opening camera'**
  String get roomkit_err_n2370_seat_video_locked;

  /// No description provided for @roomkit_err_n2371_camera_need_request_permission.
  ///
  /// In en, this message translates to:
  /// **'Need to apply to room owner or administrator to open camera'**
  String get roomkit_err_n2371_camera_need_request_permission;

  /// No description provided for @roomkit_err_n2372_screen_share_seat_locked.
  ///
  /// In en, this message translates to:
  /// **'The current microphone position video is locked and needs to be unlocked by the room owner before screen sharing can be enabled'**
  String get roomkit_err_n2372_screen_share_seat_locked;

  /// No description provided for @roomkit_err_n2373_screen_share_need_permission.
  ///
  /// In en, this message translates to:
  /// **'Screen sharing needs to be enabled after applying to the room owner or administrator'**
  String get roomkit_err_n2373_screen_share_need_permission;

  /// No description provided for @roomkit_err_n2380_all_members_muted.
  ///
  /// In en, this message translates to:
  /// **'All members muted in the current room'**
  String get roomkit_err_n2380_all_members_muted;

  /// No description provided for @roomkit_err_n4001_room_not_support_preload.
  ///
  /// In en, this message translates to:
  /// **'The current room does not support preloading'**
  String get roomkit_err_n4001_room_not_support_preload;

  /// No description provided for @roomkit_err_n6001_device_busy_during_call.
  ///
  /// In en, this message translates to:
  /// **'The device operation failed while in a call'**
  String get roomkit_err_n6001_device_busy_during_call;

  /// No description provided for @roomkit_err_100001_server_internal_error.
  ///
  /// In en, this message translates to:
  /// **'Server internal error, please retry'**
  String get roomkit_err_100001_server_internal_error;

  /// No description provided for @roomkit_err_100002_server_invalid_parameter.
  ///
  /// In en, this message translates to:
  /// **'The parameter is illegal. check whether the request is correct according to the error description'**
  String get roomkit_err_100002_server_invalid_parameter;

  /// No description provided for @roomkit_err_100003_room_id_already_exists.
  ///
  /// In en, this message translates to:
  /// **'The room id already exists. please select another room id'**
  String get roomkit_err_100003_room_id_already_exists;

  /// No description provided for @roomkit_err_100004_room_not_exist.
  ///
  /// In en, this message translates to:
  /// **'The room does not exist, or it once existed but has now been dissolved'**
  String get roomkit_err_100004_room_not_exist;

  /// No description provided for @roomkit_err_100005_not_room_member.
  ///
  /// In en, this message translates to:
  /// **'Not a room member'**
  String get roomkit_err_100005_not_room_member;

  /// No description provided for @roomkit_err_100006_operation_not_allowed.
  ///
  /// In en, this message translates to:
  /// **'You are currently unable to perform this operation (possibly due to lack of permission or scenario restrictions)'**
  String get roomkit_err_100006_operation_not_allowed;

  /// No description provided for @roomkit_err_100007_no_payment_info.
  ///
  /// In en, this message translates to:
  /// **'No payment information, you need to purchase a package in the console'**
  String get roomkit_err_100007_no_payment_info;

  /// No description provided for @roomkit_err_100008_room_is_full.
  ///
  /// In en, this message translates to:
  /// **'The room is full'**
  String get roomkit_err_100008_room_is_full;

  /// No description provided for @roomkit_err_100009_room_tag_limit_exceeded.
  ///
  /// In en, this message translates to:
  /// **'Tag quantity exceeds upper limit'**
  String get roomkit_err_100009_room_tag_limit_exceeded;

  /// No description provided for @roomkit_err_100010_room_id_reusable_by_owner.
  ///
  /// In en, this message translates to:
  /// **'The room id has been used, and the operator is the room owner, it can be used directly'**
  String get roomkit_err_100010_room_id_reusable_by_owner;

  /// No description provided for @roomkit_err_100011_room_id_occupied_by_im.
  ///
  /// In en, this message translates to:
  /// **'The room id has been occupied by chat. you can use a different room id or dissolve the group first'**
  String get roomkit_err_100011_room_id_occupied_by_im;

  /// No description provided for @roomkit_err_100012_create_room_frequency_limit.
  ///
  /// In en, this message translates to:
  /// **'Creating rooms exceeds the frequency limit, the same room id can only be created once within 1 second'**
  String get roomkit_err_100012_create_room_frequency_limit;

  /// No description provided for @roomkit_err_100013_payment_limit_exceeded.
  ///
  /// In en, this message translates to:
  /// **'Exceeds the upper limit, for example, the number of microphone seats, the number of pk match rooms, etc., exceeds the payment limit'**
  String get roomkit_err_100013_payment_limit_exceeded;

  /// No description provided for @roomkit_err_100015_invalid_room_type.
  ///
  /// In en, this message translates to:
  /// **'Invalid room type'**
  String get roomkit_err_100015_invalid_room_type;

  /// No description provided for @roomkit_err_100016_member_already_banned.
  ///
  /// In en, this message translates to:
  /// **'This member has been banned'**
  String get roomkit_err_100016_member_already_banned;

  /// No description provided for @roomkit_err_100017_member_already_muted.
  ///
  /// In en, this message translates to:
  /// **'This member has been muted'**
  String get roomkit_err_100017_member_already_muted;

  /// No description provided for @roomkit_err_100018_room_password_required.
  ///
  /// In en, this message translates to:
  /// **'The current room requires a password for entry'**
  String get roomkit_err_100018_room_password_required;

  /// No description provided for @roomkit_err_100019_room_password_incorrect.
  ///
  /// In en, this message translates to:
  /// **'Room entry password error'**
  String get roomkit_err_100019_room_password_incorrect;

  /// No description provided for @roomkit_err_100020_admin_limit_exceeded.
  ///
  /// In en, this message translates to:
  /// **'The admin quantity exceeds the upper limit'**
  String get roomkit_err_100020_admin_limit_exceeded;

  /// No description provided for @roomkit_err_100102_signal_request_conflict.
  ///
  /// In en, this message translates to:
  /// **'Signal request conflict'**
  String get roomkit_err_100102_signal_request_conflict;

  /// No description provided for @roomkit_err_100200_seat_is_locked.
  ///
  /// In en, this message translates to:
  /// **'The seat is locked. you can try another seat'**
  String get roomkit_err_100200_seat_is_locked;

  /// No description provided for @roomkit_err_100201_seat_is_occupied.
  ///
  /// In en, this message translates to:
  /// **'The current seat is already occupied'**
  String get roomkit_err_100201_seat_is_occupied;

  /// No description provided for @roomkit_err_100202_already_in_seat_queue.
  ///
  /// In en, this message translates to:
  /// **'Already on the seat queue'**
  String get roomkit_err_100202_already_in_seat_queue;

  /// No description provided for @roomkit_err_100203_already_on_seat.
  ///
  /// In en, this message translates to:
  /// **'Already on the seat'**
  String get roomkit_err_100203_already_on_seat;

  /// No description provided for @roomkit_err_100204_not_in_seat_queue.
  ///
  /// In en, this message translates to:
  /// **'Not on the seat queue'**
  String get roomkit_err_100204_not_in_seat_queue;

  /// No description provided for @roomkit_err_100205_all_seats_are_full.
  ///
  /// In en, this message translates to:
  /// **'The seats are all taken.'**
  String get roomkit_err_100205_all_seats_are_full;

  /// No description provided for @roomkit_err_100206_not_on_seat.
  ///
  /// In en, this message translates to:
  /// **'Not on the seat'**
  String get roomkit_err_100206_not_on_seat;

  /// No description provided for @roomkit_err_100210_user_already_on_seat.
  ///
  /// In en, this message translates to:
  /// **'The user is already on the seat'**
  String get roomkit_err_100210_user_already_on_seat;

  /// No description provided for @roomkit_err_100211_seat_not_supported.
  ///
  /// In en, this message translates to:
  /// **'The room does not support seat ability'**
  String get roomkit_err_100211_seat_not_supported;

  /// No description provided for @roomkit_err_100251_seat_list_is_empty.
  ///
  /// In en, this message translates to:
  /// **'The seat list is empty'**
  String get roomkit_err_100251_seat_list_is_empty;

  /// No description provided for @roomkit_err_100500_room_metadata_key_limit.
  ///
  /// In en, this message translates to:
  /// **'The number of keys in the room\'s metadata exceeds the limit'**
  String get roomkit_err_100500_room_metadata_key_limit;

  /// No description provided for @roomkit_err_100501_room_metadata_value_limit.
  ///
  /// In en, this message translates to:
  /// **'The size of value in the room\'s metadata exceeds the maximum byte limit'**
  String get roomkit_err_100501_room_metadata_value_limit;

  /// No description provided for @roomkit_err_100502_room_metadata_total_limit.
  ///
  /// In en, this message translates to:
  /// **'The total size of all value in the room\'s metadata exceeds the maximum byte limit'**
  String get roomkit_err_100502_room_metadata_total_limit;

  /// No description provided for @roomkit_err_100503_room_metadata_no_valid_keys.
  ///
  /// In en, this message translates to:
  /// **'There is no valid keys when delete metadata'**
  String get roomkit_err_100503_room_metadata_no_valid_keys;

  /// No description provided for @roomkit_err_100504_room_metadata_key_size_limit.
  ///
  /// In en, this message translates to:
  /// **'The size of key in the room\'s metadata exceeds the maximum byte limit'**
  String get roomkit_err_100504_room_metadata_key_size_limit;

  /// No description provided for @roomkit_err_7002_invalid_user_id.
  ///
  /// In en, this message translates to:
  /// **'Invalid userid'**
  String get roomkit_err_7002_invalid_user_id;
}

class _RoomLocalizationsDelegate
    extends LocalizationsDelegate<RoomLocalizations> {
  const _RoomLocalizationsDelegate();

  @override
  Future<RoomLocalizations> load(Locale locale) {
    return SynchronousFuture<RoomLocalizations>(
        lookupRoomLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_RoomLocalizationsDelegate old) => false;
}

RoomLocalizations lookupRoomLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return RoomLocalizationsEn();
    case 'zh':
      return RoomLocalizationsZh();
  }

  throw FlutterError(
      'RoomLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
