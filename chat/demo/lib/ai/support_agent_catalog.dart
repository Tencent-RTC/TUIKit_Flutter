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
///
/// The AI home's picker switches between the built-in assistants (the public
/// directory) and the user's own bot (see [customBotUserID]); the choice is kept
/// in [selectedBotUserID] and [fetch] only returns that one assistant. Bots
/// created in the trial workspace are not in the public directory; they are
/// verified with `POST /api/support/v1/agents/check` and used directly.
class SupportAgentCatalog {
  SupportAgentCatalog._();

  // Placeholder: replace with your own business server domain.
  static const String _placeholderHost = 'your-business-server.example.com';
  static const String _agentsUrl =
      'https://$_placeholderHost/api/support/v1/agents';
  static const String _handoffStatusPath = '/api/im/handoff-status';
  static const String _agentCheckPath = '/api/support/v1/agents/check';
  static const String _loginUserIDKey = 'devLoginUserID';
  static const String _loginUserSigKey = 'devUserSig';
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _readTimeout = Duration(seconds: 15);
  static const String _customBotKey = 'aiCustomBotUserID';
  static const String _selectedBotKey = 'aiSelectedBotUserID';
  static const String botUserIDPrefix = '@RBT#';

  static http.Client? _client;

  static List<AIAssistantAgent> _directory = const [];
  static List<AIAssistantAgent> _agents = const [];
  static AIAssistantAgent? _customAgent;
  static String _customBotUserID = '';
  static String _selectedBotUserID = '';
  static bool _loaded = false;
  static bool _directoryLoaded = false;

  /// The latest [fetch] result, holding only the selected assistant.
  static List<AIAssistantAgent> get agents => _agents;

  /// The server's built-in assistants, listed by the picker.
  static List<AIAssistantAgent> get directory => _directory;

  /// Display info of the custom bot from its last successful check.
  static AIAssistantAgent? get customAgent => _customAgent;

  /// The bot UserID the user typed in, empty when never configured.
  static String get customBotUserID => _customBotUserID;

  /// The picker's choice; empty or offline falls back to the first built-in.
  static String get selectedBotUserID => _selectedBotUserID;

  static bool get isCustomSelected =>
      _customBotUserID.isNotEmpty && _customBotUserID == _selectedBotUserID;

  /// The directory is fetched for the logged-in SDKAppID. When the app logs in
  /// to the customer's own IM app (e.g. source downloaded from GitHub) the
  /// directory is empty; with no custom assistant selected there is nothing to
  /// talk to, so the customer must first create their own assistant following
  /// the official docs.
  static bool get needsOwnAssistant =>
      _directoryLoaded && _directory.isEmpty && !isCustomSelected;

  static bool get _isPlaceholderHost => _agentsUrl.contains(_placeholderHost);

  static void _warnPlaceholderHost() => debugPrint(
      'SupportAgentCatalog: replace the _agentsUrl placeholder with your business server domain');

  /// The logged-in SDKAppID, or null before login.
  static int? _loginSdkAppID() {
    final sdkAppID = LoginStore.shared.sdkAppID;
    return sdkAppID > 0 ? sdkAppID : null;
  }

  /// Adds the logged-in SDKAppID so the server can tell the platform demo app
  /// from the customer's own app.
  static Map<String, Object> _withSdkAppID(Map<String, Object> body) {
    final sdkAppID = _loginSdkAppID();
    return sdkAppID == null ? body : {...body, 'sdkappid': sdkAppID};
  }

  /// Loads the stored choices; the getters above are valid afterwards.
  static Future<void> load() async {
    if (_loaded) return;
    final preferences = await SharedPreferences.getInstance();
    _customBotUserID = (preferences.getString(_customBotKey) ?? '').trim();
    _selectedBotUserID = (preferences.getString(_selectedBotKey) ?? '').trim();
    _loaded = true;
  }

  static Future<void> setCustomBotUserID(String userID) async {
    final value = userID.trim();
    if (value != _customBotUserID) _customAgent = null;
    _customBotUserID = value;
    await _store(_customBotKey, value);
  }

  static Future<void> setSelectedBotUserID(String userID) async {
    _selectedBotUserID = userID.trim();
    await _store(_selectedBotKey, _selectedBotUserID);
  }

  static Future<void> _store(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await preferences.remove(key);
    } else {
      await preferences.setString(key, value);
    }
  }

  static AIAssistantAgent? _selectedBuiltIn() {
    if (_directory.isEmpty) return null;
    return _directory.firstWhere(
        (agent) => agent.imUserId == _selectedBotUserID,
        orElse: () => _directory.first);
  }

  static String? displayNameForConversation(String conversationID) {
    for (final agent in [
      ..._directory,
      if (_customAgent != null) _customAgent!,
      ..._agents
    ]) {
      if (agent.conversationID == conversationID) return agent.displayName;
    }
    return null;
  }

  /// Resolves with the latest snapshot. A non-2xx response or a network error
  /// keeps the previous snapshot.
  static Future<List<AIAssistantAgent>> fetch() async {
    await load();
    final directory = await _requestDirectory();
    if (directory != null) {
      _directoryLoaded = true;
      _directory = directory;
    }
    final customID = _customBotUserID;
    if (!isCustomSelected || _directory.any((a) => a.imUserId == customID)) {
      final selected = isCustomSelected
          ? _directory.firstWhere((a) => a.imUserId == customID)
          : _selectedBuiltIn();
      _agents = selected == null ? const [] : [selected];
      return _agents;
    }
    // Trial-workspace bots are not in the public directory, so check them
    // separately and show the nickname and welcome from the reply.
    final info = await _requestBotInfo(customID);
    if (info == null) {
      // Keep the user's choice when the check itself fails.
      _agents = [_customAgent ?? _buildCustomAgent(customID, null)];
    } else if (info.exists) {
      _customAgent = _buildCustomAgent(customID, info);
      _agents = [_customAgent!];
    } else {
      // The server says the bot is gone: fall back to a built-in assistant.
      await setSelectedBotUserID('');
      final selected = _selectedBuiltIn();
      _agents = selected == null ? const [] : [selected];
    }
    return _agents;
  }

  /// Checks that [userID] is an enabled, connected bot on the server,
  /// including bots created in the trial workspace.
  static Future<CustomBotCheckResult> checkBot(String userID) async {
    final info = await _requestBotInfo(userID.trim());
    if (info == null) return CustomBotCheckResult.networkError;
    return info.exists
        ? CustomBotCheckResult.found
        : CustomBotCheckResult.notFound;
  }

  /// The public directory has no info for this bot, so build the agent from the
  /// nickname and welcome returned by the check call. An older server without
  /// those fields falls back to showing the ID.
  static AIAssistantAgent _buildCustomAgent(String userID, _BotInfo? info) =>
      AIAssistantAgent(
        id: userID,
        name: '',
        welcome: info?.welcome ?? '',
        imUserId: userID,
        imNickname: info?.nickname ?? '',
      );

  /// Current login user's ID and UserSig, empty when unavailable.
  static Future<(String, String)> _loginCredentials() async {
    final preferences = await SharedPreferences.getInstance();
    final loggedInUserID =
        (LoginStore.shared.loginState.loginUserInfo?.userID ?? '').trim();
    final userID = loggedInUserID.isNotEmpty
        ? loggedInUserID
        : (preferences.getString(_loginUserIDKey) ?? '').trim();
    final userSig = (preferences.getString(_loginUserSigKey) ?? '').trim();
    return (userID, userSig);
  }

  /// Calls `POST /api/support/v1/agents/check`. Returns the server's verdict with
  /// the bot's nickname and welcome, or null on missing credentials, network or
  /// auth failure.
  static Future<_BotInfo?> _requestBotInfo(String userID) async {
    if (_isPlaceholderHost) {
      _warnPlaceholderHost();
      return null;
    }
    try {
      final uri = Uri.tryParse(_agentsUrl)?.resolve(_agentCheckPath);
      final (loginUserID, userSig) = await _loginCredentials();
      if (uri == null || loginUserID.isEmpty || userSig.isEmpty) {
        debugPrint(
            'SupportAgentCatalog: check bot skipped: missing url/userID/userSig');
        return null;
      }
      final response = await _httpClient()
          .post(
            uri,
            headers: const {
              'Cache-Control': 'no-store',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(_withSdkAppID({
              'user_id': loginUserID,
              'usersig': userSig,
              'im_user_id': userID,
            })),
          )
          .timeout(_connectTimeout + _readTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final root = jsonDecode(utf8.decode(response.bodyBytes));
        if (root is Map && root['exists'] is bool) {
          return _BotInfo(
            exists: root['exists'] as bool,
            nickname: _string(root['im_nickname']),
            welcome: _string(root['welcome']),
          );
        }
        return null;
      }
      debugPrint('SupportAgentCatalog: check bot http ${response.statusCode}');
    } catch (e) {
      debugPrint('SupportAgentCatalog: check bot failed: $e');
    }
    return null;
  }

  /// Fetches the assistants of the logged-in SDKAppID. Returns null when the
  /// request failed, so callers can keep their snapshot.
  static Future<List<AIAssistantAgent>?> _requestDirectory() async {
    if (_isPlaceholderHost) {
      _warnPlaceholderHost();
      return const [];
    }
    try {
      final sdkAppID = _loginSdkAppID();
      final base = Uri.parse(_agentsUrl);
      final uri = sdkAppID == null
          ? base
          : base.replace(queryParameters: {'sdkappid': '$sdkAppID'});
      final response = await _httpClient().get(uri, headers: const {
        'Cache-Control': 'no-store'
      }).timeout(_connectTimeout + _readTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parse(utf8.decode(response.bodyBytes));
      }
      debugPrint(
          'SupportAgentCatalog: fetch agents http ${response.statusCode}');
    } catch (e) {
      debugPrint('SupportAgentCatalog: fetch agents failed: $e');
    }
    return null;
  }

  static Future<AIAssistantHandoffStatus> fetchHandoffStatus() async {
    if (_isPlaceholderHost) {
      _warnPlaceholderHost();
      return AIAssistantHandoffStatus.inactive;
    }
    try {
      final uri = Uri.tryParse(_agentsUrl)?.resolve(_handoffStatusPath);
      final (userID, userSig) = await _loginCredentials();
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
            body: jsonEncode(_withSdkAppID({
              'user_id': userID,
              'usersig': userSig,
              if (_agents.isNotEmpty) 'im_user_id': _agents.first.imUserId,
            })),
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

enum CustomBotCheckResult { found, notFound, networkError }

/// Reply of `POST /api/support/v1/agents/check`. Only [exists] is set when the
/// bot was not found.
class _BotInfo {
  const _BotInfo({required this.exists, this.nickname = '', this.welcome = ''});

  final bool exists;
  final String nickname;
  final String welcome;
}
