//
//  DetailCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class DetailCell: UITableViewCell {
    var d = DetailView()

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
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
