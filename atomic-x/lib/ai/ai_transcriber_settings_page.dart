import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'ai_transcriber_manager.dart';

class AITranscriberSettingsPage extends StatefulWidget {
  final VoidCallback? onClose;
  final List<SourceLanguage>? sourceLanguages;
  final List<TranslationLanguage>? translationLanguages;

  const AITranscriberSettingsPage({
    super.key,
    this.onClose,
    this.sourceLanguages,
    this.translationLanguages,
  });

  @override
  State<AITranscriberSettingsPage> createState() => _AITranscriberSettingsPageState();
}

class _AITranscriberSettingsPageState extends State<AITranscriberSettingsPage> with TickerProviderStateMixin {
  late AITranscriberSettings _settings;
  late List<SourceLanguage> _sourceLanguages;
  late List<TranslationLanguage> _translationLanguages;
  OverlayEntry? _pickerOverlay;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _settings = aiTranscriberConfigManager.currentSettings.value;
    _sourceLanguages = widget.sourceLanguages ?? SourceLanguage.values;
    _translationLanguages = widget.translationLanguages ?? const [
      TranslationLanguage.chinese,
      TranslationLanguage.english,
      TranslationLanguage.vietnamese,
      TranslationLanguage.japanese,
      TranslationLanguage.korean,
      TranslationLanguage.indonesian,
      TranslationLanguage.thai,
      TranslationLanguage.portuguese,
      TranslationLanguage.arabic,
      TranslationLanguage.spanish,
      TranslationLanguage.french,
      TranslationLanguage.malay,
      TranslationLanguage.german,
      TranslationLanguage.italian,
      TranslationLanguage.russian,
    ];
  }

  @override
  void dispose() {
    _hidePickerOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _hidePickerOverlay() {
    _pickerOverlay?.remove();
    _pickerOverlay = null;
  }

  Future<void> _showPickerOverlay(Widget picker) async {
    if (_pickerOverlay != null) return;
    
    final locale = Localizations.localeOf(context);
    _pickerOverlay = OverlayEntry(
      builder: (overlayContext) => Localizations(
        locale: locale,
        delegates: AtomicLocalizations.localizationsDelegates,
        child: ComponentTheme(
          child: SlideTransition(
            position: _slideAnimation,
            child: picker,
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_pickerOverlay!);
    _animationController.forward();
  }

  Future<void> _closePickerOverlay() async {
    await _animationController.reverse();
    _hidePickerOverlay();
  }

  void _updateSettings(AITranscriberSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);
    final locale = AtomicLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.bgColorOperate,
      appBar: _buildAppBar(context, colors, locale),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSectionHeader(context, colors, locale),
            _buildSettingsGroup(context, colors, locale),
          ],
        ),
      ),
    );
  }

  void _handleClose() {
    aiTranscriberConfigManager.updateSettings(_settings);
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, SemanticColorScheme colors, AtomicLocalizations locale) {
    return AppBar(
      backgroundColor: colors.bgColorOperate,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: _handleClose,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.arrow_back_ios,
            color: colors.textColorPrimary,
            size: 20,
          ),
        ),
      ),
      title: Text(
        locale.aiSubtitleSettings,
        style: TextStyle(
          color: colors.textColorPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSectionHeader(BuildContext context, SemanticColorScheme colors, AtomicLocalizations locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        locale.aiSubtitleRecognitionAndTranslation,
        style: TextStyle(
          fontSize: 13,
          color: colors.textColorSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, SemanticColorScheme colors, AtomicLocalizations locale) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgColorTopBar,
      ),
      child: Column(
        children: [
          _buildNavigationRow(
            context: context,
            colors: colors,
            title: locale.aiSubtitleRecognitionLanguage,
            value: LanguageDisplayConfig.getSourceLanguageDisplayName(context, _settings.sourceLanguage),
            onTap: () => _showSourceLanguagePicker(context, colors, locale),
          ),
          _buildDivider(colors),
          _buildNavigationRow(
            context: context,
            colors: colors,
            title: locale.aiSubtitleTranslationLanguage,
            value: LanguageDisplayConfig.getTranslationLanguageDisplayName(context, _settings.translationLanguage),
            onTap: () => _showTranslationLanguagePicker(context, colors, locale),
          ),
          _buildDivider(colors),
          _buildSwitchRow(
            context: context,
            colors: colors,
            title: locale.aiSubtitleShowBilingual,
            value: _settings.showBilingual,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(showBilingual: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required BuildContext context,
    required SemanticColorScheme colors,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colors.textColorPrimary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textColorSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: colors.textColorSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required SemanticColorScheme colors,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colors.textColorPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              return colors.textColorButton;
            }),
            trackColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return colors.switchColorOn;
              }
              return colors.switchColorOff;
            }),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
              return colors.clearColor;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(SemanticColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: 0.5,
      color: colors.strokeColorPrimary,
    );
  }

  void _showSourceLanguagePicker(BuildContext context, SemanticColorScheme colors, AtomicLocalizations locale) {
    _showPickerOverlay(
      _LanguagePickerPage<SourceLanguage>(
        title: locale.aiSubtitleSelectRecognitionLanguage,
        options: _sourceLanguages,
        selectedValue: _settings.sourceLanguage,
        displayNameBuilder: (lang) => LanguageDisplayConfig.getSourceLanguageDisplayName(context, lang),
        onBack: _closePickerOverlay,
        onSelected: (language) async {
          await _closePickerOverlay();
          _updateSettings(_settings.copyWith(sourceLanguage: language));
        },
      ),
    );
  }

  void _showTranslationLanguagePicker(BuildContext context, SemanticColorScheme colors, AtomicLocalizations locale) {
    _showPickerOverlay(
      _LanguagePickerPage<TranslationLanguage?>(
        title: locale.aiSubtitleSelectTranslationLanguage,
        options: [null, ..._translationLanguages],
        selectedValue: _settings.translationLanguage,
        displayNameBuilder: (lang) => LanguageDisplayConfig.getTranslationLanguageDisplayName(context, lang),
        onBack: _closePickerOverlay,
        onSelected: (language) async {
          await _closePickerOverlay();
          if (language == null) {
            _updateSettings(_settings.copyWith(clearTranslationLanguage: true));
          } else {
            _updateSettings(_settings.copyWith(translationLanguage: language));
          }
        },
      ),
    );
  }
}

class _LanguagePickerPage<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T selectedValue;
  final String Function(T) displayNameBuilder;
  final VoidCallback onBack;
  final ValueChanged<T> onSelected;

  const _LanguagePickerPage({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.displayNameBuilder,
    required this.onBack,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BaseThemeProvider.colorsOf(context);

    return Material(
      child: Scaffold(
        backgroundColor: colors.bgColorOperate,
        appBar: AppBar(
          backgroundColor: colors.bgColorOperate,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.arrow_back_ios,
                color: colors.textColorPrimary,
                size: 20,
              ),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: colors.textColorPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: options.length,
          separatorBuilder: (context, index) => Container(
            height: 0.5,
            color: colors.strokeColorPrimary,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = option == selectedValue;
            return GestureDetector(
              onTap: () => onSelected(option),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  displayNameBuilder(option),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: isSelected 
                        ? colors.buttonColorPrimaryDefault 
                        : colors.textColorPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
