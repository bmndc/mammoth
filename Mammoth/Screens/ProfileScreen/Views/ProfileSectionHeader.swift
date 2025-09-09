//
//  ProfileSectionHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 13/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol ProfileSectionHeaderDelegate: AnyObject {
    func didChangeSegment(with selectedSegment: ProfileViewModel.ViewTypes)
}

class ProfileSectionHeader: UITableViewHeaderFooterView {
    static let reuseIdentifier = "ProfileSectionHeader"

    var hasSubscription: Bool?

    private var segmentedControl = UISegmentedControl(items: [
        ProfileViewModel.ViewTypes.posts.labelText(),
        ProfileViewModel.ViewTypes.postsAndReplies.labelText(),
    ])
    weak var delegate: ProfileSectionHeaderDelegate?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        segmentedControl.frame.size.height = 38.0
    }
}

// MARK: - Setup UI

private extension ProfileSectionHeader {
    func setupUI() {
        isOpaque = true
        contentView.backgroundColor = .custom.background

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.tintColor = .custom.baseTint

        addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(segmentedValueChanged(_:)), for: .valueChanged)

        NSLayoutConstraint.activate([
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
        ])
    }
}

// MARK: - Configuration

extension ProfileSectionHeader {
    func configure() {
        if hasSubscription == true, segmentedControl.numberOfSegments == 2 {
            segmentedControl.insertSegment(withTitle: ProfileViewModel.ViewTypes.subscription.labelText(), at: 2, animated: true)
        }
    }

    func onThemeChange() {
        contentView.backgroundColor = .custom.background
        segmentedControl.tintColor = .custom.baseTint
    }
}

// MARK: - Handlers

extension ProfileSectionHeader {
    @objc func segmentedValueChanged(_ sender: UISegmentedControl!) {
        if let selected = ProfileViewModel.ViewTypes(rawValue: sender.selectedSegmentIndex) {
            delegate?.didChangeSegment(with: selected)
        }
    }
}
