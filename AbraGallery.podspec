Pod::Spec.new do |s|
  s.name             = "AbraGallery"
  s.summary          = "Something good about gallery"
  s.version          = "1.0.0"
  s.homepage         = "https://github.com/OpenSooq/Abra.git"
  s.license          = 'MIT'
  s.author           = { "OpenSooq" => "ramzi.q@opensooq.com" }
  s.source           = {
    :git => "https://github.com/OpenSooq/Abra.git",
    :tag => s.version.to_s
  }
  s.social_media_url = 'https://www.facebook.com/opesnooq.engineering/'

  s.ios.deployment_target = '8.0'

  s.requires_arc = true
  s.source_files = 'Sources/**/*'
  s.resource = 'Resources/Gallery.bundle'
  s.frameworks = 'UIKit', 'Foundation', 'AVFoundation', 'Photos', 'PhotosUI', 'CoreLocation', 'AVKit'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
  
end
