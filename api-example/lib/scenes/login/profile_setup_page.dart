import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atomic_x_core/atomicxcore.dart' hide Role;
import 'package:atomic_x_core_example/l10n/app_localizations.dart';
import 'package:atomic_x_core_example/scenes/feature_list/feature_list_page.dart';

/// Business scenario: profile setup page
///
/// This page is shown after login succeeds when the user's nickname is empty, guiding the user to set a nickname and avatar.
///
/// Related APIs:
/// - `LoginStore.shared.setSelfInfo(userProfile:completion:)` - Set personal profile information
/// - `LoginStore.shared.state.value.loginUserInfo` - Get the current user information
///
/// Interaction notes:
/// - The nickname field is initialized with a random English name, and the user can edit it freely
/// - The avatar is randomly selected from 5 preset URLs by default, and the user can tap to switch
/// - The navigation bar has a "Skip" button on the right, allowing the user to skip profile setup and enter the feature list directly
/// - Tapping the "Done" button submits the nickname and avatar to the server
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  // MARK: - Constants

  /// Preset avatar URL list
  static const List<String> _avatarURLs = [
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar1.png',
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar2.png',
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar3.png',
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar4.png',
    'https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar5.png',
  ];

  /// Preset random nickname list
  static const List<String> _randomNicknames = [
    'Alex',
    'Jordan',
    'Taylor',
    'Morgan',
    'Casey',
    'Riley',
    'Avery',
    'Quinn',
    'Harper',
    'Skyler',
  ];

  // MARK: - Properties

  final TextEditingController _nicknameController = TextEditingController();
  int _selectedAvatarIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _randomizeDefaults();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // MARK: - Init

  /// Randomly initialize the default nickname and avatar
  void _randomizeDefaults() {
    final random = Random();
    _nicknameController.text = _randomNicknames[random.nextInt(_randomNicknames.length)];
    _selectedAvatarIndex = random.nextInt(_avatarURLs.length);
  }

  // MARK: - Actions

  void _skipTapped() {
    _navigateToFeatureList();
  }

  void _randomNicknameTapped() {
    setState(() {
      _nicknameController.text = _randomNicknames[Random().nextInt(_randomNicknames.length)];
    });
  }

  void _confirmTapped() {
    FocusScope.of(context).unfocus();

    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileErrorEmptyNickname)));
      return;
    }

    _saveSelfInfo(nickname: nickname, avatarURL: _avatarURLs[_selectedAvatarIndex]);
  }

  void _avatarOptionTapped(int index) {
    setState(() {
      _selectedAvatarIndex = index;
    });
  }

  // MARK: - Save Info

  void _saveSelfInfo({required String nickname, required String avatarURL}) {
    _setLoading(true);

    final userID = LoginStore.shared.loginState.loginUserInfo?.userID ?? '';
    final profile = UserProfile(userID: userID, nickname: nickname, avatarURL: avatarURL);

    LoginStore.shared.setSelfInfo(userInfo: profile).then((result) {
      if (!mounted) return;
      _setLoading(false);

      if (result.isSuccess) {
        // Success
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileStatusSaved)));
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _navigateToFeatureList();
        });
      } else {
        // Failure
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileErrorSaveFailed(result.errorMessage ?? ''))));
      }
    });
  }

  // MARK: - Navigation

  void _navigateToFeatureList() {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const FeatureListPage()), (route) => false);
  }

  // MARK: - UI Helpers

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        automaticallyImplyLeading: false,
        actions: [
          // Skip button
          TextButton(onPressed: _isLoading ? null : _skipTapped, child: Text(l10n.profileSkip)),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Title
                  Text(
                    l10n.profileHeader,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    l10n.profileSubtitle,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Large preview of the currently selected avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                      color: Colors.grey[200],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _avatarURLs[_selectedAvatarIndex],
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Icon(Icons.person, size: 50),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Avatar selector (five options arranged horizontally)
                  SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_avatarURLs.length, (index) {
                        final isSelected = index == _selectedAvatarIndex;
                        return GestureDetector(
                          onTap: () => _avatarOptionTapped(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 44,
                            height: 44,
                            transform: isSelected ? (Matrix4.identity()..scale(1.1, 1.1)) : Matrix4.identity(),
                            transformAlignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                              color: Colors.grey[200],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _avatarURLs[index],
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 20),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Nickname input field + random nickname button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: l10n.profileNicknamePlaceholder,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Random nickname dice button
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(onPressed: _randomNicknameTapped, icon: const Icon(Icons.casino, size: 24)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Done button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmTapped,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                              : Text(l10n.profileConfirm),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
