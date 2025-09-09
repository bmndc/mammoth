//
//  DiscoverSuggestionsViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 9/25/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class DiscoverSuggestionsViewController: UIViewController {
    enum Sections: Int {
        case hashtags
        case accounts
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(HashtagCell.self, forCellReuseIdentifier: HashtagCell.reuseIdentifier)
        tableView.register(UserCardCell.self, forCellReuseIdentifier: UserCardCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }

        return tableView
    }()

    private(set) var viewModel: DiscoverSuggestionsViewModel

    required init(viewModel: DiscoverSuggestionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        title = NSLocalizedString("navigator.discover", comment: "")
        navigationItem.title = NSLocalizedString("navigator.discover", comment: "")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.viewModel.cancelAllItemSyncs()
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onThemeChange),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.cancelAllItemSyncs()
    }

    @objc private func onThemeChange() {
        tableView.reloadData()
    }
}

// MARK: UI Setup

private extension DiscoverSuggestionsViewController {
    func setupUI() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension DiscoverSuggestionsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.requestItemSync(forIndexPath: indexPath, afterSeconds: 1)
    }

    func tableView(_: UITableView, didEndDisplaying _: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.cancelItemSync(forIndexPath: indexPath)
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(forSection: section)
    }

    func numberOfSections(in _: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.hasHeader(forSection: section) {
            return 29
        } else {
            return 0
        }
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.getInfo(forIndexPath: indexPath) {
        case let .account(userCard):
            let cell = tableView.dequeueReusableCell(withIdentifier: UserCardCell.reuseIdentifier, for: indexPath) as! UserCardCell
            if let info = userCard {
                if info.followStatus != .unknown {
                    info.forceFollowButtonDisplay = true
                }
                cell.configure(info: info) { [weak self] type, isActive, data in
                    guard let self else { return }
                    PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: info, data: data)
                }
            }
            return cell
        case let .hashtag(tag):
            let cell = tableView.dequeueReusableCell(withIdentifier: HashtagCell.reuseIdentifier, for: indexPath) as! HashtagCell
            if let tag = tag {
                let hashtagStatus = HashtagManager.shared.statusForHashtag(tag)
                let showAsSubscribed = (hashtagStatus == .following || hashtagStatus == .followRequested)
                cell.configure(hashtag: tag, isSubscribed: showAsSubscribed)
            }
            return cell
        }

        log.error("unable to dequeue the correct cell in DiscoverSuggestionsViewController")
        return UITableViewCell()
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.hasHeader(forSection: section) {
            let buttonTitle = (section == Sections.accounts.rawValue) ? nil : NSLocalizedString("discover.seeAll", comment: "")
            let header = SectionHeader(buttonTitle: buttonTitle)
            if buttonTitle != nil {
                header.delegate = self
                header.delegateContext = section
            }
            header.configure(labelText: viewModel.getSectionTitle(for: section))
            return header
        } else {
            return nil
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.getInfo(forIndexPath: indexPath) {
        case let .account(userCard):
            if let user = userCard {
                let vc = ProfileViewController(user: user, screenType: user.isSelf ? .own : .others)
                if vc.isBeingPresented {} else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        case let .hashtag(tag):
            if let tag = tag {
                let vc = NewsFeedViewController(type: .hashtag(Tag(name: tag.name, url: tag.url)))
                if vc.isBeingPresented {} else {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

// MARK: UISearchControllerDelegate

extension DiscoverSuggestionsViewController: UISearchControllerDelegate {}

// MARK: UISearchResultsUpdating

extension DiscoverSuggestionsViewController: UISearchResultsUpdating {
    func updateSearchResults(for _: UISearchController) {}
}

// MARK: RequestDelegate

extension DiscoverSuggestionsViewController: DiscoverySuggestionsDelegate {
    func didUpdateAll() {
        tableView.reloadData()
    }

    func didUpdateSection(section: DiscoverSuggestionsViewModel.DiscoverySuggestionSection, with _: ViewState) {
        let sectionIndex = section.rawValue
        tableView.reloadSections([sectionIndex], with: .none)
    }

    func didUpdateCard(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func didDeleteCard(at indexPath: IndexPath) {
        tableView.deleteRows(at: [indexPath], with: .bottom)
    }
}

// MARK: UISearchBarDelegate

extension DiscoverSuggestionsViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        viewModel.search(query: searchText, fullSearch: false)
    }

    func searchBarCancelButtonClicked(_: UISearchBar) {
        viewModel.cancelSearch()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let query = searchBar.text {
            viewModel.search(query: query, fullSearch: true)
        }
    }
}

extension DiscoverSuggestionsViewController: SectionHeaderDelegate {
    func userTappedButton(context: Int) {
        if context == Sections.hashtags.rawValue {
            // Show all hashtags
            let vc = HashtagsViewController(viewModel: HashtagsViewModel(allHashtags: viewModel.allTrendingHashtags))
            if vc.isBeingPresented {} else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension DiscoverSuggestionsViewController: JumpToNewest {
    @objc func jumpToNewest() {
        tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}

// MARK: Appearance changes

extension DiscoverSuggestionsViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                tableView.backgroundColor = .custom.background
                tableView.reloadData()
            }
        }
    }
}
