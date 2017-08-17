import CoreMedia

public protocol VisionInput: class {
    func videoCapture(_ capture: Camera, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime)
}
