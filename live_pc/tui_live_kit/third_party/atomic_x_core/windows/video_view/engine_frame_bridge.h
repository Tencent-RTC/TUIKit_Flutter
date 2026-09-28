// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#ifndef ATOMIC_X_CORE_ENGINE_FRAME_BRIDGE_H_
#define ATOMIC_X_CORE_ENGINE_FRAME_BRIDGE_H_

namespace atomic_x_core {

// 引擎（AtomicXCore_Win.dll）混流帧回调桥。
//
// 引擎把 liteav ITXLocalMediaTranscoding 的 setVideoFrameRenderCallback
//（BGRA32 / Buffer，"自定义显示混合后的画面"出口）转发为裸函数指针导出
// AtomicEngine_SetMediaMixingFrameHandler。本桥经 LoadLibrary + GetProcAddress
// 解析该导出——插件 dll 不链接引擎导入库，旧版引擎（无该导出）时安全降级
// 返回 false，调用方回退到 TRTC 本地流帧路由。
//
// 帧结构：liteav::TRTCVideoFrame*（与 trtc_c_api_dyn.h 的 TrtcVideoFrame
// 布局逐字段一致），仅在回调期间有效。
class EngineFrameBridge {
 public:
  // 注册 / 反注册引擎混流帧回调。引擎 dll 未加载或导出缺失时返回
  // false（注册方向）；反注册方向恒 true（无导出时无需清理）。
  static bool SetMixedFrameHandler(void (*handler)(void* frame));
};

}  // namespace atomic_x_core

#endif  // ATOMIC_X_CORE_ENGINE_FRAME_BRIDGE_H_
