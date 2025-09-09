//
//  PollViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 09/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable:next type_body_length
class PollViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let btn0 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var options: [String] = ["", ""]
    var canAdd: Bool = false
    var fromEdit: Bool = false
    var durationMin: Int = 1440 * 60
    var currentOptions: [String] = []
    var pollsMultiple: Bool = false
    var tempOptions: [String] = ["", "", "", ""]

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateToolbar"), object: nil)
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

            for cell in self.tableView.visibleCells {
                if let cell = cell as? SelectionCell {
                    cell.textLabel?.textColor = .custom.mainTextColor
                    cell.backgroundColor = .custom.backgroundTint
                }
                if let cell = cell as? PollCell {
                    cell.backgroundColor = .custom.backgroundTint
                }
            }
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        let closeWindow = UIKeyCommand(input: "w", modifierFlags: [.command], action: #selector(dismissTap))
        closeWindow.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            closeWindow.wantsPriorityOverSystemBehavior = true
        }
        return [closeWindow]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint

        navigationItem.title = NSLocalizedString("composer.poll", comment: "")

        // set up nav bar
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
        let moreButton0 = UIBarButtonItem(customView: btn0)
        navigationItem.setLeftBarButton(moreButton0, animated: true)

        btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn2.layer.cornerRadius = 14
        btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn2.addTarget(self, action: #selector(addTap), for: .touchUpInside)
        btn2.accessibilityLabel = NSLocalizedString("composer.poll", comment: "")
        let moreButton1 = UIBarButtonItem(customView: btn2)
        navigationItem.setRightBarButton(moreButton1, animated: true)

        if fromEdit {
            if let opts = GlobalStruct.newPollPost?[0] as? [String] {
                options = opts
                tempOptions = options
                if tempOptions.count == 2 {
                    tempOptions += ["", ""]
                }
                if tempOptions.count == 3 {
                    tempOptions += [""]
                }
            }
        }

        // set up table
        setupTable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
            cell1.pollItem.becomeFirstResponder()
        }
        if fromEdit {
            updateCharacterCounts()
        }
    }

    func scrollViewDidScroll(_: UIScrollView) {
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
            cell1.pollItem.resignFirstResponder()
        }
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
            cell1.pollItem.resignFirstResponder()
        }
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
            cell1.pollItem.resignFirstResponder()
        }
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
            cell1.pollItem.resignFirstResponder()
        }
    }

    @objc func addTap() {
        if canAdd {
            triggerHapticImpact(style: .light)
            // add poll
            if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                currentOptions.append(cell1.pollItem.text ?? "")
                if let cell2 = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                    currentOptions.append(cell2.pollItem.text ?? "")
                    if let cell3 = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                        currentOptions.append(cell3.pollItem.text ?? "")
                        if let cell4 = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                            currentOptions.append(cell4.pollItem.text ?? "")
                        }
                    }
                }
            }
            GlobalStruct.newPollPost = [currentOptions, durationMin, pollsMultiple, false]
            NotificationCenter.default.post(name: Notification.Name(rawValue: "createToolbar"), object: nil)
            dismiss(animated: true, completion: nil)
        }
    }

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        dismiss(animated: true, completion: nil)
    }

    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(PollCell.self, forCellReuseIdentifier: "PollCell")
        tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.alpha = 1
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        view.addSubview(tableView)
    }

    func numberOfSections(in _: UITableView) -> Int {
        return options.count + 2
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    @objc func switchPollMultiple(_ sender: UISwitch!) {
        if sender.isOn {
            pollsMultiple = true
        } else {
            pollsMultiple = false
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == options.count + 1 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell")
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = NSLocalizedString("composer.poll.multiple", comment: "")
            cell.imageView?.image = UIImage(systemName: "hand.raised")
            cell.detailTextLabel?.text = NSLocalizedString("composer.poll.multiple.footer", comment: "")
            let switchView = UISwitch(frame: .zero)
            if UserDefaults.standard.value(forKey: "pollMultiple") as? Bool != nil {
                if UserDefaults.standard.value(forKey: "pollMultiple") as? Bool == false {
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
            switchView.addTarget(self, action: #selector(switchPollMultiple(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            cell.selectionStyle = .none
            cell.textLabel?.isEnabled = true
            cell.detailTextLabel?.isEnabled = true
            cell.textLabel?.textColor = UIColor.label
            cell.detailTextLabel?.textColor = UIColor.secondaryLabel
            cell.detailTextLabel?.numberOfLines = 0
            if indexPath.section == 0 {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        } else if indexPath.section == options.count {
            // duration cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
            // reuse filters locale
            cell.textLabel?.text = NSLocalizedString("filters.duration", comment: "")
            cell.imageView?.image = UIImage(systemName: "chart.pie")

            if durationMin == 5 * 60 {
                cell.detailTextLabel?.text = NSLocalizedString("duration.expiresAt.5mins", comment: "")
            }
            if durationMin == 15 * 60 {
                cell.detailTextLabel?.text = NSLocalizedString("duration.expiresAt.15mins", comment: "")
            }
            if durationMin == 30 * 60 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.halfHour", comment: "")
            }
            if durationMin == 60 * 60 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.hour", comment: "")
            }
            if durationMin == 360 * 60 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.6hours", comment: "")
            }
            if durationMin == 720 * 60 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.12hours", comment: "")
            }
            if durationMin == 1440 * 60 {
                cell.detailTextLabel?.text = NSLocalizedString("filters.duration.expiresAt.day", comment: "")
            }

            let view1 = UIAction(title: NSLocalizedString("duration.expiresAt.5mins", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { _ in
                self.durationMin = 5 * 60
                self.tableView.reloadData()
            }
            view1.accessibilityLabel = NSLocalizedString("duration.expiresAt.5mins", comment: "")
            if durationMin == 5 * 60 {
                view1.state = .on
            }
            let view2 = UIAction(title: NSLocalizedString("duration.expiresAt.15mins", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { _ in
                self.durationMin = 15 * 60
                self.tableView.reloadData()
            }
            view2.accessibilityLabel = NSLocalizedString("duration.expiresAt.15mins", comment: "")
            if durationMin == 15 * 60 {
                view2.state = .on
            }
            let view3 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.halfHour", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { _ in
                self.durationMin = 30 * 60
                self.tableView.reloadData()
            }
            view3.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.halfHour", comment: "")
            if durationMin == 30 * 60 {
                view3.state = .on
            }
            let view4 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.hour", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { _ in
                self.durationMin = 60 * 60
                self.tableView.reloadData()
            }
            view4.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.hour", comment: "")
            if durationMin == 60 * 60 {
                view4.state = .on
            }
            let view5 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.6hours", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { _ in
                self.durationMin = 360 * 60
                self.tableView.reloadData()
            }
            view5.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.6hours", comment: "")
            if durationMin == 360 * 60 {
                view5.state = .on
            }
            let view6 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.12hours", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { _ in
                self.durationMin = 720 * 60
                self.tableView.reloadData()
            }
            view6.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.12hours", comment: "")
            if durationMin == 720 * 60 {
                view6.state = .on
            }
            let view7 = UIAction(title: NSLocalizedString("filters.duration.expiresAt.day", comment: ""), image: UIImage(systemName: "clock"), identifier: nil) { _ in
                self.durationMin = 1440 * 60
                self.tableView.reloadData()
            }
            view7.accessibilityLabel = NSLocalizedString("filters.duration.expiresAt.day", comment: "")
            if durationMin == 1440 * 60 {
                view7.state = .on
            }
            let itemMenu1 = UIMenu(title: "", options: [], children: [view1, view2, view3, view4, view5, view6, view7])
            cell.backgroundButton.menu = itemMenu1

            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        } else {
            // poll items
            let cell = tableView.dequeueReusableCell(withIdentifier: "PollCell", for: indexPath) as! PollCell

            cell.pollItem.text = "\(tempOptions[indexPath.section])"
            cell.pollItem.placeholder = String.localizedStringWithFormat(NSLocalizedString("composer.poll.option", comment: ""), String(indexPath.section + 1))
            cell.pollItem.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("composer.poll.option", comment: ""), String(indexPath.section + 1))
            cell.pollItem.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

            cell.pollItem.tag = indexPath.section
            cell.addButton.tag = indexPath.section

            if indexPath.section == 0 {
                cell.addButton.alpha = 0
            } else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
                cell.addButton.alpha = 1
                if (indexPath.section == options.count - 1) && indexPath.section != 3 {
                    cell.addButton.layer.borderColor = UIColor.custom.baseTint.cgColor
                    cell.addButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(.custom.baseTint, renderingMode: .alwaysOriginal), for: .normal)
                    cell.addButton.removeTarget(self, action: #selector(minusTap(_:)), for: .touchUpInside)
                    cell.addButton.addTarget(self, action: #selector(plusTap(_:)), for: .touchUpInside)
                } else {
                    cell.addButton.layer.borderColor = UIColor.systemRed.cgColor
                    cell.addButton.setImage(UIImage(systemName: "minus.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.systemRed, renderingMode: .alwaysOriginal), for: .normal)
                    cell.addButton.removeTarget(self, action: #selector(plusTap(_:)), for: .touchUpInside)
                    cell.addButton.addTarget(self, action: #selector(minusTap(_:)), for: .touchUpInside)
                }
            }

            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        }
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.tag == 0 {
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                tempOptions[0] = textField.text ?? ""
            }
        }
        if textField.tag == 1 {
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                tempOptions[1] = textField.text ?? ""
            }
        }
        if textField.tag == 2 {
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                tempOptions[2] = textField.text ?? ""
            }
        }
        if textField.tag == 3 {
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                tempOptions[3] = textField.text ?? ""
            }
        }
        updateCharacterCounts()
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
            if let cell2 = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
                if cell1.pollItem.text != "", cell2.pollItem.text != "" {
                    canAdd = true
                    btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
                    btn2.backgroundColor = .custom.active
                } else {
                    canAdd = false
                    btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                    btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
                }
            }
        }
    }

    @objc func plusTap(_: UIButton) {
        triggerHapticImpact(style: .light)
        options.append("")
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
            tempOptions[0] = cell.pollItem.text ?? ""
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
            tempOptions[1] = cell.pollItem.text ?? ""
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
            tempOptions[2] = cell.pollItem.text ?? ""
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
            tempOptions[3] = cell.pollItem.text ?? ""
        }
        tableView.reloadData()
        updateCharacterCounts()
    }

    @objc func minusTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        options.remove(at: sender.tag)
        if sender.tag == 1 {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                tempOptions[0] = cell.pollItem.text ?? ""
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                    tempOptions[1] = cell.pollItem.text ?? ""
                } else {
                    tempOptions[1] = ""
                }
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                    tempOptions[2] = cell.pollItem.text ?? ""
                } else {
                    tempOptions[2] = ""
                }
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                tempOptions[3] = ""
            }
        }
        if sender.tag == 2 {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                tempOptions[0] = cell.pollItem.text ?? ""
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                tempOptions[1] = cell.pollItem.text ?? ""
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                    tempOptions[2] = cell.pollItem.text ?? ""
                } else {
                    tempOptions[2] = ""
                }
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                tempOptions[3] = ""
            }
        }
        if sender.tag == 3 {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PollCell {
                tempOptions[0] = cell.pollItem.text ?? ""
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PollCell {
                tempOptions[1] = cell.pollItem.text ?? ""
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? PollCell {
                tempOptions[2] = cell.pollItem.text ?? ""
            }
            if let _ = tableView.cellForRow(at: IndexPath(row: 0, section: 3)) as? PollCell {
                tempOptions[3] = ""
            }
        }
        tableView.reloadData()
        updateCharacterCounts()
    }

    func updateCharacterCounts() {
        for (c, _) in tempOptions.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: c)) as? PollCell {
                cell.charCount.text = "\(25 - (tempOptions[c].count))"
                if (Int(cell.charCount.text ?? "0") ?? 0) < 0 {
                    cell.charCount.textColor = UIColor.systemRed
                } else {
                    cell.charCount.textColor = .custom.baseTint
                }
            }
        }
    }
}
