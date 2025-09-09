//
//  PostCardImageCollectionCellSmall.swift
//  Mammoth
//
//  Created by Riley Howard on 5/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

// MARK: - PostCardImageCollectionCellSmall

class PostCardImageCollectionCellSmall: PostCardImageCollectionCell {
    // MARK: - Setup UI

    override func setupUI() {
        isOpaque = true

        imageView.contentMode = .scaleAspectFill
        bgImage.backgroundColor = .custom.background
        bgImage.frame = CGRect(x: 0, y: 0, width: 66, height: 66)
        bgImage.layer.cornerRadius = 6
        contentView.addSubview(bgImage)

        imageView.layer.borderWidth = 1.0 / UIScreen.main.scale
        imageView.layer.borderColor = UIColor.custom.outlines.cgColor

        imageView.backgroundColor = .custom.background
        imageView.layer.cornerRadius = 6
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    // MARK: - Configuration

    override func configure(model: PostCardImageCollectionCellModel, withRoundedCorners _: Bool = true) {
        imageView.sd_setImage(with: URL(string: model.mediaAttachment.previewURL!))
        for x in imageView.subviews {
            x.removeFromSuperview()
        }
        if model.isSensitive, GlobalStruct.blurSensitiveContent {
            let blurEffect = UIBlurEffect(style: .regular)
            var blurredEffectView = UIVisualEffectView()
            blurredEffectView = UIVisualEffectView(effect: blurEffect)
            blurredEffectView.frame = imageView.bounds
            blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.addSubview(blurredEffectView)
        }
    }
}
