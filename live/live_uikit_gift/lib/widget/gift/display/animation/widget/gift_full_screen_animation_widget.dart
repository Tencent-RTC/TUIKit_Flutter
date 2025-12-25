import 'package:atomic_x_core/api/live/live_audience_store.dart';
import 'package:flutter/material.dart';

// import 'package:flutter_effect_player/ftceffect_player.dart';
import 'package:live_uikit_gift/live_uikit_gift.dart';
import 'package:live_uikit_gift/widget/gift/display/animation/manager/list_manager.dart';
import 'package:rtc_room_engine/api/room/tui_room_engine.dart';

import '../../../../../manager/cache/gift_cache_manager.dart';
import '../../../../svga_player/parser.dart';
import '../../../../svga_player/player.dart';
import '../../../../svga_player/proto/svga_pb.dart';

class GiftFullScreenAnimationWidget extends StatefulWidget {
  final String roomId;

  const GiftFullScreenAnimationWidget({super.key, required this.roomId});

  @override
  State<GiftFullScreenAnimationWidget> createState() => GiftFullScreenAnimationWidgetState();
}

class GiftFullScreenAnimationWidgetState extends State<GiftFullScreenAnimationWidget>
    with SingleTickerProviderStateMixin {
  late SVGAAnimationController _svgaAnimationController;
  late AnimationStatusListener _svgaAnimationStatusListener;

  // FTCEffectViewController? _effectViewController;
  // final FTCEffectConfig _effectConfig = FTCEffectConfig();

  ListManager<TUIGiftData> giftQueue = ListManager<TUIGiftData>(maxLength: 3);
  ValueNotifier<String> currentAnimationUrl = ValueNotifier('');

  bool get isTCEffectPlayerUsable => true;

  @override
  void initState() {
    super.initState();
    _svgaAnimationController = SVGAAnimationController(vsync: this);
    _svgaAnimationStatusListener = _onAnimationStatusChange;
    _svgaAnimationController.addStatusListener(_svgaAnimationStatusListener);
    TUIGiftStore().giftDataMap.addListener(_onReceiveGiftData);
  }

  @override
  void dispose() {
    TUIGiftStore().giftDataMap.value.remove(widget.roomId);
    TUIGiftStore().giftDataMap.removeListener(_onReceiveGiftData);
    _svgaAnimationController.removeStatusListener(_svgaAnimationStatusListener);
    _svgaAnimationController.dispose();
    // _effectViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: currentAnimationUrl,
        builder: (context, animationUrl, _) {
          return Stack(children: [
            // FTCEffectAnimView(
            //     controllerCallback: (controller) async {
            //       await _setupEffectViewController(controller);
            //       _playAnimation();
            //     }
            // ),
            SVGAImage(
              _svgaAnimationController,
              fit: BoxFit.contain,
              clearsAfterStop: true,
              allowDrawingOverflow: false,
              filterQuality: FilterQuality.low,
            )
          ]);
        });
  }

  Future<void> _playAnimation() async {
    final isAnimating = await _isAnimating();

    if (!mounted || isAnimating || giftQueue.count == 0) {
      return;
    }

    _resetAnimationPlayerIfNeeded();
    String? animationUrl = giftQueue
        .popFirst()
        ?.gift
        .resourceURL;
    if (animationUrl == null || animationUrl.isEmpty) return;

    final animationSourceType = _getSourceType(animationUrl);
    animationSourceType == AnimationSourceType.svga
        ? _playSVGAAnimation(animationUrl)
        : _playMP4Animation(animationUrl);
  }

  void _onReceiveGiftData() async {
    final giftData = TUIGiftStore().giftDataMap.value[widget.roomId];
    if (giftData == null) {
      return;
    }

    String animationUrl = giftData.gift.resourceURL;
    final animationSourceType = _getSourceType(animationUrl);
    if (animationSourceType == AnimationSourceType.other) {
      return;
    }

    _addGiftToQueue(giftData);
    final isAnimating = await _isAnimating();
    if (!isAnimating) {
      _playAnimation();
    }
  }

  Future<bool> _isAnimating() async {
    // final result = await _effectViewController?.isPlaying() ?? false;
    // return result || _svgaAnimationController.isAnimating;
    return _svgaAnimationController.isAnimating;
  }

  Widget _getAnimationWidget(String animationUrl) {
    // AnimationSourceType sourceType = _getSourceType(animationUrl);
    // if (isTCEffectPlayerUsable && sourceType == AnimationSourceType.mp4) {
    //   return FTCEffectAnimView(
    //     controllerCallback: (controller) async {
    //       await _setupEffectViewController(controller);
    //     },
    //   );
    // } else {
    //   return SVGAImage(
    //     _svgaAnimationController,
    //     fit: BoxFit.contain,
    //     clearsAfterStop: true,
    //     allowDrawingOverflow: false,
    //     filterQuality: FilterQuality.low,
    //   );
    // }

    return SVGAImage(
      _svgaAnimationController,
      fit: BoxFit.contain,
      clearsAfterStop: true,
      allowDrawingOverflow: false,
      filterQuality: FilterQuality.low,
    );
  }

  AnimationSourceType _getSourceType(String animationUrl) {
    if (animationUrl.isEmpty) {
      return AnimationSourceType.other;
    }

    final url = animationUrl.toLowerCase();
    if (url.endsWith('.mp4')) {
      return AnimationSourceType.mp4;
    }
    if (url.endsWith('.svga')) {
      return AnimationSourceType.svga;
    }
    return AnimationSourceType.other;
  }

  void _resetAnimationPlayerIfNeeded() {
    _svgaAnimationController.reset();
  }
}

extension SVGAPlayer on GiftFullScreenAnimationWidgetState {
  Future<void> _playSVGAAnimation(String animationUrl) async {
    try {
      final movieEntity = await _loadSvgaAndParseToMovieEntity(animationUrl);
      if (mounted) {
        _svgaAnimationController.movieEntity = movieEntity;
        currentAnimationUrl.value = animationUrl;
        _svgaAnimationController.forward();
      }
    } catch (e) {
      debugPrint("GiftFullScreenAnimationWidget SVGA load entity failed: $e");
      _playAnimation();
    }
  }

  Future<MovieEntity> _loadSvgaAndParseToMovieEntity(String image) async {
    if (image.startsWith(RegExp(r'https?://'))) {
      final fileStream = await GiftCacheManager.getCachedBytes(image);
      MovieEntity movieEntity = await SVGAParser.shared.decodeFromStream(fileStream);
      return movieEntity;
    } else {
      MovieEntity movieEntity = await SVGAParser.shared.decodeFromAssets(image);
      return movieEntity;
    }
  }

  void _onAnimationStatusChange(AnimationStatus status) {
    if (AnimationStatus.completed == status) {
      debugPrint("GiftFullScreenAnimationWidget _onSVGAAnimationStatusChange:completed stop");
      currentAnimationUrl.value = '';
      _svgaAnimationController.movieEntity = null;
      _playAnimation();
    }
  }
}

extension EffectPlayer on GiftFullScreenAnimationWidgetState {
  // Future<void> _setupEffectViewController(FTCEffectViewController controller) async {
  //   _effectViewController = controller;
  //   _effectViewController?.setPlayListener(FAnimPlayListener(
  //       onPlayStart: () {},
  //       onPlayEnd: () {
  //         debugPrint("GiftFullScreenAnimationWidget _onEffectPlayerAnimationStatusChange:completed stop");
  //         currentAnimationUrl.value = '';
  //         _playAnimation();
  //       },
  //       onPlayEvent: (int event, Map params) {},
  //       onPlayError: (code) {
  //         debugPrint("GiftFullScreenAnimationWidget _onEffectPlayerAnimationStatusChange:error code: $code");
  //         _playAnimation();
  //       }));
  // }

  Future<void> _playMP4Animation(String animationUrl) async {
    // try {
    //   currentAnimationUrl.value = animationUrl;
    //   final animationLocalPath = await _loadMp4Resource(animationUrl);
    //   _effectViewController?.setConfig(_effectConfig);
    //   FTCEffectViewController controller = _effectViewController!;
    //   controller.setVideoMode(FVideoMode.VIDEO_MODE_SPLIT_HORIZONTAL);
    //   controller.setScaleType(FScaleType.CENTER_CROP);
    //   await controller.startPlay(animationLocalPath);
    // } catch (e) {
    //   debugPrint("GiftFullScreenAnimationWidget MP4 load failed: $e");
    //   _playAnimation();
    // }
  }

  Future<String> _loadMp4Resource(String animationUrl) async {
    if (animationUrl.startsWith(RegExp(r'https?://'))) {
      return await GiftCacheManager.getCachedFilePath(animationUrl);
    } else {
      return '';
    }
  }
}

extension on GiftFullScreenAnimationWidgetState {
  void _addGiftToQueue(TUIGiftData giftData) {
    int firstOtherIndex = giftQueue.count;
    for (int i = 0; i < giftQueue.count; i++) {
      if (!giftQueue[i]!.sender.isSelf()) {
        firstOtherIndex = i;
        break;
      }
    }

    if (giftData.sender.isSelf()) {
      if (firstOtherIndex == 0) {
        giftQueue.insert(giftData, 0);
      } else {
        giftQueue.removeAt(firstOtherIndex);
        giftQueue.insert(giftData, firstOtherIndex);
      }
    } else {
      if (firstOtherIndex == 0 || firstOtherIndex > 1) {
        giftQueue.append(giftData);
      } else {
        giftQueue.removeAt(firstOtherIndex);
        giftQueue.append(giftData);
      }
    }
  }
}

extension on LiveUserInfo {
  bool isSelf() {
    return userID == TUIRoomEngine
        .getSelfInfo()
        .userId;
  }
}

enum AnimationSourceType { mp4, svga, other }
