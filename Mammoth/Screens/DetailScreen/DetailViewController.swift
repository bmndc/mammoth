//
//  DetailViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 05/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import StoreKit
import UIKit

class DetailViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        PostCardCell.registerForReuseIdentifierVariants(on: tableView)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorStyle = .none
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.tableHeaderView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delaysContentTouches = false
        return tableView
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.onDragToRefresh(_:)), for: .valueChanged)
        return refresh
    }()

    private let scrollUpIndicator = ScrollUpIndicator()
    private var viewModel: DetailViewModel
    private var initialized = false
    private var shouldScrollToReplies: Bool

    required init(viewModel: DetailViewModel, scrollToReplies: Bool = false) {
        self.viewModel = viewModel
        shouldScrollToReplies = scrollToReplies
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        navigationItem.backButtonTitle = nil

        setupUI()
    }

    convenience init(post: PostCardModel, showStatusSource: Bool = false, scrollToReplies: Bool = false) {
        let viewModel = DetailViewModel(post: post, showStatusSource: showStatusSource)
        self.init(viewModel: viewModel, scrollToReplies: scrollToReplies)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButtonItems(createNavBarButtons(), animated: false)

        let gestureScrollUp = UITapGestureRecognizer(target: self, action: #selector(onScrollUpTapped))
        scrollUpIndicator.addGestureRecognizer(gestureScrollUp)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: navigationController, userInterfaceStyle: traitCollection.userInterfaceStyle)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Only pause on tab change
        if !animated {
            viewModel.post.videoPlayer?.pause()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // review prompt
        if GlobalStruct.reviewPrompt {
            GlobalStruct.reviewCount += 1
            if GlobalStruct.reviewCount % 14 == 0 {
                let infoDictionaryKey = kCFBundleVersionKey as String
                if let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String {
                    let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: "lastVersionPromptedForReviewKey")
                    if currentVersion != lastVersionPromptedForReview {
                        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            DispatchQueue.main.async {
                                SKStoreReviewController.requestReview(in: scene)
                            }
                        }
                        UserDefaults.standard.set(currentVersion, forKey: "lastVersionPromptedForReviewKey")
                    }
                }
            }
        }
    }

    func setupUI() {
        view.addSubview(tableView)
        view.addSubview(scrollUpIndicator)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollUpIndicator.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -13),
            scrollUpIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 13),
        ])
    }

    private func createNavBarButtons() -> [UIBarButtonItem] {
        // Create nav button
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let btn = UIButton(type: .custom)
        btn.setImage(FontAwesome.image(fromChar: "\u{e10a}").withConfiguration(symbolConfig).withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.accessibilityLabel = NSLocalizedString("generic.more", comment: "")
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)

        // Create context menu
        let view_in_browser = NSLocalizedString("post.viewInBrowser", comment: "")
        var contextMenuOptions: [UIAction] = []
        let option0 = UIAction(title: view_in_browser, image: PostCardButtonType.viewInBrowser.icon(symbolConfig: postCardSymbolConfig), identifier: nil) { [weak self] _ in
            guard let self else { return }
            PostActions.onViewInBrowser(postCard: self.viewModel.post)
        }
        option0.accessibilityLabel = view_in_browser
        contextMenuOptions.append(option0)

        let translate_post = NSLocalizedString("post.translatePost", comment: "")
        let option1 = UIAction(title: translate_post, image: PostCardButtonType.translate.icon(symbolConfig: postCardSymbolConfig), identifier: nil) { [weak self] _ in
            guard let self else { return }
            PostActions.onTranslate(target: self, postCard: self.viewModel.post)
        }
        option1.accessibilityLabel = translate_post
        contextMenuOptions.append(option1)

        let share_post = NSLocalizedString("post.sharePost", comment: "")
        let option2 = UIAction(title: share_post, image: PostCardButtonType.share.icon(symbolConfig: postCardSymbolConfig), identifier: nil) { [weak self] _ in
            guard let self else { return }
            PostActions.onShare(target: self, postCard: self.viewModel.post)
        }
        option2.accessibilityLabel = share_post
        contextMenuOptions.append(option2)

        let itemMenu = UIMenu(title: "", options: [], children: contextMenuOptions)
        btn.menu = itemMenu
        btn.showsMenuAsPrimaryAction = true
        let moreButton = UIBarButtonItem(customView: btn)

        return [moreButton]
    }

    @objc private func onDragToRefresh(_: Any) {
        Sound().playSound(named: "soundSuction", withVolume: 0.6)
        Task { [weak self] in
            guard let self else { return }
            try await self.viewModel.refreshData()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.refreshControl.endRefreshing()
            }
        }
    }

    @objc private func onScrollUpTapped() {
        tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt _: IndexPath) {
        if let cell = cell as? PostCardCell {
            cell.willDisplay()
        }
    }

    func tableView(_: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt _: IndexPath) {
        if let cell = cell as? PostCardCell {
            cell.didEndDisplay()
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(forSection: section)
    }

    func numberOfSections(in _: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = DetailViewModel.Section(rawValue: indexPath.section)
        let model = viewModel.getInfo(forIndexPath: indexPath)
        let hasParent = viewModel.hasParent(indexPath: indexPath)
        let hasChild = viewModel.hasChild(indexPath: indexPath)

        switch section {
        case .parents:
            if let postCard = model {
                let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard, cellType: .parent), for: indexPath) as! PostCardCell
                cell.configure(postCard: postCard, type: .parent, hasParent: hasParent, hasChild: hasChild) { [weak self] type, isActive, data in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                }
                return cell
            }

        case .post:
            if let postCard = model {
                let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard, cellType: .detail), for: indexPath) as! PostCardCell
                cell.configure(postCard: postCard, type: .detail, hasParent: hasParent || postCard.isAReply, hasChild: hasChild || postCard.hasReplies) { [weak self] type, isActive, data in
                    guard let self else { return }

                    if type == .replies && postCard.hasReplies {
                        let repliesHeight = self.tableView.rect(forSection: DetailViewModel.Section.replies.rawValue).size.height
                        let boundsHeight = self.tableView.bounds.size.height
                        let safeAreaInsets = self.view.safeAreaInsets
                        let spacerHeight = max(0, boundsHeight - repliesHeight - safeAreaInsets.top - safeAreaInsets.bottom)
                        self.tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: self.tableView.bounds.size.width, height: spacerHeight))
                        if self.tableView.numberOfRows(inSection: DetailViewModel.Section.replies.rawValue) > 0 {
                            self.tableView.scrollToRow(at: IndexPath(row: 0, section: DetailViewModel.Section.replies.rawValue), at: .top, animated: true)
                        }
                    } else {
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)

                        if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                            self.viewModel.post.videoPlayer?.pause()
                        }
                    }
                }

                return cell
            }

        case .replies:
            // Display loader cell in last row if needed
            if viewModel.shouldDisplayLoader() && indexPath.row == viewModel.numberOfItems(forSection: indexPath.section) - 1 {
                if let cell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as? LoadingCell {
                    cell.startAnimation()
                    return cell
                }
            }

            // Display error cell in last row if needed
            if viewModel.shouldDisplayError() && indexPath.row == viewModel.numberOfItems(forSection: indexPath.section) - 1 {
                if let cell = tableView.dequeueReusableCell(withIdentifier: ErrorCell.reuseIdentifier, for: indexPath) as? ErrorCell {
                    return cell
                }
            }

            if let postCard = model {
                let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard, cellType: .reply), for: indexPath) as! PostCardCell
                cell.configure(postCard: postCard, type: .reply, hasParent: hasParent, hasChild: hasChild) { [weak self] type, isActive, data in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)

                    if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                        self.viewModel.post.videoPlayer?.pause()
                    }
                }

                return cell
            }

        default:
            break
        }

        return UITableViewCell()
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = DetailViewModel.Section(rawValue: indexPath.section), section != .post else {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            return
        }

        if let model = viewModel.getInfo(forIndexPath: indexPath) {
            viewModel.post.videoPlayer?.pause()

            let vc = DetailViewController(post: model)
            if vc.isBeingPresented {} else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func scrollViewDidScrollToTop(_: UIScrollView) {
        viewModel.dismissScrollUpIndicator()
        scrollUpIndicator.isEnabled = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollUpIndicator.isEnabled {
            let postRect = tableView.rect(forSection: DetailViewModel.Section.post.rawValue)
            let safeAreaInset = view.safeAreaInsets.top
            let threshold = 50.0
            if (scrollView.contentOffset.y + safeAreaInset) < (postRect.origin.y - threshold) {
                viewModel.dismissScrollUpIndicator()
                scrollUpIndicator.isEnabled = false
            }
        }
    }
}

extension DetailViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            tableView.reloadData()
        case .success:
            UIView.setAnimationsEnabled(false)
            tableView.reloadData()

            // keep position of main post when context is loaded (only the first time)
            if !initialized {
                initialized = true

                let postHeight = tableView.rect(forSection: DetailViewModel.Section.post.rawValue).size.height
                let repliesHeight = tableView.rect(forSection: DetailViewModel.Section.replies.rawValue).size.height
                let boundsHeight = tableView.bounds.size.height
                let safeAreaInsets = view.safeAreaInsets
                let spacerHeight = max(0, boundsHeight - postHeight - repliesHeight - safeAreaInsets.top - safeAreaInsets.bottom)
                tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: tableView.bounds.size.width, height: spacerHeight))

                // only keep scroll position if user didn't already scroll
                if tableView.contentOffset.y == 0 - view.safeAreaInsets.top {
                    if tableView.numberOfRows(inSection: DetailViewModel.Section.post.rawValue) > 0 {
                        tableView.scrollToRow(at: IndexPath(row: 0, section: DetailViewModel.Section.post.rawValue), at: .top, animated: false)
                    }
                }
            }

            UIView.setAnimationsEnabled(true)
            tableView.flashScrollIndicators()

            scrollUpIndicator.isEnabled = viewModel.shouldShowScrollUpIndicator()

            if shouldScrollToReplies {
                shouldScrollToReplies = false
                if tableView.contentOffset.y == 0 - view.safeAreaInsets.top {
                    if tableView.numberOfRows(inSection: DetailViewModel.Section.post.rawValue) > 0 {
                        tableView.scrollToRow(at: IndexPath(row: 0, section: DetailViewModel.Section.replies.rawValue), at: .top, animated: true)
                    }
                }
            }
        case let .error(error):
            log.error("Error on DetailViewController didUpdate: \(state) - \(error)")
            tableView.reloadData()
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
        }
    }

    func didUpdateCard(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func didDeleteCard(at indexPath: IndexPath) {
        let section = DetailViewModel.Section(rawValue: indexPath.section)
        if section != .post {
            tableView.deleteRows(at: [indexPath], with: .bottom)
        }
    }
}

// MARK: UIContextMenuInteractionDelegate

extension DetailViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        if let section = DetailViewModel.Section(rawValue: indexPath.section), section == .post { return nil }

        if let postCard = viewModel.getInfo(forIndexPath: indexPath) {
            if let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard), for: indexPath) as? PostCardCell {
                return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { _ in
                    cell.createContextMenu(postCard: postCard) { [weak self] type, isActive, data in
                        guard let self else { return }
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                    }
                })
            }
        }

        return nil
    }
}

// MARK: Appearance changes

extension DetailViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
            }
        }
    }
}

extension DetailViewController: JumpToNewest {
    @objc func jumpToNewest() {
        tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
