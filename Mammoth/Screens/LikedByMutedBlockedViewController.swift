//
//  LikedByMutedBlockedViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 04/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import AVFoundation
import Foundation
import MobileCoreServices
import NaturalLanguage
import SafariServices
import UIKit

// swiftlint:disable:next type_body_length
class LikedByMutedBlockedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIContextMenuInteractionDelegate, UITableViewDragDelegate {
    var currentUserID: String?
    var client: Client?
    let loadingIndicator = UIActivityIndicatorView()
    let emptyView = UIImageView()
    var tableView = UITableView()
    let refreshControl = UIRefreshControl()
    var otherInstance: String = ""
    var fromOtherCommunity: Bool = false
    var currentSegment: Int = 0
    var type: Int = 0
    var id: String = ""
    var listID: String = ""
    var nBounds: CGRect = .zero
    var nBar: UINavigationBar = .init()
    var statusesAll: [Account] = []
    var statusesAllNext: RequestRange?
    var statusesAllPrev: RequestRange?
    var tempDetailUrl: String = ""

    @objc func reloadAll() {
        DispatchQueue.main.async {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileCell {
                cell.profileIcon.layer.borderColor = UIColor.custom.baseTint.cgColor
            }

            // tints

            let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
            if hcText == true {
                UIColor.custom.mainTextColor = .label
            } else {
                UIColor.custom.mainTextColor = .secondaryLabel
            }
            let hcText2 = UserDefaults.standard.value(forKey: "hcText2") as? Bool ?? false
            if hcText2 == true {
                UIColor.custom.mainTextColor2 = .label
            } else {
                UIColor.custom.mainTextColor2 = .secondaryLabel
            }

            if !self.statusesAll.isEmpty {
                self.statusesAll = self.statusesAll.filter { $0.id != GlobalStruct.idToDelete }
                self.tableView.reloadData()
                self.saveToDisk()
            }

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileCell {
            cell.profileIcon.layer.borderColor = UIColor.custom.baseTint.cgColor
        }
        tableView.tableHeaderView?.frame.size.height = 60
        emptyView.center = CGPoint(x: view.center.x, y: view.center.y - 30)

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
        currentUserID = AccountsManager.shared.currentUser()?.id
        client = AccountsManager.shared.currentAccountClient
        view.backgroundColor = .custom.backgroundTint
        if type == 0 {
            navigationItem.title = "Liked By..."
        } else if type == 10 {
            navigationItem.title = "Reposted By..."
        } else if type == 1 {
            navigationItem.title = NSLocalizedString("profile.muted", comment: "")
        } else if type == 2 {
            navigationItem.title = NSLocalizedString("profile.blocked", comment: "")
        } else if type == 3 {
            navigationItem.title = "Pinned Users"
        } else if type == 4 {
            navigationItem.title = "Follow Requests"
        } else if type == 5 {
            navigationItem.title = "List Members"
        } else {
            navigationItem.title = "Top Friends Members"
        }

        NotificationCenter.default.addObserver(self, selector: #selector(reloadAll), name: NSNotification.Name(rawValue: "reloadAll"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAllTimelines), name: NSNotification.Name(rawValue: "fetchAllTimelinesLikedBy"), object: nil)

        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.center = view.center
        view.addSubview(loadingIndicator)

        setupTable()

        fetchAllTimelines()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: navigationController, userInterfaceStyle: traitCollection.userInterfaceStyle)
    }

    func saveToDisk() {}

    @objc func fetchAllTimelines() {
        fetchTimelines1()
    }

    @objc func prevRefresh1() {
        Sound().playSound(named: "soundSuction", withVolume: 1)
        fetchTimelines1(true, nextBatch: false)
    }

    func fetchTimelines1(_ prevBatch: Bool = false, nextBatch: Bool = false) {
        var canLoad = true
        var id = "\(tempDetailUrl.split(separator: "/").last ?? "")"
        if tempDetailUrl == "" {
            id = self.id
        }
        var request2 = Statuses.favouritedBy(id: id)
        if type == 0 {
            if prevBatch {
                if let ra = statusesAllPrev {
                    request2 = Statuses.favouritedBy(id: id, range: ra)
                }
            }
            if nextBatch {
                if let ra = statusesAllNext {
                    request2 = Statuses.favouritedBy(id: id, range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 10 {
            request2 = Statuses.rebloggedBy(id: id)
            if prevBatch {
                if let ra = statusesAllPrev {
                    request2 = Statuses.rebloggedBy(id: id, range: ra)
                }
            }
            if nextBatch {
                if let ra = statusesAllNext {
                    request2 = Statuses.rebloggedBy(id: id, range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 1 {
            request2 = Mutes.all()
            if prevBatch {
                if let ra = statusesAllPrev {
                    request2 = Mutes.all(range: ra)
                }
            }
            if nextBatch {
                if let ra = statusesAllNext {
                    request2 = Mutes.all(range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 2 {
            request2 = Blocks.all()
            if prevBatch {
                if let ra = statusesAllPrev {
                    request2 = Blocks.all(range: ra)
                }
            }
            if nextBatch {
                if let ra = statusesAllNext {
                    request2 = Blocks.all(range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 3 {
            request2 = Accounts.allEndorsements()
        } else if type == 4 {
            request2 = FollowRequests.all()
            if prevBatch {
                if let ra = statusesAllPrev {
                    request2 = FollowRequests.all(range: ra)
                }
            }
            if nextBatch {
                if let ra = statusesAllNext {
                    request2 = FollowRequests.all(range: ra)
                } else {
                    canLoad = false
                }
            }
        } else if type == 5 {
            request2 = Lists.accounts(id: listID)
            if prevBatch {
                if let ra = statusesAllPrev {
                    request2 = Lists.accounts(id: listID, range: ra)
                }
            }
            if nextBatch {
                if let ra = statusesAllNext {
                    request2 = Lists.accounts(id: listID, range: ra)
                } else {
                    canLoad = false
                }
            }
        }
        if type == 6 {
            statusesAll = Array(GlobalStruct.topAccounts.reversed())
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.loadingIndicator.stopAnimating()
                self.tableView.reloadData()
            }
        } else {
            if canLoad {
                var testClient = client!
                if fromOtherCommunity || tempDetailUrl != "" {
                    let accessToken = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.instanceData.accessToken
                    testClient = Client(
                        baseURL: "https://\(otherInstance)",
                        accessToken: accessToken
                    )
                }
                testClient.run(request2) { statuses in
                    if self.type == 3 {
                        canLoad = false
                    }
                    self.statusesAllNext = statuses.pagination?.next
                    self.statusesAllPrev = statuses.pagination?.previous
                    if let error = statuses.error {
                        log.error("Failed to fetch timeline: \(error)")
                        DispatchQueue.main.async {
                            if self.statusesAll.isEmpty {
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
                        if prevBatch {
                            self.statusesAll = stat + self.statusesAll
                            self.statusesAll = self.statusesAll.removingDuplicates()
                        } else if nextBatch {
                            self.statusesAll += stat
                        } else {
                            self.statusesAll = stat
                        }
                        DispatchQueue.main.async {
                            self.refreshControl.endRefreshing()
                            self.loadingIndicator.stopAnimating()
                            self.tableView.reloadData()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }

    func setupTable() {
        emptyView.bounds.size.width = 80
        emptyView.bounds.size.height = 80
        emptyView.backgroundColor = UIColor.clear
        emptyView.image = UIImage(systemName: "sparkles", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular))?.withTintColor(UIColor.secondaryLabel.withAlphaComponent(0.18), renderingMode: .alwaysOriginal)
        emptyView.alpha = 0
        tableView.addSubview(emptyView)

        tableView.register(UserCell.self, forCellReuseIdentifier: "UserCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.refreshControl = refreshControl
        tableView.dragDelegate = self
        tableView.dragInteractionEnabled = true
        refreshControl.addTarget(self, action: #selector(prevRefresh1), for: .valueChanged)

        view.addSubview(tableView)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return statusesAll.count
    }

    func tableView(_: UITableView, itemsForBeginning _: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let stat: Account? = statusesAll[indexPath.row]

        let string = "\(stat?.url ?? "")"
        guard let data = string.data(using: .utf8) else { return [] }
        let provider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeURL as String)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = string
        return [item]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell

        cell.userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        cell.userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        cell.bioText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)

        if indexPath.row < statusesAll.count {
            emptyView.alpha = 0
            let tmpData = statusesAll[indexPath.row]

            if let ur = URL(string: tmpData.avatar) {
                cell.profileIcon.sd_setImage(with: ur, for: .normal)
            }

            cell.profileIcon.tag = indexPath.row
            cell.profileIcon.addTarget(self, action: #selector(profileTap), for: .touchUpInside)
            //
            let interaction = UIContextMenuInteraction(delegate: self)
            cell.profileIcon.addInteraction(interaction)
            //
            cell.profileIcon.tag = indexPath.row

            cell.userName.text = tmpData.displayName
            cell.userTag.text = "@\(tmpData.acct)"
            cell.bioText.text = tmpData.note.stripHTML()
            if GlobalStruct.limitProfileLines {
                cell.bioText.text = (cell.bioText.text ?? "").replacingOccurrences(of: "\n", with: " ")
                cell.bioText.numberOfLines = 2
            }

            cell.bioText.mentionColor = .custom.baseTint
            cell.bioText.hashtagColor = .custom.baseTint
            cell.bioText.URLColor = .custom.baseTint
            cell.bioText.emailColor = .custom.baseTint

            if tmpData.locked == false {
                cell.lockedBadge.alpha = 0
                cell.lockedBackground.alpha = 0
            } else {
                let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .bold)
                cell.lockedBadge.image = UIImage(systemName: "lock.circle.fill", withConfiguration: symbolConfig0)?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal)
                cell.lockedBadge.alpha = 1
                cell.lockedBackground.alpha = 1
                cell.lockedBackground.backgroundColor = .custom.backgroundTint
            }

            cell.setupConstraints(tmpData)

            // tap items
            cell.bioText.handleMentionTap { str in
                triggerHapticImpact(style: .light)
                let note = tmpData.note
                let sliced = "~\(note.slice(from: "<a href=\"", to: "</span></a>") ?? "")~"
                let sliced2 = sliced.slice(from: "@<span>", to: "~") ?? ""
                if sliced2 == str {
                    let sliced3 = sliced.slice(from: "~", to: "\" class=") ?? ""
                    if let ur = URL(string: "\(sliced3)") {
                        PostActions.openLink(ur)
                    }
                }
            }
            cell.bioText.handleHashtagTap { str in
                triggerHapticImpact(style: .light)
                let vc = NewsFeedViewController(viewModel: NewsFeedViewModel(.hashtag(Tag(name: str, url: ""))))
                if vc.isBeingPresented {} else {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            cell.bioText.handleURLTap { str in
                triggerHapticImpact(style: .light)
                PostActions.openLink(str)
            }
            cell.bioText.handleEmailTap { _ in
            }
        }

        cell.separatorInset = .zero
        let bgColorView = UIView()
        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
        cell.selectedBackgroundView = bgColorView
        cell.backgroundColor = .custom.backgroundTint

        if type == 6 {} else {
            var minusDiff = 3
            if statusesAll.count < 4 {
                minusDiff = 1
            }
            if indexPath.row == statusesAll.count - minusDiff {
                fetchTimelines1(false, nextBatch: true)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if type == 4 {
            let alert = UIAlertController(title: "Accept or reject the follow request from \(statusesAll[indexPath.row].displayName)?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { _ in
                let request = FollowRequests.authorize(id: self.statusesAll[indexPath.row].id)
                self.client!.run(request) { _ in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter { x in
                            x.id != self.statusesAll[indexPath.row].id
                        }
                        self.tableView.reloadData()
                        triggerHapticNotification()
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Reject", style: .destructive, handler: { _ in
                let request = FollowRequests.reject(id: self.statusesAll[indexPath.row].id)
                self.client!.run(request) { _ in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter { x in
                            x.id != self.statusesAll[indexPath.row].id
                        }
                        self.tableView.reloadData()
                        triggerHapticNotification()
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            }))
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        } else {
            let stat: Account? = statusesAll[indexPath.row]
            if let account = stat {
                let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
                if vc.isBeingPresented {} else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation _: CGPoint) -> UIContextMenuConfiguration? {
        var acc: Account? = nil
        acc = statusesAll[interaction.view?.tag ?? 0]
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
        acc = statusesAll[index]
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
        if type == 1 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
                _ in
                self.makeContext(indexPath.row, type: 1)
            })
        } else if type == 2 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
                _ in
                self.makeContext(indexPath.row, type: 2)
            })
        } else if type == 4 {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
                _ in
                self.makeContext(indexPath.row, type: 4)
            })
        } else {
            return nil
        }
    }

    func makeContext(_ index: Int, type: Int) -> UIMenu {
        var op1: UIAction? = nil
        if type == 1 {
            op1 = UIAction(title: "Unmute @\(statusesAll[index].username)", image: UIImage(systemName: "speaker"), identifier: nil) { _ in
                let request = Accounts.unmute(id: self.statusesAll[index].id)
                self.client!.run(request) { _ in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter { x in
                            x.id != self.statusesAll[index].id
                        }
                        self.tableView.reloadData()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnmuted"), object: nil)
                        triggerHapticNotification()
                    }
                }
            }
        }
        if type == 2 {
            op1 = UIAction(title: "Unblock @\(statusesAll[index].username)", image: UIImage(systemName: "hand.raised"), identifier: nil) { _ in
                let request = Accounts.unblock(id: self.statusesAll[index].id)
                self.client!.run(request) { _ in
                    DispatchQueue.main.async {
                        let id = self.statusesAll[index].id
                        self.statusesAll = self.statusesAll.filter { x in
                            x.id != id
                        }
                        GlobalStruct.blockedUsers = GlobalStruct.blockedUsers.filter { x in
                            x != id
                        }
                        do {
                            try Disk.save(GlobalStruct.blockedUsers, to: .documents, as: "blockedUsers.json")
                        } catch {
                            log.warning("error saving blocked users to Disk - \(error)")
                        }
                        self.tableView.reloadData()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnblocked"), object: nil)
                        triggerHapticNotification()
                    }
                }
            }
        }
        if type == 4 {
            op1 = UIAction(title: "Accept", image: UIImage(systemName: "checkmark"), identifier: nil) { _ in
                let request = FollowRequests.authorize(id: self.statusesAll[index].id)
                self.client!.run(request) { _ in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter { x in
                            x.id != self.statusesAll[index].id
                        }
                        self.tableView.reloadData()
                        triggerHapticNotification()
                    }
                }
            }
            let op2 = UIAction(title: "Reject", image: UIImage(systemName: "xmark"), identifier: nil) { _ in
                let request = FollowRequests.reject(id: self.statusesAll[index].id)
                self.client!.run(request) { _ in
                    DispatchQueue.main.async {
                        self.statusesAll = self.statusesAll.filter { x in
                            x.id != self.statusesAll[index].id
                        }
                        self.tableView.reloadData()
                        triggerHapticNotification()
                    }
                }
            }
            op2.attributes = .destructive
            if let op = op1 {
                return UIMenu(title: "", options: [], children: [op, op2])
            } else {
                return UIMenu(title: "", options: [], children: [])
            }
        }
        if let op = op1 {
            return UIMenu(title: "", options: [], children: [op])
        } else {
            return UIMenu(title: "", options: [], children: [])
        }
    }

    @objc func profileTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        // tap user profile pics
        let stat: Account? = statusesAll[sender.tag]
        // default profile pics
        if let account = stat {
            let vc = ProfileViewController(user: UserCardModel(account: account), screenType: .others)
            if vc.isBeingPresented {} else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        if type == 6 {
            return true
        } else {
            return false
        }
    }

    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: nil, message: "Are you sure you want to remove this account?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                triggerHapticNotification()
                let request2 = Lists.remove(accountIDs: [self.statusesAll[indexPath.row].id], fromList: GlobalStruct.VIPListID)
                self.client!.run(request2) { statuses in
                    if let _ = (statuses.value) {
                        DispatchQueue.main.async {
                            // added
                            print("removed users from VIP list")
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadThisExplore"), object: nil)
                            self.statusesAll = self.statusesAll.filter { x in
                                x.id != self.statusesAll[indexPath.row].id
                            }
                            self.tableView.reloadData()
                        }
                    }
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: "postUnVIP"), object: nil)
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
