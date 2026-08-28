import 'package:flutter/material.dart' hide IconButton;
import 'package:provider/provider.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart' hide AlertDialog;

import 'profile_page.dart';
import 'theme_color_picker.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const SettingsPage({
    Key? key,
    this.onBackPressed,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late LoginStore _loginStore;
  late SemanticColorScheme colorsTheme;

  // Translate language options (same as Android SettingsViewModel)
  static const List<Map<String, String>> _translateLanguageOptions = [
    {"code": "zh", "name": "简体中文"},
    {"code": "zh-TW", "name": "繁體中文"},
    {"code": "en", "name": "English"},
    {"code": "ja", "name": "日本語"},
    {"code": "ko", "name": "한국어"},
    {"code": "fr", "name": "Français"},
    {"code": "es", "name": "Español"},
    {"code": "it", "name": "Italiano"},
    {"code": "de", "name": "Deutsch"},
    {"code": "tr", "name": "Türkçe"},
    {"code": "ru", "name": "Русский"},
    {"code": "pt", "name": "Português"},
    {"code": "vi", "name": "Tiếng Việt"},
    {"code": "id", "name": "Bahasa Indonesia"},
    {"code": "th", "name": "ภาษาไทย"},
    {"code": "ms", "name": "Bahasa Melayu"},
    {"code": "hi", "name": "हिन्दी"},
  ];

  @override
  void initState() {
    super.initState();
    _loginStore = LoginStore.shared;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  void showThemeSelector(BuildContext context, ThemeState themeState, ThemeType currentTheme) {
    final chatLocale = ChatLocalizations.of(context);

    final List<Map<String, dynamic>> themes = [
      {"label": chatLocale.themeLight, "value": ThemeType.light},
      {"label": chatLocale.themeDark, "value": ThemeType.dark},
      {"label": chatLocale.followSystem, "value": ThemeType.system},
    ];

    ActionSheet.show(
      context,
      actions: themes
          .map((theme) => ActionSheetItem(
                title: theme["label"],
                isDestructive: currentTheme == theme["value"],
                onTap: () => themeState.setThemeMode(theme["value"]),
              ))
          .toList(),
    );
  }

  Widget _buildThemeColorSwatch(ThemeState themeState) {
    final color = ThemeColorPicker.parseHex(themeState.currentPrimaryColor) ??
        ThemeColorPicker.parseHex(ThemeColorPicker.defaultPrimaryColor)!;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: themeState.colors.strokeColorPrimary, width: 1.5),
      ),
    );
  }

  Future<void> showThemeColorSelector(BuildContext context, ThemeState themeState) async {
    final hex = await ThemeColorPicker.show(context, selectedHex: themeState.currentPrimaryColor);
    if (hex != null) {
      themeState.setPrimaryColor(hex);
    }
  }

  void showFriendRequestSelector(BuildContext context, ChatLocalizations chatLocale, AllowType? currentAllowType) {
    final List<Map<String, dynamic>> options = [
      {"label": chatLocale.allowAny, "value": AllowType.allowAny},
      {"label": chatLocale.needConfirm, "value": AllowType.needConfirm},
      {"label": chatLocale.denyAny, "value": AllowType.denyAny},
    ];

    ActionSheet.show(
      context,
      actions: options
          .map((option) => ActionSheetItem(
                title: option["label"],
                isDestructive: currentAllowType == option["value"],
                onTap: () => _updateFriendRequestSetting(option["value"]),
              ))
          .toList(),
    );
  }

  Future<void> _updateFriendRequestSetting(AllowType allowType) async {
    final currentUser = _loginStore.loginState.loginUserInfo;

    if (currentUser != null) {
      final updatedProfile = UserProfile(
        userID: currentUser.userID,
        allowType: allowType,
      );

      await _loginStore.setSelfInfo(userInfo: updatedProfile);
    }
  }

  String _getTranslateLanguageDisplayName(String code) {
    final option = _translateLanguageOptions.firstWhere(
      (opt) => opt["code"] == code,
      orElse: () => {"code": code, "name": code},
    );
    return option["name"] ?? code;
  }

  void _showTranslateLanguageSelector(BuildContext context) {
    final currentLanguage = AppBuilder.getInstance().translateConfig.targetLanguage;

    ActionSheet.show(
      context,
      actions: _translateLanguageOptions
          .map((option) => ActionSheetItem(
                title: option["name"] ?? "English",
                isDestructive: currentLanguage == option["code"],
                onTap: () async {
                  await AppBuilder.getInstance().translateConfig.setTargetLanguage(option["code"]!);
                  setState(() {});
                },
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _loginStore,
      child: Scaffold(
        backgroundColor: colorsTheme.bgColorInput,
        appBar: AppBar(
          backgroundColor: colorsTheme.bgColorOperate,
          automaticallyImplyLeading: false,
          leading: widget.onBackPressed != null
              ? IconButton.buttonContent(
                  content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorPrimary)),
                  type: ButtonType.noBorder,
                  size: ButtonSize.l,
                  onClick: widget.onBackPressed,
                )
              : null,
          title: Text(ChatLocalizations.of(context).me,
              style: FontScheme.body4Bold.copyWith(color: colorsTheme.textColorPrimary)),
          centerTitle: true,
        ),
        body: Consumer<LoginStore>(
          builder: (context, loginStore, child) {
            return _buildBody(context, loginStore);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LoginStore loginStore) {
    ChatLocalizations chatLocale = ChatLocalizations.of(context);
    final themeState = BaseThemeProvider.of(context);
    final ThemeType currentTheme = themeState.currentType;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;
    final currentUser = loginStore.loginState.loginUserInfo;

    String getThemeName(ThemeType themeType) {
      switch (themeType) {
        case ThemeType.light:
          return chatLocale.themeLight;
        case ThemeType.dark:
          return chatLocale.themeDark;
        case ThemeType.system:
          return chatLocale.followSystem;
        default:
          return chatLocale.followSystem;
      }
    }

    String getLocaleName(Locale? locale) {
      switch (locale?.languageCode) {
        case 'zh':
          if (locale?.scriptCode == 'Hant') return chatLocale.languageZhHant;
          return chatLocale.languageZh;
        case 'en':
          return chatLocale.languageEn;
        case 'ja':
          return chatLocale.languageJa;
        case 'ko':
          return chatLocale.languageKo;
        case 'ar':
          return chatLocale.languageAr;
        default:
          return chatLocale.followSystem;
      }
    }

    void showLanguageSelector() {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      final chatLocale = ChatLocalizations.of(context);

      final List<Map<String, dynamic>> languages = [
        // {"label": chatLocale.followSystem, "value": "system"},
        {"label": chatLocale.languageZh, "value": "zh"},
        {"label": chatLocale.languageZhHant, "value": "zh_Hant"},
        {"label": chatLocale.languageEn, "value": "en"},
        // {"label": chatLocale.languageJa, "value": "ja"},
        // {"label": chatLocale.languageKo, "value": "ko"},
        // {"label": chatLocale.languageAr, "value": "ar"},
      ];

      String? selected;
      if (localeProvider.locale == null) {
        selected = "system";
      } else if (localeProvider.locale?.languageCode == "zh" && localeProvider.locale?.scriptCode == "Hant") {
        selected = "zh_Hant";
      } else {
        selected = localeProvider.locale?.languageCode;
      }

      ActionSheet.show(
        context,
        actions: languages
            .map((lang) => ActionSheetItem(
                  title: lang["label"],
                  isDestructive: selected == lang["value"],
                  onTap: () => localeProvider.changeLanguage(lang["value"]),
                ))
            .toList(),
      );
    }

    String getFriendRequestName(ChatLocalizations chatLocale, AllowType? allowType) {
      switch (allowType) {
        case AllowType.allowAny:
          return chatLocale.allowAny;
        case AllowType.needConfirm:
          return chatLocale.needConfirm;
        case AllowType.denyAny:
          return chatLocale.denyAny;
        default:
          return chatLocale.needConfirm;
      }
    }

    return Column(
      children: [
        Container(
          color: colorsTheme.bgColorOperate,
          padding: const EdgeInsets.all(16),
          child: InkWell(
            splashColor: themeState.colors.clearColor,
            highlightColor: themeState.colors.clearColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
            child: Row(
              children: [
                Avatar.image(
                  url: currentUser?.avatarURL,
                  name: (currentUser?.nickname?.isEmpty ?? true) ? currentUser?.userID : currentUser?.nickname,
                  size: AvatarSize.l,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (currentUser?.nickname?.isEmpty ?? true)
                            ? currentUser?.userID ?? ''
                            : currentUser?.nickname ?? '',
                        style: FontScheme.body4Regular.copyWith(
                          color: themeState.colors.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${currentUser?.userID ?? ''}",
                        style: FontScheme.caption3Regular.copyWith(
                          color: themeState.colors.textColorTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.selfSignature?.isEmpty ?? true
                            ? chatLocale.noSignature
                            : currentUser!.selfSignature!,
                        style: FontScheme.caption3Regular.copyWith(
                          color: themeState.colors.textColorTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                SettingWidgets.buildSettingGroup(
                  context: context,
                  children: [
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: chatLocale.theme,
                      value: getThemeName(currentTheme),
                      onTap: () {
                        showThemeSelector(context, themeState, currentTheme);
                      },
                    ),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: chatLocale.themeColor,
                      valueWidget: _buildThemeColorSwatch(themeState),
                      onTap: () => showThemeColorSelector(context, themeState),
                    ),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: chatLocale.language,
                      value: getLocaleName(currentLocale),
                      onTap: showLanguageSelector,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingWidgets.buildSettingGroup(
                  context: context,
                  children: [
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: chatLocale.addRule,
                      value: getFriendRequestName(chatLocale, currentUser?.allowType),
                      onTap: () {
                        showFriendRequestSelector(context, chatLocale, currentUser?.allowType);
                      },
                    ),
                    // Switch + its description are one card entry so the auto
                    // divider doesn't split them.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingWidgets.buildSettingRow(
                          context: context,
                          title: chatLocale.messageReadReceipt,
                          value: AppBuilder.getInstance().messageListConfig.enableReadReceipt,
                          onChanged: (value) async {
                            await AppBuilder.getInstance().messageListConfig.setEnableReadReceipt(value);
                            setState(() {});
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            AppBuilder.getInstance().messageListConfig.enableReadReceipt
                                ? chatLocale.messageReadReceiptEnabledDesc
                                : chatLocale.messageReadReceiptDisabledDesc,
                            style: FontScheme.caption2Regular.copyWith(
                              color: themeState.colors.textColorSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: chatLocale.translateTargetLanguage,
                      value: _getTranslateLanguageDisplayName(
                        AppBuilder.getInstance().translateConfig.targetLanguage,
                      ),
                      onTap: () => _showTranslateLanguageSelector(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
