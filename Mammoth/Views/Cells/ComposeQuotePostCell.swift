//
//  ComposeQuotePostCell.swift
//  Mammoth
//
//  Created by Riley Howard on 4/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

// Hosts a QuotePostView that shows either a muted or fully formed quote post.
class ComposeQuotePostCell: UITableViewCell {
    var quotePostURL: URL?
    let quotePostHostView = QuotePostHostView()
    let quoteBackgroundView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .custom.quoteTint
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.4
        view.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // background is inset a bit from self
        contentView.addSubview(quoteBackgroundView)

        // quotePostHostView is lined up with the background
        quotePostHostView.translatesAutoresizingMaskIntoConstraints = false
        quoteBackgroundView.addSubview(quotePostHostView)

        NSLayoutConstraint.activate([
            quoteBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 85),
            quoteBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            quoteBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            quoteBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            quotePostHostView.leadingAnchor.constraint(equalTo: quoteBackgroundView.leadingAnchor, constant: 12),
            quotePostHostView.trailingAnchor.constraint(equalTo: quoteBackgroundView.trailingAnchor, constant: -12),
            quotePostHostView.topAnchor.constraint(equalTo: quoteBackgroundView.topAnchor, constant: 8),
            quotePostHostView.bottomAnchor.constraint(equalTo: quoteBackgroundView.bottomAnchor, constant: -10),
        ])

        isUserInteractionEnabled = false
        backgroundColor = UIColor.clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateForQuotePost(_ qpURL: URL?) {
        if qpURL != quotePostURL {
            quotePostURL = qpURL
            quotePostHostView.updateForQuotePost(qpURL)
        }
    }
}
