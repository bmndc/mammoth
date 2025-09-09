//
//  StatusCache.swift
//  Mammoth
//
//  Created by Riley Howard on 4/21/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class StatusCache {
    static let shared = StatusCache()
    static var cachedStatusesLock = NSLock()
    static var cachedStatuses: [URL: Status] = [:]
    static var nilValuesURLsLock = NSLock()
    static var nilValueURLs: [URL] = []

    enum MetricType {
        case like
        case repost
        case bookmark
    }

    typealias AccountId = String
    typealias StatusId = String

    // Used to serialze the storage
    let storageQueue = DispatchQueue(label: "Store StatusCache", qos: .utility)

    var localLikes: [AccountId: [StatusId: Bool]] = [:] {
        didSet {
            let localLikesToStore = localLikes
            storageQueue.async {
                UserDefaults.standard.set(localLikesToStore, forKey: "localLikes")
            }
        }
    }

    var localReposts: [AccountId: [StatusId: Bool]] = [:] {
        didSet {
            let localRepostsToStore = localReposts
            storageQueue.async {
                UserDefaults.standard.set(localRepostsToStore, forKey: "localReposts")
            }
        }
    }

    var localBookmarks: [AccountId: [StatusId: Bool]] = [:] {
        didSet {
            let localBookmarksToStore = localBookmarks
            storageQueue.async {
                UserDefaults.standard.set(localBookmarksToStore, forKey: "localBookmarks")
            }
        }
    }

    init() {
        localLikes = UserDefaults.standard.value(forKey: "localLikes") as? [AccountId: [StatusId: Bool]] ?? [:]
        localReposts = UserDefaults.standard.value(forKey: "localReposts") as? [AccountId: [StatusId: Bool]] ?? [:]
        localBookmarks = UserDefaults.standard.value(forKey: "localBookmarks") as? [AccountId: [StatusId: Bool]] ?? [:]

        if let userId = AccountsManager.shared.currentUser()?.fullAcct {
            GlobalStruct.allLikes = localLikes[userId]?.keys as? [String] ?? []
            GlobalStruct.allReposts = localReposts[userId]?.keys as? [String] ?? []
            GlobalStruct.allBookmarks = localBookmarks[userId]?.keys as? [String] ?? []
        }
    }

    func clearCache() {
        StatusCache.cachedStatusesLock.lock()
        StatusCache.cachedStatuses.removeAll()
        StatusCache.cachedStatusesLock.unlock()

        StatusCache.nilValuesURLsLock.lock()
        StatusCache.nilValueURLs.removeAll()
        StatusCache.nilValuesURLsLock.unlock()

        localLikes = [:]
        localReposts = [:]
        localBookmarks = [:]

        GlobalStruct.allLikes = []
        GlobalStruct.allReposts = []
        GlobalStruct.allBookmarks = []
    }

    func cachedStatusForURL(url: URL) -> Status? {
        // Return immedidately if we've cached this
        StatusCache.cachedStatusesLock.lock()
        let cachedStatus = StatusCache.cachedStatuses[url]
        StatusCache.cachedStatusesLock.unlock()
        if cachedStatus != nil {
            return cachedStatus
        } else {
            StatusCache.nilValuesURLsLock.lock()
            let isNil = StatusCache.nilValueURLs.contains(url)
            StatusCache.nilValuesURLsLock.unlock()
            if isNil {
                return nil
            }
        }

        return nil
    }

    // May return immediately, or send a network request
    func cacheStatusForURL(url: URL, completion: @escaping (_ url: URL, _ stat: Status?) -> Void) {
        // Return immedidately if we've cached this
        StatusCache.cachedStatusesLock.lock()
        let cachedStatus = StatusCache.cachedStatuses[url]
        StatusCache.cachedStatusesLock.unlock()

        if cachedStatus != nil {
            // log.debug("+++ cache hit for \(url)")
            completion(url, cachedStatus)
            return
        }

        StatusCache.nilValuesURLsLock.lock()
        let isNil = StatusCache.nilValueURLs.contains(url)
        StatusCache.nilValuesURLsLock.unlock()
        if isNil {
            // this URL previously returned nil; do it again
            completion(url, nil)
            return
        } else {
            // Make the network request, then the callback
            let request = Search.searchOne(query: url.absoluteString, resolve: true)
            Task {
                do {
                    let result = try await ClientService.runRequest(request: request)
                    if let stat = result.statuses.first {
                        await MainActor.run {
                            StatusCache.cachedStatusesLock.lock()
                            StatusCache.cachedStatuses[url] = stat
                            StatusCache.cachedStatusesLock.unlock()
                        }
                        completion(url, stat)
                    } else {
                        log.error("couldn't find quote post.")
                        completion(url, nil)
                    }
                } catch {
                    log.error("couldn't find quote post.")
                    completion(url, nil)
                }
            }
        }
    }

    func addLocalMetric(metricType: MetricType, statusId: String?) {
        if let userId = AccountsManager.shared.currentUser()?.fullAcct, let statusId = statusId {
            switch metricType {
            case .like:
                if localLikes[userId] == nil {
                    localLikes[userId] = [:]
                }

                localLikes[userId]?[statusId] = true
                GlobalStruct.allLikes.append(statusId)
                GlobalStruct.idsToUnlike = GlobalStruct.idsToUnlike.filter { $0 != statusId }
            case .repost:
                if localReposts[userId] == nil {
                    localReposts[userId] = [:]
                }

                localReposts[userId]?[statusId] = true
                GlobalStruct.allReposts.append(statusId)
            case .bookmark:
                if localBookmarks[userId] == nil {
                    localBookmarks[userId] = [:]
                }

                localBookmarks[userId]?[statusId] = true
                GlobalStruct.allBookmarks.append(statusId)
            }
        }
    }

    func removeLocalMetric(metricType: MetricType, statusId: String?) {
        if let userId = AccountsManager.shared.currentUser()?.fullAcct, let statusId = statusId {
            switch metricType {
            case .like:
                localLikes[userId]?[statusId] = false
                GlobalStruct.allLikes = GlobalStruct.allLikes.filter { $0 != statusId }
                GlobalStruct.idsToUnlike.append(statusId)
                UserDefaults.standard.set(GlobalStruct.idsToUnlike, forKey: "idsToUnlike")
                NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadUnlike"), object: nil)
            case .repost:
                localReposts[userId]?[statusId] = false
                GlobalStruct.allReposts = GlobalStruct.allReposts.filter { $0 != statusId }
            case .bookmark:
                localBookmarks[userId]?[statusId] = false
                GlobalStruct.allBookmarks = GlobalStruct.allBookmarks.filter { $0 != statusId }
                GlobalStruct.idsToUnbookmark.append(statusId)
            }
        }
    }

    func removeLocalMetrics(metricType: MetricType, statusIds: [String]) {
        for id in statusIds {
            removeLocalMetric(metricType: metricType, statusId: id)
        }
    }

    func hasLocalMetric(metricType: MetricType, forStatusId statusId: String?) -> Bool? {
        guard let statusId = statusId, !statusId.isEmpty else { return false }

        if let userId = AccountsManager.shared.currentUser()?.fullAcct {
            switch metricType {
            case .like:
                return localLikes[userId]?[statusId]
            case .repost:
                return localReposts[userId]?[statusId]
            case .bookmark:
                return localBookmarks[userId]?[statusId]
            }
        }

        return false
    }
}
