//
//  ErrorCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 26/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ErrorCell: UITableViewCell {
    static let reuseIdentifier = "ErrorCell"

    private var bgView = UIView()
    var titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        isOpaque = true
        contentView.isOpaque = true
        contentView.backgroundColor = .custom.background

        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        titleLabel.textColor = UIColor.secondaryLabel
        bgView.addSubview(titleLabel)

        titleLabel.text = NSLocalizedString("error.cantLoadMore", comment: "")
        titleLabel.isHidden = false

        contentView.layer.masksToBounds = false

        let viewsDict = [
            "bgView": bgView,
            "titleLabel": titleLabel,
        ]

        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))

        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel]-20-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-12-[titleLabel]-12-|", options: [], metrics: nil, views: viewsDict))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
