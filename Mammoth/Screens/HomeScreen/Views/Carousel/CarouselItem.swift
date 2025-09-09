//
//  CarouselItem.swift
//  Mammoth
//
//  Created by Benoit Nolens on 24/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class CarouselItem: UICollectionViewCell {
    static let reuseIdentifier = "CarouselItem"

    let titleLabel = UILabel()
    let menuButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = false
        button.isEnabled = false
        return button
    }()

    override var isSelected: Bool {
        didSet {
            menuButton.isEnabled = isSelected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 10

        if UIDevice.current.userInterfaceIdiom == .phone {
            contentView.layoutMargins = UIEdgeInsets(top: 9, left: 2, bottom: 9, right: 2)
        } else {
            contentView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        }

        titleLabel.textAlignment = .left
        titleLabel.font = .systemFont(ofSize: 16.0, weight: .semibold)
        titleLabel.textColor = .custom.highContrast
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        contentView.addSubview(menuButton)

        menuButton.pinEdges()

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
