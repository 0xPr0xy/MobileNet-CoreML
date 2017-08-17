import UIKit
import Vision
import CoreMedia
import AVFoundation

typealias Prediction = (String, Double)

final class Vision {

    private let model = MobileNet()
    private let semaphore = DispatchSemaphore(value: 2)
    private var camera: Camera!
    private var request: VNCoreMLRequest!
    private var startTimes: [CFTimeInterval] = []
    private var framesDone = 0
    private var frameCapturingStartTime = CACurrentMediaTime()
    public weak var delegate: VisionOutput?

    init() {
        self.setUpCamera()
        self.setUpVision()
    }

    private func setUpCamera() {
        camera = Camera()
        camera.delegate = self
        camera.fps = 50
        camera.setUp { success in
            if success {
                if let visual = self.camera.previewLayer {
                    self.delegate?.addVideoLayer(visual)
                }
                self.camera.start()
            }
        }
    }

    private func setUpVision() {
        guard let visionModel = try? VNCoreMLModel(for: model.model) else {
            print("Error: could not create Vision model")
            return
        }

        request = VNCoreMLRequest(model: visionModel, completionHandler: requestDidComplete)
        request.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
    }

    private func predict(pixelBuffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame. Note that
        // predict() can be called on the next frame while the previous one is
        // still being processed. Hence the need to queue up the start times.
        startTimes.append(CACurrentMediaTime())

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }

    private func requestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNClassificationObservation] {

            // The observations appear to be sorted by confidence already, so we
            // take the top 5 and map them to an array of (String, Double) tuples.
            let top5 = observations.prefix(through: 4)
                .map { ($0.identifier.chopPrefix(9), Double($0.confidence)) }

            DispatchQueue.main.async {
                self.show(results: top5)
                self.semaphore.signal()
            }
        }
    }

    private func show(results: [Prediction]) {
        var s: [String] = []
        for (i, pred) in results.enumerated() {
            s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, pred.0, pred.1 * 100))
        }

        let predictionLabelText = s.joined(separator: "\n\n")

        delegate?.setPredictionLabelText(predictionLabelText)

        let latency = CACurrentMediaTime() - startTimes.remove(at: 0)
        let fps = self.measureFPS()
        let timeLabelText = String(format: "%.2f FPS (latency %.5f seconds)", fps, latency)

        delegate?.setTimeLabelText(timeLabelText)
    }

    private func measureFPS() -> Double {
        // Measure how many frames were actually delivered per second.
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }

        return currentFPSDelivered
    }
}

extension Vision: VisionInput {
    public func videoCapture(_ capture: Camera, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            semaphore.wait()
            DispatchQueue.global().async {
                self.predict(pixelBuffer: pixelBuffer)
            }
        }
    }
}
