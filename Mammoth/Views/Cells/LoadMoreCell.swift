//
//  LoadMoreCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 16/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class LoadMoreCell: UITableViewCell {
    static let reuseIdentifier = "LoadMoreCell"

    private var bgView = UIView()
    var titleLabel = UILabel()
    var loadingIndicator = UIActivityIndicatorView()

    private var stackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let arrow = {
        let icon = UIImageView()
        icon.image = FontAwesome.image(fromChar: "\u{f062}", color: .custom.mediumContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2).withRenderingMode(.alwaysTemplate)
        icon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        icon.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        icon.contentMode = .scaleAspectFit
        return icon
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        isOpaque = true
        contentView.isOpaque = true
        contentView.backgroundColor = .custom.OVRLYSoftContrast
        backgroundColor = .custom.OVRLYSoftContrast

        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)

        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.textColor = .custom.mediumContrast
        titleLabel.isOpaque = true
        titleLabel.backgroundColor = .custom.OVRLYSoftContrast
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(arrow)
        stackView.addArrangedSubview(UIView())

        bgView.addSubview(stackView)

        configure()
        stackView.isHidden = false

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.isHidden = true
        bgView.addSubview(loadingIndicator)

        contentView.layer.masksToBounds = false

        let viewsDict = [
            "bgView": bgView,
            "stackView": stackView,
            "loadingIndicator": loadingIndicator,
        ]

        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))

        stackView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor).isActive = true
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[stackView]-12-|", options: [], metrics: nil, views: viewsDict))

        loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[loadingIndicator]-12-|", options: [], metrics: nil, views: viewsDict))
    }

    func configure(label: String = "Load older posts") {
        titleLabel.text = label
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.contentView.backgroundColor = .custom.background
                self.backgroundColor = .custom.background
                titleLabel.textColor = .custom.mediumContrast
                titleLabel.backgroundColor = .custom.background
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            stackView.isHidden = true
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
        } else {
            stackView.isHidden = false
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
        }
    }
}
