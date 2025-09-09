//
//  IconSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 20/04/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import CoreHaptics
import CoreMotion
import Foundation
import SafariServices
import UIKit

class IconSettingsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollisionBehaviorDelegate {
    var collectionView: UICollectionView!
    private var upgradeCellIsExpanded: Bool = false

    // Image name / CFBundleAlternateIcons name / Name preview override
    let icons: [[String]] = [
        ["Foil Dark", "AppIconFoilDark", ""],
        ["Dark Mode", "AppIconDarkMode", ""],
        ["Paper Dark", "AppIconPaperDark", ""],
        ["Stealth", "AppIconStealth", ""],
        ["Gold-Icon", "AppIconGold", "Gold"],
        ["Foil", "AppIconFoil", ""],
        ["Newsprint", "AppIconNewsprint", ""],
        ["Soft", "AppIconSoft", ""],
        ["Blue Jay", "AppIconBlueJay", ""],
        ["Granny Smith", "AppIconGrannySmith", ""],
        ["Nicholas", "AppIconNicholas", ""],
        ["Margot", "AppIconMargot", ""],
        ["Carroll", "AppIconCarroll", ""],
        ["Burton", "AppIconBurton", ""],
        ["Benson", "AppIconBenson", ""],
        ["Schultz", "AppIconSchultz", ""],
        ["Blueprints", "AppIconBlueprints", ""],
        ["Sticker", "AppIconSticker", ""],
        ["Layout", "AppIconLayout", ""],
        ["Paper Light", "AppIconPaperLight", ""],
        ["Pride", "AppIconPride", "Pride"],
        ["Pride Slant", "AppIconPrideSlant", ""],
        ["Pride Dark", "AppIconPrideDark", ""],
        ["Pride Light", "AppIconPrideLight", ""],
        ["Six Colors", "AppIconSixColors", "6 Colors"],
        ["Six Colors Slant", "AppIconSixColorsSlant", "6 Colors Slant"],
        ["Six Colors Dark", "AppIconSixColorsDark", "6 Colors Dark"],
        ["Six Colors Light", "AppIconSixColorsLight", "6 Colors Light"],
        ["OG", "AppIconOG", ""],
        ["OG Monochrome", "AppIconOGMonochrome", "OG Mono"],
        ["OG Light", "AppIconOGLight", ""],
        ["OG White", "AppIconOGWhite", ""],
        ["OG Pride", "AppIconOGPride", ""],
        ["OG Six Colors", "AppIconOGSixColors", "OG 6 Colors"],
        ["OG Pumpkin", "AppIconOGPumpkin", ""],
        ["OG Margot", "AppIconOGMargot", ""],
    ]

    let legacyIcons: [[String]] = [
        ["IconPride", "AppIconPride"],
        ["Icon", "AppIcon"],
        ["Icon1", "AppIcon1"],
        ["Icon2", "AppIcon2"],
        ["Icon3", "AppIcon3"],
        ["Icon4", "AppIcon4"],
        ["Icon5", "AppIcon5"],
        ["Icon6", "AppIcon6"],
        ["IconBlack", "AppIconBlack"],
        ["IconB", "AppIconB"],
        ["IconB1", "AppIconB1"],
        ["IconB2", "AppIconB2"],
        ["IconB3", "AppIconB3"],
        ["IconB4", "AppIconB4"],
        ["IconB5", "AppIconB5"],
        ["IconB6", "AppIconB6"],
        ["IconBBlack", "AppIconBBlack"],
        ["IconC", "AppIconC"],
        ["IconC1", "AppIconC1"],
        ["IconC2", "AppIconC2"],
        ["IconC3", "AppIconC3"],
        ["IconC4", "AppIconC4"],
        ["IconC5", "AppIconC5"],
        ["IconC6", "AppIconC6"],
        ["IconCBlack", "AppIconCBlack"],
    ]

    let appOriginalIconName = "AppIcon"
    let appOriginalIconNameHighRes = "AppIconHighRes"
    var doneOnce: Bool = false
    var motionManager: CMMotionManager!
    var animator: UIDynamicAnimator!
    var gravity: UIGravityBehavior!
    var collision: UICollisionBehavior!
    var bounce: UIDynamicItemBehavior!
    var engine: CHHapticEngine!
    var engineNeedsStart = true

    @objc func rotated() {
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
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
        navigationItem.title = NSLocalizedString("settings.appIcon.title", comment: "")

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

        title = NSLocalizedString("settings.appIcon.title", comment: "")

        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
        let layout = ColumnFlowLayout(
            cellsPerRow: 4,
            minimumInteritemSpacing: 18,
            minimumLineSpacing: 18,
            sectionInset: UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
        )
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        if #available(iOS 15.0, *) {
            self.collectionView.allowsFocus = true
        }

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.register(UpgradeItem.self, forCellWithReuseIdentifier: UpgradeItem.reuseIdentifier)
        collectionView.register(CollectionHeader.self, forCellWithReuseIdentifier: CollectionHeader.reuseIdentifier)
        view.addSubview(collectionView)

        collectionView.pinEdges()

        if let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewLayout.estimatedItemSize = CGSize(width: 1, height: 1)
        }

        collectionView.reloadData()

        createAndStartHapticEngine()
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

    func currentActiveImageString() -> String? {
        if let current = icons.first(where: { icon in
            if icon[1] == UIApplication.shared.alternateIconName {
                return true
            }
            return false
        }) {
            return current[0]
        } else if let current = legacyIcons.first(where: { icon in
            if icon[1] == UIApplication.shared.alternateIconName {
                return true
            }
            return false
        }) {
            return current[0]
        } else {
            return appOriginalIconName
        }
    }

    // MARK: CollectionView

    func numberOfSections(in _: UICollectionView) -> Int {
        let isGoldMember = IAPManager.isGoldMember
        return isGoldMember ? 2 : 3
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let isGoldMember = IAPManager.isGoldMember

        if section == 0 {
            return 1
        }

        if !isGoldMember && section == 1 {
            return 1
        }

        return icons.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionHeader.reuseIdentifier, for: indexPath) as! CollectionHeader
            cell.parentWidth = collectionView.bounds.size.width
            cell.configure(image: UIImage(named: appOriginalIconNameHighRes))
            cell.isActive = currentActiveImageString() == appOriginalIconName
            return cell
        }

        let isGoldMember = IAPManager.isGoldMember
        if indexPath.section == 1 && indexPath.item == 0 && !isGoldMember {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UpgradeItem.reuseIdentifier, for: indexPath) as? UpgradeItem {
                cell.delegate = self
                cell.configure(expanded: upgradeCellIsExpanded, title: "Mammoth Gold", featureName: NSLocalizedString("settings.gold.unlock", comment: ""))
                cell.parentWidth = collectionView.bounds.size.width
                return cell
            }
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.contentView.alpha = isGoldMember ? 1 : 0.40
        cell.parentWidth = collectionView.bounds.size.width
        cell.backgroundColor = UIColor.clear

        let imageName = icons[indexPath.row][0]
        cell.image.image = UIImage(named: imageName)
        cell.image.contentMode = .scaleAspectFill
        cell.isActive = currentActiveImageString() == imageName
        cell.nameLabel.text = !icons[indexPath.row][2].isEmpty ? icons[indexPath.row][2] : icons[indexPath.row][0]
        cell.nameLabel.isHidden = false

        if #available(iOS 13.4, *) {
            let interaction = UIPointerInteraction(delegate: nil)
            cell.addInteraction(interaction)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let isGoldMember = IAPManager.isGoldMember
        if !isGoldMember {
            let upgradeIndexItem = IndexPath(item: 0, section: 1)

            if collectionView.contentOffset.y != 0 {
                collectionView.scrollToItem(at: upgradeIndexItem, at: .centeredVertically, animated: true)
            }

            DispatchQueue.main.async {
                var needsRefresh = true

                if !self.upgradeCellIsExpanded, indexPath != upgradeIndexItem {
                    self.upgradeCellIsExpanded = true
                } else if indexPath != upgradeIndexItem {
                    needsRefresh = false
                } else {
                    self.upgradeCellIsExpanded = !self.upgradeCellIsExpanded
                }

                if needsRefresh {
                    if #available(iOS 15.0, *) {
                        collectionView.reconfigureItems(at: [upgradeIndexItem])
                    } else {
                        collectionView.reloadItems(at: [upgradeIndexItem])
                    }
                }
            }

            return
        }

        guard UIApplication.shared.supportsAlternateIcons else {
            log.error("App does not support alternative icons")
            return
        }

        triggerHapticImpact(style: .light)

        if indexPath.section == 0 {
            UIApplication.shared.setAlternateIconName(nil)
        } else {
            UIApplication.shared.setAlternateIconName(icons[indexPath.row][1]) { error in
                if let error = error {
                    log.error("Unable to set custom icon: \(error.localizedDescription)")
                } else {}
            }
        }

        collectionView.reloadSections([0, 1])

        let confettiView = SAConfettiView(frame: view.bounds)
        confettiView.colors = [UIColor.systemBlue, UIColor.systemIndigo, UIColor.systemPurple, UIColor(red: 63 / 255, green: 180 / 255, blue: 78 / 255, alpha: 1), UIColor.systemOrange, UIColor.systemPink, UIColor(red: 245 / 255.0, green: 130 / 255.0, blue: 190 / 255.0, alpha: 1.000), UIColor(red: 252 / 255.0, green: 120 / 255.0, blue: 161 / 255.0, alpha: 1.000), UIColor.systemGray, UIColor.systemBlue, UIColor.systemIndigo, UIColor.systemPurple, UIColor(red: 63 / 255, green: 180 / 255, blue: 78 / 255, alpha: 1), UIColor.systemOrange, UIColor.systemPink, UIColor(red: 245 / 255.0, green: 130 / 255.0, blue: 190 / 255.0, alpha: 1.000), UIColor(red: 252 / 255.0, green: 120 / 255.0, blue: 161 / 255.0, alpha: 1.000)]
        confettiView.intensity = 1.2
        confettiView.isUserInteractionEnabled = false
        view.addSubview(confettiView)
        confettiView.startConfetti()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            confettiView.stopConfetti()
        }
    }
}

extension IconSettingsViewController: UpgradeViewDelegate {
    func onStateChange(state _: UpgradeRootView.UpgradeViewState) {
        if !IAPManager.isGoldMember {
            let upgradeIndexItem = IndexPath(item: 0, section: 1)
            if #available(iOS 15.0, *) {
                collectionView.reconfigureItems(at: [upgradeIndexItem])
            } else {
                collectionView.reloadItems(at: [upgradeIndexItem])
            }
        } else {
            collectionView.reloadData()
        }
    }
}

extension IconSettingsViewController {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?) {
        if motion == .motionShake {
            if doneOnce == false {
                doneOnce = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.motionManager = CMMotionManager()
                    self.motionManager.startAccelerometerUpdates()
                    self.motionManager.accelerometerUpdateInterval = 0.01

                    self.motionManager.startAccelerometerUpdates(to: OperationQueue()) {
                        _, _ in
                        DispatchQueue.main.async {
                            let accelerometerData = self.motionManager.accelerometerData
                            let dx = accelerometerData!.acceleration.x
                            let dy = accelerometerData!.acceleration.y
                            self.animator.removeBehavior(self.gravity)
                            self.gravity.gravityDirection = CGVector(dx: dx, dy: dy * -1)
                            for item in self.collectionView.visibleCells {
                                self.animator.updateItem(usingCurrentState: item)
                            }
                            self.animator.addBehavior(self.gravity)
                        }
                    }

                    self.animator = UIDynamicAnimator(referenceView: self.collectionView)
                    let visibleCells = self.collectionView.visibleCells
                    self.gravity = UIGravityBehavior(items: visibleCells)
                    self.animator.addBehavior(self.gravity)

                    self.bounce = UIDynamicItemBehavior(items: visibleCells)
                    self.bounce.elasticity = 0.5
                    self.animator.addBehavior(self.bounce)

                    self.collision = UICollisionBehavior(items: visibleCells)
                    self.collision.translatesReferenceBoundsIntoBoundary = true
                    self.collision.collisionDelegate = self
                    self.animator.addBehavior(self.collision)
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
}

class ImageCell: UICollectionViewCell {
    private let mainStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 6
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .zero
        return stackView
    }()

    var image = UIImageView()
    var parentWidth: CGFloat?

    let nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 6, weight: .medium)
        label.textAlignment = .center
        label.textColor = .custom.mediumContrast
        label.isHidden = true
        return label
    }()

    private let badge: GradientButton = {
        let gradientColor = [
            UIColor(red: 240.0 / 255, green: 203.0 / 255, blue: 147.0 / 255, alpha: 1.0).cgColor,
            UIColor(red: 223.0 / 255, green: 168.0 / 255, blue: 86.0 / 255, alpha: 1.0).cgColor,
        ]

        let view = GradientButton(colors: gradientColor, startPoint: .init(x: 1, y: 0), endPoint: .init(x: 0, y: 1))
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(FontAwesome.image(fromChar: "\u{f00c}", size: 11, weight: .bold), for: .normal)
        view.layer.cornerRadius = 9.25
        view.layer.cornerCurve = .continuous
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1.5
        view.imageEdgeInsets = .init(top: 2, left: 1, bottom: 0, right: 0)
        view.isHidden = true
        return view
    }()

    var isActive: Bool = false {
        didSet {
            badge.isHidden = !isActive
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        var x = 4
        if UIDevice.current.userInterfaceIdiom == .pad && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            x = 8
        }
        let y = parentWidth ?? bounds.width
        let z = CGFloat(y) / CGFloat(x)

        attributes.size = CGSize(width: z - CGFloat(((x + 1) * 20) / x), height: z - CGFloat(((x + 1) * 20) / x) + 12 + 6)

        return attributes
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = ""
    }

    func setupUI() {
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear

        contentView.addSubview(mainStack)
        mainStack.pinEdges()

        image.layer.cornerRadius = 14
        image.layer.cornerCurve = .continuous
        image.layer.masksToBounds = true
        image.layer.borderWidth = 0.5
        image.layer.borderColor = UIColor(red: 188 / 255, green: 188 / 255, blue: 188 / 255, alpha: 0.15).cgColor
        image.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(image)

        NSLayoutConstraint.activate([
            image.trailingAnchor.constraint(equalTo: mainStack.layoutMarginsGuide.trailingAnchor),
            image.heightAnchor.constraint(equalTo: mainStack.widthAnchor),
        ])

        mainStack.addArrangedSubview(nameLabel)

        contentView.addSubview(badge)

        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 18.5),
            badge.heightAnchor.constraint(equalToConstant: 18.5),
            badge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 6),
            badge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -4),
        ])
    }
}

private class CollectionHeader: UICollectionViewCell {
    static let reuseIdentifier = "IconSettingsCollectionHeader"

    public var parentWidth: CGFloat?

    private let previewImage = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 13
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 188 / 255, green: 188 / 255, blue: 188 / 255, alpha: 0.15).cgColor
        return view
    }()

    private let badge: GradientButton = {
        let gradientColor = [
            UIColor(red: 240.0 / 255, green: 203.0 / 255, blue: 147.0 / 255, alpha: 1.0).cgColor,
            UIColor(red: 223.0 / 255, green: 168.0 / 255, blue: 86.0 / 255, alpha: 1.0).cgColor,
        ]

        let view = GradientButton(colors: gradientColor, startPoint: .init(x: 1, y: 0), endPoint: .init(x: 0, y: 1))
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(FontAwesome.image(fromChar: "\u{f00c}", size: 11, weight: .bold), for: .normal)
        view.layer.cornerRadius = 9.25
        view.layer.cornerCurve = .continuous
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 1.5
        view.imageEdgeInsets = .init(top: 2, left: 1, bottom: 0, right: 0)
        view.isHidden = true
        return view
    }()

    public var isActive: Bool = false {
        didSet {
            badge.isHidden = !isActive
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.size = CGSize(width: (parentWidth ?? bounds.width) - 40, height: attributes.size.height)
        return attributes
    }

    private func setupUI() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        container.addSubview(previewImage)
        container.addSubview(badge)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 80),
            container.heightAnchor.constraint(equalToConstant: 80),
            container.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            previewImage.widthAnchor.constraint(equalToConstant: 80),
            previewImage.heightAnchor.constraint(equalToConstant: 80),
            previewImage.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            previewImage.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            contentView.heightAnchor.constraint(equalToConstant: 100),

            badge.widthAnchor.constraint(equalToConstant: 18.5),
            badge.heightAnchor.constraint(equalToConstant: 18.5),
            badge.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 6),
            badge.topAnchor.constraint(equalTo: container.topAnchor, constant: -4),
        ])
    }

    public func configure(image: UIImage?) {
        previewImage.image = image
    }
}
