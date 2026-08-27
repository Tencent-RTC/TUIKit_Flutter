import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:url_launcher/url_launcher.dart';
import '../../common/language/gen/chat_localizations.dart';

String getGroupTypeName(BuildContext context, GroupType type) {
  ChatLocalizations chatLocale = ChatLocalizations.of(context);
  switch (type) {
    case GroupType.work:
      return chatLocale.groupWork;
    case GroupType.publicGroup:
      return chatLocale.groupPublic;
    case GroupType.meeting:
      return chatLocale.groupMeeting;
    case GroupType.community:
      return chatLocale.groupCommunity;
    case GroupType.avChatRoom:
      return chatLocale.groupWork;
  }
}

class GroupTypeSelector extends StatefulWidget {
  static const String imProductDocURL = "https://www.tencentcloud.com/document/product/1047/33515";

  final GroupType selectedGroupType;

  const GroupTypeSelector({
    super.key,
    required this.selectedGroupType,
  });

  @override
  State<GroupTypeSelector> createState() => _GroupTypeSelectorState();
}

class _GroupTypeSelectorState extends State<GroupTypeSelector> {
  late GroupType _selectedGroupType;
  late SemanticColorScheme colorsTheme;
  late ChatLocalizations chatLocale;

  final List<GroupType> _groupTypes = [
    GroupType.work,
    GroupType.publicGroup,
    GroupType.meeting,
    GroupType.community,
  ];

  @override
  void initState() {
    super.initState();
    _selectedGroupType = widget.selectedGroupType;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    colorsTheme = BaseThemeProvider.colorsOf(context);
    chatLocale = ChatLocalizations.of(context);
  }

  String _getGroupTypeFullName(GroupType type) {
    switch (type) {
      case GroupType.work:
        return chatLocale.groupWorkType;
      case GroupType.publicGroup:
        return chatLocale.groupPublicType;
      case GroupType.meeting:
        return chatLocale.groupMeetingType;
      case GroupType.community:
        return chatLocale.groupCommunityType;
      case GroupType.avChatRoom:
        return chatLocale.groupWorkType;
    }
  }

  String _getGroupTypeDescription(GroupType type) {
    switch (type) {
      case GroupType.work:
        return chatLocale.groupWorkDesc;
      case GroupType.publicGroup:
        return chatLocale.groupPublicDesc;
      case GroupType.meeting:
        return chatLocale.groupMeetingDesc;
      case GroupType.community:
        return chatLocale.groupCommunityDesc;
      case GroupType.avChatRoom:
        return chatLocale.groupWorkDesc;
    }
  }

  void _launchProductDocUrl() async {
    final uri = Uri.parse(GroupTypeSelector.imProductDocURL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('cannot open url: ${GroupTypeSelector.imProductDocURL}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.listColorDefault,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorTopBar,
        elevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.textColorSecondary)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          chatLocale.groupType,
          style: FontScheme.caption1Medium.copyWith(
            color: colorsTheme.textColorPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedGroupType),
            child: Text(
              chatLocale.confirm,
              style: FontScheme.caption1Medium.copyWith(
                color: colorsTheme.buttonColorPrimaryDefault,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _groupTypes.length,
              itemBuilder: (context, index) {
                final type = _groupTypes[index];
                final isSelected = _selectedGroupType == type;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGroupType = type;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: colorsTheme.listColorDefault,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: isSelected ? colorsTheme.textColorLink : colorsTheme.strokeColorPrimary,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: colorsTheme.textColorLink,
                                      size: 20,
                                    ),
                                  if (isSelected) const SizedBox(width: 8.0),
                                  Text(
                                    _getGroupTypeFullName(type),
                                    style: FontScheme.caption1Medium.copyWith(
                                      color: colorsTheme.textColorPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                _getGroupTypeDescription(type),
                                style: FontScheme.caption3Regular.copyWith(
                                  color: colorsTheme.textColorTertiary,
                                ),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: _launchProductDocUrl,
              child: Text(
                chatLocale.productDocumentation,
                style: FontScheme.caption2Regular.copyWith(
                  color: colorsTheme.textColorLink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
