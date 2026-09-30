// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#include "video_view/video_view_manager.h"

#include <windows.h>

#include <flutter/standard_method_codec.h>

namespace atomic_x_core {

namespace {

int64_t GetViewIdArg(const flutter::EncodableValue* args) {
  if (args == nullptr) {
    return -1;
  }
  const auto* args_map = std::get_if<flutter::EncodableMap>(args);
  if (args_map == nullptr) {
    return -1;
  }
  const auto it = args_map->find(flutter::EncodableValue("viewId"));
  if (it == args_map->end()) {
    return -1;
  }
  if (const auto* value64 = std::get_if<int64_t>(&it->second)) {
    return *value64;
  }
  if (const auto* value32 = std::get_if<int32_t>(&it->second)) {
    return *value32;
  }
  return -1;
}

std::string GetUserIdArg(const flutter::EncodableValue* args) {
  if (args == nullptr) {
    return std::string();
  }
  const auto* args_map = std::get_if<flutter::EncodableMap>(args);
  if (args_map == nullptr) {
    return std::string();
  }
  const auto it = args_map->find(flutter::EncodableValue("userId"));
  if (it == args_map->end()) {
    return std::string();
  }
  if (const auto* value = std::get_if<std::string>(&it->second)) {
    return *value;
  }
  return std::string();
}

int GetStreamTypeArg(const flutter::EncodableValue* args, int default_value) {
  if (args == nullptr) {
    return default_value;
  }
  const auto* args_map = std::get_if<flutter::EncodableMap>(args);
  if (args_map == nullptr) {
    return default_value;
  }
  const auto it = args_map->find(flutter::EncodableValue("streamType"));
  if (it == args_map->end()) {
    return default_value;
  }
  if (const auto* value = std::get_if<int32_t>(&it->second)) {
    return *value;
  }
  if (const auto* value64 = std::get_if<int64_t>(&it->second)) {
    return static_cast<int>(*value64);
  }
  return default_value;
}

}  // namespace

// static
VideoViewManager* VideoViewManager::GetInstance() {
  static VideoViewManager instance;
  return &instance;
}

void VideoViewManager::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar_ = registrar;
  channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "atomic_engine_video_view",
          &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });
}

void VideoViewManager::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const flutter::EncodableValue* args = call.arguments();

  if (call.method_name() == "createTextureView") {
    HandleCreateTextureView(result.get());
  } else if (call.method_name() == "setLocalTextureRender") {
    HandleSetLocalTextureRender(args, result.get());
  } else if (call.method_name() == "setRemoteTextureRender") {
    HandleSetRemoteTextureRender(args, result.get());
  } else if (call.method_name() == "setMixedTextureRender") {
    HandleSetMixedTextureRender(args, result.get());
  } else if (call.method_name() == "unsetLocalTextureRender") {
    HandleUnsetLocalTextureRender(args, result.get());
  } else if (call.method_name() == "unsetRemoteTextureRender") {
    HandleUnsetRemoteTextureRender(args, result.get());
  } else if (call.method_name() == "unsetMixedTextureRender") {
    HandleUnsetMixedTextureRender(result.get());
  } else if (call.method_name() == "unregisterTexture") {
    HandleUnregisterTexture(args, result.get());
  } else if (call.method_name() == "setRenderSize") {
    // Windows 上 Texture 按帧原始尺寸上屏，渲染尺寸由 Flutter 布局
    // 决定，此处与 OHOS 保留协议一致（OHOS 用于设置纹理缓冲尺寸），做空操作。
    result->Success(nullptr);
  } else {
    result->NotImplemented();
  }
}

void VideoViewManager::HandleCreateTextureView(
    flutter::MethodResult<flutter::EncodableValue>* result) {
  auto* api = TrtcCApi::GetInstance();
  if (!api->available()) {
    result->Error("liteav_unavailable",
                  "liteav.dll is not loaded; video rendering is unavailable.");
    return;
  }

  if (!GpuSurfaceRenderer::IsAvailable()) {
    result->Error("gpu_surface_unavailable",
                  "D3D11 is unavailable; GPU surface video rendering is not "
                  "supported in this environment (e.g. remote desktop).");
    return;
  }

  auto renderer = std::make_unique<GpuSurfaceRenderer>(registrar_);
  const int64_t texture_id = renderer->texture_id();
  if (texture_id == -1) {
    result->Error("texture_register_failed",
                  "Flutter texture registration failed.");
    return;
  }
  texture_map_[texture_id] = std::move(renderer);
  result->Success(flutter::EncodableValue(texture_id));
}

void VideoViewManager::HandleSetLocalTextureRender(
    const flutter::EncodableValue* args,
    flutter::MethodResult<flutter::EncodableValue>* result) {
  const int64_t view_id = GetViewIdArg(args);
  auto it = texture_map_.find(view_id);
  if (it == texture_map_.end()) {
    result->Error("view_not_found", "No texture for setLocalTextureRender.");
    return;
  }
  const int stream_type = GetStreamTypeArg(args, 0);

  auto* api = TrtcCApi::GetInstance();
  void* cloud = api->cloud();
  if (cloud == nullptr) {
    result->Error("cloud_unavailable", "liteav cloud is not available.");
    return;
  }

  std::lock_guard<std::mutex> lock(dispatcher_mutex_);
  if (!local_dispatcher_) {
    local_dispatcher_ = std::make_unique<VideoFrameDispatcher>("local");
    local_callback_ = api->CreateVideoRenderCallback(local_dispatcher_.get(),
                                                     &OnLocalRenderVideoFrame);
    if (local_callback_ == nullptr) {
      local_dispatcher_.reset();
      result->Error("callback_create_failed",
                    "CreateVideoRenderCallback failed (local).");
      return;
    }
    api->SetLocalVideoRenderCallback(cloud, kTrtcPixelFormatBGRA32,
                                     kTrtcBufferTypeBuffer, local_callback_);
  }
  local_dispatcher_->setRender(stream_type, it->second.get());
  result->Success(nullptr);
}

void VideoViewManager::HandleSetRemoteTextureRender(
    const flutter::EncodableValue* args,
    flutter::MethodResult<flutter::EncodableValue>* result) {
  const int64_t view_id = GetViewIdArg(args);
  auto it = texture_map_.find(view_id);
  if (it == texture_map_.end()) {
    result->Error("view_not_found", "No texture for setRemoteTextureRender.");
    return;
  }
  const std::string user_id = GetUserIdArg(args);
  if (user_id.empty()) {
    result->Error("invalid_args", "setRemoteTextureRender requires userId.");
    return;
  }
  const int stream_type = GetStreamTypeArg(args, 0);

  auto* api = TrtcCApi::GetInstance();
  void* cloud = api->cloud();
  if (cloud == nullptr) {
    result->Error("cloud_unavailable", "liteav cloud is not available.");
    return;
  }

  std::lock_guard<std::mutex> lock(dispatcher_mutex_);
  if (remote_dispatcher_map_.find(user_id) == remote_dispatcher_map_.end()) {
    auto dispatcher = std::make_unique<VideoFrameDispatcher>(user_id);
    void* callback = api->CreateVideoRenderCallback(
        dispatcher.get(), &OnRemoteRenderVideoFrame);
    if (callback == nullptr) {
      result->Error("callback_create_failed",
                    "CreateVideoRenderCallback failed (remote).");
      return;
    }
    api->SetRemoteVideoRenderCallback(cloud, user_id.c_str(),
                                      kTrtcPixelFormatBGRA32,
                                      kTrtcBufferTypeBuffer, callback);
    remote_dispatcher_map_[user_id] = std::move(dispatcher);
    remote_callback_map_[user_id] = callback;
  }
  remote_dispatcher_map_[user_id]->setRender(stream_type, it->second.get());
  result->Success(nullptr);
}

void VideoViewManager::HandleSetMixedTextureRender(
    const flutter::EncodableValue* args,
    flutter::MethodResult<flutter::EncodableValue>* result) {
  const int64_t view_id = GetViewIdArg(args);
  auto it = texture_map_.find(view_id);
  if (it == texture_map_.end()) {
    result->Error("view_not_found", "No texture for setMixedTextureRender.");
    return;
  }

  // 注册引擎转码帧回调。导出缺失（旧版引擎 dll）时报错，Dart 侧回退
  // CameraView 本地流路由。
  if (!EngineFrameBridge::SetMixedFrameHandler(&OnEngineMixedFrame)) {
    result->Error("engine_export_missing",
                  "AtomicEngine_SetMediaMixingFrameHandler is not available "
                  "in the loaded engine dll.");
    return;
  }

  std::lock_guard<std::mutex> lock(dispatcher_mutex_);
  mixed_handler_registered_ = true;
  mixed_renderer_ = it->second.get();
  result->Success(nullptr);
}

void VideoViewManager::HandleUnsetMixedTextureRender(
    flutter::MethodResult<flutter::EncodableValue>* result) {
  {
    std::lock_guard<std::mutex> lock(dispatcher_mutex_);
    // 传 nullptr：无条件清空混流绑定并反注册引擎回调。
    RemoveMixedRendererLocked(nullptr);
  }
  result->Success(nullptr);
}

void VideoViewManager::HandleUnsetLocalTextureRender(
    const flutter::EncodableValue* args,
    flutter::MethodResult<flutter::EncodableValue>* result) {
  const int stream_type = GetStreamTypeArg(args, 0);

  auto* api = TrtcCApi::GetInstance();
  void* cloud = api->cloud();

  std::lock_guard<std::mutex> lock(dispatcher_mutex_);
  if (local_dispatcher_) {
    local_dispatcher_->removeRender(stream_type);
    if (local_dispatcher_->isEmpty() && cloud != nullptr) {
      api->SetLocalVideoRenderCallback(cloud, kTrtcPixelFormatUnknown,
                                       kTrtcBufferTypeUnknown, nullptr);
      if (local_callback_ != nullptr) {
        api->DestroyVideoRenderCallback(local_callback_);
      }
      local_callback_ = nullptr;
      local_dispatcher_.reset();
    }
  }
  result->Success(nullptr);
}

void VideoViewManager::HandleUnsetRemoteTextureRender(
    const flutter::EncodableValue* args,
    flutter::MethodResult<flutter::EncodableValue>* result) {
  const std::string user_id = GetUserIdArg(args);
  const int stream_type = GetStreamTypeArg(args, 0);

  auto* api = TrtcCApi::GetInstance();
  void* cloud = api->cloud();

  std::lock_guard<std::mutex> lock(dispatcher_mutex_);
  auto it = remote_dispatcher_map_.find(user_id);
  if (it == remote_dispatcher_map_.end()) {
    result->Success(nullptr);
    return;
  }
  it->second->removeRender(stream_type);
  if (it->second->isEmpty()) {
    if (cloud != nullptr) {
      api->SetRemoteVideoRenderCallback(cloud, user_id.c_str(),
                                        kTrtcPixelFormatUnknown,
                                        kTrtcBufferTypeUnknown, nullptr);
    }
    const auto cb_it = remote_callback_map_.find(user_id);
    if (cb_it != remote_callback_map_.end()) {
      if (cb_it->second != nullptr) {
        api->DestroyVideoRenderCallback(cb_it->second);
      }
      remote_callback_map_.erase(cb_it);
    }
    remote_dispatcher_map_.erase(it);
  }
  result->Success(nullptr);
}

void VideoViewManager::HandleUnregisterTexture(
    const flutter::EncodableValue* args,
    flutter::MethodResult<flutter::EncodableValue>* result) {
  if (args == nullptr) {
    result->Error("invalid_args", "unregisterTexture requires textureId.");
    return;
  }
  const auto* args_map = std::get_if<flutter::EncodableMap>(args);
  int64_t texture_id = -1;
  if (args_map != nullptr) {
    const auto it = args_map->find(flutter::EncodableValue("textureId"));
    if (it != args_map->end()) {
      if (const auto* value64 = std::get_if<int64_t>(&it->second)) {
        texture_id = *value64;
      } else if (const auto* value32 = std::get_if<int32_t>(&it->second)) {
        texture_id = *value32;
      }
    }
  }

  auto it = texture_map_.find(texture_id);
  if (it == texture_map_.end()) {
    result->Success(nullptr);
    return;
  }
  RemoveRendererFromDispatchers(it->second.get());
  it->second->Dispose();
  texture_map_.erase(it);
  result->Success(nullptr);
}

void VideoViewManager::RemoveRendererFromDispatchers(
    GpuSurfaceRenderer* render) {
  auto* api = TrtcCApi::GetInstance();
  void* cloud = api->cloud();

  std::lock_guard<std::mutex> lock(dispatcher_mutex_);
  RemoveMixedRendererLocked(render);
  if (local_dispatcher_) {
    local_dispatcher_->onRenderWillDispose(render);
    if (local_dispatcher_->isEmpty()) {
      if (cloud != nullptr) {
        api->SetLocalVideoRenderCallback(cloud, kTrtcPixelFormatUnknown,
                                         kTrtcBufferTypeUnknown, nullptr);
      }
      if (local_callback_ != nullptr) {
        api->DestroyVideoRenderCallback(local_callback_);
      }
      local_callback_ = nullptr;
      local_dispatcher_.reset();
    }
  }
  for (auto it = remote_dispatcher_map_.begin();
       it != remote_dispatcher_map_.end();) {
    it->second->onRenderWillDispose(render);
    if (it->second->isEmpty()) {
      if (cloud != nullptr) {
        api->SetRemoteVideoRenderCallback(cloud, it->first.c_str(),
                                          kTrtcPixelFormatUnknown,
                                          kTrtcBufferTypeUnknown, nullptr);
      }
      const auto cb_it = remote_callback_map_.find(it->first);
      if (cb_it != remote_callback_map_.end()) {
        if (cb_it->second != nullptr) {
          api->DestroyVideoRenderCallback(cb_it->second);
        }
        remote_callback_map_.erase(cb_it);
      }
      it = remote_dispatcher_map_.erase(it);
    } else {
      ++it;
    }
  }
}

// static
void VideoViewManager::OnEngineMixedFrame(void* frame) {
  GetInstance()->DispatchMixedFrame(static_cast<TrtcVideoFrame*>(frame));
}

void VideoViewManager::DispatchMixedFrame(TrtcVideoFrame* frame) {
  if (frame == nullptr) {
    return;
  }
  GpuSurfaceRenderer* target = nullptr;
  {
    std::lock_guard<std::mutex> lock(dispatcher_mutex_);
    target = mixed_renderer_;
  }
  if (target != nullptr) {
    target->OnVideoFrame(frame);
  }
}

void VideoViewManager::RemoveMixedRendererLocked(GpuSurfaceRenderer* render) {
  if (render != nullptr && mixed_renderer_ != render) {
    return;
  }
  mixed_renderer_ = nullptr;
  if (mixed_handler_registered_) {
    EngineFrameBridge::SetMixedFrameHandler(nullptr);
    mixed_handler_registered_ = false;
  }
}

// static
void VideoViewManager::OnLocalRenderVideoFrame(void* instance,
                                               const char* user_id,
                                               int stream_type,
                                               TrtcVideoFrame* frame) {
  static_cast<VideoFrameDispatcher*>(instance)->onRenderVideoFrame(
      user_id, stream_type, frame);
}

// static
void VideoViewManager::OnRemoteRenderVideoFrame(void* instance,
                                                const char* user_id,
                                                int stream_type,
                                                TrtcVideoFrame* frame) {
  static_cast<VideoFrameDispatcher*>(instance)->onRenderVideoFrame(
      user_id, stream_type, frame);
}

}  // namespace atomic_x_core
