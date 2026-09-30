
Pod::Spec.new do |s|
  s.name             = 'atomic_x_core'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'AtomicXCore'
  s.platform = :ios, '12.0'
  s.static_framework = true
  # Keep C / ObjC headers project-level (not public) so they are not pulled
  # into the module umbrella; the Swift @objc plugin class is exposed via the
  # generated -Swift.h instead. This mirrors the working tencent_rtc_sdk pod.
  s.project_header_files = 'Classes/**/*.h'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
