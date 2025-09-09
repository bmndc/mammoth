//
//  PostCardProfilePic.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage
import UIKit

final class PostCardProfilePic: UIButton {
    enum ProfilePicSize {
        case small, regular, big

        func width() -> CGFloat {
            switch self {
            case .small:
                return 24
            case .regular:
                return 44
            case .big:
                return 109
            }
        }

        func height() -> CGFloat {
            return width() // height == width
        }

        func cornerRadius(isCircle: Bool = GlobalStruct.circleProfiles) -> CGFloat {
            if isCircle {
                return width() / 2
            } else {
                switch self {
                case .small:
                    return 4
                case .regular:
                    return 8
                case .big:
                    return 23
                }
            }
        }
    }

    static var transformer: SDImagePipelineTransformer {
        let scale = UIScreen.main.scale
        let thumbnailSize = CGSize(width: PostCardProfilePic.ProfilePicSize.regular.width() * scale, height: PostCardProfilePic.ProfilePicSize.regular.width() * scale)
        let resizeTransformer = SDImageResizingTransformer(size: thumbnailSize, scaleMode: .aspectFit)
        let roundTransformer = SDImageRoundCornerTransformer(
            radius: GlobalStruct.circleProfiles ? .greatestFiniteMagnitude : PostCardProfilePic.ProfilePicSize.regular.cornerRadius(isCircle: false),
            corners: .allCorners,
            borderWidth: 0,
            borderColor: nil
        )
        return SDImagePipelineTransformer(transformers: [resizeTransformer, roundTransformer])
    }

    // MARK: - Properties

    private(set) var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage()
        imageView.isOpaque = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerCurve = .continuous
        imageView.layer.isOpaque = true
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var badge: BlurredBackground = {
        let view = BlurredBackground()
        view.layer.cornerRadius = 11
        view.clipsToBounds = true
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var badgeIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 11
        imageView.tintColor = .custom.linkText
        return imageView
    }()

    private var user: UserCardModel?
    private var isPrivateMention: Bool = false

    var size: ProfilePicSize = .regular {
        didSet {
            imageWidthConstraint?.constant = size.width()
            imageHeightConstraint?.constant = size.height()
            onThemeChange()
        }
    }

    var onPress: PostCardButtonCallback?
    var isContextMenuEnabled = true

    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageHeightConstraint: NSLayoutConstraint?

    init(withSize profilePicSize: ProfilePicSize) {
        super.init(frame: .zero)
        size = profilePicSize
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        user = nil
        onPress = nil
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.image = nil
    }
}

// MARK: - Setup UI

private extension PostCardProfilePic {
    func setupUI() {
        isOpaque = true
        addSubview(profileImageView)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(tapGesture)

        imageWidthConstraint = profileImageView.widthAnchor.constraint(equalToConstant: size.width())
        imageWidthConstraint?.priority = .required

        imageHeightConstraint = profileImageView.heightAnchor.constraint(equalToConstant: size.height())
        imageHeightConstraint?.priority = .required

        NSLayoutConstraint.activate([
            imageWidthConstraint!,
            imageHeightConstraint!,
            profileImageView.topAnchor.constraint(equalTo: topAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        let interaction = UIContextMenuInteraction(delegate: self)
        profileImageView.addInteraction(interaction)

        addSubview(badge)
        badge.addSubview(badgeIconView)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 22),
            badge.heightAnchor.constraint(equalToConstant: 22),
            badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -6),
            badge.topAnchor.constraint(equalTo: topAnchor, constant: -6),

            badgeIconView.widthAnchor.constraint(equalToConstant: 10),
            badgeIconView.heightAnchor.constraint(equalToConstant: 10),
            badgeIconView.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            badgeIconView.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
        ])
    }
}

// MARK: - Configuration

extension PostCardProfilePic {
    func configure(user: UserCardModel, badgeIcon: UIImage? = nil, isPrivateMention: Bool = false) {
        self.user = user
        self.isPrivateMention = isPrivateMention

        if profileImageView.sd_currentImageURL?.absoluteString != user.imageURL {
            profileImageView.sd_cancelCurrentImageLoad()
        }

        profileImageView.layer.cornerRadius = size.cornerRadius()

        if let badgeIcon {
            badgeIconView.image = badgeIcon
            badge.isHidden = false
        } else {
            badge.isHidden = true
        }

        updateColors()
    }

    func optimisticUpdate(image: UIImage) {
        profileImageView.image = image.roundedCornerImage(with: size.cornerRadius() * 2)
    }

    func onThemeChange() {
        if let profileStr = user?.imageURL, let profileURL = URL(string: profileStr) {
            // This is also called when the avatar changes from round/square
            profileImageView.layer.cornerRadius = size.cornerRadius()

            profileImageView.ma_setImage(with: profileURL,
                                         cachedImage: nil,
                                         imageTransformer: PostCardProfilePic.transformer)
            { _ in
            }

            updateColors()
        }
    }

    func updateColors() {
        let backgroundColor: UIColor = .custom.OVRLYSoftContrast
        profileImageView.backgroundColor = backgroundColor
        profileImageView.layer.backgroundColor = backgroundColor.cgColor
        badgeIconView.tintColor = .custom.linkText
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        onThemeChange()
    }

    @objc func profileTapped() {
        if let user = user {
            onPress?(.profile, true, .user(user))
        }
    }

    func willDisplay() {
        if profileImageView.sd_currentImageURL?.absoluteString != user?.imageURL {
            profileImageView.sd_cancelCurrentImageLoad()
        }

        if let profileStr = user?.imageURL, let profileURL = URL(string: profileStr) {
            let userForImage = user
            profileImageView.ma_setImage(with: profileURL,
                                         cachedImage: user?.decodedProfilePic,
                                         imageTransformer: PostCardProfilePic.transformer)
            { [weak self] image in
                guard let self else { return }
                if userForImage == self.user {
                    self.user?.decodedProfilePic = image
                }
            }
        }
    }
}

// MARK: - Context menu creators

extension PostCardProfilePic {
    override func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        guard isContextMenuEnabled else { return nil }

        if let account = user?.account {
            FollowManager.shared.followStatusForAccount(account, requestUpdate: .whenUncertain)
        }

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil,
            actionProvider: { _ in
                self.createContextMenu()
            }
        )
    }

    func createContextMenu() -> UIMenu {
        guard let account = user?.account else { return UIMenu() }
        let isFollowing = FollowManager.shared.followStatusForAccount(account) == .following || (user?.isFollowing ?? false)

        if let user = user {
            if user.isSelf {
                let options = [
                    createContextMenuAction(NSLocalizedString("profile.mention", comment: ""), .mention, isActive: true, data: nil),
                    createContextMenuAction(NSLocalizedString("user.shareLink", comment: ""), .share, isActive: true, data: nil),
                ]

                return UIMenu(title: "", options: [.displayInline], children: options)
            }

            let options = [
                createContextMenuAction(NSLocalizedString("profile.mention", comment: ""), .mention, isActive: true, data: nil),

                isFollowing
                    ? createContextMenuAction(NSLocalizedString("profile.unfollow", comment: ""), .follow, isActive: false, data: nil)
                    : createContextMenuAction(NSLocalizedString("profile.follow", comment: ""), .follow, isActive: true, data: nil),

                isFollowing
                    ? UIMenu(title: NSLocalizedString("list.manage", comment: ""), image: MAMenu.list.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                        UIMenu(title: MAMenu.addToList.title, image: MAMenu.addToList.image.withRenderingMode(.alwaysTemplate), options: [], children: ListManager.shared.allLists(includeTopFriends: false).map {
                            createContextMenuAction($0.title, .addToList, isActive: true, data: PostCardButtonCallbackData.list($0.id))
                        }),
                        UIMenu(title: MAMenu.removeFromList.title, image: MAMenu.removeFromList.image.withRenderingMode(.alwaysTemplate), options: [], children: ListManager.shared.allLists(includeTopFriends: false).map {
                            createContextMenuAction($0.title, .removeFromList, isActive: true, data: PostCardButtonCallbackData.list($0.id))
                        }),
                        createContextMenuAction(NSLocalizedString("list.create", comment: ""), .createNewList, isActive: true, data: nil),
                    ])
                    : nil,

                user.isMuted
                    ? createContextMenuAction(NSLocalizedString("user.unmute", comment: ""), .unmute, isActive: true, data: nil)
                    : UIMenu(title: String.localizedStringWithFormat(NSLocalizedString("user.muteUser", comment: ""), user.username), image: MAMenu.muteOneDay.image.withRenderingMode(.alwaysTemplate), options: [], children: [
                        createContextMenuAction(NSLocalizedString("user.muteDay", comment: ""), .muteOneDay, isActive: true, data: nil),
                        createContextMenuAction(NSLocalizedString("user.muteForever", comment: ""), .muteForever, isActive: true, data: nil),
                    ]),

                createContextMenuAction(String.localizedStringWithFormat(NSLocalizedString("user.report", comment: ""), user.username), .reportUser, isActive: true, data: nil, attributes: .destructive),

                user.isBlocked
                    ? createContextMenuAction(String.localizedStringWithFormat(NSLocalizedString("user.unblockUser", comment: ""), user.username), .unblock, isActive: true, data: nil)
                    : createContextMenuAction(String.localizedStringWithFormat(NSLocalizedString("user.blockUser", comment: ""), user.username), .block, isActive: true, data: nil, attributes: .destructive),

                createContextMenuAction(NSLocalizedString("user.shareLink", comment: ""), .share, isActive: true, data: nil),
            ].compactMap { $0 }

            return UIMenu(title: "", options: [.displayInline], children: options)
        }

        log.error("[PostCardProfilePic]: created an empty UIMenu")
        return UIMenu()
    }

    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, data: PostCardButtonCallbackData?, attributes: UIMenuElement.Attributes = []) -> UIAction {
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || traitCollection.userInterfaceStyle == .dark {
            color = .white
        }

        if attributes.contains(.destructive) {
            color = UIColor.systemRed
        }

        let action = UIAction(title: title,
                              image: buttonType.icon(symbolConfig: postCardSymbolConfig)?.withTintColor(color).withRenderingMode(.alwaysTemplate),
                              identifier: nil, attributes: attributes)
        { _ in
            self.onPress?(buttonType, isActive, data)
        }
        action.accessibilityLabel = title
        return action
    }
}
