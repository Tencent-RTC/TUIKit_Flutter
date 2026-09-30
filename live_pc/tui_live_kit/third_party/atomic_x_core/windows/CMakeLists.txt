cmake_minimum_required(VERSION 3.14)
# Flutter 工具要求插件的 CMake target 名必须是 <包名>_plugin（与
# generated_plugins.cmake 的 target_link_libraries 引用保持一致）。
set(PROJECT_NAME "atomic_x_core_plugin")
project(${PROJECT_NAME} LANGUAGES CXX)

# === AtomicXCore Windows 引擎产物分发（产物随包入库，windows/lib/） ===
# 引擎产物 AtomicXCore_Win.dll 由 atomic_engine 仓库编译产出：
#   python3 compile/win/build_atomic_engine_win.py -t x64
# 构建脚本会同步一份产物到本包 windows/lib/ 目录（dll / pdb 经 git lfs
# 入库），也可通过环境变量 ATOMIC_ENGINE_SDK_DIR 指向其他含 dll 的目录。
# 产物存在时随宿主 app 打包到 exe 旁（Dart FFI 按名
# open('AtomicXCore_Win.dll')）；缺失时仅告警不阻塞编译（MethodChannel
# 正常，引擎 FFI 功能不可用）。
set(ATOMIC_ENGINE_SDK_DIR "$ENV{ATOMIC_ENGINE_SDK_DIR}")
if(ATOMIC_ENGINE_SDK_DIR STREQUAL "")
  set(ATOMIC_ENGINE_SDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib")
endif()

set(ATOMIC_ENGINE_SDK_DLLS "")
if(EXISTS "${ATOMIC_ENGINE_SDK_DIR}")
  file(GLOB ATOMIC_ENGINE_SDK_DLLS "${ATOMIC_ENGINE_SDK_DIR}/*.dll")
  message(STATUS "atomic_x_core: AtomicXCore Windows SDK found: ${ATOMIC_ENGINE_SDK_DIR}")
else()
  message(WARNING
    "atomic_x_core: AtomicXCore Windows SDK not found at '${ATOMIC_ENGINE_SDK_DIR}'. "
    "Engine capabilities are unavailable until it is built "
    "(atomic_engine: python3 compile/win/build_atomic_engine_win.py -t x64) "
    "or ATOMIC_ENGINE_SDK_DIR is set.")
endif()

add_library(${PROJECT_NAME} SHARED
  "atomic_engine_plugin.cpp"
  "atomic_engine_plugin.h"
  "atomic_engine_plugin_c_api.cpp"
  "include/atomic_x_core/atomic_engine_plugin_c_api.h"
  "video_view/engine_frame_bridge.cc"
  "video_view/engine_frame_bridge.h"
  "video_view/gpu_surface_renderer.cpp"
  "video_view/gpu_surface_renderer.h"
  "video_view/video_frame_dispatcher.cpp"
  "video_view/video_frame_dispatcher.h"
  "video_view/trtc_c_api_dyn.h"
  "video_view/video_view_manager.cpp"
  "video_view/video_view_manager.h"
)
apply_standard_settings(${PROJECT_NAME})
# 源文件为 UTF-8 编码（含中文注释），显式指定避免 MSVC 按本地代码页解码。
target_compile_options(${PROJECT_NAME} PRIVATE /utf-8)
target_compile_definitions(${PROJECT_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
# 宿主 app 的 generated_plugin_registrant.cc 按 <包名>/xxx_plugin_c_api.h
# 形式 include 插件的 c_api 头，通过 INTERFACE include 目录暴露
# windows/include/（标准 Flutter Windows 插件布局）。
target_include_directories(${PROJECT_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PROJECT_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_BINARY_DIR}")
set_target_properties(${PROJECT_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_link_libraries(${PROJECT_NAME} PRIVATE flutter flutter_wrapper_plugin)

# 引擎 SDK dll 随插件一并分发到宿主 app 的 bundle（插件自身 dll 由
# flutter 工具经 $<TARGET_FILE:${PROJECT_NAME}> 自动收集）。
set(atomic_x_core_bundled_libraries
  "${ATOMIC_ENGINE_SDK_DLLS}"
  PARENT_SCOPE
)
