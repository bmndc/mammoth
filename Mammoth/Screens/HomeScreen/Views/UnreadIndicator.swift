//
//  UnreadIndicator.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class UnreadIndicator: UIButton {
    // MARK: - Properties

    private var unreadCount: Int = 0

    private var blurEffectView: BlurredBackground
    private var animatedIn: Bool = false

    private var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter
    }()

    override init(frame _: CGRect) {
        blurEffectView = BlurredBackground(dimmed: false)

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled && unreadCount > 0 {
                animateIn()
            } else if !isEnabled {
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

private extension UnreadIndicator {
    func setupUI() {
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.layer.cornerRadius = 16
        blurEffectView.clipsToBounds = true
        addSubview(blurEffectView)

        setTitleColor(.label, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel?.textAlignment = .center

        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -50)
        isEnabled = true

        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),

            widthAnchor.constraint(equalToConstant: 42),
            heightAnchor.constraint(equalToConstant: 34),
        ])
    }

    func animateIn() {
        if !animatedIn {
            animatedIn = true
            UIView.animate(withDuration: 0.72, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.44, options: .curveEaseOut, animations: {
                let translateY = CGAffineTransform(translationX: 0, y: 0)
                self.transform = translateY
                self.alpha = 1
            })
        }
    }

    func animateOut() {
        if animatedIn {
            animatedIn = false
            transform = .identity
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = 0
                let translateY = CGAffineTransform(translationX: 0, y: -50)
                self.transform = translateY
            })
        }
    }
}

// MARK: - Configure

extension UnreadIndicator {
    func configure(unreadCount: Int) {
        guard self.unreadCount != unreadCount else {
            if unreadCount == 0, isEnabled {
                isEnabled = false
            }
            return
        }
        self.unreadCount = unreadCount
        setTitle(formatter.dividedByK(number: Double(unreadCount)), for: .normal)

        if unreadCount == 0, isEnabled, animatedIn {
            isEnabled = false
        } else if unreadCount > 0, !isEnabled {
            isEnabled = true
        }
    }
}

// MARK: Appearance changes

extension UnreadIndicator {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.blurEffectView.layer.borderColor = UIColor.systemGray4.cgColor
                self.setTitleColor(.label, for: .normal)
            }
        }
    }
}
