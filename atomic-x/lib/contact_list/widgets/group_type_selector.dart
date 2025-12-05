import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:url_launcher/url_launcher.dart';

String getGroupTypeName(BuildContext context, String type) {
  AtomicLocalizations atomicLocale = AtomicLocalizations.of(context);
  if (type == GroupType.work.value) {
    return atomicLocale.groupWork;
  } else if (type == GroupType.publicGroup.value) {
    return atomicLocale.groupPublic;
  } else if (type == GroupType.meeting.value) {
    return atomicLocale.groupMeeting;
  } else if (type == GroupType.community.value) {
    return atomicLocale.groupCommunity;
  } else {
    return atomicLocale.groupWork;
  }
}

class GroupTypeSelector extends StatefulWidget {
  static const String imProductDocURL = "https://www.tencentcloud.com/document/product/1047/33515";

  final String selectedGroupType;

  const GroupTypeSelector({
    super.key,
    required this.selectedGroupType,
  });

  @override
  State<GroupTypeSelector> createState() => _GroupTypeSelectorState();
}

class _GroupTypeSelectorState extends State<GroupTypeSelector> {
  late String _selectedGroupType;
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  final List<String> _groupTypes = [
    GroupType.work.value,
    GroupType.publicGroup.value,
    GroupType.meeting.value,
    GroupType.community.value,
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
    atomicLocale = AtomicLocalizations.of(context);
  }

  String _getGroupTypeFullName(String type) {
    if (type == GroupType.work.value) {
      return atomicLocale.groupWorkType;
    } else if (type == GroupType.publicGroup.value) {
      return atomicLocale.groupPublicType;
    } else if (type == GroupType.meeting.value) {
      return atomicLocale.groupMeetingType;
    } else if (type == GroupType.community.value) {
      return atomicLocale.groupCommunityType;
    } else {
      return atomicLocale.groupWorkType;
    }
  }

  String _getGroupTypeDescription(String type) {
    if (type == GroupType.work.value) {
      return atomicLocale.groupWorkDesc;
    } else if (type == GroupType.publicGroup.value) {
      return atomicLocale.groupPublicDesc;
    } else if (type == GroupType.meeting.value) {
      return atomicLocale.groupMeetingDesc;
    } else if (type == GroupType.community.value) {
      return atomicLocale.groupCommunityDesc;
    } else {
      return atomicLocale.groupWorkDesc;
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
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          atomicLocale.groupType,
          style: TextStyle(
            color: colorsTheme.textColorPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedGroupType),
            child: Text(
              atomicLocale.confirm,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
                                    style: TextStyle(
                                      color: colorsTheme.textColorPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                _getGroupTypeDescription(type),
                                style: TextStyle(
                                  fontSize: 12,
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
                atomicLocale.productDocumentation,
                style: TextStyle(
                  color: colorsTheme.textColorLink,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
