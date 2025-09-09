//
//  UserCardModel.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import ArkanaKeys
import Foundation
import Kingfisher
import MastodonMeta
import Meta
import MetaTextKit
import SDWebImage

class UserCardModel {
    let id: String
    let uniqueId: String
    let name: String
    let userTag: String
    let username: String

    let imageURL: String?
    let description: String?
    let isFollowing: Bool
    let emojis: [Emoji]?

    var preSyncAccount: Account?
    let account: Account?

    var instanceName: String?

    let isLocked: Bool
    let isBot: Bool

    var richName: NSAttributedString?
    let metaName: MastodonMetaContent?

    let metaDescription: MastodonMetaContent?

    let richPreviewDescription: NSAttributedString?
    var followStatus: FollowManager.FollowStatus?
    let followingCount: String
    let followersCount: String
    let fields: [HashType]?
    var relationship: Relationship?

    // when the profile pic is decoded we store it here
    var decodedProfilePic: UIImage?
    var imagePrefetchToken: SDWebImagePrefetchToken?

    // when a user has been followed we keep the unfollow button
    // until a hard refresh happens
    var forceFollowButtonDisplay: Bool = false

    let joinedOn: Date?

    var isSelf: Bool {
        return account?.fullAcct != nil && AccountsManager.shared.currentUser()?.fullAcct != nil && AccountsManager.shared.currentUser()?.fullAcct == account?.fullAcct
    }

    var isMuted: Bool {
        return ModerationManager.shared.mutedUsers.first(where: { $0.remoteFullOriginalAcct == self.uniqueId }) != nil
    }

    var isBlocked: Bool {
        return ModerationManager.shared.blockedUsers.first(where: { $0.remoteFullOriginalAcct == self.uniqueId }) != nil
    }

    // if self is tippable.
    let isTippable: Bool
    // if a tippable account is detected in metadata.
    struct TippableAccount: Equatable {
        var accountname: String
        var user: UserCardModel?
        var isFollowed: Bool?
    }

    var tippableAccount: TippableAccount?

    // deprecated initializer
    init(name: String, userTag: String, imageURL: String?, description: String?, isFollowing: Bool, emojis: [Emoji]?, account: Account?) {
        id = account?.id ?? ""
        uniqueId = account?.remoteFullOriginalAcct ?? ""
        self.name = name
        self.userTag = userTag
        username = account?.username ?? ""
        self.emojis = emojis

        self.imageURL = imageURL
        self.description = description?.stripHTML()
        self.isFollowing = isFollowing
        self.account = account

        var emojisDic: MastodonContent.Emojis = [:]
        self.emojis?.forEach { emojisDic[$0.shortcode] = $0.url.absoluteString }
        do {
            metaName = try MastodonMetaContent.convert(document: MastodonContent(content: self.name, emojis: emojisDic))
        } catch {
            metaName = MastodonMetaContent.convert(text: MastodonContent(content: self.name, emojis: emojisDic))
        }

        richName = NSMutableAttributedString(string: metaName!.string)

        richPreviewDescription = self.description != nil ? removeTrailingLinebreaks(string: NSAttributedString(string: self.description!)) : nil

        do {
            metaDescription = try MastodonMetaContent.convert(document: MastodonContent(content: self.description ?? "", emojis: emojisDic))
        } catch {
            metaDescription = MastodonMetaContent.convert(text: MastodonContent(content: self.description ?? "", emojis: emojisDic))
        }

        instanceName = nil

        isLocked = account?.locked ?? false
        isBot = account?.bot ?? false

        if let account = account, !Self.isOwn(account: account) {
            followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .none)
            relationship = FollowManager.shared.relationshipForAccount(account, requestUpdate: false)
        }

        followingCount = max(account?.followingCount ?? 0, 0).formatUsingAbbrevation()
        followersCount = max(account?.followersCount ?? 0, 0).formatUsingAbbrevation()

        fields = account?.fields
        fields?.forEach { $0.configureMetaContent(with: emojisDic) }
        joinedOn = account?.createdAt?.toDate()
        isTippable = instanceName == ArkanaKeys.Global().subClubDomain
        tippableAccount = nil
    }

    init(account: Account, instanceName: String? = nil, requestFollowStatusUpdate: FollowManager.NetworkUpdateType = .none, isFollowing: Bool = false, premiumAccount: TippableAccount? = nil) {
        id = account.id
        uniqueId = account.remoteFullOriginalAcct
        name = !account.displayName.isEmpty ? account.displayName : account.username
        userTag = account.fullAcct
        username = account.username
        imageURL = account.avatar
        description = account.note
        self.isFollowing = isFollowing
        emojis = account.emojis
        self.account = account

        var emojisDic: MastodonContent.Emojis = [:]
        emojis?.forEach { emojisDic[$0.shortcode] = $0.url.absoluteString }

        do {
            metaName = try MastodonMetaContent.convert(document: MastodonContent(content: name, emojis: emojisDic))
        } catch {
            metaName = MastodonMetaContent.convert(text: MastodonContent(content: name, emojis: emojisDic))
        }

        if let _ = metaName {
            richName = NSMutableAttributedString(string: metaName!.string)
        }

        richPreviewDescription = description != nil ? removeTrailingLinebreaks(string: NSAttributedString(string: description!)) : nil

        do {
            metaDescription = try MastodonMetaContent.convert(document: MastodonContent(content: description ?? "", emojis: emojisDic))
        } catch {
            metaDescription = MastodonMetaContent.convert(text: MastodonContent(content: description ?? "", emojis: emojisDic))
        }

        self.instanceName = instanceName

        isLocked = account.locked
        isBot = account.bot

        if !Self.isOwn(account: account) {
            followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: requestFollowStatusUpdate)
            relationship = FollowManager.shared.relationshipForAccount(account, requestUpdate: false)
        }

        followingCount = max(account.followingCount, 0).formatUsingAbbrevation()
        followersCount = max(account.followersCount, 0).formatUsingAbbrevation()

        fields = account.fields
        fields?.forEach { $0.configureMetaContent(with: emojisDic) }
        joinedOn = account.createdAt?.toDate()
        isTippable = account.acct.hasSuffix(ArkanaKeys.Global().subClubDomain)

        if let premiumAccount {
            tippableAccount = premiumAccount
        } else {
            // detect tippable link in profile fields.
            var premiumAcct: String? = nil
            for field in account.fields {
                if let s = field.value.matchingStrings(regex: "https://\(ArkanaKeys.Global().subClubDomain)/users/([a-z0-9-_]+)").first?[1] {
                    premiumAcct = s
                    break
                }
            }
            if let premiumAcct = premiumAcct {
                tippableAccount = TippableAccount(accountname: premiumAcct)
            }
        }
    }

    // Return an instance without description
    func simple() -> UserCardModel {
        return UserCardModel(name: name,
                             userTag: userTag,
                             imageURL: imageURL,
                             description: "",
                             isFollowing: isFollowing,
                             emojis: emojis,
                             account: account)
    }

    func syncFollowStatus(_ requestUpdate: FollowManager.NetworkUpdateType = .whenUncertain) {
        if let account = account {
            followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: requestUpdate)
        }
    }

    func setFollowStatus(_ followStatus: FollowManager.FollowStatus) {
        self.followStatus = followStatus
    }

    static func isOwn(account: Account) -> Bool {
        return AccountsManager.shared.currentUser()?.fullAcct != nil && AccountsManager.shared.currentUser()?.fullAcct == account.fullAcct
    }
}

extension UserCardModel {
    static func fromAccount(account: Account, instanceName: String? = nil) -> UserCardModel {
        return UserCardModel(account: account, instanceName: instanceName)
    }
}

extension UserCardModel: Equatable {
    static func == (lhs: UserCardModel, rhs: UserCardModel) -> Bool {
        return lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.imageURL == rhs.imageURL &&
            lhs.description == rhs.description &&
            lhs.followingCount == rhs.followingCount &&
            lhs.followersCount == rhs.followersCount &&
            lhs.isFollowing == rhs.isFollowing &&
            lhs.followStatus == rhs.followStatus &&
            lhs.relationship == rhs.relationship &&
            lhs.fields == rhs.fields &&
            lhs.isBot == rhs.isBot &&
            lhs.isLocked == rhs.isLocked &&
            lhs.emojis == rhs.emojis &&
            lhs.tippableAccount == rhs.tippableAccount
    }
}

extension UserCardModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preload

extension UserCardModel {
    static func preload(userCards: [UserCardModel]) {
        PostCardModel.imageDecodeQueue.async {
            for userCard in userCards {
                userCard.preloadImages()
            }
        }
    }

    // Download, transform and cache profile pic
    func preloadImages() {
        if let profilePicURLString = imageURL,
           !SDImageCache.shared.diskImageDataExists(withKey: profilePicURLString),
           let profilePicURL = URL(string: profilePicURLString)
        {
            let prefetcher = SDWebImagePrefetcher.shared
            imagePrefetchToken = prefetcher.prefetchURLs([profilePicURL], context: [.imageTransformer: PostCardProfilePic.transformer], progress: nil)
        }

        if let emojis = emojis, !emojis.isEmpty {
            let prefetcher = SDWebImagePrefetcher.shared
            prefetcher.prefetchURLs(emojis.map { $0.url }, context: [.animatedImageClass: SDAnimatedImageView.self], progress: nil)
        }
    }

    func cancelAllPreloadTasks() {
        imagePrefetchToken?.cancel()
    }

    func clearCache() {
        decodedProfilePic = nil
    }
}

extension UserCardModel {
    @discardableResult
    func getTipInfo() async throws -> UserCardModel.TippableAccount? {
        if let tippableAccount = tippableAccount {
            do {
                let request = Search.search(query: tippableAccount.accountname + "@" + ArkanaKeys.Global().subClubDomain, resolve: true)
                let result = try await ClientService.runRequest(request: request)
                if let account = (result.accounts.first) {
                    let followStatus = FollowManager.shared.followStatusForAccount(account, requestUpdate: .force) == .following
                    let premiumAccount = await MainActor.run { [weak self] in
                        self?.tippableAccount = TippableAccount(accountname: tippableAccount.accountname, user: UserCardModel(account: account), isFollowed: followStatus)
                        return self?.tippableAccount
                    }

                    return premiumAccount
                }
            } catch {
                log.error("error searching subclub account for \(tippableAccount.accountname) : \(error)")
            }
        }

        return nil
    }
}
