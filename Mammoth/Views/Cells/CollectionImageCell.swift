//
//  CollectionImageCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class CollectionImageCell: UICollectionViewCell {
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = .init()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure() {
        bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            bgImage.frame = CGRect(x: 80, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 220)
        } else {
            #if targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 80, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 220)
            #elseif !targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 80, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100, height: 220)
            #endif
        }
        bgImage.layer.cornerRadius = 10
        contentView.addSubview(bgImage)

        image.layer.borderWidth = 0.4
        image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor

        image.frame.origin.x = 80
        image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100)
        } else {
            #if targetEnvironment(macCatalyst)
                image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100)
            #elseif !targetEnvironment(macCatalyst)
                image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100
            #endif
        }
        image.frame.size.height = 220
        image.backgroundColor = .custom.quoteTint
        image.layer.cornerRadius = 10
        contentView.addSubview(image)

        altTextButton.frame = CGRect(x: 85, y: 190, width: 40, height: 25)
        altTextButton.setTitle("ALT", for: .normal)
        altTextButton.setTitleColor(UIColor.white, for: .normal)
        altTextButton.backgroundColor = .black
        altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        altTextButton.layer.cornerCurve = .continuous
        altTextButton.layer.cornerRadius = 8
        altTextButton.alpha = 0
        altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(altTextButton)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            if point.x > 80 {
                return hitView
            } else {
                return superview?.superview
            }
        } else {
            return nil
        }
    }
}

class CollectionImageCellActivity: UICollectionViewCell {
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = .init()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure() {
        bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            bgImage.frame = CGRect(x: 118, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100 - 38), height: 220)
        } else {
            #if targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 118, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100 - 38), height: 220)
            #elseif !targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 118, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100 - 38, height: 220)
            #endif
        }
        bgImage.layer.cornerRadius = 10
        contentView.addSubview(bgImage)

        image.layer.borderWidth = 0.4
        image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor

        image.frame.origin.x = 118
        image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100) - 38
        } else {
            #if targetEnvironment(macCatalyst)
                image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100) - 38
            #elseif !targetEnvironment(macCatalyst)
                image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100 - 38
            #endif
        }
        image.frame.size.height = 220
        image.backgroundColor = .custom.quoteTint
        image.layer.cornerRadius = 10
        contentView.addSubview(image)

        altTextButton.frame = CGRect(x: 123, y: 190, width: 40, height: 25)
        altTextButton.setTitle("ALT", for: .normal)
        altTextButton.setTitleColor(UIColor.white, for: .normal)
        altTextButton.backgroundColor = .black
        altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        altTextButton.layer.cornerCurve = .continuous
        altTextButton.layer.cornerRadius = 8
        altTextButton.alpha = 0
        altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(altTextButton)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            if point.x > 80 {
                return hitView
            } else {
                return superview?.superview
            }
        } else {
            return nil
        }
    }
}

class CollectionImageCellS: UICollectionViewCell {
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = .init()
    var videoOverlay = UIImageView()
    var duration = UILabel()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure() {
        bgImage.backgroundColor = .custom.quoteTint
        bgImage.frame = CGRect(x: 0, y: 0, width: 66, height: 66)
        bgImage.layer.cornerRadius = 8
        contentView.addSubview(bgImage)

        image.layer.borderWidth = 0.4
        image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor

        image.frame.origin.x = 0
        image.frame.origin.y = 0
        image.frame.size.width = 66
        image.frame.size.height = 66
        image.backgroundColor = .custom.quoteTint
        image.layer.cornerRadius = 8
        contentView.addSubview(image)
    }
}

class CollectionImageCellD: UICollectionViewCell {
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = .init()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()
    var preferredWidth: CGFloat?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure() {
        bgImage.backgroundColor = .custom.quoteTint
        bgImage.layer.cornerRadius = 0
        contentView.addSubview(bgImage)

        image.layer.borderWidth = 0.4
        image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor

        image.frame.origin.x = 0
        image.frame.origin.y = 0
        image.backgroundColor = .custom.quoteTint
        image.layer.cornerRadius = 0
        contentView.addSubview(image)

        let windowFrame = UIApplication.shared.connectedScenes
            .compactMap { scene -> UIWindow? in
                (scene as? UIWindowScene)?.windows.first
            }.first?.frame

        var fullWidth = preferredWidth ?? UIScreen.main.bounds.size.width - 87
        #if targetEnvironment(macCatalyst)
            fullWidth = preferredWidth ?? windowFrame?.size.width ?? 0
        #endif

        #if targetEnvironment(macCatalyst)
            if GlobalStruct.singleColumn {
                bgImage.frame = CGRect(x: 0, y: 0, width: fullWidth, height: 400)
                image.frame.size.width = fullWidth
                image.frame.size.height = 400
            } else {
                bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth), height: 280)
                image.frame.size.width = CGFloat(GlobalStruct.padColWidth)
                image.frame.size.height = 280
            }
        #elseif !targetEnvironment(macCatalyst)
            if UIDevice.current.userInterfaceIdiom == .pad, GlobalStruct.singleColumn, UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
                bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 87, height: 400)
                image.frame.size.width = preferredWidth ?? ((UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 87)
                image.frame.size.height = 400
            } else {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth), height: 280)
                    image.frame.size.width = CGFloat(GlobalStruct.padColWidth)
                } else {
                    bgImage.frame = CGRect(x: 0, y: 0, width: preferredWidth ?? CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width), height: 280)
                    image.frame.size.width = preferredWidth ?? CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width)
                }
                image.frame.size.height = 280
            }
        #endif

        altTextButton.frame = CGRect(x: 5, y: 250, width: 40, height: 25)
        altTextButton.setTitle("ALT", for: .normal)
        altTextButton.setTitleColor(UIColor.white, for: .normal)
        altTextButton.backgroundColor = .black
        altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        altTextButton.layer.cornerCurve = .continuous
        altTextButton.layer.cornerRadius = 8
        altTextButton.alpha = 0
        altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(altTextButton)
    }
}

class CollectionImageCell2: UICollectionViewCell {
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = .init()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure() {
        bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 190)
        } else {
            #if targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 190)
            #elseif !targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100, height: 190)
            #endif
        }
        bgImage.layer.cornerRadius = 0
        contentView.addSubview(bgImage)

        image.layer.borderWidth = 0.4
        image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor

        image.frame.origin.x = 0
        image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100)
        } else {
            #if targetEnvironment(macCatalyst)
                image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 100)
            #elseif !targetEnvironment(macCatalyst)
                image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100
            #endif
        }
        image.frame.size.height = 190
        image.backgroundColor = .custom.quoteTint
        image.layer.cornerRadius = 0
        contentView.addSubview(image)

        altTextButton.frame = CGRect(x: 5, y: 160, width: 40, height: 25)
        altTextButton.setTitle("ALT", for: .normal)
        altTextButton.setTitleColor(UIColor.white, for: .normal)
        altTextButton.backgroundColor = .black
        altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        altTextButton.layer.cornerCurve = .continuous
        altTextButton.layer.cornerRadius = 8
        altTextButton.alpha = 0
        altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(altTextButton)
    }
}

class CollectionImageCell3: UICollectionViewCell {
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = .init()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure() {
        bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 40), height: 190)
        } else {
            #if targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 40), height: 190)
            #elseif !targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40, height: 190)
            #endif
        }
        bgImage.layer.cornerRadius = 0
        contentView.addSubview(bgImage)

        image.layer.borderWidth = 0.4
        image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor

        image.frame.origin.x = 0
        image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 40)
        } else {
            #if targetEnvironment(macCatalyst)
                image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 40)
            #elseif !targetEnvironment(macCatalyst)
                image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40
            #endif
        }
        image.frame.size.height = 190
        image.backgroundColor = .custom.quoteTint
        image.layer.cornerRadius = 0
        contentView.addSubview(image)

        altTextButton.frame = CGRect(x: 5, y: 160, width: 40, height: 25)
        altTextButton.setTitle("ALT", for: .normal)
        altTextButton.setTitleColor(UIColor.white, for: .normal)
        altTextButton.backgroundColor = .black
        altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        altTextButton.layer.cornerCurve = .continuous
        altTextButton.layer.cornerRadius = 8
        altTextButton.alpha = 0
        altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(altTextButton)
    }
}

class CollectionImageCell4: UICollectionViewCell {
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = .init()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var postButton = UIButton()
    var altTextButton = UIButton()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure() {
        var minusDiff: CGFloat = 32
        if (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) > 400 {
            minusDiff = 40
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            minusDiff = 32
        }

        var fullWidth = UIScreen.main.bounds.size.width - 87
        #if targetEnvironment(macCatalyst)
            fullWidth = UIApplication.shared.windows.first?.frame.size.width ?? 0
        #endif

        bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            if GlobalStruct.singleColumn {
                bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(fullWidth) - minusDiff, height: 230)
            } else {
                bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
            }
        } else {
            #if targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
            #elseif !targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - minusDiff, height: 230)
            #endif
        }
        contentView.addSubview(bgImage)

        image.layer.borderWidth = 0.4
        image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor

        image.frame.origin.x = 0
        image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            if GlobalStruct.singleColumn {
                image.frame.size.width = CGFloat(fullWidth) - minusDiff
            } else {
                image.frame.size.width = CGFloat(GlobalStruct.padColWidth) - minusDiff
            }
        } else {
            #if targetEnvironment(macCatalyst)
                image.frame.size.width = CGFloat(GlobalStruct.padColWidth) - minusDiff
            #elseif !targetEnvironment(macCatalyst)
                image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - minusDiff
            #endif
        }
        image.frame.size.height = 230
        image.backgroundColor = .custom.quoteTint
        contentView.addSubview(image)

        altTextButton.frame = CGRect(x: 25, y: 160, width: 40, height: 25)
        altTextButton.setTitle("ALT", for: .normal)
        altTextButton.setTitleColor(UIColor.white, for: .normal)
        altTextButton.backgroundColor = .black
        altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        altTextButton.layer.cornerCurve = .continuous
        altTextButton.layer.cornerRadius = 8
        altTextButton.alpha = 0
        altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(altTextButton)

        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            if GlobalStruct.singleColumn {
                postButton.frame = CGRect(x: 0, y: 0, width: CGFloat(fullWidth) - minusDiff, height: 230)
            } else {
                postButton.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
            }
        } else {
            #if targetEnvironment(macCatalyst)
                postButton.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
            #elseif !targetEnvironment(macCatalyst)
                postButton.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - minusDiff, height: 230)
            #endif
        }
        postButton.backgroundColor = .clear
        postButton.setTitleColor(.white, for: .normal)
        postButton.layer.cornerCurve = .continuous
        postButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        postButton.titleLabel?.textAlignment = .left
        postButton.contentHorizontalAlignment = .left
        postButton.titleLabel?.lineBreakMode = .byTruncatingTail
        postButton.titleLabel?.numberOfLines = 0
        postButton.layer.masksToBounds = true
        postButton.isUserInteractionEnabled = true
        postButton.contentVerticalAlignment = .bottom
        postButton.titleLabel?.numberOfLines = 4
        contentView.addSubview(postButton)
    }
}

class CollectionImageCell5: UICollectionViewCell {
    var bgImage = UIImageView()
    var image = UIImageView()
    let gradient: CAGradientLayer = .init()
    var videoOverlay = UIImageView()
    var duration = UILabel()
    var altTextButton = UIButton()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure() {
        bgImage.backgroundColor = .custom.quoteTint
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 40), height: 240)
        } else {
            #if targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 0, y: 0, width: CGFloat(GlobalStruct.padColWidth - 40), height: 240)
            #elseif !targetEnvironment(macCatalyst)
                bgImage.frame = CGRect(x: 0, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40, height: 240)
            #endif
        }
        bgImage.layer.cornerRadius = 0
        contentView.addSubview(bgImage)

        image.layer.borderWidth = 0.4
        image.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor

        image.frame.origin.x = 0
        image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 40)
        } else {
            #if targetEnvironment(macCatalyst)
                image.frame.size.width = CGFloat(GlobalStruct.padColWidth - 40)
            #elseif !targetEnvironment(macCatalyst)
                image.frame.size.width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40
            #endif
        }
        image.frame.size.height = 240
        image.backgroundColor = .custom.quoteTint
        image.layer.cornerRadius = 0
        contentView.addSubview(image)

        altTextButton.frame = CGRect(x: 5, y: 210, width: 40, height: 25)
        altTextButton.setTitle("ALT", for: .normal)
        altTextButton.setTitleColor(UIColor.white, for: .normal)
        altTextButton.backgroundColor = .black
        altTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        altTextButton.layer.cornerCurve = .continuous
        altTextButton.layer.cornerRadius = 8
        altTextButton.alpha = 0
        altTextButton.accessibilityElementsHidden = true
        contentView.addSubview(altTextButton)
    }
}

class CollectionImageCellIAP: UICollectionViewCell {
    var image = UIImageView()
    var titleText = UILabel()
    let gradient: CAGradientLayer = .init()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func configure(_ tex: String, im: UIImage?) {
        image.layer.cornerCurve = .continuous
        image.layer.cornerRadius = 12
        image.frame.origin.x = 18
        image.frame.origin.y = 0
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            image.frame.size.width = CGFloat(120)
        } else {
            #if targetEnvironment(macCatalyst)
                image.frame.size.width = CGFloat(120)
            #elseif !targetEnvironment(macCatalyst)
                image.frame.size.width = 120
            #endif
        }
        image.frame.size.height = 240
        image.backgroundColor = .custom.quoteTint
        image.layer.masksToBounds = true
        image.image = im ?? UIImage()
        contentView.addSubview(image)

        gradient.frame = CGRect(x: 0, y: 120, width: 120, height: 120)
        gradient.colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.18).cgColor]
        image.layer.addSublayer(gradient)

        titleText.textColor = UIColor.white
        titleText.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleText.textAlignment = .left
        titleText.numberOfLines = 0
        titleText.frame = CGRect(x: 31, y: 10, width: 94, height: 100)
        titleText.text = tex
        titleText.sizeToFit()
        titleText.frame.origin.y = 240 - (titleText.frame.size.height) - 7
        contentView.addSubview(titleText)
    }
}
