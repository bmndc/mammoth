//
//  InstanceCardModel.swift
//  Mammoth
//
//  Created by Riley Howard on 9/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SDWebImage

struct InstanceCardModel {
    let name: String
    let numberOfUsers: String?
    let languages: [String]?
    let description: String?
    let categories: [String]?
    let imageURL: String?
    var isPinned: Bool

    init(instance: tagInstance) {
        name = instance.name
        numberOfUsers = instance.users
        languages = instance.info?.languages
        description = instance.info?.shortDescription
        categories = instance.info?.categories
        imageURL = instance.thumbnail
        isPinned = InstanceManager.shared.pinnedStatusForInstance(instance.name) == .pinned
    }

    mutating func setPinnedStatus(_ pinned: Bool) {
        isPinned = pinned
    }
}

// MARK: - Preload

extension InstanceCardModel {
    static func preload(instanceCards: [InstanceCardModel]) {
        PostCardModel.imageDecodeQueue.async {
            for instanceCard in instanceCards {
                instanceCard.preloadImages()
            }
        }
    }

    func preloadImages() {
        if let imageURLString = imageURL,
           !SDImageCache.shared.diskImageDataExists(withKey: imageURLString),
           let imageURL = URL(string: imageURLString)
        {
            let prefetcher = SDWebImagePrefetcher.shared
            prefetcher.prefetchURLs([imageURL], context: [.imageTransformer: PostCardProfilePic.transformer], progress: nil)
        }
    }
}
