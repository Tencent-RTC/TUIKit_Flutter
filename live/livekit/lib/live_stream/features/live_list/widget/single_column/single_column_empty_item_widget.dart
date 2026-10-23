import 'package:flutter/cupertino.dart';

import '../../../../../common/language/gen/livekit_localizations.dart';
import '../../../../../common/resources/colors.dart';
import '../../../../../common/widget/global.dart';

class SingleColumnEmptyItemWidget extends StatelessWidget {
  const SingleColumnEmptyItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(LiveKitLocalizations.of(Global.appContext())!.livelist_no_more_data,
          style: TextStyle(color: LiveColors.designStandardWhite7.withAlpha(128))),
    );
  }
}
