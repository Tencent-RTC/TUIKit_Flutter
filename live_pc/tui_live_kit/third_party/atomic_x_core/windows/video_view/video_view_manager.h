// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#ifndef ATOMIC_X_CORE_VIDEO_VIEW_MANAGER_H_
#define ATOMIC_X_CORE_VIDEO_VIEW_MANAGER_H_

#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <string>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include "engine_frame_bridge.h"
#include "gpu_surface_renderer.h"
#include "trtc_c_api_dyn.h"
#include "video_frame_dispatcher.h"

namespace atomic_x_core {

// "atomic_engine_video_view" MethodChannel 的 Windows 实现。
//
// 纹理协议：createTextureView 创建 GPU 纹理（viewId == textureId），随后
// 由三类 bind 方法决定帧来源：
// - setLocalTextureRender / setRemoteTextureRender：TRTC 本地 / 远端流的
//   自定义渲染回调（setLocal/RemoteVideoRenderCallback → dispatcher）；
// - setMixedTextureRender：本地媒体合图（混流）画面，帧来自引擎转码模块
//   自身的 setVideoFrameRenderCallback（经引擎导出
//   AtomicEngine_SetMediaMixingFrameHandler 转发）——开播前（未
//   attachTRTC）即出画面，且不受 attach/detach 影响。引擎导出缺失
//   （旧版引擎）时返回错误，Dart 侧回退 CameraView 本地流路由（开播前
//   黑屏、开播后可见，与历史行为一致）。
class VideoViewManager {
 public:
  static VideoViewManager* GetInstance();

  void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

 private:
  VideoViewManager() = default;
  VideoViewManager(const VideoViewManager&) = delete;
  VideoViewManager& operator=(const VideoViewManager&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void HandleCreateTextureView(
      flutter::MethodResult<flutter::EncodableValue>* result);
  void HandleSetLocalTextureRender(
      const flutter::EncodableValue* args,
      flutter::MethodResult<flutter::EncodableValue>* result);
  void HandleSetRemoteTextureRender(
      const flutter::EncodableValue* args,
      flutter::MethodResult<flutter::EncodableValue>* result);
  void HandleSetMixedTextureRender(
      const flutter::EncodableValue* args,
      flutter::MethodResult<flutter::EncodableValue>* result);
  void HandleUnsetLocalTextureRender(
      const flutter::EncodableValue* args,
      flutter::MethodResult<flutter::EncodableValue>* result);
  void HandleUnsetRemoteTextureRender(
      const flutter::EncodableValue* args,
      flutter::MethodResult<flutter::EncodableValue>* result);
  void HandleUnsetMixedTextureRender(
      flutter::MethodResult<flutter::EncodableValue>* result);
  void HandleUnregisterTexture(
      const flutter::EncodableValue* args,
      flutter::MethodResult<flutter::EncodableValue>* result);

  void RemoveRendererFromDispatchers(GpuSurfaceRenderer* render);

  // 引擎混流帧回调（SDK 渲染线程）：路由到混流 renderer。
  static void OnEngineMixedFrame(void* frame);
  void DispatchMixedFrame(TrtcVideoFrame* frame);

  // 清理混流绑定：renderer 销毁或解绑时，混流纹理清零后反注册引擎回调。
  // 调用方须已持有 dispatcher_mutex_。
  void RemoveMixedRendererLocked(GpuSurfaceRenderer* render);

  static void OnLocalRenderVideoFrame(void* instance, const char* user_id,
                                      int stream_type,
                                      TrtcVideoFrame* frame);
  static void OnRemoteRenderVideoFrame(void* instance, const char* user_id,
                                       int stream_type,
                                       TrtcVideoFrame* frame);

  flutter::PluginRegistrarWindows* registrar_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  std::map<int64_t, std::unique_ptr<GpuSurfaceRenderer>> texture_map_;

  std::mutex dispatcher_mutex_;
  std::unique_ptr<VideoFrameDispatcher> local_dispatcher_;
  std::map<std::string, std::unique_ptr<VideoFrameDispatcher>>
      remote_dispatcher_map_;

  // 混流绑定（dispatcher_mutex_ 保护）：帧来自引擎转码回调，不经
  // (user_id, stream_type) 路由，通常至多一个 renderer。
  GpuSurfaceRenderer* mixed_renderer_ = nullptr;
  bool mixed_handler_registered_ = false;

  void* local_callback_ = nullptr;
  std::map<std::string, void*> remote_callback_map_;
};

}  // namespace atomic_x_core

#endif  // ATOMIC_X_CORE_VIDEO_VIEW_MANAGER_H_
