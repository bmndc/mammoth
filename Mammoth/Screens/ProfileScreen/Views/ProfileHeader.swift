//
//  ProfileHeader.swift
//  Mammoth
//
//  Created by Benoit Nolens on 13/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import ArkanaKeys
import Meta
import MetaTextKit
import UIKit

class ProfileHeader: UIView {
    // MARK: - Properties

    private let wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 13, bottom: 5, trailing: 13)
        return stackView
    }()

    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 8
        stackView.layer.cornerCurve = .continuous
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 35, leading: 0, bottom: 13, trailing: 0)
        return stackView
    }()

    private let extraInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 13
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 8
        stackView.layer.cornerCurve = .continuous
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 17, leading: 16, bottom: 17, trailing: 16)
        return stackView
    }()

    private var extraInfoConstraints: [NSLayoutConstraint]?

    private let profilePicBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = PostCardProfilePic.ProfilePicSize.big.cornerRadius() + 3
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let profilePic = PostCardProfilePic(withSize: .big)

    private let headerTitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 21
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private let nameLabel: MetaLabel = {
        let label = MetaLabel()
        label.textColor = .custom.displayNames
        label.numberOfLines = 1
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.textContainer.lineFragmentPadding = 0
        label.isUserInteractionEnabled = false
        return label
    }()

    private let userTagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular)
        label.textColor = .custom.softContrast
        label.textAlignment = .center
        return label
    }()

    private var descriptionLabel: MetaText = {
        let metaText = MetaText()
        metaText.textView.backgroundColor = .clear
        metaText.textView.textAlignment = .center
        metaText.textView.translatesAutoresizingMaskIntoConstraints = false
        metaText.textView.isEditable = false
        metaText.textView.isScrollEnabled = false
        metaText.textView.isSelectable = false
        metaText.textView.textContainer.lineFragmentPadding = 0
        metaText.textView.textContainerInset = .zero
        metaText.textView.textDragInteraction?.isEnabled = false

        metaText.textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        metaText.textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        metaText.textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        metaText.textView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        return metaText
    }()

    private let followButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.custom.highContrast, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .semibold)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.custom.outlines.cgColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        return button
    }()

    private let tipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.custom.gold, for: .normal)
        button.setTitle(NSLocalizedString("profile.subscribe", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .semibold)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.custom.outlines.cgColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        button.isHidden = true
        return button
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private let statsStack: UIStackView = {
        let stackView = UIStackView()

        if UIScreen.main.bounds.width < 380 {
            stackView.axis = .vertical
        } else {
            stackView.axis = .horizontal
        }
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 0
        return stackView
    }()

    private let followersButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.custom.softContrast, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
        button.titleLabel?.textAlignment = .left
        button.contentVerticalAlignment = .top
        return button
    }()

    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular)
        label.textColor = .custom.softContrast
        label.textAlignment = .left
        return label
    }()

    var user: UserCardModel?
    var screenType: ProfileViewModel.ProfileScreenType?
    var onButtonPress: UserCardButtonCallback?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup UI

private extension ProfileHeader {
    func setupUI() {
        backgroundColor = .clear
        addSubview(wrapperStackView)

        wrapperStackView.addArrangedSubview(mainStackView)

        addSubview(profilePicBackground)
        profilePicBackground.addSubview(profilePic)
        profilePicBackground.backgroundColor = .custom.blurredOVRLYNeut

        let blurredBackgroundMain = BlurredBackground()
        mainStackView.addSubview(blurredBackgroundMain)
        blurredBackgroundMain.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            blurredBackgroundMain.topAnchor.constraint(equalTo: mainStackView.topAnchor),
            blurredBackgroundMain.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            blurredBackgroundMain.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            blurredBackgroundMain.bottomAnchor.constraint(equalTo: mainStackView.bottomAnchor),
        ])

        let blurredBackgroundExtra = BlurredBackground()
        extraInfoStackView.addSubview(blurredBackgroundExtra)
        blurredBackgroundExtra.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            blurredBackgroundExtra.topAnchor.constraint(equalTo: extraInfoStackView.topAnchor),
            blurredBackgroundExtra.leadingAnchor.constraint(equalTo: extraInfoStackView.leadingAnchor),
            blurredBackgroundExtra.trailingAnchor.constraint(equalTo: extraInfoStackView.trailingAnchor),
            blurredBackgroundExtra.bottomAnchor.constraint(equalTo: extraInfoStackView.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
            wrapperStackView.topAnchor.constraint(equalTo: topAnchor),
            wrapperStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -wrapperStackView.layoutMargins.bottom),
            wrapperStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: wrapperStackView.layoutMargins.left),
            wrapperStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -wrapperStackView.layoutMargins.right),

            mainStackView.topAnchor.constraint(equalTo: wrapperStackView.topAnchor, constant: 82),
            mainStackView.leadingAnchor.constraint(equalTo: wrapperStackView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: wrapperStackView.trailingAnchor),

            profilePicBackground.widthAnchor.constraint(equalTo: profilePic.widthAnchor, constant: 3 * 2),
            profilePicBackground.heightAnchor.constraint(equalTo: profilePic.heightAnchor, constant: 3 * 2),
            profilePicBackground.topAnchor.constraint(equalTo: topAnchor),
            profilePicBackground.centerXAnchor.constraint(equalTo: centerXAnchor),

            profilePic.centerXAnchor.constraint(equalTo: profilePicBackground.centerXAnchor),
            profilePic.centerYAnchor.constraint(equalTo: profilePicBackground.centerYAnchor),
        ])

        mainStackView.addArrangedSubview(headerTitleStackView)
        headerTitleStackView.addArrangedSubview(nameLabel)
        headerTitleStackView.addArrangedSubview(userTagLabel)

        mainStackView.addArrangedSubview(contentStackView)
        contentStackView.addArrangedSubview(buttonStackView)
        buttonStackView.addArrangedSubview(tipButton)
        buttonStackView.addArrangedSubview(followButton)

        contentStackView.addArrangedSubview(statsStack)

        statsStack.addArrangedSubview(followersButton)
        statsStack.addArrangedSubview(statsLabel)

        statsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        followersButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            headerTitleStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
        ])

        followButton.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 420, constant: -(contentStackView.layoutMargins.left + contentStackView.layoutMargins.right))
        tipButton.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 420, constant: -(contentStackView.layoutMargins.left + contentStackView.layoutMargins.right))

        profilePic.onPress = profilePicTapped
        profilePic.isContextMenuEnabled = false
        followersButton.addTarget(self, action: #selector(onFollowersTapped), for: .touchUpInside)

        descriptionLabel.textView.linkDelegate = self
    }

    func profilePicTapped(_: PostCardButtonType,
                          _: Bool,
                          _: PostCardButtonCallbackData?)
    {
        let photo = SKPhoto(url: user?.imageURL ?? "")
        let originImage = profilePic.profileImageView.image ?? UIImage()
        let browser = SKPhotoBrowser(originImage: originImage, photos: [photo], animatedFromView: profilePic.profileImageView, imageText: "", imageText2: 0, imageText3: 0, imageText4: "")
        SKPhotoBrowserOptions.enableSingleTapDismiss = false
        SKPhotoBrowserOptions.displayCounterLabel = false
        SKPhotoBrowserOptions.displayBackAndForwardButton = false
        SKPhotoBrowserOptions.displayAction = false
        SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
        SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
        SKPhotoBrowserOptions.displayCloseButton = false
        SKPhotoBrowserOptions.displayStatusbar = false
        getTopMostViewController()?.present(browser, animated: true, completion: {})
    }

    @objc func onFollowingTapped() {
        if let user = user {
            onButtonPress?(.openFollowing, .user(user))
        }
    }

    @objc func onFollowersTapped() {
        if let user = user {
            onButtonPress?(.openFollowers, .user(user))
        }
    }
}

// MARK: - Configuration

extension ProfileHeader {
    func configure(user: UserCardModel, screenType: ProfileViewModel.ProfileScreenType) {
        // Only re-configure if the user changed
        guard self.user != user else { return }

        self.user = user
        self.screenType = screenType

        onThemeChange()

        profilePic.configure(user: user)
        profilePic.willDisplay()

        if let content = user.metaName {
            nameLabel.configure(content: content)
        } else {
            nameLabel.text = user.name
        }

        userTagLabel.attributedText = formatUserTag(user: user)

        if let description = user.metaDescription {
            descriptionLabel.configure(content: description)
        } else {
            descriptionLabel.textView.text = user.description
        }

        if let description = user.description, !description.isEmpty {
            if !contentStackView.arrangedSubviews.contains(descriptionLabel.textView) {
                contentStackView.insertArrangedSubview(descriptionLabel.textView, at: 0)
                descriptionLabel.textView.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 420, constant: -(contentStackView.layoutMargins.left + contentStackView.layoutMargins.right))
            }
        } else {
            if contentStackView.arrangedSubviews.contains(descriptionLabel.textView) {
                contentStackView.removeArrangedSubview(descriptionLabel.textView)
                descriptionLabel.textView.removeFromSuperview()
                descriptionLabel.textView.constraints.forEach { $0.isActive = false }
            }
        }
        if screenType == .own {
            let buttonLabel = NSMutableAttributedString(string: NSLocalizedString("profile.edit", comment: ""))
            let imageAttachment = NSTextAttachment()
            let caretImage = FontAwesome.image(fromChar: "\u{f0d7}", size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .bold).withRenderingMode(.alwaysTemplate)
            imageAttachment.image = caretImage
            imageAttachment.bounds = CGRect(x: 0, y: -3, width: caretImage.size.width, height: caretImage.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            buttonLabel.append(NSAttributedString(string: "  "))
            buttonLabel.append(imageString)

            followButton.setAttributedTitle(buttonLabel, for: .normal)
            followButton.showsMenuAsPrimaryAction = true
            followButton.menu = createContextMenu()
        } else {
            switch user.followStatus {
            case .unknown:
                fallthrough
            case .inProgress:
                fallthrough
            case .unfollowRequested:
                fallthrough
            case .notFollowing:
                if let followedBy = self.user?.relationship?.followedBy, followedBy {
                    followButton.setTitle(NSLocalizedString("profile.followBack", comment: ""), for: .normal)
                } else {
                    followButton.setTitle(NSLocalizedString("profile.follow", comment: ""), for: .normal)
                }
                followButton.removeTarget(self, action: #selector(unfollowTapped), for: .touchUpInside)
                followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
            case .followRequested:
                fallthrough
            case .following:
                followButton.setTitle(NSLocalizedString("profile.unfollow", comment: ""), for: .normal)
                followButton.removeTarget(self, action: #selector(followTapped), for: .touchUpInside)
                followButton.addTarget(self, action: #selector(unfollowTapped), for: .touchUpInside)
            case .followAwaitingApproval:
                followButton.setTitle(NSLocalizedString("profile.awaitingApproval", comment: ""), for: .normal)
                followButton.removeTarget(self, action: #selector(followTapped), for: .touchUpInside)
                followButton.addTarget(self, action: #selector(unfollowTapped), for: .touchUpInside)
            case .none:
                followButton.setTitle(NSLocalizedString("profile.follow", comment: ""), for: .normal)
                followButton.removeTarget(self, action: #selector(unfollowTapped), for: .touchUpInside)
                followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
            }
        }

        configureSubscribeButton()

        let joinedOn = user.joinedOn?.toString(dateStyle: .short, timeStyle: .none) ?? ""
        if UIScreen.main.bounds.width < 380 {
            statsLabel.text = String.localizedStringWithFormat(NSLocalizedString("profile.joinedOn", comment: ""), joinedOn)
        } else {
            statsLabel.text = " - " + String.localizedStringWithFormat(NSLocalizedString("profile.joinedOn", comment: ""), joinedOn)
        }

        followersButton.setTitle(String.localizedStringWithFormat(user.followersCount == "1" ? NSLocalizedString("profile.followers.singular", comment: "") : NSLocalizedString("profile.followers.plural", comment: ""), user.followersCount), for: .normal)

        // Clear all fields
        if let infoConstraints = extraInfoConstraints {
            for arrangedSubview in extraInfoStackView.arrangedSubviews {
                extraInfoStackView.removeArrangedSubview(arrangedSubview)
                arrangedSubview.removeFromSuperview()
            }

            wrapperStackView.removeArrangedSubview(extraInfoStackView)
            extraInfoStackView.removeFromSuperview()
            NSLayoutConstraint.deactivate(infoConstraints)
        }
        extraInfoConstraints = nil

        // Set all fields
        if let fields = user.fields, !fields.isEmpty {
            wrapperStackView.addArrangedSubview(extraInfoStackView)

            extraInfoConstraints = [
                extraInfoStackView.trailingAnchor.constraint(equalTo: wrapperStackView.trailingAnchor),
            ]

            NSLayoutConstraint.activate(extraInfoConstraints!)

            for (index, data) in fields.enumerated() {
                let field = ProfileField(field: data)
                field.onButtonPress = onButtonPress
                field.translatesAutoresizingMaskIntoConstraints = false
                extraInfoStackView.addArrangedSubview(field)

                extraInfoConstraints?.append(field.leadingAnchor.constraint(equalTo: extraInfoStackView.leadingAnchor, constant: 16))
                extraInfoConstraints?.append(field.trailingAnchor.constraint(equalTo: extraInfoStackView.trailingAnchor, constant: -16))

                if index < fields.count - 1 {
                    let seperator = ProfileFieldSeperator()
                    seperator.translatesAutoresizingMaskIntoConstraints = false
                    extraInfoStackView.addArrangedSubview(seperator)
                    extraInfoConstraints?.append(seperator.leadingAnchor.constraint(equalTo: extraInfoStackView.leadingAnchor, constant: 16))
                    extraInfoConstraints?.append(seperator.trailingAnchor.constraint(equalTo: extraInfoStackView.trailingAnchor, constant: -16))
                    extraInfoConstraints?.append(seperator.heightAnchor.constraint(equalToConstant: 1))
                }
            }

            NSLayoutConstraint.activate(extraInfoConstraints!)
        }
    }

    func optimisticUpdate(image: UIImage) {
        profilePic.optimisticUpdate(image: image)
    }

    func onThemeChange() {
        profilePicBackground.backgroundColor = .custom.blurredOVRLYNeut
        profilePicBackground.layer.cornerRadius = PostCardProfilePic.ProfilePicSize.big.cornerRadius() + 3
        profilePic.onThemeChange()

        if let user = user {
            userTagLabel.attributedText = formatUserTag(user: user)
        }

        descriptionLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .light),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]

        descriptionLabel.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        descriptionLabel.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 12
            style.alignment = .center
            return style
        }()

        nameLabel.textColor = .custom.displayNames
        nameLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 4, weight: .bold),
            .foregroundColor: UIColor.custom.highContrast,
        ]
        nameLabel.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 4, weight: .bold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        userTagLabel.textColor = .custom.softContrast
        followButton.setTitleColor(.custom.highContrast, for: .normal)
        followButton.layer.borderColor = UIColor.custom.outlines.cgColor
        tipButton.layer.borderColor = UIColor.custom.outlines.cgColor
        followersButton.setTitleColor(.custom.softContrast, for: .normal)
        statsLabel.textColor = .custom.softContrast

        if let screenType = screenType, screenType == .own {
            let buttonLabel = NSMutableAttributedString(string: NSLocalizedString("profile.edit", comment: ""))
            let imageAttachment = NSTextAttachment()
            let caretImage = FontAwesome.image(fromChar: "\u{f0d7}", size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .bold).withRenderingMode(.alwaysTemplate)
            imageAttachment.image = caretImage
            imageAttachment.bounds = CGRect(x: 0, y: -3, width: caretImage.size.width, height: caretImage.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            buttonLabel.append(NSAttributedString(string: "  "))
            buttonLabel.append(imageString)

            followButton.setAttributedTitle(buttonLabel, for: .normal)
        }

        for view in extraInfoStackView.arrangedSubviews {
            if let field = view as? ProfileField {
                field.onThemeChange()
            }
        }

        if screenType == .own {
            followButton.menu = createContextMenu()
        }

        if let user, let screenType {
            configure(user: user, screenType: screenType)
        }
    }

    @objc func followTapped() {
        followButton.setTitle(NSLocalizedString("profile.unfollow", comment: ""), for: .normal)
        triggerHapticImpact(style: .light)

        if let userCard = user, let account = userCard.account {
            Task {
                do {
                    let _ = try await FollowManager.shared.followAccountAsync(account)

                    DispatchQueue.main.async {
                        self.user?.syncFollowStatus()
                    }

                    AnalyticsManager.track(event: .follow)

                    if userCard.followStatus != .followRequested {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableSuggestions"), object: nil)
                        }
                    }
                } catch {
                    log.error("Follow error: \(error)")
                }
            }
        }
    }

    @objc func unfollowTapped() {
        followButton.setTitle(NSLocalizedString("profile.follow", comment: ""), for: .normal)
        triggerHapticImpact(style: .light)

        if let userCard = user, let account = userCard.account {
            Task {
                do {
                    let _ = try await FollowManager.shared.unfollowAccountAsync(account)

                    DispatchQueue.main.async {
                        self.user?.syncFollowStatus()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableSuggestions"), object: nil)
                    }

                    AnalyticsManager.track(event: .unfollow)
                } catch {
                    log.error("Unfollow error: \(error)")
                }
            }
        }
    }

    @objc func subscribeTapped() {
        triggerHapticImpact(style: .light)

        if let user = user, let currentAccount = AccountsManager.shared.currentAccount?.fullAcct {
            // get user theme.
            var theme = "light"
            if GlobalStruct.overrideTheme == 1 || traitCollection.userInterfaceStyle == .light {
                theme = "light"
            } else if GlobalStruct.overrideTheme == 2 || traitCollection.userInterfaceStyle == .dark {
                theme = "dark"
            }
            var tipUser: UserCardModel?
            var tipUsername: String?
            switch user.isTippable {
            case true:
                tipUser = user
                tipUsername = user.username
            case false:
                tipUser = user.tippableAccount?.user
                tipUsername = user.tippableAccount?.accountname
            }
            if let tipUser, let tipAccount = tipUser.account, let tipUsername, let url = URL(string: "https://\(ArkanaKeys.Global().subClubDomain)/@\(tipUsername)/subscribe?callback=mammoth://subclub&id=@\(currentAccount)&theme=\(theme)") {
                FollowManager.shared.followAccount(tipAccount)
                var vc: WebViewController!
                if let tippableUserCard = user.tippableAccount?.user {
                    vc = WebViewController(url: url.absoluteString, onClose: {
                        if let acct = tippableUserCard.account, tippableUserCard.isTippable == true {
                            FollowManager.shared.followStatusForAccount(acct, requestUpdate: .force)

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak acct] in
                                if let acct {
                                    FollowManager.shared.followStatusForAccount(acct, requestUpdate: .force)
                                }
                            }
                        }
                    })
                } else {
                    vc = WebViewController(url: url.absoluteString, onClose: {
                        if let acct = user.account, user.isTippable == true {
                            FollowManager.shared.followStatusForAccount(acct, requestUpdate: .force)

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak acct] in
                                if let acct {
                                    FollowManager.shared.followStatusForAccount(acct, requestUpdate: .force)
                                }
                            }
                        }
                    })
                }

                if let presentingVC = getTopMostViewController() {
                    presentingVC.present(UINavigationController(rootViewController: vc), animated: true)
                }
            }
        }
    }

    @objc func unsubscribeTapped() {
        triggerHapticImpact(style: .light)

        if let user = user {
            var tipUser: UserCardModel?
            switch user.isTippable {
            case true:
                tipUser = user
            case false:
                tipUser = user.tippableAccount?.user
            }
            if let tipUser, let tipAccount = tipUser.account {
                FollowManager.shared.unfollowAccount(tipAccount)
                user.syncFollowStatus()
                let vc = NewPostViewController()
                vc.isModalInPresentation = true
                vc.fromPro = true
                vc.proText = "@\(tipAccount.acct) unsubscribe"
                vc.canPost = true
                vc.whoCanReply = .direct
                vc.hasEditedText = true
                if let presentingVC = getTopMostViewController() {
                    presentingVC.present(UINavigationController(rootViewController: vc), animated: true)
                }
            }
        }
    }

    func formatUserTag(user: UserCardModel) -> NSAttributedString {
        let userTag = NSMutableAttributedString(string: "")

        if user.isLocked {
            let imageAttachment = NSTextAttachment()
            let lockImage = FontAwesome.image(fromChar: "\u{f023}", color: UIColor.custom.softContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2)
            imageAttachment.image = lockImage
            imageAttachment.bounds = CGRect(x: 0, y: -2, width: lockImage.size.width, height: lockImage.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            userTag.append(imageString)
            userTag.append(NSAttributedString(string: " "))
        }

        if user.isBot {
            let imageAttachment = NSTextAttachment()
            let botImage = FontAwesome.image(fromChar: "\u{f544}", color: UIColor.custom.softContrast, size: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2)
            imageAttachment.image = botImage
            imageAttachment.bounds = CGRect(x: 0, y: -2, width: botImage.size.width, height: botImage.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            userTag.append(imageString)
            userTag.append(NSAttributedString(string: " "))
        }

        userTag.append(NSAttributedString(string: user.userTag))

        return userTag
    }

    func configureSubscribeButton() {
        // configure subscribe button.
        if let user = user {
            if !user.isSelf, user.isTippable {
                tipButton.isHidden = false
                // user is subscribed:
                if user.followStatus == .following {
                    followButton.isHidden = true
                    tipButton.removeTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
                    tipButton.addTarget(self, action: #selector(unsubscribeTapped), for: .touchUpInside)
                    tipButton.setTitle(NSLocalizedString("profile.subscribed", comment: ""), for: .normal)
                } else {
                    followButton.isHidden = false
                    tipButton.removeTarget(self, action: #selector(unsubscribeTapped), for: .touchUpInside)
                    tipButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
                    tipButton.setTitle(NSLocalizedString("profile.subscribe", comment: ""), for: .normal)
                }
            } else if !user.isSelf, user.tippableAccount != nil {
                tipButton.isHidden = false
                // user is subscribed:
                if user.tippableAccount?.isFollowed == true {
                    tipButton.removeTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
                    tipButton.addTarget(self, action: #selector(unsubscribeTapped), for: .touchUpInside)
                    tipButton.setTitle(NSLocalizedString("profile.subscribed", comment: ""), for: .normal)
                } else {
                    tipButton.removeTarget(self, action: #selector(unsubscribeTapped), for: .touchUpInside)
                    tipButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
                    tipButton.setTitle(NSLocalizedString("profile.subscribe", comment: ""), for: .normal)
                }
            }
        }
    }
}

extension ProfileHeader: MetaTextViewDelegate {
    func metaTextView(_: MetaTextView, didSelectMeta meta: Meta) {
        switch meta {
        case let .url(_, _, urlString, _):
            if let url = URL(string: urlString) {
                onButtonPress?(.link, .url(url))
            }
        case let .mention(_, mention, userInfo):
            if let userInfo = userInfo,
               let firstItem = userInfo.first,
               let value = firstItem.value as? String,
               let url = URL(string: value),
               let host = url.host
            {
                onButtonPress?(.link, .mention("@\(mention)@\(host)/"))
            } else {
                onButtonPress?(.link, .mention(mention))
            }
        case let .hashtag(_, hashtag, _):
            onButtonPress?(.link, .hashtag(hashtag))
        case let .email(text, _):
            onButtonPress?(.link, .email(text))
        default:
            break
        }
    }
}

// MARK: Appearance changes

extension ProfileHeader {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        onThemeChange()
    }
}

// MARK: - Context menu creators

extension ProfileHeader {
    func createContextMenu() -> UIMenu {
        let options = [
            createContextMenuAction(NSLocalizedString("profile.edit.avatar", comment: ""), .editAvatar),
            createContextMenuAction(NSLocalizedString("profile.edit.header", comment: ""), .editHeader),
            createContextMenuAction(NSLocalizedString("profile.edit.details", comment: ""), .editDetails),
            createContextMenuAction(NSLocalizedString("profile.edit.infoAndLinks", comment: ""), .editInfoAndLink),
        ]

        return UIMenu(title: NSLocalizedString("profile.edit", comment: ""), options: [.displayInline], children: options)
    }

    private func createContextMenuAction(_ title: String, _ buttonType: UserCardButtonType) -> UIAction {
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || traitCollection.userInterfaceStyle == .dark {
            color = .white
        }

        let action = UIAction(title: title,
                              image: buttonType.icon(symbolConfig: userCardSymbolConfig, weight: .bold)?.withTintColor(color),
                              identifier: nil)
        { [weak self] _ in
            guard let self else { return }
            if let user = self.user {
                self.onButtonPress?(buttonType, .user(user))
            }
        }
        action.accessibilityLabel = title
        return action
    }
}

// MARK: - Profile field

final class ProfileField: UIStackView, MetaLabelDelegate {
    private let valueStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let titleLabel: MetaLabel = {
        let label = MetaLabel()
        label.textAlignment = .left
        label.numberOfLines = 1
        label.textContainer.lineFragmentPadding = 0
        return label
    }()

    private let verifiedImage = UIImageView(image: FontAwesome.image(fromChar: "\u{e416}", size: 15, weight: .bold).withConfiguration(userCardSymbolConfig).withTintColor(.custom.mediumContrast, renderingMode: .alwaysTemplate))

    private let descriptionLabel: MetaLabel = {
        let label = MetaLabel()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.isOpaque = true
        label.textContainer.lineFragmentPadding = 0
        return label
    }()

    private let field: HashType

    var onButtonPress: UserCardButtonCallback?

    init(field: HashType) {
        self.field = field
        super.init(frame: .zero)
        setupUI()

        if let name = field.metaName {
            titleLabel.configure(content: name)
        }

        if let verifiedAt = field.verifiedAt, !verifiedAt.isEmpty {
            valueStack.insertArrangedSubview(verifiedImage, at: 0)
            verifiedImage.tintColor = .custom.mediumContrast
            verifiedImage.contentMode = .scaleAspectFit
            verifiedImage.transform = CGAffineTransform(translationX: 0, y: 4)
            verifiedImage.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
            verifiedImage.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        }

        descriptionLabel.linkDelegate = self

        // long press to copy the post text
        let textLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onTextLongPress))
        descriptionLabel.addGestureRecognizer(textLongPressGesture)

        if let description = field.metaValue {
            descriptionLabel.configure(content: description)
        }
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        axis = .vertical
        alignment = .top
        distribution = .fill
        spacing = 4
        backgroundColor = .clear

        addArrangedSubview(titleLabel)
        addArrangedSubview(valueStack)

        valueStack.addArrangedSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            valueStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])

        onThemeChange()
    }

    @objc private func onTextLongPress(recognizer: UIGestureRecognizer) {
        if let view = recognizer.view, let superview = recognizer.view?.superview {
            view.becomeFirstResponder()
            let menuController = UIMenuController.shared

            let copyItem = UIMenuItem(title: NSLocalizedString("generic.copy", comment: ""), action: #selector(copyText))
            menuController.menuItems = [copyItem]

            menuController.showMenu(from: superview, rect: view.frame)
        }
    }

    @objc private func copyText() {
        UIPasteboard.general.setValue(field.metaValue?.original ?? "", forPasteboardType: "public.utf8-plain-text")
    }

    func onThemeChange() {
        verifiedImage.tintColor = .custom.mediumContrast

        titleLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular),
            .foregroundColor: UIColor.custom.feintContrast,
        ]
        titleLabel.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular),
            .foregroundColor: UIColor.custom.feintContrast,
        ]
        if let name = field.metaName {
            titleLabel.configure(content: name)
        }

        descriptionLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        descriptionLabel.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 1, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        if let description = field.metaValue {
            descriptionLabel.configure(content: description)
        }
    }

    func metaLabel(_: MetaTextKit.MetaLabel, didSelectMeta meta: Meta) {
        switch meta {
        case let .url(_, _, urlString, _):
            if let url = URL(string: urlString) {
                onButtonPress?(.link, .url(url))
            }
        case let .mention(_, mention, userInfo):
            if let userInfo = userInfo,
               let firstItem = userInfo.first,
               let value = firstItem.value as? String,
               let url = URL(string: value),
               let host = url.host
            {
                onButtonPress?(.link, .mention("@\(mention.replacingOccurrences(of: "@\(host)", with: ""))@\(host)"))
            } else {
                onButtonPress?(.link, .mention(mention))
            }
        case let .hashtag(_, hashtag, _):
            onButtonPress?(.link, .hashtag(hashtag))
        case let .email(text, _):
            onButtonPress?(.link, .email(text))
        default:
            break
        }
    }
}

// MARK: Appearance changes

extension ProfileField {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        onThemeChange()
    }
}

final class ProfileFieldSeperator: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.label.withAlphaComponent(0.1)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
