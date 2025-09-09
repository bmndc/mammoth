//
//  Mute.swift
//  Mute
//
//  Created by Akram Hussein on 08/09/2017.
//

import AudioToolbox
import Foundation
import UIKit

@objcMembers
public class Mute: NSObject {
    public typealias MuteNotificationCompletion = (_ mute: Bool) -> Void

    // MARK: Properties

    /// Shared instance
    public static let shared = Mute()

    /// Sound ID for mute sound
    private let soundUrl = Mute.muteSoundUrl

    /// Should notify every second or only when changes?
    /// True will notify every second of the state, false only when it changes
    public var alwaysNotify = true

    /// Notification handler to be triggered when mute status changes
    /// Triggered every second if alwaysNotify=true, otherwise only when it switches state
    public var notify: MuteNotificationCompletion?

    /// Currently playing? used when returning from the background (if went to background and foreground really quickly)
    public private(set) var isPlaying = false

    /// Current mute state
    public private(set) var isMute = false

    /// Sound is scheduled
    private var isScheduled = false

    /// State of detection - paused when in background
    public var isPaused = false {
        didSet {
            if !isPaused, oldValue, !isPlaying {
                schedulePlaySound()
            }
        }
    }

    /// How frequently to check (seconds), minimum = 0.5
    public var checkInterval = 1.0 {
        didSet {
            if checkInterval < 0.5 {
                print("MUTE: checkInterval cannot be less than 0.5s, setting to 0.5")
                checkInterval = 0.5
            }
        }
    }

    /// Silent sound (0.5 sec)
    private var soundId: SystemSoundID = 0

    /// Time difference between start and finish of mute sound
    private var interval: TimeInterval = 0

    // MARK: Resources

    /// Library bundle
    private static var bundle: Bundle {
        return Bundle.main
    }

    /// Mute sound url path
    private static var muteSoundUrl: URL {
        guard let muteSoundUrl = Mute.bundle.url(forResource: "mute", withExtension: "aiff") else {
            fatalError("mute.aiff not found")
        }
        return muteSoundUrl
    }

    // MARK: Init

    /// private init
    override private init() {
        super.init()

        soundId = 1

        if AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId) == kAudioServicesNoError {
            var yes: UInt32 = 1
            AudioServicesSetProperty(kAudioServicesPropertyIsUISound,
                                     UInt32(MemoryLayout.size(ofValue: soundId)),
                                     &soundId,
                                     UInt32(MemoryLayout.size(ofValue: yes)),
                                     &yes)

            schedulePlaySound()
        } else {
            print("Failed to setup sound player")
            soundId = 0
        }

        // Notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(Mute.didEnterBackground(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(Mute.willEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    deinit {
        if self.soundId != 0 {
            AudioServicesRemoveSystemSoundCompletion(self.soundId)
            AudioServicesDisposeSystemSoundID(self.soundId)
        }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Notification Handlers

    /// Selector called when app enters background
    @objc private func didEnterBackground(_: Any) {
        isPaused = true
    }

    /// Selector called when app will enter foreground
    @objc private func willEnterForeground(_: Any) {
        isPaused = false
    }

    // MARK: Methods

    /// Starts a mute check outside the `checkInterval`
    public func check() {
        playSound()
    }

    /// Schedules mute sound to be played at `checkInterval`
    private func schedulePlaySound() {
        /// Don't schedule a new one if we already have one queued
        if isScheduled { return }

        isScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
            self.isScheduled = false

            /// Don't play if we're paused
            if self.isPaused {
                return
            }

            self.playSound()
        }
    }

    /// If not paused, playes mute sound
    private func playSound() {
        if !isPaused, !isPlaying {
            interval = Date.timeIntervalSinceReferenceDate
            isPlaying = true
            AudioServicesPlaySystemSoundWithCompletion(soundId) { [weak self] in
                self?.soundFinishedPlaying()
            }
        }
    }

    /// Called when AudioService finished playing sound
    private func soundFinishedPlaying() {
        isPlaying = false

        let elapsed = Date.timeIntervalSinceReferenceDate - interval
        let isMute = elapsed < 0.1

        if self.isMute != isMute || alwaysNotify {
            self.isMute = isMute
            DispatchQueue.main.async {
                self.notify?(isMute)
            }
        }
        schedulePlaySound()
    }
}
