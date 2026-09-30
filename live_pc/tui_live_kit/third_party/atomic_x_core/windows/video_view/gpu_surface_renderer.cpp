// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#include "video_view/gpu_surface_renderer.h"

#include <cstring>

#include <dxgi.h>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

namespace atomic_x_core {

namespace {

struct SharedD3D {
  ID3D11Device* device = nullptr;
  ID3D11DeviceContext* context = nullptr;
};

SharedD3D* GetSharedD3D() {
  static SharedD3D* shared = []() -> SharedD3D* {
    auto* d3d = new SharedD3D();
    UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
    HRESULT hr = D3D11CreateDevice(
        nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags, nullptr, 0,
        D3D11_SDK_VERSION, &d3d->device, nullptr, &d3d->context);
    if (FAILED(hr)) {
      hr = D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_WARP, nullptr, flags,
                             nullptr, 0, D3D11_SDK_VERSION, &d3d->device,
                             nullptr, &d3d->context);
    }
    if (FAILED(hr) || d3d->device == nullptr) {
      delete d3d;
      return nullptr;
    }
    return d3d;
  }();
  return shared;
}

void ConvertI420ToBGRA(const uint8_t* yuv, uint8_t* bgra, uint32_t width,
                       uint32_t height) {
  const uint32_t y_size = width * height;
  const uint32_t uv_stride = (width & 1) ? ((width + 1) / 2) : (width / 2);
  const uint32_t uv_height = (height & 1) ? ((height + 1) / 2) : (height / 2);
  const uint32_t uv_size = uv_stride * uv_height;
  const uint8_t* y_plane = yuv;
  const uint8_t* u_plane = yuv + y_size;
  const uint8_t* v_plane = yuv + y_size + uv_size;

  for (uint32_t row = 0; row < height; ++row) {
    for (uint32_t col = 0; col < width; ++col) {
      int y_val = y_plane[row * width + col];
      int u_val = u_plane[(row / 2) * uv_stride + (col / 2)] - 128;
      int v_val = v_plane[(row / 2) * uv_stride + (col / 2)] - 128;

      int r = y_val + ((359 * v_val) >> 8);
      int g = y_val - ((88 * u_val + 183 * v_val) >> 8);
      int b = y_val + ((454 * u_val) >> 8);

      r = (r < 0) ? 0 : (r > 255) ? 255 : r;
      g = (g < 0) ? 0 : (g > 255) ? 255 : g;
      b = (b < 0) ? 0 : (b > 255) ? 255 : b;

      uint32_t index = (row * width + col) * 4;
      bgra[index + 0] = static_cast<uint8_t>(b);
      bgra[index + 1] = static_cast<uint8_t>(g);
      bgra[index + 2] = static_cast<uint8_t>(r);
      bgra[index + 3] = 255;
    }
  }
}

}  // namespace

// static
bool GpuSurfaceRenderer::IsAvailable() { return GetSharedD3D() != nullptr; }

GpuSurfaceRenderer::GpuSurfaceRenderer(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  texture_registrar_ = registrar_->texture_registrar();
  texture_variant_ =
      std::make_unique<flutter::TextureVariant>(flutter::GpuSurfaceTexture(
          kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
          [this](size_t /*width*/, size_t /*height*/)
              -> const FlutterDesktopGpuSurfaceDescriptor* {
            std::lock_guard<std::mutex> lock(mutex_);
            if (texture_ == nullptr) {
              return nullptr;
            }
            return &descriptor_;
          }));
  texture_id_ = texture_registrar_->RegisterTexture(texture_variant_.get());
  if (texture_id_ == -1 || texture_id_ == 0) {
    texture_variant_.reset();
    texture_registrar_ = nullptr;
    texture_id_ = -1;
  }
}

GpuSurfaceRenderer::~GpuSurfaceRenderer() { Dispose(); }

bool GpuSurfaceRenderer::EnsureTextureLocked(uint32_t width, uint32_t height) {
  if (texture_ != nullptr && texture_width_ == width &&
      texture_height_ == height) {
    return true;
  }

  auto* d3d = GetSharedD3D();
  if (d3d == nullptr) {
    return false;
  }

  if (texture_ != nullptr) {
    retired_textures_.push_back(std::move(texture_));
    shared_handle_ = nullptr;
  }

  D3D11_TEXTURE2D_DESC desc = {};
  desc.Width = width;
  desc.Height = height;
  desc.MipLevels = 1;
  desc.ArraySize = 1;
  desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  desc.SampleDesc.Count = 1;
  desc.Usage = D3D11_USAGE_DEFAULT;
  desc.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
  desc.CPUAccessFlags = 0;
  desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED;
  if (FAILED(d3d->device->CreateTexture2D(&desc, nullptr,
                                          texture_.GetAddressOf())) ||
      texture_ == nullptr) {
    texture_.Reset();
    return false;
  }

  Microsoft::WRL::ComPtr<IDXGIResource> dxgi_resource;
  if (FAILED(texture_.As(&dxgi_resource)) || dxgi_resource == nullptr) {
    texture_.Reset();
    return false;
  }
  HANDLE handle = nullptr;
  const HRESULT hr = dxgi_resource->GetSharedHandle(&handle);
  if (FAILED(hr) || handle == nullptr) {
    texture_.Reset();
    return false;
  }

  texture_width_ = width;
  texture_height_ = height;
  shared_handle_ = handle;

  descriptor_ = {};
  descriptor_.struct_size = sizeof(descriptor_);
  descriptor_.handle = shared_handle_;
  descriptor_.width = width;
  descriptor_.height = height;
  descriptor_.visible_width = width;
  descriptor_.visible_height = height;
  descriptor_.format = kFlutterDesktopPixelFormatBGRA8888;
  return true;
}

void GpuSurfaceRenderer::OnVideoFrame(const TrtcVideoFrame* frame) {
  if (!frame || frame->width == 0 || frame->height == 0) {
    return;
  }
  if (is_disposed_) {
    return;
  }

  std::lock_guard<std::mutex> lock(mutex_);
  if (is_disposed_) {
    return;
  }

  if (!EnsureTextureLocked(frame->width, frame->height)) {
    return;
  }

  auto* d3d = GetSharedD3D();
  if (d3d == nullptr) {
    return;
  }

  const uint8_t* upload_data = nullptr;
  if (frame->video_format == kTrtcPixelFormatBGRA32 &&
      frame->data != nullptr) {
    upload_data = reinterpret_cast<const uint8_t*>(frame->data);
  } else if (frame->video_format == kTrtcPixelFormatI420 &&
             frame->data != nullptr) {
    const size_t bgra_size =
        static_cast<size_t>(frame->width) * frame->height * 4;
    if (convert_buffer_.size() != bgra_size) {
      try {
        convert_buffer_.resize(bgra_size);
      } catch (const std::bad_alloc&) {
        return;
      }
    }
    ConvertI420ToBGRA(reinterpret_cast<const uint8_t*>(frame->data),
                      convert_buffer_.data(), frame->width, frame->height);
    upload_data = convert_buffer_.data();
  } else {
    return;
  }

  D3D11_BOX box = {0, 0, 0, frame->width, frame->height, 1};
  d3d->context->UpdateSubresource(texture_.Get(), 0, &box, upload_data,
                                  frame->width * 4, 0);
  d3d->context->Flush();

  if (texture_registrar_ != nullptr && texture_id_ != -1) {
    texture_registrar_->MarkTextureFrameAvailable(texture_id_);
  }
}

void GpuSurfaceRenderer::Dispose() {
  if (is_disposed_.exchange(true)) {
    return;
  }

  {
    std::lock_guard<std::mutex> lock(mutex_);
    texture_.Reset();
    retired_textures_.clear();
  }

  if (texture_registrar_ != nullptr && texture_id_ != -1) {
    texture_registrar_->UnregisterTexture(texture_id_);
  }
  texture_variant_.reset();
  texture_registrar_ = nullptr;
  texture_id_ = -1;
}

}  // namespace atomic_x_core
