//
//  OpenLinksSettingsViewController.swift
//  Mammoth
//
//  Created by Kern Jackson on 6/27/24
//  Copyright © 2024 The BLVD. All rights reserved.
//

import UIKit

protocol OpenLinksSettingsViewDelegate: AnyObject {
    func didChangeBrowserSettings()
}

class OpenLinksSettingsViewController: UITableViewController {
    weak var delegate: OpenLinksSettingsViewDelegate?
    var browsers: [String] = []
    let userDefaultsKey = "PreferredBrowser"

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint

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

        browsers.append(contentsOf: LinkOpener.checkInstalledBrowsers())

        title = NSLocalizedString("settings.openLinks", comment: "")
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .custom.backgroundTint
        tableView.layer.masksToBounds = true
        tableView.rowHeight = UITableView.automaticDimension

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return browsers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = browsers[indexPath.row]

        let preferredBrowser = GlobalStruct.preferredBrowser
        if browsers[indexPath.row] == preferredBrowser {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        let bgColorView = UIView()
        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.14)
        cell.selectedBackgroundView = bgColorView
        cell.backgroundColor = .custom.OVRLYSoftContrast
        if #available(iOS 15.0, *) {
            cell.focusEffect = UIFocusHaloEffect()
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBrowser = browsers[indexPath.row]
        UserDefaults.standard.set(selectedBrowser, forKey: userDefaultsKey.value)
        GlobalStruct.preferredBrowser = selectedBrowser
        tableView.reloadData()
        delegate?.didChangeBrowserSettings()
    }

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }
}
