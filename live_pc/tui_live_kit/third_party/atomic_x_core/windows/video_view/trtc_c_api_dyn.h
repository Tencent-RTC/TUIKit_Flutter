// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#ifndef ATOMIC_X_CORE_TRTC_C_API_DYN_H_
#define ATOMIC_X_CORE_TRTC_C_API_DYN_H_

#include <windows.h>

#include <cstdint>

namespace atomic_x_core {


// TRTCVideoPixelFormat
constexpr int kTrtcPixelFormatUnknown = 0;
constexpr int kTrtcPixelFormatI420 = 1;
constexpr int kTrtcPixelFormatBGRA32 = 3;
constexpr int kTrtcPixelFormatRGBA32 = 5;

// TRTCVideoBufferType
constexpr int kTrtcBufferTypeUnknown = 0;
constexpr int kTrtcBufferTypeBuffer = 1;

// TRTCVideoStreamType
constexpr int kTrtcStreamTypeBig = 0;
constexpr int kTrtcStreamTypeSub = 2;

// trtc_video_frame_t
struct TrtcVideoFrame {
  int video_format;
  int buffer_type;
  void* texture;
  char* data;
  uint32_t length;
  uint32_t width;
  uint32_t height;
  uint64_t timestamp;
  int rotation;
};

typedef void (*TrtcOnRenderVideoFrameHandler)(void* instance,
                                               const char* user_id,
                                               int stream_type,
                                               TrtcVideoFrame* frame);

class TrtcCApi {
 public:
  static TrtcCApi* GetInstance() {
    static TrtcCApi instance;
    return &instance;
  }

  bool available() const { return loaded_; }

  void* cloud() {
    if (!loaded_) return nullptr;
    if (cloud_ == nullptr) {
      cloud_ = get_instance_(nullptr);
    }
    return cloud_;
  }

  void* CreateVideoRenderCallback(
      void* instance, TrtcOnRenderVideoFrameHandler handler) {
    return loaded_ ? create_render_cb_(instance, handler) : nullptr;
  }

  int SetLocalVideoRenderCallback(void* instance, int pixel_format,
                                  int buffer_type, void* callback) {
    return loaded_ ? set_local_cb_(instance, pixel_format, buffer_type,
                                   callback)
                   : -1;
  }

  int SetRemoteVideoRenderCallback(void* instance, const char* user_id,
                                   int pixel_format, int buffer_type,
                                   void* callback) {
    return loaded_ ? set_remote_cb_(instance, user_id, pixel_format,
                                    buffer_type, callback)
                   : -1;
  }

  void ResetVideoRenderCallback(void* callback) {
    if (loaded_ && callback != nullptr) {
      reset_cb_(callback);
    }
  }

  void DestroyVideoRenderCallback(void* callback) {
    if (loaded_ && callback != nullptr) {
      destroy_cb_(callback);
    }
  }

 private:
  TrtcCApi() { Load(); }
  TrtcCApi(const TrtcCApi&) = delete;
  TrtcCApi& operator=(const TrtcCApi&) = delete;

  void Load() {
    dll_ = ::LoadLibraryW(L"liteav.dll");
    if (dll_ == nullptr) {
      return;
    }
    get_instance_ = reinterpret_cast<PFN_GetInstance>(::GetProcAddress(
        dll_, "trtc_cloud_get_instance"));
    create_render_cb_ =
        reinterpret_cast<PFN_CreateRenderCb>(::GetProcAddress(
            dll_, "trtc_cloud_create_video_render_callback"));
    set_local_cb_ = reinterpret_cast<PFN_SetLocalCb>(::GetProcAddress(
        dll_, "trtc_cloud_set_local_video_render_callback"));
    set_remote_cb_ = reinterpret_cast<PFN_SetRemoteCb>(::GetProcAddress(
        dll_, "trtc_cloud_set_remote_video_render_callback"));
    reset_cb_ = reinterpret_cast<PFN_ResetCb>(::GetProcAddress(
        dll_, "trtc_cloud_reset_video_render_callback"));
    destroy_cb_ = reinterpret_cast<PFN_DestroyCb>(::GetProcAddress(
        dll_, "trtc_cloud_destroy_video_render_callback"));
    loaded_ = get_instance_ != nullptr && create_render_cb_ != nullptr &&
              set_local_cb_ != nullptr && set_remote_cb_ != nullptr &&
              reset_cb_ != nullptr && destroy_cb_ != nullptr;
    if (!loaded_) {
      ::FreeLibrary(dll_);
      dll_ = nullptr;
    }
  }

  typedef void* (*PFN_GetInstance)(void* context);
  typedef void* (*PFN_CreateRenderCb)(void* instance,
                                      TrtcOnRenderVideoFrameHandler handler);
  typedef int (*PFN_SetLocalCb)(void* instance, int pixel_format,
                               int buffer_type, void* callback);
  typedef int (*PFN_SetRemoteCb)(void* instance, const char* user_id,
                                 int pixel_format, int buffer_type,
                                 void* callback);
  typedef void (*PFN_ResetCb)(void* callback);
  typedef void (*PFN_DestroyCb)(void* callback);

  bool loaded_ = false;
  HMODULE dll_ = nullptr;
  void* cloud_ = nullptr;
  PFN_GetInstance get_instance_ = nullptr;
  PFN_CreateRenderCb create_render_cb_ = nullptr;
  PFN_SetLocalCb set_local_cb_ = nullptr;
  PFN_SetRemoteCb set_remote_cb_ = nullptr;
  PFN_ResetCb reset_cb_ = nullptr;
  PFN_DestroyCb destroy_cb_ = nullptr;
};

}  // namespace atomic_x_core

#endif  // ATOMIC_X_CORE_TRTC_C_API_DYN_H_
