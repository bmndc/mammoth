//
//  SelectionCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 22/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class SelectionCell: UITableViewCell {
    let backgroundButton: UIButton = {
        let backgroundButton = UIButton()
        backgroundButton.translatesAutoresizingMaskIntoConstraints = true
        backgroundButton.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundButton.showsMenuAsPrimaryAction = true
        backgroundButton.backgroundColor = .clear
        return backgroundButton
    }()

    override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        backgroundColor = .custom.OVRLYSoftContrast
        selectionStyle = .none
        textLabel?.numberOfLines = 0
        detailTextLabel?.numberOfLines = 0
        addSubview(backgroundButton)
        backgroundButton.frame = backgroundButton.superview!.bounds
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Appearance changes

extension SelectionCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.backgroundColor = .custom.OVRLYSoftContrast
            }
        }
    }
}
