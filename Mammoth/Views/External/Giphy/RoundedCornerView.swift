//
//  RoundedCornerView.swift
//  Pods
//
//  Created by Brendan Lee on 3/9/17.
//
//

import UIKit

class RoundedCornerView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 8.0 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var trackHeightForRadius: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }

    fileprivate let roundingMask = CornerRoundingMaskView(cornerRadius: 0.0)

    override var bounds: CGRect {
        didSet {
            setNeedsLayout()
        }
    }

    override required init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    fileprivate func setup() {
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if trackHeightForRadius {
            roundingMask.cornerRadius = (bounds.height != 0.0 ? bounds.height : 1.0) / 2.0
        } else {
            roundingMask.cornerRadius = cornerRadius
        }

        roundingMask.frame = bounds
        mask = roundingMask
    }
}
