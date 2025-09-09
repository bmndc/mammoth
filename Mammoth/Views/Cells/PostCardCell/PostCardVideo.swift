//
//  PostCardVideo.swift
//  Mammoth
//
//  Created by Benoit Nolens on 02/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import AVFoundation
import UIKit

// swiftlint:disable:next type_body_length
final class PostCardVideo: UIView {
    enum PostCardVideoVariant {
        case fullSize
        case thumbnail
    }

    private var videoView: UIView = {
        let videoView = UIView()
        videoView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        videoView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        videoView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        videoView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        videoView.backgroundColor = .custom.OVRLYSoftContrast
        videoView.translatesAutoresizingMaskIntoConstraints = false
        return videoView
    }()

    private var sensitiveContentOverlay: UIButton = {
        let button = UIButton(type: .custom)

        let iconView = BlurredBackground(dimmed: false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 18
        iconView.clipsToBounds = true

        button.insertSubview(iconView, aboveSubview: button.imageView!)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
        ])

        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f070}", color: .custom.linkText, size: 16, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)
        icon.pinCenter()

        let bg = BlurredBackground(dimmed: true, underlayAlpha: 0.11)
        button.insertSubview(bg, belowSubview: button.imageView!)
        bg.pinEdges()

        return button
    }()

    private var hideSensitiveOverlayGesture: UITapGestureRecognizer?
    private var dismissedSensitiveOverlay: Bool = false
    private var onPressGesture: UITapGestureRecognizer!

    private var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.accessibilityElementsHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = .zero
        button.imageView?.contentMode = .center

        let bg = BlurredBackground(dimmed: false)
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.layer.cornerCurve = .continuous
        bg.layer.cornerRadius = 12
        bg.clipsToBounds = true
        button.insertSubview(bg, belowSubview: button.imageView!)

        NSLayoutConstraint.activate([
            bg.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            bg.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            bg.widthAnchor.constraint(equalToConstant: 24),
            bg.heightAnchor.constraint(equalToConstant: 24),
        ])

        return button
    }()

    private var altButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("ALT", for: .normal)
        button.setTitleColor(.custom.active, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 7
        button.clipsToBounds = true
        button.isHidden = true
        button.accessibilityElementsHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)

        let bg = BlurredBackground(dimmed: false)
        button.insertSubview(bg, belowSubview: button.titleLabel!)
        bg.pinEdges()

        return button
    }()

    private var previewImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let loadingIndicator = UIActivityIndicatorView()
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerRateObserver: NSKeyValueObservation?
    private var playerMuteObserver: NSKeyValueObservation?
    private var playerLoopObserver: NSObjectProtocol?

    private var loopCount: Int = 0
    private let maxLoopCount: Int = 8

    private var systemPausedOverlayLarge: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.setTitle("", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        let iconView = BlurredBackground(dimmed: false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 18
        iconView.clipsToBounds = true

        button.insertSubview(iconView, aboveSubview: button.imageView!)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
        ])

        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f04b}", color: .custom.linkText, size: 16, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor, constant: 1),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
        ])

        let bg = UIView()
        bg.backgroundColor = .custom.OVRLYSoftContrast.withAlphaComponent(0.3)
        button.insertSubview(bg, belowSubview: button.imageView!)
        bg.pinEdges()

        return button

    }()

    private var systemPausedOverlayThumbnail: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = true
        button.setTitle("", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        let iconView = BlurredBackground(dimmed: false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 4
        iconView.clipsToBounds = true

        button.insertSubview(iconView, aboveSubview: button.imageView!)

        NSLayoutConstraint.activate([
            iconView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -3),
            iconView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -3),
            iconView.widthAnchor.constraint(equalToConstant: 15),
            iconView.heightAnchor.constraint(equalToConstant: 15),
        ])

        let icon = UIImageView(image: FontAwesome.image(fromChar: "\u{f04b}", color: .custom.linkText, size: 8, weight: .bold).withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .center
        iconView.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconView.centerXAnchor, constant: 0.5),
            icon.centerYAnchor.constraint(equalTo: iconView.centerYAnchor, constant: 0.25),
        ])

        return button

    }()

    private lazy var systemPausedOverlay: (_ variant: PostCardVideoVariant) -> UIButton = { variant in
        switch variant {
        case .fullSize:
            return self.systemPausedOverlayLarge
        case .thumbnail:
            return self.systemPausedOverlayThumbnail
        }
    }

    private var isSystemPaused: Bool = false

    private var postCard: PostCardModel?
    private var media: Attachment?
    private var isSensitive: Bool = false
    private let variant: PostCardVideoVariant

    // A dynamic width is used when the view has a fixed height (as in the gallery)
    private var dynamicWidthConstraint: NSLayoutConstraint?
    // A dynamic height is used when the view has a max width (as in standalone image in post card cell)
    private var dynamicHeightConstraint: NSLayoutConstraint?

    private let tallAspectRatio = 0.44

    private lazy var squareConstraints: [NSLayoutConstraint] = {
        let c1 = videoView.widthAnchor.constraint(equalTo: videoView.heightAnchor)
        c1.priority = .defaultHigh

        let c2 = videoView.heightAnchor.constraint(equalTo: videoView.widthAnchor)
        c2.priority = .defaultHigh

        let c3 = videoView.heightAnchor.constraint(equalTo: self.heightAnchor)
        c3.priority = .required

        return [c1, c2, c3]
    }()

    private lazy var portraitConstraints: [NSLayoutConstraint] = {
        // most landscape images
        if self.inGallery {
            let c1 = videoView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .defaultLow

            let c2 = videoView.widthAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: tallAspectRatio)
            c2.priority = .defaultHigh

            return [c1, c2]
        } else {
            let c1 = videoView.widthAnchor.constraint(equalTo: self.widthAnchor)
            c1.priority = .defaultHigh

            let c2 = videoView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
            c2.priority = .required

            return [c1, c2]
        }
    }()

    private lazy var tallPortraitConstraints: [NSLayoutConstraint] = {
        if self.inGallery {
            // extremely tall (more than the iPhone 14 Pro Max ratio)
            let c1 = videoView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .defaultLow

            let c2 = videoView.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 9.0 / 16.0)
            c2.priority = .required

            return [c1, c2]
        } else {
            // extremely tall (more than the iPhone 14 Pro Max ratio)
            let c1 = videoView.widthAnchor.constraint(equalTo: self.widthAnchor)
            c1.priority = .defaultHigh

            let c2 = videoView.heightAnchor.constraint(equalToConstant: 420)
            c2.priority = .defaultHigh

            return [c1, c2]
        }
    }()

    private lazy var landscapeConstraints: [NSLayoutConstraint] = {
        if self.inGallery {
            let c1 = videoView.heightAnchor.constraint(equalTo: self.heightAnchor)
            c1.priority = .required

            let c2 = videoView.widthAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: 16.0 / 9.0)
            c2.priority = .required

            return [c1, c2]
        } else {
            let c1 = videoView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor)
            c1.priority = .required

            let c2 = videoView.heightAnchor.constraint(lessThanOrEqualToConstant: 420)
            c2.priority = .required

            return [c1, c2]
        }
    }()

    private let inGallery: Bool

    init(variant: PostCardVideoVariant = .fullSize, inGallery: Bool = false) {
        self.variant = variant
        self.inGallery = inGallery
        super.init(frame: .zero)
        setupUI()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(stoppedBySystem),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }

    deinit {
        self.removeLoopObserver()
        NotificationCenter.default.removeObserver(self)
        playerStatusObserver?.invalidate()
        playerRateObserver?.invalidate()
        playerMuteObserver?.invalidate()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        postCard = nil
        media = nil
        isSensitive = false
        dismissedSensitiveOverlay = false
        onPressGesture.isEnabled = true
        isSystemPaused = false
        systemPausedOverlay(variant).isHidden = true

        playerRateObserver?.invalidate()
        playerStatusObserver?.invalidate()
        playerMuteObserver?.invalidate()

        removeLoopObserver()
        loopCount = 0

        playerLayer?.removeFromSuperlayer()
        playerLayer = nil

        previewImage.sd_cancelCurrentImageLoad()
        previewImage.image = nil

        if let _ = videoView.subviews.firstIndex(of: sensitiveContentOverlay) {
            sensitiveContentOverlay.removeFromSuperview()
        }
    }

    private func setupUI() {
        isOpaque = true
        layoutMargins = .init(top: 3, left: 0, bottom: 0, right: 0)

        videoView.clipsToBounds = true
        videoView.layer.cornerRadius = 6
        videoView.layer.cornerCurve = .continuous
        videoView.layoutMargins = .zero
        videoView.isUserInteractionEnabled = true
        addSubview(videoView)

        videoView.addSubview(previewImage)
        videoView.addSubview(loadingIndicator)
        videoView.addSubview(systemPausedOverlay(variant))

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true

        addSubview(muteButton)
        addSubview(altButton)

        switch variant {
        case .fullSize:
            altButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            altButton.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)
        case .thumbnail:
            altButton.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
            altButton.contentEdgeInsets = .init(top: 3, left: 5, bottom: 2, right: 5)
        }

        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: topAnchor),
            videoView.bottomAnchor.constraint(equalTo: bottomAnchor),
            videoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: trailingAnchor),

            previewImage.topAnchor.constraint(equalTo: videoView.topAnchor),
            previewImage.bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
            previewImage.leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            previewImage.trailingAnchor.constraint(equalTo: videoView.trailingAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: videoView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: videoView.centerYAnchor),

            systemPausedOverlay(variant).topAnchor.constraint(equalTo: videoView.topAnchor),
            systemPausedOverlay(variant).bottomAnchor.constraint(equalTo: videoView.bottomAnchor),
            systemPausedOverlay(variant).leadingAnchor.constraint(equalTo: videoView.leadingAnchor),
            systemPausedOverlay(variant).trailingAnchor.constraint(equalTo: videoView.trailingAnchor),
            altButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: variant == .fullSize ? -10 : -2),
            altButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: variant == .fullSize ? -10 : -2),
        ])

        if variant == .thumbnail {
            altButton.isHidden = true
            NSLayoutConstraint.activate([
                muteButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                muteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                muteButton.widthAnchor.constraint(equalToConstant: 40),
                muteButton.heightAnchor.constraint(equalToConstant: 40),
            ])
        } else {
            altButton.isHidden = false
            NSLayoutConstraint.activate([
                muteButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
                muteButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
                muteButton.widthAnchor.constraint(equalToConstant: 40),
                muteButton.heightAnchor.constraint(equalToConstant: 40),
            ])
        }

        onPressGesture = UITapGestureRecognizer(target: self, action: #selector(onPress))
        addGestureRecognizer(onPressGesture)

        let mutePress = UITapGestureRecognizer(target: self, action: #selector(self.mutePress))
        muteButton.addGestureRecognizer(mutePress)

        let altPress = UITapGestureRecognizer(target: self, action: #selector(self.altPress))
        altButton.addGestureRecognizer(altPress)

        let systemPausedPress = UITapGestureRecognizer(target: self, action: #selector(self.systemPausedPress))
        systemPausedOverlay(variant).addGestureRecognizer(systemPausedPress)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoView.bounds
    }

    func configure(video: Attachment?, postCard: PostCardModel, cachedPlayer: AVPlayer? = nil) {
        let shouldUpdate = media == nil || video != media!
        isSensitive = postCard.isSensitive
        self.postCard = postCard

        if let media = video {
            guard self.media != media else { return }

            self.media = media
            if let videoURL = URL(string: media.remoteURL ?? media.url ?? media.previewURL!) {
                loadingIndicator.startAnimating()

                if let previewImageURL = media.previewURL {
                    previewImage.sd_setImage(with: URL(string: previewImageURL))
                }

                if let cachedPlayer = cachedPlayer {
                    // if the player is preloaded
                    player = cachedPlayer

                    if let currentItem = player?.currentItem {
                        if currentItem.status == .readyToPlay {
                            if cachedPlayer.isPlaying() {
                                play()
                            } else if !isSensitive && !isSystemPaused && GlobalStruct.autoPlayVideos {
                                play()
                            }
                        } else if !isSensitive && GlobalStruct.autoPlayVideos {
                            observePlayerStatus(currentItem)
                        }
                    }

                    if loadingIndicator.isAnimating {
                        loadingIndicator.stopAnimating()
                    }
                } else {
                    // if no player is preloaded
                    let item = AVPlayerItem(url: videoURL)
                    player = AVPlayer(playerItem: item)
                    player?.isMuted = true
                    observePlayerStatus(item)
                    postCard.videoPlayer = player
                }

                // if the player is not already playing - make sure it doesn't auto-plays
                // if the sensitive overlay is visible or auto-play is enabled
                if !player!.isPlaying() && ((isSensitive && !dismissedSensitiveOverlay) || !GlobalStruct.autoPlayVideos) {
                    pause()
                }

                if playerLayer != nil {
                    if let _ = videoView.layer.sublayers?.firstIndex(of: playerLayer!) {
                        playerLayer?.removeFromSuperlayer()
                    }
                }

                playerRateObserver?.invalidate()
                observePlayerRate(player!)
                playerMuteObserver?.invalidate()
                observePlayerMuteState(player!)

                // sync mute button state
                if player!.isMuted {
                    muteButton.setImage(FontAwesome.image(fromChar: "\u{f6a9}", color: .custom.linkText, size: 11, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
                } else {
                    muteButton.setImage(FontAwesome.image(fromChar: "\u{f6a8}", color: .custom.linkText, size: 11, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
                }

                playerLayer = AVPlayerLayer(player: player)
                playerLayer?.videoGravity = .resizeAspectFill
                playerLayer?.frame = videoView.bounds

                videoView.layer.addSublayer(playerLayer!)

                videoView.bringSubviewToFront(systemPausedOverlay(variant))
                videoView.bringSubviewToFront(sensitiveContentOverlay)
            }

            if shouldUpdate {
                // meta itself might be nil
                var aspect: Double? = nil
                if let width = self.media?.meta?.original?.width, let height = self.media?.meta?.original?.height {
                    aspect = Double(width) / Double(height)
                } else {
                    previewImage.contentMode = .scaleAspectFit
                    playerLayer?.videoGravity = .resizeAspect
                }
                let ratio = self.media?.meta?.original?.aspect ?? aspect ?? (self.media?.type == .audio ? 1.0 : 16.0 / 9.0)

                // square
                if variant == .thumbnail || fabs(ratio - 1.0) < 0.01 {
                    deactivateAllImageConstraints()
                    NSLayoutConstraint.activate(squareConstraints)
                }

                // landscape
                else if ratio > 1 {
                    deactivateAllImageConstraints()

                    if inGallery {
                        if ratio < 16.0 / 9.0 {
                            dynamicWidthConstraint = videoView.widthAnchor.constraint(equalTo: videoView.heightAnchor, multiplier: ratio)
                            dynamicWidthConstraint!.priority = .defaultHigh + 1
                            dynamicWidthConstraint!.isActive = true
                        }
                    } else {
                        dynamicHeightConstraint = videoView.heightAnchor.constraint(equalTo: videoView.widthAnchor, multiplier: 1.0 / ratio)
                        dynamicHeightConstraint!.priority = .defaultHigh + 1
                        dynamicHeightConstraint!.isActive = true
                    }

                    NSLayoutConstraint.activate(landscapeConstraints)
                }

                // portrait
                else if ratio < 1 {
                    if ratio < tallAspectRatio {
                        deactivateAllImageConstraints()
                        NSLayoutConstraint.activate(tallPortraitConstraints)
                    } else {
                        deactivateAllImageConstraints()

                        if inGallery {
                            dynamicWidthConstraint = videoView.widthAnchor.constraint(equalTo: videoView.heightAnchor, multiplier: ratio)
                            dynamicWidthConstraint!.priority = .defaultHigh
                            dynamicWidthConstraint!.isActive = true
                        } else {
                            dynamicHeightConstraint = videoView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0 / ratio)
                            dynamicHeightConstraint!.priority = .defaultHigh
                            dynamicHeightConstraint!.isActive = true
                        }

                        NSLayoutConstraint.activate(portraitConstraints)
                    }
                }

                if GlobalStruct.blurSensitiveContent, isSensitive, !dismissedSensitiveOverlay {
                    sensitiveContentOverlay.frame = videoView.bounds
                    sensitiveContentOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    sensitiveContentOverlay.alpha = 1

                    if hideSensitiveOverlayGesture == nil {
                        hideSensitiveOverlayGesture = UITapGestureRecognizer(target: self, action: #selector(hideSensitiveOverlay))
                        sensitiveContentOverlay.addGestureRecognizer(hideSensitiveOverlayGesture!)
                    }

                    videoView.addSubview(sensitiveContentOverlay)
                }

                if let description = media.description, !description.isEmpty, media.type == .gifv {
                    altButton.isHidden = false
                    bringSubviewToFront(altButton)
                } else {
                    altButton.isHidden = true
                }
            }
        }
    }

    func configure(postCard: PostCardModel) {
        if let firstVideo = postCard.mediaAttachments.first, [.video, .gifv].contains(firstVideo.type) {
            configure(video: firstVideo, postCard: postCard, cachedPlayer: postCard.videoPlayer)
        }
    }

    private func deactivateAllImageConstraints() {
        NSLayoutConstraint.deactivate(squareConstraints
            + portraitConstraints
            + tallPortraitConstraints
            + landscapeConstraints
            + [dynamicHeightConstraint, dynamicWidthConstraint].compactMap { $0 }
        )
    }

    @objc func play() {
        systemPausedOverlay(variant).isHidden = true
        isSystemPaused = false
        loopCount = 0
        showMuteButton()

        addLoopObserver()

        if let player, !player.isPlaying(), !self.isSensitive || self.dismissedSensitiveOverlay {
            player.play()
        }

        if loadingIndicator.isAnimating {
            loadingIndicator.stopAnimating()
        }
    }

    func pause() {
        isSystemPaused = true
        systemPausedOverlay(variant).isHidden = false
        hideMuteButton()
        if let player = player, player.isPlaying() {
            player.pause()
        }
    }

    @objc func stoppedBySystem() {
        isSystemPaused = true
        systemPausedOverlay(variant).isHidden = false
        hideMuteButton()

        loopCount = 0
        player?.seek(to: CMTime.zero)
        player?.pause()
    }

    private func addLoopObserver() {
        if let observer = playerLoopObserver {
            NotificationCenter.default.removeObserver(observer)
            playerLoopObserver = nil
        }

        playerLoopObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak self] _ in
            guard let self else { return }

            if UIApplication.shared.applicationState == .active {
                if let media = self.media, media.type == .video, self.loopCount >= self.maxLoopCount {
                    self.stoppedBySystem()
                } else if !self.isSystemPaused {
                    self.loopCount += 1
                    self.player?.seek(to: CMTime.zero)
                    self.player?.play()
                }
            } else {
                self.stoppedBySystem()
            }
        }
    }

    private func removeLoopObserver() {
        if let observer = playerLoopObserver {
            NotificationCenter.default.removeObserver(observer)
            playerLoopObserver = nil
        }
    }

    private func observePlayerStatus(_ playerItem: AVPlayerItem) {
        playerStatusObserver = playerItem.observe(\AVPlayerItem.status) { [weak self] playerItem, _ in
            guard let self else { return }
            if playerItem.status == .readyToPlay {
                if let player, !player.isPlaying(), !self.isSensitive, !self.isSystemPaused {
                    player.play()
                }

                if self.loadingIndicator.isAnimating {
                    self.loadingIndicator.stopAnimating()
                }
            }
        }
    }

    private func observePlayerRate(_ player: AVPlayer) {
        playerRateObserver = player.observe(\AVPlayer.rate) { [weak self] player, _ in
            guard let self else { return }
            if player.rate.isZero {
                // Paused
                // When looping - rates switch from paused to playing at the end of each cycle.
                // To prevent the overlay to flash on each cycle we add this delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let player = self.player, !player.isPlaying(), self.systemPausedOverlay(self.variant).isHidden {
                        self.systemPausedOverlay(self.variant).isHidden = false
                        self.hideMuteButton()
                    }
                }
            } else {
                // Playing
                if !self.systemPausedOverlay(self.variant).isHidden {
                    self.systemPausedOverlay(self.variant).isHidden = true
                    self.showMuteButton()
                }
            }
        }
    }

    private func observePlayerMuteState(_ player: AVPlayer) {
        playerMuteObserver = player.observe(\AVPlayer.isMuted) { [weak self] player, _ in
            guard let self else { return }
            if player.isMuted {
                self.muteButton.setImage(FontAwesome.image(fromChar: "\u{f6a9}", color: .custom.linkText, size: 11, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
            } else {
                self.muteButton.setImage(FontAwesome.image(fromChar: "\u{f6a8}", color: .custom.linkText, size: 11, weight: .bold).withRenderingMode(.alwaysTemplate), for: .normal)
            }
        }
    }

    @objc func onPress() {
        if let player = player, let media = media, [.video, .gifv, .audio].contains(media.type) {
            let vc = CustomVideoPlayer()
            vc.allowsPictureInPicturePlayback = true
            vc.player = player
            vc.altText = media.description ?? ""
            GlobalStruct.inVideoPlayer = true
            getTopMostViewController()?.present(vc, animated: true) {
                vc.player?.play()
            }
        }
    }

    private func showMuteButton() {
        if let media = media {
            if media.type == .video || media.type == .audio {
                muteButton.isHidden = false
            } else if media.type == .gifv {
                muteButton.isHidden = true
            }
        }
    }

    private func hideMuteButton() {
        muteButton.isHidden = true
    }

    private func mute(_ player: AVPlayer) {
        player.isMuted = true
    }

    private func unmute(_ player: AVPlayer) {
        player.isMuted = false
    }

    @objc func systemPausedPress() {
        if variant == .thumbnail {
            onPress()
        } else {
            if let player = player {
                play()
                AVManager.shared.currentPlayer = player
                unmute(player)
            }
        }
    }

    @objc func mutePress() {
        if let player = player {
            if player.isMuted, player.currentItem?.tracks.first(where: { $0.assetTrack?.mediaType == .audio }) == nil {
                let alertController = UIAlertController(title: "This video has no sound", message: nil, preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default)
                alertController.addAction(okAction)
                getTopMostViewController()?.present(alertController, animated: true, completion: nil)
                return
            }

            if player.isMuted {
                unmute(player)
                AVManager.shared.currentPlayer = player
            } else {
                mute(player)
            }
        }
    }

    @objc func altPress() {
        if let altTextPopup = media?.description {
            triggerHapticImpact(style: .light)
            let alert = UIAlertController(title: nil, message: altTextPopup, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.copy", comment: ""), style: .default, handler: { _ in
                let pasteboard = UIPasteboard.general
                pasteboard.string = altTextPopup
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel, handler: { _ in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self
                presenter.sourceRect = bounds
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
    }

    @objc func hideSensitiveOverlay() {
        dismissedSensitiveOverlay = true
        triggerHapticImpact(style: .light)
        UIView.animate(withDuration: 0.13) { [weak self] in
            self?.sensitiveContentOverlay.alpha = 0
        } completion: { [weak self] _ in
            self?.sensitiveContentOverlay.removeFromSuperview()
        }

        play()
    }
}
