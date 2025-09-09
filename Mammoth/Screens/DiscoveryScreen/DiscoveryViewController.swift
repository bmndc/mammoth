//
//  DiscoveryViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 11/05/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class DiscoveryViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
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

    // searchBar for the iPad aux column
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("discover.search", comment: "")
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()

    // searchController for everything *except* the iPad aux column
    private lazy var searchController: UISearchController = .init(searchResultsController: nil)

    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        return loader
    }()

    private var viewModel: DiscoveryViewModel
    private var throttledDecelarationEndTask: Task<Void, Error>?

    required init(viewModel: DiscoveryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        title = NSLocalizedString("discover.users", comment: "")
        navigationItem.title = NSLocalizedString("discover.users", comment: "")

        if viewModel.position != .aux {
            searchController.delegate = self
            searchController.searchBar.delegate = self
            searchController.searchResultsUpdater = self
            searchController.navigationItem.hidesSearchBarWhenScrolling = false
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
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
        if viewModel.position == .aux {
            searchBar.resignFirstResponder()
        }

        throttledDecelarationEndTask?.cancel()
    }

    @objc private func onThemeChange() {
        tableView.backgroundColor = .custom.background
        tableView.reloadData()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.onThemeChange()
            }
        }
    }
}

// MARK: UI Setup

private extension DiscoveryViewController {
    func setupUI() {
        view.addSubview(tableView)
        view.addSubview(loader)

        if viewModel.position == .aux {
            view.addSubview(searchBar)
            searchBar.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            viewModel.position == .aux
                ? tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor)
                : tableView.topAnchor.constraint(equalTo: view.topAnchor),

            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        let px = 1 / UIScreen.main.scale
        let line = UIView(frame: .init(x: 0, y: 0, width: tableView.frame.size.width, height: px))
        tableView.tableHeaderView = line
        line.backgroundColor = tableView.separatorColor
    }

    func showSearchFieldLoader() {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        if viewModel.position == .aux {
            searchBar.searchTextField.leftView = loader
        }
    }

    func hideSearchFieldLoader() {
        if viewModel.position == .aux {
            searchBar.searchTextField.leftView = UISearchBar().searchTextField.leftView
        }
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension DiscoveryViewController: UITableViewDataSource, UITableViewDelegate {
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
        let userCard = viewModel.getInfo(forIndexPath: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCardCell.reuseIdentifier, for: indexPath) as! UserCardCell
        cell.configure(info: userCard, actionButtonType: .none) { [weak self] type, isActive, data in
            guard let self else { return }
            PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: userCard, data: data)
        }
        return cell
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
        let userCard = viewModel.getInfo(forIndexPath: indexPath)
        let vc = ProfileViewController(user: userCard, screenType: userCard.isSelf ? .own : .others)
        if vc.isBeingPresented {} else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func scrollViewWillBeginDragging(_: UIScrollView) {
        if let task = throttledDecelarationEndTask, !task.isCancelled {
            throttledDecelarationEndTask?.cancel()
        }
    }

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        if viewModel.shouldSyncFollowStatus() {
            throttledDecelarationEndTask = Task { [weak self] in
                guard let self else { return }
                try await Task.sleep(seconds: 1.2)
                if !Task.isCancelled {
                    if let indexPaths = self.tableView.indexPathsForVisibleRows {
                        self.viewModel.syncFollowStatus(forIndexPaths: indexPaths)
                    }
                }
            }
        }
    }
}

// MARK: UISearchControllerDelegate

extension DiscoveryViewController: UISearchControllerDelegate {}

// MARK: UISearchResultsUpdating

extension DiscoveryViewController: UISearchResultsUpdating {
    func updateSearchResults(for _: UISearchController) {}
}

// MARK: UISearchBarDelegate

extension DiscoveryViewController: UISearchBarDelegate {
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

// MARK: RequestDelegate

extension DiscoveryViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                self.showSearchFieldLoader()
                if self.viewModel.numberOfItems(forSection: 0) == 0 {
                    self.loader.isHidden = false
                    self.loader.startAnimating()
                }
            case .success:
                self.hideSearchFieldLoader()
                self.loader.stopAnimating()
                self.loader.isHidden = true
                self.tableView.reloadData()
            case let .error(error):
                self.hideSearchFieldLoader()
                self.loader.stopAnimating()
                self.loader.isHidden = true
                log.error("Error on DiscoveryViewController didUpdate: \(state) - \(error)")
            }
        }
    }

    func didUpdateCard(at indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) != nil {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func didDeleteCard(at indexPath: IndexPath) {
        tableView.deleteRows(at: [indexPath], with: .bottom)
    }
}

extension DiscoveryViewController: JumpToNewest {
    @objc func jumpToNewest() {
        tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
