//
//  EmojiCell.swift
//  Mammoth
//
//  Created by Riley on 1/9/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

class EmojiCell: UICollectionViewCell {
    static let reuseIdentifier = "EmojiCell"

    private let mainStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 6
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .zero
        return stackView
    }()

    var image = UIImageView()
    var parentWidth: CGFloat?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        var x = 4
        if UIDevice.current.userInterfaceIdiom == .pad && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            x = 8
        }
        let y = parentWidth ?? bounds.width
        let z = CGFloat(y) / CGFloat(x)

        attributes.size = CGSize(width: z - CGFloat(((x + 1) * 20) / x), height: z - CGFloat(((x + 1) * 20) / x) + 12 + 6)

        return attributes
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        image.image = nil
    }

    func setupUI() {
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear

        contentView.addSubview(mainStack)
        mainStack.pinEdges()

        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(image)

        NSLayoutConstraint.activate([
            image.trailingAnchor.constraint(equalTo: mainStack.layoutMarginsGuide.trailingAnchor),
            image.heightAnchor.constraint(equalTo: mainStack.widthAnchor),
        ])
    }
}
