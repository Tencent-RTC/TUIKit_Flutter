// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'chat_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class ChatLocalizationsAr extends ChatLocalizations {
  ChatLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get voiceTranslate => 'ترجمة';

  @override
  String get voiceCancelTranslation => 'إلغاء الترجمة';

  @override
  String get voiceSwitchLanguage => 'تبديل اللغة';

  @override
  String get voiceReadAloud => 'قراءة بصوت عالٍ';

  @override
  String get voiceStopReadAloud => 'إيقاف';

  @override
  String get voiceSwitchLanguageSheetTitle => 'تبديل لغة الترجمة';

  @override
  String get voiceTranslateFailed => 'فشلت الترجمة';

  @override
  String get voiceTtsFailed => 'فشل التشغيل';

  @override
  String get voiceMessageSettings => 'إعدادات الرسائل الصوتية';

  @override
  String get voiceClone => 'استنساخ الصوت';

  @override
  String get voiceSelect => 'اختيار الصوت';

  @override
  String get voiceCloneTip =>
      'سجّل مقطعًا صوتيًا مدته 10-18 ثانية لاستنساخ صوتك الخاص';

  @override
  String get voiceCloneReadingTipTitle => 'يُنصح بقراءة النص التالي:';

  @override
  String get voiceCloneSampleText =>
      'مرحبًا بالجميع، أنا مساعدك الصوتي الخاص، يسعدني خدمتك. الطقس جميل حقًا اليوم، أتمنى أن تكون في مزاج رائع.';

  @override
  String get voiceCloneStartRecord => 'اضغط لبدء التسجيل';

  @override
  String get voiceCloneStopRecord => 'اضغط لإيقاف التسجيل';

  @override
  String get voiceCloneRecordDone => 'اكتمل التسجيل';

  @override
  String get voiceCloneNameHint => 'أدخل اسم الصوت (اختياري)';

  @override
  String get voiceCloneSubmit => 'إرسال الاستنساخ';

  @override
  String get voiceCloneAuthTip =>
      'يتطلب إنشاء صوت الحصول على تسجيل صوتك. تُستخدم هذه المعلومات الحساسة فقط لهذه الميزة. إذا لم توافق على التفويض، فقد لا تتمكن من استخدام استنساخ الصوت. التسجيل يعني الموافقة على التفويض.';

  @override
  String get voiceCloneSuccessTitle => 'نجح الاستنساخ';

  @override
  String get voiceCloneSuccessMessage => 'تم إنشاء صوتك الخاص بنجاح!';

  @override
  String get voiceCloneFailed => 'فشل استنساخ الصوت';

  @override
  String get voiceCloneEmptyRecord => 'يرجى تسجيل مقطع صوتي أولاً';

  @override
  String get voiceCloneTooShortTitle => 'التسجيل قصير جدًا';

  @override
  String get voiceCloneTooShortMessage => 'يرجى التسجيل لمدة 3 ثوانٍ على الأقل';

  @override
  String get voiceCloneDefaultName => 'صوتي';

  @override
  String get voiceSelectDefaultGroup => 'الأصوات الافتراضية';

  @override
  String get voiceSelectCustomGroup => 'الأصوات المخصصة';

  @override
  String get voiceSelectEmptyCustom => 'لا توجد أصوات مخصصة بعد';

  @override
  String get voiceCustomBadge => 'مخصص';

  @override
  String get voiceDelete => 'حذف';

  @override
  String get voiceConfirm => 'موافق';

  @override
  String get voiceDeleteFailed => 'فشل الحذف';

  @override
  String get voiceDefault => 'افتراضي';

  @override
  String get voiceXiaoxuMale => 'شياوشو (ذكر)';

  @override
  String get voiceXiaomeiFemale => 'شياومي (أنثى)';

  @override
  String get voiceXiaoxinFemale => 'شياوشين (أنثى)';

  @override
  String get voiceXiaoyueFemale => 'شياويوي (أنثى)';

  @override
  String get listenFromHere => 'استمع من هنا';

  @override
  String get listenSelfSpeaker => 'أنا';

  @override
  String listenSays(String speaker) {
    return '$speaker قال: ';
  }

  @override
  String listenSentImage(String speaker) {
    return '$speaker أرسل صورة';
  }

  @override
  String listenSentVideo(String speaker) {
    return '$speaker أرسل فيديو';
  }

  @override
  String listenSentFile(String speaker) {
    return '$speaker أرسل ملفًا';
  }

  @override
  String listenSentMerged(String speaker, String title) {
    return '$speaker أرسل: $title';
  }

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get chat => 'الرسائل';

  @override
  String get me => 'أنا';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'مظلم';

  @override
  String get followSystem => 'اتبع النظام';

  @override
  String get color => 'لون';

  @override
  String get themeColor => 'لون السمة';

  @override
  String get selectThemeColor => 'اختر لون السمة';

  @override
  String get colorHue => 'تدرج اللون';

  @override
  String get colorSaturation => 'التشبع';

  @override
  String get colorBrightness => 'السطوع';

  @override
  String get colorHex => 'القيمة اللونية';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get language => 'اللغة';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageAr => 'اَلْعَرَبِيَّة';

  @override
  String get contact => 'جهات الاتصال';

  @override
  String get messageRevokedBySelf => 'قمت بسحب رسالة';

  @override
  String get messageRevokedByOther => 'قام الطرف الآخر بسحب رسالة';

  @override
  String messageRevokedByUser(Object user) {
    return 'قام $user بسحب رسالة';
  }

  @override
  String groupMemberJoined(Object user) {
    return 'انضم $user إلى المجموعة';
  }

  @override
  String groupMemberInvited(Object operator, Object users) {
    return 'دعا $operator $users للانضمام إلى المجموعة';
  }

  @override
  String groupMemberQuit(Object user) {
    return 'غادر $user المجموعة';
  }

  @override
  String groupMemberKicked(Object operator, Object users) {
    return 'أزال $operator $users من المجموعة';
  }

  @override
  String groupAdminSet(Object users) {
    return 'تم تعيين $users كمشرفين';
  }

  @override
  String groupAdminCancelled(Object users) {
    return 'تم إلغاء صلاحيات المشرف لـ $users';
  }

  @override
  String groupMessagePinned(Object user) {
    return 'قام $user بتثبيت رسالة';
  }

  @override
  String groupMessageUnpinned(Object user) {
    return 'قام $user بإلغاء تثبيت رسالة';
  }

  @override
  String get you => 'أنت';

  @override
  String get muted => 'تم كتم الصوت';

  @override
  String get unmuted => 'تم إلغاء كتم الصوت';

  @override
  String get day => 'يوم';

  @override
  String get hour => 'ساعة';

  @override
  String get min => 'دقيقة';

  @override
  String get second => 'ثانية';

  @override
  String get messageTypeImage => '[صورة]';

  @override
  String get messageTypeVoice => '[صوت]';

  @override
  String get messageTypeFile => '[ملف]';

  @override
  String get messageTypeVideo => '[فيديو]';

  @override
  String get messageTypeSticker => '[ملصق]';

  @override
  String get messageTypeCustom => '[رسالة مخصصة]';

  @override
  String get groupNameChangedTo => 'تم تغيير اسم المجموعة إلى';

  @override
  String get groupIntroChangedTo => 'تم تغيير وصف المجموعة إلى';

  @override
  String get groupNoticeChangedTo => 'تم تغيير إشعار المجموعة إلى';

  @override
  String get groupNoticeDeleted => 'تم حذف إشعار المجموعة';

  @override
  String get groupAvatarChanged => 'تم تغيير صورة المجموعة';

  @override
  String get groupOwnerTransferredTo => 'تم نقل ملكية المجموعة إلى';

  @override
  String get groupMuteAllEnabled => 'تم تفعيل كتم الصوت للجميع';

  @override
  String get groupMuteAllDisabled => 'تم إلغاء كتم الصوت للجميع';

  @override
  String get unknown => 'غير معروف';

  @override
  String get groupJoinMethodChangedTo => 'تم تغيير طريقة الانضمام إلى';

  @override
  String get groupInviteMethodChangedTo => 'تم تغيير طريقة الدعوة إلى';

  @override
  String get weekdaySunday => 'الأحد';

  @override
  String get weekdayMonday => 'الاثنين';

  @override
  String get weekdayTuesday => 'الثلاثاء';

  @override
  String get weekdayWednesday => 'الأربعاء';

  @override
  String get weekdayThursday => 'الخميس';

  @override
  String get weekdayFriday => 'الجمعة';

  @override
  String get weekdaySaturday => 'السبت';

  @override
  String get yesterday => 'أمس';

  @override
  String dateMonthDayFormat(int month, int day) {
    return '$day/$month';
  }

  @override
  String dateYearMonthDayFormat(int year, int month, int day) {
    return '$day/$month/$year';
  }

  @override
  String get userID => 'معرف المستخدم';

  @override
  String get groupIDLabel => 'معرف المجموعة';

  @override
  String get userIDLabel => 'معرف المستخدم';

  @override
  String get file => 'ملف';

  @override
  String get recordAVideo => 'تسجيل فيديو';

  @override
  String get audioCall => 'مكالمة صوتية';

  @override
  String get videoCall => 'مكالمة فيديو';

  @override
  String get send => 'يرسل';

  @override
  String get more => 'المزيد';

  @override
  String get delete => 'حذف';

  @override
  String get clearMessage => 'مسح سجل الدردشة';

  @override
  String get pin => 'تثبيت الدردشة';

  @override
  String get unpin => 'إلغاء التثبيت';

  @override
  String get startConversation => 'بدء دردشة';

  @override
  String get createGroupChat => 'إنشاء مجموعة';

  @override
  String get addFriend => 'أضف أصدقاء';

  @override
  String get addGroup => 'إضافة مجموعة';

  @override
  String get addContact => 'إضافة جهة اتصال';

  @override
  String get joinGroup => 'الانضمام إلى المجموعة';

  @override
  String get createGroupTips => 'إنشاء مجموعة';

  @override
  String get createCommunity => 'إنشاء مجتمع';

  @override
  String get groupIDInvalid =>
      'معرف المجموعة غير صالح، يرجى التحقق من صحة معرف المجموعة';

  @override
  String get productDocumentation => 'عرض دليل المنتج';

  @override
  String get create => 'إنشاء';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get groupIDOption => 'معرف المجموعة (اختياري)';

  @override
  String get groupFaceUrl => 'صورة رمزية للمجموعة';

  @override
  String get groupMemberSelected => 'الأعضاء المحددين في المجموعة';

  @override
  String get groupWorkType => 'مجموعة عمل الأصدقاء (Work)';

  @override
  String get groupPublicType => 'مجموعة تواصل الغرباء (Public)';

  @override
  String get groupMeetingType => 'مجموعة اجتماعات مؤقتة (Meeting)';

  @override
  String get groupCommunityType => 'مجتمع (Community)';

  @override
  String get groupWorkDesc =>
      'مجموعة عمل الأصدقاء (Work): تشبه محادثات WeChat العادية، بعد الإنشاء، يمكن للأصدقاء الموجودين في المجموعة دعوة أصدقائهم للانضمام دون الحاجة إلى موافقة المضافين أو الموافقة من قبل مالك المجموعة.';

  @override
  String get groupPublicDesc =>
      'مجموعة تواصل الغرباء (Public): تشبه مجموعات QQ، بعد الإنشاء، يمكن لمالك المجموعة تعيين مشرفين للمجموعة، عندما يبحث المستخدمون عن معرف المجموعة ويطلبون الانضمام، يجب عليهم الحصول على موافقة من مالك المجموعة أو المشرفين قبل الانضمام إلى المجموعة.';

  @override
  String get groupMeetingDesc =>
      'مجموعة اجتماعات مؤقتة (Meeting): بعد الإنشاء، يمكن للمستخدمين الانضمام والخروج من المجموعة بحرية، ويمكنهم عرض الرسائل قبل الانضمام إلى المجموعة. تستخدم هذه المجموعات في سيناريوهات الاجتماعات الصوتية والمرئية والتعليم عبر الإنترنت وغيرها من السيناريوهات التي تتطلب منتجات الصوت والفيديو الفورية.';

  @override
  String get groupCommunityDesc =>
      ' المجتمع (Community): بعد الإنشاء يمكن الدخول والخروج بحرية، يدعم حتى 100000 شخص، يدعم تخزين الرسائل السابقة، بعد البحث عن معرف المجموعة وإرسال طلب الانضمام، يمكن الانضمام إلى المجموعة دون حاجة لموافقة المشرف.';

  @override
  String get groupDetail => 'تفاصيل المحادثة الجماعية';

  @override
  String get transferGroupOwner => 'نقل ملكية المجموعة';

  @override
  String get publicGroup => 'مجموعة عامة';

  @override
  String get groupOfAnnouncement => 'إشعار المجموعة';

  @override
  String get groupManagement => 'إدارة المجموعة';

  @override
  String get groupType => 'نوع المجموعة';

  @override
  String get addGroupWay => 'طريقة الانضمام النشطة';

  @override
  String get inviteGroupType => 'طريقة الدعوة للانضمام';

  @override
  String get myAliasInGroup => 'اسمي المستعار في المجموعة';

  @override
  String get doNotDisturb => 'عدم إزعاج';

  @override
  String get groupMember => 'أعضاء المجموعة';

  @override
  String get profileRemark => 'اسم الملاحظة';

  @override
  String get groupEdit => 'تحرير';

  @override
  String get blackList => 'قائمة الحظر';

  @override
  String get profileBlack => 'إضافة إلى القائمة السوداء';

  @override
  String get deleteFriend => 'حذف الصديق';

  @override
  String get search => 'بحث';

  @override
  String get chatHistory => 'سجل المحادثة';

  @override
  String get groups => 'المجموعات';

  @override
  String get newFriend => 'جهات اتصال جديدة';

  @override
  String get myGroups => 'مجموعاتي';

  @override
  String get contactInfo => 'تفاصيل';

  @override
  String get tuiEmojiSmile => '[ابتسامة]';

  @override
  String get tuiEmojiExpect => '[توقع]';

  @override
  String get tuiEmojiBlink => '[غمز]';

  @override
  String get tuiEmojiGuffaw => '[ضحكة عالية]';

  @override
  String get tuiEmojiKindSmile => '[ابتسامة لطيفة]';

  @override
  String get tuiEmojiHaha => '[هاها]';

  @override
  String get tuiEmojiCheerful => '[مرح]';

  @override
  String get tuiEmojiSpeechless => '[بلا كلمات]';

  @override
  String get tuiEmojiAmazed => '[مدهش]';

  @override
  String get tuiEmojiSorrow => '[حزن]';

  @override
  String get tuiEmojiComplacent => '[راض]';

  @override
  String get tuiEmojiSilly => '[ضحكة غبية]';

  @override
  String get tuiEmojiLustful => '[شهواني]';

  @override
  String get tuiEmojiGiggle => '[قهقهة]';

  @override
  String get tuiEmojiKiss => '[قبلة]';

  @override
  String get tuiEmojiWail => '[بكاء]';

  @override
  String get tuiEmojiTearsLaugh => '[ضحك حتى الدموع]';

  @override
  String get tuiEmojiTrapped => '[محاصر]';

  @override
  String get tuiEmojiMask => '[قناع]';

  @override
  String get tuiEmojiFear => '[خوف]';

  @override
  String get tuiEmojiBareTeeth => '[أسنان عارية]';

  @override
  String get tuiEmojiFlareUp => '[غضب]';

  @override
  String get tuiEmojiYawn => '[تثاؤب]';

  @override
  String get tuiEmojiTact => '[دهاء]';

  @override
  String get tuiEmojiStareyes => '[عيون النجوم]';

  @override
  String get tuiEmojiShutUp => '[أغلق فمك]';

  @override
  String get tuiEmojiSigh => '[تنهد]';

  @override
  String get tuiEmojiHehe => '[ههه]';

  @override
  String get tuiEmojiSilent => '[صامت]';

  @override
  String get tuiEmojiSurprised => '[متفاجئ]';

  @override
  String get tuiEmojiAskance => '[نظرة جانبية]';

  @override
  String get tuiEmojiOk => '[حسنا]';

  @override
  String get tuiEmojiShit => '[براز]';

  @override
  String get tuiEmojiMonster => '[وحش]';

  @override
  String get tuiEmojiDaemon => '[شيطان]';

  @override
  String get tuiEmojiRage => '[غضب]';

  @override
  String get tuiEmojiFool => '[أحمق]';

  @override
  String get tuiEmojiPig => '[خنزير]';

  @override
  String get tuiEmojiCow => '[بقرة]';

  @override
  String get tuiEmojiAi => '[الذكاء الصناعي]';

  @override
  String get tuiEmojiSkull => '[جمجمة]';

  @override
  String get tuiEmojiBombs => '[قنابل]';

  @override
  String get tuiEmojiCoffee => '[قهوة]';

  @override
  String get tuiEmojiCake => '[كعكة]';

  @override
  String get tuiEmojiBeer => '[بيرة]';

  @override
  String get tuiEmojiFlower => '[زهرة]';

  @override
  String get tuiEmojiWatermelon => '[بطيخ]';

  @override
  String get tuiEmojiRich => '[غني]';

  @override
  String get tuiEmojiHeart => '[قلب]';

  @override
  String get tuiEmojiMoon => '[قمر]';

  @override
  String get tuiEmojiSun => '[شمس]';

  @override
  String get tuiEmojiStar => '[نجمة]';

  @override
  String get tuiEmojiRedPacket => '[حزمة حمراء]';

  @override
  String get tuiEmojiCelebrate => '[احتفال]';

  @override
  String get tuiEmojiBless => '[بركة]';

  @override
  String get tuiEmojiFortune => '[ثروة]';

  @override
  String get tuiEmojiConvinced => '[مقتنع]';

  @override
  String get tuiEmojiProhibit => '[ممنوع]';

  @override
  String get tuiEmoji666 => '[666]';

  @override
  String get tuiEmoji857 => '[857]';

  @override
  String get tuiEmojiKnife => '[سكين]';

  @override
  String get tuiEmojiLike => '[أعجبني]';

  @override
  String get sendMessage => 'إرسال رسالة';

  @override
  String get quitGroup => 'الخروج من المحادثة الجماعية';

  @override
  String get dismissGroup => 'حل المجموعة';

  @override
  String get groupNoticeEmpty => 'لا يوجد إعلانات حاليًا.';

  @override
  String get next => 'التالى';

  @override
  String get agree => 'قبول';

  @override
  String get accept => 'قبول';

  @override
  String get refuse => 'رفض';

  @override
  String get noFriendApplicationList => 'لا توجد طلبات صداقة جديدة';

  @override
  String get noBlackList => 'لا يوجد أصدقاء في القائمة السوداء';

  @override
  String get noGroupList => 'لا توجد محادثات جماعية';

  @override
  String get noGroupApplicationList => 'لا يوجد طلب جماعي حتى الآن';

  @override
  String get groupChatNotifications => 'إشعارات دردشة المجموعة';

  @override
  String get invite => 'دعوة';

  @override
  String get groupApplicationAllReadyBeenProcessed =>
      'تم معالجة هذا الطلب أو الدعوة بالفعل';

  @override
  String get accepted => 'تمت الموافقة';

  @override
  String get refused => 'تم الرفض';

  @override
  String get copy => 'نسخ';

  @override
  String get recall => 'استدعاء';

  @override
  String get forward => 'إعادة توجيه';

  @override
  String get quote => 'اقتباس';

  @override
  String get searchUserID => 'يرجى إدخال معرف المستخدم للبحث عن المستخدمين';

  @override
  String get searchGroupID => 'معرف المجموعة';

  @override
  String get searchGroupIDHint => 'يرجى إدخال معرف المجموعة للبحث عن المجموعات';

  @override
  String get addFailed => 'إضافة فاشلة';

  @override
  String get joinGroupFailed => 'فشل في الانضمام إلى المجموعة';

  @override
  String get alreadyFriend => 'أصدقاء بالفعل';

  @override
  String get signature => 'التوقيع';

  @override
  String get fillInTheVerificationInformation => 'إملأ معلومات التحقق';

  @override
  String get joinedGroupSuccessfully => 'نجاح';

  @override
  String get contactAddedSuccessfully => 'تمت إضافة جهة الاتصال بنجاح';

  @override
  String get message => 'الرسائل';

  @override
  String get groupWork => 'مجموعة العمل';

  @override
  String get groupPublic => 'مجموعة عامة';

  @override
  String get groupMeeting => 'مجموعة الاجتماعات';

  @override
  String get groupCommunity => 'مجتمع';

  @override
  String get groupAVChatRoom => 'مجموعة البث المباشر';

  @override
  String get groupAddAny => 'موافقة تلقائية';

  @override
  String get groupAddAuth => 'موافقة المدير';

  @override
  String get groupAddForbid => 'منع الانضمام';

  @override
  String get groupInviteForbid => 'منع الدعوة';

  @override
  String get groupOwner => 'مالك المجموعة';

  @override
  String get member => 'عضو';

  @override
  String get admin => 'مشرف';

  @override
  String get modifyGroupName => 'تعديل اسم المجموع';

  @override
  String get modifyGroupNickname => 'تعديل بطاقة اسم المجموعة';

  @override
  String get chatBackground => 'خلفية الدردشة';

  @override
  String get selectChatBackground => 'اختيار خلفية الدردشة';

  @override
  String get chatBackgroundDefault => 'افتراضي';

  @override
  String get chatBackgroundCustom => 'مخصص';

  @override
  String get quitGroupTip => 'هل تريد بالتأكيد الخروج من هذه المجموعة؟';

  @override
  String get dismissGroupTip => 'هل تريد بالتأكيد حل هذه المجموعة؟';

  @override
  String get clearMsgTip => 'هل تريد بالتأكيد مسح سجل الدردشة؟';

  @override
  String get muteAll => 'كتم الجميع';

  @override
  String get addMuteMemberTip => 'إضافة أعضاء المجموعة الذين يجب كتمهم';

  @override
  String get groupMuteTip =>
      'بعد تفعيل كتم الجميع، سيتم السماح فقط للمدير والمشرفين بالتحدث.';

  @override
  String get deleteFriendTip => 'هل تريد بالتأكيد حذف جهة الاتصال؟';

  @override
  String get remarkEdit => 'تعديل الملاحظات';

  @override
  String get detail => 'تفاصيل';

  @override
  String get setAdmin => 'تعيين كمدير';

  @override
  String get cancelAdmin => 'إلغاء تعيين المدير';

  @override
  String get deleteGroupMemberTip => 'تأكيد حذف عضو المجموعة؟';

  @override
  String get settingSuccess => 'تم الإعداد بنجاح!';

  @override
  String get settingFail => 'فشل الإعداد!';

  @override
  String get noMore => 'لا مزيد';

  @override
  String get sayTimeShort => 'مدة الكلام قصيرة جدًا';

  @override
  String get recordLimitTips => 'تم الوصول إلى الحد الأقصى لطول الصوت';

  @override
  String get chooseAvatar => 'اختر صورة رمزية';

  @override
  String get inputGroupName => 'الرجاء إدخال اسم المجموعة';

  @override
  String get error => 'خطأ';

  @override
  String maxCountFile(Object maxCount) {
    return 'يمكنك تحديد $maxCount ملف كحد أقصى فقط';
  }

  @override
  String get groupIntroDeleted => 'تم حذف ملف تعريف المجموعة';

  @override
  String get groupJoinForbidden => 'الانضمام محظور';

  @override
  String get groupJoinApproval => 'يتطلب موافقة المشرف';

  @override
  String get groupJoinFree => 'انضمام حر';

  @override
  String get groupInviteForbidden => 'الدعوة محظورة';

  @override
  String get groupInviteApproval => 'يتطلب موافقة المشرف';

  @override
  String get groupInviteFree => 'دعوة حرة';

  @override
  String get friendLimit => 'لقد وصلت إلى الحد الأقصى لعدد الأصدقاء في النظام';

  @override
  String get otherFriendLimit =>
      'لقد وصل الشخص المطلوب إلى الحد الأقصى لعدد الأصدقاء في النظام';

  @override
  String get inBlacklist => 'الشخص المطلوب موجود في القائمة السوداء الخاصة بك';

  @override
  String get setInBlacklist =>
      'لقد تم إضافتك إلى القائمة السوداء من قبل الشخص المطلوب';

  @override
  String get forbidAddFriend => 'الشخص المطلوب قد منع إضافة الأصدقاء';

  @override
  String get waitAgreeFriend => 'في انتظار موافقة الصديق';

  @override
  String get userNotExist => 'المستخدم غير موجود';

  @override
  String get addGroupPermissionDeny => 'منع الانضمام';

  @override
  String get addGroupAlreadyMember => 'أنت بالفعل عضو في المجموعة';

  @override
  String get addGroupNotFound => 'المجموعة غير موجودة';

  @override
  String get addGroupFullMember => 'المجموعة ممتلئة بالأعضاء';

  @override
  String chatRecords(Object count) {
    return '$count سجل ذو صلة';
  }

  @override
  String get addRule => 'عندما يضيفني شخص ما كصديق';

  @override
  String get allowAny => 'السماح لأي شخص';

  @override
  String get denyAny => 'رفض أي شخص';

  @override
  String get needConfirm => 'يتطلب التحقق';

  @override
  String get noSignature => 'لا يوجد توقيع شخصي بعد';

  @override
  String get gender => 'الجنس';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get birthday => 'عيد الميلاد';

  @override
  String get setNickname => 'تعديل الاسم المستعار';

  @override
  String get setSignature => 'تعديل التوقيع الشخصي';

  @override
  String get messageNum => 'رسالة';

  @override
  String get draft => '[مسودة]';

  @override
  String get sendMessageFail => 'فشل الإرسال';

  @override
  String get resendTips => 'هل تريد إعادة الإرسال؟';

  @override
  String get stopCallTip => 'مدة المكالمة';

  @override
  String get startCall => 'بدء مكالمة';

  @override
  String get acceptCall => 'تم الرد';

  @override
  String get groupCallSend => 'تم بدء مكالمة جماعية';

  @override
  String get groupCallEnd => 'تم إنهاء المكالمة';

  @override
  String get groupCallNoAnswer => 'لم يتم الرد';

  @override
  String get groupCallReject => 'رفض مكالمة جماعية ';

  @override
  String get groupCallAccept => 'قبل المكالمة ';

  @override
  String get groupCallConfirmSwitchToAudio => 'تأكيد تحويل الفيديو إلى صوتي ';

  @override
  String get unknownCall => 'مكالمة غير معروفة';

  @override
  String get join => 'انضم إلينا';

  @override
  String peopleOnCall(Object number) {
    return '$number في مكالمة حاليًا.';
  }

  @override
  String get groupReadBy => 'مقروء';

  @override
  String get groupDeliveredTo => 'غير مقروء';

  @override
  String get readReceiptAllRead => 'تمت القراءة من الجميع';

  @override
  String readReceiptNPersonRead(int count) {
    return 'قرأها $count أشخاص';
  }

  @override
  String get messageReadReceipt => 'حالة قراءة الرسالة';

  @override
  String get messageReadReceiptEnabledDesc =>
      'عند الإغلاق، لن تظهر حالة قراءة الرسائل في الرسائل التي تستلمها أو ترسلها، ولن تتمكن من معرفة ما إذا قرأ الطرف الآخر الرسالة أم لا، وبالمثل، الطرف الآخر لن يتمكن من معرفة ما إذا قرأت الرسالة أم لا.';

  @override
  String get messageReadReceiptDisabledDesc =>
      'عند الفتح، ستظهر حالة قراءة الرسائل في الرسائل التي تستلمها أو ترسلها في المحادثات الجماعية، ويمكنك رؤية ما إذا قرأ الطرف الآخر الرسالة أم لا. إذا قام أصدقاؤك في المحادثات الفردية بتفعيل حالة قراءة الرسائل، ستظهر حالة قراءة الرسائل في المحادثات الفردية التي تتبادلها معهم.';

  @override
  String get markAsRead => 'وضع علامة كمقروء';

  @override
  String get markAsUnread => 'وضع علامة كغير مقروء';

  @override
  String get multiSelect => 'تحديد متعدد';

  @override
  String get postEmojis => 'إضافة تفاعل';

  @override
  String get recentlyUsed => 'المستخدمة مؤخرا';

  @override
  String get allEmojis => 'الكل';

  @override
  String get selectChat => 'اختر محادثة';

  @override
  String selectedCount(int count) {
    return 'تم تحديد $count';
  }

  @override
  String get forwardIndividually => 'إعادة توجيه فردي';

  @override
  String get forwardMerged => 'إعادة توجيه مدمج';

  @override
  String get groupChatHistory => 'سجل محادثة المجموعة';

  @override
  String c2cChatHistoryFormat(String name) {
    return 'سجل دردشة $name';
  }

  @override
  String chatHistoryForSomebodyFormat(String name1, String name2) {
    return 'سجل الدردشة لـ $name1 و $name2';
  }

  @override
  String get forwardCompatibleText => 'يرجى الترقية لعرض سجل المحادثة';

  @override
  String get forwardFailedMessageTip => 'لا يمكن إعادة توجيه الرسائل الفاشلة!';

  @override
  String get forwardSeparateLimitTip =>
      'عدد الرسائل كبير جدًا، إعادة التوجيه الفردية غير مدعومة';

  @override
  String get deleteMessagesConfirmTip => 'هل أنت متأكد من حذف الرسائل المحددة؟';

  @override
  String get deleteConversationTip => 'هل أنت متأكد من حذف هذه المحادثة؟';

  @override
  String get conversationListAtAll => '[@الجميع]';

  @override
  String get conversationListAtMe => '[@أنا]';

  @override
  String get messageInputAllMembers => 'الجميع';

  @override
  String get selectMentionMember => 'اختر الأعضاء';

  @override
  String get tapToRemove => 'اضغط للإزالة';

  @override
  String get messageTypeSecurityStrike => 'يتضمن محتوى حساس';

  @override
  String get convertToText => 'تحويل إلى نص';

  @override
  String get convertToTextFailed => 'فشل التحويل';

  @override
  String get hide => 'إخفاء';

  @override
  String get translate => 'ترجمة';

  @override
  String get translateFailed => 'فشلت الترجمة';

  @override
  String get translateDefaultTips => 'الترجمة مدعومة من Tencent Cloud IM';

  @override
  String get translating => 'جارٍ الترجمة...';

  @override
  String get translateTargetLanguage => 'لغة الترجمة المستهدفة';

  @override
  String get backToLatest => 'العودة إلى الأحدث';

  @override
  String newMessageCount(int count) {
    return '$count رسائل جديدة';
  }

  @override
  String get holdToTalk => 'اضغط مع الاستمرار للتحدث';

  @override
  String get sendMessageOrHoldToTalk => 'اكتب أو اضغط مطولاً للتحدث...';

  @override
  String get releaseToSend => 'حرر للإرسال';

  @override
  String get releaseToCancel => 'حرر للإلغاء';

  @override
  String recordCountdownTips(int seconds) {
    return 'سيتوقف التسجيل بعد $seconds ثانية';
  }

  @override
  String get backToQuotePosition => 'العودة إلى موضع الاقتباس';

  @override
  String get quotedMessageRevoked => 'تم استدعاء المحتوى المقتبس';

  @override
  String get quotedMessageNotFound => 'المحتوى المقتبس غير متوفر';

  @override
  String get quotedOriginalMessageUnreachable =>
      'تعذر تحديد موقع الرسالة الأصلية';

  @override
  String reactionUserSummary(String name, int totalCount, int othersCount) {
    return '$name و$othersCount آخرين';
  }

  @override
  String get messageTypeMerged => '[سجلات الدردشة]';

  @override
  String get messageTypeUnknown => '[رسالة]';

  @override
  String get releaseToConvert => 'حرر للتحويل إلى نص';

  @override
  String get voiceToTextFailed => 'لم يتم التعرف على أي نص';

  @override
  String get sendOriginalVoice => 'إرسال الصوت الأصلي';

  @override
  String get addMembers => 'إضافة أعضاء';

  @override
  String get album => 'ألبوم';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get takeAPhoto => 'التقاط صورة';

  @override
  String get callRejectCaller => 'تم رفضه من الطرف الآخ';

  @override
  String get callRejectCallee => 'تم الرفض';

  @override
  String get callCancelCaller => 'تم الإلغاء';

  @override
  String get callCancelCallee => 'تم الإلغاء من الطرف الآخر';

  @override
  String get callTimeoutCaller => 'لا يوجد رد من الطرف الآخر';

  @override
  String get callTimeoutCallee => 'انتهاء الاتصال بالوقت المحدد';

  @override
  String get callLineBusyCaller => 'الخط مشغول عند الطرف الآخر';

  @override
  String get callLineBusyCallee => 'الخط مشغول عند الطرف الآخر';

  @override
  String get callingSwitchToAudio => 'تحويل الفيديو إلى صوتي';

  @override
  String get callingSwitchToAudioAccept => 'تأكيد تحويل الفيديو إلى صوتي';
}
