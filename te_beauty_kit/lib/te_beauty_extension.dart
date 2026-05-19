import 'package:flutter/cupertino.dart';
import 'package:te_beauty_kit/te_beauty_panel_widget.dart';
import 'package:tencent_cloud_uikit_core/tencent_cloud_uikit_core.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/uikit/model/te_ui_property.dart';

const kEnableBeauty = 'enableBeauty';
const kGetBeautyPanel = 'getBeautyPanel';
const kReset = 'reset';

class TEBeautyExtension implements AbstractTUIExtension, AbstractTUIService {
  List<TESDKParam> _sdkParams = [];
  PanelViewCallBack? _beautyPanelViewCallBack;
  bool _hasAppliedBeautyParam = false;

  @override
  Future<Widget> onRaiseExtension(TUIExtensionID extensionID, Map<String, dynamic> param) {
    return Future.value(SizedBox.shrink());
  }

  @override
  void onCall(String serviceName, String method, Map<String, dynamic> param) {
    if (method == kGetBeautyPanel) {
      Color? color;
      if (param.containsKey('backgroundColor')) {
        color = Color(param['backgroundColor']);
      }
      final revertWithDialog = param['revertWithDialog'] ?? true;
      param['beautyPanel'] = TEBeautyPanelWidget(backgroundColor: color, revertWithDialog: revertWithDialog);
    } else if (method == kEnableBeauty) {
      final enable = param['enable'] ?? false;
      _setEffectMode(EffectMode.PRO);
      _createPanelViewCallBack();
      _enableBeauty(enable);
    } else if (method == kReset) {
      _reset();
    }
  }

  void setBeautyParam(List<TESDKParam> sdkParams) {
    _sdkParams = sdkParams;
  }

  List<TESDKParam> getBeautyParam() {
    return _sdkParams;
  }

  PanelViewCallBack getPanelViewCallBack() {
    return _beautyPanelViewCallBack ?? PanelViewCallBack();
  }

  void _setEffectMode(EffectMode effectMode) {
    debugPrint("TEBeautyExtension _setEffectMode:$effectMode");
    TencentEffectApi.getApi()!.setEffectMode(effectMode);
  }

  void _createPanelViewCallBack() {
    _beautyPanelViewCallBack = PanelViewCallBack();
  }

  void _enableBeauty(bool enable) {
    debugPrint("TEBeautyExtension _enableBeauty:$enable");
    if (enable) {
      TencentEffectApi.getApi()!.setXmagicApiCreatedListener((data) {
        debugPrint("TEBeautyExtension XmagicApi created, data:$data, hasAppliedBeautyParam:$_hasAppliedBeautyParam");
        _applyBeautyParam();
      });
    } else {
      TencentEffectApi.getApi()!.setXmagicApiCreatedListener(null);
      _hasAppliedBeautyParam = false;
    }
    TencentEffectApi.getApi()!.enableBeauty(enable).then((result) {
      debugPrint("TEBeautyExtension _enableBeauty, result:$result");
      if (result == 0 && enable) {
        _applyBeautyParam();
      }
    });
  }

  void _applyBeautyParam() {
    debugPrint("TEBeautyExtension _applyBeautyParam, _hasAppliedBeautyParam:$_hasAppliedBeautyParam");
    if (_hasAppliedBeautyParam) return;
    getPanelViewCallBack().onUpdateEffectList(getBeautyParam());
    _hasAppliedBeautyParam = true;
  }

  void _reset() {
    debugPrint("TEBeautyExtension _reset");
    setBeautyParam([]);
    _hasAppliedBeautyParam = false;
  }
}