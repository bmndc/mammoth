//
//  NewPostButton.swift
//  Mammoth
//
//  Created by Riley Howard on 6/16/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

enum NewPostType {
    case newPost // generic new post
    case newMessage // new private message
}

protocol NewPostButtonDelegate: AnyObject {
    func newPostTypeForCurrentViewController() -> NewPostType
    func shouldShowNewPostButton() -> Bool
    func userDefaultKey() -> String
}

extension NewPostButtonDelegate {
    func userDefaultKey() -> String {
        "postButtonLocation"
    }
}

class NewPostButton: UIButton, UIGestureRecognizerDelegate {
    weak var delegate: NewPostButtonDelegate? {
        didSet {
            updateNewPostButtonImage()
        }
    }

    var allowsExtremeLeft = false
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    private let buttonSize = 40.0
    private let normalHorizontalOffset = 20.0
    private let extremeLeadingOffset = -73.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .custom.FABBackground
        clipsToBounds = true

        bringSubviewToFront(imageView!)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressedNB))
        longPressRecognizer.minimumPressDuration = 0.5
        addGestureRecognizer(longPressRecognizer)

        if allowDragging() {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture))
            panGesture.delegate = self
            addGestureRecognizer(panGesture)
        }

        adjustsImageWhenHighlighted = false
        layer.cornerRadius = buttonSize / 2
        addTarget(self, action: #selector(newPostTap), for: .touchUpInside)
        accessibilityLabel = "New Post"

        NotificationCenter.default.addObserver(self, selector: #selector(updatePostPos), name: NSNotification.Name(rawValue: "updatePostPos"), object: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func allowDragging() -> Bool {
        return !(UIDevice.current.userInterfaceIdiom == .phone)
    }

    func installInView(_ installView: UIView, additionalBottomOffset: CGFloat = 0) {
        var buttonPosition = GlobalStruct.PostButtonLocationType.lowerRight

        if allowDragging() {
            if let positionAsInt = UserDefaults.standard.value(forKey: (delegate?.userDefaultKey())!) as? Int {
                if let buttonPosFromDefault = GlobalStruct.PostButtonLocationType(rawValue: positionAsInt) {
                    buttonPosition = buttonPosFromDefault
                }
            }
        }

        installView.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false

        // Setup constraints
        widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        bottomAnchor.constraint(equalTo: installView.bottomAnchor, constant: -additionalBottomOffset - 20).isActive = true

        // Only one of the leading/trailing constraints should be hooked up
        leadingConstraint = leadingAnchor.constraint(equalTo: installView.leadingAnchor, constant: normalHorizontalOffset)
        trailingConstraint = trailingAnchor.constraint(equalTo: installView.trailingAnchor, constant: -normalHorizontalOffset)

        GlobalStruct.postButtonLocation = buttonPosition
        if GlobalStruct.postButtonLocation == .lowerLeft {
            trailingConstraint?.isActive = false
            leadingConstraint?.isActive = true
        } else if GlobalStruct.postButtonLocation == .lowerRight {
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        }
        updateNewPostButtonImage()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePostPos()
    }

    func updateNewPostButtonImage() {
        let hideButton = !(delegate?.shouldShowNewPostButton() ?? true)
        if hideButton {
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0.0
            }, completion: { done in
                if done {
                    self.isHidden = true
                }
            })
        } else {
            let isPrivateMessage = delegate?.newPostTypeForCurrentViewController() == .newMessage
            let imageChar = isPrivateMessage ? "@" : "\u{2b}"
            setImage(FontAwesome.image(fromChar: imageChar, size: 19, weight: .bold).withTintColor(.custom.FABForeground, renderingMode: .alwaysOriginal), for: .normal)
            if UIDevice.current.userInterfaceIdiom == .phone {
                imageEdgeInsets = .init(top: 1.5, left: 0, bottom: 0, right: 0)
            } else {
                if ProcessInfo.processInfo.isiOSAppOnMac {
                    imageEdgeInsets = .init(top: -0.5, left: 0.5, bottom: 0, right: 0)
                } else {
                    imageEdgeInsets = .init(top: 1.5, left: 0.5, bottom: 0, right: 0)
                }
            }
            isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 1.0
            }, completion: { done in
                if done {
                    self.isHidden = false
                }
            })
        }
    }

    @objc func handleGesture(_ sender: UIPanGestureRecognizer) {
        let translation = sender.location(in: superview)
        switch sender.state {
        case .began:
            superview?.bringSubviewToFront(self)
            trailingConstraint?.isActive = false
            leadingConstraint?.isActive = false
        case .changed:
            // move the view with a finger
            center = translation
        case .ended:
            triggerHaptic3Impact()
            // Determine where to land the button
            if translation.x > superview!.bounds.width / 2 {
                GlobalStruct.postButtonLocation = .lowerRight
            } else {
                if allowsExtremeLeft {
                    // Is the x closer to the extremeLeftOffset, or the lower left?
                    let extremeLeftCenterX = extremeLeadingOffset + (buttonSize / 2)
                    let leftCenterX = normalHorizontalOffset + (buttonSize / 2)
                    let midPoint = extremeLeftCenterX + ((leftCenterX - extremeLeftCenterX) / 2)
                    if translation.x < midPoint {
                        GlobalStruct.postButtonLocation = .extremeLeft
                    } else {
                        GlobalStruct.postButtonLocation = .lowerLeft
                    }
                } else {
                    GlobalStruct.postButtonLocation = .lowerLeft
                }
            }
            UserDefaults.standard.set(GlobalStruct.postButtonLocation.rawValue, forKey: (delegate?.userDefaultKey())!)
            updatePostPos()
            UIView.animate(withDuration: 0.75, delay: 0.0, usingSpringWithDamping: 0.52, initialSpringVelocity: 0.52, options: .curveEaseInOut) {
                self.superview?.layoutIfNeeded()
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "setupNav"), object: nil)
        case .cancelled:
            updatePostPos()
        case .failed:
            updatePostPos()
        default:
            break
        }
    }

    @objc func updatePostPos() {
        switch GlobalStruct.postButtonLocation {
        case .extremeLeft:
            // move to first half
            trailingConstraint?.isActive = false
            leadingConstraint?.constant = extremeLeadingOffset
            leadingConstraint?.isActive = true
        case .lowerLeft:
            // move to first half
            trailingConstraint?.isActive = false
            leadingConstraint?.constant = normalHorizontalOffset
            leadingConstraint?.isActive = true
        case .lowerRight:
            // move to second half
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        }
        superview?.setNeedsLayout()
    }

    @objc func longPressedNB(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        if GlobalStruct.drafts.isEmpty {} else {
            triggerHaptic3Impact()
            let vc = ScheduledPostsViewController()
            vc.drafts = GlobalStruct.drafts
            vc.fromComposeButton = true
            let nvc = UINavigationController(rootViewController: vc)
            getTopMostViewController()?.present(nvc, animated: true, completion: nil)
        }
    }

    @objc func newPostTap() {
        triggerHaptic3Impact()
        let newPostViewController = NewPostViewController()
        let isPrivateMessage = delegate?.newPostTypeForCurrentViewController() == .newMessage
        if isPrivateMessage {
            newPostViewController.fromNewDM = true
            newPostViewController.whoCanReply = .direct
        }
        let vc = UINavigationController(rootViewController: newPostViewController)
        vc.isModalInPresentation = true
        getTopMostViewController()?.present(vc, animated: true, completion: nil)
    }
}

// MARK: Appearance changes

extension NewPostButton {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.backgroundColor = .custom.FABBackground
                updateNewPostButtonImage()
            }
        }
    }
}
