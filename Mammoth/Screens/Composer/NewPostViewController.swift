//
//  NewPostViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 07/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import AVFoundation
import AVKit
import Foundation
import LinkPresentation
import MobileCoreServices
import NaturalLanguage
import PhotosUI
import UIKit
import UniformTypeIdentifiers
#if canImport(ActivityKit)
    import ActivityKit
#endif

// swiftlint:disable:next type_body_length
class NewPostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UITextFieldDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SKPhotoBrowserDelegate, AVPlayerViewControllerDelegate, UIDocumentPickerDelegate, SwiftyGiphyViewControllerDelegate, UIDropInteractionDelegate {
    let kButtonSide = 70.0
    let kButtonToKeyboardGap = 20.0 // between the image buttons and keyboard
    let kCellLowerMargin = 20.0 // between image/visiblity buttons, and the cell content
    var keyboardRect: CGRect = CGRectZero
    let maxVideoSize: Int = 40 // in MB - Mastodon rejects videos > 40MB

    // top of the keyboard, in self.view coordinates
    var topOfKeyboard: CGFloat {
        if CGRectIsEmpty(keyboardRect) {
            return CGRectGetMaxY(view.bounds)
        } else {
            let keyboardInLocal = view.convert(keyboardRect.origin, from: nil)
            return keyboardInLocal.y
        }
    }

    var pickerController: UIDocumentPickerViewController?

    private var pendingRequestWorkItem: DispatchWorkItem?

    var visibImages = 0
    var spoilerText: String = ""
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var inReplyId: String = ""
    var currentFullName: String = ""
    var fromShare: Bool = false
    var fromShareV: Bool = false
    var fromShare2: Bool = false
    var fromNewDM: Bool = false
    var fromExpanded: String = ""
    var fromEdit: Status?
    var postCharacterCount: Int = 500 // characters remaining in this post
    var postCharacterCount2: Int = 500 // max characters allowed per post
    var formatToolbar = UIToolbar()
    var formatToolbar2 = UIToolbar()
    var scrollViewM = UIScrollView()
    var trimmedAtString: String = ""
    var canPost: Bool = false
    var whoCanReply: Visibility? = .public
    var whoCanReplyPill = UIButton()
    var allStatuses: [Status] = []
    var quoteString: String = ""
    var photoPickerView: PHPickerViewController!
    let photoPickerView2 = UIImagePickerController()
    var mediaData: Data = .init()
    var mediaIdStrings: [String] = []
    var mediaAttached: Bool = false // Looks like this is never cleared (?)
    var hasEditedText = false
    var hasEditedMedia = false
    var hasEditedMetadata = false // CW, Sensitive, Post Language
    var hasEditedPoll = false
    let numImages = 4
    var imageButton = [UIButton(), UIButton(), UIButton(), UIButton()]
    var audioAttached: Bool = false
    var videoAttached: Bool = false
    var videoAttachedCheckForAttachingImages: Bool = false // check whether videos have been attached when attempting to add images
    var doneOnce: Bool = false
    var currentAcct = AccountsManager.shared.currentAccount
    var currentUser: Account? {
        return (currentAcct as? MastodonAcctData)?.account
    }

    var itemLast = UIBarButtonItem()
    var fromPro: Bool = false
    var placeCursorAtEndOfText = true
    var proText: String = ""
    var cellPostText: String = "" // storage for the cell post text
    var cellPostTextView: UITextView? // reference to the cell post UITextView
    // quote post
    var followedByQuotedAccount: FollowManager.FollowStatus = .unknown
    var quotedAccountPublicSocialGraph = false
    var isQuotePost = false
    var quotedAccount: Account?
    var haveUpdatedPostWithQuoteURL = false
    var quotePostCell = ComposeQuotePostCell()
    // view
    var scrollView = UIScrollView()
    var cwHeight: CGFloat = 0
    let dateViewBG = UIButton()
    let dateView = UIView()
    let datePicker = UIDatePicker()
    var tempDate = Date()
    var scheduledTime: String?
    var userItemsAll: [Account] = []
    var tagsAll: [Tag] = []
    var keyboardSizeView = UIView() // tracks the keyboard view size
    var keyboardSizeHeightConstraint: NSLayoutConstraint?
    // video
    var assetWriter: AVAssetWriter!
    var assetWriterVideoInput: AVAssetWriterInput!
    var audioMicInput: AVAssetWriterInput!
    var videoURL: URL!
    var audioAppInput: AVAssetWriterInput!
    var channelLayout = AudioChannelLayout()
    var assetReader: AVAssetReader?
    let bitrate: NSNumber = .init(value: 1_500_000)
    var vUrl: URL!
    var doneImagesOnce: Bool = false
    private lazy var progressRing = [ALProgressRing(), ALProgressRing(), ALProgressRing(), ALProgressRing()]
    var visibleImages: Int = 0
    var uploaded = [false, false, false, false]
    var fromAction: Bool = false
    var otherInstance: String = ""
    var isSensitive: Bool = false
    var fromDetailReply: Bool = false
    var detailReplyToEdit: String = ""
    var gifAttached: Bool = false
    var mediaItemsDisabled: Bool = false
    var thumbnailAttempt: Int = 0
    var fromCamera: Bool = false
    var hasUpdatedReplyingTo: Bool = false
    var instanceCanEditAltText: Bool = true
    var isProcessingMediaServerside: Bool = false

    var isProcessingVideo: Bool = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileCell {
            cell.profileIcon.layer.borderColor = UIColor.custom.baseTint.cgColor
        }
        for cell in tableView.visibleCells {
            if let cell = cell as? PostCell {
                let cell = cell.p
                cell.postText.textColor = .custom.mainTextColor
                cell.linkPost.textColor = .custom.mainTextColor2
            }
        }
        dateViewBG.frame = view.frame

        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp
        navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
        updateCharacterCounts()
        updateSubviewFrames()
    }

    @objc func keyboardWillShowNotification(notification _: Notification) {
        createToolbar()
    }

    @objc func keyboardDidHideOrShowNotification(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardRect = keyboardFrame.cgRectValue
            if GlobalStruct.inVideoPlayer {
                keyboardRect = CGRectZero
            }
            updateSubviewFrames()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateReplyingToIfNecessary()
        tableView.reloadData()
        updateCharacterCounts()
    }

    private func updateReplyingToIfNecessary() {
        log.error("--- THINKING about DOING IT")
        // Only do this once, when first loading the view
        if !hasUpdatedReplyingTo, cellPostTextView != nil {
            hasUpdatedReplyingTo = true
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if !GlobalStruct.inVideoPlayer {
                    self.updateReplyingTo()
                }
            }
        }
    }

    // who can reply, reply people
    @objc func updateReplyingTo() {
        if fromNewDM {
            if fromExpanded != "" {
                cellPostText = "@\(fromExpanded) "
                tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            } else {
                cellPostText = "@"
                tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            }
        } else {
            if fromPro {} else {
                let serverPostVisibility = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.defaultPostVisibility
                whoCanReply = allStatuses.first?.reblog?.visibility ?? allStatuses.first?.visibility ?? serverPostVisibility ?? .public
            }
        }

        // create toolbar
        createToolbar()
        createToolbar2()

        if cellPostTextView != nil, cellPostTextView!.isFirstResponder {
            log.warning("toggling FR")
            cellPostTextView?.resignFirstResponder()
        }

        cellPostTextView?.becomeFirstResponder()

        if fromPro {
            cellPostText = proText
            updateQuotePostURL()
            tableView.beginUpdates()
            if isQuotePost {
                tableView.reloadSections(IndexSet(2 ... 2), with: .none)
            }
            tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            tableView.endUpdates()
        }

        var allMentions: [Mention] = []
        if let x = allStatuses.first?.reblog?.mentions ?? allStatuses.first?.mentions {
            allMentions = x
        }
        // Filter out certain accounts
        let mainReplyAccount = allStatuses.first?.reblog?.account ?? allStatuses.first?.account
        allMentions = allMentions.filter { x in
            let duplicateMention = x.acct == mainReplyAccount?.acct // make sure we aren't duplicating mentions if someone pings themself
            let pingingSelf = x.url == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.url // make sure we aren't pinging ourself
            return !(duplicateMention || pingingSelf)
        }
        allMentions = allMentions.filter { x in
            if GlobalStruct.excludeUsers.contains(x.id) {
                return false
            } else {
                return true
            }
        }

        if allStatuses.isEmpty {} else {
            // change placeholder text
            if let _ = allStatuses.first?.reblog?.id ?? allStatuses.first?.id {
                if quoteString.isEmpty {
                    var moreUsers = ""
                    _ = allMentions.map { x in
                        if x.acct.contains("@") {
                            moreUsers = "\(moreUsers) @\(x.acct)"
                        } else {
                            if self.otherInstance != "" {
                                moreUsers = "\(moreUsers) @\(x.acct)@\(self.otherInstance)"
                            } else {
                                moreUsers = "\(moreUsers) @\(x.acct)"
                            }
                        }
                    }
                    if mainReplyAccount?.url == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.url ?? "" {
                        if moreUsers == "" {} else {
                            cellPostText = "\(moreUsers) "
                            tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                        }
                    } else {
                        var mainReplyString = ""
                        if mainReplyAccount?.acct.contains("@") ?? false {
                            cellPostText = "@\(mainReplyAccount!.acct)\(moreUsers) "
                            tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                        } else {
                            if mainReplyAccount?.server != (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.server {
                                cellPostText = "@\(mainReplyAccount?.fullAcct ?? "")\(moreUsers) "
                                mainReplyString = "\(mainReplyAccount?.fullAcct ?? "")"
                                tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                            } else {
                                cellPostText = "@\(mainReplyAccount?.acct ?? "")\(moreUsers) "
                                tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                            }
                        }

                        // select moreUsers text with cursor
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if let cellPostTextView = self.cellPostTextView {
                                if let startPos = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: mainReplyString.count + 2) {
                                    if let endPos = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: mainReplyString.count + 2 + moreUsers.count) {
                                        cellPostTextView.selectedTextRange = cellPostTextView.textRange(from: startPos, to: endPos)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            spoilerText = allStatuses.first?.spoilerText ?? ""
            if spoilerText != "" {
                cwHeight = UITableView.automaticDimension
                tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                createToolbar()
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                    cell.altText.placeholder = "Content warning..."
                    cell.altText.becomeFirstResponder()
                    cell.altText.text = spoilerText
                    cell.altText.isHidden = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
                }
            }
        }

        // display media from Share Extension
        if fromShare {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.addMediaFromShare()
            }
        }
        // display videos from Share Extension
        if fromShareV {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.addVideosFromShare()
            }
        }
        // display text from Share Extension
        if fromShare2 {
            addTextFromShare()
        }

        // fill in edit post details
        if let stat = fromEdit {
            // Edited posts can't modify their visibility
            whoCanReplyPill.removeFromSuperview()
            whoCanReply = stat.visibility
            cellPostText = stat.content.stripHTML()
            _ = stat.mentions.map { x in
                cellPostText = cellPostText.replacingOccurrences(of: x.username, with: x.acct)
            }
            tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            if let pollOptions = stat.poll?.options {
                let date1 = stat.poll?.expiresAt ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = GlobalStruct.dateFormat
                let date = dateFormatter.date(from: date1)

                let expiresIn = date ?? Date()
                let diff = Calendar.current.dateComponents([.second], from: Date(), to: expiresIn).second ?? 0
                var str: [String] = []
                _ = pollOptions.map { x in
                    str.append(x.title)
                }
                let a: [Any] = [str, diff, stat.poll?.multiple ?? false, false]
                GlobalStruct.newPollPost = a
                createToolbar()
            }
            spoilerText = stat.spoilerText.stripHTML()
            if spoilerText != "" {
                cwHeight = UITableView.automaticDimension
                tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                createToolbar()
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                    cell.altText.placeholder = "Content warning..."
                    cell.altText.becomeFirstResponder()
                    cell.altText.text = spoilerText
                    cell.altText.isHidden = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
                }
            }

            // media
            if !stat.mediaAttachments.isEmpty {
                isSensitive = stat.sensitive ?? false

                for mainIndex in 0 ..< numImages {
                    if stat.mediaAttachments.count == mainIndex + 1 {
                        for index in 0 ... mainIndex {
                            mediaIdStrings.append(stat.mediaAttachments[index].id)
                            if stat.mediaAttachments[index].type == .video || stat.mediaAttachments[index].type == .gifv {
                                if let ur = URL(string: stat.mediaAttachments[index].url ?? stat.mediaAttachments[index].previewURL!) {
                                    videoAttached = true
                                    vUrl = ur
                                    tryDisplayThumbnail(url: vUrl)
                                }
                            } else if index == 0, stat.mediaAttachments[0].type == .audio {
                                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
                                let photoToAttach = UIImage(systemName: "waveform.path", withConfiguration: symbolConfig)?.withTintColor(UIColor.black.withAlphaComponent(0.2), renderingMode: .alwaysOriginal)
                                imageButton[0].backgroundColor = .custom.baseTint
                                imageButton[0].setImage(photoToAttach, for: .normal)
                                imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                    self.imageButton[0].alpha = 1
                                    self.imageButton[0].transform = CGAffineTransform.identity
                                }, completion: { _ in
                                })
                                if let ur = URL(string: stat.mediaAttachments[0].url ?? stat.mediaAttachments[0].previewURL!) {
                                    audioAttached = true
                                    videoAttached = false
                                    vUrl = ur
                                    createToolbar()
                                }
                            } else {
                                imageButton[index].sd_setImage(with: URL(string: stat.mediaAttachments[index].url ?? stat.mediaAttachments[index].previewURL!), for: .normal)
                            }
                            if stat.mediaAttachments[index].type == .gifv {
                                videoAttached = false
                                gifAttached = true
                            }
                            imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                            imageButton[index].backgroundColor = .custom.baseTint
                            UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                self.imageButton[index].alpha = 1
                                self.imageButton[index].transform = CGAffineTransform.identity
                            }, completion: { _ in
                            })
                        }

                        // Disable remaining buttons
                        for index in mainIndex + 1 ..< numImages {
                            imageButton[index].isUserInteractionEnabled = false
                        }
                    }
                }
            } else {
                for index in 0 ..< numImages {
                    imageButton[index].alpha = 0
                }
            }
        }

        parseText()
        updateCharacterCounts()
        if isQuotePost {
            moveCursorToBeginning()
        }
        // Handle the @ DM case
        if fromNewDM, fromExpanded == "" {
            moveCursorToEnd()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.cellPostTextView?.resignFirstResponder()
        }
    }

    @objc func updateToolbar() {
        createToolbar()
        updatePostButton()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let z = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PostCell {
            if scrollView.contentOffset.y + 1 < (z.bounds.size.height - (navigationController?.navigationBar.bounds.size.height ?? 0)) {
                for index in 0 ..< numImages {
                    // Delays: .06, .04, .02, .00
                    UIView.animate(withDuration: 0.65, delay: 0.02 * Double(numImages - index - 1), usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                        self.imageButton[index].alpha = 0
                        self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                    }, completion: { _ in
                    })
                }
            } else {
                for index in 0 ..< numImages {
                    if imageButton[index].currentImage != nil {
                        // Delays: .00, .02, .04, .06
                        UIView.animate(withDuration: 0.65, delay: 0.02 * Double(index), usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[index].alpha = 1
                            self.imageButton[index].transform = CGAffineTransform.identity
                        }, completion: { _ in
                        })
                    }
                }
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = .custom.backgroundTint
            setupNavBar(.custom.backgroundTint)
        } else {
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                view.backgroundColor = .custom.backgroundTint
                setupNavBar(.custom.backgroundTint)
            case .dark:
                view.backgroundColor = .secondarySystemBackground
                setupNavBar(.secondarySystemBackground)
            @unknown default:
                log.error("Failed to determine userInterfaceStyle")
                view.backgroundColor = .custom.backgroundTint
                setupNavBar(.custom.backgroundTint)
            }
        }
    }

    func setupNavBar(_ col: UIColor) {
        // set up nav bar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = col
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp
        navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        let sendPost = UIKeyCommand(input: "\r", modifierFlags: [.command], action: #selector(sendTap))
        sendPost.discoverabilityTitle = "Post Post"
        if #available(iOS 15, *) {
            sendPost.wantsPriorityOverSystemBehavior = true
        }
        let closeWindow = UIKeyCommand(input: "w", modifierFlags: [.command], action: #selector(dismissTap))
        closeWindow.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            closeWindow.wantsPriorityOverSystemBehavior = true
        }
        return [sendPost, closeWindow]
    }

    @objc func translateAdded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.cellPostText = GlobalStruct.tempPostTranslate
            GlobalStruct.tempPostTranslate = ""
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
//        self.saveDraft()
    }

    func addMediaFromShare() {
        let sharedGroupContainerDirectory = FileManager().containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.theblvd.mammoth.wormhole")
        guard let fileURL = sharedGroupContainerDirectory?.appendingPathComponent("savedMedia.json") else { return }
        guard let fileContent = try? Data(contentsOf: fileURL) else { return }

        let photoToAttach = UIImage(data: fileContent) ?? UIImage()

        setupImages()

        for index in 1 ..< numImages { // All but the first
            imageButton[index].alpha = 0
        }
        imageButton[0].setImage(photoToAttach, for: .normal)
        imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
            self.imageButton[0].alpha = 1
            self.imageButton[0].transform = CGAffineTransform.identity
        }, completion: { _ in
        })

        mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
        videoAttached = false
        gifAttached = false
        attachPhoto()
        cellPostTextView?.resignFirstResponder()
        cellPostTextView?.becomeFirstResponder()
    }

    func addVideosFromShare() {
        let sharedGroupContainerDirectory = FileManager().containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.theblvd.mammoth.wormhole")
        guard let fileURL = sharedGroupContainerDirectory?.appendingPathComponent("savedMedia.json") else { return }
        guard let fileContent = try? Data(contentsOf: fileURL) else { return }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoURL = documentsURL.appendingPathComponent("video.mp4")
        try? fileContent.write(to: videoURL)

        setupImages()

        vUrl = videoURL
        tryDisplayThumbnail(url: videoURL)
        for index in 1 ..< numImages { // All but the first
            imageButton[index].alpha = 0
        }
        imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
            self.imageButton[0].alpha = 1
            self.imageButton[0].transform = CGAffineTransform.identity
        }, completion: { _ in
        })

        videoAttached = true
        mediaData = fileContent
        Task {
            await self.attachAnimatedMedia()
        }

        cellPostTextView?.resignFirstResponder()
        cellPostTextView?.becomeFirstResponder()
    }

    func addTextFromShare() {
        let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole")
        if let theData = userDefaults?.value(forKey: "shareExtensionText") as? String {
            cellPostText = theData
            cellPostTextView?.resignFirstResponder()
            cellPostTextView?.becomeFirstResponder()
            tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            hasEditedText = true
            updatePostButton()
        }
    }

    override func paste(_: Any?) {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasImages {
            triggerHapticImpact(style: .light)
            let photoToAttach = pasteboard.image ?? UIImage()

            // attach photo
            if videoAttached {
                imageButton[0].alpha = 0
            }
            for index in 0 ..< numImages {
                if imageButton[index].alpha == 0 {
                    imageButton[index].setImage(photoToAttach, for: .normal)
                    imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                        self.imageButton[index].alpha = 1
                        self.imageButton[index].transform = CGAffineTransform.identity
                    }, completion: { _ in
                    })
                    break
                }
            }
            mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
            videoAttached = false
            gifAttached = false
            attachPhoto()
            cellPostTextView?.resignFirstResponder()
            cellPostTextView?.becomeFirstResponder()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = .custom.backgroundTint
            setupNavBar(.custom.backgroundTint)
        } else {
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                view.backgroundColor = .custom.backgroundTint
                setupNavBar(.custom.backgroundTint)
            case .dark:
                view.backgroundColor = .secondarySystemBackground
                setupNavBar(.secondarySystemBackground)
            @unknown default:
                log.error("Failed to determine userInterfaceStyle")
                view.backgroundColor = .custom.backgroundTint
                setupNavBar(.custom.backgroundTint)
            }
        }

        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)

        GlobalStruct.altAdded = [:]
        GlobalStruct.whichImagesAltText = []
        GlobalStruct.excludeUsers = []
        GlobalStruct.showingNewPostComposer = true
        GlobalStruct.placeID = ""
        GlobalStruct.mediaEditID = ""
        GlobalStruct.mediaEditDescription = ""

        view.addSubview(keyboardSizeView)
        keyboardSizeView.backgroundColor = .clear
        keyboardSizeView.translatesAutoresizingMaskIntoConstraints = false
        keyboardSizeView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        keyboardSizeView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        keyboardSizeView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        keyboardSizeHeightConstraint = keyboardSizeView.heightAnchor.constraint(equalToConstant: 0)
        keyboardSizeHeightConstraint?.isActive = true

        whoCanReplyPill.backgroundColor = .custom.quoteTint
        whoCanReplyPill.layer.cornerCurve = .continuous
        whoCanReplyPill.layer.cornerRadius = 10
        whoCanReplyPill.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        whoCanReplyPill.layer.shadowOffset = CGSize(width: 3, height: 3)
        whoCanReplyPill.layer.shadowOpacity = 1.0
        whoCanReplyPill.layer.shadowRadius = 10.0
        let existingInsets = whoCanReplyPill.titleEdgeInsets
        whoCanReplyPill.contentEdgeInsets = UIEdgeInsets(top: existingInsets.top, left: 10, bottom: existingInsets.bottom, right: 10)
        view.addSubview(whoCanReplyPill)
        whoCanReplyPill.translatesAutoresizingMaskIntoConstraints = false
        whoCanReplyPill.heightAnchor.constraint(equalToConstant: 46).isActive = true
        whoCanReplyPill.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        whoCanReplyPill.bottomAnchor.constraint(equalTo: keyboardSizeView.topAnchor, constant: -kButtonToKeyboardGap).isActive = true

        refreshDrafts()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHideOrShowNotification), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHideOrShowNotification), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveDraft), name: NSNotification.Name(rawValue: "saveDraft"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateToolbar), name: NSNotification.Name(rawValue: "updateToolbar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreFromDrafts), name: NSNotification.Name(rawValue: "restoreFromDrafts"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreFromTemplate), name: NSNotification.Name(rawValue: "restoreFromTemplate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(canvasAdded), name: NSNotification.Name(rawValue: "canvasAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(translateAdded), name: NSNotification.Name(rawValue: "translateAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(createToolbar), name: NSNotification.Name(rawValue: "createToolbar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addEmoji), name: NSNotification.Name(rawValue: "addEmoji"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePostButton), name: NSNotification.Name(rawValue: "updatePostButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(quotePostDidUpdate), name: didUpdateQuotePostNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.followStatusNotification), name: didChangeFollowStatusNotification, object: nil)

        InstanceFeatures.supportsFeature(.editingAltText) { supported, instanceInfo in
            DispatchQueue.main.async {
                self.postCharacterCount = instanceInfo?.configuration?.statuses?.maxCharacters ?? 500
                self.postCharacterCount2 = self.postCharacterCount
                self.navigationItem.title = "\(self.postCharacterCount)"
                self.navigationItem.accessibilityLabel = "\(self.postCharacterCount) characters remaining"
                self.instanceCanEditAltText = supported
                if !self.instanceCanEditAltText {
                    self.setupImages2()
                }
                self.updateCharacterCounts()
            }
        }

        GlobalStruct.canPostPost = true

        // set up nav
        setupNav()

        // set up table
        setupTable()

        // update quoted account relationship to currentAccount
        if isQuotePost {
            Task.detached(priority: .userInitiated) { [weak self] in
                await self?.fetchQuotePostMetaData()
            }
        }

        updateCharacterCounts()
    }

    @objc func addEmoji() {
        if cellPostText == "" {
            cellPostText = ":\(GlobalStruct.emoticonToAdd):"
        } else if cellPostText.last == " " {
            cellPostText = "\(cellPostText):\(GlobalStruct.emoticonToAdd):"
        } else {
            cellPostText = "\(cellPostText) :\(GlobalStruct.emoticonToAdd):"
        }
        if let textRange = cellPostTextView?.selectedTextRange {
            cellPostTextView!.replace(textRange, withText: ":\(GlobalStruct.emoticonToAdd): ")
        }
    }

    func dropInteraction(_: UIDropInteraction, sessionDidEnter _: UIDropSession) {}

    func dropInteraction(_: UIDropInteraction, sessionDidExit _: UIDropSession) {}

    func dropInteraction(_: UIDropInteraction, sessionDidEnd _: UIDropSession) {}

    func dropInteraction(_: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        var dropProposal = UITableViewDropProposal(operation: .cancel)
        guard session.items.count <= 4 else { return dropProposal }
        dropProposal = UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
        return dropProposal
    }

    func dropInteraction(_: UIDropInteraction, performDrop session: UIDropSession) {
        // disable posting
        updatePostButton()

        _ = session.items.map { x in
            if x.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeGIF as String) {
                x.itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeGIF as String) { data, _ in
                    DispatchQueue.main.async {
                        triggerHapticImpact(style: .light)
                        // attach gif
                        self.imageButton[0].setImage(UIImage(data: data ?? Data()), for: .normal)
                        for index in 1 ..< self.numImages {
                            self.imageButton[index].alpha = 0
                        }
                        self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[0].alpha = 1
                            self.imageButton[0].transform = CGAffineTransform.identity
                        }, completion: { _ in
                        })

                        self.mediaData = data ?? Data()
                        self.videoAttached = false
                        self.gifAttached = true
                        self.attachPhoto()
                        self.cellPostTextView?.resignFirstResponder()
                        self.cellPostTextView?.becomeFirstResponder()
                    }
                }
            } else {
                if x.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    x.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        DispatchQueue.main.async {
                            if let photoToAttach = image as? UIImage {
                                triggerHaptic3Impact()
                                // attach photo
                                if self.videoAttached {
                                    self.imageButton[0].alpha = 0
                                }

                                if let index = self.imageButton.firstIndex(where: { imageButton in
                                    imageButton.alpha == 0
                                }) {
                                    self.imageButton[index].setImage(photoToAttach, for: .normal)
                                    self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                        self.imageButton[index].alpha = 1
                                        self.imageButton[index].transform = CGAffineTransform.identity
                                    }, completion: { _ in
                                    })
                                }

                                self.mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
                                self.videoAttached = false
                                self.gifAttached = false
                                self.attachPhoto()
                                self.cellPostTextView?.resignFirstResponder()
                                self.cellPostTextView?.becomeFirstResponder()
                            }
                        }
                    }
                }
                if x.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    x.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.movie") { data, _ in
                        DispatchQueue.main.async {
                            // attach video
                            self.videoAttached = true
                            self.mediaData = data ?? Data()
                            Task {
                                await self.attachAnimatedMedia()
                            }
                        }
                    }
                    x.itemProvider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: [:]) { [self] videoURL, _ in
                        DispatchQueue.main.async {
                            if let url = videoURL as? URL {
                                triggerHaptic3Impact()
                                self.setupImages2()

                                self.cellPostTextView?.resignFirstResponder()
                                self.cellPostTextView?.becomeFirstResponder()

                                self.vUrl = url
                                self.tryDisplayThumbnail(url: url)
                                for index in 1 ..< self.numImages { // All but the first
                                    self.imageButton[index].alpha = 0
                                }
                                self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                    self.imageButton[0].alpha = 1
                                    self.imageButton[0].transform = CGAffineTransform.identity
                                }, completion: { _ in
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if fromCamera {
            fromCamera = false
        } else {
            NotificationCenter.default.removeObserver(self)
        }
        GlobalStruct.showingNewPostComposer = false
        GlobalStruct.newPollPost = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // set footer, so that the view scrolls to the main composer area
        let footerHe = tableView.bounds.height - tableView.rectForRow(at: IndexPath(row: 1, section: 1)).height - view.safeAreaInsets.bottom - view.safeAreaInsets.top
        let customViewFooter = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: footerHe))
        customViewFooter.isUserInteractionEnabled = false
        tableView.tableFooterView = customViewFooter
        tableView.scrollToRow(at: IndexPath(row: 1, section: 1), at: .top, animated: true)

        if doneOnce == false {
            // set up images
            setupImages()
            doneOnce = true
        }

        if doneImagesOnce == false {
            updateSubviewFrames()
            doneImagesOnce = true
        }

        if isQuotePost {
            tableView.beginUpdates()
            tableView.reloadSections(IndexSet(2 ... 2), with: .none)
            tableView.endUpdates()
        }

        // menu items
        let lowercaseMenuItem = UIMenuItem(title: "Lower Case", action: #selector(lowercaseTapped))
        let uppercaseMenuItem = UIMenuItem(title: "Upper Case", action: #selector(uppercaseTapped))
        let randomcaseMenuItem = UIMenuItem(title: "Random Case", action: #selector(randomcaseTapped))
        UIMenuController.shared.menuItems = [lowercaseMenuItem, uppercaseMenuItem, randomcaseMenuItem]

        if let cellPostTextView {
            cellPostTextView.becomeFirstResponder()

            if placeCursorAtEndOfText {
                cellPostTextView.selectedTextRange = cellPostTextView.textRange(
                    from: cellPostTextView.endOfDocument,
                    to: cellPostTextView.endOfDocument
                )
            }
        }

        createToolbar()
    }

    @objc func lowercaseTapped() {
        if let cellPostTextView {
            if let textRange = cellPostTextView.selectedTextRange {
                let selectedText = cellPostTextView.text(in: textRange)
                cellPostTextView.text = cellPostTextView.text.replacingOccurrences(of: selectedText ?? "", with: selectedText?.lowercased() ?? selectedText ?? "")
                cellPostTextView.selectedTextRange = textRange
            }
        }
    }

    @objc func uppercaseTapped() {
        if let cellPostTextView {
            if let textRange = cellPostTextView.selectedTextRange {
                let selectedText = cellPostTextView.text(in: textRange)
                cellPostTextView.text = cellPostTextView.text.replacingOccurrences(of: selectedText ?? "", with: selectedText?.uppercased() ?? selectedText ?? "")
                cellPostTextView.selectedTextRange = textRange
            }
        }
    }

    @objc func randomcaseTapped() {
        if let cellPostTextView {
            if let textRange = cellPostTextView.selectedTextRange {
                let selectedText = cellPostTextView.text(in: textRange)
                let result = (selectedText ?? "").map {
                    if Int.random(in: 0 ... 1) == 0 {
                        return String($0).lowercased()
                    }
                    return String($0).uppercased()
                }.joined(separator: "")
                cellPostTextView.text = cellPostTextView.text.replacingOccurrences(of: selectedText ?? "", with: result)
                cellPostTextView.selectedTextRange = textRange
            }
        }
    }

    func updateSubviewFrames() {
        #if targetEnvironment(macCatalyst)
            for index in 0 ..< numImages {
                // x position is 20, 100, 180, 260
                imageButton[index].frame = CGRect(x: 20 + CGFloat(index * 80), y: view.bounds.height - 55 - 90, width: kButtonSide, height: kButtonSide)
            }
        #elseif !targetEnvironment(macCatalyst)
            if UIDevice.current.userInterfaceIdiom == .pad {
                for index in 0 ..< numImages {
                    // x position is 20, 100, 180, 260
                    imageButton[index].frame = CGRect(x: 20 + CGFloat(index * 80), y: CGRectGetMaxY(tableView.frame) - kButtonSide - kButtonToKeyboardGap, width: kButtonSide, height: kButtonSide)
                }
            } else {
                for index in 0 ..< numImages {
                    // x position is 20, 100, 180, 260
                    imageButton[index].frame = CGRect(x: 20 + CGFloat(index * 80), y: CGRectGetMaxY(tableView.frame) - kButtonSide - kButtonToKeyboardGap, width: kButtonSide, height: kButtonSide)
                }
            }
        #endif
        // Update the tableView height constraint
        keyboardSizeHeightConstraint?.constant = CGRectGetMaxY(keyboardSizeView.frame) - topOfKeyboard
    }

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        dismiss(animated: true, completion: nil)
    }

    func setupNav() {
        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn1.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysTemplate), for: .normal)
        btn1.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn1.layer.cornerRadius = 14
        btn1.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn1.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn1.addTarget(self, action: #selector(dismissTap), for: .touchUpInside)
        btn1.accessibilityLabel = NSLocalizedString("generic.dismiss", comment: "")
        let moreButton0 = UIBarButtonItem(customView: btn1)
        navigationItem.setLeftBarButton(moreButton0, animated: true)

        btn2.setImage(UIImage(systemName: "arrow.up", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysTemplate), for: .normal)
        btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn2.layer.cornerRadius = 14
        btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn2.addTarget(self, action: #selector(sendTap), for: .touchUpInside)
        btn2.accessibilityLabel = NSLocalizedString("composer.post", comment: "")
        let moreButton1 = UIBarButtonItem(customView: btn2)
        navigationItem.setRightBarButton(moreButton1, animated: true)
    }

    func setupTable() {
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
        tableView.register(AltTextCell2.self, forCellReuseIdentifier: "AltTextCell2")
        tableView.register(ComposeCell.self, forCellReuseIdentifier: "ComposeCell")
        tableView.alpha = 1
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        view.sendSubviewToBack(tableView)

        #if targetEnvironment(macCatalyst)
            view.addSubview(formatToolbar)
            view.addSubview(scrollView)
        #endif
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: keyboardSizeView.topAnchor).isActive = true
    }

    func setupImages() {
        updateSubviewFrames()
        if fromShare || fromShareV {} else {
            if fromEdit == nil {
                for index in 0 ..< numImages {
                    imageButton[index].alpha = 0
                }
            }
        }
        setupImages2()
    }

    func setupImages2() {
        DispatchQueue.main.async {
            // check whether there is existing media from an edit
            var mediaCount = 0
            if let fromEditMediaCount = self.fromEdit?.mediaAttachments.count {
                mediaCount = fromEditMediaCount
            }

            if !self.audioAttached {
                self.imageButton[0].backgroundColor = .clear
            }
            self.imageButton[0].layer.cornerRadius = 10
            self.imageButton[0].layer.cornerCurve = .continuous
            self.imageButton[0].imageView?.contentMode = .scaleAspectFill
            self.imageButton[0].layer.masksToBounds = true
            self.view.addSubview(self.imageButton[0])

            let image_string = NSLocalizedString("composer.media.image", comment: "")
            let view_media = NSLocalizedString("composer.media.viewMedia", comment: "")
            let add_media_description = NSLocalizedString("composer.media.altText", comment: "")
            var mediaType: String = NSLocalizedString("composer.media.video", comment: "")
            if self.gifAttached {
                mediaType = NSLocalizedString("composer.media.gif", comment: "")
            }
            let vie0 = UIAction(title: String.localizedStringWithFormat(view_media, mediaType), image: UIImage(systemName: "eye"), identifier: nil) { _ in
                self.viewVideo()
            }
            vie0.accessibilityLabel = String.localizedStringWithFormat(view_media, mediaType)
            let vie1 = UIAction(title: String.localizedStringWithFormat(view_media, image_string), image: UIImage(systemName: "eye"), identifier: nil) { _ in
                self.viewImages(self.imageButton[0])
            }
            vie1.accessibilityLabel = String.localizedStringWithFormat(view_media, image_string)
            let alt1 = UIAction(title: String.localizedStringWithFormat(add_media_description, image_string), image: UIImage(systemName: "character.cursor.ibeam"), identifier: nil) { _ in
                self.hasEditedMetadata = true
                let vc = AltTextViewController()
                vc.currentImage = self.imageButton[0].currentImage ?? UIImage()
                if let x = GlobalStruct.altAdded[0] {
                    vc.theAltText = x
                }
                if let stat = self.fromEdit {
                    if stat.mediaAttachments.count >= 1 {
                        vc.theAltText = stat.mediaAttachments[0].description ?? ""
                    }
                }
                if self.mediaIdStrings.count > 0 {
                    vc.id = self.mediaIdStrings[0]
                    vc.whichImagesAltText = 0
                    self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                }
            }
            alt1.accessibilityLabel = String.localizedStringWithFormat(add_media_description, image_string)
            if (self.instanceCanEditAltText == false && self.fromEdit != nil && mediaCount >= 1) || (self.mediaIdStrings.count < 1) {
                alt1.attributes = .hidden
            }
            let remove1 = UIAction(title: NSLocalizedString("generic.remove", comment: ""), image: UIImage(systemName: "trash"), identifier: nil) { _ in
                triggerHapticImpact(style: .light)

                GlobalStruct.whichImagesAltText = GlobalStruct.whichImagesAltText.filter { x in
                    x != 0
                }
                self.hasEditedMedia = true
                self.updatePostButton()
                self.uploaded[0] = false
                self.isProcessingVideo = false

                // Move all other images down by one since this one was deleted
                for indexToMove in 0 ..< self.numImages - 1 {
                    self.imageButton[indexToMove].setImage(self.imageButton[indexToMove + 1].currentImage, for: .normal)
                }

                // Clear alpha of any empty images
                for indexToClear in 0 ..< self.numImages - 1 {
                    if self.imageButton[indexToClear].currentImage == nil {
                        self.imageButton[indexToClear].alpha = 0
                    }
                }
                // Clear out the last button
                self.imageButton[self.numImages - 1].alpha = 0
                self.imageButton[self.numImages - 1].setImage(nil, for: .normal)

                if self.mediaIdStrings.count > 0 {
                    self.mediaIdStrings[0] = ""
                }
                self.updatePostButton()
                self.videoAttached = false
                if self.audioAttached {
                    self.audioAttached = false
                    self.visibleImages -= 1
                    self.mediaIdStrings = []
                }
                self.createToolbar()
                self.setupImages2()
            }
            remove1.accessibilityLabel = NSLocalizedString("generic.remove", comment: "")
            remove1.attributes = .destructive

            if self.canPost || self.fromEdit != nil {
                if self.audioAttached {
                    let itemMenu1 = UIMenu(title: "", options: [], children: [remove1])
                    self.imageButton[0].menu = itemMenu1
                } else {
                    if self.videoAttached {
                        let itemMenu1 = UIMenu(title: "", options: [], children: [vie0, remove1])
                        self.imageButton[0].menu = itemMenu1
                    } else if self.gifAttached {
                        let itemMenu1 = UIMenu(title: "", options: [], children: [vie0, alt1, remove1])
                        self.imageButton[0].menu = itemMenu1
                    } else {
                        let itemMenu1 = UIMenu(title: "", options: [], children: [vie1, alt1, remove1])
                        self.imageButton[0].menu = itemMenu1
                    }
                }
                self.imageButton[0].showsMenuAsPrimaryAction = true
            }

            // Skip the first cell (was taken care of above in custom code)
            for index in 1 ..< self.numImages {
                self.imageButton[index].backgroundColor = .clear
                self.imageButton[index].layer.cornerRadius = 10
                self.imageButton[index].layer.cornerCurve = .continuous
                self.imageButton[index].imageView?.contentMode = .scaleAspectFill
                self.imageButton[index].layer.masksToBounds = true
                self.view.addSubview(self.imageButton[index])

                let vie2 = UIAction(title: String.localizedStringWithFormat(view_media, image_string), image: UIImage(systemName: "eye"), identifier: nil) { _ in
                    self.viewImages(self.imageButton[index])
                }
                vie2.accessibilityLabel = String.localizedStringWithFormat(view_media, image_string)
                let alt2 = UIAction(title: String.localizedStringWithFormat(add_media_description, image_string), image: UIImage(systemName: "character.cursor.ibeam"), identifier: nil) { _ in
                    self.hasEditedMetadata = true
                    let vc = AltTextViewController()
                    vc.currentImage = self.imageButton[index].currentImage ?? UIImage()
                    if let x = GlobalStruct.altAdded[index] {
                        vc.theAltText = x
                    }
                    if let stat = self.fromEdit {
                        if stat.mediaAttachments.count >= index + 1 {
                            vc.theAltText = stat.mediaAttachments[index].description ?? ""
                        }
                    }
                    if self.mediaIdStrings.count > index {
                        vc.id = self.mediaIdStrings[index]
                        vc.whichImagesAltText = index
                        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                    }
                }
                alt2.accessibilityLabel = String.localizedStringWithFormat(add_media_description, image_string)
                // Disable this if (1) editing from an instance that doesn't support it and there's media to edit, OR
                //                 (3) there's no text placeholder - it should have been added in attachPhoto()/similar
                if (self.instanceCanEditAltText == false && self.fromEdit != nil && mediaCount >= index + 1) ||
                    (self.mediaIdStrings.count < index + 1)
                {
                    alt2.attributes = .hidden
                }
                let remove2 = UIAction(title: NSLocalizedString("generic.remove", comment: ""), image: UIImage(systemName: "trash"), identifier: nil) { _ in
                    triggerHapticImpact(style: .light)
                    GlobalStruct.whichImagesAltText = GlobalStruct.whichImagesAltText.filter { x in
                        x != index
                    }
                    self.hasEditedMedia = true
                    self.updatePostButton()
                    self.uploaded[index] = false

                    // Move all other images down by one since this one was deleted
                    for indexToMove in index ..< self.numImages - 1 {
                        self.imageButton[indexToMove].setImage(self.imageButton[indexToMove + 1].currentImage, for: .normal)
                    }
                    // Clear alpha of any empty images
                    for indexToClear in 0 ..< self.numImages {
                        if self.imageButton[indexToClear].currentImage == nil {
                            self.imageButton[indexToClear].alpha = 0
                        }
                    }
                    // Clear out the last button
                    self.imageButton[self.numImages - 1].alpha = 0
                    self.imageButton[self.numImages - 1].setImage(nil, for: .normal)

                    if self.mediaIdStrings.count > index {
                        self.mediaIdStrings[index] = ""
                    }

                    self.updatePostButton()
                }
                remove2.accessibilityLabel = NSLocalizedString("generic.remove", comment: "")
                remove2.attributes = .destructive
                let itemMenu2 = UIMenu(title: "", options: [], children: [vie2, alt2, remove2])
                if self.canPost || self.fromEdit != nil {
                    self.imageButton[index].menu = itemMenu2
                    self.imageButton[index].showsMenuAsPrimaryAction = true
                }
            }
        }
    }

    func viewVideo() {
        if vUrl == nil {
            let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.mp4")
            GIF2MP4(data: mediaData)?.convertAndExport(to: tempUrl, completion: {
                self.vUrl = tempUrl
                self.viewVideo()
            })
        } else {
            let player = AVPlayer(url: vUrl)
            let vc = CustomVideoPlayer()
            vc.delegate = self
            vc.allowsPictureInPicturePlayback = true

            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { _ in
                player.seek(to: CMTime.zero)
                player.play()
            }

            vc.player = player
            GlobalStruct.inVideoPlayer = true
            getTopMostViewController()?.present(vc, animated: true) {
                vc.player?.play()
            }
        }
    }

    func viewImages(_ image: UIButton) {
        var images = [SKPhoto]()
        let photo = SKPhoto.photoWithImage(image.currentImage ?? UIImage())
        photo.shouldCachePhotoURLImage = true
        images.append(photo)
        let originImage = image.currentImage ?? UIImage()
        let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: image, imageText: "", imageText2: 0, imageText3: 0, imageText4: "")
        browser.delegate = self
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
    }

    @objc func createToolbar() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        formatToolbar.tintColor = .custom.baseTint
        formatToolbar.barStyle = UIBarStyle.default
        formatToolbar.isTranslucent = false
        formatToolbar.barTintColor = .custom.quoteTint

        let fixedSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        fixedSpacer.width = 10
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)

        // items
        let photoButtonImage = FontAwesome.image(fromChar: "\u{f03e}", weight: .bold).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let photoButton = UIBarButtonItem(image: photoButtonImage, style: .plain, target: self, action: #selector(galleryTapped))
        photoButton.accessibilityLabel = NSLocalizedString("composer.media.fromGallery", comment: "")
        let cameraButton = UIBarButtonItem(image: UIImage(systemName: "camera", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(cameraTapped))
        cameraButton.accessibilityLabel = NSLocalizedString("composer.media.camera", comment: "")
        let gifButtonImage = FontAwesome.image(fromChar: "\u{e190}", weight: .bold).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let gifButton = UIBarButtonItem(image: gifButtonImage, style: .plain, target: self, action: #selector(gifTapped))
        gifButton.accessibilityLabel = NSLocalizedString("composer.media.gif", comment: "")
        let customEmojiButtonImage = FontAwesome.image(fromChar: "\u{e409}", weight: .bold).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let customEmojiButton = UIBarButtonItem(image: customEmojiButtonImage, style: .plain, target: self, action: #selector(customEmojiTapped))
        customEmojiButton.accessibilityLabel = NSLocalizedString("composer.media.customEmoji", comment: "")
        let pollButtonImage = FontAwesome.image(fromChar: "\u{f828}", weight: .regular).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        var pollButton = UIBarButtonItem(image: pollButtonImage, style: .plain, target: self, action: #selector(pollTapped))
        if GlobalStruct.newPollPost != nil {
            // contains a poll, tap to edit or delete
            let pollButtonImage = FontAwesome.image(fromChar: "\u{f828}", weight: .bold).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
            pollButton = UIBarButtonItem(image: pollButtonImage, style: .plain, target: self, action: nil)

            let edit_poll = NSLocalizedString("composer.poll.edit", comment: "")
            let view31 = UIAction(title: edit_poll, image: UIImage(systemName: "pencil"), identifier: nil) { _ in
                self.pollTapped(true)
            }
            view31.accessibilityLabel = edit_poll
            let remove_poll = NSLocalizedString("composer.poll.remove", comment: "")
            let view32 = UIAction(title: remove_poll, image: UIImage(systemName: "trash"), identifier: nil) { _ in
                self.hasEditedPoll = true
                GlobalStruct.newPollPost = nil
                self.createToolbar()
            }
            view32.accessibilityLabel = remove_poll
            view32.attributes = .destructive

            let itemMenu1 = UIMenu(title: "", options: [], children: [view31, view32])
            pollButton.menu = itemMenu1
        }
        pollButton.accessibilityLabel = NSLocalizedString("composer.poll", comment: "")

        let imageWeight: UIFont.Weight = cwHeight != 0 ? .bold : .regular
        let itemCWImage = FontAwesome.image(fromChar: "\u{f321}", weight: imageWeight).withConfiguration(symbolConfig).withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let itemCW = UIBarButtonItem(image: itemCWImage, style: .plain, target: self, action: #selector(cwTapped))
        itemCW.accessibilityLabel = NSLocalizedString("composer.contentWarning", comment: "")

        let languageButton = toolbarLanguageButton()

        let itemDrafts = UIBarButtonItem(image: UIImage(systemName: "doc.text", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(draftsTapped))
        itemDrafts.accessibilityLabel = NSLocalizedString("composer.drafts", comment: "")

        itemLast = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), style: .plain, target: self, action: nil)
        itemLast.accessibilityLabel = NSLocalizedString("generic.more", comment: "")
        itemLastMenu()

        if audioAttached {
            photoButton.isEnabled = false
            cameraButton.isEnabled = false
            gifButton.isEnabled = false
            pollButton.isEnabled = false
            photoButton.image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            cameraButton.image = UIImage(systemName: "camera", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            gifButton.image = UIImage(named: "gif.rectangle", in: nil, with: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            pollButton.image = UIImage(systemName: "chart.pie", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
        }
        if mediaItemsDisabled || GlobalStruct.newPollPost != nil {
            photoButton.isEnabled = false
            cameraButton.isEnabled = false
            gifButton.isEnabled = false
            photoButton.image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            cameraButton.image = UIImage(systemName: "camera", withConfiguration: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
            gifButton.image = UIImage(named: "gif.rectangle", in: nil, with: symbolConfig)!.withTintColor(.custom.baseTint.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
        }

        var toolbarItems = [
            photoButton,
            fixedSpacer,
            gifButton,
            fixedSpacer,
            customEmojiButton,
            fixedSpacer,
            pollButton,
            fixedSpacer,
            itemCW,
            fixedSpacer,
            languageButton,
            flexibleSpacer,
            itemLast,
        ]
        if !GlobalStruct.drafts.isEmpty {
            toolbarItems.insert(contentsOf: [fixedSpacer, itemDrafts], at: toolbarItems.count - 2)
        }
        formatToolbar.items = toolbarItems
        formatToolbar.sizeToFit()
        formatToolbar.frame = CGRect(x: 0, y: 0, width: 3000, height: formatToolbar.frame.size.height)
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
            cell.altText.inputAccessoryView = formatToolbar
        } else {
            log.warning("expected cell at (0, 2) for toolbar")
        }
        // Only set it if needed. If the input field is already the first responder,
        // need to call reloadInputViews().
        if cellPostTextView == nil {
            log.warning("expected cellPostTextView for toolbar")
        }

        if cellPostTextView != nil, cellPostTextView!.inputAccessoryView == nil {
            cellPostTextView!.inputAccessoryView = formatToolbar
            if cellPostTextView!.isFirstResponder {
                cellPostTextView?.reloadInputViews()
            }
        }
        #if targetEnvironment(macCatalyst)
            formatToolbar.frame = CGRect(x: 0, y: view.bounds.height - formatToolbar.bounds.size.height - 5, width: view.bounds.width, height: formatToolbar.frame.size.height)
        #endif

        let everyone_string = NSLocalizedString("composer.visibility.everyone", comment: "")
        let private_string = NSLocalizedString("composer.visibility.private", comment: "")
        let followers_string = NSLocalizedString("composer.visibility.followers", comment: "")
        let unlisted_string = NSLocalizedString("composer.visibility.unlisted", comment: "")

        var visibilityText = everyone_string
        var visibilityImage = "globe"
        if whoCanReply == .direct {
            visibilityText = private_string
            visibilityImage = "tray.full"
        }
        if whoCanReply == .private {
            visibilityText = followers_string
            visibilityImage = "person.2"
        }
        if whoCanReply == .unlisted {
            visibilityText = unlisted_string
            visibilityImage = "lock.open"
        }
        whoCanReplyPill.setTitle(visibilityText, for: .normal)
        let attachment1 = NSTextAttachment()
        let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let downImage1 = UIImage(systemName: visibilityImage, withConfiguration: symbolConfig1) ?? UIImage()
        attachment1.image = downImage1.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
        let attStringNewLine000 = NSMutableAttributedString()
        let attStringNewLine00 = NSMutableAttributedString(string: "  \(visibilityText)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.custom.baseTint])
        let attString00 = NSAttributedString(attachment: attachment1)
        attStringNewLine000.append(attString00)
        attStringNewLine000.append(attStringNewLine00)
        whoCanReplyPill.setAttributedTitle(attStringNewLine000, for: .normal)

        let view01 = UIAction(title: everyone_string, image: UIImage(systemName: "globe"), identifier: nil) { _ in
            self.whoCanReply = .public
            self.createToolbar()
        }
        view01.accessibilityLabel = everyone_string
        if whoCanReply == .public {
            view01.state = .on
        }
        let view21 = UIAction(title: private_string, image: UIImage(systemName: "tray.full"), identifier: nil) { _ in
            self.whoCanReply = .direct
            self.createToolbar()
        }
        view21.accessibilityLabel = private_string
        if whoCanReply == .direct {
            view21.state = .on
        }
        let view11 = UIAction(title: followers_string, image: UIImage(systemName: "person.2"), identifier: nil) { _ in
            self.whoCanReply = .private
            self.createToolbar()
        }
        view11.accessibilityLabel = followers_string
        if whoCanReply == .private {
            view11.state = .on
        }
        let view12 = UIAction(title: unlisted_string, image: UIImage(systemName: "lock.open"), identifier: nil) { _ in
            self.whoCanReply = .unlisted
            self.createToolbar()
        }
        view12.accessibilityLabel = unlisted_string
        if whoCanReply == .unlisted {
            view12.state = .on
        }

        let post_visibility = NSLocalizedString("composer.visibility", comment: "")
        let itemMenu1 = UIMenu(title: post_visibility, options: [], children: [view01, view21, view11, view12])
        itemMenu1.accessibilityLabel = post_visibility
        whoCanReplyPill.menu = itemMenu1
        whoCanReplyPill.showsMenuAsPrimaryAction = true
    }

    @objc func createToolbar2() {
        formatToolbar2.tintColor = UIColor.label
        formatToolbar2.barStyle = UIBarStyle.default
        formatToolbar2.isTranslucent = false
        formatToolbar2.barTintColor = .custom.quoteTint
    }

    @objc func cwTapped() {
        hasEditedMetadata = true
        if cwHeight == 0 {
            cwHeight = UITableView.automaticDimension
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .bottom)
            createToolbar()
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                cell.altText.placeholder = NSLocalizedString("composer.contentWarning.placeholder", comment: "")
                cell.altText.becomeFirstResponder()
                cell.altText.text = spoilerText
                cell.altText.isHidden = false
            }
        } else {
            cwHeight = 0
            cellPostTextView?.becomeFirstResponder()
            createToolbar()
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .top)
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                cell.altText.isHidden = true
                spoilerText = ""
            }
        }
        itemLastMenu()
        updateCharacterCounts()
    }

    @objc func canvasAdded() {
        triggerHapticImpact(style: .light)
        for index in 0 ..< numImages {
            if imageButton[index].currentImage == nil || imageButton[index].currentImage == UIImage() {
                imageButton[index].backgroundColor = UIColor.white
                imageButton[index].setImage(GlobalStruct.canvasImage, for: .normal)
                imageButton[index].alpha = 1
            }
        }
        mediaData = GlobalStruct.canvasImage.jpegData(compressionQuality: 0.7) ?? Data()
        videoAttached = false
        gifAttached = false
        attachPhoto()
    }

    @objc func translatePostTapped() {
        let vc = TranslationComposeViewController()
        vc.postText = cellPostText
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    func itemLastMenu() {
        var sensitiveText: String = NSLocalizedString("composer.sensitive.add", comment: "")
        var sensitiveImage = "exclamationmark.triangle"
        if isSensitive {
            sensitiveText = NSLocalizedString("composer.sensitive.remove", comment: "")
            sensitiveImage = "exclamationmark.triangle.fill"
        }
        let viewSensitive = UIAction(title: sensitiveText, image: UIImage(systemName: sensitiveImage), identifier: nil) { _ in
            self.hasEditedMetadata = true
            self.isSensitive = !self.isSensitive
            self.itemLastMenu()
            self.updatePostButton()
        }
        viewSensitive.accessibilityLabel = sensitiveText
        if spoilerText != "" {
            viewSensitive.attributes = .disabled
        }

        let translate_post_string = NSLocalizedString("post.translatePost", comment: "")
        let translatePost = UIAction(title: translate_post_string, image: UIImage(systemName: "arrow.triangle.2.circlepath"), identifier: nil) { _ in
            self.translatePostTapped()
        }
        translatePost.accessibilityLabel = translate_post_string

        if imageButton[0].alpha == 1 {
            let itemMenu = UIMenu(title: "", options: [], children: [viewSensitive, translatePost])
            itemLast.menu = itemMenu
        } else {
            let itemMenu = UIMenu(title: "", options: [], children: [translatePost])
            itemLast.menu = itemMenu
        }
    }

    @objc func galleryTapped() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            DispatchQueue.main.async {
                var configuration = PHPickerConfiguration()
                configuration.selectionLimit = 4
                if #available(iOS 16.0, *) {
                    configuration.filter = .any(of: [.images, .screenshots, .depthEffectPhotos, .videos, .screenRecordings, .cinematicVideos, .slomoVideos, .timelapseVideos])
                } else {
                    configuration.filter = .any(of: [.videos, .images, .livePhotos])
                }
                self.photoPickerView = PHPickerViewController(configuration: configuration)
                self.photoPickerView.modalPresentationStyle = .automatic
                self.photoPickerView.view.tintColor = .custom.gold
                self.photoPickerView.delegate = self
                self.present(self.photoPickerView, animated: true, completion: nil)
            }
        }
    }

    func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // Only allow a single video, or multiple images;
        // note that the 'if / else' structure here mirrors
        // the code below.
        var videoCount = 0
        var imageCount = 0
        for result in results {
            if result.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeGIF as String) {
                videoCount += 1
            } else {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    imageCount += 1
                }
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    videoCount += 1
                }
            }
        }
        let completion: (() -> Void)?
        if (videoCount == 1 && imageCount == 0) || (videoCount == 0) {
            // Valid selection
            completion = nil
        } else {
            // Invalid selection
            completion = {
                self.mediaFailure(title: NSLocalizedString("error.pleaseTryAgain", comment: ""), message: NSLocalizedString("composer.error.mediaLimit", comment: ""))
            }
        }

        dismiss(animated: true, completion: completion)
        guard completion == nil else { return }

        // disable posting
        updatePostButton()

        _ = results.map { x in
            if x.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeGIF as String) {
                x.itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeGIF as String) { data, _ in
                    DispatchQueue.main.async {
                        triggerHapticImpact(style: .light)
                        // attach gif
                        self.imageButton[0].setImage(UIImage(data: data ?? Data()), for: .normal)
                        for index in 1 ..< self.numImages {
                            self.imageButton[index].alpha = 0
                        }
                        self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[0].alpha = 1
                            self.imageButton[0].transform = CGAffineTransform.identity
                        }, completion: { _ in
                        })

                        self.mediaData = data ?? Data()
                        self.videoAttached = false
                        self.gifAttached = true
                        self.attachPhoto()
                        self.cellPostTextView?.resignFirstResponder()
                        self.cellPostTextView?.becomeFirstResponder()
                    }
                }
            } else {
                if x.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    x.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        DispatchQueue.main.async {
                            if let photoToAttach = image as? UIImage {
                                triggerHapticImpact(style: .light)
                                // attach photo
                                if self.videoAttached {
                                    self.imageButton[0].alpha = 0
                                }

                                if let index = self.imageButton.firstIndex(where: { imageButton in
                                    imageButton.alpha == 0
                                }) {
                                    self.imageButton[index].setImage(photoToAttach, for: .normal)
                                    self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                        self.imageButton[index].alpha = 1
                                        self.imageButton[index].transform = CGAffineTransform.identity
                                    }, completion: { _ in
                                    })
                                }

                                self.mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
                                self.videoAttached = false
                                self.gifAttached = false
                                self.attachPhoto()
                                self.cellPostTextView?.resignFirstResponder()
                                self.cellPostTextView?.becomeFirstResponder()
                            }
                        }
                    }
                }
                if x.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    x.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.movie") { data, _ in
                        DispatchQueue.main.async {
                            // attach video
                            self.videoAttached = true
                            self.mediaData = data ?? Data()
                            Task {
                                await self.attachAnimatedMedia()
                            }
                        }
                    }
                    x.itemProvider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: [:]) { [self] videoURL, _ in
                        DispatchQueue.main.async {
                            if let url = videoURL as? URL {
                                triggerHapticImpact(style: .light)

                                self.setupImages2()

                                self.cellPostTextView?.resignFirstResponder()
                                self.cellPostTextView?.becomeFirstResponder()

                                self.vUrl = url
                                self.tryDisplayThumbnail(itemProvider: x.itemProvider)
                                for index in 1 ..< self.numImages { // All but the first
                                    self.imageButton[index].alpha = 0
                                }
                                self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                                UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                    self.imageButton[0].alpha = 1
                                    self.imageButton[0].transform = CGAffineTransform.identity
                                }, completion: { _ in
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    func tryDisplayThumbnail(itemProvider: NSItemProvider) {
        imageButton[0].setImage(UIImage(), for: .normal)
        thumbnailAttempt = 0
        getThumbnailImageFromItemProvider(itemProvider: itemProvider)
    }

    func tryDisplayThumbnail(url: URL) {
        imageButton[0].setImage(UIImage(), for: .normal)
        thumbnailAttempt = 0
        getThumbnailImageFromVideoUrl(url: url)
    }

    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        // enable posting
//        updatePostButton()
        if let _ = info[UIImagePickerController.InfoKey.mediaType] as? String {
            if let photoToAttach = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    triggerHapticImpact(style: .light)
                    // attach photo
                    if self.videoAttached {
                        self.imageButton[0].alpha = 0
                    }

                    if let index = self.imageButton.firstIndex(where: { imageButton in
                        imageButton.alpha == 0
                    }) {
                        self.imageButton[index].setImage(photoToAttach, for: .normal)
                        self.imageButton[index].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[index].alpha = 1
                            self.imageButton[index].transform = CGAffineTransform.identity
                        }, completion: { _ in
                        })
                    }

                    self.mediaData = photoToAttach.jpegData(compressionQuality: 0.7) ?? Data()
                    self.videoAttached = false
                    self.gifAttached = false
                    self.attachPhoto()
                    self.cellPostTextView?.resignFirstResponder()
                    self.cellPostTextView?.becomeFirstResponder()
                }
            } else {
                if let url = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL {
                    DispatchQueue.main.async {
                        // attach video
                        self.videoAttached = true
                        do {
                            let videoData = try NSData(contentsOf: url as URL, options: .mappedIfSafe)
                            self.mediaData = videoData as Data
                            Task {
                                await self.attachAnimatedMedia()
                            }
                        } catch {
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        triggerHapticImpact(style: .light)

                        self.setupImages2()

                        self.cellPostTextView?.resignFirstResponder()
                        self.cellPostTextView?.becomeFirstResponder()

                        self.vUrl = url as URL
                        self.tryDisplayThumbnail(url: url as URL)
                        for index in 1 ..< self.numImages { // All but the first
                            self.imageButton[index].alpha = 0
                        }
                        self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                            self.imageButton[0].alpha = 1
                            self.imageButton[0].transform = CGAffineTransform.identity
                        }, completion: { _ in
                        })
                    }
                }
            }
        }
        photoPickerView2.dismiss(animated: true, completion: nil)
    }

    @objc func gifTapped() {
        let vc = SwiftyGiphyViewController()
        vc.delegate = self
        let nvc = UINavigationController(rootViewController: vc)
        nvc.modalPresentationStyle = .automatic
        present(nvc, animated: true, completion: nil)
    }

    @objc func customEmojiTapped() {
        let vc = EmoticonPickerViewController(emoticons: (currentAcct as? MastodonAcctData)?.emoticons)
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    func giphyControllerDidSelectGif(controller: SwiftyGiphyViewController, item: GiphyItem) {
        controller.dismiss(animated: true, completion: nil)
        if let x = item.originalImage?.url {
            DispatchQueue.main.async {
                // attach gif
                self.videoAttached = true
                self.gifAttached = true

                if let ur = item.originalImage?.mp4URL {
                    self.vUrl = ur
                }

                DispatchQueue.global(qos: .utility).async {
                    do {
                        self.mediaData = try Data(contentsOf: x)
                        DispatchQueue.main.async {
                            self.imageButton[0].setImage(UIImage(data: self.mediaData), for: .normal)
                            for index in 1 ..< self.numImages { // All but the first
                                self.imageButton[index].alpha = 0
                            }
                            triggerHapticImpact(style: .light)
                            self.imageButton[0].transform = CGAffineTransform.identity.translatedBy(x: 0, y: 270).scaledBy(x: 0.05, y: 0.05)
                            UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.67, initialSpringVelocity: 0.24, options: .curveEaseOut, animations: {
                                self.imageButton[0].alpha = 1
                                self.imageButton[0].transform = CGAffineTransform.identity
                            }, completion: { _ in
                            })

                            self.attachPhoto()
                            self.cellPostTextView?.resignFirstResponder()
                            self.cellPostTextView?.becomeFirstResponder()
                        }
                    } catch {
                        log.error("Error fetching GIF from URL.")
                    }
                }
            }
        }
    }

    func giphyControllerDidCancel(controller: SwiftyGiphyViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func getThumbnailImageFromItemProvider(itemProvider: NSItemProvider) {
        // Put in a gray square placeholder
        let placeholder = UIImage.makeColorTile(size: CGSize(width: 100, height: 100), color: .darkGray)
        DispatchQueue.main.async {
            self.imageButton[0].setImage(placeholder, for: .normal)

            self.imageButton[0].addSubview(self.progressRing[0])
            self.progressRing[0].translatesAutoresizingMaskIntoConstraints = false
            self.progressRing[0].centerXAnchor.constraint(equalTo: self.imageButton[0].centerXAnchor).isActive = true
            self.progressRing[0].centerYAnchor.constraint(equalTo: self.imageButton[0].centerYAnchor).isActive = true
            self.progressRing[0].widthAnchor.constraint(equalToConstant: 50).isActive = true
            self.progressRing[0].heightAnchor.constraint(equalToConstant: 50).isActive = true
            self.progressRing[0].setProgress(0.005, animated: true)
            self.progressRing[0].startColor = .custom.baseTint
            self.progressRing[0].endColor = .custom.baseTint
            self.progressRing[0].grooveColor = .custom.backgroundTint.withAlphaComponent(0.25)
            self.progressRing[0].lineWidth = 5
            self.progressRing[0].rotate360Degrees()
        }
        _ = itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { fileURL, error in
            guard error == nil else {
                log.error("Unable to make thumbnail from video")
                return
            }
            guard let fileURL else {
                log.error("Unable to use fileURL")
                return
            }
            let asset = AVAsset(url: fileURL)
            let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            avAssetImageGenerator.appliesPreferredTrackTransform = true
            let thumnailTime = CMTimeMake(value: 1, timescale: 60)
            if let cgThumbImage = try? avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil) {
                let thumbImage = UIImage(cgImage: cgThumbImage)
                DispatchQueue.main.async {
                    self.imageButton[0].setImage(thumbImage, for: .normal)
                }
            } else {
                log.error("unable to create thumbimage")
            }
        }
    }

    func getThumbnailImageFromVideoUrl(url: URL) {
        if thumbnailAttempt < 10 {
            DispatchQueue.global().async {
                let asset = AVAsset(url: url)
                let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                avAssetImageGenerator.appliesPreferredTrackTransform = true
                let thumnailTime = CMTimeMake(value: 1, timescale: 60)
                do {
                    let cgThumbImage = try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil)
                    let thumbImage = UIImage(cgImage: cgThumbImage)
                    DispatchQueue.main.async {
                        self.imageButton[0].setImage(thumbImage, for: .normal)
                    }
                } catch {
                    log.error("Error fetching thumbnail. Trying again. - \(error)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.thumbnailAttempt += 1
                        self.getThumbnailImageFromVideoUrl(url: url)
                    }
                }
            }
        }
    }

    // This will re-upload media when the user switches accounts
    // using the account picker in the avatar button.
    func reuploadMedia() {
        if !videoAttached, gifAttached {
            // This is a gif
            visibleImages = 0
            attachPhoto() // should use existing mediaData
        } else if videoAttached {
            // This is a video
            Task {
                await self.attachAnimatedMedia()
            }
        } else if audioAttached {
            // This is audio
            Task {
                await self.attachAudio()
            }
        } else if visibleImages > 0 {
            // This is one or more photos
            //
            // Store the current images
            var imagesToAttach: [UIImage] = []
            for index in 0 ..< visibleImages {
                if let buttonImage = imageButton[index].imageView?.image {
                    imagesToAttach.append(buttonImage)
                }
            }
            // Reset settings
            videoAttached = false
            gifAttached = false
            visibleImages = 0
            for index in 0 ..< numImages {
                uploaded[index] = false
            }
            // Re-attach each photo
            for index in 0 ..< imagesToAttach.count {
                mediaData = imagesToAttach[index].jpegData(compressionQuality: 0.7) ?? Data()
                attachPhoto()
            }
        }
    }

    func checkMediaValid(id: String, completion: @escaping (Bool) -> Void) {
        let request = Media.getMedia(id: id)
        (currentAcct as? MastodonAcctData)?.client.run(request, completion: { result in
            if let error = result.error {
                log.error("Error checking isMediaValid: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
            if let attachment = result.value {
                guard attachment.url != nil else {
                    // url is not there yet so media not yet processed
                    completion(false)
                    return
                }
                // if url is present, that means media finished processing
                completion(true)
            } else {
                completion(false)
            }
        })
    }

    func tryCheckingMediaValidity(id: String, retries: Int, delay: TimeInterval, completion: @escaping (Bool) -> Void) {
        checkMediaValid(id: id) { success in
            if success {
                self.isProcessingMediaServerside = false
                completion(true)
            } else if retries > 0 {
                log.debug("Media not done processing serverside.\nRetry \(retries) in \(delay)...")
                // We don't want exponential backoff in this case as media is imminently ready.
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.tryCheckingMediaValidity(id: id, retries: retries - 1, delay: delay, completion: completion)
                }
            } else {
                // We can assume the media processing has failed.
                self.isProcessingMediaServerside = false
                completion(false)
            }
        }
    }

    func attachPhoto() {
        hasEditedMedia = true
        if videoAttachedCheckForAttachingImages || gifAttached {
            videoAttached = false
            visibleImages = 0
            mediaIdStrings = []
            for index in 0 ..< numImages {
                uploaded[index] = false
            }
        }

        // Find a slot to use
        var index = 0
        for imageIndex in 0 ..< numImages {
            if imageButton[imageIndex].alpha == 1, uploaded[imageIndex] == false {
                index = imageIndex
                break
            }
        }

        uploaded[index] = true
        visibleImages += 1
        imageButton[index].addSubview(progressRing[index])
        progressRing[index].translatesAutoresizingMaskIntoConstraints = false
        progressRing[index].centerXAnchor.constraint(equalTo: imageButton[index].centerXAnchor).isActive = true
        progressRing[index].centerYAnchor.constraint(equalTo: imageButton[index].centerYAnchor).isActive = true
        progressRing[index].widthAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[index].heightAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[index].setProgress(0.005, animated: true)
        progressRing[index].startColor = .custom.baseTint
        progressRing[index].endColor = .custom.baseTint
        progressRing[index].grooveColor = .custom.backgroundTint.withAlphaComponent(0.25)
        progressRing[index].lineWidth = 5
        progressRing[index].rotate360Degrees()

        updatePostButton()
        if imageButton[index].alpha == 1 {
            setToolBarMediaItemStates(disabled: true)
            let request = Media.upload(media: .jpeg(mediaData))
            (currentAcct as? MastodonAcctData)?.client.run(request) { statuses in
                if let err = (statuses.error) {
                    log.error("error attaching photo - \(err)")
                    DispatchQueue.main.async {
                        self.setToolBarMediaItemStates(disabled: false)

                        // Move all other images down by one since this one failed to upload
                        for indexToMove in index ..< self.numImages - 1 {
                            self.imageButton[indexToMove].setImage(self.imageButton[indexToMove + 1].currentImage, for: .normal)
                        }
                        // Any image buttons that have no button should have no alpha
                        for indexToClear in index ..< self.numImages - 1 {
                            if self.imageButton[indexToClear].currentImage == nil {
                                self.imageButton[indexToClear].alpha = 0
                            }
                        }
                        // Clear the last image
                        self.imageButton[self.numImages - 1].alpha = 0
                        self.imageButton[self.numImages - 1].setImage(nil, for: .normal)

                        self.setupImages2()
                        self.uploaded[index] = false
                        self.visibleImages -= 1
                        self.updatePostButton()
                        self.mediaFailure(message: err.localizedDescription)
                    }
                }
                if let stat = (statuses.value) {
                    // Ensure there is a slot for this string in the array
                    while self.mediaIdStrings.count < index + 1 {
                        self.mediaIdStrings.append("")
                    }
                    // Now, replace the one in our slot
                    self.mediaIdStrings.remove(at: index)
                    self.mediaIdStrings.insert(stat.id, at: index)

                    self.setToolBarMediaItemStates(disabled: false)
                    self.mediaAttached = true

                    DispatchQueue.main.async {
                        self.progressRing[index].layer.removeAllAnimations()
                        self.progressRing[index].removeFromSuperview()

                        if self.mediaIdStrings.count == self.visibleImages {
                            self.updatePostButton()
                        }
                        log.debug("attached photo")
                    }
                }
            }
        }
    }

    func attachAudio() async {
        hasEditedMedia = true
        imageButton[0].addSubview(progressRing[0])
        visibleImages += 1
        progressRing[0].translatesAutoresizingMaskIntoConstraints = false
        progressRing[0].centerXAnchor.constraint(equalTo: imageButton[0].centerXAnchor).isActive = true
        progressRing[0].centerYAnchor.constraint(equalTo: imageButton[0].centerYAnchor).isActive = true
        progressRing[0].widthAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[0].heightAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[0].setProgress(0.005, animated: true)
        progressRing[0].startColor = .custom.baseTint
        progressRing[0].endColor = .custom.baseTint
        progressRing[0].grooveColor = .custom.backgroundTint.withAlphaComponent(0.25)
        progressRing[0].lineWidth = 5
        progressRing[0].rotate360Degrees()

        updatePostButton()
        setToolBarMediaItemStates(disabled: true)
        let request = Media.upload(media: .mp3(mediaData))
        (currentAcct as? MastodonAcctData)?.client.run(request) { statuses in
            if let err = (statuses.error) {
                log.error("error attaching audio - \(err.localizedDescription)")
                DispatchQueue.main.async {
                    self.setToolBarMediaItemStates(disabled: false)
                    self.imageButton[0].alpha = 0
                    self.imageButton[0].setImage(UIImage(), for: .normal)
                    self.visibleImages -= 1
                    self.updatePostButton()
                    self.mediaFailure(message: err.localizedDescription)
                }
            }
            if let stat = (statuses.value) {
                self.setToolBarMediaItemStates(disabled: false)
                self.mediaIdStrings.append(stat.id)

                DispatchQueue.main.async {
                    self.progressRing[0].layer.removeAllAnimations()
                    self.progressRing[0].setProgress(1, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.progressRing[0].removeFromSuperview()
                    }
                    self.mediaAttached = true
                    if self.imageButton[0].alpha == 1 {
                        self.updatePostButton()
                    }
                }
            }
        }
    }

    func attachAnimatedMedia() async {
        hasEditedMedia = true
        isProcessingVideo = true
        imageButton[0].addSubview(progressRing[0])
        visibleImages = 1
        mediaIdStrings = []
        videoAttachedCheckForAttachingImages = true
        progressRing[0].translatesAutoresizingMaskIntoConstraints = false
        progressRing[0].centerXAnchor.constraint(equalTo: imageButton[0].centerXAnchor).isActive = true
        progressRing[0].centerYAnchor.constraint(equalTo: imageButton[0].centerYAnchor).isActive = true
        progressRing[0].widthAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[0].heightAnchor.constraint(equalToConstant: 50).isActive = true
        progressRing[0].setProgress(0.005, animated: true)
        progressRing[0].startColor = .custom.baseTint
        progressRing[0].endColor = .custom.baseTint
        progressRing[0].grooveColor = .custom.backgroundTint.withAlphaComponent(0.25)
        progressRing[0].lineWidth = 5
        progressRing[0].rotate360Degrees()

        updatePostButton()
        setToolBarMediaItemStates(disabled: true)

        do {
            let request: Request<Attachment>
            do {
                if try VideoProcessor.shouldBeCompressed(url: vUrl, maxResolution: 1920, maxSizeInMB: maxVideoSize) {
                    let (compressedVideo, compressedVideoUrl) = try await VideoProcessor.compressVideo(videoUrl: vUrl, outputSize: CGSize(width: 960, height: 960), outputFileType: .mp4, compressionPreset: AVAssetExportPreset960x540)
                    try VideoProcessor.checkVideoSize(url: compressedVideoUrl, maxSizeInMB: maxVideoSize)
                    request = Media.upload(media: .video(compressedVideo))
                } else {
                    request = Media.upload(media: .video(mediaData))
                }
            } catch {
                log.error("unable to check if compressable: \(error)")
                request = Media.upload(media: .video(mediaData))
            }

            (currentAcct as? MastodonAcctData)?.client.run(request) { [weak self] statuses in
                guard let self = self else { return }
                if let err = (statuses.error) {
                    log.error("error attaching media - \(err.localizedDescription)")
                    DispatchQueue.main.async {
                        self.updateComposerStateForState(success: false)
                        self.mediaFailure(message: err.localizedDescription)
                    }
                }
                if let stat = (statuses.value) {
                    // If there's no url, that means the server is still processing the media and won't accept a post with the still-processing media.
                    guard stat.url != nil else {
                        log.debug("Server needs to process media")
                        self.isProcessingMediaServerside = true
                        DispatchQueue.main.async {
                            self.progressRing[0].layer.removeAllAnimations()
                            self.progressRing[0].setProgress(1, animated: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                self.progressRing[0].setProgress(0.5, animated: true)
                                self.progressRing[0].rotate360Degrees()
                            }
                            self.updatePostButton()
                        }

                        // After testing various media uploads, I've determined that generally it should be done in ~30 seconds for ~30MB media, with margin.
                        // Anything more than that we can assume it's not going to succeed. This can be adjusted if users say differently.
                        // Masto:web does a check ever 1 second after the previous check returns
                        log.debug("Start checking uploaded media validity")
                        self.tryCheckingMediaValidity(id: stat.id, retries: 20, delay: 1) { [weak self] success in
                            guard let self = self else { return }
                            if success {
                                log.debug("Serviceside media validity succeeded")
                                self.mediaIdStrings = [stat.id]
                                DispatchQueue.main.async {
                                    self.updateComposerStateForState(success: true)
                                }
                            } else {
                                log.error("Serverside media validity failed")
                                DispatchQueue.main.async {
                                    self.updateComposerStateForState(success: false)
                                    self.mediaFailure(message: NSLocalizedString("error.composer.mediaFailedServerProcessing", comment: "The uploaded media failed serverside processing"))
                                }
                            }
                        }
                        return
                    }

                    // There seems to be a valid media url, carry on...
                    self.mediaIdStrings = [stat.id]
                    DispatchQueue.main.async {
                        self.updateComposerStateForState(success: true)
                    }
                }
            }
        }
    }

    func updateComposerStateForState(success: Bool) {
        // This is a temp function for controlling actionable view states, for sanity
        // An overall NewPostVC refactor ticket is at MAM-4165, comments welcome!
        if success {
            progressRing[0].layer.removeAllAnimations()
            progressRing[0].setProgress(1, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.progressRing[0].removeFromSuperview()
            }
            mediaAttached = true
            isProcessingVideo = false
            if imageButton[0].alpha == 1 {
                updatePostButton()
            }
        } else {
            progressRing[0].layer.removeAllAnimations()
            progressRing[0].removeFromSuperview()
            setToolBarMediaItemStates(disabled: false)
            imageButton[0].alpha = 0
            imageButton[0].setImage(UIImage(), for: .normal)
            visibleImages = 0
            updatePostButton()
        }
    }

    func setToolBarMediaItemStates(disabled: Bool) {
        DispatchQueue.main.async {
            if disabled {
                self.mediaItemsDisabled = true
                self.createToolbar()
            } else {
                self.mediaItemsDisabled = false
                self.createToolbar()
            }
        }
    }

    func mediaFailure(title: String = NSLocalizedString("error.composer.mediaFailed", comment: ""), message: String) {
        let alert = UIAlertController(title: title, message: "\(message)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: { _ in
        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = getTopMostViewController()?.view
            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }

    func setPostFailure() {
        let alert = UIAlertController(title: NSLocalizedString("error.composer.postFailed", comment: ""), message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.retry", comment: ""), style: .default, handler: { [weak self] _ in
            self?.sendData()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.drafts.save", comment: ""), style: .default, handler: { [weak self] _ in
            self?.saveDraft()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.drafts.discard", comment: ""), style: .destructive, handler: { _ in
        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = getTopMostViewController()?.view
            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }

    @objc func schedulePost() {
        cellPostTextView?.resignFirstResponder()

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: { () in
            self.whoCanReplyPill.alpha = 0
        })

        dateViewBG.alpha = 1
        dateViewBG.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        dateViewBG.addTarget(self, action: #selector(dismissDateView), for: .touchUpInside)
        navigationController?.view.addSubview(dateViewBG)

        #if targetEnvironment(macCatalyst)
            var dWidth: CGFloat = view.bounds.width - 140
            var dX: CGFloat = 70
            if (view.bounds.width - 140) > 188 {
                dWidth = 188
                dX = (view.bounds.width - dWidth) / 2
            }
            dateView.frame = CGRect(x: dX, y: view.bounds.height / 2 + 150, width: dWidth, height: 125)
        #elseif !targetEnvironment(macCatalyst)
            var dWidth: CGFloat = view.bounds.width - 140
            var dX: CGFloat = 70
            if (view.bounds.width - 140) > 230 {
                dWidth = 230
                dX = (view.bounds.width - dWidth) / 2
            }
            dateView.frame = CGRect(x: dX, y: view.bounds.height / 2 + 150, width: dWidth, height: 140)
        #endif
        dateView.backgroundColor = UIColor.secondarySystemBackground
        dateView.layer.cornerCurve = .continuous
        dateView.layer.cornerRadius = 16
        dateViewBG.addSubview(dateView)

        dateView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: { () in
            self.dateView.transform = CGAffineTransform.identity
            self.dateView.frame.origin.y = self.view.bounds.height / 2 - 70
        })

        #if targetEnvironment(macCatalyst)
            datePicker.frame = CGRect(x: 15, y: 15, width: dateView.bounds.size.width - 30, height: 100)
        #elseif !targetEnvironment(macCatalyst)
            datePicker.frame = CGRect(x: 15, y: -15, width: dateView.bounds.size.width - 30, height: 100)
        #endif
        datePicker.contentHorizontalAlignment = .center
        datePicker.minimumDate = Date().adjust(.minute, offset: 10)
        datePicker.date = Date().adjust(.minute, offset: 10)
        datePicker.locale = .current
        datePicker.preferredDatePickerStyle = .compact
        datePicker.addTarget(self, action: #selector(handleDateSelection), for: .valueChanged)
        dateView.addSubview(datePicker)

        tempDate = Date().adjust(.minute, offset: 10)

        let dateDone = UIButton()
        dateDone.frame = CGRect(x: 20, y: dateView.bounds.size.height - 70, width: dateView.bounds.size.width - 40, height: 50)
        dateDone.backgroundColor = .custom.baseTint
        dateDone.layer.cornerCurve = .continuous
        dateDone.layer.cornerRadius = 12
        dateDone.setTitle("Schedule", for: .normal)
        dateDone.setTitleColor(UIColor.white, for: .normal)
        dateDone.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        dateDone.addTarget(self, action: #selector(doneDateView), for: .touchUpInside)
        dateDone.tag = 999
        dateDone.layer.shadowColor = UIColor.black.cgColor
        dateDone.layer.shadowOffset = CGSize(width: 0, height: 15)
        dateDone.layer.shadowRadius = 15
        dateDone.layer.shadowOpacity = 0.24
        for x in dateView.subviews {
            if x.tag == 999 {
                x.removeFromSuperview()
            }
        }
        dateView.addSubview(dateDone)
    }

    @objc func doneDateView() {
        triggerHapticImpact()
        dismissDateView()
        scheduledTime = tempDate.iso8601String
    }

    @objc func handleDateSelection(_ sender: UIDatePicker) {
        tempDate = sender.date
    }

    @objc func dismissDateView() {
        scheduledTime = nil
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: { () in
            self.whoCanReplyPill.alpha = 1
        })
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: { () in
            self.dateView.frame.origin.y = self.view.bounds.height / 2 - 105
        })
        UIView.animate(withDuration: 0.29, delay: 0.16, options: [.curveEaseOut], animations: { () in
            self.dateViewBG.alpha = 0
            self.dateView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.dateView.frame.origin.y = self.view.bounds.height / 2 + 150
        }) { _ in
            self.cellPostTextView?.becomeFirstResponder()
            self.dateViewBG.removeFromSuperview()
            self.dateView.removeFromSuperview()
            self.datePicker.removeFromSuperview()
            self.dateView.transform = CGAffineTransform.identity
        }
    }

    func goToPollView(_ edit: Bool = false) {
        let vc = PollViewController()
        if edit {
            vc.fromEdit = true
        }
        hasEditedPoll = true
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    @objc func pollTapped(_ edit: Bool = false) {
        if imageButton[0].alpha == 0 {
            if let _ = fromEdit, GlobalStruct.newPollPost != nil {
                let alert = UIAlertController(title: nil, message: NSLocalizedString("poll.editNotice", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.continue", comment: ""), style: .default, handler: { _ in
                    self.goToPollView(edit)
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .cancel, handler: { _ in
                }))
                if let presenter = alert.popoverPresentationController {
                    presenter.sourceView = getTopMostViewController()?.view
                    presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                }
                getTopMostViewController()?.present(alert, animated: true, completion: nil)
            } else {
                goToPollView(edit)
            }
        } else {
            let alert = UIAlertController(title: nil, message: NSLocalizedString("error.pollMedia", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel, handler: { _ in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
    }

    @objc func cameraTapped() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                    DispatchQueue.main.async {
                        self.fromCamera = true
                        self.photoPickerView2.delegate = self
                        self.photoPickerView2.sourceType = .camera
                        self.photoPickerView2.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
                        self.photoPickerView2.allowsEditing = false
                        self.present(self.photoPickerView2, animated: true, completion: nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: NSLocalizedString("generic.oops", comment: ""), message: NSLocalizedString("error.cameraDenied", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .cancel))
                    alert.addAction(UIAlertAction(title: NSLocalizedString("title.settings", comment: ""), style: .default) { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                            })
                        }
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc func draftsTapped() {
        let vc = ScheduledPostsViewController()
        vc.drafts = GlobalStruct.drafts
        vc.currentUser = currentUser
        let nvc = UINavigationController(rootViewController: vc)
        present(nvc, animated: true, completion: nil)
    }

    @objc func restoreFromDrafts() {
        updatePostButton()
        createToolbar()
        if tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            cellPostText = GlobalStruct.currentDraft?.contents.content.stripHTML() ?? ""
            tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
            if cellPostText.isEmpty {
                btn1.showsMenuAsPrimaryAction = false
            } else {
                // present drafts option
                let draft = UIAction(title: NSLocalizedString("composer.drafts.save", comment: ""), image: UIImage(systemName: "doc.text"), identifier: nil) { _ in
                    self.saveDraft()
                }
                let dismiss = UIAction(title: NSLocalizedString("generic.dismiss", comment: ""), image: UIImage(systemName: "xmark"), identifier: nil) { _ in
                    self.dismiss(animated: true, completion: nil)
                }
                dismiss.attributes = .destructive

                let newMenu = UIMenu(title: "", options: [], children: [draft, dismiss])
                btn1.menu = newMenu
                btn1.showsMenuAsPrimaryAction = true
            }
        }
        spoilerText = GlobalStruct.currentDraft?.contents.spoilerText.stripHTML() ?? ""
        if spoilerText != "" {
            cwHeight = UITableView.automaticDimension
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
            createToolbar()
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
                cell.altText.placeholder = NSLocalizedString("composer.contentWarning.placeholder", comment: "")
                cell.altText.becomeFirstResponder()
                cell.altText.text = spoilerText
                cell.altText.isHidden = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
            }
        }
        if let poll = GlobalStruct.currentDraft?.contents.poll {
            let date1 = poll.expiresAt ?? ""
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = GlobalStruct.dateFormat
            let date = dateFormatter.date(from: date1)

            let expiresIn = date ?? Date()
            let diff = Calendar.current.dateComponents([.second], from: Date(), to: expiresIn).second ?? 0
            var str: [String] = []
            _ = poll.options.map { x in
                str.append(x.title)
            }
            let a: [Any] = [str, diff, poll.multiple, false]
            GlobalStruct.newPollPost = a
            createToolbar()
        }
        if let z = GlobalStruct.currentDraft?.contents.visibility {
            whoCanReply = z
            createToolbar()
        }
        if let rep = GlobalStruct.currentDraft?.replyPost {
            allStatuses = rep
            tableView.reloadData()
            cellPostTextView?.becomeFirstResponder()
        }
        mediaIdStrings = GlobalStruct.currentDraft?.imagesIds ?? []
        if let im = GlobalStruct.currentDraft?.images {
            for index in 0 ..< numImages {
                if index < im.count, let imageData = im[index] {
                    imageButton[index].setImage(UIImage(data: imageData), for: .normal)
                    imageButton[index].alpha = 1
                } else {
                    imageButton[index].alpha = 0
                }
            }
        }

        parseText()
        updateCharacterCounts()

        if tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            if cellPostText.isEmpty || cellPostText.count > postCharacterCount2 {
                updatePostButton()
                // show default toolbar
                if let cellPostTextView {
                    cellPostTextView.inputAccessoryView = formatToolbar
                    cellPostTextView.reloadInputViews()
                }
                #if targetEnvironment(macCatalyst)
                    formatToolbar.removeFromSuperview()
                    scrollView.removeFromSuperview()
                    view.addSubview(formatToolbar)
                #endif
            } else {
                updatePostButton()
            }
        }
        updateCharacterCounts()
    }

    @objc func restoreFromTemplate() {
        // first launch composer preview template
        updatePostButton()
        if tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            if tableView.cellForRow(at: IndexPath(row: 0, section: 1)) is AltTextCell2 {
                cellPostText = "I just started trying out #Mammoth for Mastodon and I'm loving it!"
                tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                updateCharacterCounts()
            }
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        if isQuotePost {
            return 3
        } else {
            return 2
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // The post being replied to, if any
            if allStatuses.isEmpty {
                return 0
            } else {
                return 1
            }
        } else if section == 1 {
            // The post being composed
            return 2
        } else {
            // The post being quoted, if any
            return 1
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 0 {
            // Content warning
            return cwHeight
        } else {
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let newCell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
            let cell = newCell.p

            // default
            let stat = allStatuses[indexPath.row].reblog ?? allStatuses[indexPath.row]
            if let ur = URL(string: stat.account?.avatar ?? "") {
                cell.profileIcon.sd_setImage(with: ur, for: .normal)
            }

            let text = stat.content.stripHTML()
            cell.postText.commitUpdates {
                cell.postText.textColor = .custom.mainTextColor
                cell.linkPost.textColor = .custom.mainTextColor2
                cell.postText.text = text
                cell.postText.mentionColor = .custom.baseTint
                cell.postText.hashtagColor = .custom.baseTint
                cell.postText.URLColor = .custom.baseTint
                cell.postText.emailColor = .custom.baseTint

                let userName = stat.account?.displayName ?? ""
                cell.userName.text = userName

                let userTag = stat.account?.acct ?? ""
                cell.userTag.text = "@\(userTag)"

                let time1 = stat.createdAt
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = GlobalStruct.dateFormat
                var time = dateFormatter.date(from: time1)?.toStringWithRelativeTime() ?? ""
                if GlobalStruct.timeStampStyle == 1 {
                    let time1 = stat.createdAt
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = GlobalStruct.dateFormat
                    time = dateFormatter.date(from: time1)?.toString(dateStyle: .short, timeStyle: .short) ?? ""
                } else if GlobalStruct.timeStampStyle == 2 {
                    time = ""
                }
                cell.dateTime.text = time

                cell.indicator.alpha = 0

                var containsPoll = false
                if let _ = stat.poll {
                    containsPoll = true
                }
                // images
                if stat.mediaAttachments.count > 0 {
                    let z = stat.mediaAttachments
                    var isVideo = false
                    let mediaItems = z[0].previewURL

                    if z.first?.type == .video || z.first?.type == .gifv || z.first?.type == .audio {
                        isVideo = true
                        cell.playerController.view.isHidden = false
                        if z.first?.type == .audio {
                            cell.setupPlayButton(z.first?.url ?? "", isAudio: true)
                        } else {
                            cell.setupPlayButton(z.first?.url ?? "")
                        }
                    } else {
                        cell.playerController.view.isHidden = true
                        cell.setupPlayButton("")
                    }

                    var mediaItems1: String?
                    if z.count > 1 {
                        mediaItems1 = z[1].previewURL
                    }

                    var mediaItems2: String?
                    if z.count > 2 {
                        mediaItems2 = z[2].previewURL
                    }

                    var mediaItems3: String?
                    if z.count > 3 {
                        mediaItems3 = z[3].previewURL
                    }

                    cell.setupImages(url1: mediaItems ?? "", url2: mediaItems1, url3: mediaItems2, url4: mediaItems3, isVideo: isVideo, fullImages: z)
                    cell.setupConstraints(containsImages: true, quotePostCard: nil, containsRepost: false, containsPoll: containsPoll, pollOptions: stat.poll, stat: stat)
                } else {
                    cell.setupConstraints(containsImages: false, quotePostCard: nil, containsRepost: false, containsPoll: containsPoll, pollOptions: stat.poll, stat: stat)
                }
            }

            // tap items
            cell.postText.handleMentionTap { _ in
            }
            cell.postText.handleHashtagTap { _ in
            }
            cell.postText.handleURLTap { str in
                triggerHapticImpact(style: .light)
                PostActions.openLink(str)
            }
            cell.postText.handleEmailTap { _ in
            }

            cell.stackViewB.isHidden = true
            for sub in cell.stackViewB.arrangedSubviews {
                sub.removeFromSuperview()
            }

            cell.topThreadLine.alpha = 0
            cell.bottomThreadLine.alpha = 1

            newCell.separatorInset = UIEdgeInsets(top: 0, left: 78, bottom: 0, right: 0)
            let bgColorView = UIView()
            bgColorView.backgroundColor = .clear
            newCell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .clear
            return newCell
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextCell2", for: indexPath) as! AltTextCell2
                cell.altText.placeholder = ""
                cell.altText.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                cell.separatorInset = UIEdgeInsets(top: 0, left: view.bounds.width, bottom: 0, right: 0)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ComposeCell", for: indexPath) as! ComposeCell

                if let ur = URL(string: currentUser?.avatar ?? "") {
                    cell.profileIcon.sd_setImage(with: ur, for: .normal)
                }

                var items: [UIAction] = []
                for acct in AccountsManager.shared.allAccounts {
                    let im = UIImage(systemName: "person.crop.circle")
                    let imV = UIImageView()
                    imV.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                    imV.layer.cornerRadius = 10
                    imV.layer.masksToBounds = true
                    if let ur = URL(string: acct.avatar) {
                        imV.sd_setImage(with: ur)
                    }
                    let instanceAndAccount = "@\(acct.fullAcct)"
                    let op1 = UIAction(title: instanceAndAccount, image: imV.image?.withRoundedCorners()?.resize(targetSize: CGSize(width: 20, height: 20)) ?? im, identifier: nil) { _ in
                        // switch account
                        DispatchQueue.main.async {
                            self.currentFullName = "@\(instanceAndAccount)"
                            self.currentAcct = acct
                            self.tableView.reloadData()
                            self.refreshDrafts()
                            self.cellPostTextView?.becomeFirstResponder()
                            self.reuploadMedia()
                        }
                    }
                    op1.state = (currentAcct?.uniqueID == acct.uniqueID) ? .on : .off
                    items.append(op1)
                }
                let profileMenu = UIMenu(title: "Post from...", image: nil, identifier: nil, children: items)
                if AccountsManager.shared.allAccounts.count > 1 && fromEdit == nil {
                    cell.profileIcon.menu = profileMenu
                    cell.profileIcon.showsMenuAsPrimaryAction = true
                }

                // If this is the first time through here, be sure to update the content of
                // cellPostTextView, and run through again.
                if cellPostTextView == nil {
                    DispatchQueue.main.async {
                        self.updateReplyingToIfNecessary()
                    }
                }
                cellPostTextView = cell.post

                // Record and restore the firstResponder state, and
                // the selection before/after setting cell.post.text.
                let wasFirstResponder = cellPostTextView?.isFirstResponder
                let currentSelection = cellPostTextView?.selectedTextRange
                cell.post.text = cellPostText
                if currentSelection != nil {
                    cellPostTextView?.selectedTextRange = currentSelection!
                }
                if wasFirstResponder ?? false {
                    cellPostTextView?.becomeFirstResponder()
                }

                if GlobalStruct.keyboardType == 0 {
                    cell.post.keyboardType = .twitter
                } else {
                    cell.post.keyboardType = .default
                }
                cell.post.delegate = self

                if allStatuses.isEmpty {
                    cell.topThreadLine.alpha = 0
                } else {
                    cell.topThreadLine.alpha = 1
                }

                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = UIColor.clear
                return cell
            }
        } else {
            // Section 2: the quoted post
            let cell = quotePostCell
            let quotePostURL = self.quotePostURL()
            log.debug("updating quote post URL to: \(quotePostURL?.absoluteString ?? "nil")")
            cell.updateForQuotePost(quotePostURL)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func updateCharacterCounts() {
        // Count the content warning
        let contentWarning = spoilerText

        // Break down the post if necessary
        let postPieces = postPiecesFromPost(cellPostText, contentWarning: contentWarning)

        // Compose the string
        if postPieces.count == 1 {
            // Show the # of characters used
            postCharacterCount = postCharacterCount2 - countWithURL(postPieces[0]) - contentWarning.count
            navigationItem.title = "\(postCharacterCount)"
            navigationItem.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("composer.characterCount", comment: ""), postCharacterCount)
        } else {
            // Show the current number of posts, and the character space *remaining*
            postCharacterCount = postCharacterCount2 - countWithURL(postPieces.last!)

            navigationItem.title = String.localizedStringWithFormat(NSLocalizedString("composer.characterCount.thread", comment: ""), postPieces.count, postCharacterCount)
            navigationItem.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("composer.characterCount.thread.description", comment: ""), postPieces.count, postCharacterCount)
        }

        if threadingAllowed() {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .custom.backgroundTint
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            navigationItem.standardAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
        } else {
            if postCharacterCount > 30 {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .custom.backgroundTint
                appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
                navigationItem.standardAppearance = appearance
                navigationItem.scrollEdgeAppearance = appearance
            } else if postCharacterCount > 15 {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .custom.backgroundTint
                appearance.titleTextAttributes = [.foregroundColor: UIColor.systemYellow]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemYellow]
                navigationItem.standardAppearance = appearance
                navigationItem.scrollEdgeAppearance = appearance
            } else if postCharacterCount > 0 {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .custom.backgroundTint
                appearance.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
                navigationItem.standardAppearance = appearance
                navigationItem.scrollEdgeAppearance = appearance
            } else {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .custom.backgroundTint
                appearance.titleTextAttributes = [.foregroundColor: UIColor.systemRed]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemRed]
                navigationItem.standardAppearance = appearance
                navigationItem.scrollEdgeAppearance = appearance
            }
        }

        updatePostButton()
    }

    @objc func textFieldDidChange(_: UITextField) {
        hasEditedMetadata = true
        updateCharacterCounts()
        if let cell2 = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AltTextCell2 {
            spoilerText = cell2.altText.text ?? ""
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        cellPostText = textView.text

        hasEditedText = true
        updateCharacterCounts()

        var isEmoji = false
        if let x = textView.text.last {
            if "\(x)".containsEmoji {
                isEmoji = true
            }
        }

        if textView.text.isEmpty || ((textView.text.count > postCharacterCount2) && !threadingAllowed()) {
            updatePostButton()
            if isEmoji {} else {
                // show default toolbar
                cellPostTextView?.inputAccessoryView = formatToolbar
                cellPostTextView?.reloadInputViews()
                #if targetEnvironment(macCatalyst)
                    formatToolbar.removeFromSuperview()
                    scrollView.removeFromSuperview()
                    view.addSubview(formatToolbar)
                #endif
            }
        } else {
            updatePostButton()
        }

        var inSearch1 = false
        var inSearch2 = false

        if isEmoji {} else {
            // find @ mentions
            let trimmedToCursor = textView.text[..<(textView.cursorIndex ?? textView.text.endIndex)]
            var trimSpot = trimmedToCursor.firstIndex(of: "@") ?? textView.text.endIndex
            // find most recent match of a non-alphanumeric character which is followed by an @
            do {
                let regex = try NSRegularExpression(pattern: "[^a-zA-Z0-9]@")
                let matches = regex.matches(in: String(trimmedToCursor), range: NSRange(trimmedToCursor.startIndex..., in: trimmedToCursor))
                if let lastMatch = matches.last {
                    trimSpot = trimmedToCursor.utf16.index(trimmedToCursor.startIndex, offsetBy: lastMatch.range.location + lastMatch.range.length - 1)
                }
            } catch {
                log.error("Regex error: \(error.localizedDescription)")
            }
            if trimSpot <= (textView.cursorIndex ?? textView.text.endIndex) {
                let trimmed = trimmedToCursor[trimSpot ..< (textView.cursorIndex ?? textView.text.endIndex)]
                if !trimmed.contains(" "), trimmed.contains("@"), trimmed.count > 1 {
                    inSearch1 = true
                    // search for users
                    trimmedAtString = String(trimmed.dropFirst())
                    pendingRequestWorkItem?.cancel()
                    let requestWorkItem = DispatchWorkItem { [weak self] in
                        self?.searchForUsers(self?.trimmedAtString ?? "")
                    }
                    pendingRequestWorkItem = requestWorkItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: requestWorkItem)
                } else {
                    inSearch1 = false
                    // show default toolbar
                    if inSearch1 == false, inSearch2 == false {
                        pendingRequestWorkItem?.cancel()
                        cellPostTextView?.inputAccessoryView = formatToolbar
                        cellPostTextView?.reloadInputViews()
                        #if targetEnvironment(macCatalyst)
                            formatToolbar.removeFromSuperview()
                            scrollView.removeFromSuperview()
                            view.addSubview(formatToolbar)
                        #endif
                    }
                }
            } else {
                inSearch1 = false
                // show default toolbar
                if inSearch1 == false, inSearch2 == false {
                    pendingRequestWorkItem?.cancel()
                    cellPostTextView?.inputAccessoryView = formatToolbar
                    cellPostTextView?.reloadInputViews()
                    #if targetEnvironment(macCatalyst)
                        formatToolbar.removeFromSuperview()
                        scrollView.removeFromSuperview()
                        view.addSubview(formatToolbar)
                    #endif
                }
            }

            // find # tags
            let trimSpot2 = trimmedToCursor.lastIndex(of: "#") ?? textView.text.endIndex
            if trimSpot2 <= (textView.cursorIndex ?? textView.text.endIndex) {
                let trimmed = trimmedToCursor[trimSpot2 ..< (textView.cursorIndex ?? textView.text.endIndex)]
                if !trimmed.contains(" "), trimmed.contains("#") {
                    inSearch2 = true
                    // search for tags
                    trimmedAtString = String(trimmed.dropFirst())
                    pendingRequestWorkItem?.cancel()
                    let requestWorkItem = DispatchWorkItem { [weak self] in
                        self?.searchForTags(self?.trimmedAtString ?? "")
                    }
                    pendingRequestWorkItem = requestWorkItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: requestWorkItem)
                } else {
                    inSearch2 = false
                    // show default toolbar
                    if inSearch1 == false, inSearch2 == false {
                        pendingRequestWorkItem?.cancel()
                        cellPostTextView?.inputAccessoryView = formatToolbar
                        cellPostTextView?.reloadInputViews()
                        #if targetEnvironment(macCatalyst)
                            formatToolbar.removeFromSuperview()
                            scrollView.removeFromSuperview()
                            view.addSubview(formatToolbar)
                        #endif
                    }
                }
            } else {
                inSearch2 = false
                // show default toolbar
                if inSearch1 == false, inSearch2 == false {
                    pendingRequestWorkItem?.cancel()
                    cellPostTextView?.inputAccessoryView = formatToolbar
                    cellPostTextView?.reloadInputViews()
                    #if targetEnvironment(macCatalyst)
                        formatToolbar.removeFromSuperview()
                        scrollView.removeFromSuperview()
                        view.addSubview(formatToolbar)
                    #endif
                }
            }
        }

        if tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            if cellPostText.isEmpty {
                btn1.showsMenuAsPrimaryAction = false
            } else {
                // present drafts option
                let draft = UIAction(title: NSLocalizedString("composer.drafts.save", comment: ""), image: UIImage(systemName: "doc.text"), identifier: nil) { _ in
                    self.saveDraft()
                }
                let dismiss = UIAction(title: NSLocalizedString("generic.dismiss", comment: ""), image: UIImage(systemName: "xmark"), identifier: nil) { _ in
                    self.dismiss(animated: true, completion: nil)
                }
                dismiss.attributes = .destructive

                let newMenu = UIMenu(title: "", options: [], children: [draft, dismiss])
                btn1.menu = newMenu
                btn1.showsMenuAsPrimaryAction = true
            }
        }

        // These are needed to force the textView to recalculate its height, and update.
        textView.sizeToFit()
        let areAnimationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(areAnimationsEnabled)

        parseText()
    }

    func parseText() {
        if tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            // get cursor position
            var cursorPosition = 0
            if let selectedRange = cellPostTextView?.selectedTextRange {
                cursorPosition = cellPostTextView!.offset(from: cellPostTextView!.beginningOfDocument, to: selectedRange.start)
            }

            let pattern = "(?:|$)#[\\p{L}0-9_]*|\\B\\@([a-zA-Z0-9_.-]*)([\\w@a-zA-Z0-9_.-]+)|\\@|(https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|https?:\\/\\/(?:www\\.|(?!www))[a-zA-Z0-9]+\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]+\\.[^\\s]{2,})"
            let inString = cellPostText
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let range = NSMakeRange(0, inString.count)
            let matches = (regex?.matches(in: inString, options: [], range: range))!
            let attrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize + 2, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.label]
            let attrString = NSMutableAttributedString(string: inString, attributes: attrs)
            for match in matches.reversed() {
                attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.custom.baseTint, range: match.range(at: 0))
            }
            if !matches.isEmpty {
                cellPostTextView?.attributedText = attrString
            }

            // set cursor position
            if let newPosition = cellPostTextView?.position(from: cellPostTextView!.beginningOfDocument, offset: cursorPosition) {
                cellPostTextView!.selectedTextRange = cellPostTextView!.textRange(from: newPosition, to: newPosition)
            }
        } else {
            log.error("parseText called with no cell")
        }
    }

    func moveCursorToBeginning() {
        if cellPostTextView != nil {
            let startPosition = cellPostTextView!.position(from: cellPostTextView!.beginningOfDocument, offset: 0)!
            cellPostTextView?.selectedTextRange = cellPostTextView?.textRange(from: startPosition, to: startPosition)
        } else {
            log.error("expected cellPostTextView to be valid")
        }
    }

    func moveCursorToEnd() {
        if cellPostTextView != nil {
            let endPosition = cellPostTextView!.position(from: cellPostTextView!.endOfDocument, offset: 0)!
            cellPostTextView?.selectedTextRange = cellPostTextView?.textRange(from: endPosition, to: endPosition)
        } else {
            log.error("expected cellPostTextView to be valid")
        }
    }

    @objc func saveDraft() {
        let postText: String = cellPostText
        var reply: String? = nil
        if allStatuses.isEmpty, quoteString.isEmpty {} else {
            // replying to
            reply = allStatuses.first?.reblog?.inReplyToID ?? allStatuses.first?.inReplyToID ?? ""
        }
        var replyA: String? = nil
        if allStatuses.isEmpty, quoteString.isEmpty {} else {
            // replying to
            replyA = allStatuses.first?.reblog?.inReplyToAccountID ?? allStatuses.first?.inReplyToAccountID ?? ""
        }
        if mediaAttached {
            mediaIdStrings = mediaIdStrings.filter { x in
                x != ""
            }
            var images: [Data] = []
            for index in 0 ..< numImages {
                if let a1 = imageButton[index].currentImage?.pngData() {
                    images.append(a1)
                }
            }
            var poll: Poll? = nil
            if let x = GlobalStruct.newPollPost {
                var pOpt: [PollOptions] = []
                let a = x[0] as? [String] ?? []
                for z in a {
                    pOpt.append(PollOptions(title: z, votesCount: nil))
                }
                let pp = Poll(id: "0", expired: false, multiple: false, votesCount: 0, options: pOpt)
                poll = pp
            }
            let draftPost = Status(id: "\(Int.random(in: 0 ... 1_000_000))", uri: "", url: nil, account: currentUser!, inReplyToID: reply, inReplyToAccountID: replyA, content: postText, createdAt: "", emojis: [], repliesCount: 0, reblogsCount: 0, favouritesCount: 0, reblogged: nil, favourited: nil, bookmarked: nil, sensitive: nil, spoilerText: spoilerText, visibility: whoCanReply ?? .public, mediaAttachments: [], mentions: [], tags: [], card: nil, application: nil, language: nil, reblog: nil, pinned: nil, poll: poll, editedAt: nil)
            let dr1 = Draft(id: Int.random(in: 0 ... 1_000_000), contents: draftPost, images: images, imagesIds: mediaIdStrings, replyPost: allStatuses)
            GlobalStruct.drafts.insert(dr1, at: 0)
            do {
                try Disk.save(GlobalStruct.drafts, to: .documents, as: "\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json")
                dismiss(animated: true, completion: nil)
            } catch {
                log.error("error saving drafts to Disk")
            }
        } else {
            var poll: Poll? = nil
            if let x = GlobalStruct.newPollPost {
                var pOpt: [PollOptions] = []
                let a = x[0] as? [String] ?? []
                for z in a {
                    pOpt.append(PollOptions(title: z, votesCount: nil))
                }
                let pp = Poll(id: "0", expired: false, multiple: false, votesCount: 0, options: pOpt)
                poll = pp
            }
            let draftPost = Status(id: "\(Int.random(in: 0 ... 1_000_000))", uri: "", url: nil, account: currentUser!, inReplyToID: reply, inReplyToAccountID: replyA, content: postText, createdAt: "", emojis: [], repliesCount: 0, reblogsCount: 0, favouritesCount: 0, reblogged: nil, favourited: nil, bookmarked: nil, sensitive: nil, spoilerText: spoilerText, visibility: whoCanReply ?? .public, mediaAttachments: [], mentions: [], tags: [], card: nil, application: nil, language: nil, reblog: nil, pinned: nil, poll: poll, editedAt: nil)
            let dr1 = Draft(id: Int.random(in: 0 ... 1_000_000), contents: draftPost, images: [], imagesIds: nil, replyPost: allStatuses)
            GlobalStruct.drafts.insert(dr1, at: 0)
            do {
                try Disk.save(GlobalStruct.drafts, to: .documents, as: "\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json")
                dismiss(animated: true, completion: nil)
            } catch {
                log.error("error saving drafts to Disk")
            }
        }
    }

    func fetchQuotePostMetaData() async {
        if let quotedAccount = quotedAccount {
            log.debug("Fetching quoted account info for \(quotedAccount.fullAcct)")
            quotedAccountPublicSocialGraph = await FollowManager.shared.publicSocialGraphForAccount(quotedAccount)
            followedByQuotedAccount = FollowManager.shared.followedByStatusForAccount(quotedAccount, requestUpdate: .force)
        }
    }

    func updateQuotePostURL() {
        // This can get called multiple times based on timing;
        // only do it successfully once.
//        if self.haveUpdatedPostWithQuoteURL {
//            return
//        }
//        if self.followedByQuotedAccount == FollowManager.FollowStatus.unknown {
//            return
//        }
//
//        log.debug("Followed by Quote Account: \(String(self.followedByQuotedAccount.rawValue))")
//        log.debug("Quote Account SocialGraph: \(String(self.quotedAccountPublicSocialGraph))")
//
//        var enabledQuotePost = false
//
//        // user must be followed by quoted account and quoted account must have following publicly available
//        enabledQuotePost = self.followedByQuotedAccount == FollowManager.FollowStatus.following && self.quotedAccountPublicSocialGraph
//
//        // quote post is the current user's own account
//        if let currentUser = AccountsManager.shared.currentUser(), let quotedAccount = self.quotedAccount{
//            if(quotedAccount.acct == currentUser.acct){
//                enabledQuotePost = true
//            }
//        }
        // Disable any animations while we update the cell content
        tableView.beginUpdates()
        UIView.setAnimationsEnabled(false)

//        if cellPostText.count > 0 {
//            let rg = NSRange(cellPostText.endIndex..., in: cellPostText)
//            if let stringRange = Range(rg, in: cellPostText) {
//                let urlSuffix = "?public_follow=\(String(enabledQuotePost))"
//                cellPostText.replaceSubrange(stringRange, with: urlSuffix)
//                self.haveUpdatedPostWithQuoteURL = true
//                log.debug("text after updating URL: \(cellPostText)")
//                parseText()
//            }
//        }

        tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
        UIView.setAnimationsEnabled(true)
        tableView.endUpdates()
    }

    private func quotePostURL() -> URL? {
        // See if the last part of the text is a URL; if so, use it
        var quotePostURL: URL? = nil
        let postText = cellPostText
        // Look backward for "https://"
        if let urlStart = postText.range(of: "https://", options: .backwards) {
            // Take everything from "https://" forward and try to make a URL
            let urlString = postText.suffix(from: urlStart.lowerBound)
            quotePostURL = URL(string: String(urlString))
        }
        return quotePostURL
    }

    @objc func followStatusNotification(notification: Notification) {
        // Originally , we only observe the notification if it's tied to the current user,
        // and otherUser matches the quoted account.
        // However, this isn't always the case (see MAM-1538).
        //
        // Since this just an update, and the proabability and downside of updating
        // this twice is insignificant, go ahead and do the udpate based on just checking
        // the current account.

        log.debug("followStatusNotification: \(notification.userInfo)")
        if (notification.userInfo!["currentUserFullAcct"] as! String) == (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.fullAcct {
            followedByQuotedAccount = FollowManager.FollowStatus(rawValue: notification.userInfo!["followedByStatus"] as! String)!
            updateQuotePostURL()
        } else {
            log.warning("unexpected notification")
        }
    }

    func searchForUsers(_ user0: String) {
        let request = Search.searchAutocompleteAccounts(query: user0)
        formatToolbar2.sizeToFit()
        (currentAcct as? MastodonAcctData)?.client.run(request) { accounts in
            if var accountsArray = (accounts.value) {
                DispatchQueue.main.async {
                    self.formatToolbar2.items = []
                    var allWidths: CGFloat = 0
                    accountsArray = accountsArray.removingDuplicates()
                    self.userItemsAll = accountsArray
                    for (c, _) in accountsArray.enumerated() {
                        let view = UIButton()

                        let im = UIButton()
                        im.isUserInteractionEnabled = false
                        im.frame = CGRect(x: 0, y: 10, width: (self.formatToolbar2.frame.size.height) - 20, height: (self.formatToolbar2.frame.size.height) - 20)
                        im.layer.cornerRadius = ((self.formatToolbar2.frame.size.height) - 20) / 2
                        im.imageView?.contentMode = .scaleAspectFill
                        if let ur = URL(string: accountsArray[c].avatar) {
                            im.sd_setImage(with: ur, for: .normal)
                        }
                        im.layer.masksToBounds = true
                        view.addSubview(im)

                        let titl = UILabel()
                        titl.text = "@\(accountsArray[c].acct)"
                        titl.textColor = .custom.baseTint
                        titl.frame = CGRect(x: (self.formatToolbar2.frame.size.height) - 10, y: 0, width: (self.view.bounds.width) - (self.formatToolbar2.frame.size.height), height: self.formatToolbar2.frame.size.height)
                        titl.sizeToFit()
                        titl.frame.size.height = self.formatToolbar2.frame.size.height
                        titl.frame.origin.x = (self.formatToolbar2.frame.size.height) - 10
                        view.addSubview(titl)

                        let wid = im.frame.size.width + titl.frame.size.width + 30
                        view.frame = CGRect(x: 0, y: 0, width: wid, height: self.formatToolbar2.frame.size.height)
                        view.tag = c
                        view.addTarget(self, action: #selector(self.tapAccount(_:)), for: .touchUpInside)
                        let x0 = UIBarButtonItem(customView: view)
                        x0.width = wid
                        allWidths += wid
                        x0.accessibilityLabel = "@\(accountsArray[c].acct)"

                        self.formatToolbar2.items?.append(x0)
                    }

                    self.formatToolbar2.sizeToFit()
                    if (allWidths + 40) < self.view.bounds.width {
                        self.formatToolbar2.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.formatToolbar2.frame.size.height)
                    } else {
                        self.formatToolbar2.frame = CGRect(x: 0, y: 0, width: allWidths + 40, height: self.formatToolbar2.frame.size.height)
                    }
                    if self.cellPostTextView != nil {
                        self.scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.formatToolbar2.frame.size.height))
                        self.scrollView.backgroundColor = .custom.quoteTint
                        self.scrollView.showsVerticalScrollIndicator = false
                        self.scrollView.showsHorizontalScrollIndicator = false
                        self.scrollView.contentSize = self.formatToolbar2.frame.size
                        self.scrollView.addSubview(self.formatToolbar2)
                        self.cellPostTextView!.inputAccessoryView = self.scrollView
                        self.cellPostTextView!.reloadInputViews()
                        #if targetEnvironment(macCatalyst)
                            self.scrollView.frame.origin.y = self.view.bounds.height - self.formatToolbar2.bounds.size.height - 5
                            self.formatToolbar.removeFromSuperview()
                            self.scrollView.removeFromSuperview()
                            self.view.addSubview(self.scrollView)
                        #endif
                    }
                }
            }
        }
    }

    @objc func tapAccount(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        pendingRequestWorkItem?.cancel()
        let searchItem1 = userItemsAll[sender.tag].acct
        if let cellPostTextView = cellPostTextView {
            if let selectedRange = cellPostTextView.selectedTextRange {
                let cursorPosition = cellPostTextView.offset(from: cellPostTextView.beginningOfDocument, to: selectedRange.start)
                if let currPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition) {
                    let tag = getCurrentTagOrUser(isTag: false) ?? ""
                    if let currTagPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition - tag.count) {
                        if let textRange = cellPostTextView.textRange(from: currTagPosition, to: currPosition) {
                            if let range = cellPostText.rangeFromNSRange(nsRange: rangeFromTextRange(textRange: textRange, textView: cellPostTextView)) {
                                cellPostText.replaceSubrange(range, with: "\(searchItem1) ")
                                tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                            }
                        }
                    }
                    parseText()
                }
                let cursorDiff = Array(searchItem1).count - Array(trimmedAtString).count + 1
                if let newPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition + cursorDiff) {
                    if newPosition != cellPostTextView.endOfDocument {
                        cellPostTextView.selectedTextRange = cellPostTextView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
            // show default toolbar
            if tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
                cellPostTextView.inputAccessoryView = formatToolbar
                cellPostTextView.reloadInputViews()
            }
            #if targetEnvironment(macCatalyst)
                formatToolbar.removeFromSuperview()
                scrollView.removeFromSuperview()
                view.addSubview(formatToolbar)
            #endif
        }
    }

    func searchForTags(_ tag0: String) {
        let request = Search.search(query: tag0, resolve: true)
        (currentAcct as? MastodonAcctData)?.client.run(request) { statuses in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.formatToolbar2.items = []
                    var allWidths: CGFloat = 0
                    let zz = stat.hashtags
                    self.tagsAll = zz
                    for (c, _) in zz.enumerated() {
                        let view = UIButton()

                        let titl = UILabel()
                        titl.text = "#\(zz[c].name)"
                        titl.textColor = .custom.baseTint
                        titl.frame = CGRect(x: 0, y: 0, width: (self.view.bounds.width) - (self.formatToolbar2.frame.size.height) + ((self.formatToolbar2.frame.size.height) - 10), height: self.formatToolbar2.frame.size.height)
                        titl.sizeToFit()
                        titl.frame.size.height = self.formatToolbar2.frame.size.height
                        titl.frame.origin.x = 0
                        view.addSubview(titl)

                        let wid = titl.frame.size.width + 30
                        view.frame = CGRect(x: 0, y: 0, width: wid, height: self.formatToolbar2.frame.size.height)
                        view.tag = c
                        view.addTarget(self, action: #selector(self.tapTag(_:)), for: .touchUpInside)
                        let x0 = UIBarButtonItem(customView: view)
                        x0.width = wid
                        allWidths += wid
                        x0.accessibilityLabel = "@\(zz[c].name)"

                        self.formatToolbar2.items?.append(x0)
                    }

                    self.formatToolbar2.sizeToFit()
                    if (allWidths + 40) < self.view.bounds.width {
                        self.formatToolbar2.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.formatToolbar2.frame.size.height)
                    } else {
                        self.formatToolbar2.frame = CGRect(x: 0, y: 0, width: allWidths + 40, height: self.formatToolbar2.frame.size.height)
                    }
                    if self.cellPostTextView != nil {
                        self.scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.formatToolbar2.frame.size.height))
                        self.scrollView.backgroundColor = .custom.quoteTint
                        self.scrollView.showsVerticalScrollIndicator = false
                        self.scrollView.showsHorizontalScrollIndicator = false
                        self.scrollView.contentSize = self.formatToolbar2.frame.size
                        self.scrollView.addSubview(self.formatToolbar2)
                        self.cellPostTextView!.inputAccessoryView = self.scrollView
                        self.cellPostTextView!.reloadInputViews()
                        #if targetEnvironment(macCatalyst)
                            self.scrollView.frame.origin.y = self.view.bounds.height - self.formatToolbar2.bounds.size.height - 5
                            self.formatToolbar.removeFromSuperview()
                            self.scrollView.removeFromSuperview()
                            self.view.addSubview(self.scrollView)
                        #endif
                    }
                }
            }
        }
    }

    @objc func tapTag(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        pendingRequestWorkItem?.cancel()
        let searchItem1 = tagsAll[sender.tag].name
        if let cellPostTextView {
            if let selectedRange = cellPostTextView.selectedTextRange {
                let cursorPosition = cellPostTextView.offset(from: cellPostTextView.beginningOfDocument, to: selectedRange.start)
                if let currPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition) {
                    let tag = getCurrentTagOrUser(isTag: true) ?? ""
                    if let currTagPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition - tag.count) {
                        if let textRange = cellPostTextView.textRange(from: currTagPosition, to: currPosition) {
                            if let range = cellPostText.rangeFromNSRange(nsRange: rangeFromTextRange(textRange: textRange, textView: cellPostTextView)) {
                                cellPostText.replaceSubrange(range, with: "\(searchItem1) ")
                                tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                            }
                        }
                    }
                    parseText()
                }
                let cursorDiff = Array(searchItem1).count - Array(trimmedAtString).count + 1
                if let newPosition = cellPostTextView.position(from: cellPostTextView.beginningOfDocument, offset: cursorPosition + cursorDiff) {
                    if newPosition != cellPostTextView.endOfDocument {
                        cellPostTextView.selectedTextRange = cellPostTextView.textRange(from: newPosition, to: newPosition)
                    }
                }
            }
            // show default toolbar
            if tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
                cellPostTextView.inputAccessoryView = formatToolbar
                cellPostTextView.reloadInputViews()
            }
            #if targetEnvironment(macCatalyst)
                formatToolbar.removeFromSuperview()
                scrollView.removeFromSuperview()
                view.addSubview(formatToolbar)
            #endif
        }
    }

    func getCurrentTagOrUser(isTag: Bool) -> String? {
        if let cellPostTextView = cellPostTextView {
            let selectedRange: UITextRange? = cellPostTextView.selectedTextRange
            var cursorOffset: Int? = nil
            if let aStart = selectedRange?.start {
                cursorOffset = cellPostTextView.offset(from: cellPostTextView.beginningOfDocument, to: aStart)
            }
            let text = cellPostText
            let substring = (text as NSString?)?.substring(to: cursorOffset!)
            if isTag {
                let tag = substring?.components(separatedBy: "#").last
                return tag
            } else {
                var user = substring?.components(separatedBy: "@").last
                // Handle the case where the user has typed '@aaa@bbb' before tapping the button
                if user != nil {
                    if let lastWord = substring?.components(separatedBy: " ").last,
                       lastWord.hasPrefix("@"),
                       lastWord.contains(user!)
                    {
                        let index = lastWord.index(lastWord.startIndex, offsetBy: 1)
                        user = String(lastWord[index...])
                    }
                }
                return user
            }
        } else {
            return nil
        }
    }

    func rangeFromTextRange(textRange: UITextRange, textView: UITextView) -> NSRange {
        let location: Int = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
        let length: Int = textView.offset(from: textRange.start, to: textRange.end)
        return NSMakeRange(location, length)
    }

    @objc func updatePostButton() {
        DispatchQueue.main.async {
            // Is the text valid?
            var hasValidText = false
            if self.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
                let textCount = self.cellPostText.count
                hasValidText = (textCount > 0) &&
                    ((textCount <= self.postCharacterCount2) || self.threadingAllowed())
            }

            // Is there any media at all?
            let hasAnyMedia = self.imageButton[0].alpha == 1
            let hasAnyValidContent = hasValidText || hasAnyMedia

            // Enable if (1) there is any valid content, AND
            //           (2) any editing has happened
            let canSend = hasAnyValidContent && (self.hasEditedText || self.hasEditedMedia || self.hasEditedMetadata || self.hasEditedPoll) && !self.isProcessingMediaServerside

            if canSend {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                self.canPost = true
                self.btn2.setImage(UIImage(systemName: "arrow.up", withConfiguration: symbolConfig0)?.withTintColor(UIColor.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
                self.btn2.backgroundColor = .custom.active
                self.setupImages2()
            } else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                self.canPost = false
                self.btn2.setImage(UIImage(systemName: "arrow.up", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                self.btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
            }
        }
    }

    @objc func quotePostDidUpdate() {
        if isQuotePost {
            tableView.reloadSections(IndexSet(2 ... 2), with: .none)
        } else {
            log.warning("unexpectedly got an update for a quote post")
        }
    }

    func sendDataIfCanPost() {
        stopActivity()
        if GlobalStruct.canPostPost {
            sendData()
        }
    }

    @objc func sendTap() {
        DispatchQueue.main.async {
            var canP = true
            if GlobalStruct.altText {
                if GlobalStruct.whichImagesAltText.count >= self.mediaIdStrings.count {
                    canP = true
                    print("has image description")
                } else {
                    canP = false
                    print("missing image description")
                    self.postMissingAltText()
                    return
                }
            }
            if let _ = self.fromEdit {
                if GlobalStruct.canPostPost {
                    self.sendEditData()
                }
                self.dismissTap()
            } else {
                if self.canPost, canP {
                    for index in 0 ..< self.numImages {
                        if self.imageButton[index].alpha == 1 {
                            self.visibImages += 1
                        }
                    }
                    // send post
                    if (self.visibImages == self.mediaIdStrings.count) || self.audioAttached || self.videoAttached, !self.isProcessingVideo {
                        // all media attached, post it
                        self.startActivity()
                        self.sendDataIfCanPost()
                        self.dismissTap()
                        GlobalStruct.currentlyPosting = true
                    } else {
                        self.visibImages = 0
                        // all media not attached, reconsider
                        let alert = UIAlertController(title: NSLocalizedString("composer.media.progress", comment: ""), message: NSLocalizedString("composer.media.progress.confirm", comment: ""), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.media.progress.giveUp", comment: ""), style: .destructive, handler: { _ in
                            self.startActivity()
                            self.sendDataIfCanPost()
                        }))
                        alert.addAction(UIAlertAction(title: NSLocalizedString("composer.media.progress.wait", comment: "As in 'to wait'"), style: .cancel, handler: { _ in
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }

    func startActivity() {}

    func stopActivity() {
        #if !targetEnvironment(macCatalyst)
            #if canImport(ActivityKit)
                if #available(iOS 16.1, *) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Task {
                            for activity in Activity<UndoStruct>.activities {
                                await activity.end(using: nil, dismissalPolicy: .immediate)
                                print("Stopped activity")
                            }
                        }
                    }
                }
            #endif
        #endif
    }

    private func countWithURL(_ postText: String) -> Int {
        var newString: String
        // for mastodon. urls always have 23 characters
        // content warnings don't have the url rule.
        let urlRegex = try! NSRegularExpression(pattern: #"https?://[^ ]+\.[^ ][^ ]+"#, options: .caseInsensitive)
        let urlRange = NSMakeRange(0, postText.count)
        // replace with 23 characters
        newString = urlRegex.stringByReplacingMatches(in: postText, options: [], range: urlRange, withTemplate: ".......................")

        // the composer ignores the domain name in mentions when counting.
        // closest regex i derived from mastodon's:
        let mentionRegex = try! NSRegularExpression(pattern: #"(@[^ \n]+)@\.*[a-zA-Z0-9](\.*[a-zA-Z0-9]+)+"#, options: .caseInsensitive)
        let mentionRange = NSMakeRange(0, newString.count)
        newString = mentionRegex.stringByReplacingMatches(in: newString, range: mentionRange, withTemplate: "$1")
        return newString.count
    }

    func postThread(_ postText: String, contentWarning: String) {
        let postPieces = postPiecesFromPost(postText, contentWarning: contentWarning)

        // Start posting the thread
        postNextThreadPiece(postPieces, inReplyTo: inReplyId, isFirstPiece: true)
    }

    // Break down the full thread into it's smaller pieces based on the current
    // threading settings. If threading is off, it will always return an array
    // with a single item.
    //
    // It will also take the content warning into account when breaking down
    // into threads.
    private func postPiecesFromPost(_ postText: String, contentWarning: String) -> [String] {
        // If no threader mode, just return the one post
        if !threadingAllowed() {
            return [postText]
        }

        // If threader mode, but text is short, return one item
        if threadingAllowed(), postCharacterCount2 > countWithURL(postText) + contentWarning.count {
            return [postText]
        }

        // First, break this down into the sub posts
        let threadFooterSize = " (xx/xx)".count // max chars for thread footer text
        let numUserCharsPerPost = postCharacterCount2 - threadFooterSize // number of chars of the user's text per post

        // Split the post into various pieces
        var postPieces: [String] = []
        var currentPiece = ""
        var pieceSize = 0
        // separate post per word.
        let allWords = postText.split(separator: " ", omittingEmptySubsequences: false)
        for word in allWords {
            let regex = try! NSRegularExpression(pattern: "https?://[^ ]+\\.[^ ][^ ]+", options: .caseInsensitive)
            let wordSize: Int

            // links are always 23 characters
            if regex.firstMatch(in: String(word), range: NSMakeRange(0, word.count)) != nil {
                // account for space
                wordSize = 23 + 1
            } else {
                // account for space
                wordSize = word.count + 1
            }

            // if this word makes the post too big!
            if pieceSize + wordSize > numUserCharsPerPost {
                postPieces.append(currentPiece)
                currentPiece = String(word) + " "
                pieceSize = wordSize + 1
            }
            // if not!!!
            else {
                currentPiece += word + " "
                pieceSize += wordSize
            }
        }
        // append our final part
        postPieces.append(currentPiece)

        // Append footer to each thread piece
        for index in 0 ..< postPieces.count {
            var threadSuffix: String
            switch GlobalStruct.threaderStyle {
            case 0: // no suffix
                threadSuffix = ""
            case 1: // ellipsis - no ellipsis on the last piece though
                threadSuffix = (index < postPieces.count - 1) ? " …" : ""
            case 2: // (x/y)
                threadSuffix = " (\(index + 1)/\(postPieces.count))"
            case 3: // x 🧵
                threadSuffix = " \(index + 1) 🧵"
            case 4: // x 🪡
                threadSuffix = " \(index + 1) 🪡"
            default:
                threadSuffix = ""
                log.error("Unexpected threading style")
            }
            postPieces[index] += threadSuffix
        }
        return postPieces
    }

    // Post the first item in the postPieces array
    private func postNextThreadPiece(_ postPieces: [String], inReplyTo: String? = nil, isFirstPiece: Bool = false) {
        log.debug("postNextThreadPiece inReplyTo: \(inReplyTo ?? "<no id>") ifFirstPiece:\(isFirstPiece)")
        let thisPostPiece = postPieces[0]
        let remainingPostPieces = Array(postPieces.dropFirst())

        var repId: String? = nil
        if inReplyTo != nil {
            repId = inReplyTo
        }
        var whoCanRep = whoCanReply ?? .public
        // Only move public subsequent posts to .unlisted
        if !isFirstPiece, whoCanRep == .public {
            whoCanRep = .unlisted
        }

        var spoilerText: String? = nil
        if self.spoilerText != "" {
            spoilerText = self.spoilerText
        }
        log.debug("posting thread piece reply to: \(repId ?? "<no id>"), visiblity: \(whoCanRep)")
        // First, if necessary, do a search of the post to get it onto
        // the authenticated user's server.
        if inReplyTo == "ID Requires Search" {
            // Get the local post ID, and try again
            // Checking for url as reblog or original.
            if let statURL = allStatuses.first?.reblog?.url ?? allStatuses.first?.url {
                let request = Search.search(query: statURL, resolve: true)
                (currentAcct as? MastodonAcctData)?.client.run(request) { [weak self] statuses in
                    var successGettingPostID = false
                    if let error = statuses.error {
                        log.error("error from Search.search(): \(error)")
                        // I have seen 500, 503 errors returned when the serer is very busy
                    }
                    if let results = statuses.value {
                        let statuses = results.statuses
                        if let statID = statuses.first?.id {
                            successGettingPostID = true
                            DispatchQueue.main.async {
                                // Try again
                                self?.postNextThreadPiece(postPieces, inReplyTo: statID)
                            }
                        } else {
                            log.error("Expected a status")
                        }
                    }
                    // Put an alert to retry if needed.
                    if !successGettingPostID {
                        DispatchQueue.main.async { [weak self] in
                            self?.setPostFailure()
                        }
                    }
                }
            } else {
                log.error("unable to get a stat url")
            }
            return
        }
        let request = Statuses.create(status: thisPostPiece, replyToID: repId, mediaIDs: mediaIdStrings, sensitive: isSensitive, spoilerText: spoilerText, scheduledAt: scheduledTime, language: PostLanguages.shared.postLanguage, poll: GlobalStruct.newPollPost, visibility: whoCanRep)
        (currentAcct as? MastodonAcctData)?.client.run(request) { statuses in
            if let error = statuses.error {
                log.error("Unable to post thread piece; error: \(error)")
            }
            if let stat = statuses.value {
                DispatchQueue.main.async {
                    if remainingPostPieces.count > 0 {
                        self.postNextThreadPiece(remainingPostPieces, inReplyTo: stat.id)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postPosted"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateFeed"), object: nil)
                    }
                }
            }
        }
    }

    func sendDataBluesky() {
        let record = Model.Feed.Post(
            createdAt: Date(),
            text: cellPostText,
            facets: [],
            reply: nil,
            embed: nil
        )

        Task {
            guard let account = AccountsManager.shared.currentAccount as? BlueskyAcctData
            else { return }

            _ = try await account.api.createRecord(
                repo: account.userID,
                record: record
            )

            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "postPosted"),
                object: nil
            )
        }
    }

    func sendData() {
        let postText: String = cellPostText
        let contentWarning = spoilerText
        let postPieces = postPiecesFromPost(postText, contentWarning: contentWarning)
        if postPieces.count > 1 {
            postThread(postText, contentWarning: contentWarning)
        } else {
            // First, if necessary, do a search of the post to get it onto
            // the authenticated user's server.
            if inReplyId == "ID Requires Search" {
                // Get the local post ID, and try again
                // Checking for url as reblog or original.
                if let statURL = allStatuses.first?.reblog?.url ?? allStatuses.first?.url {
                    let request = Search.search(query: statURL, resolve: true)
                    (currentAcct as? MastodonAcctData)?.client.run(request) { statuses in
                        var successGettingPostID = false
                        if let error = statuses.error {
                            log.error("error from Search.search(): \(error)")
                            AnalyticsManager.track(event: self.inReplyId.isEmpty ? .newPostFailed : .newReplyFailed, props: ["isQuotePost": self.isQuotePost])
                            AnalyticsManager.reportError(error)
                            // I have seen 500, 503 errors returned when the serer is very busy
                        }
                        if let results = statuses.value {
                            let statuses = results.statuses
                            if let statID = statuses.first?.id {
                                successGettingPostID = true
                                DispatchQueue.main.async {
                                    self.inReplyId = statID
                                    // Try again
                                    self.sendData()
                                }
                            } else {
                                log.error("Expected a status")
                            }
                        }
                        // Put an alert to retry if needed.
                        if !successGettingPostID {
                            DispatchQueue.main.async { [weak self] in
                                self?.setPostFailure()
                            }
                        }
                    }
                } else {
                    log.error("unable to get a stat url")
                }
                return
            }

            var successSendingPost = false
            var repId: String? = nil
            if inReplyId != "" {
                repId = inReplyId
            }
            var spoilerText: String? = nil
            if self.spoilerText != "" {
                spoilerText = self.spoilerText
            }
            let request = Statuses.create(status: postText, replyToID: repId, mediaIDs: mediaIdStrings, sensitive: isSensitive, spoilerText: spoilerText, scheduledAt: scheduledTime, language: PostLanguages.shared.postLanguage, poll: GlobalStruct.newPollPost, visibility: whoCanReply ?? .public)
            (currentAcct as? MastodonAcctData)?.client.run(request) { statuses in
                print("new post - \(statuses)")
                if let error = statuses.error {
                    log.error("Unable to post; error: \(error)")
                    AnalyticsManager.track(event: self.inReplyId.isEmpty ? .newPostFailed : .newReplyFailed)
                    AnalyticsManager.reportError(error)
                }
                if let _ = statuses.value {
                    AnalyticsManager.track(event: .newPost, props:
                        [
                            "postLanguage": PostLanguages.shared.postLanguage,
                            "poll": (GlobalStruct.newPollPost?.isEmpty as? Bool) ?? false,
                            "hasMedia": self.mediaIdStrings.count > 0,
                            "numberOfMedia": self.mediaIdStrings.count,
                            "visibility": (self.whoCanReply ?? .public).rawValue,
                            "isQuotePost": self.isQuotePost,
                            "isReply": !self.inReplyId.isEmpty,
                        ])
                    successSendingPost = true
                    DispatchQueue.main.async {
                        if self.scheduledTime == nil {
                            if self.whoCanReply == .direct {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "postSentMessage"), object: nil)
                            } else {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "postPosted"), object: nil)
                            }
                        } else {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "postScheduled"), object: nil)
                        }
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateFeed"), object: nil)

                        if self.fromExpanded != "" {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateMessageList"), object: nil)
                        }

                        self.dismissTap()
                    }
                }

                // Put an alert to retry if needed.
                if !successSendingPost {
                    DispatchQueue.main.async { [weak self] in
                        self?.setPostFailure()
                    }
                }
            }
        }
    }

    func sendEditData() {
        if tableView.cellForRow(at: IndexPath(row: 1, section: 1)) is ComposeCell {
            let postText: String = cellPostText
            var spoilerText: String? = nil
            if self.spoilerText != "" {
                spoilerText = self.spoilerText
            }
            let id = "\((fromEdit?.uri ?? "").split(separator: "/").last ?? "")"
            var mediaAttributes: [String] = []
            if GlobalStruct.mediaEditID != "" {
                mediaAttributes = [GlobalStruct.mediaEditID, GlobalStruct.mediaEditDescription]
            }
            let request = Statuses.edit(id: id, status: postText, mediaIDs: mediaIdStrings, sensitive: isSensitive, spoilerText: spoilerText, poll: GlobalStruct.newPollPost, mediaAttributes: mediaAttributes)
            (currentAcct as? MastodonAcctData)?.client.run(request) { statuses in
                print("updated post - \(statuses)")
                if let error = statuses.error {
                    log.error("Unable to post; error: \(error)")
                }
                if let status = statuses.value {
                    DispatchQueue.main.async {
                        if self.fromDetailReply {
                            let object: [String: String] = [
                                "detailReplyToEdit": self.detailReplyToEdit,
                                "detailReplyTextToEdit": status.content.stripHTML(),
                            ]
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDetailReplyFromEdit"), object: object)
                        } else {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "postUpdated"), object: nil)
                        }
                        GlobalStruct.tempUpdateMetrics = [status]
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateMetrics"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateFeed"), object: nil)

                        // Consolidate list data with updated post card data and request a cell refresh
                        let newPost = PostCardModel(status: status)
                        newPost.preloadQuotePost()
                        NotificationCenter.default.post(name: PostActions.didUpdatePostCardNotification, object: nil, userInfo: ["postCard": newPost])
                    }
                }
            }
        }
    }

    func refreshDrafts() {
        do {
            GlobalStruct.drafts = try Disk.retrieve("\(AccountsManager.shared.currentAccount?.diskFolderName() ?? "")/drafts.json", from: .documents, as: [Draft].self)
            createToolbar()
        } catch {
            GlobalStruct.drafts = []
            createToolbar()
            log.warning("error fetching drafts from Disk - \(error)")
        }
    }

    @objc func postMissingAltText() {
        triggerHapticNotification()

        for index in 0 ..< numImages {
            if imageButton[index].alpha == 1, !GlobalStruct.whichImagesAltText.contains(index) {
                let vc = AltTextViewController()
                vc.currentImage = imageButton[index].currentImage ?? UIImage()
                if mediaIdStrings.count > index {
                    vc.id = mediaIdStrings[index]
                    vc.whichImagesAltText = index
                    present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                }
                break
            }
        }
    }

    private func threadingAllowed() -> Bool {
        // Threading only allowed if threader mode is enabled,
        // and this is NOT a private message.
        return GlobalStruct.threaderMode && (whoCanReply != .direct)
    }
}

// Toolbar language extension
extension NewPostViewController: TranslationComposeViewControllerDelegate {
    private func toolbarLanguageButton() -> UIBarButtonItem {
        let choose_language = NSLocalizedString("composer.chooseLanguage", comment: "")
        // Create the button menu
        var menuItems: [UIAction] = []
        let showLanguagePickerAction = UIAction(title: choose_language, image: nil, identifier: nil) { [weak self] _ in
            self?.menuShowLanguagePicker()
        }
        menuItems.append(showLanguagePickerAction)
        for language in PostLanguages.shared.postLanguages {
            let languageName = Locale.current.localizedString(forLanguageCode: language) ?? language
            let pickLanguageAction = UIAction(title: languageName, image: nil, identifier: nil) { [weak self] _ in
                self?.menuSelectLanguage(language)
            }
            menuItems.append(pickLanguageAction)
        }
        let buttonMenu = UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems)

        // Create the button
        let buttonImage = buttonImage()
        let toolbarLanguageButton = UIBarButtonItem(image: buttonImage, style: .plain, target: self, action: nil)
        toolbarLanguageButton.accessibilityLabel = choose_language
        toolbarLanguageButton.menu = buttonMenu
        return toolbarLanguageButton
    }

    private func buttonImage() -> UIImage {
        // Get the width of the current language
        let languageAbbreviation = PostLanguages.shared.postLanguage.uppercased()
        let attributedText = NSMutableAttributedString(string: languageAbbreviation, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10, weight: .medium)])
        let textSize = attributedText.size()

        // FontAwesome characters are 21 pixels high;
        // width is 21 or more to accomodate the text width
        var badgeSize = CGSize(width: 25, height: 21)
        let textwidthWithMargins = textSize.width + 7.0
        badgeSize.width = max(badgeSize.width, textwidthWithMargins)

        let badge = UIGraphicsImageRenderer(size: badgeSize).image { _ in
            // Draw the surrounding rect
            let borderWidth = 1.6
            let lineRect = CGRect(x: 2, y: 2, width: badgeSize.width - 4.0, height: 15)
            let context = UIGraphicsGetCurrentContext()!
            let clipPath: CGPath = UIBezierPath(roundedRect: lineRect, cornerRadius: 2.0).cgPath
            context.addPath(clipPath)
            context.closePath()
            context.setLineWidth(borderWidth)
            context.strokePath()
            // Draw the language abbreviation string
            let leftMargin = (badgeSize.width - textSize.width) / 2.0
            attributedText.draw(at: CGPointMake(leftMargin, 3.5))
        }
        return badge.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal)
    }

    @objc func menuShowLanguagePicker() {
        hasEditedMetadata = true
        updatePostButton()
        let vc = TranslationComposeViewController()
        vc.fromSetLanguage = true
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    @objc func menuSelectLanguage(_ language: String) {
        PostLanguages.shared.selectPostLanguage(language)
        createToolbar()
    }

    // TranslationComposeViewControllerDelegate
    func didSelectLanguage(language: String) {
        PostLanguages.shared.selectPostLanguage(language)
        createToolbar()
    }

    func removeLanguage(language: String) {
        PostLanguages.shared.removePostLanguage(language)
        createToolbar()
    }
}
