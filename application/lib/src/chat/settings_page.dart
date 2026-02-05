import 'package:flutter/material.dart' hide IconButton;
import 'package:provider/provider.dart';
import 'package:tuikit_atomic_x/atomicx.dart' hide AlertDialog;

import 'profile_page.dart';

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
    final atomicLocale = AtomicLocalizations.of(context);

    final List<Map<String, dynamic>> themes = [
      {"label": atomicLocale.themeLight, "value": ThemeType.light},
      {"label": atomicLocale.themeDark, "value": ThemeType.dark},
      {"label": atomicLocale.followSystem, "value": ThemeType.system},
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

  void showColorSelector(BuildContext context, ThemeState themeState) {
    final List<String> presetColors = [
      '#1c66e5',
      '#7ff879',
      '#ff6b6b',
      '#ffa726',
      '#ab47bc',
      '#26a69a',
      '#ff7043',
      '#42a5f5',
    ];

    String? selectedColor = themeState.currentPrimaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Color'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...presetColors.map((color) => RadioListTile<String>(
                        title: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(color),
                          ],
                        ),
                        value: color,
                        groupValue: selectedColor,
                        onChanged: (value) {
                          setState(() {
                            selectedColor = value;
                          });
                        },
                      )),
                  RadioListTile<String>(
                    title: const Text('Clear Color'),
                    value: '',
                    groupValue: selectedColor,
                    onChanged: (value) {
                      setState(() {
                        selectedColor = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AtomicLocalizations.of(context).cancel),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedColor != null && selectedColor!.isNotEmpty) {
                      themeState.setPrimaryColor(selectedColor!);
                    } else {
                      themeState.clearPrimaryColor();
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(AtomicLocalizations.of(context).confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showFriendRequestSelector(BuildContext context, AtomicLocalizations atomicLocale, AllowType? currentAllowType) {
    final List<Map<String, dynamic>> options = [
      {"label": atomicLocale.allowAny, "value": AllowType.allowAny},
      {"label": atomicLocale.needConfirm, "value": AllowType.needConfirm},
      {"label": atomicLocale.denyAny, "value": AllowType.denyAny},
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
        backgroundColor: colorsTheme.bgColorOperate,
        appBar: AppBar(
          backgroundColor: colorsTheme.bgColorOperate,
          automaticallyImplyLeading: false,
          leading: widget.onBackPressed != null
              ? IconButton.buttonContent(
                  content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
                  type: ButtonType.noBorder,
                  size: ButtonSize.l,
                  onClick: widget.onBackPressed,
                )
              : null,
          title: Text(AtomicLocalizations.of(context).settings,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: colorsTheme.textColorPrimary)),
          centerTitle: false,
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
    AtomicLocalizations atomicLocale = AtomicLocalizations.of(context);
    final themeState = BaseThemeProvider.of(context);
    final ThemeType currentTheme = themeState.currentType;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;
    final currentUser = loginStore.loginState.loginUserInfo;

    String getThemeName(ThemeType themeType) {
      switch (themeType) {
        case ThemeType.light:
          return atomicLocale.themeLight;
        case ThemeType.dark:
          return atomicLocale.themeDark;
        case ThemeType.system:
          return atomicLocale.followSystem;
        default:
          return atomicLocale.followSystem;
      }
    }

    String getLocaleName(Locale? locale) {
      switch (locale?.languageCode) {
        case 'zh':
          if (locale?.scriptCode == 'Hant') return atomicLocale.languageZhHant;
          return atomicLocale.languageZh;
        case 'en':
          return atomicLocale.languageEn;
        case 'ja':
          return atomicLocale.languageJa;
        case 'ko':
          return atomicLocale.languageKo;
        case 'ar':
          return atomicLocale.languageAr;
        default:
          return atomicLocale.followSystem;
      }
    }

    void showLanguageSelector() {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      final atomicLocale = AtomicLocalizations.of(context);

      final List<Map<String, dynamic>> languages = [
        // {"label": atomicLocale.followSystem, "value": "system"},
        {"label": atomicLocale.languageZh, "value": "zh"},
        {"label": atomicLocale.languageZhHant, "value": "zh_Hant"},
        {"label": atomicLocale.languageEn, "value": "en"},
        // {"label": atomicLocale.languageJa, "value": "ja"},
        // {"label": atomicLocale.languageKo, "value": "ko"},
        // {"label": atomicLocale.languageAr, "value": "ar"},
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

    String getFriendRequestName(AtomicLocalizations atomicLocale, AllowType? allowType) {
      switch (allowType) {
        case AllowType.allowAny:
          return atomicLocale.allowAny;
        case AllowType.needConfirm:
          return atomicLocale.needConfirm;
        case AllowType.denyAny:
          return atomicLocale.denyAny;
        default:
          return atomicLocale.needConfirm;
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
                CircleAvatar(
                  radius: 30,
                  backgroundImage: currentUser?.avatarURL != null && currentUser!.avatarURL!.isNotEmpty
                      ? NetworkImage(currentUser.avatarURL!)
                      : null,
                  child: currentUser?.avatarURL == null || currentUser!.avatarURL!.isEmpty
                      ? const Icon(Icons.person, size: 30)
                      : null,
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeState.colors.textColorPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${currentUser?.userID ?? ''}",
                        style: TextStyle(
                          fontSize: 14,
                          color: themeState.colors.textColorSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.selfSignature?.isEmpty ?? true
                            ? atomicLocale.noSignature
                            : currentUser!.selfSignature!,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeState.colors.textColorSecondary,
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
                const SizedBox(height: 24),
                SettingWidgets.buildSettingGroup(
                  context: context,
                  children: [
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: atomicLocale.addRule,
                      value: getFriendRequestName(atomicLocale, currentUser?.allowType),
                      onTap: () {
                        showFriendRequestSelector(context, atomicLocale, currentUser?.allowType);
                      },
                    ),
                    SettingWidgets.buildDivider(context),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: atomicLocale.theme,
                      value: getThemeName(currentTheme),
                      onTap: () {
                        showThemeSelector(context, themeState, currentTheme);
                      },
                    ),
                    SettingWidgets.buildDivider(context),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: atomicLocale.language,
                      value: getLocaleName(currentLocale),
                      onTap: showLanguageSelector,
                    ),
                    SettingWidgets.buildDivider(context),
                    SettingWidgets.buildSettingRow(
                      context: context,
                      title: atomicLocale.messageReadReceipt,
                      value: AppBuilder.getInstance().messageListConfig.enableReadReceipt,
                      onChanged: (value) async {
                        await AppBuilder.getInstance().messageListConfig.setEnableReadReceipt(value);
                        setState(() {});
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppBuilder.getInstance().messageListConfig.enableReadReceipt
                            ? atomicLocale.messageReadReceiptEnabledDesc
                            : atomicLocale.messageReadReceiptDisabledDesc,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeState.colors.textColorSecondary,
                        ),
                      ),
                    ),
                    SettingWidgets.buildDivider(context),
                    SettingWidgets.buildNavigationRow(
                      context: context,
                      title: atomicLocale.translateTargetLanguage,
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
