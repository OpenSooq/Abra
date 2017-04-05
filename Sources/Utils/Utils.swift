import UIKit
import AVFoundation
import Photos

struct Utils {

  static func rotationTransform() -> CGAffineTransform {
    switch UIDevice.current.orientation {
    case .landscapeLeft:
      return CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
    case .landscapeRight:
      return CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
    case .portraitUpsideDown:
      return CGAffineTransform(rotationAngle: CGFloat(M_PI))
    default:
      return CGAffineTransform.identity
    }
  }

  static func videoOrientation() -> AVCaptureVideoOrientation {
    switch UIDevice.current.orientation {
    case .portrait:
      return .portrait
    case .landscapeLeft:
      return .landscapeRight
    case .landscapeRight:
      return .landscapeLeft
    case .portraitUpsideDown:
      return .portraitUpsideDown
    default:
      return .portrait
    }
  }

  static func fetchOptions() -> PHFetchOptions {
    let options = PHFetchOptions()
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    if let fetchLimit = Config.Fetch.limit {
      if #available(iOS 9.0, *) {
          options.fetchLimit = fetchLimit
      } else {
          // Fallback on earlier versions
      }
    }
    return options
  }

  static func format(_ duration: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.zeroFormattingBehavior = .pad

    if duration >= 3600 {
      formatter.allowedUnits = [.hour, .minute, .second]
    } else {
      formatter.allowedUnits = [.minute, .second]
    }

    return formatter.string(from: duration) ?? ""
  }
}
