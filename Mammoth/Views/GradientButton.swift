//
//  GradientButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 27/11/2023.
//

import UIKit

class GradientButton: UIButton {
    private let colors: [CGColor]
    private let startPoint: CGPoint
    private let endPoint: CGPoint

    init(colors: [CGColor], startPoint: CGPoint, endPoint: CGPoint) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !bounds.size.height.isZero, !bounds.size.width.isZero {
            backgroundColor = UIColor.gradient(colors: colors, startPoint: startPoint, endPoint: endPoint, bounds: bounds)
        }
    }
}
