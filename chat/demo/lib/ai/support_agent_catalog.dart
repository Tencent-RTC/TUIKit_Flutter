import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tencent_chat_uikit/tencent_chat_uikit.dart';

/// Fetches the customer-server public agent directory.
///
/// `GET /api/support/v1/agents` needs no auth. The directory must be fetched
/// again every time the entry opens rather than caching disabled agents;
/// [agents] is only the snapshot for the current display and title fallback.
class SupportAgentCatalog {
  SupportAgentCatalog._();

  // Placeholder: replace with your own business server domain.
  static const String _placeholderHost = 'your-business-server.example.com';
  static const String _agentsUrl =
      'https://$_placeholderHost/api/support/v1/agents';
  static const String _handoffStatusPath = '/api/im/handoff-status';
  static const String _loginUserIDKey = 'devLoginUserID';
  static const String _loginUserSigKey = 'devUserSig';
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _readTimeout = Duration(seconds: 15);

  static http.Client? _client;

  static List<AIAssistantAgent> _agents = const [];

  static List<AIAssistantAgent> get agents => _agents;

  static String? displayNameForConversation(String conversationID) {
    for (final agent in _agents) {
      if (agent.conversationID == conversationID) return agent.displayName;
    }
    return null;
  }

  /// Resolves with the latest snapshot. A non-2xx response or a network error
  /// keeps the previous snapshot.
  static Future<List<AIAssistantAgent>> fetch() async {
    if (_agentsUrl.contains(_placeholderHost)) {
      debugPrint(
          'SupportAgentCatalog: replace the _agentsUrl placeholder with your business server domain');
      return const [];
    }
    try {
      final response = await _httpClient().get(Uri.parse(_agentsUrl),
          headers: const {
            'Cache-Control': 'no-store'
          }).timeout(_connectTimeout + _readTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _agents = _parse(utf8.decode(response.bodyBytes));
      } else {
        debugPrint(
            'SupportAgentCatalog: fetch agents http ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('SupportAgentCatalog: fetch agents failed: $e');
    }
    return _agents;
  }

  static Future<AIAssistantHandoffStatus> fetchHandoffStatus() async {
    if (_agentsUrl.contains(_placeholderHost)) {
      debugPrint(
          'SupportAgentCatalog: replace the _agentsUrl placeholder with your business server domain');
      return AIAssistantHandoffStatus.inactive;
    }
    try {
      final uri = Uri.tryParse(_agentsUrl)?.resolve(_handoffStatusPath);
      final preferences = await SharedPreferences.getInstance();
      final loggedInUserID =
          (LoginStore.shared.loginState.loginUserInfo?.userID ?? '').trim();
      final userID = loggedInUserID.isNotEmpty
          ? loggedInUserID
          : (preferences.getString(_loginUserIDKey) ?? '').trim();
      final userSig = (preferences.getString(_loginUserSigKey) ?? '').trim();
      if (uri == null || userID.isEmpty || userSig.isEmpty) {
        debugPrint(
            'SupportAgentCatalog: fetch handoff status skipped: missing url/userID/userSig');
        return AIAssistantHandoffStatus.inactive;
      }

      final response = await _httpClient()
          .post(
            uri,
            headers: const {
              'Cache-Control': 'no-store',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({
              'user_id': userID,
              'usersig': userSig,
            }),
          )
          .timeout(_connectTimeout + _readTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parseHandoffStatus(utf8.decode(response.bodyBytes));
      }
      debugPrint(
          'SupportAgentCatalog: fetch handoff status http ${response.statusCode}');
    } catch (e) {
      debugPrint('SupportAgentCatalog: fetch handoff status failed: $e');
    }
    return AIAssistantHandoffStatus.inactive;
  }

  static http.Client _httpClient() {
    return _client ??= kIsWeb
        ? http.Client()
        : IOClient(HttpClient()..connectionTimeout = _connectTimeout);
  }

  static List<AIAssistantAgent> _parse(String body) {
    Object? root;
    try {
      root = jsonDecode(body);
    } catch (_) {
      return const [];
    }
    if (root is! Map) return const [];
    final array = root['agents'];
    if (array is! List) return const [];
    final result = <AIAssistantAgent>[];
    for (final item in array) {
      if (item is! Map) continue;
      final imUserId = _string(item['im_user_id']);
      if (imUserId.isEmpty) continue;
      result.add(AIAssistantAgent(
        id: _string(item['id']),
        name: _string(item['name']),
        welcome: _string(item['welcome']),
        imUserId: imUserId,
        imNickname: _string(item['im_nickname']),
      ));
    }
    return result;
  }

  @visibleForTesting
  static AIAssistantHandoffStatus parseHandoffStatus(String body) {
    Object? root;
    try {
      root = jsonDecode(body);
    } catch (_) {
      return AIAssistantHandoffStatus.inactive;
    }
    if (root is! Map) return AIAssistantHandoffStatus.inactive;
    return AIAssistantHandoffStatus(
      callable: root['callable'] == true,
      state: _string(root['state']),
      seatImUserId: _string(root['seat_im_user_id']),
    );
  }

  static String _string(Object? value) =>
      value == null ? '' : value.toString().trim();
}
