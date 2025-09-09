//
//  ModerationManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 09/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

public let didChangeModerationNotification = Notification.Name("didChangeModerationNotification")

/// This manager keeps a local list of blocked users and muted users.
/// We use this to filter content out of the ForYou and Channels timelines.

class ModerationManager {
    static let shared = ModerationManager()

    private typealias ModerationLists = (mutes: [Account], blocks: [Account])

    private(set) var mutedUsers: [Account] = []
    private(set) var blockedUsers: [Account] = []
    private var temporaryMutes: [TemporaryMute] = []
    private var timer: Timer?

    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }

    // MARK: - Action handlers

    @objc private func willSwitchAccount() {
        temporaryMutes = []
        mutedUsers = []
        blockedUsers = []
    }

    @objc private func didSwitchAccount() {
        Task {
            do {
                if let tempMutes = self.loadTemporaryMutes() {
                    await MainActor.run {
                        self.temporaryMutes = tempMutes
                        self.clearExpiredMutes()
                    }
                }

                if let (mutes, blocks) = try self.loadLocalLists() {
                    await MainActor.run {
                        self.mutedUsers = mutes
                        self.blockedUsers = blocks
                    }
                }
            } catch {
                try await self.fetchLists()
            }
        }
    }

    /// Remove temporary mutes from list when expired
    @objc private func onTimer() {
        clearExpiredMutes()
    }

    // MARK: - Remote fetching

    private func loadRemoteLists(range: RequestRange = .default) async throws -> ModerationLists {
        var mutedUsers: [Account] = []
        var blockedUsers: [Account] = []
        var nextMutedRange: RequestRange? = range
        var nextBlocksRange: RequestRange? = range
        var hasMoreMutes = true
        var hasMoreBlocks = true
        let maxPagesToLoad = 5
        var pagesLoaded = 0

        while hasMoreMutes && pagesLoaded < maxPagesToLoad && !NetworkMonitor.shared.isNearRateLimit {
            let (accounts, pagination) = try await AccountService.mutes(range: nextMutedRange ?? .default)
            nextMutedRange = pagination?.next
            if !accounts.isEmpty {
                mutedUsers.append(contentsOf: accounts)
            }

            if accounts.isEmpty || nextMutedRange == nil {
                hasMoreMutes = false
                break
            }

            pagesLoaded += 1
        }

        pagesLoaded = 0
        while hasMoreBlocks && pagesLoaded < maxPagesToLoad && !NetworkMonitor.shared.isNearRateLimit {
            let (accounts, pagination) = try await AccountService.blocks(range: nextBlocksRange ?? .default)
            nextBlocksRange = pagination?.next

            if !accounts.isEmpty {
                blockedUsers.append(contentsOf: accounts)
            }

            if accounts.isEmpty || nextBlocksRange == nil {
                hasMoreBlocks = false
                break
            }

            pagesLoaded += 1
        }

        return (mutedUsers, blockedUsers)
    }

    // MARK: - Caching

    private func cacheLists(lists: ModerationLists) {
        cacheList(lists.mutes, path: "mutes.json")
        cacheList(lists.blocks, path: "blocks.json")
    }

    private func cacheList(_ list: [Account], path: String) {
        if let user = AccountsManager.shared.currentAccount as? MastodonAcctData {
            do {
                let path = "\(user.diskFolderName())/\(path)"
                try Disk.save(list, to: .caches, as: path)
            } catch {
                log.error("unable to cache \(path) on device: \(error)")
            }
        }
    }

    private func cacheTemporaryMutes(_ list: [TemporaryMute]) {
        if let user = AccountsManager.shared.currentAccount as? MastodonAcctData {
            do {
                let path = "\(user.diskFolderName())/tempMutes.json"
                try Disk.save(list, to: .caches, as: path)
            } catch {
                log.error("unable to cache temporary mutes on device: \(error)")
            }
        }
    }

    private func loadLocalLists() throws -> ModerationLists? {
        do {
            if let user = AccountsManager.shared.currentAccount as? MastodonAcctData {
                let mutesPath = "\(user.diskFolderName())/mutes.json"
                let mutedAccounts = try Disk.retrieve(mutesPath, from: .caches, as: [Account].self)

                let blocksPath = "\(user.diskFolderName())/blocks.json"
                let blockedAccounts = try Disk.retrieve(blocksPath, from: .caches, as: [Account].self)

                return (mutedAccounts, blockedAccounts)
            }
        } catch {
            // can't find any mutes/blocks on device
            throw error
        }

        return nil
    }

    private func loadTemporaryMutes() -> [TemporaryMute]? {
        do {
            if let user = AccountsManager.shared.currentAccount as? MastodonAcctData {
                let path = "\(user.diskFolderName())/tempMutes.json"
                return try Disk.retrieve(path, from: .caches, as: [TemporaryMute].self)
            }
        } catch {}

        return nil
    }

    private func clearExpiredMutes() {
        if !temporaryMutes.isEmpty {
            let expiredMutes = temporaryMutes.filter { $0.expiryDate <= Date() }
            for expiredMute in expiredMutes {
                unmute(user: expiredMute.account, silently: true)
            }
        }
    }
}

// MARK: - Public interface

extension ModerationManager {
    func prepareForUse() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willSwitchAccount),
                                               name: willSwitchCurrentAccountNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)

        // expire mutes when needed very 30 seconds
        timer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(onTimer), userInfo: nil, repeats: true)
    }

    func fetchLists() async throws {
        let (mutes, blocks) = try await loadRemoteLists()

        await MainActor.run {
            self.mutedUsers = mutes
            self.blockedUsers = blocks
        }

        cacheLists(lists: (mutes, blocks))
    }

    /// clear all moderation related cache and refetch lists
    func clearCache() {
        if let user = AccountsManager.shared.currentAccount as? MastodonAcctData {
            do {
                let mutesPath = "\(user.diskFolderName())/mutes.json"
                try Disk.remove(mutesPath, from: .caches)

                let blocksPath = "\(user.diskFolderName())/blocks.json"
                try Disk.remove(blocksPath, from: .caches)

                Task { try await self.fetchLists() }
            } catch {
                log.error("error clearing moderation cache: \(error)")
            }
        }
    }

    /// mute user and update local list of temporary muted and muted users
    func mute(user: Account, durationInSeconds duration: Int) {
        let expiryDate = Date().addingTimeInterval(TimeInterval(duration))
        temporaryMutes.append(TemporaryMute(expiryDate: expiryDate, account: user))
        cacheTemporaryMutes(temporaryMutes)
        mute(user: user, localOnly: true)

        NotificationCenter.default.post(name: didChangeModerationNotification, object: nil)

        Task {
            do {
                try await AccountService.mute(userId: user.id, durationInSeconds: duration)
            } catch {
                log.error("unable to send temp mute request: \(error)")
            }
        }
    }

    /// update  list of muted users
    func mute(user: Account, localOnly: Bool = false) {
        mutedUsers.append(user)
        cacheList(mutedUsers, path: "mutes.json")

        // show toast
        NotificationCenter.default.post(name: ToastNotificationManager.toast.accountMuted, object: nil)
        // notify
        NotificationCenter.default.post(name: didChangeModerationNotification, object: nil)

        if !localOnly {
            Task {
                do {
                    try await AccountService.mute(userId: user.id, durationInSeconds: 0) // 0 means forever
                } catch {
                    log.error("unable to send mute request: \(error)")
                }
            }
        }
    }

    /// unmute user and update local list of blocked users
    func unmute(user: Account, silently: Bool = false) {
        mutedUsers.removeAll(where: { $0.remoteFullOriginalAcct == user.remoteFullOriginalAcct })
        cacheList(mutedUsers, path: "mutes.json")
        temporaryMutes.removeAll(where: { $0.account.remoteFullOriginalAcct == user.remoteFullOriginalAcct })
        cacheTemporaryMutes(temporaryMutes)

        if !silently {
            // show toast
            NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnmuted"), object: nil)
        }

        // notify
        NotificationCenter.default.post(name: didChangeModerationNotification, object: nil)

        Task {
            do {
                try await AccountService.unmute(userId: user.id)
            } catch {
                log.error("unable to send unmute request: \(error)")
            }
        }
    }

    /// block user and update local list of blocked users
    func block(user: Account) {
        blockedUsers.append(user)
        cacheList(blockedUsers, path: "blocks.json")

        // notify
        NotificationCenter.default.post(name: didChangeModerationNotification, object: nil)
        // show toast
        NotificationCenter.default.post(name: ToastNotificationManager.toast.accountBlocked, object: nil)

        Task {
            do {
                try await AccountService.block(userId: user.id)
            } catch {
                log.error("unable to send block request: \(error)")
            }
        }
    }

    /// unblock user and update local list of blocked users
    func unblock(user: Account) {
        blockedUsers.removeAll(where: { $0.remoteFullOriginalAcct == user.remoteFullOriginalAcct })
        cacheList(blockedUsers, path: "blocks.json")

        // notify
        NotificationCenter.default.post(name: didChangeModerationNotification, object: nil)

        // show toast
        NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnblocked"), object: nil)

        Task {
            do {
                try await AccountService.unblock(userId: user.id)
            } catch {
                log.error("unable to send unblock request: \(error)")
            }
        }
    }
}

private struct TemporaryMute: Codable, Hashable {
    let expiryDate: Date
    let account: Account

    private enum CodingKeys: String, CodingKey {
        case expiryDate
        case account
    }
}
