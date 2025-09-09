//
//  InstancesViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 9/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class InstancesViewController: UIViewController, UITableViewDataSourcePrefetching {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(InstanceCell.self, forCellReuseIdentifier: InstanceCell.reuseIdentifier)
        tableView.register(NoResultsCell.self, forCellReuseIdentifier: NoResultsCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag

        return tableView
    }()

    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        return loader
    }()

    private var viewModel: InstancesViewModel

    required init(viewModel: InstancesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        title = NSLocalizedString("title.instances", comment: "")
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                tableView.backgroundColor = .custom.background
            }
        }
    }
}

// MARK: UI Setup

private extension InstancesViewController {
    func setupUI() {
        view.addSubview(tableView)
        view.addSubview(loader)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
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
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension InstancesViewController: UITableViewDataSource & UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If no items present, return 1 to show the No Results cell
        let numItems = viewModel.numberOfItems(forSection: section)
        return numItems == 0 ? 1 : numItems
    }

    func numberOfSections(in _: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let instanceCardModel = viewModel.getInfo(forIndexPath: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: InstanceCell.reuseIdentifier, for: indexPath) as! InstanceCell
            cell.configure(instance: instanceCardModel)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NoResultsCell.reuseIdentifier) as! NoResultsCell
            return cell
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let instance = viewModel.getInfo(forIndexPath: indexPath)?.name {
            let vc = NewsFeedViewController(type: .community(instance))
            if vc.isBeingPresented {} else {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func tableView(_: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        viewModel.preloadCards(atIndexPaths: indexPaths)
    }
}

extension InstancesViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                if self.viewModel.numberOfItems(forSection: 0) == 0 {
                    self.loader.isHidden = false
                    self.loader.startAnimating()
                }
            case .success:
                self.loader.stopAnimating()
                self.loader.isHidden = true
                self.tableView.reloadData()
            case let .error(error):
                self.loader.stopAnimating()
                self.loader.isHidden = true
                log.error("Error on InstancesViewController didUpdate: \(state) - \(error)")
            }
        }
    }

    func didUpdateCard(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func didDeleteCard(at _: IndexPath) {
        log.error("no deletions expected")
    }
}

// MARK: UISearchBarDelegate

extension InstancesViewController: UISearchBarDelegate {
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

extension InstancesViewController: JumpToNewest {
    @objc func jumpToNewest() {
        tableView.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
