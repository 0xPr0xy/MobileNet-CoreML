//
//  VideoLayer.swift
//  ARScanner
//
//  Created by Peter on 05/08/2017.
//

import AVFoundation
import UIKit

class VideoLayer: UIView {

    private let captureSession: AVCaptureSession!
    private let cameraLayer: AVCaptureVideoPreviewLayer!

    required init?(coder aDecoder: NSCoder) {

        self.captureSession = AVCaptureSession()
        self.captureSession.sessionPreset = AVCaptureSession.Preset.high
        self.cameraLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)

        super.init(coder: aDecoder)

        self.layer.addSublayer(self.cameraLayer)

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: backCamera) else {
            return
        }

        self.captureSession.addInput(input)
    }

    override func layoutSubviews() {
        self.cameraLayer.frame = self.frame
        super.layoutSubviews()
    }

    public func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "MyQueue"))

        self.captureSession.addOutput(videoOutput)
    }

    public func start() {
        self.captureSession.startRunning()
    }

    public func stop() {
        self.captureSession.stopRunning()
    }
}
