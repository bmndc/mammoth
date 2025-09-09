//
//  DetailImageCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 28/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class DetailImageCell: UITableViewCell {
    var d = DetailImageView()

    override func prepareForReuse() {
        super.prepareForReuse()
        d.prepareForReuse()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialSetup()
    }

    func initialSetup() {
        contentView.addSubview(d)
        d.addFillConstraints(with: contentView)

        separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .clear
        selectedBackgroundView = bgColorView
        backgroundColor = .custom.quoteTint
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func willDisplayContentForStat(_ stat: Status?) -> Bool {
        return DetailImageView.willDisplayContentForStat(stat)
    }
}
