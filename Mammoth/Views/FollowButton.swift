//
//  FollowButton.swift
//  Mammoth
//
//  Created by Benoit Nolens on 22/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

private extension FollowManager.FollowStatus {
    var title: String {
        switch self {
        case .notFollowing, .unknown, .unfollowRequested:
            return NSLocalizedString("profile.follow", comment: "")
        case .following, .followRequested:
            return NSLocalizedString("profile.unfollow", comment: "")
        case .followAwaitingApproval:
            return NSLocalizedString("profile.awaitingApproval", comment: "")
        case .inProgress:
            return NSLocalizedString("profile.follow", comment: "")
        }
    }
}

final class FollowButton: UIButton {
    enum ButtonType {
        case small
        case big

        var fontSize: CGFloat {
            switch self {
            case .small:
                return 13
            case .big:
                return 16
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

    var user: UserCardModel? {
        didSet {
            if let user {
                updateButton(user: user)
            }
        }
    }

    init(user: UserCardModel, type: ButtonType = .small) {
        self.user = user
        super.init(frame: .zero)
        setupUI(type: type)
    }

    init() {
        user = nil
        super.init(frame: .zero)
        setupUI(type: .small)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI(type: ButtonType) {
        layer.cornerRadius = type.cornerRadius
        layer.cornerCurve = .continuous
        layer.isOpaque = true
        isOpaque = true
        contentEdgeInsets = UIEdgeInsets(top: 4.5, left: 11, bottom: 3.5, right: 11)
        titleLabel?.font = UIFont.systemFont(ofSize: type.fontSize, weight: .semibold)
        setTitle(user?.followStatus?.title, for: .normal)
        titleLabel?.isOpaque = true

        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)

        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.defaultHigh, for: .vertical)

        addTarget(self, action: #selector(onTapped), for: .touchUpInside)
        onThemeChange()
    }

    func onThemeChange() {
        layer.backgroundColor = UIColor.custom.followButtonBG.cgColor
        backgroundColor = .custom.followButtonBG
        setTitleColor(.custom.active, for: .normal)
        titleLabel?.backgroundColor = .custom.followButtonBG
        if #available(iOS 15.0, *) {
            self.tintColor = .custom.baseTint
        }
    }

    func updateButton(user: UserCardModel) {
        setTitle(user.followStatus?.title, for: .normal)
    }
}

// MARK: Actions

extension FollowButton {
    @objc func onTapped() {
        switch user?.followStatus {
        case .notFollowing, .unknown, .unfollowRequested, .inProgress:
            user?.forceFollowButtonDisplay = true
            followTapped()
        case .following, .followRequested, .followAwaitingApproval:
            unfollowTapped()
        default:
            log.error("unexpected case")
        }
    }

    private func followTapped() {
        triggerHapticImpact(style: .light)

        if let user = user, let account = self.user?.account {
            setTitle(FollowManager.FollowStatus.followRequested.title, for: .normal)
            Task {
                do {
                    let _ = try await FollowManager.shared.followAccountAsync(account)

                    await MainActor.run {
                        user.syncFollowStatus()
                        self.updateButton(user: user)
                    }

                    AnalyticsManager.track(event: .follow)

                    if user.followStatus != .followRequested {
                        await MainActor.run {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableSuggestions"), object: nil)
                        }
                    }
                } catch {
                    log.error("Follow error: \(error)")
                    self.setTitle(FollowManager.FollowStatus.notFollowing.title, for: .normal)
                }
            }
        }
    }

    private func unfollowTapped() {
        if let user = user, let account = self.user?.account {
            setTitle(FollowManager.FollowStatus.unfollowRequested.title, for: .normal)
            Task {
                do {
                    let _ = try await FollowManager.shared.unfollowAccountAsync(account)

                    await MainActor.run {
                        user.syncFollowStatus()
                        self.updateButton(user: user)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableSuggestions"), object: nil)
                    }

                    AnalyticsManager.track(event: .unfollow)

                } catch {
                    log.error("Unfollow error: \(error)")
                    self.setTitle(FollowManager.FollowStatus.following.title, for: .normal)
                }
            }
        }
    }
}

// MARK: Appearance changes

extension FollowButton {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.onThemeChange()
            }
        }
    }
}
