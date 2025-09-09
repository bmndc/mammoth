//
//  SearchHostViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 8/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class SearchHostViewController: UIViewController {
    private let viewModel: SearchHostViewModel

    private let headerView: SearchHostHeaderView = {
        let headerView = SearchHostHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    private let blurEffectView: BlurredBackground = {
        let blurredEffectView = BlurredBackground(dimmed: true)
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        return blurredEffectView
    }()

    private let pageViewController: UIPageViewController
    private let pages: [UIViewController] = [
        DiscoverSuggestionsViewController(viewModel: DiscoverSuggestionsViewModel()),
        DiscoveryViewController(viewModel: DiscoveryViewModel()),
        HashtagsViewController(viewModel: HashtagsViewModel(allHashtags: [])),
        PostResultsViewController(viewModel: PostResultsViewModel()),
        InstancesViewController(viewModel: InstancesViewModel()),
    ]

    required init() {
        viewModel = SearchHostViewModel()
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        super.init(nibName: nil, bundle: nil)
        setupUI()
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
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pages.forEach { $0.additionalSafeAreaInsets.top = self.headerView.frame.size.height }
    }

    func setupUI() {
        viewModel.delegate = self
        headerView.carousel.delegate = self
        headerView.searchBar.delegate = self

        pageViewController.dataSource = self
        pageViewController.delegate = self

        if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.delegate = self
        }

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)

        view.bringSubviewToFront(blurEffectView)
        view.bringSubviewToFront(headerView)

        view.addSubview(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: view.topAnchor),
        ])

        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor),
        ])

        headerView.carousel.content = pages[1...].map { $0.title }
        viewModel.switchToViewAtIndex(0)
    }
}

extension SearchHostViewController: JumpToNewest {
    func jumpToNewest() {
        // Just forward the jumpToNewest() to our current page
        (pageViewController.viewControllers?.first as? JumpToNewest)?.jumpToNewest()
    }
}

// MARK: Carousel delegate and helpers

extension SearchHostViewController: CarouselDelegate {
    func carouselItemPressed(withIndex carouselIndex: Int) {
        DispatchQueue.main.async {
            let viewModelIndex = carouselIndex + 1
            self.viewModel.switchToViewAtIndex(viewModelIndex)
        }
    }

    func carouselActiveItemDoublePressed() {
        jumpToNewest()
    }

    func contextMenuForItem(withIndex _: Int) -> UIMenu? {
        return nil
    }
}

extension SearchHostViewController: SearchHostDelegate {
    func didUpdateViewType(with viewType: SearchHostViewModel.ViewTypes) {
        // Switch to the view in question
        if let pageIndex = SearchHostViewModel.ViewTypes.allCases.firstIndex(of: viewType) {
            DispatchQueue.main.async {
                self.switchToViewControllerPage(self.pages[pageIndex])
            }
        }
    }

    func switchToViewControllerPage(_ viewPage: UIViewController) {
        let previousFeedController = pageViewController.viewControllers?.first

        guard viewPage != previousFeedController else { return }

        // Initial navigation or when going back to suggestions
        if previousFeedController == nil || (viewPage as? DiscoverSuggestionsViewController) != nil {
            pageViewController.setViewControllers([pages.first!], direction: .forward, animated: false)

            // disable horizontal scroll of pageViewController
            if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                scrollView.isScrollEnabled = false
            }
        } else {
            // Navigate to complete search results
            if let _ = previousFeedController as? DiscoverSuggestionsViewController {
                pageViewController.setViewControllers([pages[1]], direction: .forward, animated: false)
            } else {
                // Navigate between complete search result pages
                if let previousIndex = pageIndex(for: previousFeedController!),
                   let nextIndex = pageIndex(for: viewPage)
                {
                    if previousIndex < nextIndex {
                        pageViewController.setViewControllers([pages[nextIndex]], direction: .forward, animated: true)
                    } else {
                        pageViewController.setViewControllers([pages[nextIndex]], direction: .reverse, animated: true)
                    }
                }
            }

            // enable horizontal scroll of pageViewController
            if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                scrollView.isScrollEnabled = true
            }
        }

        let showCarousel = viewModel.shouldShowCarousel()
        headerView.hideCarousel(!showCarousel)
    }
}

// MARK: - UIPageViewController delegate methods and helper methods

extension SearchHostViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
    func currentPageIndex() -> Int? {
        if let currentPageViewController = pageViewController.viewControllers?.first {
            return pageIndex(for: currentPageViewController)
        }

        return nil
    }

    func pageIndex(for viewController: UIViewController) -> Int? {
        return pages.firstIndex(of: viewController)
    }

    func currentPage() -> UIViewController? {
        if let currentIndex = currentPageIndex() {
            return pages[currentIndex]
        }
        return nil
    }

    func pageViewController(_: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let currentIndex = pages.firstIndex(of: viewController) {
            if currentIndex > 1 {
                return pages[currentIndex - 1]
            }
        }

        return nil
    }

    func pageViewController(_: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let currentIndex = pages.firstIndex(of: viewController) {
            if currentIndex == 0 {
                return nil
            }

            if currentIndex < pages.count - 1 {
                return pages[currentIndex + 1]
            }
        }

        return nil
    }

    func pageViewController(_: UIPageViewController, didFinishAnimating _: Bool, previousViewControllers _: [UIViewController], transitionCompleted _: Bool) {
        if let currentIndex = currentPageIndex() {
            headerView.carousel.selectItem(atIndex: currentIndex - 1)
            viewModel.switchToViewAtIndex(currentIndex)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            let width = scrollView.frame.size.width
            let offset = scrollView.contentOffset.x
            let offsetPercentage = (offset - width) / width
            headerView.carousel.adjustScrollOffset(withPercentageToNextItem: offsetPercentage)
        }
    }
}

// MARK: UISearchBarDelegate

//
// Just forward these to our current view controller
extension SearchHostViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }

    func searchBarShouldEndEditing(_: UISearchBar) -> Bool {
        return true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Do the search/filter
        for viewPage in pages {
            if let viewPageAsSearchDelegate = viewPage as? UISearchBarDelegate {
                viewPageAsSearchDelegate.searchBar?(searchBar, textDidChange: searchText)
            }
        }
        (pages.first as? DiscoverSuggestionsViewController)?.searchBar(searchBar, textDidChange: searchText)

        // If the text is empty, show the base screen
        if searchText == "" {
            viewModel.userClearedTextField()
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.text = ""
        for viewPage in pages {
            if let viewPageAsSearchDelegate = viewPage as? UISearchBarDelegate {
                viewPageAsSearchDelegate.searchBarCancelButtonClicked?(searchBar)
            }
        }
        (pages.first as? DiscoverSuggestionsViewController)?.searchBarCancelButtonClicked(searchBar)
        viewModel.userCancelledSearch()

        // Switch to the first tab in preparation for the next search
        headerView.carousel.selectItem(atIndex: 0)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        for viewPage in pages {
            if let viewPageAsSearchDelegate = viewPage as? UISearchBarDelegate {
                viewPageAsSearchDelegate.searchBarSearchButtonClicked?(searchBar)
            }
        }
        (pages.first as? DiscoverSuggestionsViewController)?.searchBarSearchButtonClicked(searchBar)
        viewModel.userInitiatedSearch()
        view.endEditing(true)

        // Re-enable the cancel button
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }
    }
}
