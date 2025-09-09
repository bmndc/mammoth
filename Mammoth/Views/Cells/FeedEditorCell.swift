//
//  FeedEditorCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 14/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class FeedEditorCell: UITableViewCell {
    static let reuseIdentifier = "FeedEditorCell"

    enum FeedEditorCellButtonActions {
        case enable
        case disable
        case delete
    }

    typealias FeedEditorCellButtonCallback = (_ item: FeedTypeItem,
                                              _ action: FeedEditorCellButtonActions) -> Void

    // MARK: - Properties

    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isBaselineRelativeArrangement = true
        stackView.spacing = 20.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.image = UIImage()
        iconView.contentMode = .left
        iconView.translatesAutoresizingMaskIntoConstraints = false
        return iconView
    }()

    private var rightAccessories: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .trailing
        stackView.isBaselineRelativeArrangement = true
        stackView.distribution = .fill
        stackView.semanticContentAttribute = .forceRightToLeft
        stackView.spacing = 12.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.clipsToBounds = false
        return stackView
    }()

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private var feedTypeItem: FeedTypeItem?
    private var onButtonPress: FeedEditorCellButtonCallback?

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        feedTypeItem = nil
        onButtonPress = nil
        titleLabel.text = nil
        iconView.alpha = 1
        setupUIFromSettings()

        for arrangedSubview in rightAccessories.arrangedSubviews {
            rightAccessories.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
    }
}

// MARK: - Setup UI

private extension FeedEditorCell {
    func setupUI() {
        clipsToBounds = false
        selectionStyle = .none
        separatorInset = .zero
        layoutMargins = .zero
        contentView.preservesSuperviewLayoutMargins = false
        contentView.backgroundColor = .custom.background
        tintColor = .custom.highContrast
        contentView.layoutMargins = .init(top: 16, left: 13, bottom: 16, right: 13)

        mainStackView.backgroundColor = .clear
        contentView.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])

        mainStackView.addArrangedSubview(iconView)
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(rightAccessories)

        // Don't compress but let siblings fill the space
        rightAccessories.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        rightAccessories.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 752), for: .horizontal)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 12),
        ])

        iconView.image = FontAwesome.image(fromChar: "\u{e411}").withRenderingMode(.alwaysTemplate)
        iconView.tintColor = .custom.softContrast

        setupUIFromSettings()
    }

    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
    }
}

// MARK: - Configuration

extension FeedEditorCell {
    func configure(feedTypeItem: FeedTypeItem, onButtonPress: @escaping FeedEditorCellButtonCallback) {
        self.feedTypeItem = feedTypeItem
        self.onButtonPress = onButtonPress

        if !feedTypeItem.isDraggable {
            iconView.alpha = 0
        }

        if feedTypeItem.isEnabled {
            if titleLabel.textColor != nil {
                titleLabel.textColor = nil
                titleLabel.attributedText = feedTypeItem.type.attributedTitle()
            }

            if feedTypeItem.isDraggable {
                // only draggable items can be disabled
                let button = self.button(with: "\u{f056}", weight: .regular)
                button.tintColor = .custom.highContrast
                rightAccessories.addArrangedSubview(button)

                button.addHandler { [weak self] in
                    guard let self, let feedTypeItem = self.feedTypeItem else { return }
                    self.onButtonPress?(feedTypeItem, .disable)
                }
            }
        } else {
            titleLabel.attributedText = feedTypeItem.type.attributedTitle()
            titleLabel.textColor = .custom.softContrast

            let button = self.button(with: "\u{f055}", weight: .bold)
            button.tintColor = .custom.highContrast
            rightAccessories.addArrangedSubview(button)

            button.addHandler { [weak self] in
                guard let self, let feedTypeItem = self.feedTypeItem else { return }
                self.onButtonPress?(feedTypeItem, .enable)
            }

            switch feedTypeItem.type {
            case let .community(instance):
                if instance != AccountsManager.shared.currentUser()?.server {
                    fallthrough
                }

            case .hashtag, .list, .channel:
                let button = self.button(with: "\u{e12e}", weight: .bold)
                button.tintColor = .custom.destructive
                rightAccessories.addArrangedSubview(button)

                button.addHandler { [weak self] in
                    guard let self, let feedTypeItem = self.feedTypeItem else { return }
                    self.onButtonPress?(feedTypeItem, .delete)
                }

            default:
                break
            }
        }

        onThemeChange()
    }

    func button(with char: String, weight: UIFont.Weight) -> UIButton {
        let imageSize = 21.0
        var imageSizeMultiplier: Double
        var imageContentMode: UIView.ContentMode

        if DeviceHelpers.isiOSAppOnMac() {
            imageSizeMultiplier = 4.0
            imageContentMode = .scaleAspectFit
        } else {
            imageSizeMultiplier = 1.0
            imageContentMode = .center
        }

        let button = UIButton(type: .custom)
        button.clipsToBounds = false
        button.contentEdgeInsets = .init(top: 0, left: -6, bottom: 0, right: 6)
        button.contentMode = imageContentMode
        let circleLineImage = FontAwesome.image(fromChar: char, size: imageSize * imageSizeMultiplier, weight: weight)
        button.setImage(circleLineImage.withRenderingMode(.alwaysTemplate), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: circleLineImage.size.width / imageSizeMultiplier),
            button.heightAnchor.constraint(equalToConstant: circleLineImage.size.height / imageSizeMultiplier),
        ])
        return button
    }

    func onThemeChange() {
        contentView.backgroundColor = .custom.background
    }

    func showLoader() {
        for arrangedSubview in rightAccessories.arrangedSubviews {
            rightAccessories.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        rightAccessories.addArrangedSubview(loader)
    }
}

// MARK: Actions

extension FeedEditorCell {}

// MARK: Appearance changes

extension FeedEditorCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.onThemeChange()
            }
        }
    }
}
