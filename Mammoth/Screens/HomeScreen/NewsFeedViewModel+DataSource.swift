//
//  NewsFeedViewModel+DataSource.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

enum NewsFeedSections {
    case main
    case loader
    case empty
}

// swiftlint:disable:next type_body_length
struct NewsFeedListData {
    var forYou: [NewsFeedListItem]?
    var following: [NewsFeedListItem]?
    var federated: [NewsFeedListItem]?
    var community: [String: [NewsFeedListItem]] = [:]
    var trending: [String: [NewsFeedListItem]] = [:]
    var hashtag: [String: [NewsFeedListItem]] = [:]
    var list: [String: [NewsFeedListItem]] = [:]
    var likes: [NewsFeedListItem]?
    var bookmarks: [NewsFeedListItem]?
    var mentionsIn: [NewsFeedListItem]?
    var mentionsOut: [NewsFeedListItem]?
    var activity: [String: [NewsFeedListItem]] = [:]
    var channel: [String: [NewsFeedListItem]] = [:]

    let empty = NewsFeedListItem.empty
    let loadMore = NewsFeedListItem.loadMore
    let error = NewsFeedListItem.error

    func forType(type: NewsFeedTypes) -> [NewsFeedListItem]? {
        switch type {
        case .forYou:
            return forYou
        case .following:
            return following
        case .federated:
            return federated
        case let .community(name):
            return community[name]
        case let .trending(name):
            return trending[name]
        case let .hashtag(tag):
            return hashtag[tag.name]
        case let .list(list):
            return self.list[list.id]
        case .likes:
            return likes
        case .bookmarks:
            return bookmarks
        case .mentionsIn:
            return mentionsIn
        case .mentionsOut:
            return mentionsOut
        case let .activity(type):
            return activity[type?.rawValue ?? "all"]
        case let .channel(channel):
            return self.channel[channel.id]
        }
    }

    mutating func set(items: [NewsFeedListItem], forType type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou = items
        case .following:
            following = items
        case .federated:
            federated = items
        case let .community(name):
            community[name] = items
        case let .trending(name):
            trending[name] = items
        case let .hashtag(tag):
            hashtag[tag.name] = items
        case let .list(list):
            self.list[list.id] = items
        case .likes:
            likes = items
        case .bookmarks:
            bookmarks = items
        case .mentionsIn:
            mentionsIn = items
        case .mentionsOut:
            mentionsOut = items
        case let .activity(type):
            activity[type?.rawValue ?? "all"] = items
        case let .channel(channel):
            self.channel[channel.id] = items
        }
    }

    mutating func clear(forType type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou = []
        case .following:
            following = []
        case .federated:
            federated = []
        case let .community(name):
            community[name] = []
        case let .trending(name):
            trending[name] = []
        case let .hashtag(tag):
            hashtag[tag.name] = []
        case let .list(list):
            self.list[list.id] = []
        case .likes:
            likes = []
        case .bookmarks:
            bookmarks = []
        case .mentionsIn:
            mentionsIn = []
        case .mentionsOut:
            mentionsOut = []
        case let .activity(type):
            activity[type?.rawValue ?? "all"] = []
        case let .channel(channel):
            self.channel[channel.id] = []
        }
    }

    mutating func insert(items: [NewsFeedListItem], forType type: NewsFeedTypes, after: NewsFeedListItem) {
        switch type {
        case .forYou:
            let index = forYou?.firstIndex(where: { $0 == after })
            var copy = forYou
            copy?.insert(contentsOf: items, at: index ?? forYou?.count ?? 0)
            forYou = copy

        case .following:
            let index = following?.firstIndex(where: { $0 == after })
            var copy = following
            copy?.insert(contentsOf: items, at: index ?? following?.count ?? 0)
            following = copy

        case .federated:
            let index = federated?.firstIndex(where: { $0 == after })
            var copy = federated
            copy?.insert(contentsOf: items, at: index ?? federated?.count ?? 0)
            federated = copy

        case let .community(name):
            let index = community[name]?.firstIndex(where: { $0 == after })
            var copy = community[name]
            copy?.insert(contentsOf: items, at: index ?? community[name]?.count ?? 0)
            community[name] = copy

        case let .trending(name):
            let index = trending[name]?.firstIndex(where: { $0 == after })
            var copy = trending[name]
            copy?.insert(contentsOf: items, at: index ?? trending[name]?.count ?? 0)
            trending[name] = copy

        case let .hashtag(tag):
            let index = hashtag[tag.name]?.firstIndex(where: { $0 == after })
            var copy = hashtag[tag.name]
            copy?.insert(contentsOf: items, at: index ?? hashtag[tag.name]?.count ?? 0)
            hashtag[tag.name] = copy

        case let .list(list):
            let index = self.list[list.id]?.firstIndex(where: { $0 == after })
            var copy = self.list[list.id]
            copy?.insert(contentsOf: items, at: index ?? self.list[list.id]?.count ?? 0)
            self.list[list.id] = copy

        case .likes:
            let index = likes?.firstIndex(where: { $0 == after })
            var copy = likes
            copy?.insert(contentsOf: items, at: index ?? likes?.count ?? 0)
            likes = copy

        case .bookmarks:
            let index = bookmarks?.firstIndex(where: { $0 == after })
            var copy = bookmarks
            copy?.insert(contentsOf: items, at: index ?? bookmarks?.count ?? 0)
            bookmarks = copy

        case .mentionsIn:
            let index = mentionsIn?.firstIndex(where: { $0 == after })
            var copy = mentionsIn
            copy?.insert(contentsOf: items, at: index ?? mentionsIn?.count ?? 0)
            mentionsIn = copy

        case .mentionsOut:
            let index = mentionsOut?.firstIndex(where: { $0 == after })
            var copy = mentionsOut
            copy?.insert(contentsOf: items, at: index ?? mentionsOut?.count ?? 0)
            mentionsOut = copy

        case let .activity(type):
            let key = type?.rawValue ?? "all"
            let index = activity[key]?.firstIndex(where: { $0 == after })
            var copy = activity[key]
            copy?.insert(contentsOf: items, at: index ?? activity[key]?.count ?? 0)
            activity[key] = copy

        case let .channel(channel):
            let index = self.channel[channel.id]?.firstIndex(where: { $0 == after })
            var copy = self.channel[channel.id]
            copy?.insert(contentsOf: items, at: index ?? self.channel[channel.id]?.count ?? 0)
            self.channel[channel.id] = copy
        }
    }

    mutating func update(item: NewsFeedListItem) {
        for feedType in NewsFeedTypes.allCases {
            switch feedType {
            case .forYou:
                if let index = forYou?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    update(item: item, atIndex: index, forType: feedType)
                }

            case .following:
                if let index = following?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    update(item: item, atIndex: index, forType: feedType)
                }

            case .federated:
                if let index = federated?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    update(item: item, atIndex: index, forType: feedType)
                }

            case .community:
                for (key, community) in community {
                    if let index = community.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        update(item: item, atIndex: index, forType: .community(key))
                    }
                }

            case .trending:
                for (key, trending) in trending {
                    if let index = trending.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        update(item: item, atIndex: index, forType: .trending(key))
                    }
                }

            case .hashtag:
                for (key, hashtag) in hashtag {
                    if let index = hashtag.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        update(item: item, atIndex: index, forType: .hashtag(Tag(name: key, url: "")))
                    }
                }

            case .list:
                for (key, list) in list {
                    if let index = list.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        update(item: item, atIndex: index, forType: .list(List(id: key, title: "")))
                    }
                }

            case .likes:
                if let index = likes?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    update(item: item, atIndex: index, forType: feedType)
                }

            case .bookmarks:
                if let index = bookmarks?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    update(item: item, atIndex: index, forType: feedType)
                }

            case .mentionsIn:
                if let index = mentionsIn?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    update(item: item, atIndex: index, forType: feedType)
                }

            case .mentionsOut:
                if let index = mentionsOut?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    update(item: item, atIndex: index, forType: feedType)
                }

            case .activity:
                for (key, activities) in activity {
                    let activityType: NotificationType? = key == "all" ? nil : NotificationType(rawValue: key)
                    if let index = activities.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        update(item: item, atIndex: index, forType: .activity(activityType))
                    } else if let index = activities.firstIndex(where: { $0.extractPostCard()?.uniqueId == item.uniqueId() }) {
                        // update the postcard in the activity
                        if case let .activity(activity) = activities[index] {
                            activity.postCard = item.extractPostCard()
                            update(item: .activity(activity), atIndex: index, forType: .activity(activityType))
                        }
                    }
                }

            case .channel:
                for (key, channel) in channel {
                    if let index = channel.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        update(item: item, atIndex: index, forType: .channel(Channel(id: key, title: "", owner: ChannelOwner())))
                    }
                }
            }
        }
    }

    mutating func update(item: NewsFeedListItem, atIndex index: Int, forType type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou?[index] = item
        case .following:
            following?[index] = item
        case .federated:
            federated?[index] = item
        case let .community(name):
            community[name]?[index] = item
        case let .trending(name):
            trending[name]?[index] = item
        case let .hashtag(tag):
            hashtag[tag.name]?[index] = item
        case let .list(list):
            self.list[list.id]?[index] = item
        case .likes:
            likes?[index] = item
        case .bookmarks:
            bookmarks?[index] = item
        case .mentionsIn:
            mentionsIn?[index] = item
        case .mentionsOut:
            mentionsOut?[index] = item
        case let .activity(type):
            activity[type?.rawValue ?? "all"]?[index] = item
        case let .channel(channel):
            self.channel[channel.id]?[index] = item
        }
    }

    @discardableResult
    mutating func remove(atIndex index: Int, forType type: NewsFeedTypes) -> NewsFeedListItem? {
        switch type {
        case .forYou:
            return forYou?.remove(at: index)
        case .following:
            return following?.remove(at: index)
        case .federated:
            return federated?.remove(at: index)
        case let .community(name):
            return community[name]?.remove(at: index)
        case let .trending(name):
            return trending[name]?.remove(at: index)
        case let .hashtag(tag):
            return hashtag[tag.name]?.remove(at: index)
        case let .list(list):
            return self.list[list.id]?.remove(at: index)
        case .likes:
            return likes?.remove(at: index)
        case .bookmarks:
            return bookmarks?.remove(at: index)
        case .mentionsIn:
            return mentionsIn?.remove(at: index)
        case .mentionsOut:
            return mentionsOut?.remove(at: index)
        case let .activity(type):
            return activity[type?.rawValue ?? "all"]?.remove(at: index)
        case let .channel(channel):
            return self.channel[channel.id]?.remove(at: index)
        }
    }

    mutating func remove(item: NewsFeedListItem) {
        for feedType in NewsFeedTypes.allCases {
            switch feedType {
            case .forYou:
                if let index = forYou?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    remove(atIndex: index, forType: feedType)
                }
            case .following:
                if let index = following?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    remove(atIndex: index, forType: feedType)
                }
            case .federated:
                if let index = federated?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    remove(atIndex: index, forType: feedType)
                }
            case .community:
                for (key, community) in community {
                    if let index = community.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        remove(atIndex: index, forType: .community(key))
                    }
                }
            case .trending:
                for (key, trending) in trending {
                    if let index = trending.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        remove(atIndex: index, forType: .trending(key))
                    }
                }
            case .hashtag:
                for (key, hashtag) in hashtag {
                    if let index = hashtag.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        remove(atIndex: index, forType: .hashtag(Tag(name: key, url: "")))
                    }
                }
            case .list:
                for (key, list) in list {
                    if let index = list.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        remove(atIndex: index, forType: .list(List(id: key, title: "")))
                    }
                }
            case .likes:
                if let index = likes?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    remove(atIndex: index, forType: feedType)
                }
            case .bookmarks:
                if let index = bookmarks?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    remove(atIndex: index, forType: feedType)
                }
            case .mentionsIn:
                if let index = mentionsIn?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    remove(atIndex: index, forType: feedType)
                }
            case .mentionsOut:
                if let index = mentionsOut?.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                    remove(atIndex: index, forType: feedType)
                }
            case .activity:
                for (key, activities) in activity {
                    if let index = activities.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        let activityType: NotificationType? = key == "all" ? nil : NotificationType(rawValue: key)
                        remove(atIndex: index, forType: .activity(activityType))
                    }
                }
            case .channel:
                for (key, channel) in channel {
                    if let index = channel.firstIndex(where: { $0.uniqueId() == item.uniqueId() }) {
                        remove(atIndex: index, forType: .channel(Channel(id: key, title: "", owner: ChannelOwner())))
                    }
                }
            }
        }
    }
}

// MARK: - Data source accessors & mutators

extension NewsFeedViewModel {
    // MARK: - Set

    func syncDataSource(type: NewsFeedTypes? = nil, completed: (() -> Void)? = nil) {
        let feedType = type ?? self.type
        let cards = listData.forType(type: feedType)?.removingDuplicates().removeMutesAndBlocks().removeFiltered() ?? []

        if cards.isEmpty {
            // Retrieve cards and scroll position from disk
            clearSnapshot()
            state = .loading
            delegate?.showLoader(enabled: true)
            hydrateCache(forFeedType: feedType) { [weak self] retrievedItems, retrievedPosition in
                guard let self else { return }

                self.snapshot.deleteSections([.main])
                self.snapshot = self.appendMainSectionToSnapshot(snapshot: self.snapshot)

                guard retrievedItems != nil else {
                    self.state = .success
                    completed?()
                    return
                }

                self.snapshot.appendItems(retrievedItems?.removingDuplicates().removeMutesAndBlocks() ?? [], toSection: .main)
                self.snapshot.deleteSections([.empty])
                self.isLoadMoreEnabled = true
                self.state = .success
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: feedType,
                                                 updateType: .hydrate,
                                                 scrollPosition: retrievedPosition,
                                                 onCompleted: completed)
            }
        } else {
            // Retrieve cards and scroll position from memory
            state = .loading
            snapshot.deleteSections([.main])
            snapshot.appendSections([.main])

            snapshot.appendItems(cards, toSection: .main)
            if !cards.isEmpty {
                snapshot.deleteSections([.main])
            }
            isLoadMoreEnabled = true
            state = .success

            delegate?.didUpdateSnapshot(snapshot,
                                        feedType: feedType,
                                        updateType: .hydrate,
                                        scrollPosition: nil,
                                        onCompleted: completed)
        }
    }

    func set(withCards cards: [PostCardModel], forType type: NewsFeedTypes) {
        set(withItems: toListCardItems(cards), forType: type)
    }

    func set(withItems items: [NewsFeedListItem], forType type: NewsFeedTypes, silently: Bool = false) {
        listData.set(items: items.removingDuplicates(), forType: type)

        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }

        snapshot.deleteSections([.main])
        snapshot.appendSections([.main])

        snapshot.appendItems(items.removingDuplicates(), toSection: .main)

        if !silently {
            delegate?.didUpdateSnapshot(snapshot,
                                        feedType: type,
                                        updateType: .replaceAll,
                                        scrollPosition: nil,
                                        onCompleted: nil)
        }
    }

    // MARK: - Update

    func update(with item: NewsFeedListItem, forType type: NewsFeedTypes, silently: Bool = false) {
        listData.update(item: item)

        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }
        guard let _ = listData.forType(type: type)?.first(where: { $0.uniqueId() == item.uniqueId() }) else { return }

        if snapshot.indexOfItem(item) != nil {
            if #available(iOS 15.0, *) {
                self.snapshot.reconfigureItems([item])
            } else {
                snapshot.reloadItems([item])
            }

            if !silently {
                delegate?.didUpdateSnapshot(snapshot,
                                            feedType: type,
                                            updateType: .update,
                                            scrollPosition: nil,
                                            onCompleted: nil)
            }
        } else {
            // This might happen when the view is not in the view hierarchy
            log.debug("updating 1 item but can not find it (replaceAll instead)")
            let allItems = listData.forType(type: type)?.removingDuplicates()
            set(withItems: allItems ?? [], forType: type, silently: silently)
        }
    }

    func updateFollowStatusForPosts(fromAccount fullAcct: String) {
        var didUpdateSnapshot = false
        for itemIdentifier in snapshot.itemIdentifiers {
            if let postCard = itemIdentifier.extractPostCard(),
               let postCardFullAccount = postCard.user?.account?.fullAcct,
               postCardFullAccount == fullAcct
            {
                postCard.user?.syncFollowStatus(.none)
                let item = NewsFeedListItem.postCard(postCard)

                if snapshot.indexOfItem(item) != nil {
                    if #available(iOS 15.0, *) {
                        self.snapshot.reconfigureItems([item])
                    } else {
                        snapshot.reloadItems([item])
                    }

                    didUpdateSnapshot = true
                }
            }
        }

        if didUpdateSnapshot {
            delegate?.didUpdateSnapshot(snapshot,
                                        feedType: type,
                                        updateType: .update,
                                        scrollPosition: nil,
                                        onCompleted: nil)
        }
    }

    // MARK: - Insert

    func append(items: [NewsFeedListItem], forType type: NewsFeedTypes, after: NewsFeedListItem? = nil) {
        guard let _ = snapshot.indexOfSection(.main) else { return }

        let current = snapshot.itemIdentifiers(inSection: .main)

        if let after {
            listData.insert(items: items, forType: type, after: after)
        } else {
            listData.set(items: current + items, forType: type)
        }

        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }

        snapshot = appendMainSectionToSnapshot(snapshot: snapshot)

        let uniques = items.filter { !self.snapshot.itemIdentifiers(inSection: .main).contains($0) }
        if !uniques.isEmpty {
            if let after, snapshot.itemIdentifiers.contains(after) {
                snapshot.insertItems(uniques, afterItem: after)
                delegate?.didUpdateSnapshot(snapshot,
                                            feedType: type,
                                            updateType: .inject,
                                            scrollPosition: nil,
                                            onCompleted: nil)
            } else {
                snapshot.appendItems(uniques, toSection: .main)
                delegate?.didUpdateSnapshot(snapshot,
                                            feedType: type,
                                            updateType: .append,
                                            scrollPosition: nil,
                                            onCompleted: nil)
            }
        } else {
            // Trying to append 0 items after another element means we need to remove the "load more" button
            if let _ = after {
                hideLoadMore(feedType: type)
                delegate?.didUpdateSnapshot(snapshot,
                                            feedType: type,
                                            updateType: .remove,
                                            scrollPosition: nil,
                                            onCompleted: nil)
            }
        }
    }

    func insert(items: [NewsFeedListItem], forType type: NewsFeedTypes) {
        let current = listData.forType(type: type) ?? []
        listData.set(items: items + current, forType: type)

        // Don't update data source if this feed is not currently viewed
        guard type == self.type else { return }

        if !snapshot.sectionIdentifiers.contains(.main) {
            snapshot.appendSections([.main])
        }

        if let firstItem = snapshot.itemIdentifiers(inSection: .main).first {
            snapshot.insertItems(items, beforeItem: firstItem)
        } else {
            snapshot.appendItems(items, toSection: .main)
        }

        delegate?.didUpdateSnapshot(snapshot,
                                    feedType: type,
                                    updateType: .insert,
                                    scrollPosition: nil)
        { [weak self] in
            guard let self else { return }
            self.insertUnreadIds(ids: items.map { $0.uniqueId() }, forFeed: type)
            self.delegate?.didUpdateUnreadState(type: type)
        }
    }

    func appendMainSectionToSnapshot(snapshot: NewsFeedSnapshot) -> NewsFeedSnapshot {
        var snapshot = snapshot
        if !snapshot.sectionIdentifiers.contains(.main) {
            snapshot.appendSections([.main])
        }

        return snapshot
    }

    func insertNewest(items: [NewsFeedListItem], includeLoadMore: Bool, forType type: NewsFeedTypes) {
        // don't update data source if this feed is not currently viewed
        guard type == self.type else { return }

        // append main section if needed
        snapshot = appendMainSectionToSnapshot(snapshot: snapshot)
        let numberOfItemsPreUpdate = snapshot.numberOfItems(inSection: .main)

        if let isReadingNewest = isReadingNewest(forType: type) {
            if isReadingNewest {
                // if the user is reading the newest posts remove old items at the bottom
                removeOldFromSnapshot(forType: type)
            } else {
                // if the user is NOT reading the newest posts remove newest items at the top
                removeNewestFromSnapshot(forType: type)
            }
        }

        // insert new cards at the top
        if let firstItem = snapshot.itemIdentifiers(inSection: .main).first {
            snapshot.insertItems(items.removingDuplicates(), beforeItem: firstItem)
        } else {
            snapshot.appendItems(items.removingDuplicates(), toSection: .main)
        }

        // optionally add a "read more" button
        if includeLoadMore, let lastItem = items.last {
            displayLoadMore(after: lastItem, feedType: type)
        }

        // update in-memory cache
        listData.set(items: snapshot.itemIdentifiers(inSection: .main), forType: type)

        if numberOfItemsPreUpdate == 0 {
            setUnreadEnabled(enabled: false, forFeed: type)
            hideLoader(forType: type)
        }

        if snapshot.numberOfItems(inSection: .main) == 0 {
            showEmpty(forType: type)
        } else {
            delegate?.didUpdateSnapshot(snapshot,
                                        feedType: type,
                                        updateType: .insert,
                                        scrollPosition: nil)
            {
                // Set the unread state after updating the data source.
                // This will show the unread pill/indicator
                if GlobalStruct.feedReadDirection == .topDown {
                    if NewsFeedTypes.allActivityTypes.contains(type) || [.mentionsIn, .mentionsOut].contains(type) {
                        self.insertUnreadIds(ids: items.map { $0.uniqueId() }, forFeed: type)
                        self.setUnreadEnabled(enabled: true, forFeed: type)
                    } else {
                        if items.count >= 5, numberOfItemsPreUpdate > 0 {
                            self.insertUnreadIds(ids: items.map { $0.uniqueId() }, forFeed: type)
                            self.setUnreadEnabled(enabled: true, forFeed: type)
                        } else {
                            self.insertUnreadIds(ids: items.map { $0.uniqueId() }, forFeed: type)
                            self.setUnreadEnabled(enabled: false, forFeed: type)
                        }
                    }
                } else {
                    self.insertUnreadIds(ids: items.map { $0.uniqueId() }, forFeed: type)
                    self.setUnreadEnabled(enabled: true, forFeed: type)
                    self.delegate?.didUpdateUnreadState(type: type)
                }
            }
        }
    }

    // MARK: - Remove

    // When scrolled to the top we slice the feed to only keep the items above the "load more" button
    func removeOldItems(forType type: NewsFeedTypes) {
        DispatchQueue.main.async {
            // Don't update data source if this feed is not currently viewed
            guard type == self.type else { return }

            let didRemove = self.removeOldFromSnapshot(forType: self.type)
            if didRemove {
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: type,
                                                 updateType: .remove,
                                                 scrollPosition: nil,
                                                 onCompleted: nil)
            }
        }
    }

    func removeNewestFromSnapshot(forType type: NewsFeedTypes) {
        guard let _ = snapshot.indexOfSection(.main) else { return }
        let current = snapshot.itemIdentifiers(inSection: .main)
        if let lastNewItem = lastItemOfTheNewestItems(forType: type),
           let index = current.firstIndex(of: lastNewItem)
        {
            let newest = Array(current[0 ... index])
            log.debug("deleting \(newest.count) new items to be replaced")
            snapshot.deleteItems(newest)
        }
    }

    @discardableResult
    func removeOldFromSnapshot(forType type: NewsFeedTypes) -> Bool {
        guard let _ = snapshot.indexOfSection(.main) else { return false }
        let current = snapshot.itemIdentifiers(inSection: .main)
        if let lastNewItem = lastItemOfTheNewestItems(forType: type),
           let index = current.firstIndex(of: lastNewItem)
        {
            let old = Array(current[min(index + 1, current.count - 1)...])
            snapshot.deleteItems(old)
            snapshot.deleteItems([.loadMore])
            log.debug("deleting \(old.count) old items + the LoadMore btn")
            return true
        }

        return false
    }

    func remove(card: PostCardModel, forType type: NewsFeedTypes) {
        DispatchQueue.main.async {
            self.listData.remove(item: .loadMore)

            // Don't update data source if this feed is not currently viewed
            guard type == self.type else { return }
            let item = NewsFeedListItem.postCard(card)
            if self.snapshot.indexOfItem(item) != nil {
                self.snapshot.deleteItems([item])
                self.delegate?.didUpdateSnapshot(self.snapshot,
                                                 feedType: type,
                                                 updateType: .remove,
                                                 scrollPosition: nil,
                                                 onCompleted: nil)
            }
        }
    }

    func removePostsFromUsers(userIDs: [String]) {
        DispatchQueue.main.async {
            let itemsToDelete = self.snapshot.itemIdentifiers.filter { item in
                switch item {
                case let .postCard(postCardModel):
                    let isByUser = userIDs.contains(postCardModel.user?.id ?? "")
                    let isRebloggedByUser = userIDs.contains(postCardModel.rebloggerID ?? "")
                    return isByUser || isRebloggedByUser

                default:
                    return false
                }
            }

            guard !itemsToDelete.isEmpty else { return }

            self.snapshot.deleteItems(itemsToDelete)

            self.delegate?.didUpdateSnapshot(
                self.snapshot,
                feedType: self.type,
                updateType: .remove,
                scrollPosition: nil,
                onCompleted: nil
            )
        }
    }

    func refreshSnapshot() {
        log.debug("[NewsFeedViewModel] Refresh snapshot")
        let feedType = type
        let cards = listData.forType(type: feedType)?
            .removingDuplicates()
            .removeMutesAndBlocks()
            .removeFiltered() ?? []

        if !snapshot.itemIdentifiers.isEmpty, !snapshot.sectionIdentifiers.isEmpty {
            snapshot.deleteAllItems()
        }
        snapshot = appendMainSectionToSnapshot(snapshot: snapshot)
        snapshot.appendItems(cards, toSection: .main)
        isLoadMoreEnabled = true
        state = .success

        delegate?.didUpdateSnapshot(snapshot,
                                    feedType: feedType,
                                    updateType: .replaceAll,
                                    scrollPosition: nil,
                                    onCompleted: nil)
    }

    func clearSnapshot() {
        log.debug("[NewsFeedViewModel] Clear snapshot")
        guard !snapshot.sectionIdentifiers.isEmpty else { return }
        snapshot.deleteAllItems()
        delegate?.didUpdateSnapshot(
            snapshot,
            feedType: type,
            updateType: .removeAll,
            scrollPosition: nil,
            onCompleted: nil
        )
    }

    func removeAll(type: NewsFeedTypes, clearScrollPosition: Bool = true) {
        guard type == self.type else { return }

        log.debug("[NewsFeedViewModel] Remove All")

        listData.clear(forType: type)
        clearAllUnreadIds(forFeed: type)
        if clearScrollPosition {
            setScrollPosition(model: nil, offset: 0, forFeed: type)
        }

        guard !snapshot.sectionIdentifiers.isEmpty else { return }
        snapshot.deleteAllItems()

        delegate?.didUpdateSnapshot(
            snapshot,
            feedType: type,
            updateType: .removeAll,
            scrollPosition: nil,
            onCompleted: nil
        )
    }

    func clearAllHeights(forType type: NewsFeedTypes) {
        if let current = listData.forType(type: type) {
            let updated = current.compactMap {
                if case let .postCard(postCard) = $0 {
                    postCard.cellHeight = 0
                    return NewsFeedListItem.postCard(postCard)
                }

                return nil
            }
            listData.set(items: updated, forType: type)
        }
    }

    // MARK: - Loader

    func displayLoader(forType type: NewsFeedTypes) {
        // Don't show loader if this feed is not currently viewed
        guard type == self.type else { return }
        delegate?.showLoader(enabled: true)
    }

    func hideLoader(forType type: NewsFeedTypes) {
        // Don't hide loader if this feed is not currently viewed
        guard type == self.type else { return }
        delegate?.showLoader(enabled: false)
    }

    // MARK: - Load more

    func displayLoadMore(after item: NewsFeedListItem, feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard feedType == type else { return }

        if snapshot.indexOfItem(.loadMore) == nil {
            snapshot.appendItems([.loadMore], toSection: .main)
            snapshot.moveItem(.loadMore, afterItem: item)
        } else {
            snapshot.moveItem(.loadMore, afterItem: item)
        }
    }

    func hideLoadMore(feedType _: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard type == type else { return }
        guard let _ = snapshot.indexOfItem(.loadMore) else { return }
        snapshot.deleteItems([.loadMore])
    }

    // MARK: - Error item

    func displayError(feedType: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard feedType == type else { return }
        if snapshot.indexOfSection(.main) == nil {
            snapshot = appendMainSectionToSnapshot(snapshot: snapshot)
        }

        if snapshot.indexOfItem(.error) == nil {
            snapshot.appendItems([.error], toSection: .main)

            delegate?.didUpdateSnapshot(snapshot,
                                        feedType: type,
                                        updateType: .append,
                                        scrollPosition: nil,
                                        onCompleted: nil)
        }
    }

    func hideError(feedType _: NewsFeedTypes) {
        // Don't update data source if this feed is not currently viewed
        guard type == type else { return }

        if snapshot.indexOfSection(.main) == nil {
            snapshot = appendMainSectionToSnapshot(snapshot: snapshot)
        }

        guard let _ = snapshot.indexOfItem(.error) else { return }
        snapshot.deleteItems([.error])

        delegate?.didUpdateSnapshot(snapshot,
                                    feedType: type,
                                    updateType: .append,
                                    scrollPosition: nil,
                                    onCompleted: nil)
    }

    // MARK: - Empty

    func showEmpty(forType type: NewsFeedTypes) {
        guard type == self.type else { return }

        DispatchQueue.main.async {
            guard self.snapshot.indexOfSection(.empty) == nil else { return }

            self.snapshot.appendSections([.empty])
            if self.snapshot.indexOfItem(self.listData.empty) == nil {
                self.snapshot.appendItems([self.listData.empty], toSection: .empty)
            }
            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: type,
                                             updateType: .append,
                                             scrollPosition: nil,
                                             onCompleted: nil)
        }
    }

    func hideEmpty(forType type: NewsFeedTypes) {
        guard type == self.type else { return }
        DispatchQueue.main.async {
            guard let _ = self.snapshot.indexOfSection(.empty) else { return }
            self.snapshot.deleteSections([.empty])
            self.delegate?.didUpdateSnapshot(self.snapshot,
                                             feedType: type,
                                             updateType: .append,
                                             scrollPosition: nil,
                                             onCompleted: nil)
        }
    }

    // MARK: - Index paths

    func getIndexPathForItem(item: NewsFeedListItem) -> IndexPath? {
        return getIndexPathForItem(snapshot: snapshot, item: item)
    }

    func getIndexPathForItem(snapshot: NewsFeedSnapshot, item: NewsFeedListItem) -> IndexPath? {
        // For postcards find item based on uniqueId
        if case let .postCard(postCard) = item {
            guard let _ = snapshot.indexOfSection(.main) else { return nil }
            let index = snapshot.itemIdentifiers(inSection: .main).firstIndex(where: {
                if case let .postCard(currentPostCard) = $0, currentPostCard.uniqueId == postCard.uniqueId {
                    return true
                }
                return false
            })

            if let index, let sectionIndex = self.snapshot.indexOfSection(.main) {
                return IndexPath(row: index, section: sectionIndex)
            }

            return nil

            // Find item based on `indexOfItem`
        } else {
            if let index = snapshot.indexOfItem(item),
               let section = snapshot.sectionIdentifier(containingItem: item),
               let sectionIndex = snapshot.indexOfSection(section)
            {
                return IndexPath(row: index, section: sectionIndex)
            }
        }

        return nil
    }

    func getItemForIndexPath(_ indexPath: IndexPath) -> NewsFeedListItem? {
        return dataSource?.itemIdentifier(for: indexPath)
    }

    // MARK: - Helpers

    func isItemInSnapshot(_ item: NewsFeedListItem) -> Bool {
        return getIndexPathForItem(item: item) != nil
    }

    // First item id in the feed
    func newestItemId(forType _: NewsFeedTypes) -> String? {
        guard let _ = snapshot.indexOfSection(.main) else { return nil }
        if case let .postCard(postCard) = snapshot.itemIdentifiers(inSection: .main).filter({ $0.extractPostCard() != nil }).first {
            return postCard.cursorId
        }

        if case let .activity(activity) = snapshot.itemIdentifiers(inSection: .main).first {
            return activity.cursorId
        }
        return nil
    }

    // Last item id in the feed
    func oldestItemId(forType _: NewsFeedTypes) -> String? {
        guard let _ = snapshot.indexOfSection(.main) else { return nil }

        if cursorId != nil {
            return cursorId
        }

        if case let .postCard(postCard) = snapshot.itemIdentifiers(inSection: .main).last {
            return postCard.cursorId
        }

        if case let .activity(activity) = snapshot.itemIdentifiers(inSection: .main).last {
            return activity.cursorId
        }
        return nil
    }

    // Last item id before the "load more" button
    func lastOfTheNewestItemsId(forType type: NewsFeedTypes) -> String? {
        if let item = lastItemOfTheNewestItems(forType: type) {
            if case let .postCard(postCard) = item {
                return postCard.cursorId
            }

            if case let .activity(activity) = item {
                return activity.cursorId
            }
        }

        return nil
    }

    // Last item before the "load more" button
    func lastItemOfTheNewestItems(forType _: NewsFeedTypes) -> NewsFeedListItem? {
        if let loadMoreIndexPath = getIndexPathForItem(item: .loadMore) {
            let lastItemIndexPath = IndexPath(row: loadMoreIndexPath.row - 1, section: loadMoreIndexPath.section)
            let item = getItemForIndexPath(lastItemIndexPath)
            return item
        }

        return nil
    }

    // First item id after the "load more" button
    func firstOfTheOlderItemsId(forType type: NewsFeedTypes) -> String? {
        if let item = firstOfTheOlderItems(forType: type) {
            if case let .postCard(postCard) = item {
                return postCard.cursorId
            }

            if case let .activity(activity) = item {
                return activity.cursorId
            }
        }

        return nil
    }

    // First item after the "load more" button
    func firstOfTheOlderItems(forType _: NewsFeedTypes) -> NewsFeedListItem? {
        // if there's no "load more" return the top item in the feed
        guard let _ = snapshot.indexOfItem(.loadMore),
              let _ = snapshot.indexOfSection(.main)
        else {
            return snapshot.itemIdentifiers(inSection: .main).first
        }

        if let loadMoreIndexPath = getIndexPathForItem(item: .loadMore) {
            let firstItemIndexPath = IndexPath(row: loadMoreIndexPath.row + 1, section: loadMoreIndexPath.section)
            let item = getItemForIndexPath(firstItemIndexPath)
            return item
        }

        return nil
    }

    // Is the cached scroll position higher than the "load more" button
    func isReadingNewest(forType type: NewsFeedTypes) -> Bool? {
        let scrollPosition = getScrollPosition(forFeed: type)

        // if there's no "load more" button we don't know
        guard let _ = snapshot.indexOfItem(.loadMore) else {
            return nil
        }

        if let visibleItem = scrollPosition.model,
           let scrollPositionIndexPath = getIndexPathForItem(item: visibleItem),
           let lastNewItem = lastItemOfTheNewestItems(forType: type),
           let lastNewItemIndexPath = getIndexPathForItem(item: lastNewItem)
        {
            if lastNewItemIndexPath.row >= scrollPositionIndexPath.row {
                return true
            }
        }

        return false
    }

    func isLoadMoreButtonInView(forType _: NewsFeedTypes) async -> Bool {
        // if there's no "load more" button we don't know
        guard let _ = snapshot.indexOfItem(.loadMore) else {
            return false
        }

        if let visibleIndexPaths = await delegate?.getVisibleIndexPaths() {
            for indexPath in visibleIndexPaths {
                if let item = getItemForIndexPath(indexPath) {
                    if case .loadMore = item {
                        return true
                    }
                }
            }
        }

        return false
    }

    func numberOfItems(forSection section: NewsFeedSections) -> Int {
        if snapshot.indexOfSection(.main) != nil {
            return snapshot.itemIdentifiers(inSection: section).count
        }
        return 0
    }

    func isNewestItemOlderThen(targetDate: Date) -> Bool? {
        if snapshot.indexOfSection(.main) != nil {
            if let firstItem = snapshot.itemIdentifiers(inSection: .main).first {
                switch firstItem {
                case let .postCard(postCard):
                    let postDate = postCard.createdAt
                    return targetDate > postDate
                default:
                    return nil
                }
            }
        }

        return nil
    }

    // MARK: - Prefetching

    func shouldFetchNext(prefetchRowsAt indexPaths: [IndexPath]) -> Bool {
        if !isLoadMoreEnabled {
            return false
        }

        switch state {
        case .loading:
            return false // Dont fetch next items if already loading
        case .error:
            fallthrough
        case .success:
            let highest = indexPaths.reduce(0) {
                if $0 > $1.row {
                    return $0
                } else {
                    return $1.row
                }
            }

            let total = numberOfItems(forSection: .main)

            if highest > total - 13 {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }
}
