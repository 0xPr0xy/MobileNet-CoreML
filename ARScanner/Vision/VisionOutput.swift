import AVFoundation

public protocol VisionOutput: class {
    func addVideoLayer(_ layer: AVCaptureVideoPreviewLayer)
    func setPredictionLabelText(_ text: String)
    func setTimeLabelText(_ text: String)
}
