//
//  NotificationSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 21/07/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import CoreSpotlight
import Foundation
import IntentsUI
import MobileCoreServices
import UIKit

// This may prompt the user
func EnablePushNotificationSetting(checkOnlyOnceFlag: Bool, completionHandler: ((Bool) -> Void)? = nil) {
    // In some cases, we only want to prompt the user once per lifetime (switching to the
    // Activity or Mentions tab). In those cases, check to see if we've prompted the
    // user and don't do so again.
    var proceed = true
    if checkOnlyOnceFlag {
        if UserDefaults.standard.value(forKey: "doNotifOnce") == nil {
            UserDefaults.standard.set(true, forKey: "doNotifOnce")
        } else {
            proceed = false
        }
    }

    if proceed {
        let authOptions = UNAuthorizationOptions(arrayLiteral: .alert, .badge, .sound)
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                log.error("Error: \(error)")
                AnalyticsManager.failedToRegisterForPushNotifications(error: error)
            }
            if success {
                DispatchQueue.main.async {
                    GlobalStruct.notifs1 = true
                    UserDefaults.standard.set(true, forKey: "notifs1")
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            completionHandler?(success)
        }
    }
}

func DisablePushNotificationsSetting(completionHandler: @escaping () -> Void) {
    GlobalStruct.notifs1 = false
    UserDefaults.standard.set(false, forKey: "notifs1")
    Task {
        for account in AccountsManager.shared.allAccounts {
            if let account = account as? MastodonAcctData {
                try await PushNotificationManager.unsubscribe(account: account)
            }
        }
        await MainActor.run {
            completionHandler()
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }
}

// swiftlint:disable:next type_body_length
class NotificationSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var tableView = UITableView()
    let firstSection = [NSLocalizedString("settings.notifications.activity", comment: "")]
    var section0Images: [String] = ["app.badge"]
    var secondSection = [NSLocalizedString("navigator.mentions", comment: ""), NSLocalizedString("activity.likes", comment: ""), NSLocalizedString("activity.reposts", comment: ""), NSLocalizedString("activity.newFollowers", comment: ""), NSLocalizedString("activity.polls", comment: ""), NSLocalizedString("activity.newPosts", comment: "")]
    var section1Images: [String] = ["at", "heart", "arrow.2.squarepath", "person.2", "chart.pie", "heart.text.square"]
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
        navigationItem.title = NSLocalizedString("settings.notifications.push", comment: "")

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell2")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell3")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell4")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell5")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell6")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell7")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCellai")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        tableView.reloadData()
    }

    // MARK: TableView

    func numberOfSections(in _: UITableView) -> Int {
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            return 2
        } else {
            return 3
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return firstSection.count
        } else if section == 1 {
            return secondSection.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
            cell = UITableViewCell(style: .default, reuseIdentifier: "settingsCell")
            cell.textLabel?.numberOfLines = 0
            cell.imageView?.image = settingsSystemImage(section0Images[indexPath.row])
            cell.textLabel?.text = firstSection[indexPath.row]
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "notifs1") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "notifs1") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(false, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(switchNotifs1(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            cell.backgroundColor = .custom.OVRLYSoftContrast
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell2", for: indexPath)
                cell = UITableViewCell(style: .default, reuseIdentifier: "settingsCell2")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = settingsSystemImage(section1Images[indexPath.row])
                cell.textLabel?.text = secondSection[indexPath.row]
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "pnMentions") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "pnMentions") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(switchpnMentions(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                if GlobalStruct.notifs1 {
                    cell.textLabel?.isEnabled = true
                    cell.detailTextLabel?.isEnabled = true
                    cell.isUserInteractionEnabled = true
                    cell.imageView?.tintColor = .custom.baseTint
                    switchView.isEnabled = true
                } else {
                    cell.textLabel?.isEnabled = false
                    cell.detailTextLabel?.isEnabled = false
                    cell.isUserInteractionEnabled = false
                    cell.imageView?.tintColor = UIColor.secondaryLabel
                    switchView.isEnabled = false
                }
                return cell
            } else if indexPath.row == 1 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell3", for: indexPath)
                cell = UITableViewCell(style: .default, reuseIdentifier: "settingsCell3")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = settingsSystemImage(section1Images[indexPath.row])
                cell.textLabel?.text = secondSection[indexPath.row]
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "pnLikes") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "pnLikes") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(switchpnLikes(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                if GlobalStruct.notifs1 {
                    cell.textLabel?.isEnabled = true
                    cell.detailTextLabel?.isEnabled = true
                    cell.isUserInteractionEnabled = true
                    cell.imageView?.tintColor = .custom.baseTint
                    switchView.isEnabled = true
                } else {
                    cell.textLabel?.isEnabled = false
                    cell.detailTextLabel?.isEnabled = false
                    cell.isUserInteractionEnabled = false
                    cell.imageView?.tintColor = UIColor.secondaryLabel
                    switchView.isEnabled = false
                }
                return cell
            } else if indexPath.row == 2 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell4", for: indexPath)
                cell = UITableViewCell(style: .default, reuseIdentifier: "settingsCell4")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = settingsSystemImage(section1Images[indexPath.row])
                cell.textLabel?.text = secondSection[indexPath.row]
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "pnReposts") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "pnReposts") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(switchpnReposts(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                if GlobalStruct.notifs1 {
                    cell.textLabel?.isEnabled = true
                    cell.detailTextLabel?.isEnabled = true
                    cell.isUserInteractionEnabled = true
                    cell.imageView?.tintColor = .custom.baseTint
                    switchView.isEnabled = true
                } else {
                    cell.textLabel?.isEnabled = false
                    cell.detailTextLabel?.isEnabled = false
                    cell.isUserInteractionEnabled = false
                    cell.imageView?.tintColor = UIColor.secondaryLabel
                    switchView.isEnabled = false
                }
                return cell
            } else if indexPath.row == 3 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell5", for: indexPath)
                cell = UITableViewCell(style: .default, reuseIdentifier: "settingsCell5")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = settingsSystemImage(section1Images[indexPath.row])
                cell.textLabel?.text = secondSection[indexPath.row]
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "pnFollows") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "pnFollows") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(switchpnFollows(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                if GlobalStruct.notifs1 {
                    cell.textLabel?.isEnabled = true
                    cell.detailTextLabel?.isEnabled = true
                    cell.isUserInteractionEnabled = true
                    cell.imageView?.tintColor = .custom.baseTint
                    switchView.isEnabled = true
                } else {
                    cell.textLabel?.isEnabled = false
                    cell.detailTextLabel?.isEnabled = false
                    cell.isUserInteractionEnabled = false
                    cell.imageView?.tintColor = UIColor.secondaryLabel
                    switchView.isEnabled = false
                }
                return cell
            } else if indexPath.row == 4 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell6", for: indexPath)
                cell = UITableViewCell(style: .default, reuseIdentifier: "settingsCell6")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = settingsSystemImage(section1Images[indexPath.row])
                cell.textLabel?.text = secondSection[indexPath.row]
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "pnPolls") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "pnPolls") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(switchpnPolls(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                if GlobalStruct.notifs1 {
                    cell.textLabel?.isEnabled = true
                    cell.detailTextLabel?.isEnabled = true
                    cell.isUserInteractionEnabled = true
                    cell.imageView?.tintColor = .custom.baseTint
                    switchView.isEnabled = true
                } else {
                    cell.textLabel?.isEnabled = false
                    cell.detailTextLabel?.isEnabled = false
                    cell.isUserInteractionEnabled = false
                    cell.imageView?.tintColor = UIColor.secondaryLabel
                    switchView.isEnabled = false
                }
                return cell
            } else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell7", for: indexPath)
                cell = UITableViewCell(style: .default, reuseIdentifier: "settingsCell7")
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = settingsSystemImage(section1Images[indexPath.row])
                cell.textLabel?.text = secondSection[indexPath.row]
                let switchView = UISwitch(frame: .zero)
                if UserDefaults.standard.value(forKey: "pnStatuses") as? Bool != nil {
                    if UserDefaults.standard.value(forKey: "pnStatuses") as? Bool == false {
                        switchView.setOn(false, animated: false)
                    } else {
                        switchView.setOn(true, animated: false)
                    }
                } else {
                    switchView.setOn(true, animated: false)
                }
                switchView.onTintColor = .custom.gold
                switchView.tintColor = .custom.baseTint
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(switchpnStatuses(_:)), for: .valueChanged)
                cell.accessoryView = switchView
                cell.selectionStyle = .none
                cell.backgroundColor = .custom.OVRLYSoftContrast
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                if GlobalStruct.notifs1 {
                    cell.textLabel?.isEnabled = true
                    cell.detailTextLabel?.isEnabled = true
                    cell.isUserInteractionEnabled = true
                    cell.imageView?.tintColor = .custom.baseTint
                    switchView.isEnabled = true
                } else {
                    cell.textLabel?.isEnabled = false
                    cell.detailTextLabel?.isEnabled = false
                    cell.isUserInteractionEnabled = false
                    cell.imageView?.tintColor = UIColor.secondaryLabel
                    switchView.isEnabled = false
                }
                return cell
            }
        } else {
            var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCellai", for: indexPath)
            cell = UITableViewCell(style: .default, reuseIdentifier: "settingsCellai")
            cell.textLabel?.numberOfLines = 0
            cell.imageView?.image = settingsSystemImage("bell.badge")
            cell.textLabel?.text = NSLocalizedString("settings.notifications.badges", comment: "")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "activityBadges") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "activityBadges") as? Bool == false {
                    switchView.setOn(false, animated: false)
                } else {
                    switchView.setOn(true, animated: false)
                }
            } else {
                switchView.setOn(true, animated: false)
            }
            switchView.onTintColor = .custom.gold
            switchView.tintColor = .custom.baseTint
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(switchActivityBadges(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            cell.backgroundColor = .custom.OVRLYSoftContrast
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            if GlobalStruct.notifs1 {
                cell.textLabel?.isEnabled = true
                cell.detailTextLabel?.isEnabled = true
                cell.isUserInteractionEnabled = true
                cell.imageView?.tintColor = .custom.baseTint
                switchView.isEnabled = true
            } else {
                cell.textLabel?.isEnabled = false
                cell.detailTextLabel?.isEnabled = false
                cell.isUserInteractionEnabled = false
                cell.imageView?.tintColor = UIColor.secondaryLabel
                switchView.isEnabled = false
            }
            return cell
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func switchNotifs1(_ sender: UISwitch!) {
        if sender.isOn {
            setupNotifs()
        } else {
            DisablePushNotificationsSetting {
                self.tableView.reloadData()
            }
        }
    }

    func setupNotifs() {
        EnablePushNotificationSetting(checkOnlyOnceFlag: false) { success in
            if success {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }

    @objc func switchpnMentions(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.pnMentions = true
            UserDefaults.standard.set(true, forKey: "pnMentions")
            tableView.reloadData()
            setupNotifs()
        } else {
            GlobalStruct.pnMentions = false
            UserDefaults.standard.set(false, forKey: "pnMentions")
            tableView.reloadData()
        }
    }

    @objc func switchpnLikes(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.pnLikes = true
            UserDefaults.standard.set(true, forKey: "pnLikes")
            tableView.reloadData()
            setupNotifs()
        } else {
            GlobalStruct.pnLikes = false
            UserDefaults.standard.set(false, forKey: "pnLikes")
            tableView.reloadData()
        }
    }

    @objc func switchpnReposts(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.pnReposts = true
            UserDefaults.standard.set(true, forKey: "pnReposts")
            tableView.reloadData()
            setupNotifs()
        } else {
            GlobalStruct.pnReposts = false
            UserDefaults.standard.set(false, forKey: "pnReposts")
            tableView.reloadData()
        }
    }

    @objc func switchpnFollows(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.pnFollows = true
            UserDefaults.standard.set(true, forKey: "pnFollows")
            tableView.reloadData()
            setupNotifs()
        } else {
            GlobalStruct.pnFollows = false
            UserDefaults.standard.set(false, forKey: "pnFollows")
            tableView.reloadData()
        }
    }

    @objc func switchpnPolls(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.pnPolls = true
            UserDefaults.standard.set(true, forKey: "pnPolls")
            tableView.reloadData()
            setupNotifs()
        } else {
            GlobalStruct.pnPolls = false
            UserDefaults.standard.set(false, forKey: "pnPolls")
            tableView.reloadData()
        }
    }

    @objc func switchpnStatuses(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.pnStatuses = true
            UserDefaults.standard.set(true, forKey: "pnStatuses")
            tableView.reloadData()
            setupNotifs()
        } else {
            GlobalStruct.pnStatuses = false
            UserDefaults.standard.set(false, forKey: "pnStatuses")
            tableView.reloadData()
        }
    }

    @objc func switchActivityBadges(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.activityBadges = true
            UserDefaults.standard.set(true, forKey: "activityBadges")
        } else {
            GlobalStruct.activityBadges = false
            UserDefaults.standard.set(false, forKey: "activityBadges")
        }
    }

    func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("settings.notifications.footer1", comment: "")
        } else if section == 1 {
            return NSLocalizedString("settings.notifications.footer2", comment: "")
        } else {
            return NSLocalizedString("settings.notifications.footer3", comment: "")
        }
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}
