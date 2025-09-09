//
//  NavigationBarTitle.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class NavigationBarTitle: UIView {
    let titleLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        layoutMargins = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)

        titleLabel.textAlignment = .left
        titleLabel.font = .systemFont(ofSize: 24.0, weight: .semibold)
        titleLabel.textColor = .custom.highContrast
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
    }

    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
}
