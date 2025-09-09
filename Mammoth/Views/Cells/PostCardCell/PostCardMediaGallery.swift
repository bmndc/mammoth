//
//  PostCardMediaGallery.swift
//  Mammoth
//
//  Created by Benoit Nolens on 17/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

import SDWebImage
import UIKit
import UnifiedBlurHash

private let PostCardMediaGalleryHeight = min((UIScreen.main.bounds.width * 0.76) * (9.0 / 16.0), 260)

protocol PostCardMediaGalleryDelegate: AnyObject {
    func galleryItemForPhoto(withIndex index: Int) -> PostCardImage?
    func scrollGalleryToItem(atIndex index: Int, animated: Bool)
}

final class PostCardMediaGallery: UIView {
    private let scrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        view.layoutMargins = .zero
        view.isDirectionalLockEnabled = true
        view.delaysContentTouches = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    private let stackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 8.0
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var attachments: [Attachment]?
    private var postCard: PostCardModel?

    override init(frame _: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(scrollView)
        scrollView.pinEdges()

        scrollView.addSubview(stackView)
        stackView.pinEdges(to: scrollView)

        let scrollViewHeight = scrollView.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
        scrollViewHeight.isActive = true
        scrollViewHeight.priority = .defaultHigh

        let stackViewHeight = stackView.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
        stackViewHeight.isActive = true
        stackViewHeight.priority = .required
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isHidden == false, alpha == 1, attachments != nil else { return nil }
        let leadingInset = -86.0 // Inset needs to be >= leading inset from the edge of the cell to the gallery
        let trailingOffset = 800.0 // Offset needs to be >= trailing offset from the trailing edge of the gallery to the trailing edge of the cell
        let expendedBounds = CGRect(origin: bounds.insetBy(dx: leadingInset, dy: 0).origin,
                                    size: .init(width: bounds.width + trailingOffset, height: bounds.height))
        if expendedBounds.contains(point) {
            let convertedPoint = stackView.convert(point, from: self)
            // Accept touches outside the scrollview bounds,
            // if it's hitting scrollview content
            return stackView.hitTest(convertedPoint, with: event)
        }

        return nil
    }
}

extension PostCardMediaGallery {
    func prepareForReuse() {}

    func configure(postCard: PostCardModel) {
        let shouldUpdate = attachments == nil || postCard.mediaAttachments != attachments!
        attachments = postCard.mediaAttachments
        self.postCard = postCard

        if shouldUpdate {
            scrollView.setContentOffset(.zero, animated: false)
            for arrangedSubview in stackView.arrangedSubviews {
                stackView.removeArrangedSubview(arrangedSubview)
                arrangedSubview.removeFromSuperview()
            }

            attachments?.forEach { media in
                if media.type == .image {
                    let image = PostCardImage(inGallery: true)
                    image.configure(image: media, postCard: postCard)
                    image.galleryDelegate = self
                    self.stackView.addArrangedSubview(image)

                    let ratio = Double(media.meta?.small?.width ?? 16) / Double(media.meta?.small?.height ?? 9)

                    let heightAnchor = image.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
                    heightAnchor.priority = .defaultHigh
                    heightAnchor.isActive = true
                    let widthAnchor = image.widthAnchor.constraint(equalTo: image.heightAnchor, multiplier: ratio)
                    widthAnchor.isActive = true
                    widthAnchor.priority = .defaultHigh
                }

                if media.type == .video || media.type == .gifv || media.type == .audio {
                    let video = PostCardVideo(inGallery: true)
                    video.configure(video: media, postCard: postCard)
                    video.pause()
                    self.stackView.addArrangedSubview(video)

                    let heightAnchor = video.heightAnchor.constraint(equalToConstant: PostCardMediaGalleryHeight)
                    heightAnchor.priority = .defaultHigh
                    heightAnchor.isActive = true
                }
            }
        }
    }
}

extension PostCardMediaGallery: PostCardMediaGalleryDelegate {
    func galleryItemForPhoto(withIndex index: Int) -> PostCardImage? {
        if let item = stackView.arrangedSubviews[index] as? PostCardImage {
            return item
        }

        return nil
    }

    func scrollGalleryToItem(atIndex index: Int, animated: Bool) {
        if let activeItem = stackView.arrangedSubviews[index] as? PostCardImage {
            guard scrollView.contentSize.width > scrollView.frame.size.width else { return }
            let maxOffset = scrollView.contentSize.width - scrollView.frame.size.width
            scrollView.setContentOffset(.init(x: min(activeItem.frame.origin.x, maxOffset), y: 0), animated: animated)
        } else {
            scrollView.setContentOffset(.zero, animated: animated)
        }
    }
}
