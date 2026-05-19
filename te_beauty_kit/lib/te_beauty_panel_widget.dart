import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:te_beauty_kit/tui_beauty_kit.dart';
import 'package:tencent_effect_flutter/uikit/callback/te_default_panel_view_callback.dart';
import 'package:tencent_effect_flutter/uikit/config/te_res_config.dart';
import 'package:tencent_effect_flutter/uikit/model/te_ui_property.dart';
import 'package:tencent_effect_flutter/uikit/producer/te_general_data_producer.dart';
import 'package:tencent_effect_flutter/uikit/producer/te_panel_data_producer.dart';
import 'package:tencent_effect_flutter/uikit/view/te_beauty_panel_view.dart';
import 'package:te_beauty_kit/language/gen/tebeautykit_localizations.dart';

class TEBeautyPanelWidget extends StatefulWidget {
  final Color? backgroundColor;
  final bool? revertWithDialog;

  const TEBeautyPanelWidget({super.key, this.backgroundColor, this.revertWithDialog = true});

  @override
  State<StatefulWidget> createState() {
    return _TEBeautyPanelWidgetState();
  }
}

class _TEBeautyPanelWidgetState extends State<TEBeautyPanelWidget> {
  final PanelViewCallBack beautyPanelViewCallBack = TUIBeautyKit.instance.getPanelViewCallBack();
  final TEPanelDataProducer panelDataProducer = TEGeneralDataProducer();
  List<TESDKParam>? lastSdkParam;
  TEBeautyKitLocalizations? _localizations;

  @override
  void initState() {
    TEResConfig.getConfig().panelBackgroundColor = widget.backgroundColor ?? Color(0xFF22262E);
    panelDataProducer.setPanelDataList(TEResConfig.getConfig().defaultPanelDataList);
    lastSdkParam = TUIBeautyKit.instance.getBeautyParam();
    panelDataProducer.setUsedParams(lastSdkParam);
    beautyPanelViewCallBack.setOnRevertCallback(() {
      if (widget.revertWithDialog == true) {
        _showRevertDialog();
      } else {
        _revertEffectAndPanelView();
      }
    });
    beautyPanelViewCallBack.setImagePickCallback((bool isGreenScreen) {
      return _showPickImageDialog(isGreenScreen);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = TEBeautyKitLocalizations.of(context);
  }

  @override
  void dispose() {
    lastSdkParam = beautyPanelViewCallBack.getUsedParams();
    TUIBeautyKit.instance.setBeautyParam(lastSdkParam ?? []);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        Expanded(
          child: TEBeautyPanelView(beautyPanelViewCallBack, panelDataProducer, beautyPanelViewCallBack.panelController),
        ),
      ],
    );
  }

  void _showRevertDialog() {
    CommonDialog.show(
      context: context,
      title: _localizations!.beauty_reset_title,
      content: _localizations!.beauty_reset_content,
      leftText: _localizations!.beauty_cancel,
      rightText: _localizations!.beauty_reset_confirm,
      onLeftPress: null,
      onRightPress: () {
        Navigator.of(context).pop(true);
        _revertEffectAndPanelView();
      },
    );
  }

  Future<bool?> _showPickImageDialog(bool isGreenScreen) {
    final screenType = isGreenScreen ? _localizations!.beauty_green_screen : _localizations!.beauty_blue_screen;
    return CommonDialog.show(
      context: context,
      title: _localizations!.beauty_import_image,
      content: _localizations!.beauty_import_image_tip.replaceAll('xxx', screenType),
      leftText: _localizations!.beauty_cancel,
      rightText: _localizations!.beauty_pick_image,
      onLeftPress: null,
      onRightPress: () {
        Navigator.of(context).pop(true);
      },
    );
  }

  void _revertEffectAndPanelView() {
    try {
      beautyPanelViewCallBack.revertEffectAndPanelView(context);
    } catch (e) {
      debugPrint("revertEffectAndPanelView error: $e");
    }
  }
}

typedef ImagePickCallback = Future<bool?> Function(bool isGreenScreen);

class PanelViewCallBack extends TEDefaultPanelViewCallBack {
  final bool _pickImg = true;
  List<TESDKParam>? defaultEffectParams;
  VoidCallback? _onRevert;
  ImagePickCallback? _onPickImage;

  void setOnRevertCallback(VoidCallback callback) {
    _onRevert = callback;
  }

  void setImagePickCallback(ImagePickCallback callback) {
    _onPickImage = callback;
  }

  @override
  Future<void> onClickCustomSeg(TEUIProperty uiProperty) async {
    if (uiProperty.sdkParam?.extraInfo == null) {
      return;
    }
    if (uiProperty.displayNameEn == 'Custom') {
      _pickImage(uiProperty);
    } else {
      final isGreenScreen = uiProperty.displayNameEn?.toLowerCase().contains('green') == true;
      final result = await _onPickImage?.call(isGreenScreen);
      if (result == true) {
        _pickImage(uiProperty);
      }
    }
  }

  @override
  void onDefaultEffectList(List<TESDKParam> paramList) {
    super.onDefaultEffectList(paramList);
    defaultEffectParams = paramList;
  }

  @override
  void onRevertBtnClick(BuildContext context, TEBeautyPanelView panelView) {
    _onRevert?.call();
  }

  void _pickImage(TEUIProperty uiProperty) async {
    try {
      final ImagePicker picker = ImagePicker();
      // Pick an image
      XFile? xFile =
          _pickImg
              ? await picker.pickImage(source: ImageSource.gallery)
              : await picker.pickVideo(source: ImageSource.gallery);
      if (xFile == null) {
        return;
      }
      uiProperty.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_BG_TYPE] =
          _pickImg ? TESDKParam.EXTRA_INFO_BG_TYPE_IMG : TESDKParam.EXTRA_INFO_BG_TYPE_VIDEO;
      uiProperty.sdkParam!.extraInfo![TESDKParam.EXTRA_INFO_KEY_BG_PATH] = xFile.path;
      onUpdateEffect(uiProperty.sdkParam!);
      panelController.checkPanelViewItem(uiProperty);
    } catch (e) {
      debugPrint("Pick image/video failed: $e");
    }
  }
}

class CommonDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    required String leftText,
    required String rightText,
    VoidCallback? onLeftPress,
    VoidCallback? onRightPress,
    double borderRadius = 12.0,
  }) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          child: Container(
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    content,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16, color: Colors.black38),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, thickness: 1, color: Colors.black12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () {
                          if (onLeftPress != null) {
                            onLeftPress();
                          } else {
                            Navigator.of(context).pop(false);
                          }
                        },
                        child: Text(
                          leftText,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 60, color: Colors.black12),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () {
                          if (onRightPress != null) {
                            onRightPress();
                          } else {
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: Text(
                          rightText,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.blueAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}