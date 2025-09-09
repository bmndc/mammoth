//
//  BlurredBackground.swift
//  Mammoth
//
//  Created by Benoit Nolens on 04/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class BlurredBackground: UIView {
    static let blurEffectDimmed = UIBlurEffect(style: .regular)
    static let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)

    private let blurEffectView: UIVisualEffectView

    private let underlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var isDimmed: Bool = false

    init(dimmed: Bool = false, underlayAlpha _: CGFloat? = nil) {
        if dimmed {
            blurEffectView = UIVisualEffectView(effect: BlurredBackground.blurEffectDimmed)
        } else {
            blurEffectView = UIVisualEffectView(effect: BlurredBackground.blurEffect)
        }

        blurEffectView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)

        isDimmed = dimmed
        addSubview(underlay)
        addSubview(blurEffectView)

        NSLayoutConstraint.activate([
            underlay.topAnchor.constraint(equalTo: topAnchor),
            underlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            underlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            underlay.bottomAnchor.constraint(equalTo: bottomAnchor),

            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        onThemeChange()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onThemeChange() {
        blurEffectView.alpha = 1.0

        if traitCollection.userInterfaceStyle == .light {
            underlay.backgroundColor = .custom.background.darker(by: 0.65)?.withAlphaComponent(isDimmed ? 0.75 : 0.35)
            if isDimmed {
                blurEffectView.effect = Self.blurEffectDimmed
            } else {
                blurEffectView.effect = Self.blurEffect
            }
        } else {
            let isHighContractsMode = GlobalStruct.overrideThemeHighContrast
            if isHighContractsMode {
                if isDimmed {
                    blurEffectView.effect = nil
                    underlay.backgroundColor = .custom.background.darker(by: 0.27)?.withAlphaComponent(1)
                } else {
                    blurEffectView.effect = Self.blurEffect
                    blurEffectView.alpha = 0.7
                    underlay.backgroundColor = .custom.background.lighter(by: 0.27)?.withAlphaComponent(0.95)
                }
            } else {
                underlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: isDimmed ? 0.85 : 0.45)
                if isDimmed {
                    blurEffectView.effect = Self.blurEffectDimmed
                } else {
                    blurEffectView.effect = Self.blurEffect
                }
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.onThemeChange()
            }
        }
    }
}
