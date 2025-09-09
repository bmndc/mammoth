//
//  PostCardPoll.swift
//  Mammoth
//
//  Created by Benoit Nolens on 06/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class PostCardPoll: UIView {
    // MARK: - Properties

    private var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 12.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.layer.borderWidth = 1.0 / UIScreen.main.scale
        stackView.layer.borderColor = UIColor.custom.outlines.cgColor
        stackView.layer.masksToBounds = true
        stackView.layer.cornerRadius = 6
        stackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]

        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 11, leading: 10, bottom: 9, trailing: 10)

        return stackView
    }()

    private var optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .equalSpacing
        stackView.spacing = 12.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var footerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .custom.softContrast
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    private var optionsTrailingConstraints: [NSLayoutConstraint] = []

    private var postCard: PostCardModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        for arrangedSubview in optionsStackView.arrangedSubviews {
            optionsStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        NSLayoutConstraint.deactivate(optionsTrailingConstraints)
        optionsTrailingConstraints = []
    }
}

// MARK: - Setup UI

private extension PostCardPoll {
    func setupUI() {
        isHidden = true
        isOpaque = true
        addSubview(mainStackView)

        mainStackView.addArrangedSubview(optionsStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            optionsStackView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, constant: -(mainStackView.directionalLayoutMargins.leading + mainStackView.directionalLayoutMargins.trailing)),
        ])

        mainStackView.addArrangedSubview(footerLabel)
    }
}

// MARK: - Configuration

extension PostCardPoll {
    func configure(postCard: PostCardModel) {
        self.postCard = postCard

        if let poll = postCard.poll {
            // sanity check if an option was removed
            while poll.options.count < optionsStackView.arrangedSubviews.count {
                optionsStackView.removeArrangedSubview(optionsStackView.arrangedSubviews.last!)
                optionsTrailingConstraints.removeLast()
            }

            // update every poll option.
            for (index, pollOption) in poll.options.enumerated() {
                let data = PostCardPollOption.PollOption(index: index,
                                                         title: pollOption.title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                         percentage: Float(pollOption.votesCount ?? 0) / Float(max(poll.votesCount, 1)),
                                                         isActive: !poll.expired)

                let optionView = PostCardPollOption(option: data, onTap: { [weak self] option in
                    // On vote tap
                    PostActions.onVote(postCard: postCard, choices: [option.index])

                    guard let self else { return }
                    self.updateOnVote(voteOptionIndex: data.index)
                })

                // sanity check if an option was added
                if index < optionsStackView.arrangedSubviews.count {
                    // update poll
                    for (otherIndex, view) in optionsStackView.arrangedSubviews.enumerated() {
                        if let currentOptionView = view as? PostCardPollOption, index == otherIndex {
                            currentOptionView.update(option: data)
                        }
                    }
                } else {
                    optionsStackView.addArrangedSubview(optionView)
                    optionsTrailingConstraints.append(optionView.trailingAnchor.constraint(equalTo: optionsStackView.trailingAnchor))
                }
            }

            NSLayoutConstraint.activate(optionsTrailingConstraints)

            let numOfVotesString = "\(poll.votesCount.withCommas()) vote\(poll.votesCount == 1 ? "" : "s")"
            footerLabel.text = "\(numOfVotesString) • Poll \(readableDate(withDateString: poll.expiresAt ?? ""))"

            isHidden = false
        }
    }

    private func updateOnVote(voteOptionIndex: Int) {
        for (index, view) in optionsStackView.arrangedSubviews.enumerated() {
            if let optionView = view as? PostCardPollOption,
               let poll = postCard?.poll,
               poll.options.count >= index
            {
                let option = poll.options[index]
                // Optimistically add 1 vote to the right poll option for animation
                let data = PostCardPollOption.PollOption(index: index,
                                                         title: option.title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                         percentage: Float((option.votesCount ?? 0) + (voteOptionIndex == index ? 1 : 0)) / Float(poll.votesCount + 1),
                                                         isActive: !poll.expired)

                optionView.update(option: data)
            }
        }
    }

    func onThemeChange() {
        mainStackView.layer.borderColor = UIColor.custom.outlines.cgColor

        for option in optionsStackView.subviews {
            if let option = option as? PostCardPollOption {
                option.onThemeChange()
            }
        }
    }
}

// MARK: - Formatters

private extension PostCardPoll {
    func readableDate(withDateString dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = GlobalStruct.dateFormat
        let date = dateFormatter.date(from: dateString)

        var diff = getMinutesDifferenceFromTwoDates(start: Date(), end: date ?? Date())
        var mVote = "\(diff) minutes"
        var tText = "ends in"
        var tText2 = ""

        if diff == 1 {
            mVote = "\(diff) minute"
        }
        if diff > 60 {
            diff /= 60
            mVote = "\(diff) hours"
            if diff == 1 {
                mVote = "\(diff) hour"
            }
        } else if diff < 0 {
            tText = "ended"
            tText2 = "ago"
            diff *= -1
            mVote = "\(diff) minutes"
            if diff == 1 {
                mVote = "\(diff) minute"
            }
            if diff > 60 {
                diff /= 60
                mVote = "\(diff) hours"
                if diff == 1 {
                    mVote = "\(diff) hour"
                }
                if diff > 24 {
                    diff /= 24
                    mVote = "\(diff) days"
                    if diff == 1 {
                        mVote = "\(diff) day"
                    }
                    if diff > 30 {
                        diff /= 30
                        mVote = "\(diff) months"
                        if diff == 1 {
                            mVote = "\(diff) month"
                        }
                    }
                }
            }
        }

        return "\(tText) \(mVote) \(tText2)"
    }
}

private class PostCardPollOption: UIStackView {
    private var optionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.setTitleColor(.custom.pollBarText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var optionResult: UILabel = {
        let label = UILabel()
        label.textColor = .custom.softContrast
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isOpaque = true
        label.backgroundColor = .custom.background

        return label
    }()

    private var optionBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = .custom.pollBars
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.isUserInteractionEnabled = false
        bar.layer.cornerRadius = 6
        bar.layer.masksToBounds = true
        return bar
    }()

    private var barWidthConstraint: NSLayoutConstraint?

    struct PollOption {
        var index: Int
        var title: String
        var percentage: Float
        var isActive: Bool
    }

    typealias PollOptionTapCallback = (_ option: PollOption) -> Void
    private let option: PollOption?
    private let tapCallback: PollOptionTapCallback?

    init(option: PollOption, onTap: @escaping PollOptionTapCallback) {
        self.option = option
        tapCallback = onTap
        super.init(frame: .zero)
        setupUI()
    }

    override init(frame: CGRect) {
        option = nil
        tapCallback = nil
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 10.0
        isLayoutMarginsRelativeArrangement = true
        translatesAutoresizingMaskIntoConstraints = false

        if let option = option, option.isActive {
            optionButton.addTarget(self, action: #selector(onTapped), for: .touchUpInside)
        } else {
            optionButton.isUserInteractionEnabled = false
        }

        // Don't compress but let siblings fill the space
        optionResult.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        optionResult.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)

        // Set a minimum width to the option result
        optionResult.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true

        optionButton.setTitle(option?.title ?? "", for: .normal)
        optionResult.text = "\(Int((option?.percentage ?? 0) * 100))%"

        optionButton.insertSubview(optionBar, at: 0)
        optionBar.heightAnchor.constraint(equalTo: optionButton.heightAnchor).isActive = true

        barWidthConstraint = optionBar.widthAnchor.constraint(equalTo: optionButton.widthAnchor, multiplier: CGFloat(option?.percentage ?? 0), constant: 0)
        barWidthConstraint?.isActive = true

        NSLayoutConstraint.activate([
            optionBar.centerYAnchor.constraint(equalTo: optionButton.centerYAnchor),
            optionBar.leadingAnchor.constraint(equalTo: optionButton.leadingAnchor),
        ])

        addArrangedSubview(optionButton)
        addArrangedSubview(optionResult)
    }

    func update(option: PollOption) {
        if barWidthConstraint != nil {
            barWidthConstraint?.isActive = false
            barWidthConstraint = nil
        }

        barWidthConstraint = optionBar.widthAnchor.constraint(equalTo: optionButton.widthAnchor, multiplier: CGFloat(option.percentage), constant: 0)
        barWidthConstraint?.isActive = true
        optionResult.text = "\(Int(option.percentage * 100))%"

        UIView.animate(withDuration: 0.5) {
            self.layoutIfNeeded()
        }
    }

    func onThemeChange() {}

    @objc func onTapped() {
        if let option = option, let callback = tapCallback {
            triggerHapticImpact(style: .light)

            let alert = UIAlertController(title: "Vote for '\(option.title)'?",
                                          message: "You cannot change your vote once you have voted.",
                                          preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Vote", style: .default, handler: { _ in
                callback(option)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel, handler: nil))

            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = getTopMostViewController()?.view
                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
            }
            getTopMostViewController()?.present(alert, animated: true, completion: nil)
        }
    }
}
