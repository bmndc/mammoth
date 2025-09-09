//
//  StaticPic.swift
//  Mammoth
//
//  Created by Riley Howard on 9/27/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class StaticPic: UIImageView {
    enum StaticPicSize {
        case small, regular

        func width() -> CGFloat {
            switch self {
            case .small:
                return 24
            case .regular:
                return 44
            }
        }

        func height() -> CGFloat {
            return width() // height == width
        }

        func cornerRadius() -> CGFloat {
            if GlobalStruct.circleProfiles {
                return width() / 2
            } else {
                switch self {
                case .small:
                    return 4
                case .regular:
                    return 8
                }
            }
        }
    }

    // MARK: - Properties

    private(set) var glyphView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.clipsToBounds = false
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private var size: StaticPicSize = .regular

    init(withSize StaticPicSize: StaticPicSize) {
        super.init(frame: .zero)
        size = StaticPicSize
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        glyphView.image = nil
    }
}

// MARK: - Setup UI

private extension StaticPic {
    func setupUI() {
        addSubview(glyphView)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .custom.OVRLYSoftContrast
        layer.borderColor = UIColor.custom.outlines.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = size.cornerRadius()

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width()),
            heightAnchor.constraint(equalToConstant: size.height()),
            glyphView.centerXAnchor.constraint(equalTo: centerXAnchor),
            glyphView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

// MARK: - Configuration

extension StaticPic {
    func setImage(_ image: UIImage) {
        glyphView.image = image
    }

    func onThemeChange() {
        backgroundColor = .custom.OVRLYSoftContrast
        layer.borderColor = UIColor.custom.outlines.cgColor
        glyphView.backgroundColor = .custom.OVRLYSoftContrast
        glyphView.layer.cornerRadius = size.cornerRadius()
    }
}

// MARK: Appearance changes

extension StaticPic {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.onThemeChange()
            }
        }
    }
}
