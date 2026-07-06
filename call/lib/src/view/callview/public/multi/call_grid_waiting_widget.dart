import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';

import '../../core/common/call_colors.dart';
import '../../core/common/constants.dart';
import 'package:tuikit_atomic_x/base_component/localizations/atomic_localizations.dart';
import '../../core/common/utils/utils.dart';

// ignore_for_file: unused_import

class CallGridWaitingWidget extends StatelessWidget {
  const CallGridWaitingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AtomicLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _getCallerInfoDisplay(),
        Text(
          l10n.callInvitedToGroupCall,
          textScaleFactor: 1.0,
          style: const TextStyle(fontSize: 16, color: CallColors.colorG5),
        ),
        const SizedBox(
          height: 50,
        ),
        _getInviteeListView(),
      ],
    );
  }

  _getCallerInfoDisplay() {
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.activeCall,
      builder: (context, activeCall, child) {
        return _CallerInfoWidget(userId: activeCall.inviterId);
      },
    );
  }

  _getInviteeListView() {
    return ValueListenableBuilder(
      valueListenable: CallStore.shared.state.allParticipants,
      builder: (context, allParticipants, child) {
        List<String> inviteeAvatarList = [];
        for (var participant in allParticipants) {
          if (participant.id != CallStore.shared.state.selfInfo.value.id
              && participant.id != CallStore.shared.state.activeCall.value.inviterId) {
            inviteeAvatarList.add(participant.avatarURL);
          }
        }
        if (inviteeAvatarList.isNotEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AtomicLocalizations.of(context).callTheyAreAlsoThere,
                textScaleFactor: 1.0,
                style: const TextStyle(fontSize: 15, color: CallColors.colorG5),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: List.generate(inviteeAvatarList.length, ((index) {
                    return Container(
                      height: 30,
                      width: 30,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      child: Image(
                        image: NetworkImage(
                          StringStream.makeNull(
                            inviteeAvatarList[index],
                            Constants.defaultAvatar,
                          ),
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stackTrace) => Image.asset(
                          'call_assets/user_icon.png',
                          package: 'tuikit_atomic_x',
                        ),
                      ),
                    );
                  })),
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}


class _CallerInfoWidget extends StatefulWidget {
  final String userId;

  const _CallerInfoWidget({super.key, required this.userId});

  @override
  State<_CallerInfoWidget> createState() => _CallerInfoWidgetState();
}

class _CallerInfoWidgetState extends State<_CallerInfoWidget> {
  ContactInfo? _contactInfo;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  Future<void> _loadContactInfo() async {
    final handler = await ContactStore.shared.getContactInfo(userIDList: [widget.userId]);
    if (handler.isSuccess && handler.contactInfoList.isNotEmpty && mounted) {
      setState(() {
        _contactInfo = handler.contactInfoList.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _contactInfo?.nickname ?? "";
    final avatarUrl = _contactInfo?.avatarURL ?? Constants.defaultAvatar;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 150),
          height: 120,
          width: 120,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: Image(
                image: NetworkImage(
                  StringStream.makeNull(
                    avatarUrl,
                    Constants.defaultAvatar,
                  ),
                ),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stackTrace) => Image.asset(
                  'call_assets/user_icon.png',
                  package: 'tuikit_atomic_x',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                displayName,
                textScaleFactor: 1.0,
                style: const TextStyle(fontSize: 24, color: CallColors.colorG7),
              ),
            ),
          ],
        );
  }
}
