import 'package:atomic_x_core/atomicxcore.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';

class UIKitUtil {
  static RegExp urlReg = RegExp(
      r"([hH][tT]{2}[pP]:\/\/|[hH][tT]{2}[pP][sS]:\/\/|[wW]{3}.|[wW][aA][pP].|[fF][tT][pP].|[fF][iI][lL][eE].)[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]");

  /// Group member display name priority: nameCard > friendRemark > nickname > userID
  static String memberDisplayName(GroupMember member) {
    if (member.nameCard != null && member.nameCard!.isNotEmpty) return member.nameCard!;
    if (member.friendRemark != null && member.friendRemark!.isNotEmpty) return member.friendRemark!;
    if (member.nickname != null && member.nickname!.isNotEmpty) return member.nickname!;
    return member.userID;
  }

  static void reportChatInvokeCall() {
    TencentImSDKPlugin.v2TIMManager.callExperimentalAPI(
      api: 'report_tuifeature_usage',
      param: {
        'report_tuifeature_usage_uicomponent_type': 1020,
      },
    );
  }
}
