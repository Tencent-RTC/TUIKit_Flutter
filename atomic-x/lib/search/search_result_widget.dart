import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/material.dart';
import 'package:tuikit_atomic_x/base_component/base_component.dart';
import 'package:tuikit_atomic_x/message_list/utils/message_utils.dart';
import 'package:tuikit_atomic_x/search/utils/text_highlighter.dart';

import 'search_bar.dart';
import 'search_message_in_conversation_page.dart';
import 'search_result_more_page.dart';

class SearchResultWidget extends StatelessWidget {
  final SearchStore searchStore;
  final String keyword;
  final OnContactSelect? onContactSelect;
  final OnGroupSelect? onGroupSelect;
  final OnConversationSelect? onConversationSelect;
  final OnMessageSelect? onMessageSelect;

  const SearchResultWidget({
    super.key,
    required this.searchStore,
    required this.keyword,
    this.onContactSelect,
    this.onGroupSelect,
    this.onConversationSelect,
    this.onMessageSelect,
  });

  @override
  Widget build(BuildContext context) {
    final atomicLocale = AtomicLocalizations.of(context);
    final searchState = searchStore.searchState;

    return ListView(
      children: [
        if (searchState.friendList.isNotEmpty)
          _buildFriendSection(
            context: context,
            title: atomicLocale.contact,
            friends: searchState.friendList,
            atomicLocale: atomicLocale,
          ),
        if (searchState.groupList.isNotEmpty)
          _buildGroupSection(
            context: context,
            title: atomicLocale.groups,
            groups: searchState.groupList,
            atomicLocale: atomicLocale,
          ),
        if (searchState.messageResults.isNotEmpty)
          _buildMessageSection(
            context: context,
            title: atomicLocale.chatHistory,
            messageResults: searchState.messageResults,
            atomicLocale: atomicLocale,
          ),
      ],
    );
  }

  Widget _buildFriendSection({
    required BuildContext context,
    required String title,
    required List<FriendSearchInfo> friends,
    required AtomicLocalizations atomicLocale,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final bool showMoreButton = friends.length > 3;
    final int itemCount = friends.length > 3 ? 3 : friends.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorsTheme.textColorPrimary),
              ),
              if (showMoreButton)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchResultMorePage(
                          searchType: SearchType.friend,
                          keyword: keyword,
                          onContactSelect: onContactSelect,
                          onGroupSelect: onGroupSelect,
                          onConversationSelect: onConversationSelect,
                          onMessageSelect: onMessageSelect,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    atomicLocale.more,
                    style: TextStyle(color: colorsTheme.buttonColorPrimaryDefault),
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return _buildFriendItem(context, friends[index], colorsTheme);
          },
        ),
      ],
    );
  }

  Widget _buildGroupSection({
    required BuildContext context,
    required String title,
    required List<GroupSearchInfo> groups,
    required AtomicLocalizations atomicLocale,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final bool showMoreButton = groups.length > 3;
    final int itemCount = groups.length > 3 ? 3 : groups.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorsTheme.textColorPrimary),
              ),
              if (showMoreButton)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchResultMorePage(
                          searchType: SearchType.group,
                          keyword: keyword,
                          onContactSelect: onContactSelect,
                          onGroupSelect: onGroupSelect,
                          onConversationSelect: onConversationSelect,
                          onMessageSelect: onMessageSelect,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    atomicLocale.more,
                    style: TextStyle(color: colorsTheme.buttonColorPrimaryDefault),
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return _buildGroupItem(context, groups[index], colorsTheme);
          },
        ),
      ],
    );
  }

  Widget _buildMessageSection({
    required BuildContext context,
    required String title,
    required List<MessageSearchResultItem> messageResults,
    required AtomicLocalizations atomicLocale,
  }) {
    final colorsTheme = BaseThemeProvider.colorsOf(context);
    final bool showMoreButton = messageResults.length > 3;
    final int itemCount = messageResults.length > 3 ? 3 : messageResults.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorsTheme.textColorPrimary),
              ),
              if (showMoreButton)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchResultMorePage(
                          searchType: SearchType.message,
                          keyword: keyword,
                          onContactSelect: onContactSelect,
                          onGroupSelect: onGroupSelect,
                          onConversationSelect: onConversationSelect,
                          onMessageSelect: onMessageSelect,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    atomicLocale.more,
                    style: TextStyle(color: colorsTheme.buttonColorPrimaryDefault),
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return _buildMessageResultItem(context, messageResults[index], colorsTheme, atomicLocale);
          },
        ),
      ],
    );
  }

  Widget _buildFriendItem(BuildContext context, FriendSearchInfo friend, SemanticColorScheme colorsTheme) {
    const double avatarSize = 40.0;
    const double leadingPadding = 16.0;
    const double titleLeftPadding = 16.0;

    final titleStyle = TextStyle(color: colorsTheme.textColorPrimary);
    final subtitleStyle = TextStyle(color: colorsTheme.textColorSecondary);

    final displayName = friend.friendRemark?.isNotEmpty == true
        ? friend.friendRemark!
        : (friend.userInfo?.nickname?.isNotEmpty == true ? friend.userInfo!.nickname! : friend.userID);
    final avatar = friend.userInfo?.avatarURL ?? '';

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: leadingPadding),
          leading: Avatar.image(
            name: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            url: avatar,
            size: AvatarSize.m,
          ),
          title: TextHighlighter.buildHighlightedText(displayName, keyword, titleStyle, colorsTheme.textColorLink),
          subtitle: TextHighlighter.buildHighlightedText(
              'ID:${friend.userID}', keyword, subtitleStyle, colorsTheme.textColorLink),
          onTap: () {
            if (onContactSelect != null) {
              onContactSelect!(friend);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: avatarSize + leadingPadding + titleLeftPadding),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupItem(BuildContext context, GroupSearchInfo group, SemanticColorScheme colorsTheme) {
    const double avatarSize = 40.0;
    const double leadingPadding = 16.0;
    const double titleLeftPadding = 16.0;

    final titleStyle = TextStyle(color: colorsTheme.textColorPrimary);
    final subtitleStyle = TextStyle(color: colorsTheme.textColorSecondary);

    final displayName = group.groupName.isNotEmpty ? group.groupName : group.groupID;
    final avatar = group.groupAvatarURL;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: leadingPadding),
          leading: Avatar.image(
            name: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            url: avatar,
            size: AvatarSize.m,
          ),
          title: TextHighlighter.buildHighlightedText(displayName, keyword, titleStyle, colorsTheme.textColorLink),
          subtitle: TextHighlighter.buildHighlightedText(
              'groupID: ${group.groupID}', keyword, subtitleStyle, colorsTheme.textColorLink),
          onTap: () {
            if (onGroupSelect != null) {
              onGroupSelect!(group);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: avatarSize + leadingPadding + titleLeftPadding),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageResultItem(BuildContext context, MessageSearchResultItem messageResult,
      SemanticColorScheme colorsTheme, AtomicLocalizations atomicLocale) {
    const double avatarSize = 40.0;
    const double leadingPadding = 16.0;
    const double titleLeftPadding = 16.0;

    final titleStyle = TextStyle(color: colorsTheme.textColorPrimary);
    final subtitleStyle = TextStyle(color: colorsTheme.textColorSecondary);

    final displayName = messageResult.conversationShowName;
    final avatar = messageResult.conversationAvatarURL;

    String subtitle;
    if (messageResult.messageCount > 1) {
      subtitle = atomicLocale.chatRecords(messageResult.messageCount);
    } else if (messageResult.messageList.isNotEmpty) {
      subtitle = MessageUtil.getMessageAbstract(messageResult.messageList.first, context);
    } else {
      subtitle = '';
    }

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: leadingPadding),
          leading: Avatar.image(
            name: displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            url: avatar,
            size: AvatarSize.m,
          ),
          title: TextHighlighter.buildHighlightedText(displayName, keyword, titleStyle, colorsTheme.textColorLink),
          subtitle: subtitle.isNotEmpty
              ? TextHighlighter.buildHighlightedText(subtitle, keyword, subtitleStyle, colorsTheme.textColorLink)
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchMessageInConversationPage(
                  conversationID: messageResult.conversationID,
                  conversationName: messageResult.conversationShowName,
                  conversationAvatar: messageResult.conversationAvatarURL,
                  keyword: keyword,
                  onConversationSelect: onConversationSelect,
                  onMessageSelect: onMessageSelect,
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: avatarSize + leadingPadding + titleLeftPadding),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ],
    );
  }
}
