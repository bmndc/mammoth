//
//  ReadMoreButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 09/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

class ReadMoreButton: UIButton {
    init() {
        super.init(frame: .zero)
        setupUI()
        isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setTitle("Read more", for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        setTitleColor(.custom.highContrast, for: .normal)
        contentEdgeInsets = .init(top: 2, left: 0, bottom: 0, right: 3)
    }

    func configure(backgroundColor _: UIColor) {}
}
