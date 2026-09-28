import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Default launch size; the minimum size is smaller (1300x700).
  private let defaultContentSize = NSSize(width: 1300, height: 850)
  private let minContentSize = NSSize(width: 1300, height: 700)
  private let topBarHeight: CGFloat = 44
  /// 交通灯左侧起点与按钮间距。
  private let trafficLightLeftPadding: CGFloat = 13
  private let trafficLightSpacing: CGFloat = 6

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.setContentSize(defaultContentSize)
    self.minSize = minContentSize
    self.center()

    // 无标题栏：内容延伸到标题栏区域，保留系统交通灯。
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = false

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 窗口拖拽通道：由 Flutter 顶栏空白区触发 performDrag。
    let channel = FlutterMethodChannel(
      name: "window_control",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "startDragging":
        if let event = NSApp.currentEvent {
          self?.performDrag(with: event)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // 首次定位延后一帧：awakeFromNib 阶段按钮所在的标题栏容器尚未完成布局，
    // 立即定位会读到未就绪的尺寸。
    DispatchQueue.main.async { [weak self] in
      self?.repositionTrafficLights()
    }
    // 系统会在 resize / 成为 key / 结束实时缩放 / 全屏切换等时机重置按钮位置，
    // 逐一补偿以保持对齐。
    let center = NotificationCenter.default
    for name in [
      NSWindow.didResizeNotification,
      NSWindow.didBecomeKeyNotification,
      NSWindow.didEndLiveResizeNotification,
      NSWindow.didEnterFullScreenNotification,
      NSWindow.didExitFullScreenNotification,
    ] {
      center.addObserver(
        self,
        selector: #selector(repositionTrafficLights),
        name: name,
        object: self)
    }

    super.awakeFromNib()
  }

  /// 将系统交通灯垂直居中于 topBarHeight 顶栏并左对齐。
  ///
  /// 关键：`setFrameOrigin` 的坐标系是按钮的**父视图（标题栏容器）**，
  /// 不是 contentView。二者高度不同，用 contentView 高度换算会得到越界的
  /// y 值，被系统钳制回默认位置（表现为偏上、未在顶栏居中）。
  /// 因此这里以按钮父视图的高度为基准换算。macOS 坐标原点在左下角。
  @objc private func repositionTrafficLights() {
    let buttonTypes: [NSWindow.ButtonType] = [
      .closeButton, .miniaturizeButton, .zoomButton,
    ]
    let buttons = buttonTypes.compactMap { self.standardWindowButton($0) }
    guard let containerHeight = buttons.first?.superview?.bounds.height else {
      return
    }

    var x = trafficLightLeftPadding
    for button in buttons {
      let size = button.frame.size
      // 容器顶部与窗口顶部对齐；令按钮中心距顶 topBarHeight/2。
      let y = containerHeight - (topBarHeight + size.height) / 2
      button.setFrameOrigin(NSPoint(x: x, y: y))
      x += size.width + trafficLightSpacing
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
