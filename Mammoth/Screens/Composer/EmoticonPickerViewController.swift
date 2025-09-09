//
//  EmoticonPickerViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 05/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import SafariServices
import UIKit

class EmoticonPickerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let btn0 = UIButton(type: .custom)
    var collectionView: UICollectionView!
    var doneOnce: Bool = false
    var engineNeedsStart = true

    let emoticons: [Emoji]?

    init(emoticons: [Emoji]?) {
        self.emoticons = emoticons
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func rotated() {
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        collectionView.frame = CGRect(x: 0, y: Int(navigationController?.navigationBar.bounds.height ?? 0), width: Int(view.bounds.width), height: Int(view.bounds.height) - Int(navigationController?.navigationBar.bounds.height ?? 0))

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
        navigationItem.title = NSLocalizedString("composer.addEmoji", comment: "")

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

        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)

        btn0.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn0.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn0.layer.cornerRadius = 14
        btn0.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn0.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn0.addTarget(self, action: #selector(dismissTap), for: .touchUpInside)
        btn0.accessibilityLabel = NSLocalizedString("generic.dismiss", comment: "")
        let moreButton1 = UIBarButtonItem(customView: btn0)
        navigationItem.setLeftBarButton(moreButton1, animated: true)

        NotificationCenter.default.addObserver(self, selector: #selector(reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)

        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
        let layout = ColumnFlowLayout(
            cellsPerRow: 4,
            minimumInteritemSpacing: 18,
            minimumLineSpacing: 18,
            sectionInset: UIEdgeInsets(top: 20, left: 20, bottom: 48, right: 20)
        )
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: Int(view.bounds.width), height: Int(view.bounds.height)), collectionViewLayout: layout)
        if #available(iOS 15.0, *) {
            self.collectionView.allowsFocus = true
        }
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseIdentifier)
        view.addSubview(collectionView)
        collectionView.reloadData()
    }

    // MARK: CollectionView

    func allEmoticons() -> [Emoji] {
        return emoticons ?? []
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return allEmoticons().count
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let x = 6
        let y = view.bounds.width
        let z = CGFloat(y) / CGFloat(x)
        return CGSize(width: z - CGFloat(((x + 1) * 20) / x), height: z - CGFloat(((x + 1) * 20) / x))
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCell.reuseIdentifier, for: indexPath) as! EmojiCell
        cell.image.image = nil
        let x = 6
        let y = view.bounds.width
        let z = CGFloat(y) / CGFloat(x)
        cell.image.frame.size.width = z - CGFloat(((x + 1) * 20) / x)
        cell.image.frame.size.height = z - CGFloat(((x + 1) * 20) / x)
        cell.image.sd_setImage(with: allEmoticons()[indexPath.row].url)
        if #available(iOS 13.4, *) {
            let interaction = UIPointerInteraction(delegate: nil)
            cell.addInteraction(interaction)
        }
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        triggerHapticImpact(style: .light)
        GlobalStruct.emoticonToAdd = allEmoticons()[indexPath.row].shortcode
        NotificationCenter.default.post(name: Notification.Name(rawValue: "addEmoji"), object: self)
        dismiss(animated: true)
    }
}
