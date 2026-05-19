import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:te_beauty_kit/te_beauty_extension.dart';
import 'package:te_beauty_kit/te_beauty_panel_widget.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/uikit/config/te_res_config.dart';
import 'package:tencent_effect_flutter/uikit/manager/te_res_path_manager.dart';
import 'package:tencent_effect_flutter/uikit/model/te_ui_property.dart';

enum BeautyLevel {
  A1_00, A1_01, A1_02, A1_03, A1_04, A1_05, A1_06,
  S1_00, S1_01, S1_02, S1_03, S1_04, S1_07,
}

const kTEBeautyService = 'TEBeautyService';

class TUIBeautyKit {
  TUIBeautyKit._internal();

  final TEBeautyExtension _teBeautyExtension = TEBeautyExtension();

  static final TUIBeautyKit instance = TUIBeautyKit._internal();

  void init(String licenseUrl, String licenseKey, BeautyLevel level) async {
    debugPrint("init, level:$level");
    _registerExtension();
    _initPanelViewConfig(level);
    String resourceDir = await TEResPathManager.getResManager().getResPath();
    debugPrint('_initResource ,xmagic resource dir is $resourceDir');
    TencentEffectApi.getApi()?.setResourcePath(resourceDir);
    bool isCopiedRes = await _isCopiedRes();
    debugPrint("_isCopiedRes:$isCopiedRes");
    if (isCopiedRes) {
      _setLicense(licenseKey, licenseUrl);
    } else {
      TencentEffectApi.getApi()?.initXmagic((result) {
        debugPrint("initXmagic, result:$result");
        if (result) {
          _saveResCopied();
          _setLicense(licenseKey, licenseUrl);
        }
      });
    }
  }

  void setBeautyParam(List<TESDKParam> sdkParams) {
    _teBeautyExtension.setBeautyParam(sdkParams);
  }

  List<TESDKParam> getBeautyParam() {
    return _teBeautyExtension.getBeautyParam();
  }

  PanelViewCallBack getPanelViewCallBack() {
    return _teBeautyExtension.getPanelViewCallBack();
  }

  void _registerExtension() {
    TUICore.instance.registerService(kTEBeautyService, _teBeautyExtension);
    TUICore.instance.registerExtension(TUIExtensionID.joinInGroup, _teBeautyExtension);
  }

  void _setLicense(String licenseKey, String licenseUrl) {
    TencentEffectApi.getApi()?.setLicense(licenseKey, licenseUrl, (code, msg) {
      debugPrint("_setLicense code:$code | msg:$msg");
    });
  }

  Future<bool> _isCopiedRes() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentAppVersionName = packageInfo.version;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? versionName = sharedPreferences.getString("app_version_name");
    return currentAppVersionName == versionName;
  }

  void _saveResCopied() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentAppVersionName = packageInfo.version;
    await sharedPreferences.setString("app_version_name", currentAppVersionName);
  }

  void _initPanelViewConfig(BeautyLevel level) {
    final config = TEResConfig.getConfig();
    config.defaultPanelDataList.clear();
    final beautyJson = "assets/beauty_panel/beauty.json";
    final beautyTemplateJson = Platform.isAndroid ? "assets/beauty_panel/beauty_template.json" : "assets/beauty_panel/beauty_template_ios.json";
    final beautyBodyJson = "assets/beauty_panel/beauty_body.json";
    final beautyImageJson = "assets/beauty_panel/beauty_image.json";
    final beautyMakeupJson = "assets/beauty_panel/beauty_makeup.json";
    final beautyShapeJson = "assets/beauty_panel/beauty_shape.json";
    final lightMakeupJson = "assets/beauty_panel/light_makeup.json";
    final lutJson = "assets/beauty_panel/lut.json";
    final makeupJson = "assets/beauty_panel/makeup.json";
    final motions2DJson = "assets/beauty_panel/motions_2d.json";
    final motions3DJson = "assets/beauty_panel/motions_3d.json";
    final motionsGestureJson = "assets/beauty_panel/motions_gesture.json";
    final segmentationJson = "assets/beauty_panel/segmentation.json";

    switch(level) {
      case BeautyLevel.A1_00:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setLutRes(lutJson);
        break;
      case BeautyLevel.A1_01:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        break;
      case BeautyLevel.A1_02:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setMotionRes(motions2DJson);
        break;
      case BeautyLevel.A1_03:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setMotionRes(motions2DJson);
        break;
      case BeautyLevel.A1_04:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        break;
      case BeautyLevel.A1_05:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setMotionRes(motions2DJson);
        config.setSegmentationRes(segmentationJson);
        break;
      case BeautyLevel.A1_06:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setMakeUpRes(makeupJson);
        config.setMotionRes(motions2DJson);
        break;
      case BeautyLevel.S1_00:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setBeautyRes(beautyShapeJson);
        config.setBeautyRes(beautyMakeupJson);
        break;
      case BeautyLevel.S1_01:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setBeautyRes(beautyShapeJson);
        config.setBeautyRes(beautyMakeupJson);
        config.setLightMakeupRes(lightMakeupJson);
        config.setMakeUpRes(makeupJson);
        config.setMotionRes(motions2DJson);
        config.setMotionRes(motions3DJson);
        break;
      case BeautyLevel.S1_02:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setBeautyRes(beautyShapeJson);
        config.setBeautyRes(beautyMakeupJson);
        config.setLightMakeupRes(lightMakeupJson);
        config.setMakeUpRes(makeupJson);
        config.setMotionRes(motions2DJson);
        config.setMotionRes(motions3DJson);
        config.setMotionRes(motionsGestureJson);
        break;
      case BeautyLevel.S1_03:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setBeautyRes(beautyShapeJson);
        config.setBeautyRes(beautyMakeupJson);
        config.setLightMakeupRes(lightMakeupJson);
        config.setMakeUpRes(makeupJson);
        config.setMotionRes(motions2DJson);
        config.setMotionRes(motions3DJson);
        config.setSegmentationRes(segmentationJson);
        break;
      case BeautyLevel.S1_04:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setBeautyRes(beautyShapeJson);
        config.setBeautyRes(beautyMakeupJson);
        config.setLightMakeupRes(lightMakeupJson);
        config.setMakeUpRes(makeupJson);
        config.setMotionRes(motions2DJson);
        config.setMotionRes(motions3DJson);
        config.setMotionRes(motionsGestureJson);
        config.setSegmentationRes(segmentationJson);
        break;
      case BeautyLevel.S1_07:
        config.setBeautyTemplateRes(beautyTemplateJson);
        config.setBeautyRes(beautyJson);
        config.setBeautyRes(beautyImageJson);
        config.setLutRes(lutJson);
        config.setBeautyRes(beautyShapeJson);
        config.setBeautyRes(beautyMakeupJson);
        config.setLightMakeupRes(lightMakeupJson);
        config.setMakeUpRes(makeupJson);
        config.setMotionRes(motions2DJson);
        config.setMotionRes(motions3DJson);
        config.setMotionRes(motionsGestureJson);
        config.setSegmentationRes(segmentationJson);
        config.setBeautyBodyRes(beautyBodyJson);
        break;
    }
  }
}
