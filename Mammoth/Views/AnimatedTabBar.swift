//
//  AnimatedTabBar.swift
//  Mammoth
//
//  Created by Riley Howard on 8/8/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

private let animationDuration = 0.26
private let pillHorizontalMargin = 15.0
private let pillVerticalMargin = 12.0
private let gapBetweenButtons = 5.0
private let gapBetweenImageAndTitle = 7.0

class AnimatedTabBarController: UITabBarController {
    let animatedTabBar = AnimatedTabBarView()
    private let tabBarBackground: BlurredBackground = {
        let view = BlurredBackground(dimmed: true)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = false
        tabBar.layer.opacity = 0
        tabBar.isTranslucent = true

        if #available(iOS 15.0, *) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithTransparentBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            tabBar.standardAppearance = tabBarAppearance
            tabBar.scrollEdgeAppearance = tabBarAppearance
        }

        setupUI()
    }

    private func setupUI() {
        view.addSubview(tabBarBackground)
        view.addSubview(animatedTabBar)
        animatedTabBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tabBarBackground.topAnchor.constraint(equalTo: tabBar.topAnchor),
            tabBarBackground.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            tabBarBackground.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            tabBarBackground.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),

            animatedTabBar.topAnchor.constraint(equalTo: tabBar.topAnchor),
            animatedTabBar.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            animatedTabBar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            animatedTabBar.bottomAnchor.constraint(equalTo: tabBar.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    // When setViewControllers is called, create the related
    // AnimatedTabBarView buttons.
    override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        createTabBarView()
    }

    private func createTabBarView() {
        var animTabBarItems: [AnimatedTabBarItem] = []
        for vc in viewControllers! {
            let tabBarItem = vc.tabBarItem!
            let animTabBarItem = AnimatedTabBarItem(icon: tabBarItem.image!, title: tabBarItem.title!)
            animTabBarItem.translatesAutoresizingMaskIntoConstraints = false
            animTabBarItem.addTarget(self, action: #selector(barItemTap), for: .touchUpInside)

            animTabBarItems.append(animTabBarItem)
        }
        animatedTabBar.setTabBarItems(animTabBarItems)
    }

    func showActivityUnreadIndicator() {
        let items = animatedTabBar.tabBarItems
        items[2].unreadDot.isHidden = false
    }

    func hideActivityUnreadIndicator() {
        let items = animatedTabBar.tabBarItems
        items[2].unreadDot.isHidden = true
    }

    func showMessagesUnreadIndicator() {
        let items = animatedTabBar.tabBarItems
        items[3].unreadDot.isHidden = false
    }

    func hideMessagesUnreadIndicator() {
        let items = animatedTabBar.tabBarItems
        items[3].unreadDot.isHidden = true
    }

    @objc func barItemTap(_ sender: Any) {
        guard let animatedTabBarItem = sender as? AnimatedTabBarItem else {
            log.error("unexpected type")
            return
        }
        if let itemIndex = animatedTabBar.indexOfTabBarItem(animatedTabBarItem) {
            selectedIndex = itemIndex
        }
    }

    override var selectedViewController: UIViewController? {
        didSet {
            animatedTabBar.selectTabBarItemAtIndex(selectedIndex)
        }
    }

    override var selectedIndex: Int {
        didSet {
            animatedTabBar.selectTabBarItemAtIndex(selectedIndex)
        }
    }
}

class AnimatedTabBarView: UIView {
    var tabBarItems = [AnimatedTabBarItem]()
    let itemsStackView = UIStackView()
    let selectionPill: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 13.5
        view.layer.opacity = 0.85
        view.clipsToBounds = true
        view.backgroundColor = .custom.OVRLYMedContrast
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    var pillLeadingConstraint: NSLayoutConstraint?
    var pillWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func setTabBarItems(_ items: [AnimatedTabBarItem]) {
        // Remove all previous subviews
        for arrangedSubview in itemsStackView.arrangedSubviews {
            itemsStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        tabBarItems = items

        // Create and add new buttons + unread indicator if needed
        for tabBarItem in tabBarItems {
            itemsStackView.addArrangedSubview(tabBarItem)
        }
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(itemsStackView)
        itemsStackView.axis = .horizontal
        itemsStackView.distribution = .equalSpacing
        itemsStackView.alignment = .center
        itemsStackView.spacing = gapBetweenButtons
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false

        let leading = itemsStackView.leadingAnchor.constraint(lessThanOrEqualTo: leadingAnchor, constant: 32)
        leading.priority = .defaultLow
        let trailing = itemsStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        trailing.priority = .defaultLow

        NSLayoutConstraint.activate([
            itemsStackView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            leading,
            trailing,
            itemsStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            itemsStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        addSubview(selectionPill)
        pillLeadingConstraint = selectionPill.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        pillWidthConstraint = selectionPill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            pillLeadingConstraint!,
            pillWidthConstraint!,
            selectionPill.centerYAnchor.constraint(equalTo: centerYAnchor),
            selectionPill.heightAnchor.constraint(equalToConstant: 27),
        ])
        bringSubviewToFront(itemsStackView)
    }

    func indexOfTabBarItem(_ animatedTabBarItem: AnimatedTabBarItem) -> Int? {
        return tabBarItems.firstIndex(of: animatedTabBarItem)
    }

    func selectTabBarItemAtIndex(_ itemIndex: Int) {
        layoutIfNeeded()
        for (index, tabBarItem) in tabBarItems.enumerated() {
            tabBarItem.isSelected = (index == itemIndex)
        }
        UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 0.77, initialSpringVelocity: 2, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.layoutIfNeeded()
        })

        for tabBarItem in tabBarItems {
            if tabBarItem.isSelected {
                let tabBarItemFrame = tabBarItem.bounds
                let tabBarItemOrigin = convert(tabBarItemFrame, from: tabBarItem).origin

                pillLeadingConstraint!.constant = tabBarItemOrigin.x
                pillWidthConstraint!.constant = tabBarItemFrame.size.width
                UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 0.77, initialSpringVelocity: 2, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    self.layoutIfNeeded()
                })
            }
        }
    }
}

// MARK: Appearance changes

extension AnimatedTabBarView {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.selectionPill.backgroundColor = .custom.OVRLYMedContrast
            }
        }
    }
}

class AnimatedTabBarItem: UIButton {
    private let itemTitle: String
    let unreadDot: UIView = {
        let view = UIView()
        view.backgroundColor = .custom.mediumContrast
        view.clipsToBounds = true
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    required init(icon: UIImage, title: String, isUnread: Bool = false) {
        itemTitle = title.uppercased()
        super.init(frame: .zero)
        alpha = 0

        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        adjustsImageWhenHighlighted = false

        setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
        tintColor = .custom.mediumContrast

        // Setting the title during init is needed to
        // correctly set the frame. If not done, the label animates in
        // from the top left on its first animation.
        setTitle(title, for: .normal)
        titleLabel?.sizeToFit()

        titleLabel?.alpha = 0
        setTitle(title, for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setTitle("", for: .normal)
            self.alpha = 1
        }

        setTitleColor(.custom.mediumContrast, for: .normal)

        unreadDot.isHidden = !isUnread

        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleLabel?.font = .systemFont(ofSize: 10.0, weight: .bold)
        contentHorizontalAlignment = .center

        addSubview(unreadDot)

        NSLayoutConstraint.activate([
            unreadDot.widthAnchor.constraint(equalToConstant: 5),
            unreadDot.heightAnchor.constraint(equalToConstant: 5),
            unreadDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            unreadDot.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let widthC = widthAnchor.constraint(greaterThanOrEqualToConstant: 28)
        widthC.priority = .required
        widthC.isActive = true

        let contentPadding = UIEdgeInsets(top: pillVerticalMargin, left: 0, bottom: pillVerticalMargin, right: 0)
        setInsets(forContentPadding: contentPadding, imageTitlePadding: 0)
    }

    override var isSelected: Bool {
        didSet {
            let imageTitleGap = isSelected ? gapBetweenImageAndTitle : 0.0
            let t = isSelected ? itemTitle : ""
            if t != title(for: .normal) {
                setTitle(t, for: .normal)
                titleLabel?.alpha = isSelected ? 1 : 0

                let contentPadding = UIEdgeInsets(top: pillVerticalMargin, left: pillHorizontalMargin, bottom: pillVerticalMargin, right: pillHorizontalMargin)
                setInsets(forContentPadding: contentPadding, imageTitlePadding: imageTitleGap)
            }
        }
    }

    // Larger tap targets
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let biggerFrame = bounds.insetBy(dx: -20, dy: -30)
        return biggerFrame.contains(point)
    }
}

extension AnimatedTabBarItem {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.tintColor = .custom.mediumContrast
                self.setTitleColor(.custom.mediumContrast, for: .normal)
                self.unreadDot.backgroundColor = .custom.mediumContrast
            }
        }
    }
}

private extension UIButton {
    func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
    ) {
        contentEdgeInsets = UIEdgeInsets(
            top: contentPadding.top,
            left: contentPadding.left,
            bottom: contentPadding.bottom,
            right: contentPadding.right + imageTitlePadding
        )
        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageTitlePadding,
            bottom: 0,
            right: -imageTitlePadding
        )
    }
}
