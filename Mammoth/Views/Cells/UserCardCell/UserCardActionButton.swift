//
//  UserCardActionButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 10/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class UserCardActionButton: UIButton {
    enum ButtonType {
        case block
        case unblock
        case mute
        case unmute
        case addToList
        case removeFromList

        var title: String {
            switch self {
            case .mute:
                return "Mute"
            case .unmute:
                return "Unmute"
            case .block:
                return "Block"
            case .unblock:
                return "Unblock"
            case .addToList:
                return "Add"
            case .removeFromList:
                return "Remove"
            }
        }
    }

    enum ButtonSize {
        case small
        case big

        var fontSize: CGFloat {
            switch self {
            case .small:
                return 13
            case .big:
                return 15
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small:
                return 6
            case .big:
                return 8
            }
        }
    }

    var user: UserCardModel

    private var type: ButtonType {
        didSet {
            updateButton(user: user)
        }
    }

    var onPress: PostCardButtonCallback?

    init(user: UserCardModel, type: ButtonType, size: ButtonSize = .small) {
        self.user = user
        self.type = type
        super.init(frame: .zero)
        setupUI(type: type, size: size)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(type: ButtonType, size: ButtonSize) {
        layer.cornerRadius = size.cornerRadius
        clipsToBounds = true
        layer.cornerCurve = .continuous
        backgroundColor = .custom.followButtonBG
        setTitleColor(.custom.active, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 4.5, left: 11, bottom: 3.5, right: 11)
        titleLabel?.font = UIFont.systemFont(ofSize: size.fontSize, weight: .semibold)
        setTitle(type.title, for: .normal)

        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)

        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.defaultHigh, for: .vertical)

        addTarget(self, action: #selector(onTapped), for: .touchUpInside)

        if #available(iOS 15.0, *) {
            self.tintColor = .custom.baseTint
        }
    }

    func updateButton(user _: UserCardModel) {
        setTitle(type.title, for: .normal)
    }
}

// MARK: Actions

extension UserCardActionButton {
    @objc func onTapped() {
        triggerHapticImpact(style: .light)
        switch type {
        case .block:
            onPress?(.block, true, Optional.none)
            type = .unblock
        case .unblock:
            onPress?(.unblock, true, Optional.none)
            type = .block
        case .mute:
            onPress?(.muteForever, true, Optional.none)
            type = .unmute
        case .unmute:
            onPress?(.unmute, true, Optional.none)
            type = .mute
        case .addToList:
            onPress?(.addToList, true, Optional.none)
            type = .removeFromList
        case .removeFromList:
            onPress?(.removeFromList, true, Optional.none)
            type = .addToList
        }
    }
}
