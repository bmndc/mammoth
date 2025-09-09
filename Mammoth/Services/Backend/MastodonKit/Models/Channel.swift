//
//  Channel.swift
//  Mammoth
//
//  Created by Riley Howard on 8/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public class Channel: Codable {
    /// The channel ID
    public let id: String
    /// The channel title
    public let title: String
    /// General info about the channel
    public let description: String
    /// Channel icon (unicode character for FontAwesome)
    public let icon: String?
    /// Channel owner / maintainer
    public let owner: ChannelOwner?

    init() {
        id = ""
        title = ""
        description = ""
        icon = nil
        owner = ChannelOwner(username: "", domain: "", acct: "", displayName: "")
    }

    init(id: String, title: String, description: String = "", icon: String? = nil, owner: ChannelOwner? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.owner = owner
    }
}

extension Channel: Equatable {
    public static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Channel: CustomDebugStringConvertible {
    public var debugDescription: String {
        title
    }
}
