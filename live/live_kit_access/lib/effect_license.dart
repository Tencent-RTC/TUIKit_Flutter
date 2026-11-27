import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_effect_player/ftceffect_player.dart';

import 'generate_test_user_sig.dart';
import 'package:tencent_live_uikit/src/common/platform/advanced_beauty_channel.dart';

/// 提交 MP4 特效授权；Future 完成只表示调用已提交，最终结果由回调给出。
/// 启动和成功登录后均可调用，让首次联网前失败的授权有机会重新发起。
Future<void>? _licenseSubmission;

Future<void> initializeEffectLicense() =>
    _licenseSubmission ??= _initializeEffectLicense().whenComplete(() => _licenseSubmission = null);

Future<void> _initializeEffectLicense() async {
  await AdvancedBeautyChannel.setLicense(
    GenerateTestUserSig.tencentEffectLicenseURL,
    GenerateTestUserSig.tencentEffectLicenseKey,
  );
  try {
    await FTCMediaXBase.instance.setLicense(
      GenerateTestUserSig.tencentEffectLicenseURL,
      GenerateTestUserSig.tencentEffectLicenseKey,
      (code, _) {
        // 只记录结果码，不输出 License URL、Key 或原生错误详情。
        debugPrint('[LiveKitAccess][EffectLicense] result=$code');
      },
    );
  } on Object catch (error) {
    final code = error is PlatformException ? error.code : error.runtimeType;
    debugPrint('[LiveKitAccess][EffectLicense] submit failed: $code');
  }
}
