//
//  IdentityData.swift
//  Mammoth
//
//  Created by Benoit Nolens on 17/04/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import Foundation

struct IdentityData: Codable {
    let id: String
    let created_at: String?

    let server: String
    let lastStatusAt: String?
    let accountCreatedAt: String?
    let followersCount: Int
    let followingCount: Int
    let statusesCount: Int
    let numberOfSubscribedChannels: Int
    let subscribedChannels: [String]
    let numberOfAccounts: Int
    let theme: String
    let isGoldMember: Bool
    let appLanguage: String
    let isLanguageSupported: Bool
    let hasAvatar: Bool
    let hasBio: Bool
    let isBot: Bool
    let pushEnabled: Bool
    let unsubscribed: Bool

    init(from acctData: MastodonAcctData, allAccounts: [any AcctDataType]) {
        id = acctData.account.fullAcct.sha256
        created_at = acctData.account.createdAt

        server = acctData.account.server
        followersCount = acctData.account.followersCount
        followingCount = acctData.account.followingCount
        statusesCount = acctData.account.statusesCount
        lastStatusAt = acctData.account.lastStatusAt
        accountCreatedAt = acctData.account.createdAt
        numberOfSubscribedChannels = acctData.forYou.subscribedChannels.count
        subscribedChannels = acctData.forYou.subscribedChannels.map { $0.title }
        numberOfAccounts = allAccounts.count
        isGoldMember = IAPManager.isGoldMember
        hasAvatar = !acctData.account.avatar.isEmpty && !acctData.account.avatar.contains("original/missing.png")
        hasBio = !acctData.account.note.isEmpty
        isBot = acctData.account.bot

        let themePrefix = GlobalStruct.overrideThemeHighContrast ? "HC:" : ""
        switch GlobalStruct.overrideTheme {
        case 1:
            theme = "\(themePrefix)light"
        case 2:
            theme = "\(themePrefix)dark"
        default:
            theme = "\(themePrefix)system"
        }

        appLanguage = l10n.getCurrentLocale() ?? "en"
        isLanguageSupported = l10n.isCurrentLanguageSupported()

        let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
        if notificationType == [] {
            pushEnabled = false
        } else {
            pushEnabled = true
        }

        unsubscribed = false
    }
}
