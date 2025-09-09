//
//  NewsFeedListItem.swift
//  Mammoth
//
//  Created by Benoit Nolens on 05/07/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

enum NewsFeedListItem: Hashable {
    case postCard(PostCardModel)
    case activity(ActivityCardModel)
    case empty
    case loadMore
    case error

    func uniqueId() -> String {
        switch self {
        case let .postCard(postCard):
            return postCard.uniqueId ?? "postCard"
        case let .activity(activityCard):
            return activityCard.uniqueId
        case .empty:
            return "empty"
        case .loadMore:
            return "loadMore"
        case .error:
            return "error"
        }
    }
}

extension NewsFeedListItem {
    func extractPostCard() -> PostCardModel? {
        if case let .postCard(postCard) = self { return postCard }
        if case let .activity(activity) = self { return activity.postCard }
        return nil
    }

    func extractData() -> Any? {
        if case let .postCard(postCard) = self {
            let data = postCard.data
            if case let .mastodon(status) = data {
                return status
            }
        }
        if case let .activity(activityCard) = self { return activityCard.notification }
        return nil
    }

    func extractUniqueId() -> String? {
        if case let .postCard(postCard) = self { return postCard.uniqueId }
        if case let .activity(activity) = self { return activity.uniqueId }
        return nil
    }
}

extension NewsFeedListItem {
    func deepEqual(with item: NewsFeedListItem) -> Bool {
        if case let .postCard(lhs) = self, case let .postCard(rhs) = item {
            return lhs.uniqueId == rhs.uniqueId &&
                lhs.username == rhs.username &&
                lhs.containsPoll == rhs.containsPoll &&
                lhs.hasLink == rhs.hasLink &&
                lhs.hasMediaAttachment == rhs.hasMediaAttachment &&
                lhs.mediaAttachments.count == rhs.mediaAttachments.count &&
                lhs.hasQuotePost == rhs.hasQuotePost &&
                lhs.isAReply == rhs.isAReply &&
                lhs.postText == rhs.postText &&
                lhs.profileURL == rhs.profileURL &&
                lhs.userTag == rhs.userTag &&
                lhs.user?.followStatus == rhs.user?.followStatus &&
                lhs.likeCount == rhs.likeCount &&
                lhs.replyCount == rhs.replyCount &&
                lhs.repostCount == rhs.repostCount
        }
        if case let .activity(lhs) = self, case let .activity(rhs) = item {
            return lhs.uniqueId == rhs.uniqueId
        }
        return true
    }
}

func toListCardItems(_ cards: [PostCardModel]?) -> [NewsFeedListItem] {
    return cards?.map { .postCard($0) } ?? []
}

func extractListData(_ items: [NewsFeedListItem]?) -> [Any]? {
    guard let items, items.count > 0 else { return nil }
    return items.compactMap { $0.extractData() }
}

func toPostCards(_ items: [NewsFeedListItem]?) -> [PostCardModel]? {
    return items?.compactMap { $0.extractPostCard() }
}

extension Array where Element == NewsFeedListItem {
    func removeMutesAndBlocks() -> [Element] {
        let blockedIds = ModerationManager.shared.blockedUsers.map { $0.remoteFullOriginalAcct }
        let mutedIds = ModerationManager.shared.mutedUsers.map { $0.remoteFullOriginalAcct }
        return filter {
            if case let .postCard(postCard) = $0 {
                let isBlocked = blockedIds.contains(where: {
                    postCard.user?.uniqueId as? String == $0
                })

                let isMuted = mutedIds.contains(where: {
                    postCard.user?.uniqueId as? String == $0
                })
                return !isBlocked && !isMuted
            } else if case let .activity(activity) = $0 {
                let isBlocked = blockedIds.contains(where: {
                    activity.user.uniqueId == $0
                })

                let isMuted = mutedIds.contains(where: {
                    activity.user.uniqueId == $0
                })
                return !isBlocked && !isMuted
            }
            return false
        }
    }

    func removeFiltered() -> [Element] {
        return filter {
            if case let .postCard(postCard) = $0 {
                if case .hide = postCard.filterType {
                    return false
                }
            }

            return true
        }
    }
}

extension Array where Element == PostCardModel {
    func removeFiltered() -> [Element] {
        return filter {
            if case .hide = $0.filterType {
                return false
            }

            return true
        }
    }
}
