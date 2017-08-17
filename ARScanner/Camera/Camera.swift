import UIKit
import AVFoundation
import CoreVideo

public class Camera: NSObject {

    public var previewLayer: AVCaptureVideoPreviewLayer?
    public weak var delegate: VisionInput?
    public var fps = 15
    private let captureSession = AVCaptureSession()
    private let captureOutput = AVCaptureVideoDataOutput()
    private let initializationQueue = DispatchQueue(label: "nl.pydev.ARScanner.eye")
    private var lastTimestamp = CMTime()

    private func setUpCamera(sessionPreset: AVCaptureSession.Preset) -> Bool {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset

        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("Error: no video devices available")
            return false
        }

        guard let captureInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Error: could not create AVCaptureDeviceInput")
            return false
        }

        if captureSession.canAddInput(captureInput) {
            captureSession.addInput(captureInput)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = .portrait

        self.previewLayer = previewLayer

        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]

        captureOutput.videoSettings = settings
        captureOutput.alwaysDiscardsLateVideoFrames = true
        captureOutput.setSampleBufferDelegate(self, queue: initializationQueue)
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
        }

        // We want the buffers to be in portrait orientation otherwise they are
        // rotated by 90 degrees. Need to set this _after_ addOutput()!
        captureOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait

        captureSession.commitConfiguration()
        return true
    }

    public func setUp(sessionPreset: AVCaptureSession.Preset = .medium,
                      completion: @escaping (Bool) -> Void) {
        initializationQueue.async {
            let success = self.setUpCamera(sessionPreset: sessionPreset)
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    public func start() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired
        // framerate.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - lastTimestamp
        if deltaTime >= CMTimeMake(1, Int32(fps)) {
            lastTimestamp = timestamp
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            delegate?.videoCapture(self, didCaptureVideoFrame: imageBuffer, timestamp: timestamp)
        }
    }

    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        //print("dropped frame")
    }
}
