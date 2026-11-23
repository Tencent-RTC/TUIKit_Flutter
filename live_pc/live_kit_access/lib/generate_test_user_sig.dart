library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// 仅用于本地联调的测试 UserSig 生成器。
///
/// 正式环境请改为由业务服务端签发 UserSig，避免将密钥放在客户端。
class GenerateTestUserSig {
  GenerateTestUserSig._();

  /// 可通过 `--dart-define=LIVEKIT_SDKAPPID=xxx` 覆盖。
  static const int sdkAppId = int.fromEnvironment(
    'LIVEKIT_SDKAPPID',
    defaultValue: 0,
  );

  static const int _expireTime = 604800;

  /// 可通过 `--dart-define=LIVEKIT_SECRETKEY=xxx` 覆盖。
  static const String _secretKey = String.fromEnvironment(
    'LIVEKIT_SECRETKEY',
    defaultValue: '',
  );

  /// 服务端若已下发 UserSig，可通过 `--dart-define=LIVEKIT_USERSIG=xxx` 覆盖。
  static const String _presetUserSig = String.fromEnvironment('LIVEKIT_USERSIG');

  static String genTestUserSig(String userId) {
    if (_presetUserSig.isNotEmpty) {
      return _presetUserSig;
    }
    if (sdkAppId <= 0 || _secretKey.isEmpty || userId.isEmpty) {
      return '';
    }

    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String signature = _hmacSHA256(
      userId: userId,
      currentTime: currentTime,
    );
    if (signature.isEmpty) {
      return '';
    }

    final SplayTreeMap<String, Object> document = SplayTreeMap<String, Object>.of(
      <String, Object>{
        'TLS.ver': '2.0',
        'TLS.identifier': userId,
        'TLS.sdkappid': sdkAppId,
        'TLS.expire': _expireTime,
        'TLS.time': currentTime,
        'TLS.sig': signature,
      },
    );

    final List<int> compressed = ZLibCodec(
      level: ZLibOption.minLevel,
    ).encode(utf8.encode(jsonEncode(document)));
    return _base64Url(compressed);
  }

  static String _hmacSHA256({
    required String userId,
    required int currentTime,
  }) {
    final String contentToBeSigned = 'TLS.identifier:$userId\n'
        'TLS.sdkappid:$sdkAppId\n'
        'TLS.time:$currentTime\n'
        'TLS.expire:$_expireTime\n';
    final Hmac hmac = Hmac(sha256, utf8.encode(_secretKey));
    return base64.encode(hmac.convert(utf8.encode(contentToBeSigned)).bytes);
  }

  static String _base64Url(List<int> bytes) {
    return base64
        .encode(bytes)
        .replaceAll('+', '*')
        .replaceAll('/', '-')
        .replaceAll('=', '_');
  }
}
