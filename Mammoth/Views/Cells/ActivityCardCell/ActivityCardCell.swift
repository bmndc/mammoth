//
//  ActivityCardCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 01/09/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import MastodonMeta
import MetaTextKit
import UIKit

final class ActivityCardCell: UITableViewCell {
    static let reuseIdentifier = "ActivityCardCell"

    // MARK: - Properties

    // Includes the header extension and the rest of the cell
    private var wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 6.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // Basic cell columns: profile pic, and cell content
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.spacing = 11.0
        stackView.preservesSuperviewLayoutMargins = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // Includes header, text, media
    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.isOpaque = true
        stackView.layoutMargins = .zero
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

    private let profilePic = PostCardProfilePic(withSize: .regular)
    private let header = ActivityCardHeader()

    private var postTextLabel: MetaLabel = {
        let label = MetaLabel()
        label.textColor = .custom.mediumContrast
        label.isOpaque = true
        label.numberOfLines = 2
        label.textContainer.lineFragmentPadding = 0
        label.textContainer.maximumNumberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false

        label.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]

        label.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        label.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 12
            style.alignment = .natural
            return style
        }()

        return label
    }()

    // Contains image attachment, poll, and/or link preview if needed
    private var mediaContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.layoutMargins = .zero
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()

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

    private var mediaStack: PostCardMediaStack?
    private var mediaStackTrailingConstraint: NSLayoutConstraint?

    private var mediaGallery: PostCardMediaGallery?
    private var mediaGalleryTrailingConstraint: NSLayoutConstraint?

    private var linkPreview: PostCardLinkPreview?
    private var linkPreviewTrailingConstraint: NSLayoutConstraint?

    private var quotePost: PostCardQuotePost?
    private var quotePostTrailingConstraint: NSLayoutConstraint?

    private var activityCard: ActivityCardModel?
    private var onButtonPress: PostCardButtonCallback?

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setupUIFromSettings),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        activityCard = nil
        profilePic.prepareForReuse()
        postTextLabel.reset()
        postTextLabel.isUserInteractionEnabled = true

        header.prepareForReuse()
        resetMedia()

        contentStackView.setCustomSpacing(0, after: textAndSmallMediaStackView)
    }

    private func resetMedia() {
        thumbnailImage?.prepareForReuse()
        thumbnailImage?.isHidden = true
        imageTrailingConstraint?.isActive = true

        image?.prepareForReuse()
        image?.isHidden = true
        imageTrailingConstraint?.isActive = false

        video?.prepareForReuse()
        video?.isHidden = true
        videoTrailingConstraint?.isActive = false

        thumbnailVideo?.prepareForReuse()
        thumbnailVideo?.isHidden = true
        thumbnailVideoTrailingConstraint?.isActive = false

        mediaStack?.prepareForReuse()
        mediaStack?.isHidden = true
        mediaStackTrailingConstraint?.isActive = false

        mediaGallery?.prepareForReuse()
        mediaGallery?.isHidden = true
        mediaGalleryTrailingConstraint?.isActive = false

        linkPreview!.prepareForReuse()
        linkPreview!.isHidden = true
        linkPreviewTrailingConstraint?.isActive = false

        poll!.prepareForReuse()
        poll!.isHidden = true
        pollTrailingConstraint?.isActive = false

        quotePost!.prepareForReuse()
        quotePost!.isHidden = true
        quotePostTrailingConstraint?.isActive = false
    }

    /// the cell will be displayed in the tableview
    func willDisplay() {
        if let postCard = activityCard?.postCard, postCard.hasMediaAttachment, [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
            if GlobalStruct.autoPlayVideos {
                video?.play()
            }
        }

        if let postCard = activityCard?.postCard, postCard.hasQuotePost {
            postCard.preloadQuotePost()
        }

        profilePic.willDisplay()
        header.startTimeUpdates()
    }

    // the cell will end being displayed in the tableview
    func didEndDisplay() {
        if let postCard = activityCard?.postCard, postCard.hasMediaAttachment, [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
            video?.pause()
        }

        if let postCard = activityCard?.postCard, postCard.hasQuotePost, let quotePostCard = postCard.quotePostData, let video = quotePostCard.videoPlayer {
            video.pause()
        }

        header.stopTimeUpdates()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        if let mediaGallery = mediaGallery,
           activityCard?.postCard?.mediaDisplayType == .carousel,
           mediaGallery.isHidden == false,
           mediaGallery.alpha == 1
        {
            let convertedPoint = mediaGallery.convert(point, from: self)
            return mediaGallery.hitTest(convertedPoint, with: event) ?? hitView
        }

        return hitView
    }
}

// MARK: - Setup UI

private extension ActivityCardCell {
    func setupUI() {
        selectionStyle = .none
        separatorInset = .zero
        layoutMargins = .zero
        contentView.preservesSuperviewLayoutMargins = false
        isOpaque = true
        contentView.isOpaque = true
        contentView.layoutMargins = .init(top: 18, left: 13, bottom: 18, right: 13)

        contentView.addSubview(wrapperStackView)
        wrapperStackView.addArrangedSubview(mainStackView)

        NSLayoutConstraint.activate([
            wrapperStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            wrapperStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            wrapperStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            wrapperStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            // Force main stack view to fill the parent width
            mainStackView.trailingAnchor.constraint(equalTo: wrapperStackView.layoutMarginsGuide.trailingAnchor),
        ])

        mainStackView.addArrangedSubview(profilePic)
        mainStackView.addArrangedSubview(contentStackView)

        contentStackView.addArrangedSubview(header)
        contentStackView.addArrangedSubview(textAndSmallMediaStackView)
        textAndSmallMediaStackView.addArrangedSubview(postTextLabel)
        contentStackView.addArrangedSubview(mediaContainer)

        postTextLabel.linkDelegate = self

        let postTextTrailing = postTextLabel.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor)
        postTextTrailing.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // Force header to fill the parent width
            header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            // Force post text to fill the parent width
            postTextTrailing,
        ])

        // Force media container to fill the parent width - with max width for big displays
        mediaContainer.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 340)

        // Poll
        poll = PostCardPoll()
        poll!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(poll!)
        pollTrailingConstraint = poll!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
        poll!.isHidden = true

        // Quote Post
        quotePost = PostCardQuotePost(mediaVariant: .small)
        quotePost!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(quotePost!)
        quotePostTrailingConstraint = quotePost!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
        quotePost!.isHidden = true

        // Link Preview
        linkPreview = PostCardLinkPreview()
        linkPreview!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(linkPreview!)
        linkPreviewTrailingConstraint = linkPreview!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
        linkPreview!.isHidden = true

        // Thumbnail image
        thumbnailImage = PostCardImage(variant: .thumbnail)
        thumbnailImage!.translatesAutoresizingMaskIntoConstraints = false
        textAndSmallMediaStackView.addArrangedSubview(thumbnailImage!)
        thumbnailImageTrailingConstraint = thumbnailImage!.widthAnchor.constraint(equalToConstant: 60)
        thumbnailImage!.isHidden = true

        // Full size image
        image = PostCardImage(variant: .fullSize)
        image!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(image!)
        imageTrailingConstraint = image!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
        image!.isHidden = true

        // Thumbnail video
        thumbnailVideo = PostCardVideo(variant: .thumbnail)
        thumbnailVideo!.translatesAutoresizingMaskIntoConstraints = false
        textAndSmallMediaStackView.addArrangedSubview(thumbnailVideo!)
        thumbnailVideoTrailingConstraint = thumbnailVideo!.widthAnchor.constraint(equalToConstant: 60)
        thumbnailVideo!.isHidden = true

        // Full size video
        video = PostCardVideo(variant: .fullSize)
        video!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(video!)
        videoTrailingConstraint = video!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
        video!.isHidden = true

        // Media Stack
        mediaStack = PostCardMediaStack(variant: .thumbnail)
        mediaStack!.translatesAutoresizingMaskIntoConstraints = false
        textAndSmallMediaStackView.addArrangedSubview(mediaStack!)
        mediaStackTrailingConstraint = mediaStack!.widthAnchor.constraint(equalToConstant: 60)
        mediaStack!.isHidden = true

        // Media Gallery
        mediaGallery = PostCardMediaGallery()
        mediaGallery!.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addArrangedSubview(mediaGallery!)
        mediaGalleryTrailingConstraint = mediaGallery!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
        mediaGallery!.isHidden = true

        setupUIFromSettings()
    }

    @objc func setupUIFromSettings() {
        postTextLabel.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]
        configurePostTextLabelAttributes()

        postTextLabel.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 12
            style.alignment = .natural
            return style
        }()

        header.setupUIFromSettings()
        linkPreview?.setupUIFromSettings()
        quotePost?.setupUIFromSettings()

        onThemeChange()
    }

    func configurePostTextLabelAttributes() {
        let linkAttributeColor: UIColor
        let linkAttributeWeight: UIFont.Weight
        if let cardType = activityCard?.type {
            switch cardType {
            case .follow, .follow_request:
                linkAttributeColor = UIColor.custom.mediumContrast
                linkAttributeWeight = .regular
            default:
                linkAttributeColor = UIColor.custom.highContrast
                linkAttributeWeight = .semibold
            }
            postTextLabel.linkAttributes = [
                .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: linkAttributeWeight),
                .foregroundColor: linkAttributeColor,
            ]
        }
    }
}

// MARK: - Configuration

extension ActivityCardCell {
    func configure(activity: ActivityCardModel, onButtonPress: @escaping PostCardButtonCallback) {
        activityCard = activity
        self.onButtonPress = onButtonPress

        let cellVariant = activity.postCard != nil ? PostCardCell.PostCardVariant.cellVariant(for: activity.postCard!, cellType: .regular) : nil

        profilePic.configure(user: activity.user, badgeIcon: mapTypeTBadgeImage(activity: activity))
        profilePic.onPress = onButtonPress

        let isVerticallyCentered = activity.postCard?.mediaDisplayType == .carousel
            && ((activity.postCard?.postText ?? "")?.isEmpty ?? false)
            && cellVariant?.mediaVariant == .large
            && activity.type == .status

        header.configure(activity: activity, isVerticallyCentered: isVerticallyCentered)
        header.onPress = onButtonPress

        configurePostTextLabelAttributes()
        switch activity.type {
        case .follow, .follow_request:
            let content = MastodonContent(content: activity.user.userTag, emojis: [:])
            postTextLabel.configure(content: MastodonMetaContent.convert(text: content))
            postTextLabel.isUserInteractionEnabled = false
            postTextLabel.isHidden = false
        default:
            if let content = activity.postCard?.metaPostText {
                if !content.original.isEmpty {
                    postTextLabel.configure(content: content)
                    postTextLabel.isHidden = false

                } else if [.small, .hidden].contains(cellVariant?.mediaVariant), activity.type == .status {
                    // If there's no post text, but a media attachment,
                    // set the post text to either:
                    //  - ([type])
                    //  - ([type] description: [meta description])
                    if let type = activity.postCard?.mediaDisplayType.captializedDisplayName {
                        if let desc = activity.postCard?.mediaAttachments.first?.description {
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
            }
        }

        if let postCard = activity.postCard {
            let hideMedia = [.favourite, .reblog].contains(activity.type)

            if activity.type == .status {
                if postTextLabel.textContainer.maximumNumberOfLines != GlobalStruct.maxLines {
                    postTextLabel.textContainer.maximumNumberOfLines = GlobalStruct.maxLines
                }
            }

            // Display poll if needed
            if postCard.containsPoll, !hideMedia {
                poll!.configure(postCard: postCard)
                poll!.isHidden = false
                pollTrailingConstraint?.isActive = true
            } else {
                poll!.isHidden = true
                pollTrailingConstraint?.isActive = false
            }

            // Display the quote post preview if needed
            if postCard.hasQuotePost, !hideMedia {
                quotePost!.configure(postCard: postCard)
                quotePost!.onPress = onButtonPress
                quotePost!.isHidden = false
                quotePostTrailingConstraint?.isActive = true
            } else {
                quotePost!.isHidden = true
                quotePostTrailingConstraint?.isActive = false
            }

            // Display the link preview if needed
            if postCard.hasLink, !postCard.hasQuotePost {
                linkPreview!.configure(postCard: postCard)
                linkPreview!.onPress = onButtonPress
                linkPreview!.isHidden = false
                linkPreviewTrailingConstraint?.isActive = true
            } else {
                linkPreview!.isHidden = true
                linkPreviewTrailingConstraint?.isActive = false
            }

            // Display single image if needed
            if postCard.hasMediaAttachment, postCard.mediaDisplayType == .singleImage, !hideMedia {
                if activity.type == .status, let postCard = activity.postCard {
                    switch cellVariant?.mediaVariant {
                    case .small:
                        thumbnailImage?.configure(postCard: postCard)
                        thumbnailImage?.isHidden = false
                        thumbnailImageTrailingConstraint?.isActive = true
                    case .large, .fullWidth:
                        image?.configure(postCard: postCard)
                        image?.isHidden = false
                        imageTrailingConstraint?.isActive = true
                    default:
                        thumbnailImage?.isHidden = true
                        thumbnailImageTrailingConstraint?.isActive = false
                        image?.isHidden = true
                        imageTrailingConstraint?.isActive = false
                    }
                } else {
                    thumbnailImage?.configure(postCard: postCard)
                    thumbnailImage?.isHidden = false
                    thumbnailImageTrailingConstraint?.isActive = true
                }
            } else {
                thumbnailImage?.isHidden = true
                thumbnailImageTrailingConstraint?.isActive = false
                image?.isHidden = true
                imageTrailingConstraint?.isActive = false
            }

            // Display single video/gif if needed
            if postCard.hasMediaAttachment, [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType), !hideMedia {
                if activity.type == .status, let postCard = activity.postCard {
                    let cellVariant = PostCardCell.PostCardVariant.cellVariant(for: postCard, cellType: .regular)
                    switch cellVariant?.mediaVariant {
                    case .small:
                        thumbnailVideo?.configure(postCard: postCard)
                        thumbnailVideo?.isHidden = false
                        thumbnailVideoTrailingConstraint?.isActive = true
                    case .large, .fullWidth:
                        video?.configure(postCard: postCard)
                        video?.isHidden = false
                        videoTrailingConstraint?.isActive = true
                    default:
                        video?.isHidden = true
                        videoTrailingConstraint?.isActive = false
                        thumbnailVideo?.isHidden = true
                        thumbnailVideoTrailingConstraint?.isActive = false
                    }
                } else {
                    thumbnailVideo?.configure(postCard: postCard)
                    thumbnailVideo?.isHidden = false
                    thumbnailVideoTrailingConstraint?.isActive = true
                }
            } else {
                video?.isHidden = true
                videoTrailingConstraint?.isActive = false
                thumbnailVideo?.isHidden = true
                thumbnailVideoTrailingConstraint?.isActive = false
            }

            // Display the image carousel if needed
            if postCard.hasMediaAttachment, postCard.mediaDisplayType == .carousel, !hideMedia {
                if activity.type == .status, let postCard = activity.postCard {
                    switch cellVariant?.mediaVariant {
                    case .small:
                        mediaStack?.configure(postCard: postCard)
                        mediaStack?.isHidden = false
                        mediaStackTrailingConstraint?.isActive = true
                    case .large, .fullWidth:
                        mediaGallery?.configure(postCard: postCard)
                        mediaGallery?.isHidden = false
                        mediaGalleryTrailingConstraint?.isActive = true
                    default:
                        mediaStack?.isHidden = true
                        mediaStackTrailingConstraint?.isActive = false
                        mediaGallery?.isHidden = true
                        mediaGalleryTrailingConstraint?.isActive = false
                    }
                } else {
                    mediaStack?.configure(postCard: postCard)
                    mediaStack?.isHidden = false
                    mediaStackTrailingConstraint?.isActive = true
                }
            } else {
                mediaStack?.isHidden = true
                mediaStackTrailingConstraint?.isActive = false
                mediaGallery?.isHidden = true
                mediaGalleryTrailingConstraint?.isActive = false
            }

            // If we are hiding the link image, move the link view
            // so it's below any possible media.
            if let linkPreview = linkPreview, postCard.hideLinkImage, mediaContainer.arrangedSubviews.contains(linkPreview), !hideMedia {
                mediaContainer.insertArrangedSubview(linkPreview, at: mediaContainer.arrangedSubviews.count - 1)
            }

            // Add extra spacing between text and media
            let cellVariant = PostCardCell.PostCardVariant.cellVariant(for: postCard, cellType: .regular)
            if postCard.hasLink || postCard.hasMediaAttachment, activity.type == .status, !postCard.postText.isEmpty, cellVariant?.mediaVariant == .large {
                contentStackView.setCustomSpacing(12, after: textAndSmallMediaStackView)
            } else {
                if postCard.hasMediaAttachment {
                    contentStackView.setCustomSpacing(2, after: textAndSmallMediaStackView)
                } else {
                    contentStackView.setCustomSpacing(0, after: textAndSmallMediaStackView)
                }
            }
        } else {
            resetMedia()
        }

        if CommandLine.arguments.contains("-M_DEBUG_TIMELINES") {
            // Configure for debugging
            configureForDebugging(activity: activity)
        }
    }

    private func mapTypeTBadgeImage(activity: ActivityCardModel) -> UIImage {
        switch activity.type {
        case .favourite:
            return FontAwesome.image(fromChar: "\u{f004}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .follow:
            return FontAwesome.image(fromChar: "\u{f007}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .follow_request:
            return FontAwesome.image(fromChar: "\u{f007}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .poll:
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .reblog:
            return FontAwesome.image(fromChar: "\u{f079}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .status:
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .update:
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .direct:
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        case .mention:
            if let postCard = activity.postCard, postCard.isPrivateMention {
                return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
            }
            return FontAwesome.image(fromChar: "\u{e149}", weight: .bold).withRenderingMode(.alwaysTemplate)
        }
    }

    private func configureForDebugging(activity: ActivityCardModel) {
        if let batchId = activity.batchId, let batchItemIndex = activity.batchItemIndex {
            postTextLabel.reset()
            postTextLabel.text = "\(batchId) - \(batchItemIndex)"

            if let mediaStack = mediaStack {
                mediaStackTrailingConstraint?.isActive = false
                textAndSmallMediaStackView.removeArrangedSubview(mediaStack)
                mediaStack.removeFromSuperview()
            }

            if let linkPreview = linkPreview {
                linkPreviewTrailingConstraint?.isActive = false
                mediaContainer.removeArrangedSubview(linkPreview)
                linkPreview.removeFromSuperview()
                linkPreview.prepareForReuse()
            }

            if let poll = poll {
                pollTrailingConstraint?.isActive = false
                mediaContainer.removeArrangedSubview(poll)
                poll.removeFromSuperview()
                poll.prepareForReuse()
            }

            if let quotePost = quotePost {
                quotePostTrailingConstraint?.isActive = false
                mediaContainer.removeArrangedSubview(quotePost)
                quotePost.removeFromSuperview()
                quotePost.prepareForReuse()
            }
        }
    }

    func onThemeChange() {
        backgroundColor = .custom.background
        contentView.backgroundColor = .custom.background
        postTextLabel.backgroundColor = contentView.backgroundColor

        profilePic.onThemeChange()
        header.onThemeChange()
        poll?.onThemeChange()
        linkPreview?.onThemeChange()
        quotePost?.onThemeChange()
    }
}

// MARK: - Context menu creators

extension ActivityCardCell {
    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, onPress: @escaping PostCardButtonCallback) -> UIAction {
        let action = UIAction(title: title,
                              image: isActive
                                  ? buttonType.activeIcon(symbolConfig: postCardSymbolConfig)
                                  : buttonType.icon(symbolConfig: postCardSymbolConfig),
                              identifier: nil)
        { _ in
            onPress(buttonType, isActive, nil)
        }
        action.accessibilityLabel = title
        return action
    }

    // General cell context menu
    func createContextMenu(postCard: PostCardModel, onButtonPress: @escaping PostCardButtonCallback) -> UIMenu {
        let options = [
            createContextMenuAction(NSLocalizedString("post.reply", comment: ""), .reply, isActive: false, onPress: onButtonPress),

            postCard.isReposted
                ? createContextMenuAction(NSLocalizedString("post.repost.undo", comment: ""), .repost, isActive: true, onPress: onButtonPress)
                : createContextMenuAction(NSLocalizedString("post.repost", comment: ""), .repost, isActive: false, onPress: onButtonPress),

            postCard.isLiked
                ? createContextMenuAction(NSLocalizedString("post.like.undo", comment: ""), .like, isActive: true, onPress: onButtonPress)
                : createContextMenuAction(NSLocalizedString("post.like", comment: ""), .like, isActive: false, onPress: onButtonPress),

            postCard.isBookmarked
                ? createContextMenuAction(NSLocalizedString("post.bookmark.undo", comment: ""), .unbookmark, isActive: false, onPress: onButtonPress)
                : createContextMenuAction(NSLocalizedString("post.bookmark", comment: ""), .bookmark, isActive: false, onPress: onButtonPress),

            createContextMenuAction(NSLocalizedString("post.translatePost", comment: ""), .translate, isActive: false, onPress: onButtonPress),
            createContextMenuAction(NSLocalizedString("post.viewInBrowser", comment: ""), .viewInBrowser, isActive: false, onPress: onButtonPress),
            createContextMenuAction(NSLocalizedString("post.sharePost", comment: ""), .share, isActive: false, onPress: onButtonPress),

            postCard.isOwn
                ? UIMenu(title: NSLocalizedString("post.modify", comment: ""), options: [], children: [
                    postCard.isPinned
                        ? createContextMenuAction(NSLocalizedString("post.pin.undo", comment: ""), .pinPost, isActive: true, onPress: onButtonPress)
                        : createContextMenuAction(NSLocalizedString("post.pin", comment: ""), .pinPost, isActive: false, onPress: onButtonPress),

                    createContextMenuAction(NSLocalizedString("post.edit", comment: ""), .editPost, isActive: false, onPress: onButtonPress),
                    createContextMenuAction(NSLocalizedString("post.delete", comment: ""), .deletePost, isActive: false, onPress: onButtonPress),
                ])
                : nil,
        ].compactMap { $0 }

        return UIMenu(title: "", options: [.displayInline], children: options)
    }
}

// MARK: - MetaLabelDelegate

extension ActivityCardCell: MetaLabelDelegate {
    func metaLabel(_: MetaTextKit.MetaLabel, didSelectMeta meta: Meta) {
        switch meta {
        case let .url(_, _, urlString, _):
            if let url = URL(string: urlString) {
                onButtonPress?(.link, true, .url(url))
            }
        case let .mention(_, mention, _):
            if case let .mastodon(status) = activityCard?.postCard?.data {
                onButtonPress?(.link, true, .mention((mention, status)))
            }
        case let .hashtag(_, hashtag, _):
            onButtonPress?(.link, true, .hashtag(hashtag))
        default:
            if let postCard = activityCard?.postCard {
                onButtonPress?(.postDetails, true, .post(postCard))
            }
        }
    }
}

// MARK: Appearance changes

extension ActivityCardCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.setupUIFromSettings()
            }
        }
    }
}
