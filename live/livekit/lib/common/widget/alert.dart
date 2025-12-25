import 'package:flutter/material.dart';
import 'package:tencent_live_uikit/common/index.dart';

class AlertInfo {
  final String description;
  final String? imageUrl;

  final ({String title, Color titleColor})? cancelActionInfo;
  final ({String title, Color titleColor}) defaultActionInfo;
  final VoidCallback? cancelCallback;
  final VoidCallback defaultCallback;

  AlertInfo(
      {required this.description,
      required this.defaultActionInfo,
      required this.defaultCallback,
      this.imageUrl,
      this.cancelActionInfo,
      this.cancelCallback});
}

class AlertHandler {
  BuildContext? _context;

  AlertHandler();

  void _setContext(BuildContext? context) {
    _context = context;
  }

  bool isShowing() {
    return _context != null && _context!.mounted;
  }

  void close() {
    if (isShowing() && Navigator.canPop(_context!)) {
      Navigator.pop(_context!);
    }
  }
}

class Alert {
  static AlertHandler showAlert(AlertInfo info, {BuildContext? context}) {
    final handler = AlertHandler();
    showDialog(
      context: context ?? Global.appContext(),
      barrierDismissible: false,
      builder: (builderContext) {
        handler._setContext(builderContext);
        return Dialog(
          backgroundColor: LiveColors.designStandardTransparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 0.8.screenHeight,
              minWidth: 323.width,
            ),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: LiveColors.designStandardFlowkitWhite,
                  borderRadius: BorderRadius.circular(10.height),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 45.width, top: 24.height, right: 45.width, bottom: 24.height),
                      child: Row(
                        children: [
                          if (info.imageUrl != null)
                            ClipOval(
                              child: Image.network(
                                info.imageUrl!,
                                width: 24.radius,
                                height: 24.radius,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, _) {
                                  return Image.asset(
                                    LiveImages.defaultAvatar,
                                    package: Constants.pluginName,
                                    width: 24.radius,
                                    height: 24.radius,
                                  );
                                },
                              ),
                            ),
                          SizedBox(width: 4.width),
                          Expanded(
                            child: Text(
                              info.description,
                              style: const TextStyle(color: LiveColors.designStandardG1, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1.height, color: LiveColors.designStandardG7),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          if (info.cancelActionInfo != null)
                            Expanded(
                              child: TextButton(
                                onPressed: info.cancelCallback,
                                child: Text(
                                  info.cancelActionInfo!.title,
                                  style: TextStyle(
                                    color: info.cancelActionInfo!.titleColor,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          if (info.cancelActionInfo != null)
                            Container(
                              width: 1.width,
                              color: LiveColors.designStandardG7,
                            ),
                          Expanded(
                            child: TextButton(
                              onPressed: info.defaultCallback,
                              child: Text(
                                info.defaultActionInfo.title,
                                style: TextStyle(
                                  color: info.defaultActionInfo.titleColor,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() => handler._setContext(null));
    return handler;
  }
}
