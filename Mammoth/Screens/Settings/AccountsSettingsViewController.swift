//
//  AccountsSettingsViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 15/07/2020.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import AuthenticationServices
import UIKit

class AccountsSettingsViewController: UIViewController, ASWebAuthenticationPresentationContextProviding, UITableViewDataSource, UITableViewDelegate {
    var tableView = UITableView()
    let btn2 = UIButton(type: .custom)
    var doneOnce: Bool = false
    var showTestIAP: Bool = false
    var currentInstanceDetails: Instance?

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }

    override func viewDidLayoutSubviews() {
        tableView.frame = CGRect(x: view.safeAreaInsets.left, y: 0, width: view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right, height: view.bounds.height)

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

    @objc func didSwitchAccount() {
        reloadTable()
    }

    func reloadTable() {
        currentInstanceDetails = nil
        reloadAll()
        // Update the footer info
        Task {
            self.currentInstanceDetails = try await InstanceService.instanceDetails()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        navigationItem.title = "Accounts"

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
        NotificationCenter.default.addObserver(self, selector: #selector(didSwitchAccount), name: NSNotification.Name(didSwitchCurrentAccountNotification.rawValue), object: nil)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        btn2.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate), for: .normal)
        btn2.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn2.addTarget(self, action: #selector(newTap), for: .touchUpInside)
        btn2.accessibilityLabel = "Add Account"
        let moreButton = UIBarButtonItem(customView: btn2)
        navigationItem.setRightBarButtonItems([moreButton], animated: true)

        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
        if #available(iOS 15.0, *) {
            self.tableView.allowsFocus = true
        }
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(AccountCell.self, forCellReuseIdentifier: "AccountCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.dragInteractionEnabled = true
        view.addSubview(tableView)
        tableView.reloadData()
        // Update footer as well
        reloadTable()
    }

    @objc func newTap() {
        triggerHapticImpact(style: .light)
        let vc = IntroViewController()
        vc.fromPlus = true
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

//    //MARK: TableView

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return AccountsManager.shared.allAccounts.count
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath) as! AccountCell
        cell.delegate = self

        let allAccounts = AccountsManager.shared.allAccounts
        var acctData: (any AcctDataType)? = nil
        if indexPath.row < allAccounts.count {
            acctData = allAccounts[indexPath.row]
        }
        if let acctData {
            cell.configure(acctData: acctData)
        }

        if allAccounts.count == 0 {
            cell.accessoryType = .none
        } else {
            let currentAccount = AccountsManager.shared.currentAccount
            if acctData?.uniqueID == currentAccount?.uniqueID {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }

        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        DispatchQueue.main.async {
            let allAccounts = AccountsManager.shared.allAccounts
            var acctData: (any AcctDataType)? = nil
            if indexPath.row < allAccounts.count {
                acctData = allAccounts[indexPath.row]
            }
            AccountsManager.shared.switchToAccount(acctData)
        }
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { _ in
            if AccountsManager.shared.currentAccount != nil {
                return self.makeContextMenu(indexPath)
            } else {
                return nil
            }
        })
    }

    func makeContextMenu(_ indexPath: IndexPath) -> UIMenu {
        let logoutAction = UIAction(title: NSLocalizedString("settings.accounts.signOut", comment: ""), image: UIImage(systemName: "xmark"), identifier: nil) { _ in
            let accountToRemove = AccountsManager.shared.allAccounts[indexPath.row]
            AccountsManager.shared.logoutAndDeleteAccount(accountToRemove)
        }
        logoutAction.attributes = .destructive
        return UIMenu(title: "", image: nil, identifier: nil, children: [logoutAction])
    }

    func tableView(_: UITableView, titleForFooterInSection _: Int) -> String? {
        var theMessage: String
        if let currentInstance = currentInstanceDetails {
            let theTitle = "\(currentInstance.domain.stripHTML()) (\(currentInstance.version ?? "1.0.0"))"
            theMessage = theTitle + "\n" + String.localizedStringWithFormat(NSLocalizedString("profile.addAccount.mau", comment: ""), currentInstance.usage.users.activeMonth.formatUsingAbbrevation()) + "\n\n" + currentInstance.description.stripHTML()
        } else {
            theMessage = ""
        }

        var rules = ""
        if let ru = currentInstanceDetails?.rules {
            if ru.isEmpty {} else {
                rules = "\n\n" + NSLocalizedString("profile.addAccount.rules", comment: "") + "\n"
                for (c, x) in ru.enumerated() {
                    rules = "\(rules)\n\(c + 1). \(x.text)"
                }
            }
        }
        return NSLocalizedString("profile.addAccount.message", comment: "") + "\n\n" + theMessage + rules
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension AccountsSettingsViewController: AccountCellDelegate {
    func signOutAccount(_ account: any AcctDataType) {
        let alert = UIAlertController(title: NSLocalizedString("signOut.title", comment: ""), message: NSLocalizedString("signOut.message", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.cancel", comment: ""), style: .cancel, handler: { _ in
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("signOut.option", comment: ""), style: .destructive, handler: { _ in
            AccountsManager.shared.logoutAndDeleteAccount(account)
        }))
        present(alert, animated: true, completion: nil)
    }
}
