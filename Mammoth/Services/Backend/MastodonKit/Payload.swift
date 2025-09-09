//
//  Payload.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/28/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

enum Payload {
    case parameters([Parameter]?)
    case other([Parameter]?)
    case media(MediaAttachment?)
    case empty
}

extension Payload {
    var items: [URLQueryItem]? {
        switch self {
        case let .parameters(parameters): return parameters?.compactMap(toQueryItem)
        case let .other(parameters): return parameters?.compactMap(toQueryItem)
        case .media: return nil
        case .empty: return nil
        }
    }

    var data: Data? {
        switch self {
        case let .parameters(parameters):
            return parameters?
                .compactMap(toString)
                .joined(separator: "&")
                .data(using: .utf8)
        case let .other(parameters):
            return parameters?
                .compactMap(toString)
                .joined(separator: "&")
                .data(using: .utf8)
        case let .media(mediaAttachment): return mediaAttachment.flatMap(Data.init)
        case .empty: return nil
        }
    }

    var type: String? {
        switch self {
        case let .parameters(parameters):
            return parameters.map { _ in "application/x-www-form-urlencoded; charset=utf-8" }
        case let .other(parameters):
            return parameters.map { _ in "multipart/form-data; boundary=MastodonKitBoundary" }
        case let .media(mediaAttachment):
            return mediaAttachment.map { _ in "multipart/form-data; boundary=MastodonKitBoundary" }
        case .empty: return nil
        }
    }
}
