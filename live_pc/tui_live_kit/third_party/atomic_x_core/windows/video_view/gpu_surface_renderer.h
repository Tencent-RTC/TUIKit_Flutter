// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#ifndef ATOMIC_X_CORE_GPU_SURFACE_RENDERER_H_
#define ATOMIC_X_CORE_GPU_SURFACE_RENDERER_H_

#include <d3d11.h>
#include <wrl/client.h>

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <vector>

#include <flutter/plugin_registrar_windows.h>
#include <flutter/texture_registrar.h>
#include <flutter_texture_registrar.h>

#include "trtc_c_api_dyn.h"

namespace atomic_x_core {

class GpuSurfaceRenderer {
 public:
  static bool IsAvailable();

  GpuSurfaceRenderer(flutter::PluginRegistrarWindows* registrar);
  ~GpuSurfaceRenderer();

  GpuSurfaceRenderer(const GpuSurfaceRenderer&) = delete;
  GpuSurfaceRenderer& operator=(const GpuSurfaceRenderer&) = delete;

  int64_t texture_id() const { return texture_id_; }

  void OnVideoFrame(const TrtcVideoFrame* frame);

  void Dispose();

 private:
  bool EnsureTextureLocked(uint32_t width, uint32_t height);

  flutter::PluginRegistrarWindows* registrar_;
  flutter::TextureRegistrar* texture_registrar_ = nullptr;
  std::unique_ptr<flutter::TextureVariant> texture_variant_;
  int64_t texture_id_ = -1;

  std::mutex mutex_;
  Microsoft::WRL::ComPtr<ID3D11Texture2D> texture_;
  HANDLE shared_handle_ = nullptr;
  uint32_t texture_width_ = 0;
  uint32_t texture_height_ = 0;
  FlutterDesktopGpuSurfaceDescriptor descriptor_ = {};
  std::vector<uint8_t> convert_buffer_;
  std::vector<Microsoft::WRL::ComPtr<ID3D11Texture2D>> retired_textures_;
  std::atomic<bool> is_disposed_{false};
};

}  // namespace atomic_x_core

#endif  // ATOMIC_X_CORE_GPU_SURFACE_RENDERER_H_
