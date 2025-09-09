//
//  HashtagsViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 9/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class HashtagsViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(HashtagCell.self, forCellReuseIdentifier: HashtagCell.reuseIdentifier)
        tableView.register(NoResultsCell.self, forCellReuseIdentifier: NoResultsCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
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

    private var viewModel: HashtagsViewModel

    required init(viewModel: HashtagsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        title = NSLocalizedString("title.hashtags", comment: "")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onThemeChange() {
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onThemeChange),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
    }
}

// MARK: UI Setup

private extension HashtagsViewController {
    func setupUI() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let px = 1 / UIScreen.main.scale
        let line = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.size.width, height: px))
        tableView.tableHeaderView = line
        line.backgroundColor = tableView.separatorColor
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension HashtagsViewController: UITableViewDataSource & UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If no items present, return 1 to show the No Results cell
        let numItems = viewModel.numberOfItems(forSection: section)
        return numItems == 0 ? 1 : numItems
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
        if let (hashtag, isSubscribed) = viewModel.getInfo(forIndexPath: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: HashtagCell.reuseIdentifier, for: indexPath) as! HashtagCell
            cell.configure(hashtag: hashtag, isSubscribed: isSubscribed)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NoResultsCell.reuseIdentifier) as! NoResultsCell
            return cell
        }
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.hasHeader(forSection: section) {
            let header = SectionHeader(buttonTitle: nil)
            header.configure(labelText: viewModel.getSectionTitle(for: section))
            return header
        } else {
            return nil
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug(#function)
        if let (hashtag, _) = viewModel.getInfo(forIndexPath: indexPath) {
            let vc = NewsFeedViewController(type: .hashtag(hashtag))
            if vc.isBeingPresented {} else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension HashtagsViewController: RequestDelegate {
    func didUpdate(with _: ViewState) {
        tableView.reloadData()
    }

    func didUpdateCard(at _: IndexPath) {
        tableView.reloadData()
    }

    func didDeleteCard(at _: IndexPath) {
        tableView.reloadData()
    }
}

// MARK: UISearchBarDelegate

extension HashtagsViewController: UISearchBarDelegate {
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

extension HashtagsViewController: JumpToNewest {
    @objc func jumpToNewest() {
        tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
