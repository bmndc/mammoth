//
//  PostCardHeaderExtension.swift
//  Mammoth
//
//  Created by Benoit Nolens on 09/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class PostCardHeaderExtension: UIView {
    // MARK: - Properties

    var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 5.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    var leadingMarginAnchor: NSLayoutXAxisAnchor {
        mainStackView.leadingAnchor
    }

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.feintContrast
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()

    var onPress: PostCardButtonCallback?
    private var postCard: PostCardModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        addGestureRecognizer(tapGesture)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        postCard = nil
        onPress = nil
        titleLabel.text = nil
    }

    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
    }
}

// MARK: - Setup UI

private extension PostCardHeaderExtension {
    func setupUI() {
        addSubview(mainStackView)

        let leadingConstraint = mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        leadingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStackView.heightAnchor.constraint(equalToConstant: 18),
            leadingConstraint,
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        mainStackView.addArrangedSubview(titleLabel)
        setupUIFromSettings()
    }
}

// MARK: - Estimated height

extension PostCardHeaderExtension {
    static func estimatedHeight() -> CGFloat {
        return 18
    }
}

// MARK: - Configuration

extension PostCardHeaderExtension {
    func configure(postCard: PostCardModel) {
        guard case .mastodon = postCard.data else { return }

        self.postCard = postCard

        if postCard.isReblogged {
            let normalized_username = postCard
                .rebloggerUsername
                .stripCustomEmojiShortcodes()
                .stripEmojis()
                .stripLeadingTrailingSpaces()
            titleLabel.text = String.localizedStringWithFormat(NSLocalizedString("post.reposted", comment: "Shows up over a post in the timeline indicating who reposted it."), normalized_username)
        }

        if postCard.isHashtagged {
            titleLabel.text = "[replace with hashtag]"
        }

        if postCard.isPrivateMention {
            titleLabel.text = NSLocalizedString("post.privateMention", comment: "Shows up over a post in the timeline indicating that it's been sent privately.")
            titleLabel.textColor = .custom.feintContrast
        } else if postCard.isTipAccount {
            titleLabel.text = NSLocalizedString("post.fromTipped", comment: "Shows up over a post in the timeline indicating that it's been sent privately.")
            titleLabel.textColor = .custom.gold
        }

        if let postCard = self.postCard {
            if postCard.isPrivateMention {
                backgroundColor = .custom.OVRLYSoftContrast
            } else if postCard.isTipAccount {
                // tip background.
            }
        } else {
            titleLabel.backgroundColor = .custom.background
        }
    }

    func onThemeChange() {
        if let postCard = postCard {
            if postCard.isPrivateMention {
                backgroundColor = .custom.OVRLYSoftContrast
            } else if postCard.isTipAccount {
                // tip background.
            }
        } else {
            titleLabel.backgroundColor = .custom.background
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        onThemeChange()
    }
}

// MARK: - Handlers

extension PostCardHeaderExtension {
    @objc func profileTapped() {
        guard case let .mastodon(status) = postCard?.data else { return }
        if let account = status.account {
            onPress?(.profile, true, .account(account))
        }
    }
}
