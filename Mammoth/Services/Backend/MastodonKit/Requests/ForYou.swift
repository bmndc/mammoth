//
//  ForYou.swift
//  Mammoth
//
//  Created by Riley Howard on 8/9/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

enum ForYouAccountType: String, Decodable, Encodable {
    case personal // is enrolled in 2.0 personalization
    case `public` // original public for you feed (OG)
    case waitlist // user was public, but on the waitlist for personal
}

public struct ForYouAccount: Decodable, Encodable {
    var forYou: ForYouType
    var subscribedChannels: [Channel]
    private enum CodingKeys: String, CodingKey {
        case forYou = "for_you_settings"
        case subscribedChannels = "subscribed_channels"
    }
}

extension ForYouAccount {
    init() {
        forYou = ForYouType()
        subscribedChannels = []
    }
}

extension ForYouAccount: Equatable {
    public static func == (lhs: ForYouAccount, rhs: ForYouAccount) -> Bool {
        return lhs.forYou == rhs.forYou &&
            lhs.subscribedChannels == rhs.subscribedChannels
    }
}

// For you values are 0-3
// 0-off. 1,2,3 translates to low, med, high respectively
public struct ForYouType: Decodable, Encodable {
    var type: ForYouAccountType
    var yourFollows: Int // 0 off; anything else is on
    var friendsOfFriends: Int
    var fromYourChannels: Int
    var curatedByMammoth: Int
    var enabledChannelIDs: [String]
    private enum CodingKeys: String, CodingKey {
        case type
        case yourFollows = "your_follows"
        case friendsOfFriends = "friends_of_friends"
        case fromYourChannels = "from_your_channels"
        case curatedByMammoth = "curated_by_mammoth"
        case enabledChannelIDs = "enabled_channels"
    }
}

extension ForYouType {
    init() {
        type = .public
        yourFollows = 1
        friendsOfFriends = 1
        fromYourChannels = 1
        curatedByMammoth = 1
        enabledChannelIDs = []
    }
}

extension ForYouType: Equatable {
    public static func == (lhs: ForYouType, rhs: ForYouType) -> Bool {
        return lhs.type == rhs.type &&
            lhs.yourFollows == rhs.yourFollows &&
            lhs.friendsOfFriends == rhs.friendsOfFriends &&
            lhs.fromYourChannels == rhs.fromYourChannels &&
            lhs.curatedByMammoth == rhs.curatedByMammoth &&
            lhs.enabledChannelIDs == rhs.enabledChannelIDs
    }
}

public extension Timelines {
    /// Retrieves the For You curated timeline.
    ///
    /// - Parameters:
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
    static func forYou(range: RequestRange = .default) -> Request<[Status]> {
        var rangeParameters: [Parameter]
        if case let .limit(limit) = range {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: limit)) ?? []
        } else if case let .min(_, limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else if case let .max(_, limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else {
            rangeParameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        }

        let method = HTTPMethod.get(.parameters(rangeParameters))

        return Request<[Status]>(path: "/api/v2/timelines/for_you", method: method)
    }

    /// Retrieves the For You v4 curated timeline.
    ///
    /// - Parameters:
    ///   - remoteFullOriginalAcct: full user handle 'jtomchak@infosec.social'  local Moth.social accounts can just be 'jtomchak'
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
    static func forYouV4(remoteFullOriginalAcct: String, range: RequestRange = .default) -> Request<[Status]> {
        var parameters = [
            Parameter(name: "acct", value: remoteFullOriginalAcct),
            Parameter(name: "beta", value: "true"), // adds acct to enrollment list
        ]

        var rangeParameters: [Parameter]
        if case let .limit(limit) = range {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: limit)) ?? []
        } else if case let .min(_, limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else if case let .max(_, limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else {
            rangeParameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        }

        parameters += rangeParameters
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<[Status]>(path: "/api/v4/timelines/for_you", method: method)
    }

    /// Retrieves the For You (Mammoth Picks) curated timeline.
    /// For after Mammoth sunsets recommendations based For You
    ///
    /// - Parameters:
    ///   - range: The bounds used when requesting data from Mastodon.
    /// - Returns: Request for `[Status]`.
    static func forYouMammothPicks(range: RequestRange = .default) -> Request<[Status]> {
        var rangeParameters: [Parameter]
        if case let .limit(limit) = range {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: limit)) ?? []
        } else if case let .min(_, limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else if case let .max(_, limit) = range, let limit {
            rangeParameters = range.parameters(limit: between(1, and: limit, default: 20)) ?? []
        } else {
            rangeParameters = range.parameters(limit: between(1, and: 40, default: 20)) ?? []
        }
        let method = HTTPMethod.get(.parameters(rangeParameters))

        return Request<[Status]>(path: "/", method: method)
    }

    /// Retrieves the For You meta data.
    ///
    /// - Parameters:
    ///   - remoteFullOriginalAcct: full user handle 'jtomchak@infosec.social'
    /// - Returns: Request for `ForYouAccount`.
    static func forYouMe(remoteFullOriginalAcct: String) -> Request<ForYouAccount> {
        let parameters = [
            Parameter(name: "acct", value: remoteFullOriginalAcct),
        ]
        let method = HTTPMethod.get(.parameters(parameters))

        return Request<ForYouAccount>(path: "/api/v4/timelines/for_you/me", method: method)
    }

    /// Sets the For You meta data.
    ///
    /// - Parameters:
    ///   - remoteFullOriginalAcct: full user handle 'jtomchak@infosec.social'
    /// - Returns: Request for `ForYouAccount`.
    static func updateForYouMe(remoteFullOriginalAcct: String, forYouInfo: ForYouType) -> Request<ForYouAccount> {
        var parameters = [
            Parameter(name: "acct", value: remoteFullOriginalAcct),
            Parameter(name: "friends_of_friends", value: String(forYouInfo.friendsOfFriends)),
            Parameter(name: "from_your_channels", value: String(forYouInfo.fromYourChannels)),
            Parameter(name: "curated_by_mammoth", value: String(forYouInfo.curatedByMammoth)),
            Parameter(name: "your_follows", value: String(forYouInfo.yourFollows)),
            Parameter(name: "ur_follows", value: String(forYouInfo.yourFollows)),
        ]
        // Append enabled channels
        if forYouInfo.enabledChannelIDs.count == 0 {
            parameters.append(Parameter(name: "enabled_channels[]", value: "false"))
        } else {
            for channelID in forYouInfo.enabledChannelIDs {
                parameters.append(Parameter(name: "enabled_channels[]", value: channelID))
            }
        }
        let method = HTTPMethod.put(.parameters(parameters))
        return Request<ForYouAccount>(path: "/api/v4/timelines/for_you/me", method: method)
    }

    /// Retrieves the origin info for the For You statius.
    ///
    /// - Parameters:
    ///   - id: post ID
    /// - Returns: Request for `StatusSource`.
    static func forYouStatusSource(id: String) -> Request<[StatusSource]> {
        return Request<[StatusSource]>(path: "/api/v4/timelines/for_you/statuses/\(id)")
    }
}
