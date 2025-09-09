//
//  ScrollUpIndicator.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class ScrollUpIndicator: UIButton {
    // MARK: - Properties

    private var blurEffectView: BlurredBackground
    private var animatedIn: Bool = false

    private var hiddenTransformation: CGAffineTransform = {
        let shrink = CGAffineTransform(scaleX: 0.8, y: 0.8)
        let move = CGAffineTransform(translationX: 0, y: -20)
        return CGAffineTransformConcat(shrink, move)
    }()

    private var visibleTransformation: CGAffineTransform = {
        let grow = CGAffineTransform(scaleX: 1, y: 1)
        let move = CGAffineTransform(translationX: 0, y: 0)
        return CGAffineTransformConcat(grow, move)
    }()

    override init(frame _: CGRect) {
        blurEffectView = BlurredBackground(dimmed: false)

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                animateIn()
            } else {
                animateOut()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI

private extension ScrollUpIndicator {
    func setupUI() {
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.layer.cornerRadius = 18
        blurEffectView.clipsToBounds = true
        addSubview(blurEffectView)

        let image = UIImageView(image: FontAwesome.image(fromChar: "\u{f062}", size: 16, weight: .regular).withTintColor(.custom.active, renderingMode: .alwaysOriginal))
        image.contentMode = .center
        image.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.addSubview(image)

        alpha = 0
        isEnabled = false
        transform = hiddenTransformation

        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),

            image.topAnchor.constraint(equalTo: blurEffectView.topAnchor),
            image.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor),
            image.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor),

            widthAnchor.constraint(equalToConstant: 36),
            heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    func animateIn() {
        animatedIn = true
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.64, options: .curveEaseOut, animations: {
            self.transform = self.visibleTransformation
            self.alpha = 1
        })
    }

    func animateOut() {
        animatedIn = false
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.transform = self.hiddenTransformation
        })
    }
}

// MARK: - Configure

extension ScrollUpIndicator {
    func configure(enable: Bool) {
        isEnabled = enable
    }
}

// MARK: Appearance changes

extension ScrollUpIndicator {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.blurEffectView.layer.borderColor = UIColor.systemGray4.cgColor
            }
        }
    }
}
