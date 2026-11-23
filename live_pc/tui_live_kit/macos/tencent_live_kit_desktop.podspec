#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tui_live_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'tencent_live_kit_desktop'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'tencent_live_kit_desktop/Sources/tui_live_kit/**/*.swift'

  # 隐私清单以资源束打包（不能进 source_files，否则 Xcode 把它当源码编译：
  # "no rule to process file ... PrivacyInfo.xcprivacy of type text.xml"）。
  s.resource_bundles = {
    'tencent_live_kit_desktop_privacy' => ['tencent_live_kit_desktop/Sources/tui_live_kit/PrivacyInfo.xcprivacy']
  }

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
