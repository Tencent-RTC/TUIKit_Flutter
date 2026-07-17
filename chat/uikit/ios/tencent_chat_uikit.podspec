#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint tencent_chat_uikit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'tencent_chat_uikit'
  s.version          = '1.0.0'
  s.summary          = 'tencent_chat_uikit is a chat-specific UI library built on top of tuikit_atomic_x.'
  s.description      = <<-DESC
tencent_chat_uikit is a chat-specific UI library built on top of tuikit_atomic_x.
                       DESC
  s.homepage         = 'https://trtc.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tencent Cloud' => 'trtc@tencent.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'tuikit_atomic_x'
  s.dependency 'Masonry'
  s.dependency 'AlbumPickerCore', '~> 1.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.platform = :ios, '14.0'
  s.resources = 'Assets/**/*'
  s.frameworks = 'Photos', 'AVFoundation', 'UIKit', 'SwiftUI'
end
