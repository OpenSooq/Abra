import Foundation
import Photos
import AVFoundation

struct Permission {

  static var hasPermissions: Bool {
    return Photos.hasPermission && Camera.hasPermission && Microphone.hasPermissionOrAlreadyAsked
  }

  struct Photos {
    static var hasPermission: Bool {
      return PHPhotoLibrary.authorizationStatus() == .authorized
    }

    static func request(_ completion: @escaping () -> Void) {
      PHPhotoLibrary.requestAuthorization { status in
        completion()
      }
    }
  }

  struct Camera {
    static var hasPermission: Bool {
      return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized
    }

    static func request(_ completion: @escaping () -> Void) {
      AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
        completion()
      }
    }
  }
  
  struct Microphone {
    
    static var didAsk = false
    
    static var hasPermission: Bool {
      return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized
    }
    
    static var hasPermissionOrAlreadyAsked: Bool {
      if didAsk {
        return true
      }
      return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized
    }
    
    static func request(_ completion: @escaping () -> Void) {
      AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio) { granted in
        didAsk = true
        completion()
      }
    }
  }
}
