//
//  VNClassificationLabel.swift
//  ARScanner
//
//  Created by Peter on 05/08/2017.
//

import UIKit
import Vision

class VNClassificationLabel: UILabel {

    private var lastObservation: VNClassificationObservation? {
        didSet {
            self.animateUpdate(text: lastObservation?.identifier)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.alpha = 0.0
    }

    private func animateUpdate(text: String?) {
        self.text = text
        self.alpha = 0.6

        UIView.animate(withDuration: 0.5, delay: 2.0, options: UIViewAnimationOptions.curveLinear, animations: {
            self.alpha = 0.0
        })
    }

    public func handleVisionRequestUpdate(_ request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let newObservation = request.results?.first as? VNClassificationObservation else {
                return
            }

            guard newObservation.confidence >= 0.6 else {
                return
            }

            guard newObservation.identifier != self.lastObservation?.identifier else {
                return
            }

            self.lastObservation = newObservation
        }
    }

    public func handleError(_ error: Error?) {
        self.animateUpdate(text: error?.localizedDescription)
    }
}
