import Foundation
import AVFoundation
import PhotosUI
import Photos

protocol CameraManDelegate: class {
  func cameraManNotAvailable(_ cameraMan: CameraMan)
  func cameraManDidStart(_ cameraMan: CameraMan)
  func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput)
}

class CameraMan {
  weak var delegate: CameraManDelegate?

  let session = AVCaptureSession()
  let queue = DispatchQueue(label: "no.hyper.Gallery.Camera.SessionQueue", qos: .background)
  let savingQueue = DispatchQueue(label: "no.hyper.Gallery.Camera.SavingQueue", qos: .background)

  var backCamera: AVCaptureDeviceInput?
  var frontCamera: AVCaptureDeviceInput?
  var stillImageOutput: AVCaptureStillImageOutput?
  var movieOutput: ClosuredAVCaptureMovieFileOutput?

  deinit {
    stop()
  }

  // MARK: - Setup

  func setup() {
    if Permission.Camera.hasPermission {
      self.start()
    } else {
      self.delegate?.cameraManNotAvailable(self)
    }
  }

  func setupDevices() {
    // Input
    AVCaptureDevice
      .devices().flatMap {
        return $0 as? AVCaptureDevice
      }.filter {
        return $0.hasMediaType(AVMediaTypeVideo)
      }.forEach {
        switch $0.position {
        case .front:
          self.frontCamera = try? AVCaptureDeviceInput(device: $0)
        case .back:
          self.backCamera = try? AVCaptureDeviceInput(device: $0)
        default:
          break
        }
    }

    // Output
    stillImageOutput = AVCaptureStillImageOutput()
    stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
    
    movieOutput = ClosuredAVCaptureMovieFileOutput(sessionQueue: queue)
  }

  func addInput(_ input: AVCaptureDeviceInput) {
    configurePreset(input)

    if session.canAddInput(input) {
      session.addInput(input)

      DispatchQueue.main.async {
        self.delegate?.cameraMan(self, didChangeInput: input)
      }
    }
  }

  // MARK: - Session

  var currentInput: AVCaptureDeviceInput? {
    return session.inputs.first as? AVCaptureDeviceInput
  }

  fileprivate func start() {
    // Devices
    setupDevices()

    guard let input = backCamera, let imageOutput = stillImageOutput, let movieOutput = movieOutput else { return }

    addInput(input)

    if session.canAddOutput(imageOutput) {
      session.addOutput(imageOutput)
    }
    
    movieOutput.addToSession(session)

    queue.async {
      self.session.startRunning()

      DispatchQueue.main.async {
        self.delegate?.cameraManDidStart(self)
      }
    }
  }

  func stop() {
    self.session.stopRunning()
  }

  func switchCamera(_ completion: (() -> Void)? = nil) {
    guard let currentInput = currentInput
      else {
        completion?()
        return
    }

    queue.async {
      guard let input = (currentInput == self.backCamera) ? self.frontCamera : self.backCamera
        else {
          DispatchQueue.main.async {
            completion?()
          }
          return
      }

      self.configure {
        self.session.removeInput(currentInput)
        self.addInput(input)
      }

      DispatchQueue.main.async {
        completion?()
      }
    }
  }

  func takePhoto(_ previewLayer: AVCaptureVideoPreviewLayer, location: CLLocation?, completion: @escaping ((PHAsset?) -> Void)) {
    guard let connection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) else { return }

    connection.videoOrientation = Utils.videoOrientation()

    queue.async {
      self.stillImageOutput?.captureStillImageAsynchronously(from: connection) {
        buffer, error in

        guard error == nil, let buffer = buffer, CMSampleBufferIsValid(buffer),
          let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
          let image = UIImage(data: imageData)
          else {
            DispatchQueue.main.async {
              completion(nil)
            }
            return
        }

        self.savePhoto(image, location: location, completion: completion)
      }
    }
  }

  func savePhoto(_ image: UIImage, location: CLLocation?, completion: @escaping ((PHAsset?) -> Void)) {
    self.save({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
    }, location: location, completion: completion)
  }
    
  func save(_ req: @escaping ((Void) -> PHAssetChangeRequest?), location: CLLocation?, completion: ((PHAsset?) -> Void)?) {
    savingQueue.async {
      var localIdentifier: String?
      do {
        try PHPhotoLibrary.shared().performChangesAndWait {
          if let request = req() {
            localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            request.creationDate = Date()
            request.location = location
          }
        }
        DispatchQueue.main.async {
          if let localIdentifier = localIdentifier {
            completion?(Fetcher.fetchAsset(localIdentifier))
          } else {
            completion?(nil)
          }
        }
      } catch {
        DispatchQueue.main.async {
          completion?(nil)
        }
      }
    }
  }
  
  func isRecording() -> Bool {
    return self.movieOutput?.isRecording() ?? false
  }
  
  func startVideoRecord(_ completion: ((Bool) -> Void)?) {
    self.movieOutput?.startRecording(completion)
  }
  
  func stopVideoRecording(location: CLLocation?, _ completion: ((PHAsset?) -> Void)? = nil) {
    self.movieOutput?.stopVideoRecording(location: location) { url in
      if let url = url {
        self.saveVideo(at: url, location: location, completion: completion)
      } else {
        completion?(nil)
      }
    }
    
  }
  
  func saveVideo(at path: URL, location: CLLocation?, completion: ((PHAsset?) -> Void)?) {
    self.save({
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: path)
    }, location: location, completion: completion)
  }

  
  func flash(_ mode: AVCaptureFlashMode) {
    guard let device = currentInput?.device , device.isFlashModeSupported(mode) else { return }

    queue.async {
      self.lock {
        device.flashMode = mode
      }
    }
  }

  func focus(_ point: CGPoint) {
    guard let device = currentInput?.device , device.isFocusModeSupported(AVCaptureFocusMode.locked) else { return }

    queue.async {
      self.lock {
        device.focusPointOfInterest = point
      }
    }
  }

  // MARK: - Lock

  func lock(_ block: () -> Void) {
    if let device = currentInput?.device , (try? device.lockForConfiguration()) != nil {
      block()
      device.unlockForConfiguration()
    }
  }

  // MARK: - Configure
  func configure(_ block: () -> Void) {
    session.beginConfiguration()
    block()
    session.commitConfiguration()
  }

  // MARK: - Preset

  func configurePreset(_ input: AVCaptureDeviceInput) {
    for asset in preferredPresets() {
      if input.device.supportsAVCaptureSessionPreset(asset) && self.session.canSetSessionPreset(asset) {
        self.session.sessionPreset = asset
        return
      }
    }
  }

  func preferredPresets() -> [String] {
    return [
      AVCaptureSessionPresetHigh,
      AVCaptureSessionPresetMedium,
      AVCaptureSessionPresetLow
    ]
  }
}
