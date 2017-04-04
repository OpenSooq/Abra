import UIKit
import AVFoundation

protocol CameraViewDelegate: class {
  func cameraView(_ cameraView: CameraView, didTouch point: CGPoint)
}

class CameraView: UIView, UIGestureRecognizerDelegate {

  lazy var closeButton: UIButton = self.makeCloseButton()
  lazy var flashButton: TripleButton = self.makeFlashButton()
  lazy var rotateButton: UIButton = self.makeRotateButton()
  fileprivate lazy var bottomContainer: UIView = self.makeBottomContainer()
  lazy var bottomView: UIView = self.makeBottomView()
  lazy var stackView: StackView = self.makeStackView()
  lazy var shutterButton: ShutterButton = self.makeShutterButton()
  lazy var doneButton: UIButton = self.makeDoneButton()
  lazy var focusImageView: UIImageView = self.makeFocusImageView()
  lazy var tapGR: UITapGestureRecognizer = self.makeTapGR()
  lazy var rotateOverlayView: UIView = self.makeRotateOverlayView()
  lazy var shutterOverlayView: UIView = self.makeShutterOverlayView()
  lazy var blurView: UIVisualEffectView = self.makeBlurView()
  lazy var recLabel: UILabel = self.makeRecLabel()
  lazy var saveLabel: UILabel = self.makeSaveLabel()

  var timer: Timer?
  var previewLayer: AVCaptureVideoPreviewLayer?
  weak var delegate: CameraViewDelegate?

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = UIColor.black
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  func setup() {
    addGestureRecognizer(tapGR)

    [closeButton, flashButton, rotateButton, bottomContainer, recLabel, saveLabel].forEach {
      addSubview($0)
    }

    [bottomView, shutterButton].forEach {
      bottomContainer.addSubview($0)
    }

    [stackView, doneButton].forEach {
      bottomView.addSubview($0 as! UIView)
    }

    [closeButton, flashButton, rotateButton, recLabel].forEach {
      $0.g_addShadow()
    }

    rotateOverlayView.addSubview(blurView)
    insertSubview(rotateOverlayView, belowSubview: rotateButton)
    insertSubview(focusImageView, belowSubview: bottomContainer)
    insertSubview(shutterOverlayView, belowSubview: bottomContainer)

    closeButton.g_pin(on: .top)
    closeButton.g_pin(on: .left)
    closeButton.g_pin(size: CGSize(width: 44, height: 44))

    flashButton.g_pin(on: .centerY, view: closeButton)
    flashButton.g_pin(on: .centerX)
    flashButton.g_pin(size: CGSize(width: 60, height: 44))
    
    recLabel.g_pin(on: .centerY, view: closeButton)
    recLabel.g_pin(on: .centerX)
    
    recLabel.sizeToFit()
    recLabel.g_pin(size: recLabel.bounds.size)

    rotateButton.g_pin(on: .top)
    rotateButton.g_pin(on: .right)
    rotateButton.g_pin(size: CGSize(width: 44, height: 44))

    bottomContainer.g_pinDownward()
    bottomContainer.g_pin(height: 80)
    bottomView.g_pinEdges()

    stackView.g_pin(on: .centerY, constant: -4)
    stackView.g_pin(on: .left, constant: 38)
    stackView.g_pin(size: CGSize(width: 56, height: 56))

    shutterButton.g_pinCenter()
    shutterButton.g_pin(size: CGSize(width: 60, height: 60))
    
    saveLabel.g_pin(on: .centerY, view: shutterButton, constant: -45)
    saveLabel.g_pin(on: .centerX, view: shutterButton)
    
    saveLabel.sizeToFit()
    saveLabel.g_pin(size: saveLabel.bounds.size)
    
    doneButton.g_pin(on: .centerY)
    doneButton.g_pin(on: .right, constant: -38)

    rotateOverlayView.g_pinEdges()
    blurView.g_pinEdges()
    shutterOverlayView.g_pinEdges()
  }

  func setupPreviewLayer(_ session: AVCaptureSession) {
    guard previewLayer == nil else { return }

    let layer = AVCaptureVideoPreviewLayer(session: session)
    layer?.autoreverses = true
    layer?.videoGravity = AVLayerVideoGravityResizeAspectFill

    self.layer.insertSublayer(layer!, at: 0)
    layer?.frame = self.layer.bounds

    previewLayer = layer
  }

  // MARK: - Action

  func viewTapped(_ gr: UITapGestureRecognizer) {
    let point = gr.location(in: self)

    focusImageView.transform = CGAffineTransform.identity
    timer?.invalidate()
    delegate?.cameraView(self, didTouch: point)

    focusImageView.center = point

    UIView.animate(withDuration: 0.5, animations: {
      self.focusImageView.alpha = 1
      self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
    }, completion: { _ in
      self.timer = Timer.scheduledTimer(timeInterval: 1, target: self,
        selector: #selector(CameraView.timerFired(_:)), userInfo: nil, repeats: false)
    })
  }

  // MARK: - Timer

  func timerFired(_ timer: Timer) {
    UIView.animate(withDuration: 0.3, animations: {
      self.focusImageView.alpha = 0
    }, completion: { _ in
      self.focusImageView.transform = CGAffineTransform.identity
    })
  }

  // MARK: - UIGestureRecognizerDelegate
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    let point = gestureRecognizer.location(in: self)

    return point.y > closeButton.frame.maxY
      && point.y < bottomContainer.frame.origin.y
  }
    
  // MARK: - Video recording.
    
  func morphToVideoRecordingStarted() {
    UIView.animate(withDuration: 0.2) {
      self.bottomView.alpha = 0.0
      self.recLabel.alpha = 1.0
      self.flashButton.alpha = 0.0
      self.shutterButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
    }
  }
  
  func morphToVideoRecordingSavingStarted() {
    UIView.animate(withDuration: 0.2) {
      self.saveLabel.alpha = 1.0
    }
  }
  
  func morphToVideoRecordingSavingDone() {
    UIView.animate(withDuration: 0.2) {
      self.bottomView.alpha = 1.0
      self.recLabel.alpha = 0.0
      self.flashButton.alpha = 1.0
      self.saveLabel.alpha = 0.0
      self.shutterButton.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
  }
  
  func morphToVideoRecordingReset() {
    UIView.animate(withDuration: 0.2) {
      self.bottomView.alpha = 0.0
      self.recLabel.alpha = 0.0
      self.flashButton.alpha = 1.0
      self.saveLabel.alpha = 0.0
      self.shutterButton.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
  }

  // MARK: - Controls

  func makeCloseButton() -> UIButton {
    let button = UIButton(type: .custom)
    button.setImage(Bundle.image("gallery_close"), for: UIControlState())

    return button
  }

  func makeFlashButton() -> TripleButton {
    let states: [TripleButton.State] = [
      TripleButton.State(title: "Gallery.Camera.Flash.Off".g_localize(fallback: "OFF"), image: Bundle.image("gallery_camera_flash_off")!),
      TripleButton.State(title: "Gallery.Camera.Flash.On".g_localize(fallback: "ON"), image: Bundle.image("gallery_camera_flash_on")!),
      TripleButton.State(title: "Gallery.Camera.Flash.Auto".g_localize(fallback: "AUTO"), image: Bundle.image("gallery_camera_flash_auto")!)
    ]

    let button = TripleButton(states: states)

    return button
  }

  func makeRotateButton() -> UIButton {
    let button = UIButton(type: .custom)
    button.setImage(Bundle.image("gallery_camera_rotate"), for: UIControlState())

    return button
  }

  func makeBottomContainer() -> UIView {
    let view = UIView()

    return view
  }

  func makeBottomView() -> UIView {
    let view = UIView()
    view.backgroundColor = Config.Camera.BottomContainer.backgroundColor
    view.alpha = 0

    return view
  }

  func makeStackView() -> StackView {
    let view = StackView()

    return view
  }

  func makeShutterButton() -> ShutterButton {
    let button = ShutterButton()
    
    switch Config.Camera.recordMode {
    case .photo:
        button.overlayView.backgroundColor = .white
    case .video:
        button.overlayView.backgroundColor = .red
    }
    button.g_addShadow()

    return button
  }

  func makeDoneButton() -> UIButton {
    let button = UIButton(type: .system)
    button.setTitleColor(UIColor.white, for: UIControlState())
    button.setTitleColor(UIColor.lightGray, for: .disabled)
    button.titleLabel?.font = Config.Font.Text.regular.withSize(16)
    button.setTitle("Gallery.Done".g_localize(fallback: "Done"), for: UIControlState())

    return button
  }
    
  func makeRecLabel() -> UILabel {
    let button = UILabel()
    button.text = "REC"
    button.textColor = .red
    button.alpha = 0.0
    return button
  }
  
  func makeSaveLabel() -> UILabel {
    let button = UILabel()
    button.text = "Saving video..."
    button.textColor = .white
    button.alpha = 0.0
    button.font = UIFont.systemFont(ofSize: 12)
    return button
  }

  func makeFocusImageView() -> UIImageView {
    let view = UIImageView()
    view.frame.size = CGSize(width: 110, height: 110)
    view.image = Bundle.image("gallery_camera_focus")
    view.backgroundColor = .clear
    view.alpha = 0

    return view
  }

  func makeTapGR() -> UITapGestureRecognizer {
    let gr = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
    gr.delegate = self

    return gr
  }

  func makeRotateOverlayView() -> UIView {
    let view = UIView()
    view.alpha = 0

    return view
  }

  func makeShutterOverlayView() -> UIView {
    let view = UIView()
    view.alpha = 0
    view.backgroundColor = UIColor.black

    return view
  }

  func makeBlurView() -> UIVisualEffectView {
    let effect = UIBlurEffect(style: .dark)
    let blurView = UIVisualEffectView(effect: effect)

    return blurView
  }

}
