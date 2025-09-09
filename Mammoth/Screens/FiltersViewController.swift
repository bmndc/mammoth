//
//  FiltersViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var showingSearch: Bool = true
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    let emptyView = UIImageView()
    var tableView = UITableView()
    var allFilters: [Filters] = []

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        tableView.tableHeaderView?.frame.size.height = 60
        emptyView.center = CGPoint(x: view.center.x, y: view.center.y - 30)
    }

    var tempScrollPosition: CGFloat = 0
    @objc func scrollToTop() {
        if !allFilters.isEmpty {
            // scroll to top
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            tempScrollPosition = tableView.contentOffset.y
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
            for cell in self.tableView.visibleCells {
                if let cell = cell as? TrendsFeedCell {
                    cell.titleLabel.textColor = .custom.mainTextColor
                    cell.backgroundColor = .custom.quoteTint

                    cell.titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                    cell.bio.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize + GlobalStruct.customTextSize, weight: .regular)
                }
                if let cell = cell as? TrendsCell {
                    cell.titleLabel.textColor = .custom.mainTextColor
                    cell.backgroundColor = .custom.quoteTint

                    cell.titleLabel.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
                }
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

    @objc func reloadThis() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarLayout(navigationController: navigationController, userInterfaceStyle: traitCollection.userInterfaceStyle)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint
        navigationItem.title = NSLocalizedString("profile.filters", comment: "")

        NotificationCenter.default.addObserver(self, selector: #selector(reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadThis), name: NSNotification.Name(rawValue: "reloadThis"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchFilters), name: NSNotification.Name(rawValue: "fetchFilters"), object: nil)

        // set up nav
        setupNav()

        setupTable()

        // fetch data
        fetchFilters()
    }

    func setupNav() {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        btn2.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate), for: .normal)
        btn2.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btn2.addTarget(self, action: #selector(newFilter), for: .touchUpInside)
        btn2.accessibilityLabel = NSLocalizedString("filters.new", comment: "")
        let moreButton3 = UIBarButtonItem(customView: btn2)
        navigationItem.setRightBarButtonItems([moreButton3], animated: true)
    }

    @objc func newFilter() {
        triggerHapticImpact(style: .light)
        let vc = FilterDetailsViewController()
        vc.showingSearch = false
        vc.isShowingXmark = true
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    func setupTable() {
        emptyView.bounds.size.width = 80
        emptyView.bounds.size.height = 80
        emptyView.backgroundColor = UIColor.clear
        emptyView.image = UIImage(systemName: "sparkles", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))?.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.18), renderingMode: .alwaysOriginal)
        emptyView.alpha = 0
        tableView.addSubview(emptyView)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.register(TrendsFeedCell.self, forCellReuseIdentifier: "TrendsFeedCell")
        tableView.register(TrendsCell.self, forCellReuseIdentifier: "TrendsCell")
        tableView.register(TrendsTopCell.self, forCellReuseIdentifier: "TrendsTopCell")
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

    @objc func fetchFilters() {
        let request0 = FilterPosts.all()
        AccountsManager.shared.currentAccountClient.run(request0) { statuses in
            if let error = statuses.error {
                log.error("Failed to fetch filters: \(error)")
                DispatchQueue.main.async {
                    if self.allFilters.isEmpty {
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
                DispatchQueue.main.async {
                    self.allFilters = stat
                    self.tableView.reloadData()
                    self.saveToDisk()

                    if let filt = stat.first(where: { f in
                        f.id == GlobalStruct.currentFilterId
                    }) {
                        GlobalStruct.currentFilter = filt
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilterAgain"), object: nil)
                    }
                }
            }
        }
    }

    func saveToDisk() {}

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return allFilters.count
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCell", for: indexPath) as! TrendsCell
        var keyW = ""
        for (c, x) in allFilters[indexPath.row].keywords.enumerated() {
            let aa = x.keyword.lowercased()
            if c == 0 {
                keyW = "\(aa)"
            } else {
                keyW = "\(keyW), \(aa)"
            }
        }
        var filt = ""
        for (c, x) in allFilters[indexPath.row].context.enumerated() {
            let aa = x.capitalized.replacingOccurrences(of: "Home", with: NSLocalizedString("filters.extras.homeAndLists", comment: "")).replacingOccurrences(of: "Public", with: "Public Timelines").replacingOccurrences(of: "Thread", with: NSLocalizedString("filters.extras.conversations", comment: "")).replacingOccurrences(of: "Account", with: NSLocalizedString("filters.extras.profiles", comment: ""))
            if c == 0 {
                filt = "\(aa)"
            } else if c == allFilters[indexPath.row].context.count - 1 {
                filt = "\(filt), and \(aa)"
            } else {
                filt = "\(filt), \(aa)"
            }
        }
        if keyW == "" {
            keyW = "Not filtering any keywords\n\(filt)"
        } else {
            keyW = "Filtering: \(keyW)\n\(filt)"
        }
        cell.configure(allFilters[indexPath.row].title, titleLabel2: "\(keyW)")
        cell.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
        cell.selectedBackgroundView = bgColorView
        cell.backgroundColor = .custom.backgroundTint
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        GlobalStruct.currentFilterId = allFilters[indexPath.row].id
        let vc = FilterDetailsViewController()
        vc.showingSearch = false
        vc.filter = allFilters[indexPath.row]
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { _ in
            self.makeContextMenu(indexPath.row)
        })
    }

    func makeContextMenu(_ index: Int) -> UIMenu {
        let op1 = UIAction(title: "Delete Filter", image: UIImage(systemName: "trash"), identifier: nil) { _ in
            let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this filter?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                let request = FilterPosts.delete(id: self.allFilters[index].id)
                AccountsManager.shared.currentAccountClient.run(request) { statuses in
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            print("deleted filter")
                            triggerHapticNotification()
                            self.fetchFilters()
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel, handler: { _ in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
        op1.accessibilityLabel = "Delete Filter"
        op1.attributes = .destructive
        return UIMenu(title: "", options: [], children: [op1])
    }

    func tableView(_ tableView: UITableView, canEditRowAt _: IndexPath) -> Bool {
        if tableView == self.tableView {
            return true
        } else {
            return false
        }
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this filter?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                let request = FilterPosts.delete(id: self.allFilters[indexPath.row].id)
                AccountsManager.shared.currentAccountClient.run(request) { statuses in
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            print("deleted filter")
                            triggerHapticNotification()
                            self.fetchFilters()
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel, handler: { _ in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
    }
}

extension FiltersViewController: JumpToNewest {
    @objc func jumpToNewest() {
        scrollToTop()
        fetchFilters()
    }
}
