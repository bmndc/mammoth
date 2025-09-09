//
//  ProfileNavigationTitle.swift
//  Mammoth
//
//  Created by Benoit Nolens on 20/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import SDWebImage
import UIKit

class ProfileNavigationTitle: UIView {
    // MARK: - Properties

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_: CGSize) -> CGSize {
        let width = CGRectGetWidth(titleLabel.bounds)
        let height = CGRectGetHeight(titleLabel.bounds)
        return CGSizeMake(width, height)
    }

    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
}

// MARK: - Setup UI

private extension ProfileNavigationTitle {
    func setupUI() {
        addSubview(titleLabel)
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = NSLocalizedString("navigator.profile", comment: "")
        titleLabel.layer.opacity = 0
        titleLabel.sizeToFit()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

extension ProfileNavigationTitle {
    func configure(title: String) {
        titleLabel.text = title
        titleLabel.sizeToFit()
    }
}

// MARK: - Configuration

extension ProfileNavigationTitle {
    func onThemeChange() {
        titleLabel.textColor = .label
    }

    func didScroll(scrollView: UIScrollView) {
        let startOffset = 120.0 - scrollView.safeAreaInsets.top
        let endOffset = 130.0 - scrollView.safeAreaInsets.top
        if scrollView.contentOffset.y > startOffset, scrollView.contentOffset.y < endOffset {
            let opacity = Float(min(max((scrollView.contentOffset.y - startOffset) / (endOffset - startOffset), 0), 1))
            titleLabel.layer.opacity = opacity
        } else if scrollView.contentOffset.y >= endOffset {
            titleLabel.layer.opacity = 1
        } else {
            titleLabel.layer.opacity = 0
        }
    }
}
