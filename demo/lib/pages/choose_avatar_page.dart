import 'package:tuikit_atomic_x/atomicx.dart' hide AlertDialog;
import 'package:flutter/material.dart' hide IconButton;

class ChooseAvatarPage extends StatefulWidget {
  final String currentAvatarUrl;

  const ChooseAvatarPage({
    super.key,
    required this.currentAvatarUrl,
  });

  @override
  State<StatefulWidget> createState() => ChooseAvatarPageState();
}

class ChooseAvatarPageState extends State<ChooseAvatarPage> {
  late SemanticColorScheme colorsTheme;
  late AtomicLocalizations atomicLocale;

  final String _userFaceURL = "https://im.sdk.qcloud.com/download/tuikit-resource/avatar/avatar_%s.png";
  final int _userFaceCount = 26;
  List<String> userAvatars = [];
  String selectedAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _userFaceCount; i++) {
      userAvatars.add(_userFaceURL.replaceAll('%s', (i + 1).toString()));
    }

    selectedAvatarUrl = widget.currentAvatarUrl;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    atomicLocale = AtomicLocalizations.of(context);
    colorsTheme = BaseThemeProvider.colorsOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorsTheme.listColorDefault,
      appBar: AppBar(
        backgroundColor: colorsTheme.bgColorTopBar,
        scrolledUnderElevation: 0,
        leading: IconButton.buttonContent(
          content: IconOnlyContent(Icon(Icons.arrow_back_ios, color: colorsTheme.buttonColorPrimaryDefault)),
          type: ButtonType.noBorder,
          size: ButtonSize.l,
          onClick: () => Navigator.of(context).pop(),
        ),
        title: Text(
          atomicLocale.chooseAvatar,
          style: TextStyle(
            color: colorsTheme.textColorPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _submitAvatar,
            child: Text(
              atomicLocale.confirm,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorsTheme.buttonColorPrimaryDefault,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorsTheme.strokeColorPrimary,
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: userAvatars.length,
          itemBuilder: (context, index) {
            final avatarUrl = userAvatars[index];
            final isSelected = selectedAvatarUrl == avatarUrl;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedAvatarUrl = avatarUrl;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? colorsTheme.buttonColorPrimaryDefault : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitAvatar() async {
    if (selectedAvatarUrl.isNotEmpty && selectedAvatarUrl != widget.currentAvatarUrl) {
      if (mounted) {
        Navigator.of(context).pop(selectedAvatarUrl);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
