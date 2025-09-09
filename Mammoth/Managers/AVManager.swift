//
//  AVManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import AVFoundation
import Foundation

class AVManager {
    static let shared = AVManager()

    var currentPlayer: AVPlayer? {
        willSet {
            // Mute previously playing video
            // Only one video can be unmuted at the time
            if currentPlayer !== newValue {
                currentPlayer?.isMuted = true
            }
        }
    }

    func prepareForUse() {
        Mute.shared.checkInterval = 0.5
        Mute.shared.alwaysNotify = false
        Mute.shared.check()

        Mute.shared.notify = { [weak self] isMuted in
            guard let self else { return }
            if isMuted {
                self.currentPlayer?.isMuted = true
            }
        }
    }
}
