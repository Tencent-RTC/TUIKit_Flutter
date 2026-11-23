#include "flutter_window.h"

#include <optional>

#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>
#include <windowsx.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Original WndProc of the Flutter view child window, captured before
// subclassing. The runner creates exactly one view, so a file-static is
// sufficient.
WNDPROC g_flutter_view_proc = nullptr;

// Resize hot-zone width in logical pixels (DPI-scaled at hit time); matches
// Win32Window::MessageHandler's WM_NCHITTEST border.
constexpr int kResizeBorderWidth = 8;

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

// static
LRESULT CALLBACK FlutterWindow::FlutterViewWndProc(HWND hwnd, UINT message,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
  if (message == WM_NCHITTEST) {
    // With the frameless client area covering the whole window, this child
    // view receives the edge hit test instead of the parent frame (the
    // engine answers HTCLIENT), which made the parent's resize hot zones
    // dead code. Forward edge hits with HTTRANSPARENT so Windows re-tests
    // the parent, whose WM_NCHITTEST maps them to HTTOP/HTLEFT/... and the
    // resize loop then sizes the top-level window. Returning the HT*
    // codes here directly would resize this child instead.
    HWND parent = ::GetParent(hwnd);
    if (parent != nullptr && !::IsZoomed(parent) && !::IsIconic(parent)) {
      POINT cursor{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      ::ScreenToClient(hwnd, &cursor);
      RECT client{};
      ::GetClientRect(hwnd, &client);
      UINT dpi = FlutterDesktopGetDpiForHWND(hwnd);
      const int border =
          static_cast<int>(kResizeBorderWidth * (dpi / 96.0));
      const bool on_edge = cursor.x < border ||
          cursor.x >= client.right - border || cursor.y < border ||
          cursor.y >= client.bottom - border;
      if (on_edge) {
        return HTTRANSPARENT;
      }
    }
  }
  return CallWindowProc(g_flutter_view_proc, hwnd, message, wparam, lparam);
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Subclass the Flutter view's window proc so edge hit tests can be
  // forwarded to the parent frame (restores window resizing; aligned with
  // macOS, where AppKit resizes frameless windows natively).
  HWND view_hwnd = flutter_controller_->view()->GetNativeWindow();
  g_flutter_view_proc = reinterpret_cast<WNDPROC>(
      GetWindowLongPtr(view_hwnd, GWLP_WNDPROC));
  SetWindowLongPtr(view_hwnd, GWLP_WNDPROC,
                   reinterpret_cast<LONG_PTR>(&FlutterWindow::FlutterViewWndProc));

  // Window control channel for the frameless (headless) title bar, aligned
  // with the macOS implementation (channel name and "startDragging").
  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "window_control",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleWindowControlCall(call, std::move(result));
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;
  if (flutter_controller_) {
    // Restore the view's original WndProc before the engine tears it down.
    HWND view_hwnd = flutter_controller_->view()->GetNativeWindow();
    if (view_hwnd != nullptr && g_flutter_view_proc != nullptr) {
      SetWindowLongPtr(view_hwnd, GWLP_WNDPROC,
                       reinterpret_cast<LONG_PTR>(g_flutter_view_proc));
      g_flutter_view_proc = nullptr;
    }
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::HandleWindowControlCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "startDragging") {
    // Enter the native move loop: release the button capture taken by
    // Flutter, then feed WM_NCLBUTTONDOWN/HTCAPTION to the window proc.
    ReleaseCapture();
    SendMessage(GetHandle(), WM_NCLBUTTONDOWN, HTCAPTION, 0);
    result->Success();
    return;
  }
  if (call.method_name() == "minimize") {
    ShowWindow(GetHandle(), SW_MINIMIZE);
    result->Success();
    return;
  }
  if (call.method_name() == "toggleMaximize") {
    ShowWindow(GetHandle(), IsZoomed(GetHandle()) ? SW_RESTORE : SW_MAXIMIZE);
    result->Success();
    return;
  }
  if (call.method_name() == "close") {
    PostMessage(GetHandle(), WM_CLOSE, 0, 0);
    result->Success();
    return;
  }
  result->NotImplemented();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;

    case WM_SIZE:
      // Notify Flutter about maximize / restore transitions so the title
      // bar button can swap between the maximize and restore icons.
      if (window_channel_) {
        const bool maximized = (wparam == SIZE_MAXIMIZED);
        if (maximized != was_maximized_) {
          was_maximized_ = maximized;
          window_channel_->InvokeMethod(
              "onMaximizedChanged",
              std::make_unique<flutter::EncodableValue>(maximized));
        }
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
