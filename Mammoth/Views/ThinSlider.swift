//
//  ThinSlider.swift
//  Mammoth
//
//  Created by Riley Howard on 9/6/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class ThinSlider: UISlider {
    override init(frame: CGRect) {
        super.init(frame: frame)
        tintColor = .custom.baseTint
        minimumTrackTintColor = .custom.feintContrast
        maximumTrackTintColor = .custom.feintContrast
        setThumbImage(UIImage(named: "ThinSliderThumb")?.withTintColor(.custom.mediumContrast), for: .normal)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let point = CGPoint(x: bounds.minX, y: bounds.midY)
        return CGRect(origin: point, size: CGSize(width: bounds.width, height: 1))
    }
}

// MARK: Appearance changes

extension ThinSlider {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.tintColor = .custom.baseTint
                self.minimumTrackTintColor = .custom.feintContrast
                self.maximumTrackTintColor = .custom.feintContrast
            }
        }
    }
}
