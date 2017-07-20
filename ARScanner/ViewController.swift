//
//  ViewController.swift
//  ARScanner
//
//  Created by Peter on 14/07/2017.
//

import UIKit
import Metal
import MetalKit
import ARKit
import Vision

extension MTKView : RenderDestinationProvider {}

class ViewController: UIViewController, MTKViewDelegate, ARSessionDelegate {

    @IBOutlet weak var label: UILabel!

    private var session: ARSession!
    private var renderer: Renderer!
    private var model: VNCoreMLModel!
    private var frames: Int = 0

    required init?(coder aDecoder: NSCoder) {
        do {
            model = try VNCoreMLModel(for: MobileNet().model)
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }

        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        session = ARSession()
        session.delegate = self

        if let view = self.view as? MTKView {

            view.device = MTLCreateSystemDefaultDevice()
            view.delegate = self

            guard view.device != nil else {
                fatalError("Metal is not supported on this device")
            }

            renderer = Renderer(session: session, metalDevice: view.device!, renderDestination: view)
            renderer.drawRectResized(size: view.bounds.size)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingSessionConfiguration()
        session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: Private
    private func classify(frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
        let mlRequest = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification: VNClassificationObservation = request.results!.first as? VNClassificationObservation else {
                return
            }

            let roundedConfidence = String(format: "%.2f", classification.confidence)
            self.label.text = "\(classification.identifier) - \(roundedConfidence)"
        }

        mlRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)

        do {
            try handler.perform([mlRequest])
        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.drawRectResized(size: size)
    }

    func draw(in view: MTKView) {
        renderer.update()

        DispatchQueue.main.async {
            if let currentFrame = self.session.currentFrame {
                self.classify(frame: currentFrame)
            }
        }
    }

    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
    }

    func sessionWasInterrupted(_ session: ARSession) {
    }

    func sessionInterruptionEnded(_ session: ARSession) {
    }
}

