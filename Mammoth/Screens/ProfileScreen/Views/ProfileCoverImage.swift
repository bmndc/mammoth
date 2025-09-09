//
//  ProfileCoverImage.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import SDWebImage
import UIKit

class ProfileCoverImage: UIView {
    // MARK: - Properties

    private let coverImage = UIImageView()
    private let gradient = UIView()
    private var user: UserCardModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds

        // Define the gradient colors
        let transparentColor = UIColor.clear.cgColor
        let blackColor = UIColor.black.cgColor
        gradientLayer.colors = [blackColor, transparentColor]

        // Define the gradient locations
        gradientLayer.locations = [0, 1.0]

        // Define the gradient direction
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        layer.mask = gradientLayer
    }
}

// MARK: - Setup UI

private extension ProfileCoverImage {
    func setupUI() {
        isOpaque = true
        backgroundColor = .custom.background
        addSubview(coverImage)
        addSubview(gradient)

        coverImage.translatesAutoresizingMaskIntoConstraints = false
        gradient.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            coverImage.topAnchor.constraint(equalTo: topAnchor),
            coverImage.bottomAnchor.constraint(equalTo: bottomAnchor),
            coverImage.leadingAnchor.constraint(equalTo: leadingAnchor),
            coverImage.trailingAnchor.constraint(equalTo: trailingAnchor),

            gradient.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradient.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradient.heightAnchor.constraint(equalToConstant: 100),
        ])
    }
}

// MARK: - Configuration

extension ProfileCoverImage {
    func configure(user: UserCardModel) {
        // Only re-configure if the header URL changed
        guard self.user?.account?.headerStatic != user.account?.headerStatic else { return }

        self.user = user

        if let headerImageStr = user.account?.headerStatic, let headerImageURL = URL(string: headerImageStr) {
            coverImage.contentMode = .scaleAspectFill
            coverImage.sd_imageTransition = .fade
            coverImage.sd_setImage(with: headerImageURL, placeholderImage: coverImage.image, context: [.storeCacheType: SDImageCacheType.memory.rawValue])
        }
    }

    func optimisticUpdate(image: UIImage) {
        coverImage.contentMode = .scaleAspectFill
        coverImage.image = image
    }

    func onThemeChange() {
        backgroundColor = .custom.background
    }

    func didScroll(scrollView: UIScrollView) {
        let maxOffset = 120.0 - scrollView.safeAreaInsets.top
        if scrollView.contentOffset.y < maxOffset {
            coverImage.layer.opacity = 1 - Float(min(max(scrollView.contentOffset.y / maxOffset, 0), 1))
        } else if coverImage.layer.opacity > 0 {
            coverImage.layer.opacity = 0
        }
    }
}
