//
//  AnalyticsManager.swift
//  Mammoth
//
//  Created by Terence on 10/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import ArkanaKeys
import Foundation
import Segment

enum Events: String {
    case newPost
    case newPostFailed
    case newReplyFailed
    case upgradedToGold
    case restoredToGold
    case failedToUpgrade
    case postBookmarked
    case channelSubscribed
    case channelUnsubscribed
    case navigateToChannel

    case loggedIn
    case accountCreated
    case verifiedEmail
    case switchingAccount

    case follow
    case unfollow

    case like
    case unlike
    case repost
    case unrepost
}

class AnalyticsManager {
    private let analytics: Analytics
    static let shared = AnalyticsManager()

    init() {
        #if DEBUG
            let key = ArkanaKeys.Staging().analyticsKey
            let config = Configuration(writeKey: key)
                .trackApplicationLifecycleEvents(true)
                .flushAt(1)
                .flushInterval(5)

            analytics = Analytics(configuration: config)

        #else
            let key = ArkanaKeys.Production().analyticsKey
            let config = Configuration(writeKey: key)
                .trackApplicationLifecycleEvents(true)
                .flushAt(3)
                .flushInterval(10)

            analytics = Analytics(configuration: config)
        #endif

        analytics.enabled = GlobalStruct.shareAnalytics
    }

    func prepareForUse() {
        NotificationCenter.default.addObserver(self, selector: #selector(didSwitchAccount), name: didSwitchCurrentAccountNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdatePurchase), name: didUpdatePurchaseStatus, object: nil)

        analytics.add(plugin: DeviceToken())
        analytics.add(plugin: UIKitScreenTracking())
    }

    @objc func didSwitchAccount(_: NSNotification) {
        // stub
    }

    @objc func didUpdatePurchase(_: NSNotification) {
        // stub
    }

    private func callActivities() {
        if GlobalStruct.shareAnalytics {
            if let currentFullAccount = AccountsManager.shared.currentAccount?.remoteFullOriginalAcct {
                // We used to call out to a simple feature.moth.social checkin here
                // Now this is stubbed above
                // I think we'll likely want other types of analytics at some point so I'm leaving this in
            } else {
                log.warning("no account to check in with")
            }
        }
    }

    static func track(event: Events, props: [String: Any]? = [:]) {
        if GlobalStruct.shareAnalytics {
            shared.analytics.track(name: event.rawValue, properties: props)
        }
    }

    static func reportError(_ error: Error) {
        if GlobalStruct.shareAnalytics {
            shared.analytics.reportInternalError(error)
        }
    }

    static func identity(userId: String, identity: IdentityData) {
        if GlobalStruct.shareAnalytics {
            shared.analytics.identify(userId: userId, traits: identity)
        }
    }

    static func alias(userId: String) {
        if GlobalStruct.shareAnalytics {
            shared.analytics.alias(newId: userId)
        }
    }

    static func openURL(url: URL) {
        if GlobalStruct.shareAnalytics {
            shared.analytics.openURL(url)
        }
    }

    static func setDeviceToken(token: Data) {
        if GlobalStruct.shareAnalytics {
            shared.analytics.registeredForRemoteNotifications(deviceToken: token)
        }
    }

    static func failedToRegisterForPushNotifications(error: Error?) {
        if GlobalStruct.shareAnalytics {
            shared.analytics.failedToRegisterForRemoteNotification(error: error)
        }
    }

    static func subscribe() {
        shared.analytics.enabled = true
        shared.analytics.identify(traits: ["shareAnalytics": true])
        shared.analytics.flush()
    }

    static func unsubscribe() {
        shared.analytics.identify(traits: ["shareAnalytics": false])
        shared.analytics.flush()
        shared.analytics.reset()
        shared.analytics.enabled = false
    }

    static func reset() {
        shared.analytics.flush()
        shared.analytics.reset()
    }
}
