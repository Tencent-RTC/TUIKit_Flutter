import 'dart:async';

import 'package:atomic_x_core/api/group/group_store.dart';
import 'package:atomic_x_core/api/conversation/conversation_list_store.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/impl/group/group_store_impl.dart';
import 'package:atomic_x_core/impl/common/chat_util.dart';
import 'package:atomic_x_core/impl/common/data_report.dart';
import 'package:atomic_x_core/impl/common/notification_center.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation_filter.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class ConversationNotificationNames {
  static const String clearChatHistoryMessage = 'clear_chat_history_message';
  static const String conversationMute = 'conversation_mute';
}

class MessageListClearEventData {
  final String conversationID;

  MessageListClearEventData({required this.conversationID});
}

class ConversationMuteEventData {
  final String conversationID;
  final ReceiveMessageOption receiveMessageOption;

  ConversationMuteEventData({required this.conversationID, required this.receiveMessageOption});
}

class _ConversationStateImpl implements ConversationListState {
  final ValueNotifier<List<ConversationInfo>> conversationListValue = ValueNotifier([]);
  final ValueNotifier<bool> hasMoreConversationsValue = ValueNotifier(true);
  final ValueNotifier<int> totalUnreadCountValue = ValueNotifier(0);

  @override
  ValueListenable<List<ConversationInfo>> get conversationList => conversationListValue;

  @override
  ValueListenable<bool> get hasMoreConversations => hasMoreConversationsValue;

  @override
  ValueListenable<int> get totalUnreadCount => totalUnreadCountValue;
}

class _ListenerHandle {
  V2TimConversationListener? conversationListener;
  V2TimFriendshipListener? friendshipListener;
  StreamSubscription<void>? cacheUpdateListener;
  Timer? calculateTimer;
  ConversationListFilter? subscribedFilter;

  void addConversationListener(V2TimConversationListener listener) {
    conversationListener = listener;
    TencentImSDKPlugin.v2TIMManager.getConversationManager().addConversationListener(listener: listener);
  }

  void removeConversationListener() {
    if (conversationListener != null) {
      TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .removeConversationListener(listener: conversationListener!);
      conversationListener = null;
    }
  }

  void addFriendshipListener(V2TimFriendshipListener listener) {
    friendshipListener = listener;
    TencentImSDKPlugin.v2TIMManager.getFriendshipManager().addFriendListener(listener: listener);
  }

  void removeFriendshipListener() {
    if (friendshipListener != null) {
      TencentImSDKPlugin.v2TIMManager.getFriendshipManager().removeFriendListener(listener: friendshipListener!);
      friendshipListener = null;
    }
  }

  void cancelCacheUpdateListener() {
    cacheUpdateListener?.cancel();
    cacheUpdateListener = null;
  }

  void cancelCalculateTimer() {
    calculateTimer?.cancel();
    calculateTimer = null;
  }

  void unsubscribeFilter() {
    if (subscribedFilter != null) {
      final v2Filter = ConversationConverter.convertToV2TIMFilter(subscribedFilter);
      TencentImSDKPlugin.v2TIMManager.getConversationManager().unsubscribeUnreadMessageCountByFilter(filter: v2Filter);
      subscribedFilter = null;
    }
  }
}

class ConversationListStoreImpl extends ConversationListStore {
  static final Finalizer<_ListenerHandle> _finalizer = Finalizer((handle) {
    handle.removeConversationListener();
    handle.removeFriendshipListener();
    handle.cancelCacheUpdateListener();
    handle.cancelCalculateTimer();
    handle.unsubscribeFilter();
  });

  final _listenerHandle = _ListenerHandle();
  final _conversationState = _ConversationStateImpl();

  List<ConversationInfo> _conversationList = [];
  int _sdkTotalUnreadCount = 0;

  String? _conversationGroup;
  ConversationLoadOption? _option;
  int _nextSeq = 0;
  V2TimConversationListener? _conversationListener;
  V2TimFriendshipListener? _friendshipListener;
  ConversationListFilter? _currentSubscribedFilter;

  bool _isCalculationScheduled = false;
  Timer? _calculateTimer;
  StreamSubscription<void>? _cacheUpdateListener;

  ConversationListStoreImpl({String? conversationGroup}) {
    _conversationGroup = conversationGroup;
    _addConversationListenerInternal();
    _addFriendshipListenerInternal();
    _observeMarkedConversationCacheUpdate();
    _initTotalUnreadCount();
    _finalizer.attach(this, _listenerHandle, detach: this);
  }

  @override
  ConversationListState get state => _conversationState;

  void _observeMarkedConversationCacheUpdate() {
    _cacheUpdateListener = notificationCenter.addListener<void>(
      MarkedConversationRepository.cacheUpdateNotification,
      (_) {
        _cancelScheduledCalculation();
        _calculateTotalUnreadCount();
      },
    );
    _listenerHandle.cacheUpdateListener = _cacheUpdateListener;
  }

  void _cancelScheduledCalculation() {
    _calculateTimer?.cancel();
    _calculateTimer = null;
    _isCalculationScheduled = false;
  }

  void _initTotalUnreadCount() async {
    await MarkedConversationRepository.shared.ensureInitialized();

    if (_conversationGroup != null) {
      final filter = ConversationListFilter(conversationGroup: _conversationGroup);
      await _getFilteredUnreadCount(filter);
    } else {
      await _getAllUnreadCount();
    }
  }

  @override
  Future<CompletionHandler> loadConversations({ConversationLoadOption? option}) async {
    DataReport.reportAtomicMetrics(AtomicMetrics.conversationList);

    final handler = CompletionHandler();
    _option = option;

    final filter = _buildV2Filter(option);
    final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().getConversationListByFilter(
          filter: filter,
          nextSeq: 0,
          count: option?.count ?? 100,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      final convList = ConversationConverter.convertToSortedConversationList(result.data!.conversationList ?? []);
      _conversationList = convList;
      _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
      _conversationState.hasMoreConversationsValue.value = !(result.data!.isFinished ?? true);
      _nextSeq = int.parse(result.data!.nextSeq ?? '0');
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> loadMoreConversations() async {
    final handler = CompletionHandler();

    if (!_conversationState.hasMoreConversationsValue.value) {
      handler.errorCode = TIMErrCode.ERR_NO_SUCC_RESULT.value;
      handler.errorMessage = "No more conversation";
      return handler;
    }

    if (_option == null) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Please call loadConversations first";
      return handler;
    }

    final filter = _buildV2Filter(_option!);
    final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().getConversationListByFilter(
          filter: filter,
          nextSeq: _nextSeq,
          count: _option!.count,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      final newConvList = ConversationConverter.convertToSortedConversationList(result.data!.conversationList ?? []);

      for (var conversation in newConvList) {
        final existingIndex =
            _conversationList.indexWhere((element) => element.conversationID == conversation.conversationID);
        if (existingIndex == -1) {
          _conversationList.add(conversation);
        } else {
          _conversationList[existingIndex] = conversation;
        }
      }

      _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
      _conversationState.hasMoreConversationsValue.value = !(result.data!.isFinished ?? true);
      _nextSeq = int.parse(result.data!.nextSeq ?? '0');
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> pinConversation({required String conversationID, required bool pin}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().pinConversation(
          conversationID: conversationID,
          isPinned: pin,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      final index = _conversationList.indexWhere((element) => element.conversationID == conversationID);
      if (index != -1) {
        _conversationList[index].isPinned = pin;
        _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
      }
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> setReceiveMessageOpt(
      {required String conversationID, required ReceiveMessageOption opt}) async {
    final handler = CompletionHandler();

    bool isC2C = conversationID.contains(c2cConversationIDPrefix);
    bool isGroup = conversationID.contains(groupConversationIDPrefix);
    if (!isC2C && !isGroup) {
      handler.errorCode = -1;
      handler.errorMessage = 'conversationID is invalid';
      return handler;
    }

    final recvOpt = ChatUtil.convertToV2TIMReceiveMessageOpt(opt);

    if (isGroup) {
      String groupID = ChatUtil.getGroupID(conversationID);
      final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().setGroupReceiveMessageOpt(
            groupID: groupID,
            opt: recvOpt,
          );

      if (result.code == TIMErrCode.ERR_SUCC.value) {
        notificationCenter.post(ConversationNotificationNames.conversationMute,
            ConversationMuteEventData(conversationID: conversationID, receiveMessageOption: opt));
      } else {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    } else {
      String userID = ChatUtil.getUserID(conversationID);
      final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().setC2CReceiveMessageOpt(
        userIDList: [userID],
        opt: recvOpt,
      );

      if (result.code == TIMErrCode.ERR_SUCC.value) {
        notificationCenter.post(ConversationNotificationNames.conversationMute,
            ConversationMuteEventData(conversationID: conversationID, receiveMessageOption: opt));
      } else {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    }

    return handler;
  }

  @override
  Future<CompletionHandler> deleteConversation({required String conversationID}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().deleteConversation(
          conversationID: conversationID,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      _conversationList.removeWhere((element) => element.conversationID == conversationID);
      _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> setConversationDraft({required String conversationID, String? draft}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().setConversationDraft(
          conversationID: conversationID,
          draftText: draft ?? '',
        );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      final index = _conversationList.indexWhere((element) => element.conversationID == conversationID);
      if (index != -1) {
        _conversationList[index].draft = draft;
        _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
      }
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<GetConversationInfoCompletionHandler> getConversationInfo({required String conversationID}) async {
    final handler = GetConversationInfoCompletionHandler();
    final result =
        await TencentImSDKPlugin.v2TIMManager.getConversationManager().getConversation(conversationID: conversationID);

    if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
      handler.conversationInfo = ConversationConverter.convertToConversation(result.data!);
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }
    return handler;
  }

  @override
  Future<CompletionHandler> clearConversationMessages({required String conversationID}) async {
    final handler = CompletionHandler();
    final userID = ChatUtil.getUserID(conversationID);
    final groupID = ChatUtil.getGroupID(conversationID);

    if (userID.isEmpty && groupID.isEmpty) {
      handler.errorCode = -1;
      handler.errorMessage = "Invalid conversationID";
      return handler;
    }

    if (userID.isNotEmpty) {
      final result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().clearC2CHistoryMessage(userID: userID);
      if (result.code == TIMErrCode.ERR_SUCC.value) {
        notificationCenter.post(ConversationNotificationNames.clearChatHistoryMessage,
            MessageListClearEventData(conversationID: conversationID));
      } else {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    } else if (groupID.isNotEmpty) {
      final result =
          await TencentImSDKPlugin.v2TIMManager.getMessageManager().clearGroupHistoryMessage(groupID: groupID);
      if (result.code == TIMErrCode.ERR_SUCC.value) {
        notificationCenter.post(ConversationNotificationNames.clearChatHistoryMessage,
            MessageListClearEventData(conversationID: conversationID));
      } else {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    }

    return handler;
  }

  @override
  Future<CompletionHandler> clearConversationUnreadCount({required String conversationID}) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().cleanConversationUnreadMessageCount(
          conversationID: conversationID,
          cleanTimestamp: 0,
          cleanSequence: 0,
        );

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      final index = _conversationList.indexWhere((element) => element.conversationID == conversationID);
      if (index != -1) {
        _conversationList[index].unreadCount = 0;
        _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
      }
    } else {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
    }

    return handler;
  }

  @override
  Future<CompletionHandler> markConversation({
    required List<String> conversationIDList,
    required ConversationMarkType markType,
    required bool enable,
  }) async {
    final handler = CompletionHandler();
    final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().markConversation(
          conversationIDList: conversationIDList,
          markType: markType.rawValue,
          enableMark: enable,
        );

    if (result.code != TIMErrCode.ERR_SUCC.value) {
      handler.errorCode = result.code;
      handler.errorMessage = result.desc;
      return handler;
    }

    final failure = _firstConvOpFailure(result.data);
    if (failure != null) {
      handler.errorCode = failure.code;
      handler.errorMessage = failure.info;
    }

    return handler;
  }

  ({int code, String info})? _firstConvOpFailure(List<V2TimConversationOperationResult>? list) {
    if (list == null) return null;
    for (final r in list) {
      final code = r.resultCode ?? TIMErrCode.ERR_SUCC.value;
      if (code != TIMErrCode.ERR_SUCC.value) {
        return (code: code, info: r.resultInfo ?? 'Unknown error');
      }
    }
    return null;
  }

  // ======== Internal helpers ========

  V2TimConversationFilter _buildV2Filter(ConversationLoadOption? option) {
    final v2Filter = V2TimConversationFilter();
    if (_conversationGroup != null) {
      if (_conversationGroup == ConversationGroup.c2c.value) {
        v2Filter.conversationType = ConversationType.c2c.index;
      } else if (_conversationGroup == ConversationGroup.group.value) {
        v2Filter.conversationType = ConversationType.group.index;
      } else if (_conversationGroup == ConversationGroup.hasUnreadCount.value) {
        v2Filter.hasUnreadCount = true;
      } else if (_conversationGroup == ConversationGroup.hasGroupAtInfo.value) {
        v2Filter.hasGroupAtInfo = true;
      } else {
        v2Filter.conversationGroup = _conversationGroup;
      }
    }
    if (option?.markType != null) {
      v2Filter.markType = option!.markType!.rawValue;
    }
    return v2Filter;
  }

  // ======== Unread count ========

  Future<void> _getFilteredUnreadCount(ConversationListFilter filter) async {
    final v2Filter = ConversationConverter.convertToV2TIMFilter(filter);

    if (_currentSubscribedFilter != null) {
      _unsubscribeUnreadMessageCountByFilter(_currentSubscribedFilter!);
    }

    final result =
        await TencentImSDKPlugin.v2TIMManager.getConversationManager().getUnreadMessageCountByFilter(filter: v2Filter);

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      _sdkTotalUnreadCount = result.data ?? 0;
      _calculateTotalUnreadCount();
      _subscribeUnreadMessageCountByFilter(filter);
    }
  }

  Future<void> _getAllUnreadCount() async {
    if (_currentSubscribedFilter != null) {
      _unsubscribeUnreadMessageCountByFilter(_currentSubscribedFilter!);
    }

    V2TimValueCallback<int> result =
        await TencentImSDKPlugin.v2TIMManager.getConversationManager().getTotalUnreadMessageCount();

    if (result.code == TIMErrCode.ERR_SUCC.value) {
      _sdkTotalUnreadCount = result.data ?? 0;
      _calculateTotalUnreadCount();
    }
  }

  void _subscribeUnreadMessageCountByFilter(ConversationListFilter filter) {
    final v2Filter = ConversationConverter.convertToV2TIMFilter(filter);
    _currentSubscribedFilter = filter;
    _listenerHandle.subscribedFilter = filter;
    TencentImSDKPlugin.v2TIMManager.getConversationManager().subscribeUnreadMessageCountByFilter(filter: v2Filter);
  }

  void _unsubscribeUnreadMessageCountByFilter(ConversationListFilter filter) {
    final v2Filter = ConversationConverter.convertToV2TIMFilter(filter);
    TencentImSDKPlugin.v2TIMManager.getConversationManager().unsubscribeUnreadMessageCountByFilter(filter: v2Filter);
    _currentSubscribedFilter = null;
    _listenerHandle.subscribedFilter = null;
  }

  void _scheduleTotalUnreadCountCalculation() {
    if (_isCalculationScheduled) return;
    _isCalculationScheduled = true;

    _calculateTimer?.cancel();
    _calculateTimer = Timer(const Duration(milliseconds: 100), () {
      _isCalculationScheduled = false;
      _calculateTotalUnreadCount();
    });
  }

  void _calculateTotalUnreadCount() {
    if (!MarkedConversationRepository.shared.isCacheInitialized) {
      return;
    }

    ConversationListFilter? currentFilter;
    if (_conversationGroup != null) {
      currentFilter = ConversationListFilter(conversationGroup: _conversationGroup);
    }

    final finalUnread = MarkedConversationRepository.shared.calculateUnreadCount(
      sdkTotalUnreadCount: _sdkTotalUnreadCount,
      filter: currentFilter,
    );

    _conversationState.totalUnreadCountValue.value = finalUnread;
  }

  // ======== Listeners ========

  void _addConversationListenerInternal() {
    _conversationListener = V2TimConversationListener(
      onConversationChanged: (conversationList) {
        final conversationInfoList = conversationList.map((conv) => ConversationConverter.convertToConversation(conv)).toList();
        _updateConversations(conversationInfoList);
      },
      onNewConversation: (conversationList) {
        final conversationInfoList = conversationList.map((conv) => ConversationConverter.convertToConversation(conv)).toList();
        _updateConversations(conversationInfoList);
      },
      onConversationDeleted: (conversationIDList) {
        final conversationIDSet = conversationIDList.toSet();
        _conversationList.removeWhere((conversation) => conversationIDSet.contains(conversation.conversationID));
        _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
      },
      onTotalUnreadMessageCountChanged: (totalCount) {
        if (_currentSubscribedFilter != null) return;
        _sdkTotalUnreadCount = totalCount;
        _scheduleTotalUnreadCountCalculation();
      },
      onUnreadMessageCountChangedByFilter: (filter, totalUnreadCount) {
        if (_currentSubscribedFilter == null) return;

        if (_convertToUIConversationType(filter.conversationType ?? 0) != _currentSubscribedFilter!.type ||
            filter.conversationGroup != _currentSubscribedFilter!.conversationGroup ||
            filter.markType != (_currentSubscribedFilter!.markType?.rawValue ?? 0) ||
            filter.hasUnreadCount != (_currentSubscribedFilter!.hasUnreadCount ?? false) ||
            filter.hasGroupAtInfo != (_currentSubscribedFilter!.hasGroupAtInfo ?? false)) {
          return;
        }

        _sdkTotalUnreadCount = totalUnreadCount;
        _scheduleTotalUnreadCountCalculation();
      },
    );

    _listenerHandle.addConversationListener(_conversationListener!);
  }

  void _updateConversations(List<ConversationInfo> conversationInfoList) {
    var conversationListUpdated = List<ConversationInfo>.from(_conversationList);

    final conversationIndexMap = <String, int>{};
    for (int i = 0; i < conversationListUpdated.length; i++) {
      conversationIndexMap[conversationListUpdated[i].conversationID] = i;
    }

    for (var conversationInfo in conversationInfoList) {
      final existingIndex = conversationIndexMap[conversationInfo.conversationID];
      if (existingIndex != null) {
        conversationListUpdated[existingIndex] = conversationInfo;
      } else {
        conversationListUpdated.add(conversationInfo);
      }
    }

    conversationListUpdated.sort((a, b) => (b.rawConversation?.orderkey ?? 0).compareTo(a.rawConversation?.orderkey ?? 0));
    _conversationList = conversationListUpdated;
    _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
  }

  static ConversationType _convertToUIConversationType(int v2Type) {
    switch (v2Type) {
      case 1:
        return ConversationType.c2c;
      case 2:
        return ConversationType.group;
      default:
        return ConversationType.unknown;
    }
  }

  void _addFriendshipListenerInternal() {
    _friendshipListener = V2TimFriendshipListener(
      onFriendInfoChanged: _onFriendInfoChanged,
    );
    _listenerHandle.addFriendshipListener(_friendshipListener!);
  }

  void _onFriendInfoChanged(List<V2TimFriendInfo> infoList) {
    bool hasChanges = false;

    final conversationMap = <String, ConversationInfo>{};
    for (final conversation in _conversationList) {
      final userID = ChatUtil.getUserID(conversation.conversationID);
      conversationMap[userID] = conversation;
    }

    for (var friendInfo in infoList) {
      String userID = friendInfo.userID;
      String nickname = friendInfo.userProfile?.nickName ?? '';
      String friendRemark = friendInfo.friendRemark ?? '';
      String showName = friendRemark.isNotEmpty ? friendRemark : (nickname.isNotEmpty ? nickname : userID);
      final conversation = conversationMap[userID];
      if (conversation != null) {
        if (conversation.title != showName) {
          conversation.title = showName;
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      _conversationState.conversationListValue.value = List.unmodifiable(_conversationList);
    }
  }
}

// ======== ConversationListFilter (internal, used by unread count logic) ========

class ConversationListFilter {
  ConversationType type;
  String? conversationGroup;
  ConversationMarkType? markType;
  bool? hasUnreadCount;
  bool? hasGroupAtInfo;

  ConversationListFilter({
    this.type = ConversationType.unknown,
    this.conversationGroup,
    this.markType,
    this.hasUnreadCount,
    this.hasGroupAtInfo,
  });
}

// ======== MarkedConversationRepository ========

class MarkedConversationRepository {
  static final MarkedConversationRepository shared = MarkedConversationRepository._();
  static const String cacheUpdateNotification = 'marked_conversation_cache_updated';

  final Map<String, ConversationInfo> _hiddenConversationsCache = {};
  final Map<String, ConversationInfo> _foldedConversationsCache = {};
  final Map<String, ConversationInfo> _unreadMarkedConversationsCache = {};

  final Set<String> _pendingUnhideConversations = {};
  final Set<String> _pendingUnmarkUnreadConversations = {};
  final Map<String, ConversationInfo> _pendingUpdates = {};

  bool isCacheInitialized = false;
  bool _isInitialized = false;
  V2TimConversationListener? _conversationListener;

  MarkedConversationRepository._();

  Future<void> ensureInitialized() async {
    if (isCacheInitialized) return;
    if (_isInitialized) return;
    _isInitialized = true;

    _addConversationListener();
    await _fetchAllMarkedConversations();
    _processPendingUpdates();
    isCacheInitialized = true;

    notificationCenter.post<void>(cacheUpdateNotification, null);
  }

  void _addConversationListener() {
    _conversationListener = V2TimConversationListener(
      onNewConversation: (conversationList) {
        final list = conversationList.map((c) => ConversationConverter.convertToConversation(c)).toList();
        _update(list);
      },
      onConversationChanged: (conversationList) {
        final list = conversationList.map((c) => ConversationConverter.convertToConversation(c)).toList();
        _update(list);
      },
      onConversationDeleted: (conversationIDList) {
        _remove(conversationIDList);
      },
    );

    TencentImSDKPlugin.v2TIMManager.getConversationManager().addConversationListener(listener: _conversationListener!);
  }

  void _processPendingUpdates() {
    if (_pendingUpdates.isEmpty) return;
    final updates = _pendingUpdates.values.toList();
    _processUpdatesInternal(updates);
    _pendingUpdates.clear();
  }

  int calculateUnreadCount({required int sdkTotalUnreadCount, ConversationListFilter? filter}) {
    if (!isCacheInitialized) return sdkTotalUnreadCount;

    int hiddenUnreadCount = _hiddenConversationsCache.values
        .where((c) => _matchesFilter(c, filter) && !_isMuted(c))
        .fold(0, (sum, c) => sum + _getSdkUnreadCount(c));

    int foldedUnreadCount = _foldedConversationsCache.values
        .where((c) => _matchesFilter(c, filter) && !_isMuted(c))
        .fold(0, (sum, c) => sum + _getSdkUnreadCount(c));

    int manualBadgeCount = _unreadMarkedConversationsCache.values.where((conv) {
      return _matchesFilter(conv, filter) &&
          !_isMuted(conv) &&
          !_hiddenConversationsCache.containsKey(conv.conversationID) &&
          !_foldedConversationsCache.containsKey(conv.conversationID) &&
          _getSdkUnreadCount(conv) == 0;
    }).length;

    int result = sdkTotalUnreadCount + manualBadgeCount - hiddenUnreadCount - foldedUnreadCount;
    return result < 0 ? 0 : result;
  }

  bool _matchesFilter(ConversationInfo conversation, ConversationListFilter? filter) {
    if (filter == null) return true;
    if (filter.type != ConversationType.unknown && conversation.type != filter.type) return false;
    if (filter.conversationGroup != null) {
      if (!conversation.conversationGroupList.contains(filter.conversationGroup)) return false;
    }
    return true;
  }

  bool _isMuted(ConversationInfo conversation) {
    return conversation.receiveOption == ReceiveMessageOption.notNotify ||
        conversation.receiveOption == ReceiveMessageOption.notNotifyExceptMention;
  }

  int _getSdkUnreadCount(ConversationInfo conversation) {
    return conversation.rawConversation?.unreadCount ?? 0;
  }

  void _update(List<ConversationInfo> conversationList) {
    if (!isCacheInitialized) {
      for (var conv in conversationList) {
        _pendingUpdates[conv.conversationID] = conv;
      }
      return;
    }
    _processUpdatesInternal(conversationList);
  }

  void _processUpdatesInternal(List<ConversationInfo> conversationList) {
    bool hasChange = false;
    List<String> conversationsToUnhide = [];
    List<String> conversationsToUnmarkUnread = [];

    for (var conversation in conversationList) {
      final conversationID = conversation.conversationID;

      if (conversation.conversationMarkList.contains(ConversationMarkType.hide)) {
        final cachedConversation = _hiddenConversationsCache[conversationID];
        final currentUnreadCount = cachedConversation != null ? _getSdkUnreadCount(cachedConversation) : 0;
        final sdkUnreadCount = _getSdkUnreadCount(conversation);

        if (sdkUnreadCount > currentUnreadCount) {
          if (!_pendingUnhideConversations.contains(conversationID)) {
            conversationsToUnhide.add(conversationID);
          }
        }

        if (_hiddenConversationsCache[conversationID] != conversation) {
          _hiddenConversationsCache[conversationID] = conversation;
          hasChange = true;
        }
      } else {
        if (_hiddenConversationsCache.remove(conversationID) != null) {
          hasChange = true;
          _pendingUnhideConversations.remove(conversationID);
        }
      }

      if (conversation.conversationMarkList.contains(ConversationMarkType.fold)) {
        if (_foldedConversationsCache[conversationID] != conversation) {
          _foldedConversationsCache[conversationID] = conversation;
          hasChange = true;
        }
      } else {
        if (_foldedConversationsCache.remove(conversationID) != null) {
          hasChange = true;
        }
      }

      final sdkUnreadCount = _getSdkUnreadCount(conversation);
      if (conversation.conversationMarkList.contains(ConversationMarkType.unread)) {
        if (sdkUnreadCount > 0) {
          if (!_pendingUnmarkUnreadConversations.contains(conversationID)) {
            conversationsToUnmarkUnread.add(conversationID);
          }
        }

        if (_unreadMarkedConversationsCache[conversationID] != conversation) {
          _unreadMarkedConversationsCache[conversationID] = conversation;
          hasChange = true;
        }
      } else {
        if (_unreadMarkedConversationsCache.remove(conversationID) != null) {
          hasChange = true;
          _pendingUnmarkUnreadConversations.remove(conversationID);
        }
      }
    }

    _executeBatchMarkOperations(
      conversationsToUnhide: conversationsToUnhide,
      conversationsToUnmarkUnread: conversationsToUnmarkUnread,
    );

    if (hasChange) {
      notificationCenter.post<void>(cacheUpdateNotification, null);
    }
  }

  void _executeBatchMarkOperations({
    required List<String> conversationsToUnhide,
    required List<String> conversationsToUnmarkUnread,
  }) {
    if (conversationsToUnhide.isNotEmpty) {
      _pendingUnhideConversations.addAll(conversationsToUnhide);
      TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .markConversation(
            conversationIDList: conversationsToUnhide,
            markType: ConversationMarkType.hide.rawValue,
            enableMark: false,
          )
          .then((_) {
        for (var id in conversationsToUnhide) {
          _pendingUnhideConversations.remove(id);
        }
      }).catchError((_) {
        for (var id in conversationsToUnhide) {
          _pendingUnhideConversations.remove(id);
        }
      });
    }

    if (conversationsToUnmarkUnread.isNotEmpty) {
      _pendingUnmarkUnreadConversations.addAll(conversationsToUnmarkUnread);
      TencentImSDKPlugin.v2TIMManager
          .getConversationManager()
          .markConversation(
            conversationIDList: conversationsToUnmarkUnread,
            markType: ConversationMarkType.unread.rawValue,
            enableMark: false,
          )
          .then((_) {
        for (var id in conversationsToUnmarkUnread) {
          _pendingUnmarkUnreadConversations.remove(id);
        }
      }).catchError((_) {
        for (var id in conversationsToUnmarkUnread) {
          _pendingUnmarkUnreadConversations.remove(id);
        }
      });
    }
  }

  void _remove(List<String> conversationIDList) {
    if (!isCacheInitialized) {
      for (var id in conversationIDList) {
        _pendingUpdates.remove(id);
      }
      return;
    }

    bool hasChange = false;
    for (var conversationID in conversationIDList) {
      if (_hiddenConversationsCache.remove(conversationID) != null) hasChange = true;
      if (_foldedConversationsCache.remove(conversationID) != null) hasChange = true;
      if (_unreadMarkedConversationsCache.remove(conversationID) != null) hasChange = true;
      _pendingUnhideConversations.remove(conversationID);
      _pendingUnmarkUnreadConversations.remove(conversationID);
    }

    if (hasChange) {
      notificationCenter.post<void>(cacheUpdateNotification, null);
    }
  }

  Future<void> _fetchAllMarkedConversations() async {
    final results = await Future.wait([
      _fetchAllConversationsByMarkType(ConversationMarkType.hide),
      _fetchAllConversationsByMarkType(ConversationMarkType.fold),
      _fetchAllConversationsByMarkType(ConversationMarkType.unread),
    ]);

    _hiddenConversationsCache.clear();
    for (var conv in results[0]) {
      _hiddenConversationsCache[conv.conversationID] = conv;
    }

    _foldedConversationsCache.clear();
    for (var conv in results[1]) {
      _foldedConversationsCache[conv.conversationID] = conv;
    }

    _unreadMarkedConversationsCache.clear();
    for (var conv in results[2]) {
      _unreadMarkedConversationsCache[conv.conversationID] = conv;
    }
  }

  Future<List<ConversationInfo>> _fetchAllConversationsByMarkType(ConversationMarkType markType) async {
    List<ConversationInfo> accumulator = [];

    Future<void> fetchPage(int nextSeq) async {
      final filter = V2TimConversationFilter();
      filter.markType = markType.rawValue;

      final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().getConversationListByFilter(
            filter: filter,
            nextSeq: nextSeq,
            count: 100,
          );

      if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
        final list = result.data!.conversationList ?? [];
        accumulator.addAll(list.map((c) => ConversationConverter.convertToConversation(c)));

        if (!(result.data!.isFinished ?? true)) {
          final nextSeqValue = int.tryParse(result.data!.nextSeq ?? '0') ?? 0;
          await fetchPage(nextSeqValue);
        }
      }
    }

    await fetchPage(0);
    return accumulator;
  }
}

// ======== ConversationConverter ========

class ConversationConverter {
  static ConversationInfo convertToConversation(V2TimConversation imConversation) {
    GroupType? groupType;
    if (imConversation.groupType != null && imConversation.groupType!.isNotEmpty) {
      groupType = GroupStoreImpl.groupTypeFromV2TIMString(imConversation.groupType!);
    }

    List<GroupAtInfo>? groupAtInfoList;
    if (imConversation.groupAtInfoList != null && imConversation.groupAtInfoList!.isNotEmpty) {
      groupAtInfoList =
          imConversation.groupAtInfoList!.where((v2GroupAtInfo) => v2GroupAtInfo != null).map((v2GroupAtInfo) {
        int msgSeq = int.tryParse(v2GroupAtInfo!.seq) ?? 0;
        return GroupAtInfo(
          msgSeq: msgSeq,
          atType: _convertToGroupAtType(v2GroupAtInfo.atType),
        );
      }).toList();
    }

    List<ConversationMarkType> conversationMarkList = [];
    if (imConversation.markList != null && imConversation.markList!.isNotEmpty) {
      conversationMarkList = _convertToMarkTypeList(imConversation.markList!);
    }

    int unreadCount = imConversation.unreadCount ?? 0;
    if (conversationMarkList.any((mark) => mark == ConversationMarkType.unread) && unreadCount == 0) {
      unreadCount = 1;
    }

    return ConversationInfo(
      conversationID: imConversation.conversationID,
      type: _convertToUIConversationType(imConversation.type!),
      avatarURL: imConversation.faceUrl,
      title: imConversation.showName,
      lastMessage: imConversation.lastMessage != null ? ChatUtil.convertToUIMessage(imConversation.lastMessage!) : null,
      draft: imConversation.draftText,
      unreadCount: unreadCount,
      isPinned: imConversation.isPinned ?? false,
      receiveOption: _convertToReceiveMessageOption(imConversation.recvOpt ?? 0),
      groupType: groupType,
      groupAtInfoList: groupAtInfoList,
      conversationMarkList: conversationMarkList,
      conversationGroupList: (imConversation.conversationGroupList ?? []).whereType<String>().toList(),
      rawConversation: imConversation,
    );
  }

  static List<ConversationInfo> convertToSortedConversationList(List<V2TimConversation> v2List) {
    return v2List.map((conv) => convertToConversation(conv)).toList()
      ..sort((a, b) => (b.rawConversation?.orderkey ?? 0).compareTo(a.rawConversation?.orderkey ?? 0));
  }

  static V2TimConversationFilter convertToV2TIMFilter(ConversationListFilter? filter) {
    final v2Filter = V2TimConversationFilter();
    if (filter == null) return v2Filter;

    if (filter.type != ConversationType.unknown) {
      v2Filter.conversationType = _convertToV2TIMConversationType(filter.type);
    }
    if (filter.conversationGroup != null) {
      v2Filter.conversationGroup = filter.conversationGroup;
    }
    if (filter.markType != null) {
      v2Filter.markType = filter.markType!.rawValue;
    }
    if (filter.hasUnreadCount != null) {
      v2Filter.hasUnreadCount = filter.hasUnreadCount;
    }
    if (filter.hasGroupAtInfo != null) {
      v2Filter.hasGroupAtInfo = filter.hasGroupAtInfo;
    }
    return v2Filter;
  }

  static int _convertToV2TIMConversationType(ConversationType type) {
    switch (type) {
      case ConversationType.c2c:
        return 1;
      case ConversationType.group:
        return 2;
      default:
        return 0;
    }
  }

  static ConversationType _convertToUIConversationType(int v2Type) {
    switch (v2Type) {
      case 1:
        return ConversationType.c2c;
      case 2:
        return ConversationType.group;
      default:
        return ConversationType.unknown;
    }
  }

  static ReceiveMessageOption _convertToReceiveMessageOption(int v2Opt) {
    switch (v2Opt) {
      case 0:
        return ReceiveMessageOption.receive;
      case 1:
        return ReceiveMessageOption.notReceive;
      case 2:
        return ReceiveMessageOption.notNotify;
      case 3:
        return ReceiveMessageOption.notNotifyExceptMention;
      case 4:
        return ReceiveMessageOption.notReceiveExceptMention;
      default:
        return ReceiveMessageOption.receive;
    }
  }

  static GroupAtType _convertToGroupAtType(int? v2AtType) {
    if (v2AtType == null) return GroupAtType.atMe;
    switch (v2AtType) {
      case 1:
        return GroupAtType.atMe;
      case 2:
        return GroupAtType.atAll;
      case 3:
        return GroupAtType.atAllAtMe;
      default:
        return GroupAtType.atMe;
    }
  }

  static List<ConversationMarkType> _convertToMarkTypeList(List<dynamic> v2MarkList) {
    List<ConversationMarkType> markList = [];
    for (var markValue in v2MarkList) {
      if (markValue is int) {
        final markType = ConversationMarkType(markValue);
        if (!markType.isEmpty) {
          markList.add(markType);
        }
      }
    }
    return markList;
  }
}
