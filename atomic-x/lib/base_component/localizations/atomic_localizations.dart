import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'atomic_localizations_ar.dart';
import 'atomic_localizations_en.dart';
import 'atomic_localizations_ja.dart';
import 'atomic_localizations_ko.dart';
import 'atomic_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AtomicLocalizations
/// returned by `AtomicLocalizations.of(context)`.
///
/// Applications need to include `AtomicLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localizations/atomic_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AtomicLocalizations.localizationsDelegates,
///   supportedLocales: AtomicLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AtomicLocalizations.supportedLocales
/// property.
abstract class AtomicLocalizations {
  AtomicLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AtomicLocalizations of(BuildContext context) {
    return Localizations.of<AtomicLocalizations>(context, AtomicLocalizations)!;
  }

  static const LocalizationsDelegate<AtomicLocalizations> delegate =
      _AtomicLocalizationsDelegate();

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
    Locale('ar'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageZhHant.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get languageZhHant;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// No description provided for @languageKo.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKo;

  /// No description provided for @languageAr.
  ///
  /// In en, this message translates to:
  /// **'اَلْعَرَبِيَّة'**
  String get languageAr;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contact;

  /// No description provided for @messageRevokedDefault.
  ///
  /// In en, this message translates to:
  /// **'A user recalled a message'**
  String get messageRevokedDefault;

  /// No description provided for @messageRevokedBySelf.
  ///
  /// In en, this message translates to:
  /// **'You recalled a message'**
  String get messageRevokedBySelf;

  /// No description provided for @messageRevokedByOther.
  ///
  /// In en, this message translates to:
  /// **'The other party recalled a message'**
  String get messageRevokedByOther;

  /// No description provided for @messageRevokedByUser.
  ///
  /// In en, this message translates to:
  /// **'{user} recalled a message'**
  String messageRevokedByUser(Object user);

  /// No description provided for @groupMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'{user} joined the group'**
  String groupMemberJoined(Object user);

  /// No description provided for @groupMemberInvited.
  ///
  /// In en, this message translates to:
  /// **'{operator} invited {users} to join the group'**
  String groupMemberInvited(Object operator, Object users);

  /// No description provided for @groupMemberQuit.
  ///
  /// In en, this message translates to:
  /// **'{user} left the group'**
  String groupMemberQuit(Object user);

  /// No description provided for @groupMemberKicked.
  ///
  /// In en, this message translates to:
  /// **'{operator} removed {users} from the group'**
  String groupMemberKicked(Object operator, Object users);

  /// No description provided for @groupAdminSet.
  ///
  /// In en, this message translates to:
  /// **'{users} were set as administrators'**
  String groupAdminSet(Object users);

  /// No description provided for @groupAdminCancelled.
  ///
  /// In en, this message translates to:
  /// **'{users} were removed from administrators'**
  String groupAdminCancelled(Object users);

  /// No description provided for @groupMessagePinned.
  ///
  /// In en, this message translates to:
  /// **'{user} pinned a message'**
  String groupMessagePinned(Object user);

  /// No description provided for @groupMessageUnpinned.
  ///
  /// In en, this message translates to:
  /// **'{user} unpinned a message'**
  String groupMessageUnpinned(Object user);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @muted.
  ///
  /// In en, this message translates to:
  /// **'muted'**
  String get muted;

  /// No description provided for @unmuted.
  ///
  /// In en, this message translates to:
  /// **'unmuted'**
  String get unmuted;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @second.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get second;

  /// No description provided for @messageTypeImage.
  ///
  /// In en, this message translates to:
  /// **'[Image]'**
  String get messageTypeImage;

  /// No description provided for @messageTypeVoice.
  ///
  /// In en, this message translates to:
  /// **'[Voice]'**
  String get messageTypeVoice;

  /// No description provided for @messageTypeFile.
  ///
  /// In en, this message translates to:
  /// **'[File]'**
  String get messageTypeFile;

  /// No description provided for @messageTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'[Video]'**
  String get messageTypeVideo;

  /// No description provided for @messageTypeSticker.
  ///
  /// In en, this message translates to:
  /// **'[Sticker]'**
  String get messageTypeSticker;

  /// No description provided for @messageTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'[Custom Message]'**
  String get messageTypeCustom;

  /// No description provided for @groupNameChangedTo.
  ///
  /// In en, this message translates to:
  /// **'changed group name to'**
  String get groupNameChangedTo;

  /// No description provided for @groupIntroChangedTo.
  ///
  /// In en, this message translates to:
  /// **'changed group description to'**
  String get groupIntroChangedTo;

  /// No description provided for @groupNoticeChangedTo.
  ///
  /// In en, this message translates to:
  /// **'changed group notice to'**
  String get groupNoticeChangedTo;

  /// No description provided for @groupNoticeDeleted.
  ///
  /// In en, this message translates to:
  /// **'deleted group notice'**
  String get groupNoticeDeleted;

  /// No description provided for @groupAvatarChanged.
  ///
  /// In en, this message translates to:
  /// **'changed group avatar'**
  String get groupAvatarChanged;

  /// No description provided for @groupOwnerTransferredTo.
  ///
  /// In en, this message translates to:
  /// **'transferred group ownership to'**
  String get groupOwnerTransferredTo;

  /// No description provided for @groupMuteAllEnabled.
  ///
  /// In en, this message translates to:
  /// **'enabled mute all members'**
  String get groupMuteAllEnabled;

  /// No description provided for @groupMuteAllDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled mute all members'**
  String get groupMuteAllDisabled;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @groupJoinMethodChangedTo.
  ///
  /// In en, this message translates to:
  /// **'changed join method to'**
  String get groupJoinMethodChangedTo;

  /// No description provided for @groupInviteMethodChangedTo.
  ///
  /// In en, this message translates to:
  /// **'changed invite method to'**
  String get groupInviteMethodChangedTo;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySaturday;

  /// No description provided for @userID.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userID;

  /// No description provided for @album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @recordAVideo.
  ///
  /// In en, this message translates to:
  /// **'Record a video'**
  String get recordAVideo;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendSoundTips.
  ///
  /// In en, this message translates to:
  /// **'Press and hold to speak Release to send'**
  String get sendSoundTips;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clearMessage.
  ///
  /// In en, this message translates to:
  /// **'Clear chat history'**
  String get clearMessage;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin chat'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin chat'**
  String get unpin;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get startConversation;

  /// No description provided for @createGroupChat.
  ///
  /// In en, this message translates to:
  /// **'Create Group Chat'**
  String get createGroupChat;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friends'**
  String get addFriend;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @createGroupTips.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupTips;

  /// No description provided for @createCommunity.
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get createCommunity;

  /// No description provided for @groupIDInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid group ID. Check whether the group ID is correct.'**
  String get groupIDInvalid;

  /// No description provided for @communityIDEditFormatTips.
  ///
  /// In en, this message translates to:
  /// **'Community ID prefix must be @TGS#_ !'**
  String get communityIDEditFormatTips;

  /// No description provided for @groupIDEditFormatTips.
  ///
  /// In en, this message translates to:
  /// **'Group ID prefix cannot be @TGS# !'**
  String get groupIDEditFormatTips;

  /// No description provided for @groupIDEditExceedTips.
  ///
  /// In en, this message translates to:
  /// **'Group ID up to 48 bytes!'**
  String get groupIDEditExceedTips;

  /// No description provided for @productDocumentation.
  ///
  /// In en, this message translates to:
  /// **'View product documentation'**
  String get productDocumentation;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupIDOption.
  ///
  /// In en, this message translates to:
  /// **'Group ID (optional)'**
  String get groupIDOption;

  /// No description provided for @groupFaceUrl.
  ///
  /// In en, this message translates to:
  /// **'Group Avatar'**
  String get groupFaceUrl;

  /// No description provided for @groupMemberSelected.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get groupMemberSelected;

  /// No description provided for @groupWorkType.
  ///
  /// In en, this message translates to:
  /// **'Friends Working group(Work)'**
  String get groupWorkType;

  /// No description provided for @groupPublicType.
  ///
  /// In en, this message translates to:
  /// **'Stranger Social group(Public）'**
  String get groupPublicType;

  /// No description provided for @groupMeetingType.
  ///
  /// In en, this message translates to:
  /// **'Temporary Meeting group(Meeting）'**
  String get groupMeetingType;

  /// No description provided for @groupCommunityType.
  ///
  /// In en, this message translates to:
  /// **'Community(Community)'**
  String get groupCommunityType;

  /// No description provided for @groupWorkDesc.
  ///
  /// In en, this message translates to:
  /// **'Friends work group (Work): Similar to ordinary WeChat groups, after creation, only friends who are already in the group can be invited to join the group, and there is no need for the approval of the invitee or the approval of the group owner.'**
  String get groupWorkDesc;

  /// No description provided for @groupPublicDesc.
  ///
  /// In en, this message translates to:
  /// **'Stranger social group (Public): Similar to QQ group, the group owner can designate the group administrator after creation. After the user searches for the group ID and initiates a group application, the group owner or administrator must approve it before joining the group.'**
  String get groupPublicDesc;

  /// No description provided for @groupMeetingDesc.
  ///
  /// In en, this message translates to:
  /// **'Temporary meeting group (Meeting): After creation, you can enter and leave at will, and support viewing of messages before joining the group; it is suitable for audio and video conference scenarios, online education scenarios, and other scenarios that are combined with real-time audio and video products.'**
  String get groupMeetingDesc;

  /// No description provided for @groupCommunityDesc.
  ///
  /// In en, this message translates to:
  /// **'Community(Community)：After creation, you can enter and leave at will, support up to 100,000 people, support historical message storage, and after users search for group ID and initiate a group application, they can join the group without administrator approval.'**
  String get groupCommunityDesc;

  /// No description provided for @groupDetail.
  ///
  /// In en, this message translates to:
  /// **'Group Chat Details'**
  String get groupDetail;

  /// No description provided for @transferGroupOwner.
  ///
  /// In en, this message translates to:
  /// **'Transfer Group Owner'**
  String get transferGroupOwner;

  /// No description provided for @privateGroup.
  ///
  /// In en, this message translates to:
  /// **'Discussion Group'**
  String get privateGroup;

  /// No description provided for @publicGroup.
  ///
  /// In en, this message translates to:
  /// **'Public Group'**
  String get publicGroup;

  /// No description provided for @chatRoom.
  ///
  /// In en, this message translates to:
  /// **'Chatroom'**
  String get chatRoom;

  /// No description provided for @communityGroup.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityGroup;

  /// No description provided for @groupOfAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Group Notice'**
  String get groupOfAnnouncement;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Manage Group'**
  String get groupManagement;

  /// No description provided for @groupType.
  ///
  /// In en, this message translates to:
  /// **'Group Type'**
  String get groupType;

  /// No description provided for @addGroupWay.
  ///
  /// In en, this message translates to:
  /// **'Group Joining Method'**
  String get addGroupWay;

  /// No description provided for @inviteGroupType.
  ///
  /// In en, this message translates to:
  /// **'Group Inviting Method'**
  String get inviteGroupType;

  /// No description provided for @myAliasInGroup.
  ///
  /// In en, this message translates to:
  /// **'My Alias in Group'**
  String get myAliasInGroup;

  /// No description provided for @doNotDisturb.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get doNotDisturb;

  /// No description provided for @groupMember.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMember;

  /// No description provided for @profileRemark.
  ///
  /// In en, this message translates to:
  /// **'Alias'**
  String get profileRemark;

  /// No description provided for @groupEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get groupEdit;

  /// No description provided for @blackList.
  ///
  /// In en, this message translates to:
  /// **'Blocked List'**
  String get blackList;

  /// No description provided for @profileBlack.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get profileBlack;

  /// No description provided for @deleteFriend.
  ///
  /// In en, this message translates to:
  /// **'Delete Contact'**
  String get deleteFriend;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistory;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @newFriend.
  ///
  /// In en, this message translates to:
  /// **'New Contacts'**
  String get newFriend;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'Group Chats'**
  String get myGroups;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get contactInfo;

  /// No description provided for @includeGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'Include members:'**
  String get includeGroupMembers;

  /// No description provided for @tuiEmojiSmile.
  ///
  /// In en, this message translates to:
  /// **'[Smile]'**
  String get tuiEmojiSmile;

  /// No description provided for @tuiEmojiExpect.
  ///
  /// In en, this message translates to:
  /// **'[Expect]'**
  String get tuiEmojiExpect;

  /// No description provided for @tuiEmojiBlink.
  ///
  /// In en, this message translates to:
  /// **'[Blink]'**
  String get tuiEmojiBlink;

  /// No description provided for @tuiEmojiGuffaw.
  ///
  /// In en, this message translates to:
  /// **'[Guffaw]'**
  String get tuiEmojiGuffaw;

  /// No description provided for @tuiEmojiKindSmile.
  ///
  /// In en, this message translates to:
  /// **'[Kind Smile]'**
  String get tuiEmojiKindSmile;

  /// No description provided for @tuiEmojiHaha.
  ///
  /// In en, this message translates to:
  /// **'[Haha]'**
  String get tuiEmojiHaha;

  /// No description provided for @tuiEmojiCheerful.
  ///
  /// In en, this message translates to:
  /// **'[Cheerful]'**
  String get tuiEmojiCheerful;

  /// No description provided for @tuiEmojiSpeechless.
  ///
  /// In en, this message translates to:
  /// **'[Speechless]'**
  String get tuiEmojiSpeechless;

  /// No description provided for @tuiEmojiAmazed.
  ///
  /// In en, this message translates to:
  /// **'[Amazed]'**
  String get tuiEmojiAmazed;

  /// No description provided for @tuiEmojiSorrow.
  ///
  /// In en, this message translates to:
  /// **'[Sorrow]'**
  String get tuiEmojiSorrow;

  /// No description provided for @tuiEmojiComplacent.
  ///
  /// In en, this message translates to:
  /// **'[Complacent]'**
  String get tuiEmojiComplacent;

  /// No description provided for @tuiEmojiSilly.
  ///
  /// In en, this message translates to:
  /// **'[Silly]'**
  String get tuiEmojiSilly;

  /// No description provided for @tuiEmojiLustful.
  ///
  /// In en, this message translates to:
  /// **'[Lustful]'**
  String get tuiEmojiLustful;

  /// No description provided for @tuiEmojiGiggle.
  ///
  /// In en, this message translates to:
  /// **'[Giggle]'**
  String get tuiEmojiGiggle;

  /// No description provided for @tuiEmojiKiss.
  ///
  /// In en, this message translates to:
  /// **'[Kiss]'**
  String get tuiEmojiKiss;

  /// No description provided for @tuiEmojiWail.
  ///
  /// In en, this message translates to:
  /// **'[Wail]'**
  String get tuiEmojiWail;

  /// No description provided for @tuiEmojiTearsLaugh.
  ///
  /// In en, this message translates to:
  /// **'[Tears Laugh]'**
  String get tuiEmojiTearsLaugh;

  /// No description provided for @tuiEmojiTrapped.
  ///
  /// In en, this message translates to:
  /// **'[Trapped]'**
  String get tuiEmojiTrapped;

  /// No description provided for @tuiEmojiMask.
  ///
  /// In en, this message translates to:
  /// **'[Mask]'**
  String get tuiEmojiMask;

  /// No description provided for @tuiEmojiFear.
  ///
  /// In en, this message translates to:
  /// **'[Fear]'**
  String get tuiEmojiFear;

  /// No description provided for @tuiEmojiBareTeeth.
  ///
  /// In en, this message translates to:
  /// **'[Bare Teeth]'**
  String get tuiEmojiBareTeeth;

  /// No description provided for @tuiEmojiFlareUp.
  ///
  /// In en, this message translates to:
  /// **'[Flare Up]'**
  String get tuiEmojiFlareUp;

  /// No description provided for @tuiEmojiYawn.
  ///
  /// In en, this message translates to:
  /// **'[Yawn]'**
  String get tuiEmojiYawn;

  /// No description provided for @tuiEmojiTact.
  ///
  /// In en, this message translates to:
  /// **'[Tact]'**
  String get tuiEmojiTact;

  /// No description provided for @tuiEmojiStareyes.
  ///
  /// In en, this message translates to:
  /// **'[Stareyes]'**
  String get tuiEmojiStareyes;

  /// No description provided for @tuiEmojiShutUp.
  ///
  /// In en, this message translates to:
  /// **'[Shut Up]'**
  String get tuiEmojiShutUp;

  /// No description provided for @tuiEmojiSigh.
  ///
  /// In en, this message translates to:
  /// **'[Sigh]'**
  String get tuiEmojiSigh;

  /// No description provided for @tuiEmojiHehe.
  ///
  /// In en, this message translates to:
  /// **'[Hehe]'**
  String get tuiEmojiHehe;

  /// No description provided for @tuiEmojiSilent.
  ///
  /// In en, this message translates to:
  /// **'[Silent]'**
  String get tuiEmojiSilent;

  /// No description provided for @tuiEmojiSurprised.
  ///
  /// In en, this message translates to:
  /// **'[Surprised]'**
  String get tuiEmojiSurprised;

  /// No description provided for @tuiEmojiAskance.
  ///
  /// In en, this message translates to:
  /// **'[Askance]'**
  String get tuiEmojiAskance;

  /// No description provided for @tuiEmojiOk.
  ///
  /// In en, this message translates to:
  /// **'[OK]'**
  String get tuiEmojiOk;

  /// No description provided for @tuiEmojiShit.
  ///
  /// In en, this message translates to:
  /// **'[Shit]'**
  String get tuiEmojiShit;

  /// No description provided for @tuiEmojiMonster.
  ///
  /// In en, this message translates to:
  /// **'[Monster]'**
  String get tuiEmojiMonster;

  /// No description provided for @tuiEmojiDaemon.
  ///
  /// In en, this message translates to:
  /// **'[Daemon]'**
  String get tuiEmojiDaemon;

  /// No description provided for @tuiEmojiRage.
  ///
  /// In en, this message translates to:
  /// **'[Rage]'**
  String get tuiEmojiRage;

  /// No description provided for @tuiEmojiFool.
  ///
  /// In en, this message translates to:
  /// **'[Fool]'**
  String get tuiEmojiFool;

  /// No description provided for @tuiEmojiPig.
  ///
  /// In en, this message translates to:
  /// **'[Pig]'**
  String get tuiEmojiPig;

  /// No description provided for @tuiEmojiCow.
  ///
  /// In en, this message translates to:
  /// **'[Cow]'**
  String get tuiEmojiCow;

  /// No description provided for @tuiEmojiAi.
  ///
  /// In en, this message translates to:
  /// **'[AI]'**
  String get tuiEmojiAi;

  /// No description provided for @tuiEmojiSkull.
  ///
  /// In en, this message translates to:
  /// **'[Skull]'**
  String get tuiEmojiSkull;

  /// No description provided for @tuiEmojiBombs.
  ///
  /// In en, this message translates to:
  /// **'[Bombs]'**
  String get tuiEmojiBombs;

  /// No description provided for @tuiEmojiCoffee.
  ///
  /// In en, this message translates to:
  /// **'[Coffee]'**
  String get tuiEmojiCoffee;

  /// No description provided for @tuiEmojiCake.
  ///
  /// In en, this message translates to:
  /// **'[Cake]'**
  String get tuiEmojiCake;

  /// No description provided for @tuiEmojiBeer.
  ///
  /// In en, this message translates to:
  /// **'[Beer]'**
  String get tuiEmojiBeer;

  /// No description provided for @tuiEmojiFlower.
  ///
  /// In en, this message translates to:
  /// **'[Flower]'**
  String get tuiEmojiFlower;

  /// No description provided for @tuiEmojiWatermelon.
  ///
  /// In en, this message translates to:
  /// **'[Watermelon]'**
  String get tuiEmojiWatermelon;

  /// No description provided for @tuiEmojiRich.
  ///
  /// In en, this message translates to:
  /// **'[Rich]'**
  String get tuiEmojiRich;

  /// No description provided for @tuiEmojiHeart.
  ///
  /// In en, this message translates to:
  /// **'[Heart]'**
  String get tuiEmojiHeart;

  /// No description provided for @tuiEmojiMoon.
  ///
  /// In en, this message translates to:
  /// **'[Moon]'**
  String get tuiEmojiMoon;

  /// No description provided for @tuiEmojiSun.
  ///
  /// In en, this message translates to:
  /// **'[Sun]'**
  String get tuiEmojiSun;

  /// No description provided for @tuiEmojiStar.
  ///
  /// In en, this message translates to:
  /// **'[Star]'**
  String get tuiEmojiStar;

  /// No description provided for @tuiEmojiRedPacket.
  ///
  /// In en, this message translates to:
  /// **'[Red Packet]'**
  String get tuiEmojiRedPacket;

  /// No description provided for @tuiEmojiCelebrate.
  ///
  /// In en, this message translates to:
  /// **'[Celebrate]'**
  String get tuiEmojiCelebrate;

  /// No description provided for @tuiEmojiBless.
  ///
  /// In en, this message translates to:
  /// **'[Bless]'**
  String get tuiEmojiBless;

  /// No description provided for @tuiEmojiFortune.
  ///
  /// In en, this message translates to:
  /// **'[Fortune]'**
  String get tuiEmojiFortune;

  /// No description provided for @tuiEmojiConvinced.
  ///
  /// In en, this message translates to:
  /// **'[Convinced]'**
  String get tuiEmojiConvinced;

  /// No description provided for @tuiEmojiProhibit.
  ///
  /// In en, this message translates to:
  /// **'[Prohibit]'**
  String get tuiEmojiProhibit;

  /// No description provided for @tuiEmoji666.
  ///
  /// In en, this message translates to:
  /// **'[666]'**
  String get tuiEmoji666;

  /// No description provided for @tuiEmoji857.
  ///
  /// In en, this message translates to:
  /// **'[857]'**
  String get tuiEmoji857;

  /// No description provided for @tuiEmojiKnife.
  ///
  /// In en, this message translates to:
  /// **'[Knife]'**
  String get tuiEmojiKnife;

  /// No description provided for @tuiEmojiLike.
  ///
  /// In en, this message translates to:
  /// **'[Like]'**
  String get tuiEmojiLike;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @addMembers.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get addMembers;

  /// No description provided for @quitGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get quitGroup;

  /// No description provided for @dismissGroup.
  ///
  /// In en, this message translates to:
  /// **'Disband Group'**
  String get dismissGroup;

  /// No description provided for @groupNoticeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No group notice'**
  String get groupNoticeEmpty;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get agree;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get refuse;

  /// No description provided for @noFriendApplicationList.
  ///
  /// In en, this message translates to:
  /// **'Friend request is empty'**
  String get noFriendApplicationList;

  /// No description provided for @noBlackList.
  ///
  /// In en, this message translates to:
  /// **'Block list is empty'**
  String get noBlackList;

  /// No description provided for @noGroupList.
  ///
  /// In en, this message translates to:
  /// **'Group chats is empty'**
  String get noGroupList;

  /// No description provided for @noGroupApplicationList.
  ///
  /// In en, this message translates to:
  /// **'No group application yet'**
  String get noGroupApplicationList;

  /// No description provided for @groupChatNotifications.
  ///
  /// In en, this message translates to:
  /// **'Group Chat Notifications'**
  String get groupChatNotifications;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'invite'**
  String get invite;

  /// No description provided for @groupApplicationAllReadyBeenProcessed.
  ///
  /// In en, this message translates to:
  /// **'This invitation or request has been processed.'**
  String get groupApplicationAllReadyBeenProcessed;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Agreed'**
  String get accepted;

  /// No description provided for @refused.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get refused;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @recall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get recall;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @quote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @searchUserID.
  ///
  /// In en, this message translates to:
  /// **'Please enter User ID to search for users'**
  String get searchUserID;

  /// No description provided for @searchGroupID.
  ///
  /// In en, this message translates to:
  /// **'Search Group ID'**
  String get searchGroupID;

  /// No description provided for @searchGroupIDHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter Group ID to search for groups'**
  String get searchGroupIDHint;

  /// No description provided for @addFailed.
  ///
  /// In en, this message translates to:
  /// **'Add failed'**
  String get addFailed;

  /// No description provided for @joinGroupFailed.
  ///
  /// In en, this message translates to:
  /// **'Join group failed'**
  String get joinGroupFailed;

  /// No description provided for @alreadyInGroup.
  ///
  /// In en, this message translates to:
  /// **'Already in group'**
  String get alreadyInGroup;

  /// No description provided for @alreadyFriend.
  ///
  /// In en, this message translates to:
  /// **'Already friends'**
  String get alreadyFriend;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get signature;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search error'**
  String get searchError;

  /// No description provided for @fillInTheVerificationInformation.
  ///
  /// In en, this message translates to:
  /// **'Fill in verification information'**
  String get fillInTheVerificationInformation;

  /// No description provided for @joinedGroupSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'success'**
  String get joinedGroupSuccessfully;

  /// No description provided for @contactAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Contact Added Successfully'**
  String get contactAddedSuccessfully;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @groupWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get groupWork;

  /// No description provided for @groupPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get groupPublic;

  /// No description provided for @groupMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get groupMeeting;

  /// No description provided for @groupCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get groupCommunity;

  /// No description provided for @groupAVChatRoom.
  ///
  /// In en, this message translates to:
  /// **'AVChatRoom'**
  String get groupAVChatRoom;

  /// No description provided for @groupAddAny.
  ///
  /// In en, this message translates to:
  /// **'Auto Approval'**
  String get groupAddAny;

  /// No description provided for @groupAddAuth.
  ///
  /// In en, this message translates to:
  /// **'Admin Approval'**
  String get groupAddAuth;

  /// No description provided for @groupAddForbid.
  ///
  /// In en, this message translates to:
  /// **'Prohibited from Joining'**
  String get groupAddForbid;

  /// No description provided for @groupInviteForbid.
  ///
  /// In en, this message translates to:
  /// **'Prohibited from Inviting'**
  String get groupInviteForbid;

  /// No description provided for @groupOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupOwner;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @modifyGroupName.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Name'**
  String get modifyGroupName;

  /// No description provided for @groupNickname.
  ///
  /// In en, this message translates to:
  /// **'My Alias in Group'**
  String get groupNickname;

  /// No description provided for @modifyGroupNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit My Alias in Group'**
  String get modifyGroupNickname;

  /// No description provided for @modifyGroupNoticeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get modifyGroupNoticeSuccess;

  /// No description provided for @quitGroupTip.
  ///
  /// In en, this message translates to:
  /// **'Leave the group?'**
  String get quitGroupTip;

  /// No description provided for @dismissGroupTip.
  ///
  /// In en, this message translates to:
  /// **'Disband the group?'**
  String get dismissGroupTip;

  /// No description provided for @clearMsgTip.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the chat history?'**
  String get clearMsgTip;

  /// No description provided for @muteAll.
  ///
  /// In en, this message translates to:
  /// **'Mute All'**
  String get muteAll;

  /// No description provided for @addMuteMemberTip.
  ///
  /// In en, this message translates to:
  /// **'Add members to mute'**
  String get addMuteMemberTip;

  /// No description provided for @groupMuteTip.
  ///
  /// In en, this message translates to:
  /// **'When Mute All is enabled, only the group owner and admins are allowed to send messages.'**
  String get groupMuteTip;

  /// No description provided for @deleteFriendTip.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the contact?'**
  String get deleteFriendTip;

  /// No description provided for @remarkEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Alias'**
  String get remarkEdit;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detail;

  /// No description provided for @setAdmin.
  ///
  /// In en, this message translates to:
  /// **'Set Administrator'**
  String get setAdmin;

  /// No description provided for @cancelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Cancel Admin'**
  String get cancelAdmin;

  /// No description provided for @deleteGroupMemberTip.
  ///
  /// In en, this message translates to:
  /// **'Confirm to delete group member?'**
  String get deleteGroupMemberTip;

  /// No description provided for @settingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Setup Success!'**
  String get settingSuccess;

  /// No description provided for @settingFail.
  ///
  /// In en, this message translates to:
  /// **'Setup failed!'**
  String get settingFail;

  /// No description provided for @noMore.
  ///
  /// In en, this message translates to:
  /// **'No more'**
  String get noMore;

  /// No description provided for @sayTimeShort.
  ///
  /// In en, this message translates to:
  /// **'Message too short'**
  String get sayTimeShort;

  /// No description provided for @recordLimitTips.
  ///
  /// In en, this message translates to:
  /// **'Maximum voice length reached'**
  String get recordLimitTips;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get chooseAvatar;

  /// No description provided for @inputGroupName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a group name'**
  String get inputGroupName;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @permissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Required permissions'**
  String get permissionNeeded;

  /// No description provided for @permissionDeniedContent.
  ///
  /// In en, this message translates to:
  /// **'Please go to Settings and enable the Photos permission.'**
  String get permissionDeniedContent;

  /// No description provided for @maxCountFile.
  ///
  /// In en, this message translates to:
  /// **'You can only select at most {maxCount} files'**
  String maxCountFile(Object maxCount);

  /// No description provided for @groupIntroDeleted.
  ///
  /// In en, this message translates to:
  /// **'deleted group description'**
  String get groupIntroDeleted;

  /// No description provided for @groupJoinForbidden.
  ///
  /// In en, this message translates to:
  /// **'Join forbidden'**
  String get groupJoinForbidden;

  /// No description provided for @groupJoinApproval.
  ///
  /// In en, this message translates to:
  /// **'Admin approval required'**
  String get groupJoinApproval;

  /// No description provided for @groupJoinFree.
  ///
  /// In en, this message translates to:
  /// **'Free to join'**
  String get groupJoinFree;

  /// No description provided for @groupInviteForbidden.
  ///
  /// In en, this message translates to:
  /// **'Invite forbidden'**
  String get groupInviteForbidden;

  /// No description provided for @groupInviteApproval.
  ///
  /// In en, this message translates to:
  /// **'Admin approval required'**
  String get groupInviteApproval;

  /// No description provided for @groupInviteFree.
  ///
  /// In en, this message translates to:
  /// **'Free to invite'**
  String get groupInviteFree;

  /// No description provided for @mergeMessage.
  ///
  /// In en, this message translates to:
  /// **'Merge Messages'**
  String get mergeMessage;

  /// No description provided for @upgradeLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Please upgrade to the latest version'**
  String get upgradeLatestVersion;

  /// No description provided for @friendLimit.
  ///
  /// In en, this message translates to:
  /// **'The number of your contacts exceeds the limit.'**
  String get friendLimit;

  /// No description provided for @otherFriendLimit.
  ///
  /// In en, this message translates to:
  /// **'The number of the other user\'s contacts exceeds the limit.'**
  String get otherFriendLimit;

  /// No description provided for @inBlacklist.
  ///
  /// In en, this message translates to:
  /// **'You have blocked this user.'**
  String get inBlacklist;

  /// No description provided for @setInBlacklist.
  ///
  /// In en, this message translates to:
  /// **'You have been blocked.'**
  String get setInBlacklist;

  /// No description provided for @forbidAddFriend.
  ///
  /// In en, this message translates to:
  /// **'This user has disabled contact request.'**
  String get forbidAddFriend;

  /// No description provided for @waitAgreeFriend.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get waitAgreeFriend;

  /// No description provided for @haveBeFriend.
  ///
  /// In en, this message translates to:
  /// **'You two are already contacts of each other.'**
  String get haveBeFriend;

  /// No description provided for @addGroupPermissionDeny.
  ///
  /// In en, this message translates to:
  /// **'Prohibited from Joining'**
  String get addGroupPermissionDeny;

  /// No description provided for @addGroupAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'The user is a group member'**
  String get addGroupAlreadyMember;

  /// No description provided for @addGroupNotFound.
  ///
  /// In en, this message translates to:
  /// **'The group does not exist'**
  String get addGroupNotFound;

  /// No description provided for @addGroupFullMember.
  ///
  /// In en, this message translates to:
  /// **'The number of group members has reached the limit'**
  String get addGroupFullMember;

  /// No description provided for @chatRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} related records'**
  String chatRecords(Object count);

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Contact Request'**
  String get addRule;

  /// No description provided for @allowAny.
  ///
  /// In en, this message translates to:
  /// **'Allow anyone'**
  String get allowAny;

  /// No description provided for @denyAny.
  ///
  /// In en, this message translates to:
  /// **'Deny anyone'**
  String get denyAny;

  /// No description provided for @needConfirm.
  ///
  /// In en, this message translates to:
  /// **'Requires verification'**
  String get needConfirm;

  /// No description provided for @noSignature.
  ///
  /// In en, this message translates to:
  /// **'No signature yet'**
  String get noSignature;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @setNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit nickname'**
  String get setNickname;

  /// No description provided for @setSignature.
  ///
  /// In en, this message translates to:
  /// **'Edit signature'**
  String get setSignature;

  /// No description provided for @messageNum.
  ///
  /// In en, this message translates to:
  /// **'messages'**
  String get messageNum;

  /// No description provided for @sendMessageFail.
  ///
  /// In en, this message translates to:
  /// **'Send Failed'**
  String get sendMessageFail;

  /// No description provided for @resendTips.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to resend?'**
  String get resendTips;

  /// No description provided for @callRejectCaller.
  ///
  /// In en, this message translates to:
  /// **'Call declined by user'**
  String get callRejectCaller;

  /// No description provided for @callRejectCallee.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get callRejectCallee;

  /// No description provided for @callCancelCaller.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get callCancelCaller;

  /// No description provided for @callCancelCallee.
  ///
  /// In en, this message translates to:
  /// **'Call canceled by caller'**
  String get callCancelCallee;

  /// No description provided for @stopCallTip.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get stopCallTip;

  /// No description provided for @callTimeoutCaller.
  ///
  /// In en, this message translates to:
  /// **'Call was not answered'**
  String get callTimeoutCaller;

  /// No description provided for @callTimeoutCallee.
  ///
  /// In en, this message translates to:
  /// **'Call timeout'**
  String get callTimeoutCallee;

  /// No description provided for @callLineBusyCaller.
  ///
  /// In en, this message translates to:
  /// **'Line busy'**
  String get callLineBusyCaller;

  /// No description provided for @callLineBusyCallee.
  ///
  /// In en, this message translates to:
  /// **'Line busy'**
  String get callLineBusyCallee;

  /// No description provided for @startCall.
  ///
  /// In en, this message translates to:
  /// **'Start Call'**
  String get startCall;

  /// No description provided for @acceptCall.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get acceptCall;

  /// No description provided for @callingSwitchToAudio.
  ///
  /// In en, this message translates to:
  /// **'Switch to voice call'**
  String get callingSwitchToAudio;

  /// No description provided for @callingSwitchToAudioAccept.
  ///
  /// In en, this message translates to:
  /// **'Confirm video to voice'**
  String get callingSwitchToAudioAccept;

  /// No description provided for @invalidCommand.
  ///
  /// In en, this message translates to:
  /// **'invalid command'**
  String get invalidCommand;

  /// No description provided for @groupCallSend.
  ///
  /// In en, this message translates to:
  /// **'initiated a group call'**
  String get groupCallSend;

  /// No description provided for @groupCallEnd.
  ///
  /// In en, this message translates to:
  /// **'End group call'**
  String get groupCallEnd;

  /// No description provided for @groupCallNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'no answer'**
  String get groupCallNoAnswer;

  /// No description provided for @groupCallReject.
  ///
  /// In en, this message translates to:
  /// **'declined call'**
  String get groupCallReject;

  /// No description provided for @groupCallAccept.
  ///
  /// In en, this message translates to:
  /// **'answered'**
  String get groupCallAccept;

  /// No description provided for @groupCallConfirmSwitchToAudio.
  ///
  /// In en, this message translates to:
  /// **'confirm to audio call'**
  String get groupCallConfirmSwitchToAudio;

  /// No description provided for @unknownCall.
  ///
  /// In en, this message translates to:
  /// **'Unknown call'**
  String get unknownCall;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'join in'**
  String get join;

  /// No description provided for @peopleOnCall.
  ///
  /// In en, this message translates to:
  /// **'{number} person are currently on the call'**
  String peopleOnCall(Object number);
}

class _AtomicLocalizationsDelegate
    extends LocalizationsDelegate<AtomicLocalizations> {
  const _AtomicLocalizationsDelegate();

  @override
  Future<AtomicLocalizations> load(Locale locale) {
    return SynchronousFuture<AtomicLocalizations>(
        lookupAtomicLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AtomicLocalizationsDelegate old) => false;
}

AtomicLocalizations lookupAtomicLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AtomicLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AtomicLocalizationsAr();
    case 'en':
      return AtomicLocalizationsEn();
    case 'ja':
      return AtomicLocalizationsJa();
    case 'ko':
      return AtomicLocalizationsKo();
    case 'zh':
      return AtomicLocalizationsZh();
  }

  throw FlutterError(
      'AtomicLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
