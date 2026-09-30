// Copyright (c) 2026 Tencent. All rights reserved.
// Author: zackshi

#include "video_frame_dispatcher.h"

namespace atomic_x_core {

VideoFrameDispatcher::VideoFrameDispatcher(const std::string& user_id)
    : user_id_(user_id) {}

VideoFrameDispatcher::~VideoFrameDispatcher() {
  std::lock_guard<std::mutex> lock(mutex_);
  renders_.clear();
}

void VideoFrameDispatcher::setRender(int stream_type,
                                      GpuSurfaceRenderer* render) {
  std::lock_guard<std::mutex> lock(mutex_);
  renders_[stream_type] = render;
}

void VideoFrameDispatcher::removeRender(int stream_type) {
  std::lock_guard<std::mutex> lock(mutex_);
  renders_.erase(stream_type);
}

void VideoFrameDispatcher::onRenderWillDispose(GpuSurfaceRenderer* render) {
  if (render == nullptr) {
    return;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  for (auto it = renders_.begin(); it != renders_.end();) {
    if (it->second == render) {
      it = renders_.erase(it);
    } else {
      ++it;
    }
  }
}

bool VideoFrameDispatcher::isEmpty() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return renders_.empty();
}

void VideoFrameDispatcher::onRenderVideoFrame(const char* /*user_id*/,
                                               int stream_type,
                                               TrtcVideoFrame* frame) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = renders_.find(stream_type);
  if (it != renders_.end() && it->second != nullptr) {
    it->second->OnVideoFrame(frame);
  }
}

}  // namespace atomic_x_core
