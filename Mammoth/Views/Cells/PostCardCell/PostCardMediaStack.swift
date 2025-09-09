//
//  PostCardMediaStack.swift
//  Mammoth
//
//  Created by Benoit Nolens on 12/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import AVFoundation
import SDWebImage
import UIKit

final class PostCardMediaStack: UIView {
    enum PostCardImageStackVariant {
        case fullSize
        case thumbnail
    }

    private var imageView = PostCardImage(variant: .thumbnail)
    private var videoView = PostCardVideo(variant: .thumbnail)
    private var backgroundCard = {
        let view = UIImageView()
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.layer.shouldRasterize = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.transform = CGAffineTransformConcat(
            .init(rotationAngle: CGFloat(Float.pi / 180.0) * 9),
            .init(translationX: 3, y: 0)
        )

        let overlay = UIView()
        overlay.backgroundColor = UIColor(red: 86.0 / 255.0, green: 86.0 / 255.0, blue: 86.0 / 255.0, alpha: 0.20)
        view.addSubview(overlay)
        overlay.pinEdges()

        return view
    }()

    private var media: Attachment?
    private var postCard: PostCardModel?
    private let variant: PostCardImageStackVariant

    init(variant: PostCardImageStackVariant = .thumbnail) {
        self.variant = variant
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        media = nil
        postCard = nil
        imageView.prepareForReuse()
        videoView.prepareForReuse()
        backgroundCard.sd_cancelCurrentImageLoad()
        backgroundCard.image = nil
        backgroundCard.isHidden = false
    }

    private func setupUI() {
        isOpaque = true
        layoutMargins = .zero
        isUserInteractionEnabled = true

        addSubview(backgroundCard)
        addSubview(imageView)
        addSubview(videoView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onPress))
        addGestureRecognizer(tapGesture)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        videoView.translatesAutoresizingMaskIntoConstraints = false

        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowPath = UIBezierPath(roundedRect: .init(origin: .zero, size: .init(width: 56, height: 56)), cornerRadius: 6).cgPath
        imageView.layer.shadowOpacity = 0.4
        imageView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        imageView.layer.shadowRadius = 2
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = false

        videoView.layer.shadowColor = UIColor.black.cgColor
        videoView.layer.shadowPath = UIBezierPath(roundedRect: .init(origin: .zero, size: .init(width: 56, height: 56)), cornerRadius: 6).cgPath
        videoView.layer.shadowOpacity = 0.4
        videoView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        videoView.layer.shadowRadius = 2
        videoView.backgroundColor = .clear
        videoView.isUserInteractionEnabled = false

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 56),
            imageView.heightAnchor.constraint(equalToConstant: 56),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),

            videoView.widthAnchor.constraint(equalToConstant: 56),
            videoView.heightAnchor.constraint(equalToConstant: 56),
            videoView.topAnchor.constraint(equalTo: topAnchor),
            videoView.leadingAnchor.constraint(equalTo: leadingAnchor),

            backgroundCard.widthAnchor.constraint(equalToConstant: 56),
            backgroundCard.heightAnchor.constraint(equalToConstant: 56),
            backgroundCard.topAnchor.constraint(equalTo: topAnchor),
            backgroundCard.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundCard.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }

    func configure(postCard: PostCardModel) {
        let shouldUpdate = media == nil || postCard.mediaAttachments.first != media!
        media = postCard.mediaAttachments.first
        self.postCard = postCard

        if let postCard = self.postCard {
            if postCard.isPrivateMention {
                backgroundColor = .custom.OVRLYSoftContrast
            } else if postCard.isTipAccount {
                // tip background.
            }
        } else {
            backgroundColor = .custom.background
        }

        if shouldUpdate {
            if let media = media {
                if media.type == .image {
                    imageView.configure(postCard: postCard)
                    imageView.isHidden = false
                    videoView.isHidden = true
                }

                if media.type == .video || media.type == .gifv || media.type == .audio {
                    videoView.configure(postCard: postCard)
                    videoView.isHidden = false
                    imageView.isHidden = true

                    videoView.pause()

                    // Audio is currenlty using a carousel view in large-mode.
                    // To make this work in small-mode using this image stack
                    // we hide the backgroundCard if it's an audio track alone.
                    // FIX: when audio has it's own view
                    if media.type == .audio, postCard.mediaAttachments.count == 1 {
                        backgroundCard.isHidden = true
                    }
                }

                if let second = (postCard.mediaAttachments.count > 1 ? postCard.mediaAttachments[1] : nil), let blurhash = second.blurhash, let decodedBlurImage = postCard.decodedBlurhashes[blurhash] {
                    backgroundCard.image = decodedBlurImage
                }
            }
        }
    }

    @objc func onPress() {
        if let originImage = imageView.image {
            // Open fullscreen image preview
            let images = postCard?.mediaAttachments.compactMap { attachment in
                guard attachment.type == .image else { return SKPhoto() }
                let photo = SKPhoto.photoWithImageURL(attachment.url ?? attachment.previewURL!)
                photo.shouldCachePhotoURLImage = false

                let imageFromCache = SDImageCache.shared.imageFromCache(forKey: attachment.url)
                let previewFromCache = SDImageCache.shared.imageFromCache(forKey: attachment.previewURL)

                var blurImage: UIImage? = nil
                if let blurhash = attachment.blurhash, imageFromCache == nil, let currentMedia = self.media, attachment.url != currentMedia.url, let decodedBlurImage = postCard?.decodedBlurhashes[blurhash] {
                    blurImage = decodedBlurImage
                }
                photo.underlyingImage = imageFromCache ?? previewFromCache ?? blurImage
                return photo
            } ?? [SKPhoto()]

            let descriptions = postCard?.mediaAttachments.map { $0.description ?? "" } ?? []

            let browser = SKPhotoBrowser(originImage: originImage,
                                         photos: images,
                                         animatedFromView: imageView,
                                         descriptions: descriptions,
                                         currentIndex: 0)
            SKPhotoBrowserOptions.enableSingleTapDismiss = false
            SKPhotoBrowserOptions.displayCounterLabel = false
            SKPhotoBrowserOptions.displayBackAndForwardButton = false
            SKPhotoBrowserOptions.displayAction = false
            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
            SKPhotoBrowserOptions.displayCloseButton = false
            SKPhotoBrowserOptions.displayStatusbar = false
            browser.initializePageIndex(0)
            getTopMostViewController()?.present(browser, animated: true, completion: {})

            // Preload other images
            PostCardModel.imageDecodeQueue.async { [weak self] in
                guard let self else { return }
                let prefetcher = SDWebImagePrefetcher.shared
                let urls = self.postCard?.mediaAttachments.compactMap { URL(string: $0.url ?? $0.previewURL!) }
                prefetcher.prefetchURLs(urls, progress: nil) { _, _ in
                    let images = self.postCard?.mediaAttachments.compactMap { attachment in
                        guard attachment.type == .image else { return nil }
                        let photo = SKPhoto.photoWithImageURL(attachment.url ?? attachment.previewURL!)
                        photo.shouldCachePhotoURLImage = false
                        photo.underlyingImage = SDImageCache.shared.imageFromCache(forKey: attachment.url)
                        return photo
                    } ?? [SKPhoto()]

                    DispatchQueue.main.async {
                        browser.photos = images
                        browser.reloadData()
                    }
                }
            }

        } else {
            // Open fullscreen video player
            if let mediaURLString = media?.url {
                if let mediaURL = URL(string: mediaURLString) {
                    let player = AVPlayer(url: mediaURL)

                    let vc = CustomVideoPlayer()
                    vc.allowsPictureInPicturePlayback = true
                    vc.player = player
                    vc.altText = media?.description ?? ""
                    GlobalStruct.inVideoPlayer = true
                    getTopMostViewController()?.present(vc, animated: true) {
                        vc.player?.play()
                    }
                }
            }
        }
    }
}
