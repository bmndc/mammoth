//
//  HTTPMethod.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/28/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

enum HTTPMethod {
    case get(Payload)
    case post(Payload)
    case put(Payload)
    case patch(Payload)
    case delete(Payload)
}

extension HTTPMethod {
    var name: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        case .delete: return "DELETE"
        case .patch: return "PATCH"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case let .get(payload): return payload.items
        default: return nil
        }
    }

    var httpBody: Data? {
        switch self {
        case let .post(payload): return payload.data
        case let .put(payload): return payload.data
        case let .patch(payload): return payload.data
        case let .delete(payload): return payload.data
        default: return nil
        }
    }

    var contentType: String? {
        switch self {
        case let .post(payload): return payload.type
        case let .put(payload): return payload.type
        case let .patch(payload): return payload.type
        case let .delete(payload): return payload.type
        default: return nil
        }
    }
}
