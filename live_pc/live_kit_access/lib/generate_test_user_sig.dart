library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class GenerateTestUserSig {
  GenerateTestUserSig._();

  static const int sdkAppId = int.fromEnvironment(
    'LIVEKIT_SDKAPPID',
    defaultValue: 0,
  );

  static const int _expireTime = 604800;

  static const String _secretKey = String.fromEnvironment(
    'LIVEKIT_SECRETKEY',
    defaultValue: '',
  );

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
