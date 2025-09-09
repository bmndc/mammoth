//
//  CarouselNavigationHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

import UIKit

class CarouselNavigationHeader: UIView {
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isBaselineRelativeArrangement = true
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let title: NavigationBarTitle
    let carousel: Carousel = .init(withContextButton: false)

    init(title: String) {
        self.title = NavigationBarTitle(title: title)
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI

private extension CarouselNavigationHeader {
    func setupUI() {
        backgroundColor = .clear

        title.translatesAutoresizingMaskIntoConstraints = false
        title.clipsToBounds = false
        carousel.translatesAutoresizingMaskIntoConstraints = false

        if UIDevice.current.userInterfaceIdiom == .phone {
            layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        } else {
            layoutMargins = .init(top: 9, left: 16, bottom: 0, right: 16)
        }

        if let text = title.titleLabel.text, !text.isEmpty {
            titleStackView.addArrangedSubview(title)
            mainStackView.addArrangedSubview(titleStackView)

            NSLayoutConstraint.activate([
                title.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
                title.heightAnchor.constraint(equalToConstant: 28),
            ])
        }

        mainStackView.addArrangedSubview(carousel)

        addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            carousel.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: -3),
            carousel.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant: 3),
            carousel.heightAnchor.constraint(equalToConstant: 36),
        ])
    }
}
