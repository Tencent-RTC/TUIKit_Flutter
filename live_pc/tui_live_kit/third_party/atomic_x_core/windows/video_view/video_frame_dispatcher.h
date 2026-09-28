// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#ifndef ATOMIC_X_CORE_VIDEO_FRAME_DISPATCHER_H_
#define ATOMIC_X_CORE_VIDEO_FRAME_DISPATCHER_H_

#include <map>
#include <mutex>
#include <string>

#include "gpu_surface_renderer.h"

namespace atomic_x_core {

class VideoFrameDispatcher {
 public:
  explicit VideoFrameDispatcher(const std::string& user_id);
  ~VideoFrameDispatcher();

  VideoFrameDispatcher(const VideoFrameDispatcher&) = delete;
  VideoFrameDispatcher& operator=(const VideoFrameDispatcher&) = delete;

  void setRender(int stream_type, GpuSurfaceRenderer* render);

  void removeRender(int stream_type);

  void onRenderWillDispose(GpuSurfaceRenderer* render);

  bool isEmpty() const;

  const std::string& user_id() const { return user_id_; }

  void onRenderVideoFrame(const char* user_id, int stream_type,
                           TrtcVideoFrame* frame);

 private:
  std::string user_id_;
  mutable std::mutex mutex_;
  std::map<int, GpuSurfaceRenderer*> renders_;
};

}  // namespace atomic_x_core

#endif  // ATOMIC_X_CORE_VIDEO_FRAME_DISPATCHER_H_
