//
//  HashType.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 14/10/2018.
//  Copyright © 2018 Shihab Mehboob. All rights reserved.
//

import Foundation
import MastodonMeta
import Meta

public class HashType: Codable {
    public let name: String
    public var metaName: MastodonMetaContent?
    public let value: String
    public var metaValue: MastodonMetaContent?
    public let verifiedAt: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case value
        case verifiedAt = "verified_at"
    }
}

public extension HashType {
    func configureMetaContent(with emojis: MastodonContent.Emojis) {
        do {
            metaValue = try MastodonMetaContent.convert(document: MastodonContent(content: value, emojis: emojis))
        } catch {
            metaValue = MastodonMetaContent.convert(text: MastodonContent(content: value, emojis: emojis))
        }

        do {
            metaName = try MastodonMetaContent.convert(document: MastodonContent(content: name, emojis: emojis))
        } catch {
            metaName = MastodonMetaContent.convert(text: MastodonContent(content: name, emojis: emojis))
        }
    }
}

extension HashType: Equatable {
    public static func == (lhs: HashType, rhs: HashType) -> Bool {
        return lhs.name == rhs.name &&
            lhs.value == rhs.value &&
            lhs.verifiedAt == rhs.verifiedAt
    }
}
