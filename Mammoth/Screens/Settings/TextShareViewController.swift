//
//  TextShareViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 01/08/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import NaturalLanguage
import UIKit
import Vision

class TextShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let btn0 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var id: String = ""
    var keyHeight: CGFloat = 0

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
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextCell2 {
            addText(cell1.altText.text ?? "")
        }
    }

    @objc func keyboardWillChange(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 4
            keyHeight = CGFloat(keyboardHeight)
        }
    }

    func addText(_: String) {
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextCell2 {
            GlobalStruct.shareAsImageTextCaption = cell1.altText.text ?? ""
            UserDefaults.standard.set(GlobalStruct.shareAsImageTextCaption, forKey: "shareAsImageTextCaption")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
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

            for cell in self.tableView.visibleCells {
                if let cell = cell as? AltTextCell2 {
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

        navigationItem.title = "Caption Text"

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

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
        btn2.accessibilityLabel = "Caption text"
        let moreButton1 = UIBarButtonItem(customView: btn2)
        navigationItem.setRightBarButton(moreButton1, animated: true)

        // set up table
        setupTable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextCell2 {
            cell1.altText.text = GlobalStruct.shareAsImageTextCaption
            cell1.altText.becomeFirstResponder()
        }
    }

    @objc func addTap() {
        triggerHapticImpact(style: .light)
        dismiss(animated: true, completion: nil)
    }

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        dismiss(animated: true, completion: nil)
    }

    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(AltTextCell2.self, forCellReuseIdentifier: "AltTextCell2")
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
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextCell2", for: indexPath) as! AltTextCell2

        cell.altText.placeholder = "Caption text..."
        cell.altText.accessibilityLabel = "Caption text..."
        cell.altText.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        cell.altText.tag = indexPath.section

        cell.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
        cell.selectedBackgroundView = bgColorView
        cell.backgroundColor = .custom.quoteTint
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt _: IndexPath) {}

    @objc func textFieldDidChange(_: UITextField) {
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextCell2 {
            let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
            if cell1.altText.text != "" {
                btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
                btn2.backgroundColor = .custom.baseTint
            } else {
                btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
            }
        }
    }

    func tableView(_: UITableView, titleForFooterInSection _: Int) -> String? {
        return "Add a text caption to posts you're sharing as images."
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}
