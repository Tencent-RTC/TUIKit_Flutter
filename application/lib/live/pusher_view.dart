import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tencent_live_uikit/tencent_live_uikit.dart';
import '../common/app_strings.dart';
import 'broadcast_type_bar_view.dart';

class AppPusherView extends StatelessWidget {
  const AppPusherView({super.key, required this.liveID});
  final String liveID;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: PusherView(
        liveID: liveID,
        onExit: () => Navigator.of(context).pop(),
        prepareAccessory: BroadcastTypeBarView(
          onSelect: (type) {
            if (type == BroadcastType.video) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppStrings.of(context, type.name)} · ${AppStrings.of(context, 'unavailable')}'),
              ),
            );
          },
        ),
      ),
    ),
  );
}
