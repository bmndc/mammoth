//
//  PostResultsViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 10/6/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class PostResultsViewModel {
    enum ScreenPosition {
        case main
        case aux
    }

    private enum ViewTypes: Int, CaseIterable {
        case regular
        case typing
        case searchResult
    }

    weak var delegate: RequestDelegate?
    let position: ScreenPosition

    private var type: ViewTypes = .regular
    private var state: ViewState {
        didSet {
            delegate?.didUpdate(with: state)
        }
    }

    private var searchDebouncer: Timer?
    private var searchTask: Task<Void, Never>?
    private var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                // TODO: make class vars thread-safe instead
                DispatchQueue.main.async {
                    self.type = .regular
                    self.state = .success
                }
            } else {
                if let task = searchTask, !task.isCancelled {
                    task.cancel()
                }

                searchTask = Task {
                    await self.searchAll(query: self.searchQuery)
                }
            }
        }
    }

    private var listData: [PostCardModel] = [] // posts visible to the user in the table
    private var suggested: [PostCardModel] = [] // all posts from search result

    init(screenPosition: ScreenPosition = .main) {
        state = .idle
        position = screenPosition

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onUpdateClient),
                                               name: NSNotification.Name(rawValue: "updateClient"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onPostCardUpdate),
                                               name: PostActions.didUpdatePostCardNotification,
                                               object: nil)
        Task {
            await self.loadRecommendations()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func pauseAllVideos() {
        for listData in listData {
            listData.videoPlayer?.pause()
        }
    }
}

// MARK: - DataSource

extension PostResultsViewModel {
    func numberOfItems(forSection _: Int) -> Int {
        return listData.count
    }

    var numberOfSections: Int {
        return 1
    }

    func hasHeader(forSection _: Int) -> Bool {
        switch type {
        case .regular:
            return true
        case .typing:
            return false
        case .searchResult:
            return false
        }
    }

    func shouldSyncFollowStatus() -> Bool {
        switch type {
        case .typing:
            return false
        default:
            return true
        }
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> PostCardModel {
        return listData[indexPath.row]
    }

    func getSectionTitle(for _: Int) -> String {
        switch type {
        case .regular:
            return NSLocalizedString("activity.posts", comment: "")
        case .typing:
            return NSLocalizedString("activity.posts", comment: "")
        case .searchResult:
            return NSLocalizedString("activity.posts", comment: "")
        }
    }

    func updateFollowStatus(atIndexPath _: IndexPath, forceUpdate _: Bool = false) {}

    func updateFollowStatusForAccountName(_: String!, followStatus _: FollowManager.FollowStatus) -> Int? {
        return nil
    }
}

// MARK: - Service

extension PostResultsViewModel {
    func loadRecommendations() async {
        // The initial state here is an empty list
        DispatchQueue.main.async {
            self.state = .loading
            self.suggested = []
            self.listData = self.suggested
            self.state = .success
        }
    }

    func search(query: String, fullSearch: Bool = false) {
        // Debounce search
        searchDebouncer?.invalidate()

        if fullSearch {
            type = .searchResult
            state = .success // force a table reload
        } else {
            type = .typing
            state = .success // force a table reload
        }

        if query.isEmpty {
            searchQuery = query
        } else {
            searchDebouncer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { [weak self] _ in
                guard let self else { return }
                self.searchQuery = query
            })
        }
    }

    func searchAll(query: String) async {
        state = .loading
        do {
            let result = try await SearchService.searchPosts(query: query)
            DispatchQueue.main.async {
                self.listData = result.map { PostCardModel(status: $0) }
                self.state = .success
            }
        } catch {
            // TODO: make class vars thread-safe instead
            DispatchQueue.main.async {
                self.state = .error(error)
            }
        }
    }

    func cancelSearch() {
        type = .regular
        listData = suggested
        searchQuery = ""
    }

    func syncFollowStatus(forIndexPaths _: [IndexPath]) {}
}

// MARK: - Notification handlers

private extension PostResultsViewModel {
    @objc func didSwitchAccount() {
        Task {
            // Reload recommentations when a user is set/changed
            await self.loadRecommendations()
        }
    }

    @objc func onUpdateClient() {
        Task {
            // Reload recommentations when a user is set/changed
            await self.loadRecommendations()
        }
    }

    @objc func onPostCardUpdate(notification: Notification) {
        if let postCard = notification.userInfo?["postCard"] as? PostCardModel {
            if let cardIndex = listData.firstIndex(where: { $0.uniqueId == postCard.uniqueId }) {
                DispatchQueue.main.async {
                    if let isDeleted = notification.userInfo?["deleted"] as? Bool, isDeleted == true {
                        // Delete post card data in list data
                        self.listData.remove(at: cardIndex)
                        // Request a table view cell refresh
                        self.delegate?.didDeleteCard(at: IndexPath(row: cardIndex, section: 0))
                    } else {
                        // Replace post card data in list data
                        self.listData[cardIndex] = postCard
                        // Request a table view cell refresh
                        self.delegate?.didUpdateCard(at: IndexPath(row: cardIndex, section: 0))
                    }
                }
            }
        }
    }
}
