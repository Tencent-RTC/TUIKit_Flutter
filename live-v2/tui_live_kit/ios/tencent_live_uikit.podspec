Pod::Spec.new do |s|
  s.name             = 'tencent_live_uikit'
  s.version          = '0.0.1'
  s.summary          = 'TUILiveKit Flutter 组件库的 iOS 承载层。'
  s.description      = <<-DESC
封装 Live 所需系统能力，以及 TEBeautyKit 面板和共享 TRTC 视频帧美颜处理。
                       DESC
  s.homepage         = 'https://trtc.io/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tencent' => 'trtc@tencent.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.resources = ['Resources/*.bundle', 'Resources/beauty_panel/*.json', 'Resources/beauty_panel/**/*.png']
  s.static_framework = true
  s.dependency 'Flutter'
  # Beauty and MP4 gifts share TencentEffect authorization.
  s.dependency 'TEBeautyKit/S1-07', '4.2.0.21'
  s.dependency 'TencentEffect_S1-07', '4.3.0.25'
  s.dependency 'TXLiteAVSDK_Professional'
  s.platform = :ios, '12.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
