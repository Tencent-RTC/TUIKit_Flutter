
Pod::Spec.new do |s|
  s.name             = 'atomic_x_core'
  s.version= '0.0.1'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '11.0'
  s.static_framework = true
  # Keep C / ObjC headers project-level (not public) so they are not pulled
  # into the module umbrella; the Swift @objc plugin class is exposed via the
  # generated -Swift.h instead. This mirrors the working iOS pod.
  s.project_header_files = 'Classes/**/*.h'

  # Engine binary is distributed via CocoaPods trunk as the AtomicXCore_Mac
  # pod (pushed from the atomic_engine release pipeline; the xcframework is
  # hosted on the official download site). TRTC / TXFFmpeg / TXSoundTouch
  # come transitively from TXLiteAVSDK_TRTC_Mac, and IM from
  # TXIMSDK_Plus_Mac, both declared by the AtomicXCore_Mac podspec.
  #
  # NOTE: AtomicXCore_Mac's podspec does NOT pin TRTC/IM versions, and the
  # TRTC build used for local engine development (13.4.21082) is not
  # available on trunk. C++ vtable layouts differ across TRTC versions, and
  # any build/runtime mismatch may crash with SIGSEGV on API calls into
  # ITXLocalMediaTranscoding; 13.5.21355 itself crashes on Intel/AMD Macs in
  # the local media transcoding (multi-source mixing) Metal path. TRTC is
  # therefore pinned HERE instead of in every host app's Podfile (dependency
  # constraints from all podspecs merge during resolution), so integrators
  # get the aligned version with zero extra configuration.
  # Known gap: 13.4.21067 lacks 5 BaseBeautyModule C symbols added in
  # 13.4.21082 (trtc_cloud_get_beauty_manager / tx_beauty_manager_set_*).
  # They are lazily bound: calling BaseBeautyStore beauty APIs crashes on
  # 13.4.21067, everything else is unaffected. Re-pin when a TRTC build
  # containing them reaches trunk.
  s.dependency 'AtomicXCore_Mac'
  s.dependency 'TXLiteAVSDK_TRTC_Mac', '= 13.4.21067'

  s.frameworks = [
    'AppKit', 'Foundation', 'SystemConfiguration', 'AVFoundation',
    'CoreMedia', 'CoreVideo', 'AudioToolbox', 'VideoToolbox',
    'Security', 'CoreGraphics', 'CFNetwork'
  ]
  s.libraries = ['c++', 'sqlite3', 'resolv']

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
