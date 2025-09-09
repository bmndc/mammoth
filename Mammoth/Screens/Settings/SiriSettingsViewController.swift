//
//  SiriSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 13/07/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import CoreSpotlight
import Foundation
import IntentsUI
import MobileCoreServices
import UIKit

class SiriSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, INUIAddVoiceShortcutViewControllerDelegate {
    var tableView = UITableView()
    let firstSection = [NSLocalizedString("settings.siriShortcuts.compose", comment: "")]
    var section0Images: [String] = ["square.and.pencil"]
    var latestTapped = 0

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)

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

    @objc func reloadAll() {
        DispatchQueue.main.async {
            // tints

            let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
            if hcText == true {
                UIColor.custom.mainTextColor = .label
            } else {
                UIColor.custom.mainTextColor = .secondaryLabel
            }
            self.tableView.reloadData()

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

    @objc func dismissTap() {
        dismiss(animated: true, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTabBar"), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateTabBar"), object: nil)
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
        navigationItem.title = NSLocalizedString("settings.siriShortcuts.title", comment: "")
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

        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
        if #available(iOS 15.0, *) {
            self.tableView.allowsFocus = true
        }
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        tableView.reloadData()

        if let userP = UserDefaults.standard.value(forKey: "siriPhrases") as? [String] {
            for _ in firstSection {
                GlobalStruct.siriPhrases.append("")
            }
            GlobalStruct.siriPhrases = userP
            if GlobalStruct.siriPhrases.count < firstSection.count {
                for _ in 0 ..< (firstSection.count - GlobalStruct.siriPhrases.count) {
                    GlobalStruct.siriPhrases.append("")
                }
            }
        } else {
            _ = firstSection.map { _ in
                GlobalStruct.siriPhrases.append("")
            }
        }
    }

    // MARK: TableView

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return firstSection.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell")
        cell.textLabel?.numberOfLines = 0
        cell.imageView?.image = settingsSystemImage(section0Images[indexPath.row])
        cell.textLabel?.text = firstSection[indexPath.row]
        cell.backgroundColor = .custom.OVRLYSoftContrast

        if GlobalStruct.siriPhrases[indexPath.row] == "" {} else {
            cell.detailTextLabel?.text = "\"\(GlobalStruct.siriPhrases[indexPath.row])\""
            cell.detailTextLabel?.textColor = UIColor.secondaryLabel
        }

        if #available(iOS 15.0, *) {
            cell.focusEffect = UIFocusHaloEffect()
        }
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        #if !targetEnvironment(macCatalyst)
            latestTapped = indexPath.row

            if latestTapped == 0 {
                let activity1 = NSUserActivity(activityType: "com.theblvd.mammoth.new")
                activity1.title = NSLocalizedString("settings.siriShortcuts.compose", comment: "")
                let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
                attributes.contentDescription = NSLocalizedString("settings.siriShortcuts.compose", comment: "")
                activity1.contentAttributeSet = attributes
                activity1.isEligibleForSearch = true
                activity1.isEligibleForPrediction = true
                activity1.persistentIdentifier = "com.theblvd.mammoth.new"
                activity1.suggestedInvocationPhrase = NSLocalizedString("settings.siriShortcuts.compose", comment: "")
                activity1.persistentIdentifier = String(latestTapped)
                view.userActivity = activity1
                activity1.becomeCurrent()
                let shortcut = INShortcut(userActivity: activity1)
                let vc = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            }
        #endif
    }

    func addVoiceShortcutViewController(_: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error _: Error?) {
        GlobalStruct.siriPhrases[latestTapped] = "\(voiceShortcut?.invocationPhrase ?? "")"
        UserDefaults.standard.set(GlobalStruct.siriPhrases, forKey: "siriPhrases")
        tableView.reloadData()
        dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewControllerDidCancel(
        _: INUIAddVoiceShortcutViewController)
    {
        dismiss(animated: true, completion: nil)
    }

    func tableView(_: UITableView, titleForFooterInSection _: Int) -> String? {
        return NSLocalizedString("settings.siriShortcuts.footer1", comment: "") + "\n\n" + NSLocalizedString("settings.siriShortcuts.footer2", comment: "")
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}
