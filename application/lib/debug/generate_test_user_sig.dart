import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Android、iOS 共用的 SDK 配置；默认值用于当前接入工程的开发调试。
/// 登录参数覆盖优先级：APP_* → LIVEKIT_* → 此文件默认值。
abstract final class GenerateTestUserSig {
  /// 腾讯云应用 ID。
  static const int sdkAppId = int.fromEnvironment(
    'APP_SDKAPPID',
    defaultValue: int.fromEnvironment('LIVEKIT_SDKAPPID', defaultValue: 1400704311),
  );

  /// 测试 UserSig 签名密钥；显式传空可关闭客户端签名。
  static const String secretKey = String.fromEnvironment(
    'APP_SECRETKEY',
    defaultValue: String.fromEnvironment(
      'LIVEKIT_SECRETKEY',
      defaultValue: 'f466445b65ad86a830221a3cbb26ff8a402cda22a1c362d10866bd27e95b4422',
    ),
  );

  /// 服务端签发的 UserSig，非空时优先使用。
  static const String userSig = String.fromEnvironment(
    'APP_USERSIG',
    defaultValue: String.fromEnvironment('LIVEKIT_USERSIG'),
  );

  /// 测试 UserSig 有效期，单位为秒。
  static const int userSigExpireSeconds = 604800;

  /// 高级美颜与 MP4 特效授权；显式传空可关闭授权提交。
  static const String effectLicenseUrl = String.fromEnvironment(
    'APP_EFFECT_LICENSE_URL',
    defaultValue: 'https://license.vod2.myqcloud.com/license/v2/1252463788_1/v_cube.license',
  );
  static const String effectLicenseKey = String.fromEnvironment(
    'APP_EFFECT_LICENSE_KEY',
    defaultValue: 'f5109b0ec0ba0027f809cb947d204c65',
  );

  static String genTestUserSig({required String identifier}) {
    final user = identifier;
    const appId = sdkAppId;
    const supplied = userSig;
    if (supplied.isNotEmpty) return supplied;
    const key = secretKey;
    if (key.isEmpty) return '';
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const expire = userSigExpireSeconds;
    final data = 'TLS.identifier:$user\nTLS.sdkappid:$appId\nTLS.time:$time\nTLS.expire:$expire\n';
    final sig = base64Encode(Hmac(sha256, utf8.encode(key)).convert(utf8.encode(data)).bytes);
    final json = jsonEncode({
      'TLS.ver': '2.0',
      'TLS.identifier': user,
      'TLS.sdkappid': appId,
      'TLS.expire': expire,
      'TLS.time': time,
      'TLS.sig': sig,
    });
    return base64Encode(zlib.encode(utf8.encode(json))).replaceAll('+', '*').replaceAll('/', '-').replaceAll('=', '_');
  }
}
