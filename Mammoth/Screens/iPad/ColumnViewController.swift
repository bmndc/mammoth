//
//  ColumnViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable:next type_body_length
class ColumnViewController: UIViewController {
    static var shared = ColumnViewController()

    var doneOnceLayout: Bool = false
    var hasRotated: Bool = false

    let firstViewWidth = 87.0
    let auxColumnWidthRatio = (1.0 / 1.61803) // Use the golden ratio
    let verticalMargin = 25.0
    let horizontalGap = 20.0

    let newPostButton = NewPostButton()

    private var sidebarNavVC: UINavigationController?
    private var sidebarViewController = SidebarViewController.shared

    // The main (left) column
    var mainColumnNavVC: UINavigationController?
    private var mainColumnPlaceholderView = ExtendedTouchView()
    // The auxilary (right) column
    private var auxColumnNavVC: UINavigationController?
    private var auxColumnPlaceholderView = UIView()

    // Constraints to deal with rotation
    private var auxColumnWidthConstraintGolden: NSLayoutConstraint?
    private var auxColumnWidthConstraintZero: NSLayoutConstraint?
    private var auxGapWidthConstraint: NSLayoutConstraint?

    private var mainVCList: [UINavigationController] = []

    required init() {
        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(goToActivityTab), name: NSNotification.Name(rawValue: "goToActivityTab"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(goToMessagesTab), name: NSNotification.Name(rawValue: "goToMessagesTab"), object: nil)
    }

    private func setupUI() {
        // List of UINavigationController that can populate the main column
        mainVCList.append(UINavigationController(rootViewController: HomeViewController()))
        mainVCList.append(UINavigationController(rootViewController: SearchHostViewController()))
        mainVCList.append(UINavigationController(rootViewController: ActivityViewController()))
        mainVCList.append(UINavigationController(rootViewController: MentionsViewController()))
        mainVCList.append(UINavigationController(rootViewController: ProfileViewController(acctData: AccountsManager.shared.currentAccount)))

        // Lefthand view with buttons
        sidebarViewController.delegate = self
        sidebarNavVC = UINavigationController(rootViewController: sidebarViewController)
        sidebarNavVC!.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(sidebarNavVC!)
        view.addSubview(sidebarNavVC!.view)

        // Since sidebarViewController is a singleton, make sure
        // it has the correct icon selected.
        sidebarViewController.reset()

        // Main column view
        mainColumnPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainColumnPlaceholderView)

        // Side column view
        auxColumnPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(auxColumnPlaceholderView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func installInMainColumn(_ navController: UINavigationController) {
        if navController != mainColumnNavVC {
            let previousMainColumnVC = mainColumnNavVC
            mainColumnNavVC = navController

            navController.view.translatesAutoresizingMaskIntoConstraints = false
            navController.view.layer.cornerRadius = 10
            navController.view.layer.borderWidth = 0.6
            navController.view.layer.borderColor = UIColor.custom.outlines.cgColor
            addChild(navController)
            mainColumnPlaceholderView.addSubview(navController.view)
            mainColumnPlaceholderView.addConstraints([
                navController.view.leadingAnchor.constraint(equalTo: mainColumnPlaceholderView.leadingAnchor),
                navController.view.trailingAnchor.constraint(equalTo: mainColumnPlaceholderView.trailingAnchor),
                navController.view.topAnchor.constraint(equalTo: mainColumnPlaceholderView.topAnchor),
                navController.view.bottomAnchor.constraint(equalTo: mainColumnPlaceholderView.bottomAnchor),
            ])

            previousMainColumnVC?.willMove(toParent: nil)
            previousMainColumnVC?.view.removeFromSuperview()
            previousMainColumnVC?.removeFromParent()
        }
    }

    private func installInAuxColumn(_ navController: UINavigationController) {
        if navController != auxColumnNavVC {
            let previousAuxColumnVC = auxColumnNavVC
            auxColumnNavVC = navController

            navController.view.translatesAutoresizingMaskIntoConstraints = false
            navController.view.layer.cornerRadius = 10
            navController.view.layer.borderWidth = 0.6
            navController.view.layer.borderColor = UIColor.custom.outlines.cgColor
            addChild(navController)
            auxColumnPlaceholderView.addSubview(navController.view)
            auxColumnPlaceholderView.addConstraints([
                navController.view.leadingAnchor.constraint(equalTo: auxColumnPlaceholderView.leadingAnchor),
                navController.view.trailingAnchor.constraint(equalTo: auxColumnPlaceholderView.trailingAnchor),
                navController.view.topAnchor.constraint(equalTo: auxColumnPlaceholderView.topAnchor),
                navController.view.bottomAnchor.constraint(equalTo: auxColumnPlaceholderView.bottomAnchor),
            ])

            previousAuxColumnVC?.willMove(toParent: nil)
            previousAuxColumnVC?.view.removeFromSuperview()
            previousAuxColumnVC?.removeFromParent()
        }
    }

    @objc func goToActivityTab(notification: Notification) {
        sidebarViewController.barSingleTap(didSelect: 2)

        if let activityVC = mainColumnNavVC?.children.first as? ActivityViewController {
            activityVC.carouselItemPressed(withIndex: 0)
            activityVC.headerView.carousel.scrollTo(index: 0)

            // Delay required to finish the carousel animation smoothly first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                activityVC.jumpToNewest()
            }

            if let navController = mainColumnNavVC {
                navController.popToRootViewController(animated: true)
            }

            // Navigate to the target post if there's one included in the notification
            if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
                if !postCard.isDeleted, !postCard.isMuted, !postCard.isBlocked {
                    let vc = DetailViewController(post: postCard)
                    if vc.isBeingPresented {} else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.mainColumnNavVC?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }

    @objc func goToMessagesTab(notification: Notification) {
        sidebarViewController.barSingleTap(didSelect: 3)

        if let mentionsVC = mainColumnNavVC?.children.first as? MentionsViewController {
            mentionsVC.carouselItemPressed(withIndex: 0)
            mentionsVC.headerView.carousel.scrollTo(index: 0)
            // Delay required to finish the carousel animation smoothly first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                mentionsVC.jumpToNewest()
            }

            if let navController = mainColumnNavVC {
                navController.popToRootViewController(animated: true)
            }

            // Navigate to the target post if there's one included in the notification
            if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
                if !postCard.isDeleted, !postCard.isMuted, !postCard.isBlocked {
                    let vc = DetailViewController(post: postCard)
                    if vc.isBeingPresented {} else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.mainColumnNavVC?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }

    @objc func switchSidebar1() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoItem1"), object: self)
    }

    @objc func switchSidebar2() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoItem2"), object: self)
    }

    @objc func switchSidebar3() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoM"), object: self)
    }

    @objc func switchSidebar4() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoP"), object: self)
    }

    @objc func switchSidebar5() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1B"), object: self)
    }

    @objc func switchSidebar6() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1M"), object: self)
    }

    @objc func switchSidebar66() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1MS"), object: self)
    }

    @objc func switchSidebar7() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1E"), object: self)
    }

    @objc func switchSidebar8() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1U"), object: self)
    }

    @objc func switchSidebar9() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto1L"), object: self)
    }

    @objc func switchSidebar0() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "goto2M"), object: self)
    }

    @objc func switchSidebarSea() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "gotoFil"), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        newPostButton.delegate = self
        newPostButton.allowsExtremeLeft = true
        newPostButton.installInView(mainColumnPlaceholderView)
        newPostButton.addInteraction(UIPointerInteraction(delegate: nil))

        // Show sign in view if appropriate
        if AccountsManager.shared.allAccounts.isEmpty {
            NotificationCenter.default.post(name: shouldChangeRootViewController, object: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        if doneOnceLayout == false {
            doneOnceLayout = true

            view.addConstraints([
                sidebarNavVC!.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sidebarNavVC!.view.topAnchor.constraint(equalTo: view.topAnchor, constant: verticalMargin),
                sidebarNavVC!.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalMargin),
                sidebarNavVC!.view.widthAnchor.constraint(equalToConstant: firstViewWidth),
            ])
            // Main column view
            auxGapWidthConstraint = mainColumnPlaceholderView.trailingAnchor.constraint(equalTo: auxColumnPlaceholderView.leadingAnchor, constant: -horizontalGap)
            view.addConstraints([
                mainColumnPlaceholderView.leadingAnchor.constraint(equalTo: sidebarNavVC!.view.trailingAnchor),
                mainColumnPlaceholderView.topAnchor.constraint(equalTo: view.topAnchor, constant: verticalMargin),
                mainColumnPlaceholderView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalMargin),
                auxGapWidthConstraint!,
            ])
            // Side column view
            auxColumnWidthConstraintGolden = auxColumnPlaceholderView.widthAnchor.constraint(equalTo: mainColumnPlaceholderView.widthAnchor, multiplier: auxColumnWidthRatio)
            auxColumnWidthConstraintZero = auxColumnPlaceholderView.widthAnchor.constraint(equalToConstant: 0)

            view.addConstraints([
                auxColumnPlaceholderView.topAnchor.constraint(equalTo: view.topAnchor, constant: verticalMargin),
                auxColumnPlaceholderView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -verticalMargin),
                auxColumnPlaceholderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalGap),
            ])
        }

        // Adjust widths based on landscape/portrait
        let isPortrait = view.bounds.height > view.bounds.width
        // Use one of the aux column width constraints
        auxColumnWidthConstraintGolden?.isActive = !isPortrait
        auxColumnWidthConstraintZero?.isActive = isPortrait
        auxGapWidthConstraint?.constant = isPortrait ? 0.0 : -horizontalGap

        super.viewDidLayoutSubviews()

        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp
        navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        hasRotated = true
    }

    override var keyCommands: [UIKeyCommand]? {
        let newPost = UIKeyCommand(input: "n", modifierFlags: [.command], action: #selector(newPost))
        newPost.discoverabilityTitle = "New Post"
        if #available(iOS 15, *) {
            newPost.wantsPriorityOverSystemBehavior = true
        }
        let newMessage = UIKeyCommand(input: "n", modifierFlags: [.command, .shift], action: #selector(newMessage))
        newMessage.discoverabilityTitle = "New Message"
        if #available(iOS 15, *) {
            newMessage.wantsPriorityOverSystemBehavior = true
        }
        let goTo1 = UIKeyCommand(input: "1", modifierFlags: .command, action: #selector(scrollTo1))
        goTo1.discoverabilityTitle = "Feed"
        if #available(iOS 15, *) {
            goTo1.wantsPriorityOverSystemBehavior = true
        }
        let goTo2 = UIKeyCommand(input: "2", modifierFlags: .command, action: #selector(scrollTo2))
        goTo2.discoverabilityTitle = "Activity"
        if #available(iOS 15, *) {
            goTo2.wantsPriorityOverSystemBehavior = true
        }
        let goTo3 = UIKeyCommand(input: "3", modifierFlags: .command, action: #selector(scrollTo3))
        goTo3.discoverabilityTitle = "Messages"
        if #available(iOS 15, *) {
            goTo3.wantsPriorityOverSystemBehavior = true
        }
        let goTo4 = UIKeyCommand(input: "4", modifierFlags: .command, action: #selector(scrollTo4))
        goTo4.discoverabilityTitle = "Explore"
        if #available(iOS 15, *) {
            goTo4.wantsPriorityOverSystemBehavior = true
        }
        let goTo5 = UIKeyCommand(input: "5", modifierFlags: .command, action: #selector(scrollTo5))
        goTo5.discoverabilityTitle = NSLocalizedString("navigator.profile", comment: "")
        if #available(iOS 15, *) {
            goTo5.wantsPriorityOverSystemBehavior = true
        }
        let goTo6 = UIKeyCommand(input: "6", modifierFlags: .command, action: #selector(scrollTo6))
        goTo6.discoverabilityTitle = NSLocalizedString("title.likes", comment: "")
        if #available(iOS 15, *) {
            goTo6.wantsPriorityOverSystemBehavior = true
        }
        let goTo7 = UIKeyCommand(input: "7", modifierFlags: .command, action: #selector(scrollTo7))
        goTo7.discoverabilityTitle = "Bookmarks"
        if #available(iOS 15, *) {
            goTo7.wantsPriorityOverSystemBehavior = true
        }
        let goTo8 = UIKeyCommand(input: "8", modifierFlags: .command, action: #selector(scrollTo8))
        goTo8.discoverabilityTitle = NSLocalizedString("profile.filters", comment: "")
        if #available(iOS 15, *) {
            goTo8.wantsPriorityOverSystemBehavior = true
        }
        let search = UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(scrollTo9))
        search.discoverabilityTitle = "Search"
        if #available(iOS 15, *) {
            search.wantsPriorityOverSystemBehavior = true
        }
        let settings = UIKeyCommand(input: ",", modifierFlags: .command, action: #selector(settingsTap))
        settings.discoverabilityTitle = "Settings"
        if #available(iOS 15, *) {
            settings.wantsPriorityOverSystemBehavior = true
        }
        return [newPost, newMessage, goTo1, goTo2, goTo3, goTo4, goTo5, goTo6, goTo7, search, settings]
    }

    @objc func newPost() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "newPost"), object: nil)
    }

    @objc func newMessage() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "newMessage"), object: nil)
    }

    @objc func scrollTo1() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 0
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func scrollTo2() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 1
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func scrollTo3() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 2
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func scrollTo4() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 3
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func scrollTo5() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 4
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func scrollTo6() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 5
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func scrollTo7() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 6
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func scrollTo8() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 7
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func scrollTo9() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "scrollTo"), object: nil)
        GlobalStruct.sidebarItem = 8
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func searchTap() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "searchTap"), object: nil)
        GlobalStruct.sidebarItem = 9
        NotificationCenter.default.post(name: Notification.Name(rawValue: "selectItem"), object: nil)
    }

    @objc func settingsTap() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "settingsTap"), object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        installInMainColumn(mainVCList[0])
        installInAuxColumn(UINavigationController(rootViewController: AuxColumnViewController()))

        view.backgroundColor = .custom.backgroundTint
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
    }

    @objc func reloadAll() {
        DispatchQueue.main.async {
            self.view.backgroundColor = .custom.backgroundTint
            let navApp = UINavigationBarAppearance()
            navApp.configureWithOpaqueBackground()
            navApp.backgroundColor = .custom.backgroundTint
            navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]

            self.mainColumnNavVC?.navigationBar.standardAppearance = navApp
            self.mainColumnNavVC?.navigationBar.scrollEdgeAppearance = navApp
            self.mainColumnNavVC?.navigationBar.compactAppearance = navApp

            self.auxColumnNavVC?.navigationBar.standardAppearance = navApp
            self.auxColumnNavVC?.navigationBar.scrollEdgeAppearance = navApp
            self.auxColumnNavVC?.navigationBar.compactAppearance = navApp

            self.mainColumnNavVC?.view.layer.borderColor = UIColor.custom.outlines.cgColor
            self.mainColumnNavVC?.navigationBar.backgroundColor = .custom.backgroundTint
            self.mainColumnNavVC?.view.layer.borderColor = UIColor.custom.outlines.cgColor
            self.auxColumnNavVC?.view.layer.borderColor = UIColor.custom.outlines.cgColor
            self.auxColumnNavVC?.navigationBar.backgroundColor = .custom.backgroundTint
            self.auxColumnNavVC?.view.layer.borderColor = UIColor.custom.outlines.cgColor
        }
    }
}

// MARK: Appearance changes

extension ColumnViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.reloadAll()
            }
        }
    }
}

extension ColumnViewController: SidebarViewControllerDelegate {
    func didSelect(_ index: Int) {
        installInMainColumn(mainVCList[index])
        newPostButton.updateNewPostButtonImage()
        newPostButton.superview?.bringSubviewToFront(newPostButton)
    }

    func viewControllerAtIndex(_ index: Int) -> UIViewController? {
        guard index < mainVCList.count else {
            log.error("unexpected double-tap index")
            return nil
        }
        return mainVCList[index].viewControllers.first
    }
}

extension ColumnViewController: AppStateRestoration {
    func storeUserActivity(in activity: NSUserActivity) {
        log.debug("ColumnViewController:" + #function)
        // Allow subviews to store their data, if any
        sidebarViewController.storeUserActivity(in: activity)

        if let mainColumnVC = mainColumnNavVC?.topViewController as? AppStateRestoration {
            mainColumnVC.storeUserActivity(in: activity)
        }
        if let auxColumnVC = auxColumnNavVC?.topViewController as? AppStateRestoration {
            auxColumnVC.storeUserActivity(in: activity)
        }
    }

    func restoreUserActivity(from activity: NSUserActivity) {
        log.debug("ColumnViewController:" + #function)
        // Allow subviews to restore their data, if any
        sidebarViewController.restoreUserActivity(from: activity)
        if let mainColumnVC = mainColumnNavVC?.topViewController as? AppStateRestoration {
            mainColumnVC.restoreUserActivity(from: activity)
        }
        if let auxColumnVC = auxColumnNavVC?.topViewController as? AppStateRestoration {
            auxColumnVC.restoreUserActivity(from: activity)
        }
    }
}

extension ColumnViewController: NewPostButtonDelegate {
    private func isOnTab(vcType: AnyClass) -> Bool {
        var containsSpecificView = false
        if let vcStack = mainColumnNavVC?.viewControllers {
            containsSpecificView = vcStack.contains(where: { vc in
                type(of: vc) == vcType
            })
        }
        return containsSpecificView
    }

    private func isOnDiscoverTab() -> Bool {
        return isOnTab(vcType: SearchHostViewController.self)
    }

    private func isOnMessagesTab() -> Bool {
        return isOnTab(vcType: MentionsViewController.self)
    }

    func newPostTypeForCurrentViewController() -> NewPostType {
        if isOnMessagesTab() {
            return .newMessage
        } else {
            return .newPost
        }
    }

    func shouldShowNewPostButton() -> Bool {
        return !isOnDiscoverTab()
    }
}
