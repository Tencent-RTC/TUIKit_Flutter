/// 对应 iOS `LiveKitAccess/GenerateTestUserSig.swift` 与 Android
/// `livekitaccess/app/src/main/java/com/livekit/demo/GenerateTestUserSig.java`。
///
/// 生成测试用 UserSig。UserSig 是腾讯云为其云服务设计的安全签名，
/// 由 `SDKAppID`、`UserID` 和 `EXPIRETIME` 通过 HMAC-SHA256 计算得到。
///
/// 注意：请不要在正式商用的应用中使用下面的代码。
/// 该代码能正确计算出 UserSig，但只适合快速验证 SDK 的基础能力，不适合商用场景。
/// 客户端代码中的 `SECRETKEY` 很容易被反编译逆向破解，尤其是 Web 端。
/// 一旦密钥泄露，攻击者就可以盗用你的腾讯云流量。
/// 正确做法是将 UserSig 的计算代码和密钥部署到你的业务服务器上，由客户端按需向服务器请求。
///
/// 参考文档：https://cloud.tencent.com/document/product/269/32688#Server
library;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class GenerateTestUserSig {
  GenerateTestUserSig._();

  /// 腾讯云 SDKAppID，需要替换为你自己账号下的 SDKAppID。
  ///
  /// 进入腾讯云 [即时通信 IM 控制台](https://console.cloud.tencent.com/avc)
  /// 创建应用后，即可看到 SDKAppID，它是腾讯云用于区分客户的唯一标识。
  ///
  /// 可用 `--dart-define=LIVEKIT_SDKAPPID=xxx` 覆盖。
  static const int sdkAppID = int.fromEnvironment(
    'LIVEKIT_SDKAPPID',
    defaultValue: 0,
  );

  /// 签名有效期，不建议设置过短。
  ///
  /// 单位：秒
  /// 默认值：604800（7 天）
  static const int _expireTime = 604800;

  /// 计算签名用的加密密钥，获取步骤如下：
  ///
  /// 步骤一：进入 [IM 控制台](https://console.cloud.tencent.com/avc)，
  /// 如果还没有应用则先创建一个。
  /// 步骤二：点击你的应用，找到“基本配置”。
  /// 步骤三：点击“显示密钥”，即可看到计算 UserSig 用的加密密钥，将其复制到下面的变量中。
  ///
  /// 注意：该方案仅适合本地跑通 Demo 和功能调试。
  /// 正式上线前请将 UserSig 计算代码和密钥迁移到后台服务器，避免密钥泄露导致流量盗用。
  /// 参考文档：https://cloud.tencent.com/document/product/269/32688#Server
  ///
  /// 可用 `--dart-define=LIVEKIT_SECRETKEY=xxx` 覆盖，正式包应传入空串并改用服务端下发的 UserSig。
  static const String _secretKey = String.fromEnvironment(
    'LIVEKIT_SECRETKEY',
    defaultValue: '',
  );

  /// 腾讯特效 License，与 iOS、Android 原生接入 App 保持一致。
  static const String tencentEffectLicenseURL = '';
  static const String tencentEffectLicenseKey = '';

  /// 服务端下发的 UserSig。配置后优先使用，客户端不再参与签名计算。
  ///
  /// 通过 `--dart-define=LIVEKIT_USERSIG=xxx` 传入。
  static const String _presetUserSig = String.fromEnvironment('LIVEKIT_USERSIG');

  /// 计算 UserSig。
  ///
  /// 函数内部使用 HMAC-SHA256 非对称加密算法，
  /// 基于 `SDKAppID`、`UserID` 和 `EXPIRETIME` 计算 UserSig。
  static String genTestUserSig(String userID) {
    if (_presetUserSig.isNotEmpty) {
      return _presetUserSig;
    }
    if (sdkAppID <= 0 || _secretKey.isEmpty || userID.isEmpty) {
      return '';
    }

    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String signature = _hmacSHA256(userID: userID, currentTime: currentTime);
    if (signature.isEmpty) {
      return '';
    }

    // 与 iOS 的 `JSONSerialization.sortedKeys` 对齐，保证文档字段顺序稳定。
    final SplayTreeMap<String, Object> document = SplayTreeMap<String, Object>.of(
      <String, Object>{
        'TLS.ver': '2.0',
        'TLS.identifier': userID,
        'TLS.sdkappid': sdkAppID,
        'TLS.expire': _expireTime,
        'TLS.time': currentTime,
        'TLS.sig': signature,
      },
    );
    // 与 iOS `compress2(..., Z_BEST_SPEED)`、Android `Deflater()` 对齐。
    final List<int> compressed =
        ZLibCodec(level: ZLibOption.minLevel).encode(utf8.encode(jsonEncode(document)));
    return _base64URL(compressed);
  }

  static String _hmacSHA256({required String userID, required int currentTime}) {
    final String contentToBeSigned = 'TLS.identifier:$userID\n'
        'TLS.sdkappid:$sdkAppID\n'
        'TLS.time:$currentTime\n'
        'TLS.expire:$_expireTime\n';
    final Hmac hmac = Hmac(sha256, utf8.encode(_secretKey));
    return base64.encode(hmac.convert(utf8.encode(contentToBeSigned)).bytes);
  }

  /// 与 IM / TRTC 服务端约定的 base64 变体。
  static String _base64URL(List<int> bytes) {
    return base64.encode(bytes).replaceAll('+', '*').replaceAll('/', '-').replaceAll('=', '_');
  }
}
