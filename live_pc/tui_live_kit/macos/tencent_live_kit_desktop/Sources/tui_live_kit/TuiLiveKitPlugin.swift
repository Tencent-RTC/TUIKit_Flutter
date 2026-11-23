import Cocoa
import FlutterMacOS

/// tui_live_kit macOS plugin.
///
/// Current capability: Security-Scoped Bookmarks.
/// Under the App Sandbox, files picked via NSOpenPanel are readable only for
/// the lifetime of the process (entitlement
/// com.apple.security.files.user-selected.read-only); the authorization is
/// lost on relaunch. Bookmarks persist that authorization: create a bookmark
/// when the file is picked and store it in the local snapshot, then resolve
/// the bookmark on the next launch to regain access.
///
/// Access lifecycle: resolve activates the security scope and holds it;
/// "releaseAccess" (called when the owning media source is removed) or
/// detachFromEngine stops accessing. startAccessing/stopAccessing are
/// reference-counted per URL, so every activation must be balanced.
public class TuiLiveKitPlugin: NSObject, FlutterPlugin {
  /// URLs whose security scope is currently active (deduplicated by path).
  ///
  /// Guarded by [accessedURLsLock]. Method-channel handlers are dispatched
  /// on the main thread today, so there is no actual race; the lock keeps
  /// the invariant safe if dispatch ever moves off the main thread
  /// (background channels / multiple engines).
  private static var accessedURLs: [URL] = []
  private static let accessedURLsLock = NSLock()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tui_live_kit", binaryMessenger: registrar.messenger)
    let instance = TuiLiveKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createBookmark":
      handleCreateBookmark(call, result: result)
    case "resolveBookmark":
      handleResolveBookmark(call, result: result)
    case "releaseAccess":
      handleReleaseAccess(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Balances every startAccessingSecurityScopedResource: called when the
  /// owning media source is removed, and as a catch-all on engine detach.
  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    Self.accessedURLsLock.lock()
    let urls = Self.accessedURLs
    Self.accessedURLs.removeAll()
    Self.accessedURLsLock.unlock()
    for url in urls {
      url.stopAccessingSecurityScopedResource()
    }
  }

  /// Input: file path string. Returns: base64-encoded bookmark.
  private func handleCreateBookmark(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let path = call.arguments as? String, !path.isEmpty else {
      result(FlutterError(code: "bad_args", message: "path required", details: nil))
      return
    }
    let url = URL(fileURLWithPath: path)
    do {
      // .securityScopeAllowOnlyReadAccess is required: the app's file access
      // is read-only (files.user-selected.read-only), and bookmarkData fails
      // without it (NSCocoaErrorDomain 256 "Could not open() the item").
      let data = try url.bookmarkData(
        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      result(data.base64EncodedString())
    } catch {
      let nsError = error as NSError
      result(FlutterError(
        code: "bookmark_create_failed",
        message: error.localizedDescription,
        details: "domain=\(nsError.domain) code=\(nsError.code) userInfo=\(nsError.userInfo)"
      ))
    }
  }

  /// Input: base64-encoded bookmark. Returns: {path, refreshedBookmark?}.
  /// On success the security scope is activated and held; when the bookmark
  /// is stale a rebuilt bookmark is returned and the caller should update
  /// its snapshot.
  private func handleResolveBookmark(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let base64 = call.arguments as? String,
          let data = Data(base64Encoded: base64) else {
      result(FlutterError(code: "bad_args", message: "base64 bookmark required", details: nil))
      return
    }
    var stale = false
    do {
      let url = try URL(
        resolvingBookmarkData: data,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      )
      // Deduplicate by path (not URL equality): a URL resolved from a
      // bookmark may differ structurally from one built via
      // URL(fileURLWithPath:), so URL equality could miss duplicates and
      // double-hold the scope. releaseAccess also compares by path, keeping
      // activation and release consistent.
      Self.accessedURLsLock.lock()
      var accessGranted = Self.accessedURLs.contains(where: { $0.path == url.path })
      if !accessGranted && url.startAccessingSecurityScopedResource() {
        Self.accessedURLs.append(url)
        accessGranted = true
      }
      Self.accessedURLsLock.unlock()
      // A false from startAccessingSecurityScopedResource on a freshly
      // resolved security-scoped URL means the sandbox grant was NOT
      // activated — continuing would hand the engine an unreadable path.
      guard accessGranted else {
        result(FlutterError(
          code: "bookmark_access_denied",
          message: "Failed to start accessing security-scoped resource",
          details: url.path
        ))
        return
      }
      var refreshed: String? = nil
      if stale,
         let newData = try? url.bookmarkData(
           options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
           includingResourceValuesForKeys: nil,
           relativeTo: nil
         ) {
        refreshed = newData.base64EncodedString()
      }
      result(["path": url.path, "refreshedBookmark": refreshed as Any])
    } catch {
      result(FlutterError(code: "bookmark_resolve_failed", message: error.localizedDescription, details: nil))
    }
  }

  /// Input: file path string. Stops accessing the security scope for the
  /// file, balancing the activation done in handleResolveBookmark.
  private func handleReleaseAccess(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let path = call.arguments as? String, !path.isEmpty else {
      result(FlutterError(code: "bad_args", message: "path required", details: nil))
      return
    }
    Self.accessedURLsLock.lock()
    let heldURL = Self.accessedURLs.first(where: { $0.path == path })
    if let heldURL {
      Self.accessedURLs.removeAll { $0.path == path }
    }
    Self.accessedURLsLock.unlock()
    heldURL?.stopAccessingSecurityScopedResource()
    result(nil)
  }
}
