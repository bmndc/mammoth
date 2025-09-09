//
//  InstancesViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 9/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

class InstancesViewModel {
    weak var delegate: RequestDelegate?

    private var state: ViewState {
        didSet {
            delegate?.didUpdate(with: state)
        }
    }

    private var listData: [InstanceCardModel] = []

    init() {
        state = .idle
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(allInstancesDidChange),
                                               name: didChangeAllInstancesNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pinnedInstancesDidChange),
                                               name: didChangePinnedInstancesNotification,
                                               object: nil)
        Task {
            await self.loadRecommendations()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func preloadCards(atIndexPaths indexPaths: [IndexPath]) {
        let cards = indexPaths.compactMap { self.getInfo(forIndexPath: $0) }
        InstanceCardModel.preload(instanceCards: cards)
    }
}

// MARK: - DataSource

extension InstancesViewModel {
    func numberOfItems(forSection _: Int) -> Int {
        return listData.count
    }

    var numberOfSections: Int {
        return 1
    }

    func hasHeader(forSection _: Int) -> Bool {
        return false
    }

    func getInfo(forIndexPath indexPath: IndexPath) -> InstanceCardModel? {
        guard listData.count != 0 else {
            return nil
        }
        return listData[indexPath.row]
    }
}

// MARK: - Service

extension InstancesViewModel {
    func loadRecommendations() async {
        listData = []
        state = .loading
    }

    func search(query: String, fullSearch: Bool = false) {
        if fullSearch {
            searchAll(query: query)
        }
    }

    // Actually do the searching/filtering here
    func searchAll(query: String) {
        listData = []
        state = .loading
        Task {
            let searchResults = await InstanceService.searchForInstances(query: query).map { InstanceCardModel(instance: $0) }
            DispatchQueue.main.async {
                self.listData = searchResults
                self.state = .success
            }
        }
    }

    func cancelSearch() {}
}

// MARK: - Notification handlers

private extension InstancesViewModel {
    @objc func allInstancesDidChange(notification _: Notification) {
        Task {
            await self.loadRecommendations()
        }
    }

    @objc func pinnedInstancesDidChange(notification: Notification) {
        if let instanceName = notification.userInfo?["InstanceName"] as? String, let index = updatePinnedInstanceNamed(instanceName) {
            delegate?.didUpdateCard(at: IndexPath(row: index, section: 0))
        }
    }

    func updatePinnedInstanceNamed(_ instanceName: String) -> Int? {
        // Update both allInstances and listData
        var updatedInstance: InstanceCardModel
        if let allInstancesIndex = listData.firstIndex(where: { tagInstance in
            tagInstance.name == instanceName
        }) {
            updatedInstance = listData[allInstancesIndex]
            updatedInstance.isPinned = InstanceManager.shared.pinnedStatusForInstance(instanceName) == .pinned
            listData[allInstancesIndex] = updatedInstance
        }

        let listDataIndex = listData.firstIndex(where: { tagInstance in
            tagInstance.name == instanceName
        })
        if listDataIndex != nil {
            updatedInstance = listData[listDataIndex!]
            updatedInstance.isPinned = InstanceManager.shared.pinnedStatusForInstance(instanceName) == .pinned
            listData[listDataIndex!] = updatedInstance
        }

        // Return index of listData
        return listDataIndex
    }
}
