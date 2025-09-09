//
//  AuxColumnViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 5/22/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

protocol AuxFeedViewControllerDelegate: AnyObject {
    func didChangeFeedController(_ viewController: UIViewController?)
    func didChangeFeedMenu(_ viewController: UIViewController?)
    func userActivityStorageIdentifier() -> String
}

class AuxColumnViewController: UIViewController {
    private let navbarTitleButton: UIButton
    private let auxFeedViewController: AuxFeedViewController

    let newPostButton = NewPostButton()

    required init() {
        navbarTitleButton = UIButton()
        auxFeedViewController = AuxFeedViewController()

        super.init(nibName: nil, bundle: nil)
        auxFeedViewController.delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        navigationItem.titleView = navbarTitleButton
        navbarTitleButton.showsMenuAsPrimaryAction = true
        navbarTitleButton.titleEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: -2, right: 0)
        addChild(auxFeedViewController)
        view.addSubview(auxFeedViewController.view)
        auxFeedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            auxFeedViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            auxFeedViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            auxFeedViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            auxFeedViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        updateFeedMenu()
        showSelectedFeed()
        updateNavBarButtons()

        newPostButton.delegate = self
        newPostButton.installInView(view)
        newPostButton.addInteraction(UIPointerInteraction(delegate: nil))
    }

    private func showSelectedFeed() {
        //
        // Pick a default...
        updateNavBarButtons()
        navbarTitleButton.sizeToFit()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        // Update the appearance of the navbar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp
    }
}

// MARK: AuxViewControllerDelegate

extension AuxColumnViewController: AuxFeedViewControllerDelegate {
    func userActivityStorageIdentifier() -> String {
        return "AuxColumnViewController.currentMenuItemIdentifier"
    }

    func didChangeFeedController(_: UIViewController?) {
        // Set the Feeds -> selected feed name
        updateNavBarButtons()

        newPostButton.updateNewPostButtonImage()
        newPostButton.superview?.bringSubviewToFront(newPostButton)
    }

    func didChangeFeedMenu(_: UIViewController?) {
        updateFeedMenu()

        // If views are added/removed from the feed, the related navbar items may be outdated
        updateNavBarButtons()
    }
}

// Feed Menu
extension AuxColumnViewController {
    private func updateFeedMenu() {
        let feedMenu = auxFeedViewController.feedMenu()
        navbarTitleButton.menu = UIMenu(title: "", options: [], children: feedMenu)
    }

    private func updateNavBarButtons() {
        // Update the main title
        let title = auxFeedViewController.title ?? ""
        // Adjust the caret symbol a bit...
        let downCaret = FontAwesome.image(fromChar: "\u{f0d7}", size: 12, weight: .bold)
        // ...move it down
        let offsetDownCaret = downCaret.imageWithOffset(CGPointMake(0, 3))
        // ...give it a left margin
        let insetDownCaret = offsetDownCaret!.imageWithInsets(UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0))
        // Convert the caret from image to string
        let caretAttachment = NSTextAttachment()
        caretAttachment.image = insetDownCaret!.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
        let titleString = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.label])
        let caretAsString = NSAttributedString(attachment: caretAttachment)
        let titleStringAndCaret = NSMutableAttributedString()
        titleStringAndCaret.append(titleString)
        titleStringAndCaret.append(caretAsString)
        navbarTitleButton.setAttributedTitle(titleStringAndCaret, for: .normal)
        navbarTitleButton.sizeToFit()

        // Some feeds will have additional navigation bar items
        navigationItem.setRightBarButtonItems(auxFeedViewController.navBarItems(), animated: true)
    }
}

extension AuxColumnViewController: AppStateRestoration {
    func storeUserActivity(in activity: NSUserActivity) {
        log.debug("AuxColumnViewController:" + #function)
        auxFeedViewController.storeUserActivity(in: activity)
    }

    func restoreUserActivity(from activity: NSUserActivity) {
        log.debug("AuxColumnViewController:" + #function)
        auxFeedViewController.restoreUserActivity(from: activity)
    }
}

extension AuxColumnViewController: NewPostButtonDelegate {
    private func isOnTab(vcType: AnyClass) -> Bool {
        if auxFeedViewController.currentFeedController != nil {
            return type(of: auxFeedViewController.currentFeedController!) == vcType
        } else {
            return false
        }
    }

    private func isOnMessagesTab() -> Bool {
        return isOnTab(vcType: MentionsViewController.self)
    }

    func newPostTypeForCurrentViewController() -> NewPostType {
        return .newMessage
    }

    func shouldShowNewPostButton() -> Bool {
        return isOnMessagesTab()
    }

    func userDefaultKey() -> String {
        "auxPostButtonLocation"
    }
}
