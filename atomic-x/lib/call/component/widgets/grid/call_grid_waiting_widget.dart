import 'package:atomic_x_core/atomicxcore.dart';
import 'package:flutter/cupertino.dart';

import '../../../common/call_colors.dart';
import '../../../common/constants.dart';
import '../../../common/i18n/i18n_utils.dart';
import '../../../common/utils/utils.dart';

class CallGridWaitingWidget extends StatelessWidget {
  const CallGridWaitingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _getCallerInfoDisplay(),
        Text(
          CallKit_t("invitedToGroupCall"),
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
                CallKit_t("theyAreAlsoThere"),
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

  const _CallerInfoWidget({Key? key, required this.userId}) : super(key: key);

  @override
  State<_CallerInfoWidget> createState() => _CallerInfoWidgetState();
}

class _CallerInfoWidgetState extends State<_CallerInfoWidget> {
  String displayName = "";
  String avatarUrl = Constants.defaultAvatar;
  ContactListStore contactListStore = ContactListStore.create();

  @override
  void initState() {
    contactListStore.addListener(() {
      displayName = contactListStore.contactListState.addFriendInfo?.title ?? "";
      avatarUrl = contactListStore.contactListState.addFriendInfo?.avatarURL ?? Constants.defaultAvatar;
      if (mounted) setState(() {});
    });
    contactListStore.fetchUserInfo(userID: widget.userId);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    contactListStore.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(fontSize: 24, color: CallColors.colorG7,),
          ),
        ),
      ],
    );
  }

}