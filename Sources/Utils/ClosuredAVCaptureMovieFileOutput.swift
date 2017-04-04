import Foundation
import AVFoundation
import Photos

public class ClosuredAVCaptureMovieFileOutput: NSObject, AVCaptureFileOutputRecordingDelegate {
  
  private let output: AVCaptureMovieFileOutput
  private let queue: DispatchQueue
  
  private var videoRecordStartedCompletion: ((Bool) -> Void)?
  private var videoRecordCompletion: ((URL?) -> Void)?
  
  public init(sessionQueue: DispatchQueue) {
    self.queue = sessionQueue
    self.output = AVCaptureMovieFileOutput()
    self.output.minFreeDiskSpaceLimit = 1024 * 1024
    self.output.movieFragmentInterval = kCMTimeInvalid
  }
  
  public func addToSession(_ session: AVCaptureSession) {
    if session.canAddOutput(output) {
      session.addOutput(output)
    }
  }
  
  public func isRecording() -> Bool {
    return output.isRecording
  }
  
  public func startRecording(_ completion: ((Bool) -> Void)?) {
    
    guard let connection = output.connection(withMediaType: AVMediaTypeVideo) else {
      completion?(false)
      return
    }
    
    connection.videoOrientation = Utils.videoOrientation()
    
    queue.async {
      if let url = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("movie.mov") {
        if FileManager.default.fileExists(atPath: url.absoluteString) {
          try? FileManager.default.removeItem(at: url)
        }
        self.videoRecordStartedCompletion = completion
        self.output.startRecording(toOutputFileURL: url, recordingDelegate: self)
      } else {
        DispatchQueue.main.async { completion?(false) }
      }
    }
  }
  
  public func stopVideoRecording(location: CLLocation?, _ completion: ((URL?) -> Void)? = nil) {
    self.videoRecordCompletion = completion
    queue.async {
      self.output.stopRecording()
    }
  }
  
  public func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
    self.videoRecordStartedCompletion?(false)
    self.videoRecordStartedCompletion = nil
  }
  
  public func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
    if error == nil {
      DispatchQueue.main.async {
        self.videoRecordCompletion?(outputFileURL)
        self.videoRecordCompletion = nil
      }
    } else {
      DispatchQueue.main.async {
        self.videoRecordCompletion?(nil)
        self.videoRecordCompletion = nil
      }
    }
  }
}
