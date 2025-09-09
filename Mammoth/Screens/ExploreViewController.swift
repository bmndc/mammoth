//
//  ExploreViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 03/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

// swiftlint:disable:next type_body_length
class ExploreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIContextMenuInteractionDelegate {
    var currentUserID: String?
    var client: Client?
    var showingSearch: Bool = true
    let btn1 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var allLinks: [Card] = []
    var allLinksNeedsSave = true
    var allTrends: [Tag] = []
    var allTags: [Tag] = []
    var acc: [Account] = []
    var otherInstance: String = ""
    var fromOtherCommunity: Bool = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.reloadData()
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        tableView.tableHeaderView?.frame.size.height = 60

        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async {
            UIView.setAnimationsEnabled(false)
            self.tableView.reloadData()
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TrendsTopCell {
                cell.setupPostWithoutDots(self.allLinks)
            }
            UIView.setAnimationsEnabled(true)
        }
    }

    var tempScrollPosition: CGFloat = 0
    @objc func scrollToTop() {
        DispatchQueue.main.async {
            if !self.allTrends.isEmpty {
                // scroll to top
                if self.tableView.numberOfRows(inSection: 0) > 0 {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    self.tempScrollPosition = self.tableView.contentOffset.y
                }
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

    @objc func fetchPad() {
        fetchAllTrendData()
    }

    @objc func reloadThis() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @objc func reloadThisExplore() {
        DispatchQueue.main.async {
            self.fetchVIPMembers()
        }
    }

    @objc func updateClient() {
        if UIDevice.current.userInterfaceIdiom != .phone {
            currentUserID = AccountsManager.shared.currentUser()?.id
            client = AccountsManager.shared.currentAccountClient
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        currentUserID = AccountsManager.shared.currentUser()?.id
        client = AccountsManager.shared.currentAccountClient

        view.backgroundColor = .custom.backgroundTint
        navigationItem.title = NSLocalizedString("title.explore", comment: "")

        NotificationCenter.default.addObserver(self, selector: #selector(updateClient), name: NSNotification.Name(rawValue: "updateClient"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadThis), name: NSNotification.Name(rawValue: "reloadThis"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadThisExplore), name: NSNotification.Name(rawValue: "reloadThisExplore"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTrendHeader), name: NSNotification.Name(rawValue: "reloadTrendHeader"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadBars), name: NSNotification.Name(rawValue: "reloadBars"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchPad), name: NSNotification.Name(rawValue: "fetchPad"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchFollowingTags), name: NSNotification.Name(rawValue: "fetchFollowingTags"), object: nil)

        // set up nav bar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp

        // set up nav
        setupNav()

        // set up table
        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
        setupTable()

        // fetch data
        if !fromOtherCommunity {
            restoreAll()
        }
        if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {
            fetchTrendingLinks()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.fetchTrendingLinks()
            }
        }
        fetchAllTrendData()
        fetchFollowingTags()
        fetchVIPMembers()
    }

    func fetchVIPMembers() {
        let request2 = Lists.accounts(id: GlobalStruct.VIPListID)
        client!.run(request2) { statuses in
            if let error = statuses.error {
                log.error("Failed to fetch list accounts: \(error)")
                DispatchQueue.main.async {
                    do {
                        if let x = self.currentUserID {
                            GlobalStruct.topAccounts = try Disk.retrieve("\(x)/topAccounts2.json", from: .documents, as: [Account].self)
                            self.tableView.reloadData()
                        }
                    } catch {
                        log.error("error fetching top accounts from Disk - \(error)")
                        GlobalStruct.topAccounts = []
                        self.tableView.reloadData()
                    }
                }
            }
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    GlobalStruct.topAccounts = stat
                    self.tableView.reloadData()
                    if let x = self.currentUserID {
                        do {
                            try Disk.save(GlobalStruct.topAccounts, to: .documents, as: "\(x)/topAccounts2.json")
                        } catch {
                            log.error("error saving top accounts to Disk")
                        }
                    }
                }
            }
        }
    }

    func setupNav() {}

    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.register(TrendsFeedCell.self, forCellReuseIdentifier: "TrendsFeedCell")
        tableView.register(TrendsCell.self, forCellReuseIdentifier: "TrendsCell")
        tableView.register(VIPCell.self, forCellReuseIdentifier: "VIPCell")
        tableView.register(TrendsCellExtra.self, forCellReuseIdentifier: "TrendsCellExtra01")
        tableView.register(TrendsCellExtra.self, forCellReuseIdentifier: "TrendsCellExtra")
        tableView.register(TrendsCellExtra.self, forCellReuseIdentifier: "TrendsCellExtra2")
        tableView.register(TrendsCellExtra.self, forCellReuseIdentifier: "TrendsCellExtra3")
        tableView.register(TrendsCell.self, forCellReuseIdentifier: "TrendsCellList1")
        tableView.register(TrendsCellExtra.self, forCellReuseIdentifier: "TrendsCellList2")
        tableView.register(ProfileFieldsCell.self, forCellReuseIdentifier: "ProfileFieldsCell2")
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

    func fetchTrendingLinks() {
        let request0 = TrendingTags.links()
        var testClient = client!
        if fromOtherCommunity {
            let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
            testClient = Client(
                baseURL: "https://\(otherInstance)",
                accessToken: accessToken
            )
        }
        testClient.run(request0) { statuses in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.allLinks = stat
                    self.allLinksNeedsSave = true
                    self.tableView.reloadData()
                    if !self.fromOtherCommunity {
                        self.saveToDisk()
                    }
                }
            }
        }
    }

    func fetchAllTrendData() {
        let request0 = TrendingTags.trendingTags()
        var testClient = client!
        if fromOtherCommunity {
            let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
            testClient = Client(
                baseURL: "https://\(otherInstance)",
                accessToken: accessToken
            )
        }
        testClient.run(request0) { statuses in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.allTrends = stat
                    self.tableView.reloadData()
                }
            }
        }
    }

    @objc func fetchFollowingTags() {
        let request0 = TrendingTags.followedTags()
        var testClient = client!
        if fromOtherCommunity {
            let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
            testClient = Client(
                baseURL: "https://\(otherInstance)",
                accessToken: accessToken
            )
        }
        testClient.run(request0) { statuses in
            if let stat = (statuses.value) {
                DispatchQueue.main.async {
                    self.allTags = stat
                    self.tableView.reloadData()
                }
            }
        }
    }

    func saveToDisk() {
        log.debug(#function + " - " + String(describing: self))

        if allLinksNeedsSave {
            do {
                if allLinks.isEmpty {} else {
                    log.debug("writing allLinks")
                    try Disk.save(allLinks, to: .documents, as: "\(currentUserID ?? "all")/allLinks.json")
                    allLinksNeedsSave = false
                }
            } catch {
                log.error("error saving links to Disk")
            }
        }
    }

    func restoreAll() {
        do {
            allLinks = try Disk.retrieve("\(currentUserID ?? "all")/allLinks.json", from: .documents, as: [Card].self)
            allLinksNeedsSave = false
            tableView.reloadData()
        } catch {
            log.error("error fetching links from Disk - \(error)")
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        if fromOtherCommunity {
            return 3
        } else {
            if allTags.isEmpty {
                return 4
            } else {
                return 5
            }
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fromOtherCommunity {
            if section == 0 {
                if allLinks.isEmpty {
                    return 0
                } else {
                    return 1
                }
            } else if section == 1 {
                return 1
            } else {
                return allTrends.count
            }
        } else {
            if allTags.isEmpty {
                if section == 0 {
                    if allLinks.isEmpty {
                        return 0
                    } else {
                        return 1
                    }
                } else if section == 1 {
                    if fromOtherCommunity {
                        return 0
                    } else {
                        return 5
                    }
                } else if section == 2 {
                    if fromOtherCommunity {
                        return 0
                    } else {
                        return 1 + ListManager.shared.allLists(includeTopFriends: false).count
                    }
                } else {
                    return allTrends.count
                }
            } else {
                if section == 0 {
                    if allLinks.isEmpty {
                        return 0
                    } else {
                        return 1
                    }
                } else if section == 1 {
                    if fromOtherCommunity {
                        return 0
                    } else {
                        return 5
                    }
                } else if section == 2 {
                    if fromOtherCommunity {
                        return 0
                    } else {
                        return 1 + ListManager.shared.allLists(includeTopFriends: false).count
                    }
                } else if section == 3 {
                    if fromOtherCommunity {
                        return 0
                    } else {
                        return allTags.count
                    }
                } else {
                    return allTrends.count
                }
            }
        }
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 230
        } else {
            if indexPath.section == 1 && indexPath.row == 0 {
                return UITableView.automaticDimension
            } else {
                return UITableView.automaticDimension
            }
        }
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if allLinks.isEmpty {
                return 0
            } else {
                return UITableView.automaticDimension
            }
        } else {
            return 52
        }
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        } else if section == 1 {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame

            lab.attributedText = NSAttributedString(string: NSLocalizedString("title.explore", comment: ""))

            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        } else if section == 2 {
            if fromOtherCommunity {
                let bg = UIView()
                bg.frame = CGRect(x: 0, y: 6, width: view.bounds.width, height: 40)
                let lab = UILabel()
                lab.frame = bg.frame

                lab.attributedText = NSAttributedString(string: NSLocalizedString("explore.trendingTags", comment: ""))

                lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
                lab.textColor = UIColor.label
                bg.addSubview(lab)
                return bg
            } else {
                let bg = UIView()
                bg.frame = CGRect(x: 0, y: 6, width: view.bounds.width, height: 40)
                let lab = UILabel()
                lab.frame = bg.frame

                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
                let fullString = NSMutableAttributedString(string: "")
                let image1Attachment = NSTextAttachment()
                image1Attachment.image = UIImage(systemName: "list.bullet.circle.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate)
                let image1String = NSAttributedString(attachment: image1Attachment)
                fullString.append(image1String)
                fullString.append(NSAttributedString(string: "  " + NSLocalizedString("explore.lists", comment: "")))
                lab.attributedText = fullString

                lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
                lab.textColor = UIColor.label
                bg.addSubview(lab)
                return bg
            }
        } else if section == 3 {
            if allTags.isEmpty {
                let bg = UIView()
                bg.frame = CGRect(x: 0, y: 6, width: view.bounds.width, height: 40)
                let lab = UILabel()
                lab.frame = bg.frame

                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
                let fullString = NSMutableAttributedString(string: "")
                let image1Attachment = NSTextAttachment()
                image1Attachment.image = UIImage(systemName: "chart.bar.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate)
                let image1String = NSAttributedString(attachment: image1Attachment)
                fullString.append(image1String)
                fullString.append(NSAttributedString(string: "  " + NSLocalizedString("explore.trendingTags", comment: "")))
                lab.attributedText = fullString

                lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
                lab.textColor = UIColor.label
                bg.addSubview(lab)
                return bg
            } else {
                if fromOtherCommunity {
                    return nil
                } else {
                    let bg = UIView()
                    bg.frame = CGRect(x: 0, y: 6, width: view.bounds.width, height: 40)
                    let lab = UILabel()
                    lab.frame = bg.frame

                    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
                    let fullString = NSMutableAttributedString(string: "")
                    let image1Attachment = NSTextAttachment()
                    image1Attachment.image = UIImage(systemName: "number.circle.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate)
                    let image1String = NSAttributedString(attachment: image1Attachment)
                    fullString.append(image1String)
                    fullString.append(NSAttributedString(string: "  " + NSLocalizedString("explore.followedTags", comment: "")))
                    lab.attributedText = fullString

                    lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
                    lab.textColor = UIColor.label
                    bg.addSubview(lab)
                    return bg
                }
            }
        } else {
            let bg = UIView()
            bg.frame = CGRect(x: 0, y: 6, width: view.bounds.width, height: 40)
            let lab = UILabel()
            lab.frame = bg.frame

            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            let fullString = NSMutableAttributedString(string: "")
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = UIImage(systemName: "chart.bar.fill", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate)
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            fullString.append(NSAttributedString(string: "  " + NSLocalizedString("explore.trendingTags", comment: "")))
            lab.attributedText = fullString

            lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lab.textColor = UIColor.label
            bg.addSubview(lab)
            return bg
        }
    }

    @objc func reloadTrendHeader() {
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }

    @objc func profile1tap() {
        triggerHapticImpact(style: .light)
        let vc = ProfileViewController(user: UserCardModel(account: acc[0]), screenType: .others)
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func profile2tap() {
        triggerHapticImpact(style: .light)
        let vc = ProfileViewController(user: UserCardModel(account: acc[1]), screenType: .others)
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func profile3tap() {
        triggerHapticImpact(style: .light)
        let vc = ProfileViewController(user: UserCardModel(account: acc[2]), screenType: .others)
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func profile4tap() {
        triggerHapticImpact(style: .light)
        let vc = ProfileViewController(user: UserCardModel(account: acc[3]), screenType: .others)
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func profile5tap() {
        triggerHapticImpact(style: .light)
        let vc = ProfileViewController(user: UserCardModel(account: acc[4]), screenType: .others)
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func profile6tap() {
        triggerHapticImpact(style: .light)
        let vc = ProfileViewController(user: UserCardModel(account: acc[5]), screenType: .others)
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func profileMoretap() {
        triggerHapticImpact(style: .light)
        if GlobalStruct.displayingVIPLists == 0 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "createVIPListPrompt"), object: nil)
        } else {
            let vc = LikedByMutedBlockedViewController()
            vc.type = 6
            if vc.isBeingPresented {} else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsTopCell", for: indexPath) as! TrendsTopCell
            if fromOtherCommunity {
                GlobalStruct.hasSetupNewsDots = false
                cell.setupPost(allLinks)
            } else {
                if GlobalStruct.hasSetupNewsDots == false {
                    GlobalStruct.hasSetupNewsDots = true
                    cell.setupPost(allLinks)
                }
            }
            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        } else if indexPath.section == 1 {
            if fromOtherCommunity {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCellExtra3", for: indexPath) as! TrendsCellExtra
                cell.configure(NSLocalizedString("explore.trendingPosts", comment: ""))
                cell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                cell.accessoryType = .disclosureIndicator
                return cell
            } else {
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "VIPCell", for: indexPath) as! VIPCell
                    if fromOtherCommunity {
                    } else {
                        cell.titleText.text = "Top Friends"
                        cell.valueText.text = "Posts from your inner circle"

                        acc = Array(GlobalStruct.topAccounts.reversed())

                        cell.profile1.removeTarget(self, action: #selector(profile1tap), for: .touchUpInside)
                        cell.profile1.removeTarget(self, action: #selector(profileMoretap), for: .touchUpInside)

                        if acc.count > 5 {
                            cell.profile6.alpha = 1
                            cell.profile6.isUserInteractionEnabled = true
                            cell.profile5.alpha = 1
                            cell.profile5.isUserInteractionEnabled = true
                            cell.profile4.alpha = 1
                            cell.profile4.isUserInteractionEnabled = true
                            cell.profile3.alpha = 1
                            cell.profile3.isUserInteractionEnabled = true
                            cell.profile2.alpha = 1
                            cell.profile2.isUserInteractionEnabled = true

                            if let profileURL = URL(string: acc[0].avatar) {
                                cell.profile1.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile1.addTarget(self, action: #selector(profile1tap), for: .touchUpInside)

                                let interaction1 = UIContextMenuInteraction(delegate: self)
                                cell.profile1.addInteraction(interaction1)
                                cell.profile1.tag = indexPath.row + 100_000
                            }
                            if let profileURL = URL(string: acc[1].avatar) {
                                cell.profile2.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile2.addTarget(self, action: #selector(profile2tap), for: .touchUpInside)

                                let interaction2 = UIContextMenuInteraction(delegate: self)
                                cell.profile2.addInteraction(interaction2)
                                cell.profile2.tag = indexPath.row + 200_000
                            }
                            if let profileURL = URL(string: acc[2].avatar) {
                                cell.profile3.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile3.addTarget(self, action: #selector(profile3tap), for: .touchUpInside)

                                let interaction3 = UIContextMenuInteraction(delegate: self)
                                cell.profile3.addInteraction(interaction3)
                                cell.profile3.tag = indexPath.row + 300_000
                            }
                            if let profileURL = URL(string: acc[3].avatar) {
                                cell.profile4.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile4.addTarget(self, action: #selector(profile4tap), for: .touchUpInside)

                                let interaction4 = UIContextMenuInteraction(delegate: self)
                                cell.profile4.addInteraction(interaction4)
                                cell.profile4.tag = indexPath.row + 400_000
                            }
                            if let profileURL = URL(string: acc[4].avatar) {
                                cell.profile5.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile5.addTarget(self, action: #selector(profile5tap), for: .touchUpInside)

                                let interaction5 = UIContextMenuInteraction(delegate: self)
                                cell.profile5.addInteraction(interaction5)
                                cell.profile5.tag = indexPath.row + 500_000
                            }
                            if let profileURL = URL(string: acc[5].avatar) {
                                cell.profile6.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile6.addTarget(self, action: #selector(profile6tap), for: .touchUpInside)
                                cell.profile6.alpha = 1
                                cell.profile6.isUserInteractionEnabled = true

                                let interaction6 = UIContextMenuInteraction(delegate: self)
                                cell.profile6.addInteraction(interaction6)
                                cell.profile6.tag = indexPath.row + 600_000

                                cell.profileMore.alpha = 1
                                cell.profileMore.addTarget(self, action: #selector(profileMoretap), for: .touchUpInside)
                                cell.profileMore.isUserInteractionEnabled = true
                            }
                        } else if acc.count > 4 {
                            cell.profile6.alpha = 0
                            cell.profile6.setImage(UIImage(), for: .normal)
                            cell.profile6.isUserInteractionEnabled = false

                            cell.profile5.alpha = 1
                            cell.profile5.isUserInteractionEnabled = true
                            cell.profile4.alpha = 1
                            cell.profile4.isUserInteractionEnabled = true
                            cell.profile3.alpha = 1
                            cell.profile3.isUserInteractionEnabled = true
                            cell.profile2.alpha = 1
                            cell.profile2.isUserInteractionEnabled = true

                            cell.profileMore.alpha = 0
                            cell.profileMore.isUserInteractionEnabled = false

                            if let profileURL = URL(string: acc[0].avatar) {
                                cell.profile1.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile1.addTarget(self, action: #selector(profile1tap), for: .touchUpInside)

                                let interaction1 = UIContextMenuInteraction(delegate: self)
                                cell.profile1.addInteraction(interaction1)
                                cell.profile1.tag = indexPath.row + 100_000
                            }
                            if let profileURL = URL(string: acc[1].avatar) {
                                cell.profile2.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile2.addTarget(self, action: #selector(profile2tap), for: .touchUpInside)

                                let interaction2 = UIContextMenuInteraction(delegate: self)
                                cell.profile2.addInteraction(interaction2)
                                cell.profile2.tag = indexPath.row + 200_000
                            }
                            if let profileURL = URL(string: acc[2].avatar) {
                                cell.profile3.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile3.addTarget(self, action: #selector(profile3tap), for: .touchUpInside)

                                let interaction3 = UIContextMenuInteraction(delegate: self)
                                cell.profile3.addInteraction(interaction3)
                                cell.profile3.tag = indexPath.row + 300_000
                            }
                            if let profileURL = URL(string: acc[3].avatar) {
                                cell.profile4.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile4.addTarget(self, action: #selector(profile4tap), for: .touchUpInside)

                                let interaction4 = UIContextMenuInteraction(delegate: self)
                                cell.profile4.addInteraction(interaction4)
                                cell.profile4.tag = indexPath.row + 400_000
                            }
                            if let profileURL = URL(string: acc[4].avatar) {
                                cell.profile5.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile5.addTarget(self, action: #selector(profile5tap), for: .touchUpInside)

                                let interaction5 = UIContextMenuInteraction(delegate: self)
                                cell.profile5.addInteraction(interaction5)
                                cell.profile5.tag = indexPath.row + 500_000
                            }
                        } else if acc.count > 3 {
                            cell.profile6.alpha = 0
                            cell.profile6.setImage(UIImage(), for: .normal)
                            cell.profile6.isUserInteractionEnabled = false

                            cell.profile5.alpha = 0
                            cell.profile5.setImage(UIImage(), for: .normal)
                            cell.profile5.isUserInteractionEnabled = false

                            cell.profile4.alpha = 1
                            cell.profile4.isUserInteractionEnabled = true
                            cell.profile3.alpha = 1
                            cell.profile3.isUserInteractionEnabled = true
                            cell.profile2.alpha = 1
                            cell.profile2.isUserInteractionEnabled = true

                            cell.profileMore.alpha = 0
                            cell.profileMore.isUserInteractionEnabled = false

                            if let profileURL = URL(string: acc[0].avatar) {
                                cell.profile1.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile1.addTarget(self, action: #selector(profile1tap), for: .touchUpInside)

                                let interaction1 = UIContextMenuInteraction(delegate: self)
                                cell.profile1.addInteraction(interaction1)
                                cell.profile1.tag = indexPath.row + 100_000
                            }
                            if let profileURL = URL(string: acc[1].avatar) {
                                cell.profile2.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile2.addTarget(self, action: #selector(profile2tap), for: .touchUpInside)

                                let interaction2 = UIContextMenuInteraction(delegate: self)
                                cell.profile2.addInteraction(interaction2)
                                cell.profile2.tag = indexPath.row + 200_000
                            }
                            if let profileURL = URL(string: acc[2].avatar) {
                                cell.profile3.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile3.addTarget(self, action: #selector(profile3tap), for: .touchUpInside)

                                let interaction3 = UIContextMenuInteraction(delegate: self)
                                cell.profile3.addInteraction(interaction3)
                                cell.profile3.tag = indexPath.row + 300_000
                            }
                            if let profileURL = URL(string: acc[3].avatar) {
                                cell.profile4.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile4.addTarget(self, action: #selector(profile4tap), for: .touchUpInside)

                                let interaction4 = UIContextMenuInteraction(delegate: self)
                                cell.profile4.addInteraction(interaction4)
                                cell.profile4.tag = indexPath.row + 400_000
                            }
                        } else if acc.count > 2 {
                            cell.profile6.alpha = 0
                            cell.profile6.setImage(UIImage(), for: .normal)
                            cell.profile6.isUserInteractionEnabled = false

                            cell.profile5.alpha = 0
                            cell.profile5.setImage(UIImage(), for: .normal)
                            cell.profile5.isUserInteractionEnabled = false

                            cell.profile4.alpha = 0
                            cell.profile4.setImage(UIImage(), for: .normal)
                            cell.profile4.isUserInteractionEnabled = false

                            cell.profile3.alpha = 1
                            cell.profile3.isUserInteractionEnabled = true
                            cell.profile2.alpha = 1
                            cell.profile2.isUserInteractionEnabled = true

                            cell.profileMore.alpha = 0
                            cell.profileMore.isUserInteractionEnabled = false

                            if let profileURL = URL(string: acc[0].avatar) {
                                cell.profile1.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile1.addTarget(self, action: #selector(profile1tap), for: .touchUpInside)

                                let interaction1 = UIContextMenuInteraction(delegate: self)
                                cell.profile1.addInteraction(interaction1)
                                cell.profile1.tag = indexPath.row + 100_000
                            }
                            if let profileURL = URL(string: acc[1].avatar) {
                                cell.profile2.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile2.addTarget(self, action: #selector(profile2tap), for: .touchUpInside)

                                let interaction2 = UIContextMenuInteraction(delegate: self)
                                cell.profile2.addInteraction(interaction2)
                                cell.profile2.tag = indexPath.row + 200_000
                            }
                            if let profileURL = URL(string: acc[2].avatar) {
                                cell.profile3.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile3.addTarget(self, action: #selector(profile3tap), for: .touchUpInside)

                                let interaction3 = UIContextMenuInteraction(delegate: self)
                                cell.profile3.addInteraction(interaction3)
                                cell.profile3.tag = indexPath.row + 300_000
                            }
                        } else if acc.count > 1 {
                            cell.profile6.alpha = 0
                            cell.profile6.setImage(UIImage(), for: .normal)
                            cell.profile6.isUserInteractionEnabled = false

                            cell.profile5.alpha = 0
                            cell.profile5.setImage(UIImage(), for: .normal)
                            cell.profile5.isUserInteractionEnabled = false

                            cell.profile4.alpha = 0
                            cell.profile4.setImage(UIImage(), for: .normal)
                            cell.profile4.isUserInteractionEnabled = false

                            cell.profile3.alpha = 0
                            cell.profile3.setImage(UIImage(), for: .normal)
                            cell.profile3.isUserInteractionEnabled = false

                            cell.profile2.alpha = 1
                            cell.profile2.isUserInteractionEnabled = true

                            cell.profileMore.alpha = 0
                            cell.profileMore.isUserInteractionEnabled = false

                            if let profileURL = URL(string: acc[0].avatar) {
                                cell.profile1.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile1.addTarget(self, action: #selector(profile1tap), for: .touchUpInside)

                                let interaction1 = UIContextMenuInteraction(delegate: self)
                                cell.profile1.addInteraction(interaction1)
                                cell.profile1.tag = indexPath.row + 100_000
                            }
                            if let profileURL = URL(string: acc[1].avatar) {
                                cell.profile2.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile2.addTarget(self, action: #selector(profile2tap), for: .touchUpInside)

                                let interaction2 = UIContextMenuInteraction(delegate: self)
                                cell.profile2.addInteraction(interaction2)
                                cell.profile2.tag = indexPath.row + 200_000
                            }
                        } else if acc.count > 0 {
                            cell.profile6.alpha = 0
                            cell.profile6.setImage(UIImage(), for: .normal)
                            cell.profile6.isUserInteractionEnabled = false

                            cell.profile5.alpha = 0
                            cell.profile5.setImage(UIImage(), for: .normal)
                            cell.profile5.isUserInteractionEnabled = false

                            cell.profile4.alpha = 0
                            cell.profile4.setImage(UIImage(), for: .normal)
                            cell.profile4.isUserInteractionEnabled = false

                            cell.profile3.alpha = 0
                            cell.profile3.setImage(UIImage(), for: .normal)
                            cell.profile3.isUserInteractionEnabled = false

                            cell.profile2.alpha = 0
                            cell.profile2.setImage(UIImage(), for: .normal)
                            cell.profile2.isUserInteractionEnabled = false

                            cell.profileMore.alpha = 0
                            cell.profileMore.isUserInteractionEnabled = false

                            if let profileURL = URL(string: acc[0].avatar) {
                                cell.profile1.sd_setImage(with: profileURL, for: .normal, completed: nil)
                                cell.profile1.addTarget(self, action: #selector(profile1tap), for: .touchUpInside)

                                let interaction1 = UIContextMenuInteraction(delegate: self)
                                cell.profile1.addInteraction(interaction1)
                                cell.profile1.tag = indexPath.row + 100_000
                            }
                        } else {
                            cell.profile6.alpha = 0
                            cell.profile6.setImage(UIImage(), for: .normal)
                            cell.profile6.isUserInteractionEnabled = false

                            cell.profile5.alpha = 0
                            cell.profile5.setImage(UIImage(), for: .normal)
                            cell.profile5.isUserInteractionEnabled = false

                            cell.profile4.alpha = 0
                            cell.profile4.setImage(UIImage(), for: .normal)
                            cell.profile4.isUserInteractionEnabled = false

                            cell.profile3.alpha = 0
                            cell.profile3.setImage(UIImage(), for: .normal)
                            cell.profile3.isUserInteractionEnabled = false

                            cell.profile2.alpha = 0
                            cell.profile2.setImage(UIImage(), for: .normal)
                            cell.profile2.isUserInteractionEnabled = false

                            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
                            cell.profile1.setImage(UIImage(systemName: "plus", withConfiguration: symbolConfig)?.withTintColor(.custom.baseTint, renderingMode: .alwaysTemplate), for: .normal)
                            cell.profile1.backgroundColor = .custom.backgroundTint

                            cell.profile1.addTarget(self, action: #selector(profileMoretap), for: .touchUpInside)

                            cell.profileMore.alpha = 0
                            cell.profileMore.isUserInteractionEnabled = false
                        }
                    }

                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    cell.accessoryType = .disclosureIndicator
                    return cell
                } else if indexPath.row == 1 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCellExtra3", for: indexPath) as! TrendsCellExtra
                    cell.configure(NSLocalizedString("explore.trendingPosts", comment: ""))
                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    cell.accessoryType = .disclosureIndicator
                    return cell
                } else if indexPath.row == 2 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCellExtra01", for: indexPath) as! TrendsCellExtra
                    cell.configure(NSLocalizedString("explore.followSuggestions", comment: ""))
                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    cell.accessoryType = .disclosureIndicator
                    return cell
                } else if indexPath.row == 3 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCellExtra", for: indexPath) as! TrendsCellExtra
                    cell.configure(NSLocalizedString("explore.profileDirectory", comment: ""))
                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    cell.accessoryType = .disclosureIndicator
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCellExtra2", for: indexPath) as! TrendsCellExtra
                    cell.configure(NSLocalizedString("explore.browseCommunities", comment: ""))
                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    cell.accessoryType = .disclosureIndicator
                    return cell
                }
            }
        } else if indexPath.section == 2 {
            if fromOtherCommunity {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCell", for: indexPath) as! TrendsCell
                var talkingAbout = 0
                _ = allTrends[indexPath.row].history?.map { x in
                    talkingAbout += Int(x.accounts) ?? 0
                }
                cell.titleLabel.text = "#\(allTrends[indexPath.row].name)"

                let attachment1 = NSTextAttachment()
                let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
                let downImage1 = UIImage(systemName: "megaphone.fill", withConfiguration: symbolConfig1) ?? UIImage()
                attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
                let attStringNewLine000 = NSMutableAttributedString()
                var talkingAboutText = " " + String.localizedStringWithFormat(NSLocalizedString("explore.people", comment: ""), talkingAbout.withCommas())
                if talkingAbout <= 10 {
                    talkingAboutText = " " + NSLocalizedString("explore.somePeople", comment: "")
                }
                let attStringNewLine00 = NSMutableAttributedString(string: talkingAboutText, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
                let attString00 = NSAttributedString(attachment: attachment1)
                attStringNewLine000.append(attString00)
                attStringNewLine000.append(attStringNewLine00)
                cell.titleLabel2.attributedText = attStringNewLine000

                cell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                cell.accessoryType = .disclosureIndicator
                return cell
            } else {
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCellList1", for: indexPath) as! TrendsCell
                    cell.configure("New List", titleLabel2: "Tap to create a new list")
                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    cell.accessoryType = .none
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCellList2", for: indexPath) as! TrendsCellExtra
                    cell.configure(ListManager.shared.allLists(includeTopFriends: false)[indexPath.row - 1].title)
                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    cell.accessoryType = .disclosureIndicator
                    return cell
                }
            }
        } else if indexPath.section == 3 {
            if allTags.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCell", for: indexPath) as! TrendsCell
                var talkingAbout = 0
                _ = allTrends[indexPath.row].history?.map { x in
                    talkingAbout += Int(x.accounts) ?? 0
                }
                cell.titleLabel.text = "#\(allTrends[indexPath.row].name)"

                let attachment1 = NSTextAttachment()
                let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
                let downImage1 = UIImage(systemName: "megaphone.fill", withConfiguration: symbolConfig1) ?? UIImage()
                attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
                let attStringNewLine000 = NSMutableAttributedString()
                var talkingAboutText = " " + String.localizedStringWithFormat(NSLocalizedString("explore.people", comment: ""), talkingAbout.withCommas())
                if talkingAbout <= 10 {
                    talkingAboutText = " " + NSLocalizedString("explore.somePeople", comment: "")
                }
                let attStringNewLine00 = NSMutableAttributedString(string: talkingAboutText, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
                let attString00 = NSAttributedString(attachment: attachment1)
                attStringNewLine000.append(attString00)
                attStringNewLine000.append(attStringNewLine00)
                cell.titleLabel2.attributedText = attStringNewLine000

                cell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                cell.accessoryType = .disclosureIndicator
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileFieldsCell2", for: indexPath) as! ProfileFieldsCell
                cell.title.text = "#\(allTags[indexPath.row].name)"
                cell.title.isUserInteractionEnabled = false

                cell.accessoryType = .disclosureIndicator
                cell.backgroundColor = .custom.quoteTint
                cell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                cell.selectedBackgroundView = bgColorView
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TrendsCell", for: indexPath) as! TrendsCell
            var talkingAbout = 0
            _ = allTrends[indexPath.row].history?.map { x in
                talkingAbout += Int(x.accounts) ?? 0
            }
            cell.titleLabel.text = "#\(allTrends[indexPath.row].name)"

            let attachment1 = NSTextAttachment()
            let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .semibold)
            let downImage1 = UIImage(systemName: "megaphone.fill", withConfiguration: symbolConfig1) ?? UIImage()
            attachment1.image = downImage1.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
            let attStringNewLine000 = NSMutableAttributedString()
            var talkingAboutText = " " + String.localizedStringWithFormat(NSLocalizedString("explore.people", comment: ""), talkingAbout.withCommas())
            if talkingAbout <= 10 {
                talkingAboutText = " " + NSLocalizedString("explore.somePeople", comment: "")
            }
            let attStringNewLine00 = NSMutableAttributedString(string: talkingAboutText, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
            let attString00 = NSAttributedString(attachment: attachment1)
            attStringNewLine000.append(attString00)
            attStringNewLine000.append(attStringNewLine00)
            cell.titleLabel2.attributedText = attStringNewLine000

            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            if fromOtherCommunity {
                let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.trending(otherInstance)))
                if vc.isBeingPresented {} else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                if indexPath.row == 0 {
                    if GlobalStruct.displayingVIPLists != 1 {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "createVIPListPrompt"), object: nil)
                    } else {
                        let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.list(List(id: GlobalStruct.VIPListID, title: "Top Friends"))))
                        if vc.isBeingPresented {} else {
                            navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
                if indexPath.row == 1 {
                    if let account = AccountsManager.shared.currentAccount as? MastodonAcctData {
                        let currentInstance = account.instanceData.instanceText
                        let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.trending(currentInstance)))
                        if vc.isBeingPresented {} else {
                            navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
                if indexPath.row == 2 {
                    let vc = ProfileDirectoryViewController()
                    vc.fromSuggestions = true
                    if vc.isBeingPresented {} else {
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
                if indexPath.row == 3 {
                    let vc = ProfileDirectoryViewController()
                    if vc.isBeingPresented {} else {
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
                if indexPath.row == 4 {
                    let vc = SignInViewController()
                    vc.isFromSignIn = false
                    if vc.isBeingPresented {} else {
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        } else if indexPath.section == 2 {
            if fromOtherCommunity {
                let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: allTrends[indexPath.row].name, url: ""))))

                if vc.isBeingPresented {} else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                if indexPath.row == 0 {
                    let vc = AltTextViewController()
                    vc.newList = true
                    present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                } else {
                    let listId = ListManager.shared.allLists(includeTopFriends: false)[indexPath.row - 1].id
                    let listTitle = ListManager.shared.allLists(includeTopFriends: false)[indexPath.row - 1].title
                    let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.list(List(id: listId, title: listTitle))))

                    if vc.isBeingPresented {} else {
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        } else if indexPath.section == 3 {
            if allTags.isEmpty {
                let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: allTrends[indexPath.row].name, url: ""))))

                if vc.isBeingPresented {} else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: allTags[indexPath.row].name, url: ""))))
                if vc.isBeingPresented {} else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        } else if indexPath.section == 4 {
            let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: allTrends[indexPath.row].name, url: ""))))
            if vc.isBeingPresented {} else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        var acc: Account? = nil
        if (interaction.view?.tag ?? 0) >= 600_000 {
            acc = self.acc[5]
        } else if (interaction.view?.tag ?? 0) >= 500_000 {
            acc = self.acc[4]
        } else if (interaction.view?.tag ?? 0) >= 400_000 {
            acc = self.acc[3]
        } else if (interaction.view?.tag ?? 0) >= 300_000 {
            acc = self.acc[2]
        } else if (interaction.view?.tag ?? 0) >= 200_000 {
            acc = self.acc[1]
        } else {
            acc = self.acc[0]
        }
        if acc?.id ?? "" == currentUserID ?? "" {
            return nil
        } else {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
                _ in
                self.makeContextProfileMain(interaction.view?.tag ?? 0)
            })
        }
    }

    func makeContextProfileMain(_ index: Int) -> UIMenu {
        var acc: Account? = nil
        if index >= 600_000 {
            acc = self.acc[5]
        } else if index >= 500_000 {
            acc = self.acc[4]
        } else if index >= 400_000 {
            acc = self.acc[3]
        } else if index >= 300_000 {
            acc = self.acc[2]
        } else if index >= 200_000 {
            acc = self.acc[1]
        } else {
            acc = self.acc[0]
        }
        let op0 = UIAction(title: NSLocalizedString("profile.mention", comment: ""), image: UIImage(systemName: "at"), identifier: nil) { _ in
            let vc = NewPostViewController()
            vc.isModalInPresentation = true
            vc.fromPro = true
            vc.proText = "@\(acc?.acct ?? "") "
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        let op00 = UIAction(title: "Message", image: UIImage(systemName: "tray.full"), identifier: nil) { _ in
            let vc = NewPostViewController()
            vc.isModalInPresentation = true
            vc.fromPro = true
            vc.proText = "@\(acc?.acct ?? "") "
            vc.whoCanReply = .direct
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        let mentionMenu = UIMenu(title: "", options: [.displayInline], children: [op0, op00])
        if #available(iOS 16.0, *) {
            mentionMenu.preferredElementSize = .medium
        }

        let op000 = UIAction(title: "Recent Media", image: UIImage(systemName: "photo.on.rectangle"), identifier: nil) { _ in
            let vc = GalleryViewController()
            vc.otherUserId = acc?.id ?? ""
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }

        var opVIP = UIAction(title: "Add to Top Friends", image: UIImage(systemName: "star"), identifier: nil) { _ in
            if GlobalStruct.displayingVIPLists == 0 {
                let userInfoDict = (acc == nil) ? nil : ["Account": acc!]
                NotificationCenter.default.post(name: Notification.Name(rawValue: "createVIPListPrompt"), object: nil, userInfo: userInfoDict)
            } else {
                let request2 = Lists.add(accountIDs: [acc?.id ?? ""], toList: GlobalStruct.VIPListID)
                self.client!.run(request2) { statuses in
                    if let error = statuses.error {
                        log.error("Failed to add to list: \(error)")
                        DispatchQueue.main.async {
                            if GlobalStruct.accountIDsToFollow.contains(acc?.id ?? "") {
                                if let account = acc {
                                    let userInfoDict = ["Account": account]
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "addToTopFriends"), object: nil, userInfo: userInfoDict)
                                }
                            } else {
                                let userInfoDict = (acc == nil) ? nil : ["Account": acc!]
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "followAndAddToTopFriends"), object: nil, userInfo: userInfoDict)
                            }
                        }
                    }
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            // added
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "postVIP"), object: nil)
                            print("added users to new VIP list")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadThisExplore"), object: nil)
                            if let x = acc {
                                GlobalStruct.topAccounts.append(x)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchAllTimelinesLikedBy"), object: nil)
                                if let x = self.currentUserID {
                                    do {
                                        try Disk.save(GlobalStruct.topAccounts, to: .documents, as: "\(x)/topAccounts2.json")
                                    } catch {
                                        log.error("error saving top accounts to Disk")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if GlobalStruct.topAccounts.contains(where: { x in
            x.id == acc?.id ?? ""
        }) {
            opVIP = UIAction(title: "Remove from Top Friends", image: UIImage(systemName: "star.slash"), identifier: nil) { _ in
                let request2 = Lists.remove(accountIDs: [acc?.id ?? ""], fromList: GlobalStruct.VIPListID)
                self.client!.run(request2) { statuses in
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            // added
                            print("removed users from VIP list")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadThisExplore"), object: nil)
                            if let x = acc {
                                GlobalStruct.topAccounts = GlobalStruct.topAccounts.filter { y in
                                    y != x
                                }
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchAllTimelinesLikedBy"), object: nil)
                                if let x = self.currentUserID {
                                    do {
                                        try Disk.save(GlobalStruct.topAccounts, to: .documents, as: "\(x)/topAccounts2.json")
                                    } catch {
                                        log.error("error saving top accounts to Disk")
                                    }
                                }
                            }
                        }
                    }
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnVIP"), object: nil)
            }
        }
        if GlobalStruct.displayingVIPLists == 2 {
            opVIP.attributes = .hidden
        }

        var listAct1: [UIAction] = []
        for x in ListManager.shared.allLists(includeTopFriends: false) {
            let op1 = UIAction(title: x.title, image: UIImage(systemName: "list.bullet"), identifier: nil) { _ in
                ListManager.shared.addToList(accountID: acc?.id ?? "", listID: x.id) { success in
                    if !success {
                        log.error("Failed to add to list")
                        DispatchQueue.main.async {
                            let userInfoDict = (acc == nil) ? nil : ["Account": acc!, "List": x.id]
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "followAndAddToTopFriends"), object: nil, userInfo: userInfoDict)
                        }
                    } else {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "postVIP"), object: nil)
                            triggerHapticNotification()
                        }
                    }
                }
            }
            listAct1.append(op1)
        }
        let list1 = UIMenu(title: "Add to List", image: UIImage(systemName: "plus"), options: [], children: listAct1)
        var listAct2: [UIAction] = []
        for x in ListManager.shared.allLists(includeTopFriends: false) {
            let op1 = UIAction(title: x.title, image: UIImage(systemName: "list.bullet"), identifier: nil) { _ in
                NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnVIP"), object: nil)
                ListManager.shared.removeFromList(accountID: acc?.id ?? "", listID: x.id) { success in
                    if success {
                        DispatchQueue.main.async {
                            triggerHapticNotification()
                        }
                    }
                }
            }
            listAct2.append(op1)
        }
        let list2 = UIMenu(title: "Remove from List", image: UIImage(systemName: "minus"), options: [], children: listAct2)
        let op3 = UIMenu(title: "Manage Lists", image: UIImage(systemName: "list.bullet"), options: [], children: [list1, list2])

        let trans = UIAction(title: "Translate Bio", image: UIImage(systemName: "globe"), identifier: nil) { _ in
            PostActions.translateString(acc?.note.stripHTML() ?? "")
        }

        let share = UIAction(title: "Share Profile", image: FontAwesome.image(fromChar: "\u{e09a}"), identifier: nil) { _ in
            let text = URL(string: "\(acc?.url ?? "")")!
            let textToShare = [text]
            let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
        let shareMenu = UIMenu(title: "", options: [.displayInline], children: [share])

        return UIMenu(title: "", options: [], children: [mentionMenu, op000, opVIP, op3, trans, shareMenu])
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        if indexPath.section == 2, indexPath.row != 0 {
            if fromOtherCommunity {
                return nil
            } else {
                return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { _ in
                    self.makeContextMenu(indexPath.row)
                })
            }
        } else if indexPath.section == 3 {
            if allTags.isEmpty {
                return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { _ in
                    self.makeContextMenu2(indexPath.row)
                })
            } else {
                return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { _ in
                    self.makeContextMenu3(indexPath.row)
                })
            }
        } else if indexPath.section == 4 {
            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: { nil }, actionProvider: { _ in
                self.makeContextMenu2(indexPath.row)
            })
        } else {
            return nil
        }
    }

    func makeContextMenu(_ index: Int) -> UIMenu {
        let op1 = UIAction(title: "View List Members", image: UIImage(systemName: "person.2"), identifier: nil) { _ in
            let vc = UserListViewController(listID: ListManager.shared.allLists(includeTopFriends: false)[index - 1].id)
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        op1.accessibilityLabel = "Reply"
        let op2 = UIAction(title: "Edit List Title", image: UIImage(systemName: "pencil"), identifier: nil) { _ in
            let vc = AltTextViewController()
            vc.editList = ListManager.shared.allLists(includeTopFriends: false)[index - 1].title
            vc.listId = ListManager.shared.allLists(includeTopFriends: false)[index - 1].id
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
        op2.accessibilityLabel = "Edit List Title"
        let op3 = UIAction(title: "Delete List", image: UIImage(systemName: "trash"), identifier: nil) { _ in
            let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this list?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                let id = ListManager.shared.allLists(includeTopFriends: false)[index - 1].id
                ListManager.shared.deleteList(id) { _ in
                    DispatchQueue.main.async {
                        log.debug("deleted list: \(id)")
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                        self.tableView.reloadData()
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
        op3.accessibilityLabel = "Delete List"
        op3.attributes = .destructive
        return UIMenu(title: "", options: [], children: [op1, op2, op3])
    }

    func tableView(_: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 2 && indexPath.row != 0 {
            return true
        } else {
            return false
        }
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this list?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                let id = ListManager.shared.allLists(includeTopFriends: false)[indexPath.row - 1].id
                ListManager.shared.deleteList(id, completion: { success in
                    DispatchQueue.main.async {
                        if success {
                            log.debug("deleted list: \(id)")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                        }
                        self.tableView.reloadData()
                    }
                })
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

    func makeContextMenu2(_ index: Int) -> UIMenu {
        let op1 = UIAction(title: "Follow Tag", image: UIImage(systemName: "plus.circle"), identifier: nil) { _ in
            triggerHapticImpact(style: .light)
            let request = TrendingTags.follow(id: "\(self.allTrends[index].name.lowercased())")
            self.client!.run(request) { statuses in
                if let _ = (statuses.value) {
                    DispatchQueue.main.async {
                        triggerHapticNotification()
                        self.fetchFollowingTags()
                    }
                }
            }
        }
        op1.accessibilityLabel = "Follow Tag"
        return UIMenu(title: "", options: [], children: [op1])
    }

    func makeContextMenu3(_ index: Int) -> UIMenu {
        let op1 = UIAction(title: "Unfollow Tag", image: UIImage(systemName: "minus.circle"), identifier: nil) { _ in
            triggerHapticImpact(style: .light)
            let request = TrendingTags.unfollow(id: "\(self.allTags[index].name.lowercased())")
            self.client!.run(request) { statuses in
                if let _ = (statuses.value) {
                    DispatchQueue.main.async {
                        triggerHapticNotification()
                        self.allTags = self.allTags.filter { $0.name.lowercased() != self.allTags[index].name.lowercased() }
                        self.tableView.reloadData()
                    }
                }
            }
        }
        op1.accessibilityLabel = "Unfollow Tag"
        return UIMenu(title: "", options: [], children: [op1])
    }
}
