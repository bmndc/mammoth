//
//  NewsFeedViewModel+UnreadCount.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import OrderedCollections

struct NewsFeedUnreadState {
    var count: Int {
        return unreadIDs.count
    }

    var unreadIDs = OrderedSet<String>()
    var enabled: Bool = true
    var unreadPics: [URL] = []
    var showJumpToNow: Bool = false
}

// swiftlint:disable:next type_body_length
struct NewsFeedUnreadStates {
    var forYou = NewsFeedUnreadState()
    var following = NewsFeedUnreadState()
    var federated = NewsFeedUnreadState()
    var community: [String: NewsFeedUnreadState] = [:]
    var trending: [String: NewsFeedUnreadState] = [:]
    var hashtag: [String: NewsFeedUnreadState] = [:]
    var list: [String: NewsFeedUnreadState] = [:]
    var likes = NewsFeedUnreadState()
    var bookmarks = NewsFeedUnreadState()
    var mentionsIn = NewsFeedUnreadState()
    var mentionsOut = NewsFeedUnreadState()
    var activity: [String: NewsFeedUnreadState] = [:]
    var channel: [String: NewsFeedUnreadState] = [:]

    mutating func setEnabled(enabled: Bool, forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.enabled = enabled
        case .following:
            following.enabled = enabled
        case .federated:
            federated.enabled = enabled
        case let .community(name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.enabled = enabled
            community[name] = model
        case let .trending(name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.enabled = enabled
            trending[name] = model
        case let .hashtag(data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.enabled = enabled
            hashtag[data.name] = model
        case let .list(data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.enabled = enabled
            list[data.id] = model
        case .likes:
            likes.enabled = enabled
        case .bookmarks:
            bookmarks.enabled = enabled
        case .mentionsIn:
            mentionsIn.enabled = enabled
        case .mentionsOut:
            mentionsOut.enabled = enabled
        case let .activity(type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.enabled = enabled
            activity[type?.rawValue ?? "all"] = model
        case let .channel(data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.enabled = enabled
            channel[data.id] = model
        }
    }

    mutating func setUnreadPics(urls: [URL], forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.unreadPics = urls
        case .following:
            following.unreadPics = urls
        case .federated:
            federated.unreadPics = urls
        case let .community(name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            community[name] = model
        case let .trending(name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            trending[name] = model
        case let .hashtag(data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            hashtag[data.name] = model
        case let .list(data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            list[data.id] = model
        case .likes:
            likes.unreadPics = urls
        case .bookmarks:
            bookmarks.unreadPics = urls
        case .mentionsIn:
            mentionsIn.unreadPics = urls
        case .mentionsOut:
            mentionsOut.unreadPics = urls
        case let .activity(type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            activity[type?.rawValue ?? "all"] = model
        case let .channel(data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadPics = urls
            channel[data.id] = model
        }
    }

    mutating func setShowJumpToNow(enabled: Bool, forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.showJumpToNow = enabled
        case .following:
            following.showJumpToNow = enabled
        case .federated:
            federated.showJumpToNow = enabled
        case let .community(name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            community[name] = model
        case let .trending(name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            trending[name] = model
        case let .hashtag(data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            hashtag[data.name] = model
        case let .list(data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            list[data.id] = model
        case .likes:
            likes.showJumpToNow = enabled
        case .bookmarks:
            bookmarks.showJumpToNow = enabled
        case .mentionsIn:
            mentionsIn.showJumpToNow = enabled
        case .mentionsOut:
            mentionsOut.showJumpToNow = enabled
        case let .activity(type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            activity[type?.rawValue ?? "all"] = model
        case let .channel(data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.showJumpToNow = enabled
            channel[data.id] = model
        }
    }

    mutating func addUnreadIds(ids: [String], forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.unreadIDs.formUnion(ids)
        case .following:
            following.unreadIDs.formUnion(ids)
        case .federated:
            federated.unreadIDs.formUnion(ids)
        case let .community(name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            community[name] = model
        case let .trending(name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            trending[name] = model
        case let .hashtag(data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            hashtag[data.name] = model
        case let .list(data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            list[data.id] = model
        case .likes:
            likes.unreadIDs.formUnion(ids)
        case .bookmarks:
            bookmarks.unreadIDs.formUnion(ids)
        case .mentionsIn:
            mentionsIn.unreadIDs.formUnion(ids)
        case .mentionsOut:
            mentionsOut.unreadIDs.formUnion(ids)
        case let .activity(type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            activity[type?.rawValue ?? "all"] = model
        case let .channel(data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.formUnion(ids)
            channel[data.id] = model
        }
    }

    mutating func insertUnreadIds(ids: [String], forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.unreadIDs.elements.insert(contentsOf: ids, at: 0)
        case .following:
            following.unreadIDs.elements.insert(contentsOf: ids, at: 0)
        case .federated:
            federated.unreadIDs.elements.insert(contentsOf: ids, at: 0)
        case let .community(name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.unreadIDs.elements.insert(contentsOf: ids, at: 0)
            community[name] = model
        case let .trending(name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.unreadIDs.elements.insert(contentsOf: ids, at: 0)
            trending[name] = model
        case let .hashtag(data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.unreadIDs.elements.insert(contentsOf: ids, at: 0)
            hashtag[data.name] = model
        case let .list(data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.elements.insert(contentsOf: ids, at: 0)
            list[data.id] = model
        case .likes:
            likes.unreadIDs.elements.insert(contentsOf: ids, at: 0)
        case .bookmarks:
            bookmarks.unreadIDs.elements.insert(contentsOf: ids, at: 0)
        case .mentionsIn:
            mentionsIn.unreadIDs.elements.insert(contentsOf: ids, at: 0)
        case .mentionsOut:
            mentionsOut.unreadIDs.elements.insert(contentsOf: ids, at: 0)
        case let .activity(type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.unreadIDs.elements.insert(contentsOf: ids, at: 0)
            activity[type?.rawValue ?? "all"] = model
        case let .channel(data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.elements.insert(contentsOf: ids, at: 0)
            channel[data.id] = model
        }
    }

    mutating func removeUnreadId(id: String, forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            let startIndex = forYou.unreadIDs.firstIndex(of: id)
            if let startIndex {
                forYou.unreadIDs.removeSubrange(startIndex...)
            }
        case .following:
            let startIndex = following.unreadIDs.firstIndex(of: id)
            if let startIndex {
                following.unreadIDs.removeSubrange(startIndex...)
            }
        case .federated:
            let startIndex = federated.unreadIDs.firstIndex(of: id)
            if let startIndex {
                federated.unreadIDs.removeSubrange(startIndex...)
            }
        case let .community(name):
            var model = community[name] ?? NewsFeedUnreadState()
            let startIndex = model.unreadIDs.firstIndex(of: id)
            if let startIndex {
                model.unreadIDs.removeSubrange(startIndex...)
            }
            community[name] = model
        case let .trending(name):
            var model = trending[name] ?? NewsFeedUnreadState()
            let startIndex = model.unreadIDs.firstIndex(of: id)
            if let startIndex {
                model.unreadIDs.removeSubrange(startIndex...)
            }
            trending[name] = model
        case let .hashtag(data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            let startIndex = model.unreadIDs.firstIndex(of: id)
            if let startIndex {
                model.unreadIDs.removeSubrange(startIndex...)
            }
            hashtag[data.name] = model
        case let .list(data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            let startIndex = model.unreadIDs.firstIndex(of: id)
            if let startIndex {
                model.unreadIDs.removeSubrange(startIndex...)
            }
            list[data.id] = model
        case .likes:
            let startIndex = likes.unreadIDs.firstIndex(of: id)
            if let startIndex {
                likes.unreadIDs.removeSubrange(startIndex...)
            }
        case .bookmarks:
            let startIndex = bookmarks.unreadIDs.firstIndex(of: id)
            if let startIndex {
                bookmarks.unreadIDs.removeSubrange(startIndex...)
            }
        case .mentionsIn:
            let startIndex = mentionsIn.unreadIDs.firstIndex(of: id)
            if let startIndex {
                mentionsIn.unreadIDs.removeSubrange(startIndex...)
            }
        case .mentionsOut:
            let startIndex = mentionsOut.unreadIDs.firstIndex(of: id)
            if let startIndex {
                mentionsOut.unreadIDs.removeSubrange(startIndex...)
            }
        case let .activity(type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            let startIndex = model.unreadIDs.firstIndex(of: id)
            if let startIndex {
                model.unreadIDs.removeSubrange(startIndex...)
            }
            activity[type?.rawValue ?? "all"] = model
        case let .channel(data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            let startIndex = model.unreadIDs.firstIndex(of: id)
            if let startIndex {
                model.unreadIDs.removeSubrange(startIndex...)
            }
            channel[data.id] = model
        }
    }

    mutating func clearAllUnreadIds(forFeed type: NewsFeedTypes) {
        switch type {
        case .forYou:
            forYou.unreadIDs.removeAll()
        case .following:
            following.unreadIDs.removeAll()
        case .federated:
            federated.unreadIDs.removeAll()
        case let .community(name):
            var model = community[name] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            community[name] = model
        case let .trending(name):
            var model = trending[name] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            trending[name] = model
        case let .hashtag(data):
            var model = hashtag[data.name] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            hashtag[data.name] = model
        case let .list(data):
            var model = list[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            list[data.id] = model
        case .likes:
            likes.unreadIDs.removeAll()
        case .bookmarks:
            bookmarks.unreadIDs.removeAll()
        case .mentionsIn:
            mentionsIn.unreadIDs.removeAll()
        case .mentionsOut:
            mentionsOut.unreadIDs.removeAll()
        case let .activity(type):
            var model = activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            activity[type?.rawValue ?? "all"] = model
        case let .channel(data):
            var model = channel[data.id] ?? NewsFeedUnreadState()
            model.unreadIDs.removeAll()
            channel[data.id] = model
        }
    }

    func getState(forType type: NewsFeedTypes) -> NewsFeedUnreadState {
        switch type {
        case .forYou:
            return forYou
        case .following:
            return following
        case .federated:
            return federated
        case let .community(name):
            return community[name] ?? NewsFeedUnreadState()
        case let .trending(name):
            return trending[name] ?? NewsFeedUnreadState()
        case let .hashtag(data):
            return hashtag[data.name] ?? NewsFeedUnreadState()
        case let .list(data):
            return list[data.id] ?? NewsFeedUnreadState()
        case .likes:
            return likes
        case .bookmarks:
            return bookmarks
        case .mentionsIn:
            return mentionsIn
        case .mentionsOut:
            return mentionsOut
        case let .activity(type):
            return activity[type?.rawValue ?? "all"] ?? NewsFeedUnreadState()
        case let .channel(data):
            return channel[data.id] ?? NewsFeedUnreadState()
        }
    }
}

// MARK: - Unread count accessors

extension NewsFeedViewModel {
    func setUnreadEnabled(enabled: Bool, forFeed type: NewsFeedTypes) {
        unreadCounts.setEnabled(enabled: enabled, forFeed: type)
    }

    func setUnreadPics(urls: [URL], forFeed type: NewsFeedTypes) {
        unreadCounts.setUnreadPics(urls: urls, forFeed: type)
    }

    func addUnreadIds(ids: [String], forFeed type: NewsFeedTypes) {
        unreadCounts.addUnreadIds(ids: ids, forFeed: type)
    }

    func insertUnreadIds(ids: [String], forFeed type: NewsFeedTypes) {
        unreadCounts.insertUnreadIds(ids: ids, forFeed: type)
    }

    func removeUnreadId(id: String, forFeed type: NewsFeedTypes) {
        unreadCounts.removeUnreadId(id: id, forFeed: type)
    }

    func clearAllUnreadIds(forFeed type: NewsFeedTypes) {
        unreadCounts.clearAllUnreadIds(forFeed: type)
    }

    func getUnreadCount(forFeed type: NewsFeedTypes) -> Int {
        return unreadCounts.getState(forType: type).unreadIDs.count
    }

    func getUnreadEnabled(forFeed type: NewsFeedTypes) -> Bool {
        return unreadCounts.getState(forType: type).enabled
    }

    func getUnreadPics(forFeed type: NewsFeedTypes) -> [URL] {
        return unreadCounts.getState(forType: type).unreadPics
    }

    func getUnreadState(forFeed type: NewsFeedTypes) -> NewsFeedUnreadState {
        return unreadCounts.getState(forType: type)
    }

    func setShowJumpToNow(enabled: Bool, forFeed type: NewsFeedTypes) {
        unreadCounts.setShowJumpToNow(enabled: enabled, forFeed: type)
    }

    func getShowJumpToNow(forFeed type: NewsFeedTypes) -> Bool {
        return unreadCounts.getState(forType: type).showJumpToNow
    }
}
