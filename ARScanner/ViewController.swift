import UIKit
import Vision
import CoreMedia
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    private let vision = Vision()

    override func viewDidLoad() {
        super.viewDidLoad()

        predictionLabel.text = ""
        timeLabel.text = ""
        vision.delegate = self
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        videoPreview.layer.sublayers?.first?.frame = videoPreview.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension ViewController: VisionOutput {

    public func addVideoLayer(_ layer: AVCaptureVideoPreviewLayer) {
        videoPreview.layer.addSublayer(layer)
    }

    public func setPredictionLabelText(_ text: String) {
        predictionLabel.text = text
    }

    public func setTimeLabelText(_ text: String) {
        timeLabel.text = text
    }
}
