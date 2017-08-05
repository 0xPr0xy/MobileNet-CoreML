//
//  ViewController.swift
//  ARScanner
//
//  Created by Peter on 04/08/2017.
//

import AVFoundation
import Vision
import UIKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: Properties

    @IBOutlet private weak var cameraView: VideoLayer!

    @IBOutlet private weak var classificationLabel: VNClassificationLabel!

    private let visionSequenceHandler = VNSequenceRequestHandler()

    private let model: VNCoreMLModel = {
        do {
            return try VNCoreMLModel(for: MobileNet().model)
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraView?.setDelegate(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.cameraView?.start()
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.cameraView?.stop()
        super.viewWillDisappear(animated)
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let request = VNCoreMLRequest(model: self.model, completionHandler: self.classificationLabel.handleVisionRequestUpdate)
        request.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop

        do {
            try self.visionSequenceHandler.perform([request], on: pixelBuffer)
        } catch {
            self.classificationLabel.handleError(error)
        }
    }
}
