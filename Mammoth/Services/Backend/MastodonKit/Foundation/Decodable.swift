//
//  Decodable.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 12/31/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

extension Decodable {
    static func decode(data: Data) throws -> Self {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.mastodonFormatter)
            return try decoder.decode(Self.self, from: data)
        } catch let error as DecodingError {
            switch error {
            case let .dataCorrupted(context):
                log.error("Decoding JSON - corrupted")
                log.error("context: \(context.debugDescription)")
            case let .keyNotFound(key, context):
                log.error("Decoding JSON - key not found: '\(key)'")
                log.error("context: \(context.debugDescription)")
            case let .valueNotFound(value, context):
                log.error("Decoding JSON - value not found: '\(value)'")
                log.error("context: \(context.debugDescription)")
            case let .typeMismatch(type, context):
                log.error("Decoding JSON - type mismatch: '\(type)'")
                log.error("context: \(context.debugDescription)")
            @unknown default:
                log.error("Decoding JSON - unknown error")
            }
            throw error
        } catch {
            log.error("Decoding JSON - error: \(error)")
            throw error
        }
    }
}
