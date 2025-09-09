//
//  AlertsSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 29/07/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable:next type_body_length
class AlertsSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIColorPickerViewControllerDelegate {
    var tableView = UITableView()
    var section0: [String] = ["Post Sent", "Post Deleted", "User Actions", "List Actions", "Other Actions"]

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
        navigationItem.title = "Pop-Up Alerts"

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell2")
        tableView.alpha = 1
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)
    }

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        dismiss(animated: true, completion: nil)
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return section0.count
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupPostPosted") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupPostPosted") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(switch1(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupPostDeleted") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupPostDeleted") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(switch2(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupUserActions") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupUserActions") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(switch3(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupListActions") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupListActions") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(switch4(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else if indexPath.row == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupBookmarkActions") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupBookmarkActions") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(switch5(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell2", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "\(section0[indexPath.row])"
            cell.imageView?.image = UIImage(systemName: "exclamationmark.circle")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "popupRateLimits") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "popupRateLimits") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(switch6(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        }
    }

    @objc func switch1(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupPostPosted = true
            UserDefaults.standard.set(true, forKey: "popupPostPosted")
            tableView.reloadData()
        } else {
            GlobalStruct.popupPostPosted = false
            UserDefaults.standard.set(false, forKey: "popupPostPosted")
            tableView.reloadData()
        }
    }

    @objc func switch2(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupPostDeleted = true
            UserDefaults.standard.set(true, forKey: "popupPostDeleted")
            tableView.reloadData()
        } else {
            GlobalStruct.popupPostDeleted = false
            UserDefaults.standard.set(false, forKey: "popupPostDeleted")
            tableView.reloadData()
        }
    }

    @objc func switch3(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupUserActions = true
            UserDefaults.standard.set(true, forKey: "popupUserActions")
            tableView.reloadData()
        } else {
            GlobalStruct.popupUserActions = false
            UserDefaults.standard.set(false, forKey: "popupUserActions")
            tableView.reloadData()
        }
    }

    @objc func switch4(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupListActions = true
            UserDefaults.standard.set(true, forKey: "popupListActions")
            tableView.reloadData()
        } else {
            GlobalStruct.popupListActions = false
            UserDefaults.standard.set(false, forKey: "popupListActions")
            tableView.reloadData()
        }
    }

    @objc func switch5(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupBookmarkActions = true
            UserDefaults.standard.set(true, forKey: "popupBookmarkActions")
            tableView.reloadData()
        } else {
            GlobalStruct.popupBookmarkActions = false
            UserDefaults.standard.set(false, forKey: "popupBookmarkActions")
            tableView.reloadData()
        }
    }

    @objc func switch6(_ sender: UISwitch!) {
        if sender.isOn {
            GlobalStruct.popupRateLimits = true
            UserDefaults.standard.set(true, forKey: "popupRateLimits")
            tableView.reloadData()
        } else {
            GlobalStruct.popupRateLimits = false
            UserDefaults.standard.set(false, forKey: "popupRateLimits")
            tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_: UITableView, titleForFooterInSection _: Int) -> String? {
        return "Choose which pop-up alerts to display."
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}
