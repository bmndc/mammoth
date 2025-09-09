//
//  QuotePostHostView.swift
//  Mammoth
//
//  Created by Riley Howard on 4/26/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

public let didUpdateQuotePostNotification = Notification.Name("didUpdateQuotePostNotification")

class QuotePostHostView: UIView {
    enum QuotePostType {
        case text
        case image
        case notFound
    }

    let contentStack: UIView = {
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        return content
    }()

    let detailCell: DetailView = .init(isQuotedPostPreview: true)
    let detailImageCell: DetailImageView = .init(isQuotedPostPreview: true)
    let notFoundCell: QuotePostMutedView = .init()
    let loadingIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)

    var currentStatUrl: URL?
    var quotedStatus: Status?
    let overlayButton = UIButton()

    var conditionalConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(contentStack)

        detailCell.translatesAutoresizingMaskIntoConstraints = false
        detailCell.isHidden = true
        contentStack.addSubview(detailCell)

        detailImageCell.translatesAutoresizingMaskIntoConstraints = false
        detailImageCell.isHidden = true
        contentStack.addSubview(detailImageCell)

        notFoundCell.translatesAutoresizingMaskIntoConstraints = false
        notFoundCell.isHidden = true
        contentStack.addSubview(notFoundCell)

        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addSubview(loadingIndicator)

        overlayButton.backgroundColor = UIColor.clear
        overlayButton.addTarget(self, action: #selector(didTapOverlay), for: .touchUpInside)
        contentStack.addSubview(overlayButton)
        overlayButton.translatesAutoresizingMaskIntoConstraints = false
        overlayButton.addFillConstraints(with: self)
        bringSubviewToFront(overlayButton)

        // Constraints
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            contentStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            loadingIndicator.centerXAnchor.constraint(equalTo: contentStack.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentStack.centerYAnchor),
        ])
    }

    func setConstraints(forType type: QuotePostType) {
        NSLayoutConstraint.deactivate(conditionalConstraints)

        switch type {
        case QuotePostType.text:
            conditionalConstraints = [
                detailCell.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
                detailCell.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
                detailCell.topAnchor.constraint(equalTo: contentStack.topAnchor),
                detailCell.bottomAnchor.constraint(equalTo: bottomAnchor),
            ]
        case QuotePostType.image:
            conditionalConstraints = [
                detailCell.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
                detailCell.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
                detailCell.topAnchor.constraint(equalTo: contentStack.topAnchor),

                detailImageCell.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
                detailImageCell.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
                detailImageCell.topAnchor.constraint(equalTo: detailCell.bottomAnchor, constant: 6),
                detailImageCell.bottomAnchor.constraint(equalTo: contentStack.bottomAnchor),
            ]
        case QuotePostType.notFound:
            conditionalConstraints = [
                notFoundCell.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
                notFoundCell.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),
                notFoundCell.topAnchor.constraint(equalTo: contentStack.topAnchor),
                notFoundCell.bottomAnchor.constraint(equalTo: contentStack.bottomAnchor),
            ]
        }

        NSLayoutConstraint.activate(conditionalConstraints)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateForQuotePost(_ qpURL: URL?) {
        // Typical URL: https://moth.social/@bart/110231660759681860

        if let cardURL = qpURL {
            currentStatUrl = cardURL
            StatusCache.shared.cacheStatusForURL(url: cardURL, completion: { url, _stat in
                guard self.currentStatUrl == url else {
                    log.warning("StatusCache: URL changed for view while doing a lookup from:\(self.currentStatUrl?.absoluteString ?? "nil") to:\(url) ")
                    return
                }

                DispatchQueue.main.async {
                    UIView.setAnimationsEnabled(false)

                    if let stat = _stat {
                        self.quotedStatus = stat
                        self.detailCell.isHidden = false
                        self.notFoundCell.isHidden = true
                        self.detailCell.updateFromStat(stat)

                        let showImage = DetailImageCell.willDisplayContentForStat(stat)
                        self.detailImageCell.isHidden = !showImage
                        if showImage {
                            self.detailImageCell.isHidden = false
                            self.detailImageCell.updateFromStat(stat)
                            self.setConstraints(forType: .image)
                        } else {
                            self.detailImageCell.isHidden = true
                            self.setConstraints(forType: .text)
                        }

                        NotificationCenter.default.post(name: didUpdateQuotePostNotification, object: nil)

                    } else {
                        // stat is nil
                        self.notFoundCell.updateFromStat(nil)
                        self.notFoundCell.isHidden = false
                        self.detailCell.isHidden = true
                        self.detailImageCell.isHidden = true
                        self.setConstraints(forType: .notFound)
                    }

                    UIView.setAnimationsEnabled(true)
                    self.loadingIndicator.stopAnimating()
                }
            })
        } else {
            UIView.setAnimationsEnabled(false)
            notFoundCell.isHidden = true
            detailCell.isHidden = true
            detailImageCell.isHidden = true
            UIView.setAnimationsEnabled(true)
            loadingIndicator.stopAnimating()
        }
    }

    @objc func didTapOverlay() {
        if let status = quotedStatus {
            let vc = DetailViewController(post: PostCardModel(status: status))
            findViewController()?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
