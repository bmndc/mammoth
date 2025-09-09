//
//  GalleryViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/07/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import AVFoundation
import AVKit
import CoreHaptics
import CoreMotion
import Foundation
import LinkPresentation
import NaturalLanguage
import Photos
import SafariServices
import UIKit
import Vision

// swiftlint:disable:next type_body_length
class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollisionBehaviorDelegate, SKPhotoBrowserDelegate, AVPlayerViewControllerDelegate, UIActivityItemSource {
    let emptyView = UIImageView()
    var collectionView: UICollectionView!
    var statuses: [Status] = []
    var statusesNext: RequestRange?
    var otherUserId: String = ""
    var doneOnce: Bool = false
    var motionManager: CMMotionManager!
    var animator: UIDynamicAnimator!
    var gravity: UIGravityBehavior!
    var collision: UICollisionBehavior!
    var bounce: UIDynamicItemBehavior!
    var engine: CHHapticEngine!
    var engineNeedsStart = true
    var tmpIndex: Int = 0

    @objc func rotated() {
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        collectionView.frame = CGRect(x: 0, y: Int(navigationController?.navigationBar.bounds.height ?? 0), width: Int(view.bounds.width), height: Int(view.bounds.height) - Int(navigationController?.navigationBar.bounds.height ?? 0))
        emptyView.center = CGPoint(x: view.center.x, y: view.center.y - 30)

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
    }

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        dismiss(animated: true, completion: nil)
    }

    @objc func reloadAll() {
        DispatchQueue.main.async {
            // tints

            let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
            if hcText == true {
                UIColor.custom.mainTextColor = .label
            } else {
                UIColor.custom.mainTextColor = .secondaryLabel
            }
            self.collectionView.reloadData()

            // update various elements
            self.view.backgroundColor = .custom.backgroundTint
            let navApp = UINavigationBarAppearance()
            navApp.configureWithOpaqueBackground()
            navApp.backgroundColor = .custom.backgroundTint
            navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
            self.navigationController?.navigationBar.standardAppearance = navApp
            self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
            self.navigationController?.navigationBar.compactAppearance = navApp
            if #available(iOS 15.0, *) {
                self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
            }
            if GlobalStruct.hideNavBars2 {
                self.extendedLayoutIncludesOpaqueBars = true
            } else {
                self.extendedLayoutIncludesOpaqueBars = false
            }
        }
    }

    @objc func reloadBars() {
        DispatchQueue.main.async {
            if GlobalStruct.hideNavBars2 {
                self.extendedLayoutIncludesOpaqueBars = true
            } else {
                self.extendedLayoutIncludesOpaqueBars = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .custom.backgroundTint
        navigationItem.title = "Recent Media"

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

        NotificationCenter.default.addObserver(self, selector: #selector(reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)

        title = "Recent Media"

        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
        let layout = ColumnFlowLayout(
            cellsPerRow: 3,
            minimumInteritemSpacing: 0,
            minimumLineSpacing: 0,
            sectionInset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: Int(view.bounds.width), height: Int(view.bounds.height)), collectionViewLayout: layout)
        if #available(iOS 15.0, *) {
            self.collectionView.allowsFocus = true
        }
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        view.addSubview(collectionView)
        collectionView.reloadData()

        emptyView.bounds.size.width = 80
        emptyView.bounds.size.height = 80
        emptyView.backgroundColor = UIColor.clear
        emptyView.image = UIImage(systemName: "sparkles", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))?.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.18), renderingMode: .alwaysOriginal)
        emptyView.alpha = 0
        collectionView.addSubview(emptyView)

        createAndStartHapticEngine()

        // fetch media
        fetchData()
    }

    @objc func fetchData(_ nextBatch: Bool = false) {
        var id: String = AccountsManager.shared.currentUser()?.id ?? ""
        if otherUserId != "" {
            id = otherUserId
        }
        var canLoad = true
        var request = Accounts.statuses(id: id, mediaOnly: true)
        if nextBatch {
            if let ra = statusesNext {
                request = Accounts.statuses(id: id, mediaOnly: true, range: ra)
            } else {
                canLoad = false
            }
        }
        if canLoad {
            AccountsManager.shared.currentAccountClient.run(request) { statuses in
                self.statusesNext = statuses.pagination?.next
                if let error = statuses.error {
                    log.error("Failed to fetch timeline: \(error)")
                    DispatchQueue.main.async {
                        if self.statuses.isEmpty {
                            self.emptyView.alpha = 1
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        if (statuses.value?.count ?? 0) > 0 {
                            self.emptyView.alpha = 0
                        } else {
                            self.emptyView.alpha = 1
                        }
                    }
                }
                if let stat = (statuses.value) {
                    if nextBatch {
                        self.statuses += stat
                    } else {
                        self.statuses = stat
                    }
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }

    func createAndStartHapticEngine() {
        do {
            engine = try CHHapticEngine()
        } catch {
            log.error("Engine Creation Error: \(error)")
            return
        }
        engine.stoppedHandler = { reason in
            log.error("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
            switch reason {
            case .audioSessionInterrupt:
                log.error("Audio session interrupt.")
            case .applicationSuspended:
                log.error("Application suspended.")
            case .idleTimeout:
                log.error("Idle timeout.")
            case .notifyWhenFinished:
                log.error("Finished.")
            case .systemError:
                log.error("System error.")
            case .engineDestroyed:
                log.error("Engine destroyed.")
            case .gameControllerDisconnect:
                log.error("Controller disconnected.")
            @unknown default:
                log.error("Unknown error. Haptic engine not available.")
            }
            self.engineNeedsStart = true
        }
        engine.resetHandler = {
            print("The engine reset --> Restarting now!")
            self.engineNeedsStart = true
        }
        do {
            try engine.start()
            engineNeedsStart = false
        } catch {
            log.error("The engine failed to start with error: \(error)")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if engine != nil {
            engine.stop(completionHandler: { err in
                if let err = err {
                    log.error("Failed to start engine - \(err)")
                }
            })
        }
    }

    func collisionBehavior(_: UICollisionBehavior,
                           beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier _: NSCopying?,
                           at _: CGPoint)
    {
        do {
            if engineNeedsStart {
                try engine.start()
                engineNeedsStart = false
            }
            let velocity = bounce.linearVelocity(for: item)
            let xVelocity = Float(velocity.x)
            let yVelocity = Float(velocity.y)

            let magnitude = sqrtf(xVelocity * xVelocity + yVelocity * yVelocity)
            let normalizedMagnitude = min(max(Float(magnitude) / 3000, 0.0), 1.0)

            let hapticPlayer = try playerForMagnitude(normalizedMagnitude)

            try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            log.error("Haptic Playback Error: \(error)")
        }
    }

    func playerForMagnitude(_ magnitude: Float) throws -> CHHapticPatternPlayer? {
        let volume = linearInterpolation(alpha: magnitude, min: 0.1, max: 0.4)
        let decay: Float = linearInterpolation(alpha: magnitude, min: 0.0, max: 0.1)
        let audioEvent = CHHapticEvent(eventType: .audioContinuous, parameters: [
            CHHapticEventParameter(parameterID: .audioPitch, value: -0.15),
            CHHapticEventParameter(parameterID: .audioVolume, value: volume),
            CHHapticEventParameter(parameterID: .decayTime, value: decay),
            CHHapticEventParameter(parameterID: .sustained, value: 0),
        ], relativeTime: 0)

        let sharpness = linearInterpolation(alpha: magnitude, min: 0.9, max: 0.5)
        let intensity = linearInterpolation(alpha: magnitude, min: 0.375, max: 1.0)
        let hapticEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
        ], relativeTime: 0)

        let pattern = try CHHapticPattern(events: [audioEvent, hapticEvent], parameters: [])
        return try engine.makePlayer(with: pattern)
    }

    func linearInterpolation(alpha: Float, min: Float, max: Float) -> Float {
        return min + alpha * (max - min)
    }

    // MARK: CollectionView

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return statuses.count
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let x = 3
        let y = view.bounds.width
        let z = CGFloat(y) / CGFloat(x)
        return CGSize(width: z, height: z)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        if indexPath.item < statuses.count {
            emptyView.alpha = 0
            let stat: Status? = statuses[indexPath.row]
            cell.image.image = nil
            cell.layer.cornerRadius = 0
            cell.image.layer.cornerRadius = 0
            cell.image.layer.masksToBounds = true
            cell.backgroundColor = UIColor.clear
            let x = 3
            let y = view.bounds.width
            let z = CGFloat(y) / CGFloat(x)
            cell.image.frame.size.width = z
            cell.image.frame.size.height = z

            if stat?.reblog?.mediaAttachments.count ?? stat?.mediaAttachments.count ?? 0 > 0 {
                let z = stat?.reblog?.mediaAttachments ?? stat?.mediaAttachments ?? []
                let mediaItems = z[0].previewURL ?? ""
                if let ur = URL(string: mediaItems) {
                    cell.image.sd_setImage(with: ur)
                }
            }

            var minusDiff = 3
            if statuses.count < 4 {
                minusDiff = 1
            }
            if indexPath.item == statuses.count - minusDiff {
                fetchData(true)
            }
        }

        cell.image.contentMode = .scaleAspectFill
        if #available(iOS 13.4, *) {
            let interaction = UIPointerInteraction(delegate: nil)
            cell.addInteraction(interaction)
        }
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let status = statuses[indexPath.row]
        let vc = DetailViewController(post: PostCardModel(status: status))
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else { return nil }
        if let cell = collectionView.cellForItem(at: indexPath) as? ImageCell {
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .clear
            return UITargetedPreview(view: cell.image, parameters: parameters)
        } else {
            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else { return nil }
        if let cell = collectionView.cellForItem(at: indexPath) as? ImageCell {
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = .clear
            return UITargetedPreview(view: cell.image, parameters: parameters)
        } else {
            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: {
            self.makePreview(indexPath.row)
        }, actionProvider: { _ in
            self.makeContextMenu(indexPath.row, collectionView: collectionView)
        })
    }

    func makePreview(_ index: Int) -> UIViewController {
        if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? ImageCell {
            let theImage = cell.image.image ?? UIImage()
            let viewController = UIViewController()
            let imageView = UIImageView(image: theImage)
            viewController.view = imageView
            var ratioS: CGFloat = 1
            if theImage.size.height == 0 {} else {
                ratioS = theImage.size.width / theImage.size.height
            }
            if theImage == UIImage() {
                imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.width / ratioS)
            }
            imageView.contentMode = .scaleAspectFit
            viewController.preferredContentSize = imageView.frame.size
            return viewController
        } else {
            return UIViewController()
        }
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        return ""
    }

    func activityViewController(_: UIActivityViewController, itemForActivityType _: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        var image1 = UIImage()
        if let cell = collectionView.cellForItem(at: IndexPath(item: tmpIndex, section: 0)) as? ImageCell {
            image1 = cell.image.image ?? UIImage()
        }
        let image = image1
        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        return metadata
    }

    func makeContextMenu(_ index: Int, collectionView: UICollectionView) -> UIMenu {
        var image1 = UIImage()
        if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ImageCell {
            image1 = cell.image.image ?? UIImage()
        }
        let copy = UIAction(title: NSLocalizedString("generic.copy", comment: ""), image: UIImage(systemName: "doc.on.doc"), identifier: nil) { _ in
            UIPasteboard.general.image = image1
        }
        let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: FontAwesome.image(fromChar: "\u{e09a}"), identifier: nil) { _ in
            self.tmpIndex = index
            let imToShare = [image1, self]
            let activityViewController = UIActivityViewController(activityItems: imToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
            getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
        }
        let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { _ in
            UIImageWriteToSavedPhotosAlbum(image1, nil, nil, nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "savedImage"), object: nil)
        }
        let actMenu = UIMenu(title: "", options: [.displayInline], children: [copy, share, save])
        if #available(iOS 16.0, *) {
            actMenu.preferredElementSize = .small
        }
        return UIMenu(title: "", image: nil, identifier: nil, children: [actMenu])
    }
}
