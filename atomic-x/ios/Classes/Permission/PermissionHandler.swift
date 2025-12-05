import Flutter
import AVFoundation
import Photos
import UserNotifications

/// Handles the actual permission logic for iOS platform.
class PermissionHandler {
  
  func requestPermissions(_ permissions: [String], result: @escaping FlutterResult) {
    var resultMap: [String: String] = [:]
    let group = DispatchGroup()

    for permission in permissions {
      group.enter()
      requestPermission(permission) { status in
        resultMap[permission] = status as? String ?? "denied"
        group.leave()
      }
    }

    group.notify(queue: .main) {
      result(resultMap)
    }
  }

  func openAppSettings() -> Bool {
    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
      return false
    }

    if UIApplication.shared.canOpenURL(settingsUrl) {
      UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
      return true
    }
    return false
  }

  func getPermissionStatus(_ permission: String) -> String {
    switch permission {
    case "camera":
      return getCameraPermissionStatus()
    case "photos":
      return getPhotosPermissionStatus()
    case "microphone":
      return getMicrophonePermissionStatus()
    case "notification":
      return getNotificationPermissionStatus()
    default:
      return "denied"
    }
  }

  // MARK: - Private Methods

  private func requestPermission(_ permission: String, result: @escaping FlutterResult) {
    switch permission {
    case "camera":
      requestCameraPermission(result: result)
    case "photos":
      requestPhotosPermission(result: result)
    case "microphone":
      requestMicrophonePermission(result: result)
    case "notification":
      requestNotificationPermission(result: result)
    default:
      result("denied")
    }
  }

  // MARK: - Camera Permission

  private func getCameraPermissionStatus() -> String {
    if #available(iOS 10.0, *) {
      let status = AVCaptureDevice.authorizationStatus(for: .video)
      switch status {
      case .authorized:
        return "granted"
      case .denied:
        return "permanentlyDenied"
      case .restricted:
        return "denied"
      case .notDetermined:
        return "denied"
      @unknown default:
        return "denied"
      }
    }
    return "denied"
  }

  private func requestCameraPermission(result: @escaping FlutterResult) {
    if #available(iOS 10.0, *) {
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          if granted {
            result("granted")
          } else {
            // iOS: Once denied, it's permanent until user changes in Settings
            result("permanentlyDenied")
          }
        }
      }
    } else {
      result("denied")
    }
  }

  // MARK: - Photos Permission

  private func getPhotosPermissionStatus() -> String {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      switch status {
      case .authorized:
        return "granted"
      case .limited:
        return "limited"
      case .denied:
        return "permanentlyDenied"
      case .restricted:
        return "denied"
      case .notDetermined:
        return "denied"
      @unknown default:
        return "denied"
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized:
        return "granted"
      case .denied:
        return "permanentlyDenied"
      case .restricted:
        return "denied"
      case .notDetermined:
        return "denied"
      @unknown default:
        return "denied"
      }
    }
  }

  private func requestPhotosPermission(result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
        DispatchQueue.main.async {
          switch status {
          case .authorized:
            result("granted")
          case .limited:
            result("limited")
          case .denied:
            // iOS: Once denied, it's permanent until user changes in Settings
            result("permanentlyDenied")
          case .restricted:
            // Restricted by system policy, treat as denied
            result("denied")
          case .notDetermined:
            result("denied")
          @unknown default:
            result("denied")
          }
        }
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
          switch status {
          case .authorized:
            result("granted")
          case .denied:
            // iOS: Once denied, it's permanent until user changes in Settings
            result("permanentlyDenied")
          case .restricted, .notDetermined:
            result("denied")
          @unknown default:
            result("denied")
          }
        }
      }
    }
  }

  // MARK: - Microphone Permission

  private func getMicrophonePermissionStatus() -> String {
    let status = AVAudioSession.sharedInstance().recordPermission
    switch status {
    case .granted:
      return "granted"
    case .denied:
      return "permanentlyDenied"
    case .undetermined:
      return "denied"
    @unknown default:
      return "denied"
    }
  }

  private func requestMicrophonePermission(result: @escaping FlutterResult) {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      DispatchQueue.main.async {
        if granted {
          result("granted")
        } else {
          // iOS: Once denied, it's permanent until user changes in Settings
          result("permanentlyDenied")
        }
      }
    }
  }

  // MARK: - Notification Permission

  private func getNotificationPermissionStatus() -> String {
    var status = "denied"
    let semaphore = DispatchSemaphore(value: 0)

    UNUserNotificationCenter.current().getNotificationSettings { settings in
      switch settings.authorizationStatus {
      case .authorized:
        status = "granted"
      case .denied:
        status = "permanentlyDenied"
      case .notDetermined:
        status = "denied"
      case .provisional, .ephemeral:
        status = "limited"
      @unknown default:
        status = "denied"
      }
      semaphore.signal()
    }

    semaphore.wait()
    return status
  }

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      DispatchQueue.main.async {
        if granted {
          result("granted")
        } else {
          // iOS: Once denied, it's permanent until user changes in Settings
          result("permanentlyDenied")
        }
      }
    }
  }
}
