//
//  PostCardCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 24/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import MastodonMeta
import Meta
import MetaTextKit
import UIKit

let screenWidth = UIScreen.main.bounds.width

// swiftlint:disable:next type_body_length
final class PostCardCell: UITableViewCell {
    enum PostCardMediaVariant: String, Equatable, CaseIterable {
//        UNCOMMENT TO SUPPORT DYNAMIC MEDIA SIZE MODE
//        case auto
        case fullWidth
        case large
        case small
        case hidden

        var displayName: String {
            switch self {
//            UNCOMMENT TO SUPPORT DYNAMIC MEDIA SIZE MODE
//            case .auto: return "Dynamic"

            case .fullWidth: return NSLocalizedString("settings.appearance.mediaSize.fullWidth", comment: "")
            case .large: return NSLocalizedString("settings.appearance.mediaSize.large", comment: "")
            case .small: return NSLocalizedString("settings.appearance.mediaSize.small", comment: "")
            case .hidden: return NSLocalizedString("settings.appearance.mediaSize.hidden", comment: "")
            }
        }
    }

    static func reuseIdentifier(for variant: PostCardVariant) -> String {
        switch variant {
        case .textOnly: return "PostCardCell.TextOnly"
        case let .textAndMedia(mediaVariant): return "PostCardCell.TextAndMedia(variant=\(mediaVariant.rawValue))"
        case let .mediaOnly(mediaVariant): return "PostCardCell.MediaOnly(variant=\(mediaVariant.rawValue))"
        }
    }

    static func reuseIdentifier(for postCard: PostCardModel, cellType: PostCardCellType = .regular) -> String {
        if let variant = PostCardVariant.cellVariant(for: postCard, cellType: cellType) {
            return reuseIdentifier(for: variant)
        }

        // Fallback to text-only
        log.error("PostCardCell fallback to .textOnly")
        return reuseIdentifier(for: .textOnly)
    }

    static func variant(for reusableIdentifier: String) -> PostCardVariant {
        switch reusableIdentifier {
        case "PostCardCell.TextOnly": return .textOnly
        case "PostCardCell.TextAndMedia(variant=hidden)": return .textAndMedia(.hidden)
        case "PostCardCell.TextAndMedia(variant=small)": return .textAndMedia(.small)
        case "PostCardCell.TextAndMedia(variant=large)": return .textAndMedia(.large)
        case "PostCardCell.TextAndMedia(variant=fullWidth)": return .textAndMedia(.fullWidth)
        case "PostCardCell.MediaOnly(variant=hidden)": return .mediaOnly(.hidden)
        case "PostCardCell.MediaOnly(variant=small)": return .mediaOnly(.small)
        case "PostCardCell.MediaOnly(variant=large)": return .mediaOnly(.large)
        case "PostCardCell.MediaOnly(variant=fullWidth)": return .mediaOnly(.fullWidth)
        default:
            log.error("PostCardCell fallback to .textOnly")
            return .textOnly
        }
    }

    static func registerForReuseIdentifierVariants(on tableView: UITableView) {
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textOnly))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textAndMedia(.hidden)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textAndMedia(.small)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textAndMedia(.large)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .textAndMedia(.fullWidth)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .mediaOnly(.hidden)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .mediaOnly(.small)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .mediaOnly(.large)))
        tableView.register(PostCardCell.self, forCellReuseIdentifier: PostCardCell.reuseIdentifier(for: .mediaOnly(.fullWidth)))
    }

    enum PostCardCellType {
        case regular // regular post cell
        case forYou // post in the For You feed
        case channel // post in a channel feed
        case detail // main post on the detail screen
        case parent // parent post on the detail screen
        case reply // reply post on the detail screen
        case mentions // post in the Mentions feed
        case following
        case list

        var headerType: PostCardHeader.PostCardHeaderTypes {
            switch self {
            case .detail:
                return PostCardHeader.PostCardHeaderTypes.detail
            case .forYou:
                return PostCardHeader.PostCardHeaderTypes.forYou
            case .channel:
                return PostCardHeader.PostCardHeaderTypes.channel
            case .mentions:
                return PostCardHeader.PostCardHeaderTypes.mentions
            case .following:
                return PostCardHeader.PostCardHeaderTypes.following
            case .list:
                return PostCardHeader.PostCardHeaderTypes.list
            default:
                return PostCardHeader.PostCardHeaderTypes.regular
            }
        }

        var numberOfLines: Int {
            switch self {
            case .regular, .mentions, .following, .list, .forYou, .channel:
                return GlobalStruct.maxLines
            case .reply, .parent, .detail:
                return 0
            }
        }

        var mediaVariant: PostCardMediaVariant {
            switch self {
            case .detail: return .large
            case .mentions: return .small
            default: return GlobalStruct.mediaSize
            }
        }

        func shouldSyncFollowStatus(postCard: PostCardModel) -> Bool {
            switch self {
            case .mentions:
                return false
            case .list, .following:
                return postCard.isReblogged
            default:
                return true
            }
        }

        var shouldShowDetailedMetrics: Bool {
            switch self {
            case .reply, .parent:
                return false
            default:
                return true
            }
        }

        var shouldShowSourceAndApplicationName: Bool {
            switch self {
            case .detail:
                return true
            default:
                return false
            }
        }

        var shouldShowFullWidthLayout: Bool {
            switch self {
            case .detail, .parent, .reply:
                return false
            default:
                return true
            }
        }
    }

    enum PostCardVariant: Equatable {
        case textOnly
        case textAndMedia(PostCardMediaVariant)
        case mediaOnly(PostCardMediaVariant)

        static func cellVariant(for postCard: PostCardModel, cellType: PostCardCellType) -> Self? {
            let hasText = !postCard.postText.isEmpty

            guard cellType.shouldShowFullWidthLayout else {
                // In details feed, don't show full width
                if cellType.mediaVariant == .fullWidth {
                    return hasText ? .textAndMedia(.large) : .mediaOnly(.large)
                } else {
                    return hasText ? .textAndMedia(cellType.mediaVariant) : .mediaOnly(cellType.mediaVariant)
                }
            }

            if postCard.containsPoll || postCard.hasQuotePost || postCard.hasLink || postCard.hasMediaAttachment || (cellType.shouldShowFullWidthLayout && cellType.mediaVariant == .fullWidth) {
                let mediaVariant = cellType.mediaVariant

//                UNCOMMENT TO SUPPORT DYNAMIC MEDIA SIZE MODE
//                if mediaVariant == .auto {
//                    if let firstImage = postCard.mediaAttachments.first,
//                        let original = firstImage.meta?.original,
//                        (original.width ?? 0) < 200 && (original.height ?? 0) < 200 {
//                        mediaVariant = .small
//                    } else {
//                        mediaVariant = .large
//                    }
//                }

                // NOTE: when a post has only media in thumbnail-mode we do display a text label as well
                return hasText || [.small, .hidden].contains(mediaVariant) ? .textAndMedia(mediaVariant) : .mediaOnly(mediaVariant)
            }

            return .textOnly
        }

        var hasText: Bool {
            if self == .textOnly { return true }
            if case .textAndMedia = self { return true }
            return false
        }

        var hasMedia: Bool {
            if case .mediaOnly = self { return true }
            if case .textAndMedia = self { return true }
            return false
        }

        var mediaVariant: PostCardMediaVariant {
            if case let .textAndMedia(mediaVariant) = self {
                return mediaVariant
            }
            if case let .mediaOnly(mediaVariant) = self {
                return mediaVariant
            }
            return .hidden
        }
    }

    // MARK: - Properties

    static let paragraphSpacing = 12.0

    // Includes the header extension and the rest of the cell
    private var wrapperStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 6.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()

    // Basic cell columns: profile pic, and cell content
    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.spacing = 0.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()

    // Includes header, text, media and footer
    private var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.isOpaque = true
        stackView.layoutMargins = .init(top: 0, left: 12, bottom: 0, right: 0)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    // Includes profile and header in extra large media mode
    private var headerStackView: UIStackView = {
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
    private let header = PostCardHeader()
    private let footer = PostCardFooter()

    private var contentWarningButton: UIButton = {
        let contentWarningButton = UIButton()
        contentWarningButton.backgroundColor = .custom.OVRLYSoftContrast
        contentWarningButton.layer.cornerRadius = 8
        contentWarningButton.layer.cornerCurve = .continuous
        contentWarningButton.setTitleColor(.secondaryLabel, for: .normal)
        contentWarningButton.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 2, weight: .regular)
        contentWarningButton.titleLabel?.numberOfLines = 6
        contentWarningButton.layer.masksToBounds = true
        contentWarningButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        contentWarningButton.contentVerticalAlignment = .top
        contentWarningButton.contentHorizontalAlignment = .left
        contentWarningButton.translatesAutoresizingMaskIntoConstraints = false
        contentWarningButton.isOpaque = true
        return contentWarningButton
    }()

    private var contentWarningConstraints: [NSLayoutConstraint] = []

    private var deletedWarningButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .custom.OVRLYSoftContrast
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.numberOfLines = 6
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false

        button.isOpaque = true
        return button
    }()

    private var deletedWarningConstraints: [NSLayoutConstraint] = []

    private var postTextView: MetaLabel = {
        let metaText = MetaLabel()
        metaText.isOpaque = true
        metaText.backgroundColor = .custom.background
        metaText.translatesAutoresizingMaskIntoConstraints = false
        metaText.textContainer.lineFragmentPadding = 0
        metaText.numberOfLines = 0
        metaText.textContainer.maximumNumberOfLines = 0
        metaText.textContainer.lineBreakMode = .byTruncatingTail

        metaText.setContentHuggingPriority(.defaultHigh, for: .vertical)

        metaText.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]

        metaText.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        metaText.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = 12
            style.alignment = .natural
            return style
        }()

        return metaText
    }()

    private var hiddenImageIndicator: UILabel = {
        let label = UILabel()
        label.isOpaque = true
        label.backgroundColor = .custom.background
        label.textColor = .custom.highContrast
        label.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()

    private var postTextTrailingConstraint: NSLayoutConstraint?

    // Contains image attachment, poll, and/or link preview if needed
    private var mediaContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.isOpaque = true
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.layoutMargins = .zero
        stackView.preservesSuperviewLayoutMargins = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var mediaContainerConstraints: [NSLayoutConstraint]? = []

    private var poll: PostCardPoll?
    private var pollTrailingConstraint: NSLayoutConstraint?

    private var image: PostCardImage?
    private var imageTrailingConstraint: NSLayoutConstraint?

    private var video: PostCardVideo?
    private var videoTrailingConstraint: NSLayoutConstraint?

    private var mediaGallery: PostCardMediaGallery?
    private var mediaGalleryTrailingConstraint: NSLayoutConstraint?

    private var mediaStack: PostCardMediaStack?
    private var mediaStackTrailingConstraint: NSLayoutConstraint?

    private var linkPreview: PostCardLinkPreview?
    private var linkPreviewTrailingConstraint: NSLayoutConstraint?

    private var webview: PostCardWebview?
    private var webviewTrailingConstraint: NSLayoutConstraint?

    private var quotePost: PostCardQuotePost?
    private var quotePostTrailingConstraint: NSLayoutConstraint?

    private var postCard: PostCardModel?
    private var type: PostCardCellType?
    private var onButtonPress: PostCardButtonCallback?
    private var headerExtension = PostCardHeaderExtension()
    private var metadata: PostCardMetadata?

//    private var readMoreButton: ReadMoreButton?

    private var cellVariant: PostCardVariant {
        if let reuseIdentifier = reuseIdentifier {
            return Self.variant(for: reuseIdentifier)
        }

        return .textOnly
    }

    private let parentThread: UIView = {
        let view = UIView()
        view.isOpaque = true
        view.layer.shouldRasterize = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .custom.feintContrast
        view.isHidden = true
        return view
    }()

    private let childThread: UIView = {
        let view = UIView()
        view.isOpaque = true
        view.layer.shouldRasterize = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .custom.feintContrast
        view.isHidden = true
        return view
    }()

    private var textLongPressGesture: UILongPressGestureRecognizer?
    private var isPrivateMention: Bool = false
    private var isTipAccount: Bool = false

    private enum MetricButtons: Int {
        case likes
        case reposts
        case replies
    }

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
        postCard = nil
        postTextView.reset()
        profilePic.prepareForReuse()
        footer.onButtonPress = nil
        separatorInset = .zero

//        self.readMoreButton?.isHidden = true

        hiddenImageIndicator.isHidden = true

        contentStackView.setCustomSpacing(contentStackView.spacing, after: header)

        contentWarningButton.isHidden = true
        contentWarningButton.isUserInteractionEnabled = false
        NSLayoutConstraint.deactivate(contentWarningConstraints)

        deletedWarningButton.isHidden = true
        NSLayoutConstraint.deactivate(deletedWarningConstraints)

        header.prepareForReuse()

        parentThread.isHidden = true
        childThread.isHidden = true

        metadata?.prepareForReuse()

        if quotePost?.isHidden == false {
            quotePost?.prepareForReuse()
            quotePost?.isHidden = true
        }

        image?.prepareForReuse()
        video?.prepareForReuse()
        poll?.prepareForReuse()
        linkPreview?.prepareForReuse()
        webview?.prepareForReuse()
        mediaStack?.prepareForReuse()
        mediaGallery?.prepareForReuse()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        if let mediaGallery = mediaGallery,
           postCard?.mediaDisplayType == .carousel,
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

private extension PostCardCell {
    func setupUI() {
        selectionStyle = .none
        separatorInset = .zero
        layoutMargins = .zero
        contentView.preservesSuperviewLayoutMargins = false
        isOpaque = true
        contentView.isOpaque = true

        contentView.addSubview(wrapperStackView)

        wrapperStackView.addArrangedSubview(headerExtension)
        wrapperStackView.addArrangedSubview(mainStackView)

        NSLayoutConstraint.activate([
            wrapperStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            wrapperStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            wrapperStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            wrapperStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            // Force main stack view to fill the parent width
            mainStackView.trailingAnchor.constraint(equalTo: wrapperStackView.layoutMarginsGuide.trailingAnchor),
        ])

        mainStackView.addSubview(parentThread)
        mainStackView.addSubview(childThread)

        if cellVariant.mediaVariant == .fullWidth {
            headerStackView.addArrangedSubview(profilePic)
        } else {
            mainStackView.addArrangedSubview(profilePic)
        }

        profilePic.setContentCompressionResistancePriority(.required, for: .horizontal)

        mainStackView.addArrangedSubview(contentStackView)

        /// Only center the header content if the display name is two files and in full width mode.
        header.isCenterAligned = cellVariant.mediaVariant == .fullWidth
        headerStackView.addArrangedSubview(header)

        contentStackView.addArrangedSubview(headerStackView)
        contentStackView.addArrangedSubview(textAndSmallMediaStackView)

        if cellVariant.mediaVariant == .fullWidth {
            headerStackView.alignment = .center
            contentStackView.layoutMargins = .zero
            contentStackView.setCustomSpacing(12, after: headerStackView)
        }

        NSLayoutConstraint.activate([
            headerExtension.leadingMarginAnchor.constraint(equalTo: header.leadingAnchor),

            parentThread.widthAnchor.constraint(equalToConstant: 1),
            parentThread.topAnchor.constraint(equalTo: topAnchor),
            parentThread.bottomAnchor.constraint(equalTo: profilePic.topAnchor),
            parentThread.centerXAnchor.constraint(equalTo: profilePic.centerXAnchor),

            childThread.widthAnchor.constraint(equalToConstant: 1),
            childThread.topAnchor.constraint(equalTo: profilePic.bottomAnchor),
            childThread.bottomAnchor.constraint(equalTo: bottomAnchor),
            childThread.centerXAnchor.constraint(equalTo: profilePic.centerXAnchor),

            contentStackView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            textAndSmallMediaStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
        ])

        // insert a text label if there's a post text
        if cellVariant.hasText || [.small, .hidden].contains(cellVariant.mediaVariant) {
            textAndSmallMediaStackView.addArrangedSubview(postTextView)

            postTextView.linkDelegate = self

            if cellVariant.hasMedia {
                if cellVariant.mediaVariant == .large || cellVariant.mediaVariant == .fullWidth {
                    contentStackView.setCustomSpacing(12.0, after: textAndSmallMediaStackView)
                } else if cellVariant.mediaVariant == .small {
                    contentStackView.setCustomSpacing(4.0, after: textAndSmallMediaStackView)
                }
            }

            // Force post text to fill the parent width
            postTextTrailingConstraint = postTextView.trailingAnchor.constraint(equalTo: textAndSmallMediaStackView.layoutMarginsGuide.trailingAnchor)
            postTextTrailingConstraint!.priority = .defaultHigh
            postTextTrailingConstraint!.isActive = true

//            self.readMoreButton = ReadMoreButton()
//            self.readMoreButton?.isHidden = true
//            contentStackView.addArrangedSubview(readMoreButton!)
//            self.readMoreButton?.addTarget(self, action: #selector(self.onReadMorePress), for: .touchUpInside)
        }

        if cellVariant.hasMedia {
            if cellVariant.mediaVariant == .hidden {
                contentStackView.addArrangedSubview(hiddenImageIndicator)

                let height = ceil("1 Image".height(width: 300, font: hiddenImageIndicator.font))
                NSLayoutConstraint.activate([
                    hiddenImageIndicator.heightAnchor.constraint(equalToConstant: height),
                ])
            }

            contentStackView.addArrangedSubview(mediaContainer)

            if UIDevice.current.userInterfaceIdiom == .phone || cellVariant.mediaVariant == .fullWidth {
                let trailingConstraint = mediaContainer.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor)
                trailingConstraint.isActive = true

                mediaContainerConstraints = [trailingConstraint]
            } else {
                // Force media container to fill the parent width - with max width for big displays
                mediaContainerConstraints = mediaContainer.addHorizontalFillConstraints(withParent: contentStackView, andMaxWidth: 320)
            }

            // Setup Image
            switch cellVariant.mediaVariant {
            case .small:
                image = PostCardImage(variant: .thumbnail)
                image!.translatesAutoresizingMaskIntoConstraints = false
                textAndSmallMediaStackView.addArrangedSubview(image!)
                imageTrailingConstraint = image!.widthAnchor.constraint(equalToConstant: 60)
            case .large, .fullWidth:
                image = PostCardImage(variant: .fullSize)
                image!.translatesAutoresizingMaskIntoConstraints = false
                mediaContainer.addArrangedSubview(image!)
                imageTrailingConstraint = image!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
            default: break
            }

            // Setup Video
            switch cellVariant.mediaVariant {
            case .small:
                video = PostCardVideo(variant: .thumbnail)
                video!.translatesAutoresizingMaskIntoConstraints = false
                textAndSmallMediaStackView.addArrangedSubview(video!)
                videoTrailingConstraint = video!.widthAnchor.constraint(equalToConstant: 60)
            case .large, .fullWidth:
                video = PostCardVideo(variant: .fullSize)
                video!.translatesAutoresizingMaskIntoConstraints = false
                mediaContainer.addArrangedSubview(video!)
                videoTrailingConstraint = video!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
            default: break
            }

            // Setup Media Carousel
            switch cellVariant.mediaVariant {
            case .small:
                mediaStack = PostCardMediaStack(variant: .thumbnail)
                mediaStack?.translatesAutoresizingMaskIntoConstraints = false
                textAndSmallMediaStackView.addArrangedSubview(mediaStack!)
                mediaStackTrailingConstraint = mediaStack!.widthAnchor.constraint(equalToConstant: 60)
            case .large, .fullWidth:
                mediaGallery = PostCardMediaGallery()
                mediaGallery?.translatesAutoresizingMaskIntoConstraints = false
                mediaContainer.addArrangedSubview(mediaGallery!)
                mediaGalleryTrailingConstraint = mediaGallery!.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor)
            default: break
            }

            // Setup Poll
            poll = PostCardPoll()
            poll?.translatesAutoresizingMaskIntoConstraints = false
            mediaContainer.addArrangedSubview(poll!)
            pollTrailingConstraint = poll!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
            pollTrailingConstraint?.isActive = true

            // Setup Quote Post
            quotePost = PostCardQuotePost(mediaVariant: cellVariant.mediaVariant)
            quotePost?.translatesAutoresizingMaskIntoConstraints = false
            mediaContainer.addArrangedSubview(quotePost!)
            quotePostTrailingConstraint = quotePost!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)

            // Setup Link Preview
            linkPreview = PostCardLinkPreview()
            linkPreview?.translatesAutoresizingMaskIntoConstraints = false
            mediaContainer.addArrangedSubview(linkPreview!)
            linkPreviewTrailingConstraint = linkPreview!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)

            // setup webview.
            webview = PostCardWebview()
            webview?.translatesAutoresizingMaskIntoConstraints = false
            webview?.isHidden = true
            mediaContainer.addArrangedSubview(webview!)
            webviewTrailingConstraint = webview!.trailingAnchor.constraint(equalTo: mediaContainer.layoutMarginsGuide.trailingAnchor)
        }

        contentStackView.addArrangedSubview(footer)

        // Make sure the contentWarning covers the post text, image, link (just not the header, footer)
        contentStackView.addSubview(contentWarningButton)
        contentWarningButton.isHidden = true
        contentWarningButton.addTarget(self, action: #selector(contentWarningButtonTapped), for: .touchUpInside)
        contentWarningConstraints = [
            textAndSmallMediaStackView.topAnchor.constraint(equalTo: contentWarningButton.topAnchor, constant: 0),
            contentWarningButton.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: -48),
            textAndSmallMediaStackView.leadingAnchor.constraint(equalTo: contentWarningButton.leadingAnchor, constant: 3),
            contentWarningButton.trailingAnchor.constraint(equalTo: textAndSmallMediaStackView.trailingAnchor, constant: 3),
        ]

        // Make sure the deleted warning covers entire post text, image, link (just not the header, footer)
        addSubview(deletedWarningButton)
        deletedWarningButton.isHidden = true
        deletedWarningButton.setTitle("Post removed", for: .normal)
        deletedWarningConstraints = [
            deletedWarningButton.topAnchor.constraint(equalTo: wrapperStackView.topAnchor, constant: -1),
            deletedWarningButton.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: -8),
            deletedWarningButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: 6),
            deletedWarningButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 3),
        ]

        NSLayoutConstraint.activate([
            // Force header to fill the parent width
            header.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
        ])

        // Setup Metadata
        metadata = PostCardMetadata()
        contentStackView.insertArrangedSubview(metadata!, at: contentStackView.arrangedSubviews.firstIndex(of: footer) ?? 0)

        setupUIFromSettings()
        onThemeChange()
    }

    @objc func setupUIFromSettings() {
        deletedWarningButton.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)

        postTextView.textAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular),
            .foregroundColor: UIColor.custom.mediumContrast,
        ]

        postTextView.linkAttributes = [
            .font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold),
            .foregroundColor: UIColor.custom.highContrast,
        ]

        postTextView.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = DeviceHelpers.isiOSAppOnMac() ? 1 : 0
            style.paragraphSpacing = PostCardCell.paragraphSpacing
            style.alignment = .natural
            return style
        }()

        if footer.isHidden {
            contentView.layoutMargins = .init(top: 16, left: 13, bottom: 10, right: 13)
        } else {
            let newMargins = UIEdgeInsets(top: 16, left: 13, bottom: 0, right: 13)
            if contentView.layoutMargins != newMargins {
                contentView.layoutMargins = newMargins
            }
        }

        header.setupUIFromSettings()
        linkPreview?.setupUIFromSettings()
        quotePost?.setupUIFromSettings()
        headerExtension.setupUIFromSettings()
        metadata?.setupUIFromSettings()
    }
}

// MARK: - Estimated height

extension PostCardCell {
    static func estimatedHeight(width: CGFloat, postCard: PostCardModel, cellType: PostCardCell.PostCardCellType) -> CGFloat {
        let variant = PostCardCell.PostCardVariant.cellVariant(for: postCard, cellType: cellType)
        let contentMarginTop = 13.0
        let contentMarginBottom = 0.0
        let contentMarginLeft = 13.0
        let contentMarginRight = 13.0
        let contentColumnSpacing = 12.0
        let contentSpacing = 2.0

        var linkBoxHeight = 0.0

        var height = contentMarginTop
        let contentWidth = width - PostCardProfilePic.ProfilePicSize.regular.width() - contentMarginLeft - contentMarginRight - contentColumnSpacing

        let textWidth: CGFloat = {
            if let variant, variant.hasMedia, variant.mediaVariant == .small {
                let thumbnailSize = 60.0
                return contentWidth - thumbnailSize - 12.0
            }

            return contentWidth
        }()

        var textHeight = 0.0

        if let variant, variant.hasText {
            let contentFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
            let maxHeight = contentFont.lineHeight * Double(cellType.numberOfLines == 0 ? 100 : cellType.numberOfLines)
            let minHeight = variant.mediaVariant == .small ? 60.0 : 0.0
            textHeight = max(ceil(postCard.richPostText?.string.height(width: textWidth, font: contentFont, maxHeight: maxHeight) ?? 0.0), minHeight)

            let numberOfParagraphs = postCard.postText.string.numberOfParagraphs()
            if numberOfParagraphs > 1 {
                if cellType.numberOfLines == 0 {
                    for _ in 1 ... numberOfParagraphs - 1 {
                        textHeight += PostCardCell.paragraphSpacing
                    }
                } else {
                    // if text is trimmed and we find > 1 <p> tag, assume there are 2 paragraphs visible
                    textHeight += PostCardCell.paragraphSpacing
                }
            }

            height += textHeight
        }

        if postCard.hasLink {
            height += PostCardLinkPreview.estimatedHeight(width: contentWidth, postCard: postCard)
            height += contentSpacing
            height += 12

            linkBoxHeight += PostCardLinkPreview.estimatedHeight(width: contentWidth, postCard: postCard)
        }

        if let variant, variant.hasMedia {
            if variant.mediaVariant == .large || variant.mediaVariant == .fullWidth {
                height += 12
            } else if variant.mediaVariant == .small {
                if variant.hasText {
                    height += 14
                } else {
                    height += 4
                }
            } else if variant.mediaVariant == .hidden {
                if cellType != .detail && postCard.hasMediaAttachment && !postCard.mediaAttachmentDescription.isEmpty {
                    let hiddenMediaIndicatorHeight = ceil("1 Image".height(width: 300, font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)))
                    height += hiddenMediaIndicatorHeight
                }
            }
        }

        if postCard.isReblogged {
            height += PostCardHeaderExtension.estimatedHeight()
            height += 8
        }

        height += PostCardHeader.estimatedHeight()
        height += contentSpacing
        height += PostCardMetadata.estimatedHeight()
        height += contentSpacing
        height += PostCardFooter.estimatedHeight()
        height += contentMarginBottom
        height += 1

        return height
    }
}

// MARK: - Configuration

extension PostCardCell {
    func configure(postCard: PostCardModel, type: PostCardCellType = .regular, hasParent: Bool = false, hasChild: Bool = false, onButtonPress: @escaping PostCardButtonCallback) {
        let mediaHasChanged = postCard.mediaAttachments != self.postCard?.mediaAttachments

        let shouldUpdateTheme = (isPrivateMention != postCard.isPrivateMention || self.postCard?.isTipAccount != postCard.isTipAccount)
        isPrivateMention = postCard.isPrivateMention
        isTipAccount = postCard.isTipAccount

        self.postCard = postCard
        self.type = type
        self.onButtonPress = onButtonPress

        // Display header extension (reblogged or hashtagged indicator)
        if ((postCard.isReblogged && type != .detail) || postCard.isHashtagged || postCard.isPrivateMention || postCard.isTipAccount) && type != .forYou {
            headerExtension.onPress = onButtonPress
            headerExtension.configure(postCard: postCard)
            headerExtension.isHidden = false
        } else {
            headerExtension.isHidden = true
        }

        if let user = postCard.user, !postCard.isDeleted, !postCard.isMuted, !postCard.isBlocked, !postCard.filterType.isHide {
            profilePic.configure(user: user, isPrivateMention: postCard.isPrivateMention || postCard.isTipAccount)
            profilePic.onPress = onButtonPress
        }

        switch GlobalStruct.displayName {
        case .full:
            profilePic.size = .regular
        case .usernameOnly, .usertagOnly, .none:
            profilePic.size = .small
        }

        let isVerticallyCentered = postCard.mediaDisplayType == .carousel
            && postCard.postText.isEmpty
            && type.headerType != .quotePost
            && (cellVariant.mediaVariant == .large || (cellVariant.mediaVariant == .fullWidth && type.shouldShowFullWidthLayout))

        /// Only center the header content if the display name is two lines and in full width mode.
        header.isCenterAligned = cellVariant.mediaVariant == .fullWidth && type.shouldShowFullWidthLayout && GlobalStruct.displayName == .full
        header.configure(postCard: postCard, headerType: type.headerType, isVerticallyCentered: isVerticallyCentered)
        header.onPress = onButtonPress

        configureMetaTextContent()

        if cellVariant.hasMedia {
            var isDisplayingMedia = false

            if type != .detail, postCard.hasMediaAttachment, !postCard.mediaAttachmentDescription.isEmpty {
                hiddenImageIndicator.text = postCard.mediaAttachmentDescription
                hiddenImageIndicator.isHidden = false
                isDisplayingMedia = true
            } else {
                hiddenImageIndicator.isHidden = true
            }

            // Display poll if needed
            if postCard.containsPoll {
                poll?.prepareForReuse()
                poll?.configure(postCard: postCard)
                poll?.isHidden = false
                isDisplayingMedia = true
            } else {
                poll?.isHidden = true
            }

            // Display the quote post preview if needed
            if postCard.hasQuotePost, postCard.quotePostStatus != .notFound {
                quotePost?.configure(postCard: postCard)
                quotePost?.onPress = onButtonPress
                quotePost?.isHidden = false
                isDisplayingMedia = true
            } else {
                quotePost?.isHidden = true
            }

            // Display the link preview if needed
            if postCard.hasLink, !postCard.hasQuotePost || postCard.quotePostStatus == .notFound, !postCard.hasWebview {
                linkPreview?.configure(postCard: postCard)
                linkPreview?.onPress = onButtonPress
                linkPreview?.isHidden = false
                isDisplayingMedia = true
            } else {
                linkPreview?.isHidden = true
            }

            // display webview. don't configure twice.
            if postCard.hasWebview {
                if webview?.isHidden == true {
                    webview?.configure(postCard: postCard)
                    webview?.isHidden = false
                }
                isDisplayingMedia = true
            } else {
                webview?.isHidden = true
            }

            // Display single image if needed
            if postCard.hasMediaAttachment, postCard.mediaDisplayType == .singleImage, !postCard.hasWebview {
                image?.configure(postCard: postCard)
                image?.isHidden = false
                isDisplayingMedia = true
            } else {
                image?.isHidden = true
            }

            // Display single video/gif if needed
            if postCard.hasMediaAttachment, [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
                if mediaHasChanged {
                    video?.configure(postCard: postCard)

                    // Do not auto-play videos in thumbnail-mode
                    if [.small, .hidden].contains(cellVariant.mediaVariant) {
                        video?.pause()
                    }

                    // Auto-play videos in detail mode (unless auto-play is disabled)
                    if type == .detail, GlobalStruct.autoPlayVideos {
                        video?.play()
                    }

                    video?.isHidden = false
                }
                isDisplayingMedia = true
            } else {
                video?.isHidden = true
            }

            // Display the image carousel if needed
            if postCard.hasMediaAttachment, postCard.mediaDisplayType == .carousel {
                if cellVariant.mediaVariant == .small {
                    mediaStack?.configure(postCard: postCard)
                    mediaStack?.isHidden = false
                    mediaGallery?.isHidden = true
                } else {
                    mediaGallery?.configure(postCard: postCard)
                    mediaGallery?.isHidden = false
                    mediaStack?.isHidden = true
                }
                isDisplayingMedia = true
            } else {
                mediaGallery?.isHidden = true
                mediaStack?.isHidden = true
            }

            if cellVariant.mediaVariant == .fullWidth, type.shouldShowFullWidthLayout {
                contentStackView.setCustomSpacing(isDisplayingMedia ? 12.0 : 0.0, after: textAndSmallMediaStackView)
            }
        }

        // Enable the content warning button if needed
        if let statID = postCard.id,
           !postCard.contentWarning.isEmpty,
           !GlobalStruct.allCW.contains(statID),
           GlobalStruct.showCW
        {
            NSLayoutConstraint.activate(contentWarningConstraints)
            contentWarningButton.setTitle(postCard.contentWarning, for: .normal)
            contentWarningButton.isHidden = false
            contentWarningButton.isUserInteractionEnabled = true
        } else if case let .warn(filterName) = postCard.filterType {
            NSLayoutConstraint.activate(contentWarningConstraints)
            contentWarningButton.setTitle(String.localizedStringWithFormat(NSLocalizedString("filter.overlay", comment: ""), filterName), for: .normal)
            contentWarningButton.isHidden = false
            contentWarningButton.isUserInteractionEnabled = true
        }

        if postCard.isDeleted {
            NSLayoutConstraint.activate(deletedWarningConstraints)
            deletedWarningButton.isHidden = false
            profilePic.optimisticUpdate(image: UIImage())
            deletedWarningButton.setTitle("Post removed", for: .normal)
        } else if case let .hide(filterName) = postCard.filterType {
            NSLayoutConstraint.activate(deletedWarningConstraints)
            deletedWarningButton.isHidden = false
            profilePic.optimisticUpdate(image: UIImage())
            deletedWarningButton.setTitle("\(filterName)", for: .normal)
        } else if postCard.isBlocked {
            NSLayoutConstraint.activate(deletedWarningConstraints)
            deletedWarningButton.isHidden = false
            profilePic.optimisticUpdate(image: UIImage())
            deletedWarningButton.setTitle("Blocked author", for: .normal)
        } else if postCard.isMuted {
            NSLayoutConstraint.activate(deletedWarningConstraints)
            deletedWarningButton.isHidden = false
            profilePic.optimisticUpdate(image: UIImage())
            deletedWarningButton.setTitle("Muted author", for: .normal)
        }

        // Hide media gallery (carousel) if covered with content warning / deleted overlay
        if contentWarningButton.isHidden == false || deletedWarningButton.isHidden == false {
            mediaGallery?.alpha = 0
            textAndSmallMediaStackView.alpha = 0
            mediaStack?.alpha = 0
            metadata?.alpha = 0
        } else {
            mediaGallery?.alpha = 1
            textAndSmallMediaStackView.alpha = 1
            mediaStack?.alpha = 1
            metadata?.alpha = 1
        }

        footer.configure(postCard: postCard, includeMetrics: false)
        footer.onButtonPress = onButtonPress

        childThread.isHidden = !hasChild
        parentThread.isHidden = !hasParent

        if type.shouldShowDetailedMetrics {
            metadata?.isHidden = false
            metadata?.configure(postCard: postCard, type: type, onButtonPress: onButtonPress)

            // add custom spacing above the post details ("via Mammoth, public", and metrics)
            if contentStackView.arrangedSubviews.contains(mediaContainer) {
                contentStackView.setCustomSpacing(12, after: mediaContainer)
            } else if contentStackView.arrangedSubviews.contains(postTextView) {
                contentStackView.setCustomSpacing(10, after: postTextView)
            }
        } else {
            // remove the detailStack when not needed
            if metadata?.isHidden == false {
                metadata?.isHidden = true
            }
        }

        // set detail-specific UI
        if type == .detail {
            // long press to copy the post text
            textLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onTextLongPress))
            postTextView.addGestureRecognizer(textLongPressGesture!)

            // make sure the thread lines are behind all the other elements
            mainStackView.sendSubviewToBack(childThread)
            mainStackView.sendSubviewToBack(parentThread)
        } else if let gesture = textLongPressGesture, (self.postTextView.gestureRecognizers?.contains(gesture) as? Bool) == true {
            postTextView.removeGestureRecognizer(gesture)
        }

        // Make sure all views are underneath the contentWarningButton and the deletedWarningButton
        if contentWarningButton.isHidden == false {
            contentStackView.bringSubviewToFront(contentWarningButton)
        }
        if deletedWarningButton.isHidden == false {
            contentStackView.bringSubviewToFront(deletedWarningButton)
        }

        if CommandLine.arguments.contains("-M_DEBUG_TIMELINES") {
            // Configure for debugging
            configureForDebugging(postCard: postCard)
        }

        configureContraints()

        if shouldUpdateTheme {
            onThemeChange()
        }
    }

    func configureMetaTextContent() {
        if cellVariant.hasText {
            if postTextView.textContainer.maximumNumberOfLines != type!.numberOfLines {
                postTextView.textContainer.maximumNumberOfLines = type!.numberOfLines
                postTextView.numberOfLines = type!.numberOfLines
            }

            if let postTextContent = postCard?.metaPostText, !postTextContent.original.isEmpty {
                postTextView.configure(content: postTextContent)
                postCard?.richPostText = postTextView.attributedText
            } else if [.small].contains(cellVariant.mediaVariant) {
                // If there's no post text, but a media attachment,
                // set the post text to either:
                //  - ([type])
                //  - ([type] description: [meta description])
                if let type = postCard?.mediaDisplayType.captializedDisplayName {
                    if let desc = postCard?.mediaAttachments.first?.description {
                        let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type) description: \(desc))", emojis: [:]))
                        postTextView.configure(content: content)
                        postTextView.isHidden = false
                    } else {
                        let content = MastodonMetaContent.convert(text: MastodonContent(content: "(\(type))", emojis: [:]))
                        postTextView.configure(content: content)
                        postTextView.isHidden = false
                    }
                } else {
                    postTextView.isHidden = true
                }
            } else {
                postTextView.isHidden = true
            }

//            self.readMoreButton?.isHidden = true
//            contentStackView.setCustomSpacing(2, after: textAndSmallMediaStackView)
//            let processingPostUniqueId = postCard?.uniqueId
//            DispatchQueue.main.async { [weak self] in
//                guard let self else { return }
//                guard self.postCard?.uniqueId == processingPostUniqueId else { return }
//                if self.postTextView.isTruncated && self.type != .detail {
//                    self.readMoreButton?.isHidden = false
//                } else if self.readMoreButton?.isHidden == false {
//                    self.readMoreButton?.isHidden = true
//                }
//            }
        }
    }

    private func configureContraints() {
        if let postCard = postCard {
            // Display poll if needed
            if postCard.containsPoll {
                if let constraint = pollTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([pollTrailingConstraint!])
                }
            } else {
                if let constraint = pollTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }

            // Display the quote post preview if needed
            if postCard.hasQuotePost, postCard.quotePostStatus != .notFound {
                if let constraint = quotePostTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([quotePostTrailingConstraint!])
                }
            } else {
                if let constraint = quotePostTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }

            // Display the link preview if needed
            if postCard.hasLink, !postCard.hasQuotePost || postCard.quotePostStatus == .notFound {
                if let constraint = linkPreviewTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([constraint])
                }
            } else {
                if let constraint = linkPreviewTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }

            // display webview if needed.
            if postCard.hasWebview {
                if let constraint = webviewTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([constraint])
                }
            } else {
                if let constraint = webviewTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }

            // Display single image if needed
            if postCard.hasMediaAttachment, postCard.mediaDisplayType == .singleImage, !postCard.hasWebview {
                if let constraint = imageTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([imageTrailingConstraint!])
                }
            } else {
                if let constraint = imageTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }

            // Display single video/gif if needed
            if postCard.hasMediaAttachment, [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType) {
                if let constraint = videoTrailingConstraint, !constraint.isActive {
                    NSLayoutConstraint.activate([videoTrailingConstraint!])
                }
            } else {
                if let constraint = videoTrailingConstraint, constraint.isActive {
                    NSLayoutConstraint.deactivate([constraint])
                }
            }

            // Display the image carousel if needed
            if postCard.hasMediaAttachment, postCard.mediaDisplayType == .carousel {
                switch cellVariant.mediaVariant {
                case .small:
                    if let constraint = mediaStackTrailingConstraint, !constraint.isActive {
                        NSLayoutConstraint.activate([mediaStackTrailingConstraint!])
                    }
                    NSLayoutConstraint.deactivate([
                        mediaGalleryTrailingConstraint,
                    ].compactMap { $0 })
                case .large, .fullWidth:
                    if let constraint = mediaGalleryTrailingConstraint, !constraint.isActive {
                        NSLayoutConstraint.activate([
                            mediaGalleryTrailingConstraint!,
                        ])
                    }
                    if let constraints = mediaStackTrailingConstraint {
                        NSLayoutConstraint.deactivate([constraints])
                    }
                default: break
                }

            } else {
                NSLayoutConstraint.deactivate([
                    mediaGalleryTrailingConstraint,
                ].compactMap { $0 })
            }
        }
    }

    /// the cell will be displayed in the tableview
    func willDisplay() {
        if let postCard = postCard,
           postCard.hasMediaAttachment, [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType),
           ![.small, .hidden].contains(self.cellVariant.mediaVariant)
        {
            if GlobalStruct.autoPlayVideos {
                video?.play()
            }
        }

        if let postCard = postCard, postCard.hasQuotePost, ![.small, .hidden].contains(self.cellVariant.mediaVariant) {
            postCard.preloadQuotePost()
        }

        header.startTimeUpdates()
        profilePic.willDisplay()
        quotePost?.willDisplay()
    }

    // the cell will end being displayed in the tableview
    func didEndDisplay() {
        if let postCard = postCard,
           postCard.hasMediaAttachment, [.singleVideo, .singleGIF].contains(postCard.mediaDisplayType)
        {
            video?.pause()
        }

        if let postCard = postCard, postCard.hasQuotePost,
           let quotePostCard = postCard.quotePostData,
           let video = quotePostCard.videoPlayer
        {
            video.pause()
        }

        header.stopTimeUpdates()
    }

    @objc private func onTextLongPress(recognizer: UIGestureRecognizer) {
        if let view = recognizer.view, let superview = recognizer.view?.superview {
            view.becomeFirstResponder()
            let menuController = UIMenuController.shared

            let copyItem = UIMenuItem(title: NSLocalizedString("generic.copy", comment: ""), action: #selector(copyText))
            menuController.menuItems = [copyItem]

            menuController.showMenu(from: superview, rect: view.frame)
        }
    }

    @objc private func onMetricPress(recognizer: UIGestureRecognizer) {
        if recognizer.view?.tag == MetricButtons.likes.rawValue {
            onButtonPress?(.likes, false, nil)
        }

        if recognizer.view?.tag == MetricButtons.reposts.rawValue {
            onButtonPress?(.reposts, false, nil)
        }

        if recognizer.view?.tag == MetricButtons.replies.rawValue {
            onButtonPress?(.replies, false, nil)
        }
    }

    @objc private func copyText() {
        UIPasteboard.general.setValue(postCard?.metaPostText?.original ?? "", forPasteboardType: "public.utf8-plain-text")
    }

    private func configureForDebugging(postCard: PostCardModel) {
        if let batchId = postCard.batchId, let batchItemIndex = postCard.batchItemIndex {
            postTextView.text = "\(batchId) - \(batchItemIndex)"

            if let mediaGallery = mediaGallery {
                mediaGalleryTrailingConstraint?.isActive = false
                mediaContainer.removeArrangedSubview(mediaGallery)
                mediaGallery.removeFromSuperview()
            }

            if let linkPreview = linkPreview {
                linkPreviewTrailingConstraint?.isActive = false
                mediaContainer.removeArrangedSubview(linkPreview)
                linkPreview.removeFromSuperview()
                linkPreview.prepareForReuse()
            }

            if let webview = webview {
                webviewTrailingConstraint?.isActive = false
                mediaContainer.removeArrangedSubview(webview)
                webview.removeFromSuperview()
                webview.prepareForReuse()
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

            contentWarningButton.isHidden = true
            NSLayoutConstraint.deactivate(contentWarningConstraints)
        }
    }

    func onThemeChange() {
        var backgroundColor = UIColor.custom.background
        if let postCard = postCard {
            if postCard.isPrivateMention {
                backgroundColor = .custom.OVRLYSoftContrast
            } else if postCard.isTipAccount {
                // tip background.
            }
        }

        self.backgroundColor = backgroundColor
        contentView.backgroundColor = backgroundColor
        postTextView.backgroundColor = backgroundColor
        wrapperStackView.backgroundColor = backgroundColor
        mainStackView.backgroundColor = backgroundColor
        contentStackView.backgroundColor = backgroundColor
        mediaStack?.backgroundColor = backgroundColor
        mediaContainer.backgroundColor = backgroundColor
        textAndSmallMediaStackView.backgroundColor = backgroundColor

        profilePic.onThemeChange()
        header.onThemeChange()
        poll?.onThemeChange()
        linkPreview?.onThemeChange()
        quotePost?.onThemeChange()
        image?.onThemeChange()
        metadata?.onThemeChange()
        footer.onThemeChange()
        footer.backgroundColor = contentView.backgroundColor

//        self.readMoreButton?.configure(backgroundColor: backgroundColor)

        // Update all items that use .custom colors
        contentWarningButton.backgroundColor = .custom.OVRLYSoftContrast
        deletedWarningButton.backgroundColor = .custom.OVRLYSoftContrast
        postTextView.textColor = .custom.mediumContrast
        parentThread.backgroundColor = .custom.feintContrast
        childThread.backgroundColor = .custom.feintContrast
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupUIFromSettings()
        configureMetaTextContent()
        onThemeChange()
    }
}

// MARK: - Handlers

extension PostCardCell {
    @objc func contentWarningButtonTapped(_: UIButton) {
        triggerHapticImpact(style: .light)
        contentWarningButton.isHidden = true
        contentWarningButton.isUserInteractionEnabled = false
        GlobalStruct.allCW.append(postCard?.id ?? "")
        postCard?.filterType = .none
        mediaGallery?.alpha = 1
        textAndSmallMediaStackView.alpha = 1
        mediaStack?.alpha = 1
        metadata?.alpha = 1
    }

    @objc func onReadMorePress() {
        if let postCard = postCard {
            onButtonPress?(.postDetails, true, .post(postCard))
        }
    }
}

// MARK: - MetaTextViewDelegate

extension PostCardCell: MetaLabelDelegate {
    func metaLabel(_: MetaLabel, didSelectMeta meta: Meta) {
        switch meta {
        case let .url(_, _, urlString, _):
            if let url = URL(string: urlString) {
                onButtonPress?(.link, true, .url(url))
            }
        case let .mention(_, mention, _):
            if case let .mastodon(status) = postCard?.data {
                onButtonPress?(.link, true, .mention((mention, status)))
            }
        case let .hashtag(_, hashtag, _):
            onButtonPress?(.link, true, .hashtag(hashtag))
        default:
            guard let postCard = postCard, type != .detail else { return }
            onButtonPress?(.postDetails, true, .post(postCard))
        }
    }
}

// MARK: - Context menu creators

extension PostCardCell {
    private func createContextMenuAction(_ title: String, _ buttonType: PostCardButtonType, isActive: Bool, onPress: @escaping PostCardButtonCallback, attributes: UIMenuElement.Attributes = []) -> UIAction {
        var color: UIColor = .black
        if GlobalStruct.overrideTheme == 1 || traitCollection.userInterfaceStyle == .light {
            color = .black
        } else if GlobalStruct.overrideTheme == 2 || traitCollection.userInterfaceStyle == .dark {
            color = .white
        }

        if attributes.contains(.destructive) {
            color = UIColor.systemRed
        }

        let action = UIAction(title: title,
                              image: isActive
                                  ? buttonType.activeIcon(symbolConfig: postCardSymbolConfig)?.withTintColor(color).withRenderingMode(.alwaysTemplate)
                                  : buttonType.icon(symbolConfig: postCardSymbolConfig)?.withTintColor(color).withRenderingMode(.alwaysTemplate),
                              identifier: nil)
        { _ in
            onPress(buttonType, isActive, nil)
        }
        action.accessibilityLabel = title
        action.attributes = attributes

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

            !postCard.isOwn ? createContextMenuAction(NSLocalizedString("post.report", comment: ""), .reportPost, isActive: false, onPress: onButtonPress, attributes: .destructive) : nil,

            createContextMenuAction(NSLocalizedString("post.sharePost", comment: ""), .share, isActive: false, onPress: onButtonPress),
            postCard.isOwn
                ? UIMenu(title: NSLocalizedString("post.modify", comment: ""), options: [], children: [
                    postCard.isPinned
                        ? createContextMenuAction(NSLocalizedString("post.pin.undo", comment: ""), .pinPost, isActive: true, onPress: onButtonPress)
                        : createContextMenuAction(NSLocalizedString("post.pin", comment: ""), .pinPost, isActive: false, onPress: onButtonPress),

                    createContextMenuAction(NSLocalizedString("post.edit", comment: ""), .editPost, isActive: false, onPress: onButtonPress),
                    createContextMenuAction(NSLocalizedString("post.delete", comment: ""), .deletePost, isActive: false, onPress: onButtonPress, attributes: .destructive),
                ])
                : nil,
        ].compactMap { $0 }

        return UIMenu(title: "", options: [.displayInline], children: options)
    }
}
