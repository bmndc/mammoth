//
//  Category.swift
//  Mammoth
//
//  Created by Riley Howard on 1/20/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public enum Content {
    case account(Account)
    case hashtag(Hashtag)
}

extension Content: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleContainer = try decoder.singleValueContainer()

        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "account":
            let account = try singleContainer.decode(Account.self)
            self = .account(account)
        case "hashtag":
            let hashtag = try singleContainer.decode(Hashtag.self)
            self = .hashtag(hashtag)
        default:
            fatalError("Unknown type of content.")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var singleContainer = encoder.singleValueContainer()

        switch self {
        case let .account(account):
            try singleContainer.encode(account)
        case let .hashtag(hashtag):
            try singleContainer.encode(hashtag)
        }
    }
}

extension Content: Equatable {
    public static func == (lhs: Content, rhs: Content) -> Bool {
        switch lhs {
        case let .account(lhsAccount):
            switch rhs {
            case let .account(rhsAccount):
                return lhsAccount == rhsAccount
            case .hashtag:
                return false
            }
        case let .hashtag(lhsHashtag):
            switch rhs {
            case .account:
                return false
            case let .hashtag(rhsHashtag):
                return lhsHashtag == rhsHashtag
            }
        }
    }
}

public class Category: Codable, Hashable {
    /// The name of the category
    public let name: String
    /// The accounts associated with the category
    public let items: [Content]

    private enum CodingKeys: String, CodingKey {
        case name
        case items
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public init(name: String,
                items: [Content])
    {
        self.name = name
        self.items = items
    }
}

extension Category: Equatable {
    public static func == (lhs: Category, rhs: Category) -> Bool {
        let areEqual = lhs.name == rhs.name
        return areEqual
    }
}
