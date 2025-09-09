//
//  PostCardQuotePost.swift
//  Mammoth
//
//  Created by Benoit Nolens on 07/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import MastodonMeta
import Meta
import MetaTextKit
import UIKit

class PostCardQuotePost: UIView {
    // MARK: - Properties

    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 4.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .custom.background

        stackView.layer.borderWidth = 1.0 / UIScreen.main.scale
        stackView.layer.allowsEdgeAntialiasing = false
        stackView.layer.edgeAntialiasingMask = [.layerBottomEdge, .layerTopEdge, .layerLeftEdge, .layerRightEdge]
        stackView.layer.needsDisplayOnBoundsChange = false
        stackView.layer.rasterizationScale = UIScreen.main.scale
        stackView.layer.contentsScale = UIScreen.main.scale

        stackView.layer.borderColor = UIColor.custom.outlines.cgColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 10
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 13, trailing: 0)

        return stackView
    }()

    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 4.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)

        return stackView
    }()

    // Includes text, small media
    private var textAndSmallMediaStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.isOpaque = true
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()

    private var header = PostCardHeader()
    private var headerTrailingConstraint: NSLayoutConstraint?

    private var mediaContainerConstraints: [NSLayoutConstraint]? = []

    private var postTextLabel: MetaLabel = {
        let metaText = MetaLabel()
        metaText.isOpaque = true
        metaText.backgroundColor = .custom.background
        metaText.translatesAutoresizingMaskIntoConstraints = false
        metaText.textContainer.lineFragmentPadding = 0
        metaText.numberOfLines = 4
        metaText.textContainer.maximumNumberOfLines = 4
        metaText.textContainer.lineBreakMode = .byTruncatingTail
        return metaText
    }()

    // Contains image attachment, poll, and/or link preview if needed
    private var mediaContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        return stackView
    }()

    private var postCard: PostCardModel?
    var onPress: PostCardButtonCallback?

    private var poll: PostCardPoll?
    private var pollTrailingConstraint: NSLayoutConstraint?

    private var thumbnailImage: PostCardImage?
    private var thumbnailImageTrailingConstraint: NSLayoutConstraint?

    private var image: PostCardImage?
    private var imageTrailingConstraint: NSLayoutConstraint?

    private var thumbnailVideo: PostCardVideo?
    private var thumbnailVideoTrailingConstraint: NSLayoutConstraint?

    private var video: PostCardVideo?
    private var videoTrailingConstraint: NSLayoutConstraint?

    private var mediaGallery: PostCardMediaGallery?
    private var mediaGalleryTrailingConstraint: NSLayoutConstraint?

    private var mediaStack: PostCardMediaStack?
    private var mediaStackTrailingConstraint: NSLayoutConstraint?

    private var linkPreview: PostCardLinkPreview?
    private var linkPreviewTrailingConstraint: NSLayoutConstraint?

    private var quoteIndicator: PostCardQuoteIndicator?
    private var quoteIndicatorTrailingConstraint: NSLayoutConstraint?

    private var postNotFound: PostCardQuoteNotFound?
    private var postNotFoundTrailingConstraint: NSLayoutConstraint?

    private var postLoader: PostCardQuoteActivityIndicator?
    private var postLoaderTrailingConstraint: NSLayoutConstraint?

    private let mediaVariant: PostCardCell.PostCardMediaVariant

    init(mediaVariant: PostCardCell.PostCardMediaVariant = .large) {
        self.mediaVariant = mediaVariant
        super.init(frame: .zero)
        setupUI()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        mainStackView.addGestureRecognizer(tapGesture)

        let contextMenu = UIContextMenuInteraction(delegate: self)
        mainStackView.addInteraction(contextMenu)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        postCard = nil
        onPress = nil
        isUserInteractionEnabled = true

        header.prepareForReuse()
        header.isHidden = true
        headerTrailingConstraint?.isActive = false

        mainStackView.directionalLayoutMargins.bottom = 13
        mediaContainer.directionalLayoutMargins.leading = 12
        mediaContainer.directionalLayoutMargins.trailing = 12

        postTextLabel.reset()
        postTextLabel.isHidden = true

        if let poll = poll {
            poll.prepareForReuse()
            poll.isHidden = true
            pollTrailingConstraint?.isActive = false
        }

        if let image = image, mediaContainer.arrangedSubviews.contains(image) {
            image.prepareForReuse()
            image.isHidden = true
            imageTrailingConstraint?.isActive = false
        }

        if let image = thumbnailImage {
            image.prepareForReuse()
            image.isHidden = true
            thumbnailImageTrailingConstraint?.isActive = false
        }

        if let video = thumbnailVideo {
            video.prepareForReuse()
            video.isHidden = true
            thumbnailVideoTrailingConstraint?.isActive = false
        }

        if let video = video {
            video.prepareForReuse()
            video.isHidden = true
            videoTrailingConstraint?.isActive = false
        }

        if let mediaStack = mediaStack {
            mediaStack.prepareForReuse()
            mediaStack.isHidden = true
            mediaStackTrailingConstraint?.isActive = false
        }

        if let mediaGallery = mediaGallery {
            mediaGallery.prepareForReuse()
            mediaGallery.isHidden = true
            mediaGalleryTrailingConstraint?.isActive = false
        }

        if let linkPreview = linkPreview {
            linkPreview.prepareForReuse()
            linkPreview.isHidden = true
            linkPreviewTrailingConstraint?.isActive = false
        }

        if let quoteIndicator = quoteIndicator {
            quoteIndicator.isHidden = true
            quoteIndicatorTrailingConstraint?.isActive = false
        }

        if let postNotFound = postNotFound {
            postNotFound.isHidden = true
            postNotFoundTrailingConstraint?.isActive = false
        }

        if let postLoader = postLoader {
            postLoader.isHidden = true
            postLoaderTrailingConstraint?.isActive = false
        }
    }

    func setupUIFromSettings() {
        postTextLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        postTextLabel.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        postTextLabel.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 12
            style.alignment = .natural
            return style
        }()
    }
}

// MARK: - Setup UI

private extension PostCardQuotePost {
    func setupUI() {
        isOpaque = true
        addSubview(mainStackView)

        mainStackView.addArrangedSubview(contentStackView)

        header.isUserInteractionEnabled = false
        contentStackView.insertArrangedSubview(header, at: 0)
        headerTrailingConstraint = header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -contentStackView.directionalLayoutMargins.trailing)

        contentStackView.addArrangedSubview(textAndSmallMediaStackView)

        postTextLabel.isUserInteractionEnabled = false
        postTextLabel.isHidden = true
        textAndSmallMediaStackView.addArrangedSubview(postTextLabel)

        mainStackView.addArrangedSubview(mediaContainer)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Poll
            self.poll = PostCardPoll()
            self.poll!.isUserInteractionEnabled = false
            self.poll!.isHidden = true
            self.mediaContainer.addArrangedSubview(self.poll!)
            self.pollTrailingConstraint = self.poll!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)

            // Thumbnail image
            self.thumbnailImage = PostCardImage(variant: .thumbnail)
            self.thumbnailImage!.translatesAutoresizingMaskIntoConstraints = false
            self.thumbnailImage!.isHidden = true
            self.textAndSmallMediaStackView.addArrangedSubview(self.thumbnailImage!)
            self.thumbnailImageTrailingConstraint = self.thumbnailImage!.widthAnchor.constraint(equalToConstant: 60)

            // Fullsize image
            self.image = PostCardImage(variant: .fullSize)
            self.image!.translatesAutoresizingMaskIntoConstraints = false
            self.image!.isHidden = true
            self.mediaContainer.addArrangedSubview(self.image!)
            self.imageTrailingConstraint = self.image!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)

            // Thumbnail video
            self.thumbnailVideo = PostCardVideo(variant: .thumbnail)
            self.thumbnailVideo!.translatesAutoresizingMaskIntoConstraints = false
            self.thumbnailVideo!.isHidden = true
            self.textAndSmallMediaStackView.addArrangedSubview(self.thumbnailVideo!)
            self.thumbnailVideoTrailingConstraint = self.thumbnailVideo!.widthAnchor.constraint(equalToConstant: 60)

            // Fullsize video
            self.video = PostCardVideo(variant: .fullSize)
            self.video!.translatesAutoresizingMaskIntoConstraints = false
            self.video!.isHidden = true
            self.mediaContainer.addArrangedSubview(self.video!)
            self.videoTrailingConstraint = self.video!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)

            // Media stack
            self.mediaStack = PostCardMediaStack(variant: .thumbnail)
            self.mediaStack?.translatesAutoresizingMaskIntoConstraints = false
            self.mediaStack?.isHidden = true
            self.textAndSmallMediaStackView.addArrangedSubview(self.mediaStack!)
            self.mediaStackTrailingConstraint = self.mediaStack!.widthAnchor.constraint(equalToConstant: 60)

            // Media gallery
            self.mediaGallery = PostCardMediaGallery()
            self.mediaGallery?.isHidden = true
            self.mediaGallery?.translatesAutoresizingMaskIntoConstraints = false
            self.mediaContainer.addArrangedSubview(self.mediaGallery!)
            self.mediaGalleryTrailingConstraint = self.mediaGallery!.trailingAnchor.constraint(equalTo: self.mediaContainer.layoutMarginsGuide.trailingAnchor)

            // Link
            self.linkPreview = PostCardLinkPreview()
            self.linkPreview!.isUserInteractionEnabled = false
            self.linkPreview!.isHidden = true
            self.mediaContainer.addArrangedSubview(self.linkPreview!)
            self.linkPreviewTrailingConstraint = self.linkPreview!.trailingAnchor.constraint(equalTo: self.mediaContainer.trailingAnchor, constant: -self.mediaContainer.directionalLayoutMargins.trailing)

            NSLayoutConstraint.activate([
                // Force content container to fill the parent width
                self.contentStackView.trailingAnchor.constraint(equalTo: self.mainStackView.trailingAnchor),
                self.textAndSmallMediaStackView.trailingAnchor.constraint(equalTo: self.contentStackView.layoutMarginsGuide.trailingAnchor),

                // Force media container to fill the parent width
                self.mediaContainer.trailingAnchor.constraint(equalTo: self.mainStackView.trailingAnchor),
            ])
        }

        quoteIndicator = PostCardQuoteIndicator()
        quoteIndicator!.isUserInteractionEnabled = false
        quoteIndicator!.isHidden = true
        mainStackView.addArrangedSubview(quoteIndicator!)
        quoteIndicatorTrailingConstraint = quoteIndicator!.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant: -mainStackView.directionalLayoutMargins.trailing)

        // Post loader
        postLoader = PostCardQuoteActivityIndicator()
        postLoader!.isUserInteractionEnabled = false
        postLoader!.isHidden = true
        contentStackView.addArrangedSubview(postLoader!)
        postLoaderTrailingConstraint = postLoader!.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -contentStackView.directionalLayoutMargins.trailing)

        // Post not found
        postNotFound = PostCardQuoteNotFound()
        postNotFound!.isHidden = true
        postNotFound!.isUserInteractionEnabled = false
        postNotFound!.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(postNotFound!)
        postNotFoundTrailingConstraint = postNotFound!.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -contentStackView.directionalLayoutMargins.trailing)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        setupUIFromSettings()
    }
}

// MARK: - Configuration

extension PostCardQuotePost {
    func configure(postCard: PostCardModel) {
        self.postCard = postCard
        isUserInteractionEnabled = true

        // If a quote post status is found and loaded
        if let quotePostCard = postCard.quotePostData {
            postLoader?.isHidden = true
            postLoader?.stopAnimation()

            // Display header
            header.configure(postCard: quotePostCard, headerType: .quotePost)
            header.willDisplay()
            header.isHidden = false
            headerTrailingConstraint?.isActive = true

            // Display post text
            if let postTextContent = quotePostCard.metaPostText, !postTextContent.original.isEmpty {
                postTextLabel.configure(content: postTextContent)
                postTextLabel.isHidden = false
            } else if [.small, .hidden].contains(mediaVariant) {
                // If there's no post text, but a media attachment,
                // set the post text to either:
                //  - ([type])
                //  - ([type] description: [meta description])
                if let type = quotePostCard.mediaDisplayType.captializedDisplayName {
                    if let desc = quotePostCard.mediaAttachments.first?.description {
                        let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type) description: \(desc))", emojis: [:]))
                        postTextLabel.configure(content: content)
                        postTextLabel.isHidden = false
                    } else {
                        let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type))", emojis: [:]))
                        postTextLabel.configure(content: content)
                        postTextLabel.isHidden = false
                    }
                } else {
                    postTextLabel.isHidden = true
                }
            } else {
                postTextLabel.isHidden = true
            }

            // Display poll if needed
            if quotePostCard.containsPoll {
                poll?.configure(postCard: quotePostCard)
                poll?.isHidden = false
                pollTrailingConstraint?.isActive = true
            }

            // Display the link preview if needed
            if quotePostCard.hasLink, !quotePostCard.hasQuotePost {
                linkPreview?.configure(postCard: quotePostCard)
                linkPreview?.isHidden = false
                linkPreviewTrailingConstraint?.isActive = true
                linkPreview?.onPress = onPress
            }

            // display recursive quote indicator.
            if quotePostCard.hasQuotePost {
                quoteIndicator!.isHidden = false
                quoteIndicatorTrailingConstraint?.isActive = true
            }

            // Display single image if needed
            if quotePostCard.hasMediaAttachment, quotePostCard.mediaDisplayType == .singleImage, !quotePostCard.hasWebview {
                switch mediaVariant {
                case .small:
                    thumbnailImage?.configure(postCard: quotePostCard)
                    thumbnailImage?.isHidden = false
                    thumbnailImageTrailingConstraint?.isActive = true

                    image?.isHidden = true
                    imageTrailingConstraint?.isActive = false
                case .large, .fullWidth:
                    image?.configure(postCard: quotePostCard)
                    image?.isHidden = false
                    imageTrailingConstraint?.isActive = true

                    thumbnailImage?.isHidden = true
                    thumbnailImageTrailingConstraint?.isActive = false
                default: break
                }
            }

            // Display single video/gif if needed
            if quotePostCard.hasMediaAttachment, [.singleVideo, .singleGIF].contains(quotePostCard.mediaDisplayType) {
                switch mediaVariant {
                case .small:
                    thumbnailVideo?.isHidden = false
                    thumbnailVideo?.configure(postCard: quotePostCard)
                    thumbnailVideo?.pause()
                    thumbnailVideoTrailingConstraint?.isActive = true

                    video?.isHidden = true
                    videoTrailingConstraint?.isActive = false
                case .large, .fullWidth:
                    video?.isHidden = false
                    video?.configure(postCard: quotePostCard)
                    videoTrailingConstraint?.isActive = true

                    thumbnailVideo?.isHidden = true
                    thumbnailVideoTrailingConstraint?.isActive = false
                default:
                    video?.isHidden = true
                    videoTrailingConstraint?.isActive = false
                    thumbnailVideo?.isHidden = true
                    thumbnailVideoTrailingConstraint?.isActive = false
                }
            }

            // Display the image carousel if needed
            if quotePostCard.hasMediaAttachment, quotePostCard.mediaDisplayType == .carousel {
                switch mediaVariant {
                case .small:
                    mediaStack?.isHidden = false
                    mediaStack?.configure(postCard: quotePostCard)
                    mediaStackTrailingConstraint?.isActive = true

                    mediaGallery?.isHidden = true
                    mediaGalleryTrailingConstraint?.isActive = false
                case .large, .fullWidth:
                    mediaGallery?.isHidden = false
                    mediaGallery?.configure(postCard: quotePostCard)
                    mediaGalleryTrailingConstraint?.isActive = true

                    mediaStack?.isHidden = true
                    mediaStackTrailingConstraint?.isActive = false
                default:
                    mediaGallery?.isHidden = true
                    mediaGalleryTrailingConstraint?.isActive = false
                    mediaStack?.isHidden = true
                    mediaStackTrailingConstraint?.isActive = false
                }
            }
        }

        if postCard.quotePostStatus == .notFound {
            postLoader?.isHidden = true
            postLoader?.stopAnimation()

            // Quote post can't be found
            postNotFound?.isHidden = false
            isUserInteractionEnabled = false
            postNotFoundTrailingConstraint?.isActive = true
            mainStackView.directionalLayoutMargins.bottom = 10

            header.isHidden = true
            headerTrailingConstraint?.isActive = false
            postTextLabel.isHidden = true
        }

        if postCard.quotePostStatus == .loading {
            // Quote post is being loaded
            postLoader?.isHidden = false
            postLoader?.startAnimation()
            postLoaderTrailingConstraint?.isActive = true
            mainStackView.directionalLayoutMargins.bottom = 10

            postNotFound?.isHidden = true
            postNotFoundTrailingConstraint?.isActive = false

            header.isHidden = true
            headerTrailingConstraint?.isActive = false
            postTextLabel.isHidden = true
        }
    }

    func onThemeChange() {
        mainStackView.layer.borderColor = UIColor.custom.outlines.cgColor

        header.onThemeChange()
        linkPreview?.onThemeChange()
        poll?.onThemeChange()
        postNotFound?.onThemeChange()

        setupUIFromSettings()

        postTextLabel.backgroundColor = .custom.background
        mainStackView.backgroundColor = .custom.background
    }

    func willDisplay() {
        header.willDisplay()
    }
}

// MARK: - Handlers

extension PostCardQuotePost {
    @objc func onTapped() {
        if let quotedPost = postCard?.quotePostData {
            onPress?(.postDetails, true, .post(quotedPost))
        }
    }
}

// MARK: - Context menu creators

extension PostCardQuotePost: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        if let postCard = postCard, let onButtonPress = onPress {
            if let urlStr = postCard.quotePostCard?.url, let url = URL(string: urlStr) {
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [weak self] _ in
                    guard let self else { return UIMenu() }

                    let options = [
                        self.createContextMenuAction(NSLocalizedString("post.openLink", comment: ""), .link, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction(NSLocalizedString("generic.copy", comment: ""), .copy, isActive: false, data: .url(url), onPress: onButtonPress),
                        self.createContextMenuAction(NSLocalizedString("generic.share", comment: ""), .share, isActive: false, data: .url(url), onPress: onButtonPress),
                    ].compactMap { $0 }

                    return UIMenu(title: "", options: [.displayInline], children: options)
                })
            }
        }

        return nil
    }

    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, data: PostCardButtonCallbackData?, onPress: @escaping PostCardButtonCallback) -> UIAction {
        let action = UIAction(title: title,
                              image: buttonType.icon(symbolConfig: postCardSymbolConfig),
                              identifier: nil)
        { _ in
            onPress(buttonType, isActive, data)
        }
        action.accessibilityLabel = title
        return action
    }
}

// MARK: - Child views

private class PostCardQuoteNotFound: UIStackView {
    private var leftAttribute: UIImageView = {
        let imageView = UIImageView()
        imageView.image = FontAwesome.image(fromChar: "\u{f10d}", color: .secondaryLabel, size: 15, weight: .bold)
        return imageView
    }()

    private var rightAttribute: UIImageView = {
        let imageView = UIImageView()
        imageView.image = FontAwesome.image(fromChar: "\u{f05a}", color: .custom.baseTint, size: 15)
        return imageView
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.mediumContrast
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 8.0

        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0)

        titleLabel.text = NSLocalizedString("post.quote.notFound", comment: "")

        addArrangedSubview(leftAttribute)
        addArrangedSubview(titleLabel)
        addArrangedSubview(rightAttribute)

        // Don't compress but let siblings fill the space
        leftAttribute.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        leftAttribute.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)

        // Don't compress but let siblings fill the space
        rightAttribute.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        rightAttribute.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
    }

    func onThemeChange() {
        leftAttribute.image = FontAwesome.image(fromChar: "\u{f10d}", color: .secondaryLabel, size: 15, weight: .bold)
        rightAttribute.image = FontAwesome.image(fromChar: "\u{f05a}", color: .custom.baseTint, size: 15)
    }
}

private class PostCardQuoteActivityIndicator: UIStackView {
    private var activityIndicator: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        return loader
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 0.0

        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0)

        addArrangedSubview(activityIndicator)
    }

    func startAnimation() {
        activityIndicator.startAnimating()
    }

    func stopAnimation() {
        if activityIndicator.isAnimating {
            activityIndicator.stopAnimating()
        }
    }

    func onThemeChange() {}
}

private class PostCardQuoteIndicator: UIStackView {
    private var leftAttribute: UIImageView = {
        let imageView = UIImageView()
        imageView.image = FontAwesome.image(fromChar: "\u{f10d}", color: .custom.feintContrast, size: 15, weight: .bold)
        return imageView
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.feintContrast
        label.text = NSLocalizedString("post.quote.quoting", comment: "")
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 8.0

        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 0, trailing: 0)

        addArrangedSubview(leftAttribute)
        addArrangedSubview(titleLabel)

        // Don't compress but let siblings fill the space
        leftAttribute.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        leftAttribute.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
    }

    func onThemeChange() {
        titleLabel.textColor = .custom.feintContrast
        leftAttribute.image = FontAwesome.image(fromChar: "\u{f10d}", color: .custom.feintContrast, size: 15, weight: .bold)
    }
}
