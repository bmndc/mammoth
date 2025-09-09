//
//  NewsFeedViewModel+ScrollPositions.swift
//  Mammoth
//
//  Created by Benoit Nolens on 29/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

struct NewsFeedScrollPosition {
    var model: NewsFeedListItem?
    var offset: Double = 0

    init() {}
    init(model: NewsFeedListItem?, offset: Double) {
        self.model = model
        self.offset = offset
    }
}

// Positions are cached on disk
extension NewsFeedScrollPosition: Codable {
    enum CodingKeys: String, CodingKey { case model, offset }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let data = try values.decode(Status.self, forKey: .model)
            let postCard = PostCardModel(status: data)
            model = .postCard(postCard)
        } catch {
            do {
                let data = try values.decode(Notificationt.self, forKey: .model)
                let activity = ActivityCardModel(notification: data)
                model = .activity(activity)
            } catch {}
        }
        offset = try values.decode(Double.self, forKey: .offset)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if case let .postCard(postCard) = model {
            if case let .mastodon(status) = postCard.data {
                try container.encode(status, forKey: .model)
            }
        }
        if case let .activity(activity) = model {
            try container.encode(activity.notification, forKey: .model)
        }
        try container.encode(offset, forKey: .offset)
    }
}

struct NewsFeedScrollPositions {
    var forYou: NewsFeedScrollPosition = .init()
    var following: NewsFeedScrollPosition = .init()
    var federated: NewsFeedScrollPosition = .init()
    var community: [String: NewsFeedScrollPosition] = [:]
    var trending: [String: NewsFeedScrollPosition] = [:]
    var hashtag: [String: NewsFeedScrollPosition] = [:]
    var list: [String: NewsFeedScrollPosition] = [:]
    var likes: NewsFeedScrollPosition = .init()
    var bookmarks: NewsFeedScrollPosition = .init()
    var mentionsIn: NewsFeedScrollPosition = .init()
    var mentionsOut: NewsFeedScrollPosition = .init()
    var activity: [String: NewsFeedScrollPosition] = [:]
    var channel: [String: NewsFeedScrollPosition] = [:]

    @discardableResult
    fileprivate mutating func setPosition(model: NewsFeedListItem?, offset: Double, forFeed type: NewsFeedTypes) -> NewsFeedScrollPosition {
        let position = NewsFeedScrollPosition(model: model, offset: offset)
        switch type {
        case .forYou:
            forYou = position
        case .following:
            following = position
        case .federated:
            federated = position
        case let .community(name):
            community[name] = position
        case let .trending(name):
            trending[name] = position
        case let .hashtag(tag):
            hashtag[tag.name] = position
        case let .list(data):
            list[data.id] = position
        case .likes:
            likes = NewsFeedScrollPosition()
        case .bookmarks:
            bookmarks = NewsFeedScrollPosition()
        case .mentionsIn:
            mentionsIn = position
        case .mentionsOut:
            mentionsOut = position
        case let .activity(type):
            activity[type?.rawValue ?? "all"] = position
        case let .channel(data):
            channel[data.id] = position
        }

        return position
    }

    fileprivate func getPosition(forType type: NewsFeedTypes) -> NewsFeedScrollPosition {
        switch type {
        case .forYou:
            return forYou
        case .following:
            return following
        case .federated:
            return federated
        case let .community(name):
            return community[name] ?? NewsFeedScrollPosition()
        case let .trending(name):
            return trending[name] ?? NewsFeedScrollPosition()
        case let .hashtag(tag):
            return hashtag[tag.name] ?? NewsFeedScrollPosition()
        case let .list(data):
            return list[data.id] ?? NewsFeedScrollPosition()
        case .likes:
            return likes
        case .bookmarks:
            return bookmarks
        case .mentionsIn:
            return mentionsIn
        case .mentionsOut:
            return mentionsOut
        case let .activity(type):
            return activity[type?.rawValue ?? "all"] ?? NewsFeedScrollPosition()
        case let .channel(data):
            return channel[data.id] ?? NewsFeedScrollPosition()
        }
    }
}

// MARK: - Scroll position accessors

extension NewsFeedViewModel {
    @discardableResult
    func setScrollPosition(model: NewsFeedListItem?, offset: Double, forFeed type: NewsFeedTypes) -> NewsFeedScrollPosition {
        let position = scrollPositions.setPosition(model: model, offset: offset, forFeed: type)

        let items = listData.forType(type: type)
        saveToDisk(items: items, position: position, feedType: type)

        return position
    }

    func getScrollPosition(forFeed type: NewsFeedTypes) -> NewsFeedScrollPosition {
        return scrollPositions.getPosition(forType: type)
    }
}
