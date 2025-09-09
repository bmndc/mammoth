//
//  PostCardImageCollectionCell.swift
//  Mammoth
//
//  Created by Riley Howard on 5/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage
import UIKit
import UnifiedBlurHash

struct PostCardImageCollectionCellModel {
    var altText: String
    var mediaAttachment: Attachment
    var isSensitive: Bool
    var usesMediaPlayer: Bool
    var postCard: PostCardModel
}

class PostCardImageCollectionCell: UICollectionViewCell {
    var bgImage = UIImageView()
    var imageView = UIImageView()
//    var displayMediaButton : UIButton? = nil
    var model: PostCardImageCollectionCellModel?

    private var playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false

        let iconView = BlurredBackground(dimmed: false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 18
        iconView.clipsToBounds = true

        button.insertSubview(iconView, aboveSubview: button.imageView!)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
        ])

        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f04b}", color: .custom.linkText, size: 16, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor, constant: 1),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
        ])

        let bg = UIView()
        bg.backgroundColor = .custom.OVRLYSoftContrast.withAlphaComponent(0.3)
        button.insertSubview(bg, belowSubview: button.imageView!)
        bg.pinEdges()

        return button
    }()

    var altButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("ALT", for: .normal)
        button.setTitleColor(.custom.active, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 7
        button.clipsToBounds = true
        button.isHidden = true
        button.accessibilityElementsHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)

        let bg = BlurredBackground(dimmed: false)
        button.insertSubview(bg, belowSubview: button.titleLabel!)
        bg.pinEdges()

        return button
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        for x in imageView.subviews {
            x.removeFromSuperview()
        }

        playButton.isHidden = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI

    func setupUI() {
        isOpaque = true

        imageView.contentMode = .scaleAspectFill
        backgroundColor = .clear
        imageView.layer.masksToBounds = true
        bgImage.backgroundColor = .custom.background

        bgImage.layer.cornerRadius = 6
        contentView.addSubview(bgImage)

        imageView.layer.borderWidth = 1.0 / UIScreen.main.scale
        imageView.layer.borderColor = UIColor.custom.outlines.cgColor

        imageView.backgroundColor = .custom.background
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        contentView.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: PostCardImageAttachment.gapBetweenLargeImages),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        contentView.isUserInteractionEnabled = false

        contentView.addSubview(playButton)

        NSLayoutConstraint.activate([
            playButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            playButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            playButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: PostCardImageAttachment.gapBetweenLargeImages),
            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])

        contentView.addSubview(altButton)

        NSLayoutConstraint.activate([
            altButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            altButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        ])
    }

    // MARK: - Configuration

    func configure(model: PostCardImageCollectionCellModel, withRoundedCorners roundedCorners: Bool = true) {
        if roundedCorners {
            bgImage.layer.cornerRadius = 6
            imageView.layer.cornerRadius = 6
        } else {
            bgImage.layer.cornerRadius = 0
            imageView.layer.cornerRadius = 0
        }
        self.model = model
        imageView.accessibilityLabel = model.altText
        if model.mediaAttachment.previewURL != nil {
            var placeholder: UIImage?
            if let blurhash = model.mediaAttachment.blurhash {
                let blurWidth = model.mediaAttachment.meta?.small?.width ?? 64
                let blurHeight = model.mediaAttachment.meta?.small?.height ?? 64
                placeholder = UnifiedImage(blurHash: blurhash, size: .init(width: 64, height: 64))?
                    .resized(to: .init(width: blurWidth, height: blurHeight))
            }

            imageView.ma_setImage(with: URL(string: model.mediaAttachment.previewURL!)!,
                                  cachedImage: model.postCard.decodedImages[model.mediaAttachment.previewURL!] as? UIImage,
                                  placeholder: placeholder,
                                  imageTransformer: PostCardImage.transformer)
            { image in
                model.postCard.decodedImages[model.mediaAttachment.previewURL!] = image
            }

        } else {
            imageView.image = UIImage(systemName: "waveform.path")
            imageView.contentMode = .scaleAspectFit
        }
        altButton.isHidden = model.altText.isEmpty
        bringSubviewToFront(altButton)

        // Clear out optional views
        for x in imageView.subviews {
            x.removeFromSuperview()
        }

        // Add media play button if needed
        if model.usesMediaPlayer {
            playButton.isHidden = false
        }

        // Add blur/sensitive overlay
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

// MARK: - Display media

extension PostCardImageCollectionCell {
    // Forward single taps to buttons in our cell
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else { return nil }
        guard !isHidden else { return nil }
        guard alpha >= 0.01 else { return nil }
        guard self.point(inside: point, with: event) else { return nil }
        if !altButton.isHidden {
            if altButton.point(inside: convert(point, to: altButton), with: event) {
                return altButton
            }
        }
        return super.hitTest(point, with: event)
    }
}
