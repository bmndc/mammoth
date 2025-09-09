//
//  InstanceCell.swift
//  Mammoth
//
//  Created by Riley Howard on 9/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

final class InstanceCell: UITableViewCell {
    static let reuseIdentifier = "InstanceCell"

    // MARK: - Properties

    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 8.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 4
        return stackView
    }()

    private var headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var headerTitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = -2
        return stackView
    }()

    private var addButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("generic.subscribe", comment: "Subscribe button label"), for: .normal)
        button.setTitleColor(.custom.active, for: .normal)
        button.backgroundColor = .custom.followButtonBG
        button.contentEdgeInsets = UIEdgeInsets(top: 4.5, left: 11, bottom: 3.5, right: 11)
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 15.0, *) {
            button.tintColor = .custom.baseTint
        }
        return button
    }()

    private var cardImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage()
        imageView.backgroundColor = .custom.quoteTint
        if GlobalStruct.circleProfiles {
            imageView.layer.cornerRadius = 22
        } else {
            imageView.layer.cornerRadius = 8
        }
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.active
        label.numberOfLines = 1
        return label
    }()

    private var serverStatsStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var userCountImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = FontAwesome.image(fromChar: "\u{f007}", size: 14).withTintColor(.custom.feintContrast, renderingMode: .alwaysOriginal)
        return imageView
    }()

    private var userCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        return label
    }()

    private var languagesImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = FontAwesome.image(fromChar: "\u{f0ac}", size: 14).withTintColor(.custom.feintContrast, renderingMode: .alwaysOriginal)
        return imageView
    }()

    private var languagesLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.custom.feintContrast
        return label
    }()

    private var descriptionLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.textColor = .custom.mediumContrast
        label.numberOfLines = 2
        return label
    }()

    private var instanceCard: InstanceCardModel?

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
        instanceCard = nil
        cardImageView.image = nil
        titleLabel.text = nil
        userCountLabel.text = nil
        languagesLabel.text = nil
        descriptionLabel.attributedText = nil
        setupUIFromSettings()
    }
}

// MARK: - Setup UI

private extension InstanceCell {
    func setupUI() {
        selectionStyle = .none
        separatorInset = .zero
        layoutMargins = .zero
        contentView.preservesSuperviewLayoutMargins = false
        contentView.backgroundColor = .custom.background
        contentView.layoutMargins = .init(top: 16, left: 13, bottom: 18, right: 13)

        contentView.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])

        mainStackView.addArrangedSubview(cardImageView)

        NSLayoutConstraint.activate([
            cardImageView.widthAnchor.constraint(equalToConstant: 44),
            cardImageView.heightAnchor.constraint(equalToConstant: 44),
        ])

        mainStackView.addArrangedSubview(contentStackView)
        contentStackView.addArrangedSubview(headerStackView)

        contentStackView.setCustomSpacing(-1, after: headerStackView)

        contentStackView.addArrangedSubview(descriptionLabel)

        headerStackView.addArrangedSubview(headerTitleStackView)
        headerStackView.addArrangedSubview(addButton)

        NSLayoutConstraint.activate([
            // Force header to fill the parent width to align the follow button right
            headerStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),

            // Force addButton to have a minimum width (usefull when in loading state)
            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
        ])

        headerTitleStackView.addArrangedSubview(titleLabel)
        headerTitleStackView.addArrangedSubview(serverStatsStack)

        serverStatsStack.addArrangedSubview(userCountImage)
        serverStatsStack.addArrangedSubview(userCountLabel)
        serverStatsStack.addArrangedSubview(languagesImage)
        serverStatsStack.addArrangedSubview(languagesLabel)

        setupUIFromSettings()
    }

    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        userCountLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        languagesLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        descriptionLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        descriptionLabel.lineSpacing = -2
    }
}

// MARK: - Configuration

extension InstanceCell {
    func configure(instance: InstanceCardModel, showAddButton: Bool = true) {
        instanceCard = instance

        titleLabel.text = instance.name

        languagesLabel.text = (instance.languages?.first ?? "EN").uppercased()
        let users = Int(instance.numberOfUsers ?? "0")?.formatUsingAbbrevation() ?? "0"
        userCountLabel.text = "\(users)"

        if let desc = instance.description {
            descriptionLabel.isHidden = false
            descriptionLabel.text = desc
        } else {
            descriptionLabel.isHidden = true
        }

        guard let urlString = instance.imageURL,
              let imageURL = URL(string: urlString) else { return }

        cardImageView.sd_setImage(with: imageURL, completed: nil)
        configureAddButton(isPinned: instance.isPinned)

        addButton.isHidden = !showAddButton

        onThemeChange()
    }

    func configureAddButton(isPinned: Bool) {
        if !isPinned {
            addButton.setTitle(NSLocalizedString("generic.subscribe", comment: "Subscribe button label"), for: .normal)
            addButton.removeTarget(self, action: #selector(unpinTapped), for: .touchUpInside)
            addButton.addTarget(self, action: #selector(pinTapped), for: .touchUpInside)
            addButton.showsMenuAsPrimaryAction = true

        } else {
            addButton.setTitle(NSLocalizedString("generic.unsubscribe", comment: "Unsubscribe button label"), for: .normal)
            addButton.removeTarget(self, action: #selector(pinTapped), for: .touchUpInside)
            addButton.addTarget(self, action: #selector(unpinTapped), for: .touchUpInside)
            addButton.showsMenuAsPrimaryAction = true
        }
    }

    func onThemeChange() {
        contentView.backgroundColor = .custom.background
        addButton.backgroundColor = .custom.followButtonBG
        cardImageView.backgroundColor = .custom.quoteTint
    }
}

// MARK: Actions

extension InstanceCell {
    @objc func pinTapped() {
        triggerHapticImpact(style: .light)
        if let instanceName = instanceCard?.name {
            InstanceManager.shared.pinInstance(instanceName)
            instanceCard?.isPinned = true
        }
    }

    @objc func unpinTapped() {
        triggerHapticImpact(style: .light)
        if let instanceName = instanceCard?.name {
            InstanceManager.shared.unpinInstance(instanceName)
            instanceCard?.isPinned = false
        }
    }
}

// MARK: Appearance changes

extension InstanceCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.onThemeChange()
            }
        }
    }
}
