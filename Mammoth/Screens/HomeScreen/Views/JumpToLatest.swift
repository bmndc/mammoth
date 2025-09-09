//
//  JumpToLatest.swift
//  Mammoth
//
//  Created by Benoit Nolens on 26/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import SDWebImage
import UIKit

protocol JumpToLatestDelegate {
    func onClosePress()
}

final class JumpToLatest: UIButton {
    // MARK: - Properties

    var delegate: JumpToLatestDelegate?

    private var blurEffectView: BlurredBackground
    private var animatedIn: Bool = false

    private var closeIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.image = UIImage()
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
            } else if !isEnabled {
                animateOut()
            }
        }
    }

    // Increase the tap target
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -20, dy: -20).contains(point)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI

private extension JumpToLatest {
    func setupUI() {
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.layer.cornerRadius = 16
        blurEffectView.layer.cornerCurve = .continuous
        blurEffectView.clipsToBounds = true
        addSubview(blurEffectView)
        addSubview(closeIcon)

        alpha = 0
        isEnabled = true
        transform = CGAffineTransform(translationX: 0, y: -50)

        setTitleColor(.label, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel?.textAlignment = .center
        setTitle(NSLocalizedString("home.jumpToNow", comment: ""), for: .normal)

        contentEdgeInsets = .init(top: 0, left: 14, bottom: 0, right: 32)

        closeIcon.image = FontAwesome.image(fromChar: "\u{f00d}", color: .label, size: 12, weight: .bold).withRenderingMode(.alwaysTemplate)

        let closeGesture = UITapGestureRecognizer(target: self, action: #selector(onClosePress))
        closeIcon.addGestureRecognizer(closeGesture)

        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),

            heightAnchor.constraint(equalToConstant: 34),

            closeIcon.widthAnchor.constraint(equalToConstant: 37),
            closeIcon.heightAnchor.constraint(equalToConstant: 34),
            closeIcon.trailingAnchor.constraint(equalTo: trailingAnchor),
            closeIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc func onClosePress() {
        delegate?.onClosePress()
    }

    func animateIn() {
        animatedIn = true
        UIView.animate(withDuration: 0.72, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.44, options: .curveEaseOut, animations: {
            let translateY = CGAffineTransform(translationX: 0, y: 0)
            self.transform = translateY
            self.alpha = 1
        })
    }

    func animateOut() {
        animatedIn = false
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            let translateY = CGAffineTransform(translationX: 0, y: -50)
            self.transform = translateY
        })
    }
}

// MARK: - Configure

extension JumpToLatest {
    func configure(readCount _: Int) {}
}

// MARK: Appearance changes

extension JumpToLatest {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {}
        }
    }
}
