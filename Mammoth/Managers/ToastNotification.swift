//
//  ToastNotification.swift
//  Mammoth
//
//  Created by Riley Howard on 8/18/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

extension ToastNotificationManager {
    enum toast {
        static let imageSaved = NSNotification.Name(rawValue: "imageSaved")
        static let subscribed = NSNotification.Name(rawValue: "subscribed")
        static let unsubscribed = NSNotification.Name(rawValue: "unsubscribed")
        static let accountMuted = NSNotification.Name(rawValue: "accountMuted")
        static let accountBlocked = NSNotification.Name(rawValue: "accountBlocked")
    }
}

// In charge of listening for post-related activity, and showing the toaster-style
// notifications.
class ToastNotificationManager {
    enum NotificationType {
        case standard
        case destructive
    }

    static var shared: ToastNotificationManager?
    private var hostWindow: UIWindow
    private let blurEffectView: BlurredBackground = {
        let blurredEffectView = BlurredBackground(dimmed: false)
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurredEffectView.layer.cornerRadius = 12
        blurredEffectView.layer.cornerCurve = .continuous
        blurredEffectView.clipsToBounds = true
        blurredEffectView.backgroundColor = .clear
        return blurredEffectView
    }()

    private var toastButton: UIButton = {
        let newButton = UIButton()
        newButton.translatesAutoresizingMaskIntoConstraints = false
        newButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        newButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        newButton.backgroundColor = .clear
        newButton.isOpaque = false
        return newButton
    }()

    private var toastButtonVConstraint: NSLayoutConstraint?
    private let toastButtonVOffscreen = 80.0
    private let toastButtonVOnScreen = -58.0

    init(hostWindow: UIWindow) {
        self.hostWindow = hostWindow
        // Register for post notifications
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postPosted"), object: nil, queue: nil, using: postPosted)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postUpdated"), object: nil, queue: nil, using: postUpdated)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postScheduled"), object: nil, queue: nil, using: postScheduled)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postSentMessage"), object: nil, queue: nil, using: postSentMessage)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postLimitError"), object: nil, queue: nil, using: postLimitError)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postPostError"), object: nil, queue: nil, using: postPostError)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postMuted"), object: nil, queue: nil, using: postMuted)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postBlocked"), object: nil, queue: nil, using: postBlocked)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postUnmuted"), object: nil, queue: nil, using: postUnmuted)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postUnblocked"), object: nil, queue: nil, using: postUnblocked)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postDeleted"), object: nil, queue: nil, using: postDeleted)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postListUpdated"), object: nil, queue: nil, using: postListUpdated)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postListFollowed"), object: nil, queue: nil, using: postListFollowed)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postListUnfollowed"), object: nil, queue: nil, using: postListUnfollowed)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postListUserAdded"), object: nil, queue: nil, using: postListUserAdded)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postBookmarked"), object: nil, queue: nil, using: postBookmarked)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postUnbookmarked"), object: nil, queue: nil, using: postUnbookmarked)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postVIP"), object: nil, queue: nil, using: postVIP)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postUnVIP"), object: nil, queue: nil, using: postUnVIP)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "failedList"), object: nil, queue: nil, using: failedList)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "failedFollow"), object: nil, queue: nil, using: failedFollow)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postFollowed"), object: nil, queue: nil, using: postFollowed)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postPinned"), object: nil, queue: nil, using: postPinned)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postUnpinned"), object: nil, queue: nil, using: postUnpinned)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "userNotifsEnabled"), object: nil, queue: nil, using: userNotifsEnabled)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "userNotifsDisabled"), object: nil, queue: nil, using: userNotifsDisabled)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "userRepostsEnabled"), object: nil, queue: nil, using: userRepostsEnabled)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "userRepostsDisabled"), object: nil, queue: nil, using: userRepostsDisabled)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "userReported"), object: nil, queue: nil, using: userReported)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "postReported"), object: nil, queue: nil, using: postReported)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "actionFrom"), object: nil, queue: nil, using: actionFrom)
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "pollVoted"), object: nil, queue: nil, using: pollVoted)

        NotificationCenter.default.addObserver(forName: ToastNotificationManager.toast.imageSaved, object: nil, queue: nil, using: imageSaved)
        NotificationCenter.default.addObserver(forName: ToastNotificationManager.toast.subscribed, object: nil, queue: nil, using: subscribed)
        NotificationCenter.default.addObserver(forName: ToastNotificationManager.toast.unsubscribed, object: nil, queue: nil, using: unsubscribed)
        NotificationCenter.default.addObserver(forName: ToastNotificationManager.toast.accountMuted, object: nil, queue: nil, using: accountMuted)
        NotificationCenter.default.addObserver(forName: ToastNotificationManager.toast.accountBlocked, object: nil, queue: nil, using: accountBlocked)

        // Set up constraints
        hostWindow.addSubview(blurEffectView)
        blurEffectView.addSubview(toastButton)

        toastButtonVConstraint = blurEffectView.bottomAnchor.constraint(equalTo: hostWindow.safeAreaLayoutGuide.bottomAnchor, constant: toastButtonVOffscreen)
        NSLayoutConstraint.activate([
            toastButton.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor),
            toastButton.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor),
            toastButton.topAnchor.constraint(equalTo: blurEffectView.topAnchor),
            toastButton.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor),

            blurEffectView.centerXAnchor.constraint(equalTo: hostWindow.centerXAnchor),
            blurEffectView.widthAnchor.constraint(greaterThanOrEqualToConstant: 166),

            blurEffectView.heightAnchor.constraint(equalToConstant: 40),
            toastButtonVConstraint!,
        ])
    }

    private func postPosted(notification _: Notification) {
        if GlobalStruct.popupPostPosted {
            postNotification(title: NSLocalizedString("toast.publishedPost", comment: ""), sound: "soundPublished")
        }
    }

    private func postUpdated(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.editedPost", comment: ""), sound: "soundPublished2")
    }

    private func postScheduled(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.scheduledPost", comment: ""), sound: "soundPublished2")
    }

    private func postSentMessage(notification _: Notification) {
        if GlobalStruct.popupPostPosted {
            postNotification(title: NSLocalizedString("toast.sent", comment: ""), sound: "soundPublished")
        }
    }

    private func postLimitError(notification _: Notification) {
        if let x = UserDefaults.standard.value(forKey: "oauthToken") as? String, x != "oauthToken" {
            if GlobalStruct.popupRateLimits {
                postNotification(title: NSLocalizedString("toast.rateLimit", comment: ""), sound: "soundError", notificationType: .destructive)
            }
        }
    }

    private func postPostError(notification _: Notification) {
        toastButton.addTarget(self, action: #selector(postErrorTap), for: .touchUpInside)
        postNotification(title: NSLocalizedString("toast.errorPosting", comment: ""), sound: "soundError", notificationType: .destructive)
    }

    private func postMuted(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.muted", comment: ""), sound: "soundMallet", notificationType: .destructive)
    }

    private func postBlocked(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.blockedUser", comment: ""), sound: "soundMallet", notificationType: .destructive)
    }

    private func postUnmuted(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.unmuted", comment: ""), sound: "soundRemove")
    }

    private func postUnblocked(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.unblockedUser", comment: ""), sound: "soundRemove")
    }

    private func postDeleted(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.postDeleted", comment: ""), sound: "soundMallet", notificationType: .destructive)
    }

    private func postListUpdated(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.listUpdated", comment: ""), sound: "soundMallet")
    }

    private func postListFollowed(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.subscribedList", comment: ""), sound: "soundMallet")
    }

    private func postListUnfollowed(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.accountBlocked", comment: ""), sound: "soundRemove")
    }

    private func postListUserAdded(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.userAdded", comment: ""), sound: "soundMallet")
    }

    private func postBookmarked(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.bookmarked", comment: ""), sound: "soundMallet")
    }

    private func postUnbookmarked(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.removed", comment: ""), sound: "soundRemove")
    }

    private func postVIP(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.added", comment: ""), sound: "soundMallet")
    }

    private func postUnVIP(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.removed", comment: ""), sound: "soundRemove", notificationType: .destructive)
    }

    private func failedList(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.addFail", comment: ""), sound: "soundError", notificationType: .destructive)
    }

    private func failedFollow(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.followFail", comment: ""), sound: "soundError", notificationType: .destructive)
    }

    private func postFollowed(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.followed", comment: ""), sound: "soundMallet")
    }

    private func postPinned(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.pinned", comment: ""), sound: "soundMallet")
    }

    private func postUnpinned(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.unpinned", comment: ""), sound: "soundRemove", notificationType: .destructive)
    }

    private func userNotifsEnabled(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.enabled", comment: ""), sound: "soundMallet")
    }

    private func userNotifsDisabled(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.disabled", comment: ""), sound: "soundRemove", notificationType: .destructive)
    }

    private func userRepostsEnabled(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.enabled", comment: ""), sound: "soundMallet")
    }

    private func userRepostsDisabled(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.disabled", comment: ""), sound: "soundRemove", notificationType: .destructive)
    }

    private func userReported(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.userReported", comment: ""), sound: "soundMallet", notificationType: .destructive)
    }

    private func postReported(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.postReported", comment: ""), sound: "soundMallet", notificationType: .destructive)
    }

    private func actionFrom(notification _: Notification) {
        postNotification(title: "\(GlobalStruct.actionFromInstance)", sound: nil)
    }

    private func pollVoted(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.pollVoted", comment: ""), sound: "soundPublished2")
    }

    private func subscribed(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.subscribed", comment: ""), sound: "soundMallet")
    }

    private func unsubscribed(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.unsubscribed", comment: ""), sound: "soundMallet")
    }

    private func imageSaved(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.imageSaved", comment: ""), sound: "soundMallet")
    }

    private func accountMuted(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.accountMuted", comment: ""), sound: "soundMallet")
    }

    private func accountBlocked(notification _: Notification) {
        postNotification(title: NSLocalizedString("toast.accountBlocked", comment: ""), sound: "soundMallet", notificationType: .destructive)
    }

    // Bottleneck for all post notifications
    private func postNotification(title: String, sound: String?, notificationType: NotificationType = .standard) {
        if let sound {
            Sound().playSound(named: sound, withVolume: 1)
        }
        if GlobalStruct.popupPostPosted {
            triggerHaptic3Notification()

            toastButtonVConstraint?.constant = toastButtonVOffscreen
            let textColor = (notificationType == .destructive) ? UIColor.white : UIColor.custom.highContrast
            let attributedTitle = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold), NSAttributedString.Key.foregroundColor: textColor])
            toastButton.setAttributedTitle(attributedTitle, for: .normal)

            switch notificationType {
            case .standard:
                toastButton.backgroundColor = .custom.blurredOVRLYHigh
            case .destructive:
                toastButton.backgroundColor = .custom.destructive
            }

            hostWindow.addSubview(blurEffectView)
            hostWindow.bringSubviewToFront(blurEffectView)

            hostWindow.layoutIfNeeded()
            toastButtonVConstraint?.constant = toastButtonVOnScreen
            UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.16, options: [.curveEaseInOut]) {
                self.hostWindow.layoutIfNeeded()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                self.toastButtonVConstraint?.constant = self.toastButtonVOffscreen
                UIView.animate(withDuration: 1.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.16, options: [.curveEaseInOut]) {
                    self.hostWindow.layoutIfNeeded()
                } completion: { _ in
                    GlobalStruct.currentlyPosting = false
                }
            }
        }
    }

    @objc func postErrorTap() {
        let alert = UIAlertController(title: NSLocalizedString("toast.errorPosting.title", comment: ""), message: GlobalStruct.postPostError, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel, handler: { _ in
            self.toastButton.removeTarget(self, action: #selector(self.postErrorTap), for: .touchUpInside)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("toast.viewDrafts", comment: ""), style: .default, handler: { _ in
            let vc = ScheduledPostsViewController()
            vc.drafts = GlobalStruct.drafts
            vc.currentUser = AccountsManager.shared.currentUser()
            let nvc = UINavigationController(rootViewController: vc)
            if let presentingVC = getTopMostViewController() {
                presentingVC.present(nvc, animated: true, completion: nil)
            }
        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = hostWindow
            presenter.sourceRect = hostWindow.bounds
        }
        if let presentingVC = getTopMostViewController() {
            presentingVC.present(alert, animated: true, completion: nil)
        }
    }
}
