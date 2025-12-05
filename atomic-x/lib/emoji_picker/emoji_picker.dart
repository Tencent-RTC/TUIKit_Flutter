import 'package:flutter/material.dart';

import '../base_component/localizations/atomic_localizations.dart';
import '../base_component/theme/color_scheme.dart';
import '../base_component/theme/theme_state.dart';
import 'emoji_picker_config.dart';
import 'emoji_picker_model.dart';

class EmojiPicker extends StatefulWidget {
  Function(Map<String, dynamic> data)? onEmojiClick;
  VoidCallback? onSendClick;
  VoidCallback? onDeleteClick;

  EmojiPicker({
    super.key,
    this.onEmojiClick,
    this.onSendClick,
    this.onDeleteClick,
  });

  @override
  State<StatefulWidget> createState() => EmojiPickerState();
}

typedef OnTabClickCallback = void Function(int currentIndex);

class EmojiPickerState extends State<EmojiPicker> with SingleTickerProviderStateMixin {
  int activeTabIndex = 0;
  late OnTabClickCallback onTabClickCallback;
  late AnimationController _controller;

  void handleTabClick(int index) {
    if (index != activeTabIndex) {
      setState(() {
        activeTabIndex = index;
      });
    } else {
      debugPrint("activeIndex is same. do nothing");
    }
  }

  @override
  void initState() {
    super.initState();

    onTabClickCallback = handleTabClick;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    EmojiPickerConfig.loadData(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> delay300() async {
    await Future.delayed(const Duration(milliseconds: 60));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (EmojiPickerConfig.customStickerLists.isEmpty) {
      return const EmojiPickerError();
    }
    return FutureBuilder(
        future: delay300(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.data == true) {
            return Column(
              children: [
                EmojiPickerTab(
                  onTabClickCallback: onTabClickCallback,
                  activeTabIndex: activeTabIndex,
                ),
                EmojiPickerContent(
                  activeTabIndex: activeTabIndex,
                  onEmojiClick: widget.onEmojiClick,
                  onSendClick: widget.onSendClick,
                  onDeleteClick: widget.onDeleteClick,
                ),
              ],
            );
          }
          return Container();
        });
  }
}

class EmojiPickerError extends StatelessWidget {
  const EmojiPickerError({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Padding(
        padding: EdgeInsets.only(right: 10),
        child: Icon(Icons.error_outline),
      ),
    ]);
  }
}

class EmojiPickerTab extends StatefulWidget {
  final OnTabClickCallback onTabClickCallback;
  final int activeTabIndex;

  const EmojiPickerTab({
    super.key,
    required this.onTabClickCallback,
    required this.activeTabIndex,
  });

  @override
  State<StatefulWidget> createState() => EmojiPickerTabState();
}

class EmojiPickerTabState extends State<EmojiPickerTab> {
  late SemanticColorScheme colorsTheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorsTheme.strokeColorPrimary)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: EmojiPickerConfig.customStickerLists.map(
            (e) {
              int index = EmojiPickerConfig.customStickerLists.indexOf(e);
              bool showActiveStyle = index == widget.activeTabIndex;
              bool isLastIndex = index == EmojiPickerConfig.customStickerLists.length - 1;

              return GestureDetector(
                onTap: () {
                  widget.onTabClickCallback(index);
                },
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: showActiveStyle ? colorsTheme.buttonColorSecondaryActive : colorsTheme.clearColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  margin: EdgeInsets.only(right: isLastIndex ? 0 : 10),
                  child: Align(
                    alignment: Alignment.center,
                    child: Image(
                      image: AssetImage(e.iconPath, package: "tuikit_atomic_x"),
                      width: e.iconSize,
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

class EmojiPickerContent extends StatefulWidget {
  final int activeTabIndex;
  Function(Map<String, dynamic> data)? onEmojiClick;
  VoidCallback? onSendClick;
  VoidCallback? onDeleteClick;

  EmojiPickerContent({
    super.key,
    required this.activeTabIndex,
    this.onEmojiClick,
    this.onSendClick,
    this.onDeleteClick,
  });

  @override
  State<StatefulWidget> createState() => EmojiPickerContentState();
}

class EmojiPickerContentState extends State<EmojiPickerContent> {
  late AtomicLocalizations atomicLocale;
  late SemanticColorScheme colorsTheme;

  sendStickerMessage(int type, String name, int stickerIndex) {
    if (name.startsWith('[') && name.endsWith(']')) {
      var adjustName = name.substring(1, name.length - 1);
      name = adjustName.toLowerCase().startsWith('tuiemoji') ? name : adjustName;
    }

    if (widget.onEmojiClick != null) {
      widget.onEmojiClick!({
        "type": type,
        "name": name,
        "stickerIndex": stickerIndex,
        "eventType": "stickClick",
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  Widget build(BuildContext context) {
    List<EmojiPickerModelItem> currentStickerList = [];
    int crossAxisCount = 7;
    int stickerType = 0;
    int stickerIndex = 0;
    if (EmojiPickerConfig.customStickerLists.elementAtOrNull(widget.activeTabIndex) != null) {
      currentStickerList = EmojiPickerConfig.customStickerLists[widget.activeTabIndex].stickers;
      crossAxisCount = EmojiPickerConfig.customStickerLists[widget.activeTabIndex].rowNum;
      stickerType = EmojiPickerConfig.customStickerLists[widget.activeTabIndex].type;
      stickerIndex = EmojiPickerConfig.customStickerLists[widget.activeTabIndex].index;
    }

    return Expanded(
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                height: 220 - MediaQuery.of(context).padding.bottom,
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Expanded(
                      child: GridView(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1.0,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        children: [
                          ...currentStickerList
                              .map(
                                (e) => GestureDetector(
                                  onTap: () {
                                    sendStickerMessage(
                                      stickerType,
                                      e.name,
                                      stickerIndex,
                                    );
                                  },
                                  child: Image(
                                    image: AssetImage(e.path, package: "tuikit_atomic_x"),
                                  ),
                                ),
                              )
                              .toList(),
                          // Add blank lines to avoid button obstruction
                          ...List.generate(crossAxisCount, (index) => const SizedBox()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildActionButtons(colorsTheme, atomicLocale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(SemanticColorScheme colorsTheme, AtomicLocalizations atomicLocale) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorsTheme.textColorButton.withAlpha(0),
            colorsTheme.textColorButton.withAlpha(200),
            colorsTheme.textColorButton,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.onDeleteClick != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: widget.onDeleteClick,
                child: Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: colorsTheme.buttonColorOff,
                ),
              ),
            ),
          if (widget.onSendClick != null)
            InkWell(
              onTap: widget.onSendClick,
              child: Container(
                width: 60,
                height: 34,
                decoration: BoxDecoration(
                  color: colorsTheme.buttonColorPrimaryDefault,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    atomicLocale.send,
                    style: TextStyle(
                      color: colorsTheme.textColorButton,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
