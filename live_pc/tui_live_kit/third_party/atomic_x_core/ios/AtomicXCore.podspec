Pod::Spec.new do |spec|
  spec.name = 'AtomicXCore'
  spec.version = '1.0.0'
  spec.summary = 'AtomicXCore.xcframework wrapper pod with native dependencies.'
  spec.homepage = 'https://example.com/atomic-engine'
  spec.license = { :type => 'Proprietary', :text => 'Tencent proprietary.' }
  spec.authors = { 'Tencent' => 'atomic-engine@tencent.com' }
  spec.platform = :ios, '12.0'
  spec.source = { :path => '.' }

  spec.vendored_frameworks = 'Frameworks/AtomicXCore.xcframework'

  spec.dependency 'TXIMSDK_Plus_iOS_XCFramework'
  spec.dependency 'TXLiteAVSDK_Professional'

  spec.frameworks = ['CoreTelephony', 'Foundation', 'SystemConfiguration', 'UIKit']
  spec.libraries = ['c++', 'sqlite3']

  spec.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
end
