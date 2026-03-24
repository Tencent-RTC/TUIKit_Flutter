import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

 /// Tencent Cloud SDKAppId, which needs to be replaced with the SDKAppId under your own account.
 ///
 /// Enter Tencent Cloud IM to create an application, and you can see the SDKAppId, which is the unique identifier used by Tencent Cloud to distinguish customers.
const int SDKAPPID = 0;

 /// Encryption key used for calculating the signature, the steps to obtain it are as follows:
 ///
 /// step1. Enter Tencent Cloud IM, if you do not have an application yet, create one,
 /// step2. Click "Application Configuration" to enter the basic configuration page, and further find the "Account System Integration" section.
 /// step3. Click the "View Key" button, you can see the encryption key used to calculate UserSig, please copy and paste it into the following variable
 ///
 /// Note: This solution is only applicable to debugging demos.
 /// Before going online officially, please migrate the UserSig calculation code and keys to your backend server to avoid traffic theft caused by encryption key leakage.
const String SECRETKEY = '';

 /// Signature expiration time, it is recommended not to set it too short
 ///
 /// Time unit: seconds
 /// Default time: 7 x 24 x 60 x 60 = 604800 = 7 days
const int EXPIRETIME = 604800;

class GenerateTestUserSig {

  static String genTestUserSig({required String identifier}) {
    final int current = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final Map<String, dynamic> obj = {
      'TLS.ver': '2.0',
      'TLS.identifier': identifier,
      'TLS.sdkappid': SDKAPPID,
      'TLS.expire': EXPIRETIME,
      'TLS.time': current,
    };
    final keyOrder = [
      'TLS.identifier',
      'TLS.sdkappid',
      'TLS.time',
      'TLS.expire',
    ];
    String stringToSign = '';
    for (final key in keyOrder) {
      if (obj.containsKey(key)) {
        stringToSign += '$key:${obj[key]}\n';
      }
    }
    print('string to sign: $stringToSign');
    final sig = _hmac(stringToSign);
    obj['TLS.sig'] = sig;
    print('sig: $sig');

    final jsonStr = jsonEncode(obj);
    final jsonBytes = utf8.encode(jsonStr);

    // zlib compression
    final compressed = zlib.encode(jsonBytes);

    final result = _base64URL(Uint8List.fromList(compressed));
    return result;
  }

  static String _hmac(String plainText) {
    final key = utf8.encode(SECRETKEY);
    final data = utf8.encode(plainText);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(data);
    return base64.encode(digest.bytes);
  }

  static String _base64URL(Uint8List data) {
    final result = base64.encode(data);
    final buffer = StringBuffer();
    for (final char in result.runes) {
      final c = String.fromCharCode(char);
      switch (c) {
        case '+':
          buffer.write('*');
          break;
        case '/':
          buffer.write('-');
          break;
        case '=':
          buffer.write('_');
          break;
        default:
          buffer.write(c);
      }
    }
    return buffer.toString();
  }
}
