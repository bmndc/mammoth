//
//  NewsFeedViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 26/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

protocol NewsFeedViewControllerDelegate: AnyObject {
    func willChangeFeed(_ type: NewsFeedTypes)
    func didChangeFeed(_ type: NewsFeedTypes)
    func didScrollToTop()
    func userActivityStorageIdentifier() -> String
    func isActiveFeed(_ type: NewsFeedTypes) -> Bool
}

// swiftlint:disable:next type_body_length
class NewsFeedViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSourcePrefetching {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        PostCardCell.registerForReuseIdentifierVariants(on: tableView)
        tableView.register(ActivityCardCell.self, forCellReuseIdentifier: ActivityCardCell.reuseIdentifier)
        tableView.register(LoadMoreCell.self, forCellReuseIdentifier: LoadMoreCell.reuseIdentifier)
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        tableView.register(EmptyFeedCell.self, forCellReuseIdentifier: EmptyFeedCell.reuseIdentifier)
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.delaysContentTouches = false

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }

        // Hides the last separator
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        return tableView
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.onDragToRefresh(_:)), for: .valueChanged)
        return refresh
    }()

    private var displayingIndexPath: IndexPath?

    private let latestPill = LatestPill()
    private let unreadIndicator = UnreadIndicator()
    private let jumpToNow = JumpToLatest()
    private var feedMenuItems: [UIMenu] = []
    private var viewModel: NewsFeedViewModel
    private var didInitializeOnce = false
    private var isInsertingContent: Bool = false
    private var isScrollingProgrammatically: Bool = false
    private var disableFeedUpdates: Bool = false

    // switchingAccounts is set to true in the period between
    // willSwitchAccount and didSwitchAccount, when currentAccount
    // should not be accessed.
    private var switchingAccounts = false

    weak var delegate: NewsFeedViewControllerDelegate?
    private var deferredSnapshotUpdatesCallbacks: [() -> Void] = []

    var type: NewsFeedTypes {
        return viewModel.type
    }

    var isActiveFeed: Bool {
        if let isActive = delegate?.isActiveFeed(type) {
            return isActive
        }
        return true
    }

    convenience init(type: NewsFeedTypes) {
        let viewModel = NewsFeedViewModel(type)
        self.init(viewModel: viewModel)
    }

    required init(viewModel: NewsFeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        title = self.viewModel.type.title()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(feedMenuItemsChanged),
                                               name: NSNotification.Name(rawValue: "updateClient"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onThemeChange),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(feedMenuItemsChanged),
                                               name: didChangePinnedInstancesNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(feedMenuItemsChanged),
                                               name: didChangeHashtagsNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(feedMenuItemsChanged),
                                               name: didChangeListsNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: appDidBecomeActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willSwitchAccount),
                                               name: willSwitchCurrentAccountNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.viewModel.stopPollingListData()
        if self.viewModel.type.shouldSyncItems {
            self.viewModel.cancelAllItemSyncs()
        }
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()

        let gesturePill = UITapGestureRecognizer(target: self, action: #selector(onUnreadTapped))
        latestPill.addGestureRecognizer(gesturePill)

        let gestureUnread = UITapGestureRecognizer(target: self, action: #selector(onUnreadTapped))
        unreadIndicator.addGestureRecognizer(gestureUnread)

        let gestureToNow = UITapGestureRecognizer(target: self, action: #selector(onJumpToNow))
        jumpToNow.addGestureRecognizer(gestureToNow)

        if (NewsFeedTypes.allActivityTypes + [.mentionsIn, .mentionsOut]).contains(viewModel.type) {
            if !didInitializeOnce {
                didInitializeOnce = true
                log.debug("[NewsFeedViewController] Sync data source from `viewDidLoad` - \(viewModel.type)")
                viewModel.syncDataSource(type: viewModel.type) { [weak self] in
                    guard let self else { return }
                    guard self.viewModel.snapshot.sectionIdentifiers.contains(.main) else { return }
                    if self.viewModel.snapshot.itemIdentifiers(inSection: .main).isEmpty {
                        let type = self.viewModel.type
                        self.viewModel.displayLoader(forType: type)
                    } else {
                        for visibleCell in self.tableView.visibleCells {
                            if let cell = visibleCell as? PostCardCell {
                                cell.willDisplay()
                            } else if let cell = visibleCell as? ActivityCardCell {
                                cell.willDisplay()
                            }
                        }
                    }

                    Task { [weak self] in
                        guard let self else { return }
                        if [.mentionsIn].contains(type) || NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) {
                            try await self.viewModel.loadListData(type: type, fetchType: .refresh)
                        } else {
                            if GlobalStruct.feedReadDirection == .bottomUp {
                                try await self.viewModel.loadListData(type: self.viewModel.type, fetchType: .previousPage)
                            } else {
                                try await self.viewModel.loadLatest(feedType: type, threshold: 1)
                            }
                        }
                    }
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didInitializeOnce {
            didInitializeOnce = true
            log.debug("[NewsFeedViewController] Sync data source from `viewDidAppear` - \(viewModel.type)")

            // This `DispatchQueue.main.async` allows the runloop to complete once before hydration.
            // If removed the tableview is not correctly initialized and will not be restored correctly.
            DispatchQueue.main.async {
                self.viewModel.syncDataSource(type: self.viewModel.type) { [weak self] in
                    guard let self else { return }
                    Task {
                        self.viewModel.snapshot = self.viewModel.appendMainSectionToSnapshot(snapshot: self.viewModel.snapshot)
                        self.viewModel.dataSource?.apply(self.viewModel.snapshot, animatingDifferences: false)

                        if self.viewModel.snapshot.itemIdentifiers(inSection: .main).isEmpty {
                            let type = self.viewModel.type
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.viewModel.displayLoader(forType: type)
                            }

                            Task { [weak self] in
                                guard let self else { return }
                                if [.mentionsIn].contains(type) || NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) {
                                    try await self.viewModel.loadListData(type: type, fetchType: .refresh)
                                } else {
                                    if GlobalStruct.feedReadDirection == .bottomUp {
                                        try await self.viewModel.loadListData(type: type, fetchType: .previousPage)
                                    } else {
                                        try await self.viewModel.loadLatest(feedType: type, threshold: 1)
                                    }
                                }
                            }
                        } else {
                            self.showLoader(enabled: false)

                            for visibleCell in self.tableView.visibleCells {
                                if let cell = visibleCell as? PostCardCell {
                                    cell.willDisplay()
                                } else if let cell = visibleCell as? ActivityCardCell {
                                    cell.willDisplay()
                                }
                            }
                        }
                    }
                }
            }
        }

        if viewModel.type.shouldPollForListData {
            viewModel.startPollingListData(forFeed: viewModel.type, delay: 1)
        }

        // If the user disabled the JumpToNow button (pressed the close button)
        // re-enable it now
        viewModel.isJumpToNowButtonDisabled = false

        // reset polling status when switching feed if they've left for > 10 seconds.
        if !viewModel.didViewRecently {
            viewModel.pollingReachedTop = false
        }

        didUpdateSnapshot(viewModel.snapshot, feedType: viewModel.type, updateType: .insert, scrollPosition: nil, onCompleted: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setRightBarButtonItems(navBarItems(), animated: false)

        if !didInitializeOnce {
            let type = viewModel.type
            viewModel.displayLoader(forType: type)
        }

        viewModel.clearErrorState(type: viewModel.type)

        configureNavigationBarLayout(navigationController: navigationController, userInterfaceStyle: traitCollection.userInterfaceStyle)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.viewedDate = NSDate.now
        if !switchingAccounts {
            if !NewsFeedTypes.allActivityTypes.contains(viewModel.type), viewModel.type != .mentionsIn {
                viewModel.stopPollingListData()
            }
            if viewModel.type.shouldSyncItems {
                viewModel.cancelAllItemSyncs()
            }
            cacheScrollPosition(tableView: tableView, forFeed: viewModel.type)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Only clean up feed on tab change
        if !animated {
            viewModel.cleanUpMemoryOfCurrentFeed()
            AVManager.shared.currentPlayer?.pause()
        }
    }

    func pauseAllVideos() {
        viewModel.cleanUpMemoryOfCurrentFeed()
        AVManager.shared.currentPlayer?.pause()
    }

    func changeFeed(type: NewsFeedTypes) {
        title = type.title()
        viewModel.changeFeed(type: type)
    }

    func reloadData() {
        viewModel.clearErrorState(type: viewModel.type)
        Task { [weak self] in
            guard let self else { return }
            try await self.viewModel.loadListData()
        }
    }

    @objc private func willSwitchAccount() {
        deferredSnapshotUpdatesCallbacks = []
        cacheScrollPosition(tableView: tableView, forFeed: viewModel.type)
        viewModel.removeAll(type: viewModel.type, clearScrollPosition: false)

        if isInWindowHierarchy() {
            viewModel.stopPollingListData()
            if viewModel.type.shouldSyncItems {
                viewModel.cancelAllItemSyncs()
            }
        }
        switchingAccounts = true
    }

    @objc private func didSwitchAccount() {
        switchingAccounts = false
    }

    @objc private func onDragToRefresh(_: Any) {
        Sound().playSound(named: "soundSuction", withVolume: 0.6)
        viewModel.clearErrorState(type: viewModel.type)
        viewModel.stopPollingListData()

        Task { [weak self] in
            guard let self else { return }

            do {
                if [.mentionsIn].contains(type) || NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) {
                    try await self.viewModel.loadListData(type: self.viewModel.type, fetchType: .refresh)
                } else {
                    if GlobalStruct.feedReadDirection == .bottomUp {
                        try await self.viewModel.loadListData(type: type, fetchType: .previousPage)
                    } else {
                        try await self.viewModel.loadLatest(feedType: type, threshold: 1)
                    }
                }

                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
            }
        }

        // If the user disabled the JumpToNow button (pressed the close button)
        // re-enable it now
        viewModel.isJumpToNowButtonDisabled = false
    }

    @objc private func onThemeChange() {
        tableView.backgroundColor = .custom.background
        tableView.reloadData()
    }

    @objc func onJumpToNow() {
        viewModel.stopPollingListData()
        viewModel.cancelAllItemSyncs()
        deferredSnapshotUpdatesCallbacks = []

        isScrollingProgrammatically = true

        viewModel.clearSnapshot()
        disableFeedUpdates = true
        showLoader(enabled: true)

        viewModel.setShowJumpToNow(enabled: false, forFeed: viewModel.type)
        viewModel.clearAllUnreadIds(forFeed: viewModel.type)
        didUpdateUnreadState(type: viewModel.type)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }

            Task { [weak self] in
                guard let self else { return }
                try await self.viewModel.loadListData(type: self.viewModel.type, fetchType: .refresh)
            }

            self.disableFeedUpdates = false
        }
    }

    @objc func onUnreadTapped() {
        viewModel.setUnreadEnabled(enabled: false, forFeed: viewModel.type)
        latestPill.isEnabled = false
        unreadIndicator.isEnabled = false
        // Clear LatestPill state after scroll animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.latestPill.configure(unreadCount: 0, picUrls: [])
            self.unreadIndicator.configure(unreadCount: 0)

            if [.mentionsIn].contains(self.type) {
                // // Hide the tab bar mentions indicator (dot)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "hideIndActivity2"), object: nil)
            }

            if NewsFeedTypes.allActivityTypes.contains(self.viewModel.type) {
                // // Hide the tab bar activity indicator (dot)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "hideIndActivity"), object: nil)
            }
        }
    }

    @objc func appWillResignActive() {
        // store when the app was closed.
        viewModel.viewedDate = NSDate.now
        viewModel.stopPollingListData()
        if viewModel.type.shouldSyncItems {
            viewModel.cancelAllItemSyncs()
        }
        cacheScrollPosition(tableView: tableView, forFeed: viewModel.type)
    }

    @objc func appDidBecomeActive() {
        viewModel.clearErrorState(type: viewModel.type)
        if isActiveFeed, viewModel.type.shouldPollForListData {
            viewModel.startPollingListData(forFeed: type, delay: 2)
        }

        for visibleCell in tableView.visibleCells {
            if let cell = visibleCell as? PostCardCell {
                cell.willDisplay()
            } else if let cell = visibleCell as? ActivityCardCell {
                cell.willDisplay()
            }
        }

        // user just opened the app, assume an outdated feed if they've been out for > 10 seconds.
        if !viewModel.didViewRecently {
            viewModel.pollingReachedTop = false
        }
    }

    override func didReceiveMemoryWarning() {
        cacheScrollPosition(tableView: tableView, forFeed: viewModel.type)
        viewModel.cleanUpMemoryOfCurrentFeed()
    }
}

// MARK: UI Setup

private extension NewsFeedViewController {
    func setupUI() {
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        view.addSubview(latestPill)
        view.addSubview(unreadIndicator)
//        view.addSubview(jumpToNow)

//        jumpToNow.delegate = self

        if ![.mentionsIn, .mentionsOut].contains(viewModel.type), !NewsFeedTypes.allActivityTypes.contains(viewModel.type) {
            tableView.tableHeaderView = UIView()
        } else {
            let px = 1 / UIScreen.main.scale
            let line = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.size.width, height: px))
            tableView.tableHeaderView = line
            line.backgroundColor = tableView.separatorColor
        }

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            latestPill.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            latestPill.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 9),

//            self.jumpToNow.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
//            self.jumpToNow.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 9),

            unreadIndicator.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
            unreadIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 9),
        ])
    }
}

// MARK: - Observers

extension NewsFeedViewController {
    func setupObservers() {
        viewModel.dataSource = NewsFeedViewModel.NewsFeedDiffableDataSource(tableView: tableView) { [weak self] _, indexPath, listItemType -> UITableViewCell? in
            guard let self else { return UITableViewCell() }

            switch listItemType {
            case let .postCard(model):
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: model, cellType: viewModel.type.postCardCellType()), for: indexPath) as? PostCardCell {
                    cell.configure(postCard: model, type: viewModel.type.postCardCellType()) { [weak self] type, isActive, data in
                        guard let self else { return }
                        guard !model.isDeleted, !model.isMuted, !model.isBlocked else { return }
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: model, data: data)

                        // Show the Upgrade alert if needed (only on home feeds)
                        if !(NewsFeedTypes.allActivityTypes + [.mentionsIn, .mentionsOut, .likes, .bookmarks]).contains(self.viewModel.type),
                           [.like, .reply, .repost, .quote, .bookmark].contains(type)
                        {
                            IAPManager.shared.showUpgradeAlertIfNeeded()
                        }

                        if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                            self.viewModel.pauseAllVideos()
                        }
                    }

                    self.tableView.separatorStyle = .singleLine
                    return cell
                }
            case let .activity(model):
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: ActivityCardCell.reuseIdentifier, for: indexPath) as? ActivityCardCell {
                    cell.configure(activity: model) { [weak self] type, isActive, data in
                        guard let self else { return }
                        let account = model.notification.account
                        let userCard = UserCardModel(account: account)
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: userCard, data: data)

                        if [.profile, .deletePost, .link, .mention, .message, .muteForever, .muteOneDay, .postDetails, .quote, .viewInBrowser, .reply].contains(type) {
                            self.viewModel.pauseAllVideos()
                        }
                    }

                    self.tableView.separatorStyle = .singleLine
                    return cell
                }
            case .empty:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: EmptyFeedCell.reuseIdentifier, for: indexPath) as? EmptyFeedCell {
                    if case .list = self.viewModel.type {
                        cell.configure(label: NSLocalizedString("list.hint", comment: ""))
                    } else {
                        cell.configure()
                    }

                    self.tableView.separatorStyle = .none
                    return cell
                }
            case .loadMore:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: LoadMoreCell.reuseIdentifier, for: indexPath) as? LoadMoreCell {
                    if case .mentionsIn = self.viewModel.type {
                        cell.configure(label: "Load older mentions")
                    } else if case .mentionsOut = self.viewModel.type {
                        cell.configure(label: "Load older mentions")
                    } else if case .activity = self.viewModel.type {
                        cell.configure(label: "Load older activity")
                    }
                    return cell
                }
            case .error:
                if let cell = self.tableView.dequeueReusableCell(withIdentifier: ErrorCell.reuseIdentifier, for: indexPath) as? ErrorCell {
                    return cell
                }
            }

            log.error("#NewsFeedViewController - could not dequeue correct cell")
            return UITableViewCell()
        }
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate & UITableViewDataSourcePrefetching

extension NewsFeedViewController {
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let item = viewModel.getItemForIndexPath(indexPath) {
            if case let .postCard(postCardModel) = item {
                postCardModel.cellHeight = cell.frame.size.height
            } else if case let .activity(activityModel) = item {
                activityModel.cellHeight = cell.frame.size.height
            }

            if viewModel.getUnreadEnabled(forFeed: viewModel.type), !isInsertingContent {
                viewModel.removeUnreadId(id: item.uniqueId(), forFeed: viewModel.type)
                let count = viewModel.getUnreadCount(forFeed: viewModel.type)

                if GlobalStruct.feedReadDirection == .topDown {
                    switch viewModel.type {
                    case .mentionsIn, .mentionsOut, .activity:
                        unreadIndicator.isEnabled = true
                        unreadIndicator.configure(unreadCount: count)
                    default:
                        latestPill.isEnabled = true
                        let pics = viewModel.getUnreadPics(forFeed: viewModel.type)
                        latestPill.configure(unreadCount: count, picUrls: pics)
                    }
                } else {
                    unreadIndicator.isEnabled = true
                    unreadIndicator.configure(unreadCount: count)
                }
            }
        }

        displayingIndexPath = indexPath

        if isActiveFeed, viewModel.type.shouldSyncItems {
            if viewModel.postSyncingTasks.count > 15 {
                viewModel.cancelAllItemSyncs()
            }

            viewModel.requestItemSync(forIndexPath: indexPath, afterSeconds: 3.4)
        }

        if let cell = cell as? PostCardCell {
            cell.willDisplay()
        } else if let cell = cell as? ActivityCardCell {
            cell.willDisplay()
        }
    }

    func tableView(_: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.cancelItemSync(forIndexPath: indexPath)

        if let cell = cell as? PostCardCell {
            cell.didEndDisplay()
        } else if let cell = cell as? ActivityCardCell {
            cell.didEndDisplay()
        }
    }

    func tableView(_: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let item = viewModel.getItemForIndexPath(indexPath) {
            if case let .postCard(postCardModel) = item {
                return postCardModel.cellHeight ?? UITableView.automaticDimension
            }
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.getItemForIndexPath(indexPath) {
        case let .postCard(postCard):
            if !postCard.isDeleted, !postCard.isMuted, !postCard.isBlocked {
                // If it's from ForYou, indicate that the statusSource
                let showStatusSource = (type == .forYou)

                // we don't load the mention from its original server
                if [.mentionsIn, .mentionsOut].contains(viewModel.type) {
                    postCard.instanceName = AccountsManager.shared.currentAccountClient.baseHost
                    postCard.user?.instanceName = AccountsManager.shared.currentAccountClient.baseHost
                    postCard.isSyncedWithOriginal = true
                }

                let vc = DetailViewController(post: postCard, showStatusSource: showStatusSource)
                if vc.isBeingPresented {} else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        case let .activity(activity):
            switch activity.type {
            case .follow, .follow_request:
                if let account = activity.user.account {
                    PostActions.onProfilePress(target: self, account: account)
                }
            default:
                if let postCard = activity.postCard {
                    if !postCard.isDeleted, !postCard.isMuted, !postCard.isBlocked {
                        let vc = DetailViewController(post: postCard)
                        if vc.isBeingPresented {} else {
                            navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        case .loadMore:
            if let _ = self.tableView.dequeueReusableCell(withIdentifier: LoadMoreCell.reuseIdentifier, for: indexPath) as? LoadMoreCell {
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        try await self.viewModel.loadOlderPosts(feedType: self.viewModel.type)
                        await MainActor.run {
                            if let loadMoreIndexPath = self.viewModel.getIndexPathForItem(item: .loadMore) {
                                tableView.deselectRow(at: loadMoreIndexPath, animated: true)
                            }
                        }
                    } catch {}
                }
            }
        default:
            break
        }
    }

    func tableView(_: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if viewModel.shouldFetchNext(prefetchRowsAt: indexPaths) {
            Task { [weak self] in
                guard let self else { return }
                try await self.viewModel.loadListData(type: nil, fetchType: .nextPage)
            }
        }

        viewModel.preloadCards(atIndexPaths: indexPaths)
    }

    func tableView(_: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        viewModel.cancelPreloadCards(atIndexPaths: indexPaths)
    }

    func scrollViewWillBeginDragging(_: UIScrollView) {
        log.debug("Manual: scrollViewWillBeginDragging setting userHasScrolledManually to true for feed \(type)")
        viewModel.userHasScrolledManually = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        isScrollingProgrammatically = !tableView.isDecelerating && !tableView.isTracking && !(tableView.indexPathsForVisibleRows ?? []).isEmpty

        // scroll past the last item in feed (pull up)
        if (scrollView.contentOffset.y + view.safeAreaInsets.top) > max(scrollView.contentSize.height - (scrollView.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom), 0) + 130 {
            viewModel.clearErrorState(type: viewModel.type)
        }

        // Fetch next again if scrolling past the last elements
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.viewModel.snapshot.numberOfItems > 0, scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height - 600,
               viewModel.shouldFetchNext(prefetchRowsAt: [IndexPath(row: viewModel.numberOfItems(forSection: .main), section: 0)])
            {
                Task { [weak self] in
                    guard let self else { return }
                    try await viewModel.loadListData(type: nil, fetchType: .nextPage)
                }
            }
        }

        // When scrollview reachs the top
        // We need to include an inset when the background is translucent
        if scrollView.contentOffset.y == 0 - view.safeAreaInsets.top {
            if !isInsertingContent {
                cacheScrollPosition(tableView: tableView, forFeed: viewModel.type)
            }
            viewModel.removeOldItems(forType: viewModel.type)
            delegate?.didScrollToTop()
        }

        if scrollView.contentOffset.y < 0 - view.safeAreaInsets.top + 60 {
            // Clean unread indicator when close to top
            if viewModel.getUnreadCount(forFeed: viewModel.type) > 0 {
                if let firstIndexPath = tableView.indexPathsForVisibleRows?.first,
                   let model = viewModel.getItemForIndexPath(firstIndexPath)
                {
                    viewModel.removeUnreadId(id: model.uniqueId(), forFeed: viewModel.type)
                    didUpdateUnreadState(type: viewModel.type)
                }
            }

            delegate?.didScrollToTop()
        }

        // When scrollview reaches the top
        // We need to include an inset when the background is translucent
        if scrollView.contentOffset.y <= 0 - view.safeAreaInsets.top + 3000 {
            // For feeds with many new posts a second we don't want to
            // nag the user with the unread pill right after they reached the top.
            if viewModel.type.shouldPollForListData, viewModel.snapshot.numberOfItems > 0 {
                if !viewModel.isPollingEnabled, !isScrollingProgrammatically {
                    viewModel.startPollingListData(forFeed: viewModel.type, delay: 2.5)
                }
            }
        }
    }

    func scrollViewDidScrollToTop(_: UIScrollView) {
        isScrollingProgrammatically = false
        viewModel.userHasScrolledManually = true

        viewModel.cancelAllItemSyncs()

        if GlobalStruct.feedReadDirection == .topDown {
            switch viewModel.type {
            case .mentionsIn, .mentionsOut, .activity:
                unreadIndicator.configure(unreadCount: 0)
                unreadIndicator.isEnabled = true
            default:
                latestPill.configure(unreadCount: 0, picUrls: viewModel.getUnreadPics(forFeed: viewModel.type))
                latestPill.isEnabled = true
            }
        } else {
            unreadIndicator.configure(unreadCount: 0)
            unreadIndicator.isEnabled = true
        }

        if viewModel.type.shouldPollForListData, viewModel.snapshot.numberOfItems > 0 {
            if !viewModel.isPollingEnabled, !isScrollingProgrammatically {
                viewModel.startPollingListData(forFeed: viewModel.type, delay: 2.5)
            }
        }

        // save cloud scroll position
        let scrollPosition = cacheScrollPosition(tableView: tableView, forFeed: viewModel.type)
        CloudSyncManager.sharedManager.saveSyncStatus(for: type, scrollPosition: scrollPosition!)

        delegate?.didScrollToTop()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate _: Bool) {
        cacheScrollPosition(tableView: tableView, forFeed: viewModel.type)

        if !(scrollView.isDragging || scrollView.isDecelerating) {
            // save cloud scroll position
            let scrollPosition = cacheScrollPosition(tableView: tableView, forFeed: viewModel.type)
            CloudSyncManager.sharedManager.saveSyncStatus(for: type, scrollPosition: scrollPosition!)
        }
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        isScrollingProgrammatically = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { [weak self] in
            guard let self else { return }

            guard !self.tableView.isTracking, !self.tableView.isDecelerating else { return }
            let callbacks = self.deferredSnapshotUpdatesCallbacks
            self.deferredSnapshotUpdatesCallbacks = []
            callbacks.forEach { $0() }

            self.didUpdateSnapshot(self.viewModel.snapshot, feedType: self.viewModel.type, updateType: .insert, scrollPosition: nil, onCompleted: nil)

            // save cloud scroll position
            if let scrollPosition = self.cacheScrollPosition(tableView: self.tableView, forFeed: self.viewModel.type) {
                CloudSyncManager.sharedManager.saveSyncStatus(for: type, scrollPosition: scrollPosition)
            } else {
                log.error("scrollPosition unexpectedly nil")
            }
        }
    }
}

// MARK: NewsFeedViewModelDelegate

extension NewsFeedViewController: NewsFeedViewModelDelegate {
    func didUpdateSnapshot(_ snapshot: NewsFeedSnapshot, feedType: NewsFeedTypes, updateType: NewsFeedSnapshotUpdateType, scrollPosition: NewsFeedScrollPosition?, onCompleted: (() -> Void)?) {
        guard !switchingAccounts && !disableFeedUpdates else { return }

        let shouldFreezeAnimations = (isInWindowHierarchy() || updateType == .hydrate)
        let updateDisplay = (NewsFeedTypes.allActivityTypes + [.mentionsIn, .mentionsOut]).contains(feedType) || (isInWindowHierarchy() || updateType == .hydrate)

        guard (!tableView.isTracking && !tableView.isDecelerating) || updateType == .removeAll,
              updateDisplay,
              !(updateType == .update && isScrollingProgrammatically)
        else {
            if let callback = onCompleted {
                deferredSnapshotUpdatesCallbacks.append(callback)
            }
            return
        }

        let callbacks = deferredSnapshotUpdatesCallbacks
        deferredSnapshotUpdatesCallbacks = []
        callbacks.forEach { $0() }

        switch updateType {
        case .insert, .update, .remove, .replaceAll:
            log.debug("tableview change: \(updateType) for \(feedType); scrollPosition: \(scrollPosition)")

            isInsertingContent = true

            // Cache scroll position pre-update
            let preUpdateScrollPosition = cacheScrollPosition(tableView: tableView, forFeed: feedType, scrollReference: .top)

            if shouldFreezeAnimations, viewModel.dataSource != nil {
                CATransaction.begin()
                CATransaction.disableActions()
            }

            viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else {
                    if shouldFreezeAnimations {
                        CATransaction.commit()
                    }
                    return
                }

                if let preUpdateScrollPosition {
                    // Forcing a second scrollToPosition call on completion
                    // makes sure the scroll action happens correcty.
                    // Keep both of them to make the feed less jumpy on feed updates.
                    self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: preUpdateScrollPosition)
                }

                onCompleted?()

                DispatchQueue.main.async {
                    if let scrollPosition {
                        self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
                    }

                    if shouldFreezeAnimations {
                        CATransaction.commit()
                    }

                    self.isInsertingContent = false
                }

                // This extra commit is needed when updating with .replaceAll (triggered by refresh snapshot)
                // Without it the UI feezes.
                if updateType == .replaceAll, shouldFreezeAnimations {
                    CATransaction.commit()
                }
            }

            // Revert to pre-update scroll position
            if let preUpdateScrollPosition {
                scrollToPosition(tableView: tableView, snapshot: snapshot, position: preUpdateScrollPosition)
            }

        case .inject:
            guard isInWindowHierarchy() else { return }

            log.debug("tableview change: \(updateType) for \(feedType)")

            // Cache scroll position pre-update
            let preUpdateScrollPosition = cacheScrollPosition(tableView: tableView, forFeed: feedType, scrollReference: .top)

            if shouldFreezeAnimations {
                CATransaction.begin()
                CATransaction.disableActions()
            }

            viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else {
                    if updateDisplay {
                        CATransaction.commit()
                    }
                    return
                }

                if let preUpdateScrollPosition {
                    // Forcing a second scrollToPosition call on completion
                    // makes sure the scroll action happens correcty.
                    // Keep both of them to make the feed less jumpy on feed updates.
                    self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: preUpdateScrollPosition)
                }

                if shouldFreezeAnimations {
                    CATransaction.commit()
                    UIView.setAnimationsEnabled(false)
                }
                onCompleted?()

                DispatchQueue.main.async {
                    if let scrollPosition {
                        self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
                    }

                    if shouldFreezeAnimations {
                        UIView.setAnimationsEnabled(true)
                    }
                }
            }

            // Revert to pre-update scroll position
            if let preUpdateScrollPosition {
                scrollToPosition(tableView: tableView, snapshot: snapshot, position: preUpdateScrollPosition)
            }

        case .removeAll:
            log.debug("tableview change: \(updateType) for \(feedType)")
            viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else { return }
                if GlobalStruct.feedReadDirection == .topDown {
                    switch self.viewModel.type {
                    case .mentionsIn, .mentionsOut, .activity:
                        self.unreadIndicator.configure(unreadCount: 0)
                        self.unreadIndicator.isEnabled = true
                    default:
                        self.latestPill.configure(unreadCount: 0, picUrls: [])
                        self.latestPill.isEnabled = true
                    }
                } else {
                    self.unreadIndicator.configure(unreadCount: 0)
                    self.unreadIndicator.isEnabled = true
                    self.jumpToNow.isEnabled = false
                }

                self.cacheScrollPosition(tableView: self.tableView, forFeed: feedType)
                onCompleted?()
            }

        case .hydrate:
            log.debug("tableview change: \(updateType) for \(feedType)")
            let scrollPosition = scrollPosition ?? viewModel.getScrollPosition(forFeed: feedType)

            viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else { return }
                self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: scrollPosition)
                onCompleted?()
            }

            scrollToPosition(tableView: tableView, snapshot: snapshot, position: scrollPosition)

        case .append:
            // Cache scroll position pre-update
            let preUpdateScrollPosition = cacheScrollPosition(tableView: tableView, forFeed: feedType, scrollReference: .top)

            if shouldFreezeAnimations {
                CATransaction.begin()
                CATransaction.disableActions()
            }

            viewModel.dataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self else {
                    if shouldFreezeAnimations {
                        CATransaction.commit()
                    }
                    return
                }
                // Forcing a second scrollToPosition call on completion
                // makes sure the scroll action happens correcty.
                // Keep both of them to make the feed less jumpy on feed updates.
                if let preUpdateScrollPosition {
                    self.scrollToPosition(tableView: self.tableView, snapshot: snapshot, position: preUpdateScrollPosition)
                }

                if shouldFreezeAnimations {
                    CATransaction.commit()
                }
                onCompleted?()
            }

            if let preUpdateScrollPosition {
                scrollToPosition(tableView: tableView, snapshot: snapshot, position: preUpdateScrollPosition)
            }
        }
    }

    func didUpdateUnreadState(type: NewsFeedTypes) {
        let unreadState = viewModel.getUnreadState(forFeed: type)
        if unreadState.enabled {
            switch viewModel.type {
            case .mentionsIn, .mentionsOut, .activity:
                unreadIndicator.configure(unreadCount: unreadState.unreadIDs.count)
                unreadIndicator.isEnabled = unreadState.enabled
            default:
                if GlobalStruct.feedReadDirection == .topDown {
                    if unreadState.unreadPics.count < 4 {
                        latestPill.configure(unreadCount: 0, picUrls: [])
                        latestPill.isEnabled = unreadState.enabled
                    } else {
                        latestPill.configure(unreadCount: unreadState.unreadIDs.count, picUrls: unreadState.unreadPics)
                        latestPill.isEnabled = unreadState.enabled
                    }
                } else {
                    unreadIndicator.configure(unreadCount: unreadState.unreadIDs.count)
                    unreadIndicator.isEnabled = unreadState.enabled
                }
            }

        } else {
            switch viewModel.type {
            case .mentionsIn, .mentionsOut, .activity:
                unreadIndicator.isEnabled = false
            default:
                if GlobalStruct.feedReadDirection == .topDown {
                    latestPill.isEnabled = false
                } else {
                    unreadIndicator.isEnabled = false
                }
            }
        }

        jumpToNow.isEnabled = unreadState.showJumpToNow
    }

    func willChangeFeed(fromType: NewsFeedTypes, toType _: NewsFeedTypes) {
        // Cache scroll position of previous feed
        cacheScrollPosition(tableView: tableView, forFeed: fromType)
        latestPill.isEnabled = false
        unreadIndicator.isEnabled = false
        jumpToNow.isEnabled = false
    }

    func didChangeFeed(type: NewsFeedTypes) {
        title = type.title()
        delegate?.didChangeFeed(type)

        let unreadState = viewModel.getUnreadState(forFeed: type)

        switch viewModel.type {
        case .mentionsIn, .mentionsOut, .activity:
            unreadIndicator.isEnabled = unreadState.enabled
            unreadIndicator.configure(unreadCount: unreadState.unreadIDs.count)
        default:
            if GlobalStruct.feedReadDirection == .topDown {
                latestPill.isEnabled = unreadState.enabled
                latestPill.configure(unreadCount: unreadState.unreadIDs.count, picUrls: unreadState.unreadPics)
            } else {
                unreadIndicator.isEnabled = unreadState.enabled
                unreadIndicator.configure(unreadCount: unreadState.unreadIDs.count)
            }
        }

        if viewModel.type.shouldSyncItems {
            viewModel.cancelAllItemSyncs()
        }

        if viewModel.type.shouldPollForListData {
            viewModel.stopPollingListData()
            viewModel.startPollingListData(forFeed: viewModel.type, delay: 1)
        }
    }

    func didUpdateScrollPosition(scrollPosition: NewsFeedScrollPosition) {
        scrollToPosition(tableView: tableView, position: scrollPosition)
    }

    func operatingTableView() -> UIScrollView {
        return tableView
    }

    static let LoaderTag = 11

    func showLoader(enabled: Bool) {
        DispatchQueue.main.async {
            if enabled {
                if !self.isLoaderVisible() {
                    let loaderView = UIStackView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 40))
                    loaderView.alignment = .center
                    loaderView.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
                    let loader = UIActivityIndicatorView()
                    loader.startAnimating()
                    loaderView.addArrangedSubview(loader)
                    loaderView.tag = Self.LoaderTag
                    self.tableView.tableFooterView = loaderView
                }
            } else {
                // Hack to hide last seperator
                self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
            }
        }
    }

    func isLoaderVisible() -> Bool {
        return tableView.tableFooterView?.tag == Self.LoaderTag
    }

    func getVisibleIndexPaths() async -> [IndexPath]? {
        return await MainActor.run {
            self.tableView.indexPathsForVisibleRows
        }
    }
}

// MARK: Appearance changes

extension NewsFeedViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
                onThemeChange()
            }
        }
    }
}

// MARK: - Scroll helpers

private extension NewsFeedViewController {
    func scrollToPosition(tableView: UITableView, position: NewsFeedScrollPosition) {
        if tableView.frame.width > 0 {
            log.debug("iCloud Sync: scrollToPosition for \(type)")
            if case .postCard = position.model {
                if let indexPath = viewModel.getIndexPathForItem(item: position.model!) {
                    let yOffset = tableView.rectForRow(at: indexPath).origin.y - position.offset
                    log.debug("iCloud Sync: ATTEMPTING TO CLOUD SCROLL for \(type)")
                    // we need to include an inset when the background is translucent
                    var additionalOffset = 0.0
                    if UIDevice.current.userInterfaceIdiom == .phone, !additionalSafeAreaInsets.top.isZero {
                        additionalOffset = 25.0
                        tableView.contentOffset.y = yOffset - view.safeAreaInsets.top + additionalOffset
                    } else if !additionalSafeAreaInsets.top.isZero {
                        additionalOffset = 50.0
                        tableView.contentOffset.y = yOffset - additionalOffset
                    } else {
                        tableView.contentOffset.y = yOffset - view.safeAreaInsets.top
                    }
                } else {
                    log.error("iCloud Sync: #scrollToPosition1: no indexpath found for \(type)")
                }
            } else {
                log.error("iCloud Sync: #scrollToPosition1: position.model is not a postcard for \(type)")
            }
        } else {
            log.error("iCloud Sync: #scrollToPosition1: tableview frame not greater than 0 for \(type)")
        }
    }

    func scrollToPosition(tableView: UITableView, snapshot: NewsFeedSnapshot, position: NewsFeedScrollPosition) {
        if tableView.frame.width > 0 {
            if let model = position.model {
                if let indexPath = viewModel.getIndexPathForItem(snapshot: snapshot, item: model) {
                    let yOffset = tableView.rectForRow(at: indexPath).origin.y - position.offset
                    if yOffset > 0 {
                        // we need to include an inset when the background is translucent
                        var additionalOffset = 0.0

                        UIView.setAnimationsEnabled(false)
                        if UIDevice.current.userInterfaceIdiom == .phone, !additionalSafeAreaInsets.top.isZero {
                            additionalOffset = 176
                            tableView.contentOffset.y = yOffset - view.safeAreaInsets.top + additionalOffset
                        } else if !additionalSafeAreaInsets.top.isZero {
                            additionalOffset = 50.0
                            tableView.contentOffset.y = yOffset - additionalOffset
                        } else {
                            tableView.contentOffset.y = yOffset - view.safeAreaInsets.top
                        }
                        UIView.setAnimationsEnabled(true)
                    }
                } else {
                    log.error("#scrollToPosition2: no indexpath found")
                }
            } else {
                log.error("@scrollToPosition2: no model (shouldn't happen!)")
            }
        }
    }

    enum ScrollPositionReference { case top, bottom }

    @discardableResult
    func cacheScrollPosition(tableView: UITableView, forFeed type: NewsFeedTypes, scrollReference: ScrollPositionReference = .top) -> NewsFeedScrollPosition? {
        if let navBar = navigationController?.navigationBar {
            let whereIsNavBarInTableView = tableView.convert(navBar.bounds, from: navBar)
            let pointWhereNavBarEnds = CGPoint(x: 0, y: whereIsNavBarInTableView.origin.y + whereIsNavBarInTableView.size.height)

            if let currentCellIndexPath = getCurrentCellIndexPath(tableView: tableView, scrollReference: scrollReference) {
                guard let model = viewModel.getItemForIndexPath(currentCellIndexPath) else {
                    return nil
                }
                let rectForTopRow = tableView.rectForRow(at: currentCellIndexPath)
                // The Mentions and Activity views use a custom CarouselNavigationHeader,
                // and not the standard NavigationBar
                let additionalOffset: CGFloat
                switch viewModel.type {
                case .mentionsIn, .mentionsOut, .activity:
                    additionalOffset = 16.0
                default:
                    additionalOffset = 0.0
                }
                let offset = rectForTopRow.origin.y - pointWhereNavBarEnds.y + additionalOffset
                let scrollPosition = viewModel.setScrollPosition(model: model, offset: offset, forFeed: type)
                return scrollPosition
            }
        }

        return nil
    }

    func getCurrentCellIndexPath(tableView: UITableView, scrollReference: ScrollPositionReference = .top) -> IndexPath? {
        switch scrollReference {
        case .top:
            return tableView.indexPathsForVisibleRows?.first
        case .bottom:
            return tableView.indexPathsForVisibleRows?.last
        }
    }
}

// MARK: - Jump to newest

extension NewsFeedViewController: JumpToNewest {
    func jumpToNewest() {
        viewModel.userHasScrolledManually = true

        if !viewModel.pollingReachedTop {
            // refresh because we didn't reach the top of the feed.
            viewModel.stopPollingListData()
            viewModel.cancelAllItemSyncs()
            deferredSnapshotUpdatesCallbacks = []

            isScrollingProgrammatically = true

            viewModel.clearSnapshot()
            disableFeedUpdates = true
            showLoader(enabled: true)

            viewModel.setShowJumpToNow(enabled: false, forFeed: viewModel.type)
            viewModel.clearAllUnreadIds(forFeed: viewModel.type)
            didUpdateUnreadState(type: viewModel.type)

            unreadIndicator.configure(unreadCount: 0)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self else { return }

                Task { [weak self] in
                    guard let self else { return }
                    try await self.viewModel.loadListData(type: self.viewModel.type, fetchType: .refresh)
                }

                self.disableFeedUpdates = false
            }
        } else {
            // just scroll to the top.
            viewModel.stopPollingListData()
            viewModel.cancelAllItemSyncs()
            deferredSnapshotUpdatesCallbacks = []

            isScrollingProgrammatically = true

            disableFeedUpdates = true

            viewModel.setShowJumpToNow(enabled: false, forFeed: viewModel.type)
            viewModel.clearAllUnreadIds(forFeed: viewModel.type)
            didUpdateUnreadState(type: viewModel.type)

            tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)

            disableFeedUpdates = false

            viewModel.startPollingListData(forFeed: viewModel.type, delay: 1)
        }
    }
}

// MARK: - Force reload feed

extension NewsFeedViewController {
    func startCheckingFYStatus() {
        viewModel.startCheckingFYStatus {
            DispatchQueue.main.async {
                self.tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }

    func forceReloadForYou() {
        viewModel.forceReloadForYou()
    }
}

// MARK: UIContextMenuInteractionDelegate

extension NewsFeedViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        guard case let .postCard(postCard) = viewModel.getItemForIndexPath(indexPath)
        else { return nil }

        if let cell = tableView.dequeueReusableCell(withIdentifier: PostCardCell.reuseIdentifier(for: postCard), for: indexPath) as? PostCardCell {
            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { _ in
                cell.createContextMenu(postCard: postCard) { [weak self] type, isActive, data in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, postCard: postCard, data: data)
                }
            })
        }

        return nil
    }
}

// MARK: - App state restoration

extension NewsFeedViewController: AppStateRestoration {
    func storeUserActivity(in activity: NSUserActivity) {
        guard let userActivityStorage = delegate?.userActivityStorageIdentifier() else {
            log.error("expected a valid userActivityStorageIdentifier")
            return
        }

        do {
            let encoder = JSONEncoder()
            let typeData = try encoder.encode(viewModel.type)
            activity.userInfo?[userActivityStorage] = typeData
        } catch {
            log.error("Unable to encode app state in NewsFeedViewController: \(error)")
        }
    }

    func restoreUserActivity(from activity: NSUserActivity) {
        guard let userActivityStorage = delegate?.userActivityStorageIdentifier() else {
            log.error("expected a valid userActivityStorageIdentifier")
            return
        }

        if let feedTypeData = activity.userInfo?[userActivityStorage] as? Data {
            do {
                let decoder = JSONDecoder()
                let feedType = try decoder.decode(NewsFeedTypes.self, from: feedTypeData)
                log.debug("NewsFeedViewController:" + #function + " feedType: \(feedType)")
                delegate?.willChangeFeed(feedType)
                viewModel.changeFeed(type: feedType)
            } catch {
                log.error("Unable to decode app state in NewsFeedViewController: \(error)")
            }
        }
    }
}

// MARK: - Additional nav bar items

extension NewsFeedViewController {
    // Return additional navbar items for the current view controller
    func navBarItems() -> [UIBarButtonItem] {
        switch viewModel.type {
        case let .hashtag(tag):
            return hashtagNavBarItems(hashtag: tag.name)
        case let .list(list):
            return listNavBarItems(list: list)
        case .forYou:
            return []
        default:
            return []
        }
    }

    func contextMenu() -> UIMenu {
        var options: [UIAction] = []

        switch viewModel.type {
        case let .community(name):
            options = communityNavBarContextOptions(instanceName: name)
        case let .list(list):
            var exclusiveListMenuDeferred: UIDeferredMenuElement
            if #available(iOS 15.0, *) {
                exclusiveListMenuDeferred = UIDeferredMenuElement.uncached { completion in
                    completion(self.listNavBarContextOptions(list: list))
                }
            } else {
                exclusiveListMenuDeferred = UIDeferredMenuElement { completion in
                    completion(self.listNavBarContextOptions(list: list))
                }
            }
            return UIMenu(title: "", options: [.displayInline], children: [exclusiveListMenuDeferred])
        default:
            break
        }

        return UIMenu(title: "", options: [.displayInline], children: options)
    }

    private func communityNavBarContextOptions(instanceName: String) -> [UIAction] {
        var contextMenuOptions: [UIAction] = []

        let view_trends = NSLocalizedString("home.viewTrends", comment: "Button for showing trends of an instance in the carousel.")
        let option = UIAction(title: view_trends, image: UIImage(systemName: "binoculars"), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = ExploreViewController()
            vc.showingSearch = false
            vc.fromOtherCommunity = true
            vc.otherInstance = instanceName
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        option.accessibilityLabel = view_trends
        contextMenuOptions.append(option)

        return contextMenuOptions
    }

    private func hashtagNavBarItems(hashtag: String) -> [UIBarButtonItem] {
        let followedHashtags = HashtagManager.shared.allHashtags()
        let isFollowing = followedHashtags.contains(where: { $0.name.lowercased() == hashtag.lowercased() })

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let btn = UIButton(type: .custom)

        if isFollowing {
            btn.addAction { [weak self] in
                guard let self else { return }
                triggerHapticImpact(style: .light)
                HashtagManager.shared.unfollowHashtag(hashtag.lowercased(), completion: { _ in })
                self.delegate?.willChangeFeed(.following)
                self.viewModel.changeFeed(type: .following)
            }

            btn.setImage(UIImage(systemName: "minus.circle", withConfiguration: symbolConfig)?.withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
            btn.accessibilityLabel = NSLocalizedString("accessibility.unfollowTag", comment: "Screen reader only.")

        } else {
            btn.addAction {
                triggerHapticImpact(style: .light)
                HashtagManager.shared.followHashtag(hashtag.lowercased(), completion: { _ in })
            }
            btn.setImage(UIImage(systemName: "plus.circle", withConfiguration: symbolConfig)?.withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
            btn.accessibilityLabel = NSLocalizedString("accessibility.followTag", comment: "Screen reader only.")
        }

        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)
        let moreButton = UIBarButtonItem(customView: btn)
        return [moreButton]
    }

    private func listNavBarItems(list: List) -> [UIBarButtonItem] {
        // Create nav button
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let btn = UIButton(type: .custom)
        btn.setImage(FontAwesome.image(fromChar: "\u{e10a}").withConfiguration(symbolConfig).withTintColor(.custom.highContrast, renderingMode: .alwaysTemplate), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.accessibilityLabel = NSLocalizedString("generic.more", comment: "")
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)

        // Create context menu
        let list_members = NSLocalizedString("list.members", comment: "As in 'members in the list'")
        let viewMembersMenu = UIAction(title: list_members, image: FontAwesome.image(fromChar: "\u{f500}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = UserListViewController(listID: list.id)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        viewMembersMenu.accessibilityLabel = list_members

        let edit_list_title = NSLocalizedString("list.editTitle", comment: "")
        let editTitleMenu = UIAction(title: edit_list_title, image: FontAwesome.image(fromChar: "\u{f304}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = AltTextViewController()
            vc.editList = list.title
            vc.listId = list.id
            vc.delegate = self
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        if !ListManager.shared.isTitleEditable(List(id: list.id, title: list.title)) {
            editTitleMenu.attributes = .disabled
        }
        editTitleMenu.accessibilityLabel = edit_list_title

        let delete_list = NSLocalizedString("list.delete", comment: "")
        let deleteMenu = UIAction(title: delete_list, image: FontAwesome.image(fromChar: "\u{f1f8}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(title: nil, message: NSLocalizedString("list.delete.confirm", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.delete", comment: ""), style: .destructive, handler: { _ in
                ListManager.shared.deleteList(list.id) { _ in
                    DispatchQueue.main.async {
                        self.delegate?.willChangeFeed(.following)
                        self.viewModel.changeFeed(type: .following)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel, handler: { _ in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
        deleteMenu.accessibilityLabel = delete_list
        deleteMenu.attributes = .destructive

        let itemMenu = UIMenu(title: "", options: [], children: [viewMembersMenu, editTitleMenu, deleteMenu])
        btn.menu = itemMenu
        btn.showsMenuAsPrimaryAction = true
        btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: -1, right: 0)
        let moreButton = UIBarButtonItem(customView: btn)
        return [moreButton]
    }

    private func listNavBarContextOptions(list: List) -> [UIAction] {
        // Create context menu
        let list_members = NSLocalizedString("list.members", comment: "")
        let viewMembersMenu = UIAction(title: list_members, image: FontAwesome.image(fromChar: "\u{f500}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = UserListViewController(listID: list.id)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        viewMembersMenu.accessibilityLabel = list_members

        let edit_list_title = NSLocalizedString("list.editTitle", comment: "")
        let editTitleMenu = UIAction(title: edit_list_title, image: FontAwesome.image(fromChar: "\u{f304}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let vc = AltTextViewController()
            vc.editList = list.title
            vc.listId = list.id
            vc.delegate = self
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        if !ListManager.shared.isTitleEditable(List(id: list.id, title: list.title)) {
            editTitleMenu.attributes = .disabled
        }
        editTitleMenu.accessibilityLabel = edit_list_title

        let sortingList: List = ListManager.shared.allLists(includeTopFriends: false).filter { $0.id == list.id }[0]
        let exclusive_list = sortingList.exclusive! ? NSLocalizedString("list.exclusive.off", comment: "title for toggle to SHOW list posts in home timeline") : NSLocalizedString("list.exclusive.on", comment: "title for toggle to HIDE list posts from home timeline")
        let exclusiveListMenu = UIAction(title: exclusive_list, image: FontAwesome.image(fromChar: sortingList.exclusive! ? "\u{f06e}" : "\u{f070}", size: 16, weight: .regular).withRenderingMode(.alwaysTemplate), identifier: nil) { _ in
            ListManager.shared.updateListExclusivePosts(sortingList.id, exclusive: !sortingList.exclusive!) { success in
                if success {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "postListUpdated"), object: nil)
                }
            }
        }
        exclusiveListMenu.accessibilityLabel = exclusive_list

        let delete_list = NSLocalizedString("list.delete", comment: "")
        let deleteMenu = UIAction(title: delete_list, image: FontAwesome.image(fromChar: "\u{f1f8}", size: 16, weight: .bold).withRenderingMode(.alwaysTemplate), identifier: nil) { [weak self] _ in
            guard let self else { return }
            let alert = UIAlertController(title: nil, message: NSLocalizedString("list.delete.confirm", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.delete", comment: ""), style: .destructive, handler: { _ in
                ListManager.shared.deleteList(list.id) { _ in
                    DispatchQueue.main.async {
                        self.delegate?.willChangeFeed(.following)
                        self.viewModel.changeFeed(type: .following)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel, handler: { _ in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
        deleteMenu.accessibilityLabel = delete_list
        deleteMenu.attributes = .destructive

        return [viewMembersMenu, editTitleMenu, exclusiveListMenu, deleteMenu]
    }
}

// MARK: - Edit list delegate

extension NewsFeedViewController: AltTextViewControllerDelegate {
    func didConfirmText(updatedText: String) {
        if case let .list(list) = viewModel.type {
            viewModel.type = .list(List(id: list.id, title: updatedText))
            title = viewModel.type.title()
        }
    }
}

// MARK: - Feed menu

extension NewsFeedViewController {
    @objc func feedMenuItemsChanged() {
        feedMenuItems = []

        navigationItem.setRightBarButtonItems(navBarItems(), animated: false)
        title = viewModel.type.title()
    }
}

extension NewsFeedViewController: JumpToLatestDelegate {
    func onClosePress() {
        viewModel.setShowJumpToNow(enabled: false, forFeed: viewModel.type)
        jumpToNow.isEnabled = false
        viewModel.isJumpToNowButtonDisabled = true
    }
}
