import 'package:flutter/foundation.dart';
import 'package:atomic_x_core/api/conversation/conversation_group_store.dart';
import 'package:atomic_x_core/api/define.dart';
import 'package:atomic_x_core/api/login/login_store.dart';
import 'package:atomic_x_core/impl/common/data_report.dart';
import 'package:atomic_x_core/impl/login/login_store_impl.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation_operation_result.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_imsdk_bindings_generated.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class _ConversationGroupStateImpl implements ConversationGroupState {
  final ValueNotifier<List<String>> groupListValue = ValueNotifier([]);

  @override
  ValueListenable<List<String>> get groupList => groupListValue;
}

class ConversationGroupStoreImpl extends ConversationGroupStore {
  static final ConversationGroupStoreImpl shared = ConversationGroupStoreImpl._();

  final _conversationGroupState = _ConversationGroupStateImpl();
  V2TimConversationListener? _conversationListener;

  LoginStatus _lastObservedLoginStatus = LoginStatus.unlogin;

  ConversationGroupStoreImpl._() {
    _lastObservedLoginStatus = LoginStoreImpl.instance.loginState.loginStatus;
    _addConversationListener();
    LoginStoreImpl.instance.addListener(_onLoginStateChanged);
  }

  @override
  ConversationGroupState get state => _conversationGroupState;

  void _onLoginStateChanged() {
    final next = LoginStoreImpl.instance.loginState.loginStatus;
    if (next == _lastObservedLoginStatus) return;
    final prev = _lastObservedLoginStatus;
    _lastObservedLoginStatus = next;

    if (next == LoginStatus.logined) {
      _reattachAfterLogin();
    } else if (prev == LoginStatus.logined) {
      _resetAfterLogout();
    }
  }

  void _reattachAfterLogin() {
    _addConversationListener();
  }

  void _resetAfterLogout() {
    _conversationGroupState.groupListValue.value = const [];
  }

  void _addConversationListener() {
    _conversationListener ??= V2TimConversationListener(
      onConversationGroupCreated: (groupName, conversationList) {
        _addGroupIfNeeded(groupName);
      },
      onConversationGroupDeleted: (groupName) {
        final currentList = List<String>.from(_conversationGroupState.groupListValue.value);
        currentList.remove(groupName);
        _conversationGroupState.groupListValue.value = List.unmodifiable(currentList);
      },
      onConversationGroupNameChanged: (oldName, newName) {
        final currentList = List<String>.from(_conversationGroupState.groupListValue.value);
        final index = currentList.indexOf(oldName);
        if (index != -1) {
          currentList[index] = newName;
          _conversationGroupState.groupListValue.value = List.unmodifiable(currentList);
        }
      },
    );

    TencentImSDKPlugin.v2TIMManager.getConversationManager().addConversationListener(listener: _conversationListener!);
  }

  void _addGroupIfNeeded(String groupName) {
    if (groupName.isEmpty) return;
    final currentList = List<String>.from(_conversationGroupState.groupListValue.value);
    if (!currentList.contains(groupName)) {
      currentList.add(groupName);
      _conversationGroupState.groupListValue.value = List.unmodifiable(currentList);
    }
  }

  @override
  Future<CompletionHandler> loadGroups() async {
    DataReport.reportAtomicMetrics(AtomicMetrics.conversationGroup);
    final handler = CompletionHandler();

    try {
      final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().getConversationGroupList();
      if (result.code == TIMErrCode.ERR_SUCC.value && result.data != null) {
        _conversationGroupState.groupListValue.value = List.unmodifiable(List<String>.from(result.data!));
      } else {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    } catch (e) {
      handler.errorCode = -1;
      handler.errorMessage = e.toString();
    }

    return handler;
  }

  @override
  Future<CompletionHandler> createGroup({
    required String groupName,
    required List<String> conversationIDList,
  }) async {
    final handler = CompletionHandler();

    if (groupName.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Group name is empty";
      return handler;
    }

    if (conversationIDList.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Conversation ID list is empty";
      return handler;
    }

    try {
      final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().createConversationGroup(
            groupName: groupName,
            conversationIDList: conversationIDList,
          );

      if (result.code != TIMErrCode.ERR_SUCC.value) {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      } else {
        final failure = _firstConvOpFailure(result.data);
        if (failure != null) {
          handler.errorCode = failure.code;
          handler.errorMessage = failure.info;
        } else {
          _addGroupIfNeeded(groupName);
        }
      }
    } catch (e) {
      handler.errorCode = -1;
      handler.errorMessage = e.toString();
    }

    return handler;
  }

  @override
  Future<CompletionHandler> deleteGroup({required String groupName}) async {
    final handler = CompletionHandler();

    if (groupName.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Group name is empty";
      return handler;
    }

    try {
      final result =
          await TencentImSDKPlugin.v2TIMManager.getConversationManager().deleteConversationGroup(groupName: groupName);

      if (result.code != TIMErrCode.ERR_SUCC.value) {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    } catch (e) {
      handler.errorCode = -1;
      handler.errorMessage = e.toString();
    }

    return handler;
  }

  @override
  Future<CompletionHandler> renameGroup({
    required String oldName,
    required String newName,
  }) async {
    final handler = CompletionHandler();

    if (oldName.isEmpty || newName.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Group name is empty";
      return handler;
    }

    try {
      final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().renameConversationGroup(
            oldName: oldName,
            newName: newName,
          );

      if (result.code != TIMErrCode.ERR_SUCC.value) {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      }
    } catch (e) {
      handler.errorCode = -1;
      handler.errorMessage = e.toString();
    }

    return handler;
  }

  @override
  Future<CompletionHandler> addConversationsToGroup({
    required String groupName,
    required List<String> conversationIDList,
  }) async {
    final handler = CompletionHandler();

    if (groupName.isEmpty || conversationIDList.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Invalid parameters";
      return handler;
    }

    try {
      final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().addConversationsToGroup(
            groupName: groupName,
            conversationIDList: conversationIDList,
          );

      if (result.code != TIMErrCode.ERR_SUCC.value) {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      } else {
        final failure = _firstConvOpFailure(result.data);
        if (failure != null) {
          handler.errorCode = failure.code;
          handler.errorMessage = failure.info;
        }
      }
    } catch (e) {
      handler.errorCode = -1;
      handler.errorMessage = e.toString();
    }

    return handler;
  }

  @override
  Future<CompletionHandler> deleteConversationsFromGroup({
    required String groupName,
    required List<String> conversationIDList,
  }) async {
    final handler = CompletionHandler();

    if (groupName.isEmpty || conversationIDList.isEmpty) {
      handler.errorCode = TIMErrCode.ERR_INVALID_PARAMETERS.value;
      handler.errorMessage = "Invalid parameters";
      return handler;
    }

    try {
      final result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().deleteConversationsFromGroup(
            groupName: groupName,
            conversationIDList: conversationIDList,
          );

      if (result.code != TIMErrCode.ERR_SUCC.value) {
        handler.errorCode = result.code;
        handler.errorMessage = result.desc;
      } else {
        final failure = _firstConvOpFailure(result.data);
        if (failure != null) {
          handler.errorCode = failure.code;
          handler.errorMessage = failure.info;
        }
      }
    } catch (e) {
      handler.errorCode = -1;
      handler.errorMessage = e.toString();
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
}
