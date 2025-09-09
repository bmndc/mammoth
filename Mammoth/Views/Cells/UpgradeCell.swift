//
//  UpgradeCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 27/11/2023.
//

import ArkanaKeys
import StoreKit
import UIKit

// MARK: - UITableViewCell

final class UpgradeCell: UITableViewCell {
    static let reuseIdentifier = "UpgradeCell"
    var delegate: UpgradeViewDelegate? {
        set {
            rootView.delegate = newValue
        }

        get {
            return rootView.delegate
        }
    }

    let rootView = UpgradeRootView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        contentView.addSubview(rootView)
        rootView.translatesAutoresizingMaskIntoConstraints = false
        rootView.pinEdges()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        rootView.prepareForReuse()
    }

    func configure(expanded: Bool, title: String, featureName: String? = nil) {
        rootView.configure(expanded: expanded, title: title, featureName: featureName)
    }
}

// MARK: - UICollectionViewCell

final class UpgradeItem: UICollectionViewCell {
    static let reuseIdentifier = "UpgradeItem"
    weak var delegate: UpgradeViewDelegate? {
        set {
            rootView.delegate = newValue
        }

        get {
            return rootView.delegate
        }
    }

    private let rootView = UpgradeRootView()
    var parentWidth: CGFloat?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        contentView.addSubview(rootView)
        rootView.translatesAutoresizingMaskIntoConstraints = false
        rootView.pinEdges()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.size = CGSize(width: (parentWidth ?? bounds.width) - 40, height: attributes.size.height)
        return attributes
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        rootView.prepareForReuse()
    }

    func configure(expanded: Bool, title: String, featureName: String? = nil) {
        rootView.configure(expanded: expanded, title: title, featureName: featureName)
    }
}

// MARK: - Root View

protocol UpgradeViewDelegate: AnyObject {
    func onStateChange(state: UpgradeRootView.UpgradeViewState)
}

final class UpgradeRootView: UIView, UpgradeOptionDelegate {
    enum UpgradeViewState {
        case loading
        case unsubscribed
        case subscribed
        case thanks
    }

    private let mainStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: 14, left: 18, bottom: 14, right: 18)
        return stackView
    }()

    private let headerStack = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()

    private let expandedStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 14
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins.bottom = 2
        return stackView
    }()

    private let optionsListStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()

    private let productOptionsStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 14
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .zero
        stackView.layoutMargins.top = 8
        return stackView
    }()

    private let customBackground = {
        let view = GradientBorderView(colors: UIColor.gradients.goldBorder, startPoint: .init(x: 0, y: 0), endPoint: .init(x: 1, y: 1))
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.numberOfLines = 1
        return label
    }()

    private let createOptionLabel: (_ text: String) -> UIStackView = { text in
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 2

        let slash = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        slash.numberOfLines = 1
        slash.text = "/"
        slash.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .heavy)
        stackView.addArrangedSubview(slash)

        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.text = text
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .regular)
        label.numberOfLines = 1

        stackView.addArrangedSubview(label)
        return stackView
    }

    private let descriptionLabel: UILabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.text = NSLocalizedString("settings.gold.community", comment: "")
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    private let actionButton: GradientButton = {
        let button = GradientButton(colors: UIColor.gradients.goldButtonBackground, startPoint: .init(x: 1, y: 0.5), endPoint: .init(x: 0, y: 1))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("settings.gold.upgrade", comment: ""), for: .normal)
        button.setTitleColor(.custom.background, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .bold)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.frame.size.height = 38
        button.contentEdgeInsets = .init(top: 10, left: 17, bottom: 10, right: 17)
        return button
    }()

    private let restoreButton: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .regular)
        label.textAlignment = .center
        label.text = NSLocalizedString("settings.gold.restore", comment: "")
        label.isUserInteractionEnabled = true
        return label
    }()

    private let expandIcon: UILabel = {
        let icon = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        icon.numberOfLines = 1
        icon.text = "+"
        icon.textAlignment = .right
        icon.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .black)
        return icon
    }()

    weak var delegate: UpgradeViewDelegate?

    private let gradientBorder = CAGradientLayer()
    private let gradientBorderShape = CAShapeLayer()
    private let loader = UIActivityIndicatorView(style: .medium)
    private var options: [UpgradeOption] = []
    private var optionsContraints: [NSLayoutConstraint] = []
    private var iapProducts: [SKProduct] = [] {
        didSet {
            if oldValue != iapProducts {
                clearProductOptions()
                setupProductOptions(products: iapProducts)
            }
        }
    }

    var state: UpgradeViewState = IAPManager.isGoldMember ? .subscribed : .loading {
        didSet {
            if oldValue != state {
                configureUIForState(state)
                delegate?.onStateChange(state: state)

                if delegate == nil {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
            }
        }
    }

    private(set) var expanded: Bool = false

    override init(frame _: CGRect) {
        super.init(frame: .zero)
        setupUI()

        let restoreGesture = UITapGestureRecognizer(target: self, action: #selector(onRestorePress))
        restoreButton.addGestureRecognizer(restoreGesture)

        IAPManager.shared.fetchAvailableProductsBlock = { products in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.iapProducts = products
                self.state = IAPManager.isGoldMember ? .subscribed : .unsubscribed
            }
        }

        IAPManager.shared.purchaseStatusBlock = { type in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                switch type {
                case .disabled:
                    AnalyticsManager.track(event: .failedToUpgrade)
                    let alert = UIAlertController(title: NSLocalizedString("error.purchaseError", comment: ""), message: type.message(), preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: UIAlertAction.Style.default, handler: nil))

                    if let presentingVC = getTopMostViewController() {
                        presentingVC.present(alert, animated: true, completion: nil)
                    }
                case let .failed(error):
                    self.state = .unsubscribed
                    AnalyticsManager.track(event: .failedToUpgrade)

                    guard (error as? NSError)?.description.range(of: NSLocalizedString("error.paymentSheet", comment: "")) == nil else { return }

                    let alert = UIAlertController(title: NSLocalizedString("error.purchaseError", comment: ""), message: type.message(), preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: UIAlertAction.Style.default, handler: nil))

                    if let presentingVC = getTopMostViewController() {
                        presentingVC.present(alert, animated: true, completion: nil)
                    }
                case .restored:
                    self.state = .subscribed
                    AnalyticsManager.track(event: .restoredToGold)
                case .purchased:
                    self.state = .thanks
                    AnalyticsManager.track(event: .upgradedToGold)
                }
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        delegate = nil
        setupUIFromSettings()
    }

    func onOptionSelect(planId: String) {
        for option in options {
            if option.planId == planId {
                option.selected = true
            } else {
                option.selected = false
            }
        }
    }

    @objc func onActionButtonPressed() {
        switch state {
        case .unsubscribed:
            state = .loading
            if let selected = options.first(where: { $0.selected })?.planId {
                IAPManager.shared.purchaseProduct(productIdentifier: selected)
            }
        case .thanks, .subscribed:
            openCommunityWebView()
        default:
            break
        }
    }

    private func openCommunityWebView() {
        let userId = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.remoteFullOriginalAcct
        let queryItems = [URLQueryItem(name: "id", value: userId)]
        var communityURLComponents = URLComponents(string: ArkanaKeys.Global().joinCommunityPageURL)!
        communityURLComponents.queryItems = queryItems
        if let communityURL = communityURLComponents.url {
            let vc = WebViewController(url: communityURL.absoluteString)
            if let presentingVC = getTopMostViewController() {
                presentingVC.present(UINavigationController(rootViewController: vc), animated: true)
            }
        } else {
            log.error("unable to generate correct community URL")
        }
    }

    @objc func onRestorePress() {
        state = .loading
        IAPManager.shared.restorePurchase()
    }
}

private extension UpgradeRootView {
    func setupUI() {
        contentMode = .top
        backgroundColor = .clear
        clipsToBounds = true
        backgroundColor = .clear
        layoutMargins = .zero

        addSubview(customBackground)
        addSubview(mainStack)

        mainStack.addArrangedSubview(headerStack)

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(expandIcon)
        headerStack.addArrangedSubview(loader)

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        expandIcon.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        NSLayoutConstraint.activate([
            customBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            customBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            customBackground.topAnchor.constraint(equalTo: topAnchor),
            customBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            mainStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            headerStack.leadingAnchor.constraint(equalTo: mainStack.layoutMarginsGuide.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: mainStack.layoutMarginsGuide.trailingAnchor),
        ])

        expandedStack.addArrangedSubview(descriptionLabel)
        expandedStack.addArrangedSubview(optionsListStack)
        expandedStack.addArrangedSubview(productOptionsStack)

        optionsListStack.addArrangedSubview(createOptionLabel(NSLocalizedString("settings.gold.earlyAccess", comment: "")))
        var appIconBenefit = NSLocalizedString("settings.gold.icons", comment: "")
        if !UIApplication.shared.supportsAlternateIcons {
            appIconBenefit += " (iOS)"
        }
        optionsListStack.addArrangedSubview(createOptionLabel(appIconBenefit))
        optionsListStack.addArrangedSubview(createOptionLabel(NSLocalizedString("settings.gold.support", comment: "")))
        optionsListStack.addArrangedSubview(createOptionLabel(NSLocalizedString("settings.gold.vote", comment: "")))

        mainStack.addArrangedSubview(expandedStack)
        expandedStack.isHidden = true

        expandedStack.addArrangedSubview(actionButton)
        expandedStack.addArrangedSubview(restoreButton)

        NSLayoutConstraint.activate([
            expandedStack.trailingAnchor.constraint(equalTo: mainStack.layoutMarginsGuide.trailingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: expandedStack.layoutMarginsGuide.trailingAnchor),
            restoreButton.trailingAnchor.constraint(equalTo: expandedStack.layoutMarginsGuide.trailingAnchor),
        ])

        actionButton.addTarget(self, action: #selector(onActionButtonPressed), for: .touchUpInside)

        setupUIFromSettings()
        configureUIForState(state)
    }

    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .bold)
    }

    func setupProductOptions(products: [SKProduct]) {
        options = []
        products.forEach { [weak self] product in
            guard let self else { return }
            let isYearly = product.productIdentifier == IAPManager.GOLD_YEAR_PRODUCT_ID

            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .currency
            currencyFormatter.locale = product.priceLocale

            let priceString = currencyFormatter.string(from: product.price)

            let option = UpgradeOption(title: product.localizedTitle,
                                       description: product.localizedDescription,
                                       price: priceString ?? "",
                                       selected: isYearly,
                                       planId: product.productIdentifier,
                                       badge: isYearly ? NSLocalizedString("settings.gold.bestDeal", comment: "") : nil)

            option.delegate = self

            self.options.append(option)
            productOptionsStack.addArrangedSubview(option)

            let c = option.trailingAnchor.constraint(equalTo: expandedStack.layoutMarginsGuide.trailingAnchor)
            c.isActive = true
            self.optionsContraints.append(c)
        }
    }

    func clearProductOptions() {
        for option in options {
            productOptionsStack.removeArrangedSubview(option)
            option.removeFromSuperview()
        }

        options = []

        NSLayoutConstraint.deactivate(optionsContraints)
        optionsContraints = []
    }
}

extension UpgradeRootView {
    func configure(expanded: Bool, title: String, featureName: String?) {
        titleLabel.text = title

        if expanded, IAPManager.shared.iapProducts.isEmpty {
            IAPManager.shared.prepareForUse()
            IAPManager.shared.fetchAvailableProductsBlock = { products in
                DispatchQueue.main.async {
                    self.iapProducts = products
                    self.configure(expanded: expanded, title: title, featureName: featureName)
                }
            }
            return
        }

        expand(expanded)

        if expanded {
            expandIcon.text = "–"
            expandIcon.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .black)
        } else {
            expandIcon.text = featureName ?? "+"

            if featureName != nil {
                expandIcon.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .regular)
            } else {
                expandIcon.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .black)
            }
        }

        configureUIForState(state)
    }

    private func expand(_ expanded: Bool) {
        self.expanded = expanded

        if expanded {
            expandedStack.alpha = 0
            expandedStack.isHidden = false

            UIView.animate(withDuration: 0.12, delay: 0.21) {
                self.expandedStack.alpha = 1
            }
        } else {
            // This needs to be wrapped in DispatchQueue.main.async
            // to prevent an animation glitch
            DispatchQueue.main.async {
                self.expandedStack.alpha = 0
            }
            expandedStack.isHidden = true
        }
    }

    func configureUIForState(_ state: UpgradeViewState) {
        switch state {
        case .loading:
            loader.isHidden = false
            expandIcon.isHidden = true
            loader.hidesWhenStopped = true
            expandedStack.isHidden = true
            loader.startAnimating()
        case .subscribed:
            loader.stopAnimating()
            expandIcon.isHidden = false
            productOptionsStack.isHidden = true
            expandedStack.isHidden = !expanded
            titleLabel.text = NSLocalizedString("settings.gold.active", comment: "")
            descriptionLabel.isHidden = false
            optionsListStack.isHidden = true
            actionButton.setTitle(NSLocalizedString("settings.gold.join", comment: ""), for: .normal)
            restoreButton.isHidden = true
        case .unsubscribed:
            loader.stopAnimating()
            loader.isHidden = true
            expandIcon.isHidden = false
            expandedStack.isHidden = !expanded
            productOptionsStack.isHidden = false
            descriptionLabel.isHidden = true
            optionsListStack.isHidden = false
            actionButton.setTitle(NSLocalizedString("settings.gold.upgrade", comment: ""), for: .normal)
            restoreButton.isHidden = false
        case .thanks:
            loader.stopAnimating()
            expandIcon.isHidden = false
            titleLabel.text = NSLocalizedString("settings.gold.active", comment: "")
            productOptionsStack.isHidden = true
            expandedStack.isHidden = !expanded
            descriptionLabel.isHidden = false
            optionsListStack.isHidden = true
            actionButton.setTitle(NSLocalizedString("settings.gold.join", comment: ""), for: .normal)
            restoreButton.isHidden = true
        }
    }
}

// MARK: - Upgrade Option View

protocol UpgradeOptionDelegate: AnyObject {
    func onOptionSelect(planId: String)
}

final class UpgradeOption: UIView {
    private let customBackground = {
        let view = GradientBorderView(colors: UIColor.gradients.goldBorder, startPoint: .init(x: 1, y: 0), endPoint: .init(x: 0, y: 1))
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 6
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let mainStack: UIStackView = {
        let mainStack = UIStackView()
        mainStack.axis = .horizontal
        mainStack.distribution = .fill
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        return mainStack
    }()

    private let leftColumn: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        return stackView
    }()

    private let titleLabel: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .bold)
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .regular)
        label.numberOfLines = 1
        return label
    }()

    private let priceLabel: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .bold)
        label.numberOfLines = 1
        return label
    }()

    private let badgeLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .heavy)
        label.backgroundColor = .custom.gold
        label.setTitleColor(.custom.background, for: .normal)
        label.layer.cornerRadius = 4
        label.layer.cornerCurve = .continuous
        label.clipsToBounds = true
        label.contentEdgeInsets = .init(top: 1, left: 6, bottom: 0, right: 6)
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let planId: String
    var selected: Bool = false {
        didSet {
            layoutSubviews()
        }
    }

    weak var delegate: UpgradeOptionDelegate?

    private var backgroundColors: [CGColor] {
        if traitCollection.userInterfaceStyle == .dark {
            return [
                UIColor(red: 82.0 / 255.0, green: 61.0 / 255.0, blue: 30.0 / 255.0, alpha: 1.0).cgColor,
                UIColor(red: 109.0 / 255.0, green: 81.0 / 255.0, blue: 38.0 / 255.0, alpha: 1.0).cgColor,
            ]
        } else {
            return [
                UIColor(red: 221.0 / 255.0, green: 175.0 / 255.0, blue: 107.0 / 255.0, alpha: 0.8).cgColor,
                UIColor(red: 238.0 / 255.0, green: 180.0 / 255.0, blue: 92.0 / 255.0, alpha: 0.8).cgColor,
            ]
        }
    }

    init(title: String, description: String, price: String, selected: Bool, planId: String, badge: String? = nil) {
        self.planId = planId
        super.init(frame: .zero)
        self.selected = selected
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()

        titleLabel.text = title
        descriptionLabel.text = description
        priceLabel.text = price

        if let badge {
            badgeLabel.setTitle(badge, for: .normal)
        } else {
            badgeLabel.isHidden = true
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onPress))
        addGestureRecognizer(tapGesture)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.size.height != 0, selected {
            customBackground.backgroundColor = UIColor.gradient(colors: backgroundColors, startPoint: .init(x: 0, y: 1), endPoint: .init(x: 1, y: 0), bounds: customBackground.bounds)
        } else {
            customBackground.backgroundColor = .clear
        }

        if selected, traitCollection.userInterfaceStyle == .light {
            titleLabel.colors = [
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
            ]
            descriptionLabel.colors = [
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
            ]
            priceLabel.colors = [
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
            ]
        } else {
            titleLabel.colors = UIColor.gradients.goldText
            descriptionLabel.colors = UIColor.gradients.goldText
            priceLabel.colors = UIColor.gradients.goldText
        }
    }

    private func setupUI() {
        addSubview(customBackground)
        addSubview(mainStack)

        mainStack.addArrangedSubview(leftColumn)
        layoutMargins = .init(top: 18, left: 16, bottom: 18, right: 16)

        leftColumn.addArrangedSubview(titleLabel)
        leftColumn.addArrangedSubview(descriptionLabel)

        mainStack.addArrangedSubview(priceLabel)

        mainStack.addSubview(badgeLabel)

        NSLayoutConstraint.activate([
            customBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            customBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            customBackground.topAnchor.constraint(equalTo: topAnchor),
            customBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            mainStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),

            badgeLabel.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor, constant: -5),
            badgeLabel.topAnchor.constraint(equalTo: mainStack.topAnchor, constant: -26),
        ])
    }

    @objc func onPress() {
        selected = !selected
        layoutSubviews()
        delegate?.onOptionSelect(planId: planId)
    }
}
