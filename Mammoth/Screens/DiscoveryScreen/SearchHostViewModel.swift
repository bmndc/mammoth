//
//  SearchHostViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 8/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

protocol SearchHostDelegate: AnyObject {
    func didUpdateViewType(with viewType: SearchHostViewModel.ViewTypes)
}

class SearchHostViewModel {
    enum ViewTypes: Int, CaseIterable {
        case suggestions
        case users
        case channels
        case hashtags
        case posts
        case instances
    }

    weak var delegate: SearchHostDelegate?
    private var viewType: ViewTypes = .suggestions {
        didSet {
            delegate?.didUpdateViewType(with: viewType)
        }
    }

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSwitchAccount),
                                               name: didSwitchCurrentAccountNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification handlers

private extension SearchHostViewModel {
    @objc func didSwitchAccount() {
        Task {
            // Reset view choice
            self.viewType = .suggestions
        }
    }
}

extension SearchHostViewModel {
    func userInitiatedSearch() {
        // If showing suggestions, and the user taps 'search',
        // switch to showing Users
        if viewType == .suggestions {
            viewType = .users
        }
    }

    func userClearedTextField() {
        // Switch to showing Suggestions when the user clears the
        // search field / taps 'X'
        viewType = .suggestions
    }

    func userCancelledSearch() {
        // Switch to showing Suggestions when the user taps 'cancel'
        viewType = .suggestions
    }

    func switchToViewAtIndex(_ index: Int) {
        viewType = ViewTypes.allCases[index]
    }

    func shouldShowCarousel() -> Bool {
        return viewType != .suggestions
    }
}
