//
//  AltTextViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 10/02/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import NaturalLanguage
import UIKit
import Vision

protocol AltTextViewControllerDelegate: AnyObject {
    func didConfirmText(updatedText: String)
}

// This is used for
//      - editing image ALT text
//      - creating/editing list names
//      - creating/editing filter names

// swiftlint:disable:next type_body_length
class AltTextViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SKPhotoBrowserDelegate, UITextViewDelegate {
    let btn0 = UIButton(type: .custom)
    let btn2 = UIButton(type: .custom)
    var tableView = UITableView()
    var canAdd: Bool = false
    var id: String = ""
    var keyHeight: CGFloat = 0
    var currentImage: UIImage = .init()
    var newList: Bool = false
    var newFilter: Bool = false
    var filterId: String = ""
    var editList: String = ""
    var listId: String = ""
    var whichImagesAltText: Int?
    var theAltText: String = ""
    weak var delegate: AltTextViewControllerDelegate?
    private let onClose: (() -> Void)?

    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)

        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp
        navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
            if let x = cell1.altText.text {
                if x != "", x != " " {
                    addAlt(x)
                }
            }
        }

        onClose?()
    }

    @objc func keyboardWillChange(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 4
            keyHeight = CGFloat(keyboardHeight)
        }
    }

    func addAlt(_ altText: String) {
        if editList != "" {
            ListManager.shared.updateListTitle(listId, title: altText) { success in
                if success {
                    self.delegate?.didConfirmText(updatedText: altText)
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                }
            }
        } else {
            if newList {
                ListManager.shared.addList(altText) { _ in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchLists"), object: nil)
                }
            } else {
                if newFilter {
                    let request = FilterPosts.addKeyword(id: filterId, keyword: altText)
                    AccountsManager.shared.currentAccountClient.run(request) { statuses in
                        if let _ = (statuses.value) {
                            DispatchQueue.main.async {
                                print("added keyword")
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "fetchFilters"), object: nil)
                            }
                        }
                    }
                } else {
                    GlobalStruct.mediaEditID = id
                    GlobalStruct.mediaEditDescription = altText
                    let request = Media.updateDescription(description: altText, id: id)
                    AccountsManager.shared.currentAccountClient.run(request) { _ in
                        DispatchQueue.main.async {
                            GlobalStruct.whichImagesAltText.append(self.whichImagesAltText ?? 0)
                            GlobalStruct.altAdded[self.whichImagesAltText ?? 0] = altText
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "updatePostButton"), object: nil)
                            print("added description")
                        }
                    }
                }
            }
        }
    }

    @objc func reloadAll() {
        DispatchQueue.main.async {
            // tints

            let hcText = UserDefaults.standard.value(forKey: "hcText") as? Bool ?? true
            if hcText == true {
                UIColor.custom.mainTextColor = .label
            } else {
                UIColor.custom.mainTextColor = .secondaryLabel
            }
            self.tableView.reloadData()

            // update various elements
            self.view.backgroundColor = .custom.backgroundTint
            let navApp = UINavigationBarAppearance()
            navApp.configureWithOpaqueBackground()
            navApp.backgroundColor = .custom.backgroundTint
            navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
            self.navigationController?.navigationBar.standardAppearance = navApp
            self.navigationController?.navigationBar.scrollEdgeAppearance = navApp
            self.navigationController?.navigationBar.compactAppearance = navApp
            if #available(iOS 15.0, *) {
                self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
            }
            if GlobalStruct.hideNavBars2 {
                self.extendedLayoutIncludesOpaqueBars = true
            } else {
                self.extendedLayoutIncludesOpaqueBars = false
            }

            for cell in self.tableView.visibleCells {
                if let cell = cell as? AltTextMultiCell {
                    cell.backgroundColor = .custom.backgroundTint
                }
            }
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        let closeWindow = UIKeyCommand(input: "w", modifierFlags: [.command], action: #selector(dismissTap))
        closeWindow.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            closeWindow.wantsPriorityOverSystemBehavior = true
        }
        return [closeWindow]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint

        if editList != "" {
            navigationItem.title = NSLocalizedString("list.edit", comment: "")
        } else {
            if newList {
                navigationItem.title = NSLocalizedString("title.newList", comment: "")
            } else {
                if newFilter {
                    navigationItem.title = NSLocalizedString("filters.keywords.add", comment: "")
                } else {
                    navigationItem.title = NSLocalizedString("composer.alt", comment: "")
                }
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        // set up nav bar
        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp
        navigationController?.navigationBar.compactAppearance = navApp
        if #available(iOS 15.0, *) {
            self.navigationController?.navigationBar.compactScrollEdgeAppearance = navApp
        }
        if GlobalStruct.hideNavBars2 {
            extendedLayoutIncludesOpaqueBars = true
        } else {
            extendedLayoutIncludesOpaqueBars = false
        }

        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn0.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn0.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn0.layer.cornerRadius = 14
        btn0.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn0.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn0.addTarget(self, action: #selector(dismissTap), for: .touchUpInside)
        btn0.accessibilityLabel = NSLocalizedString("generic.dismiss", comment: "")
        let moreButton0 = UIBarButtonItem(customView: btn0)
        navigationItem.setLeftBarButton(moreButton0, animated: true)

        btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
        btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        btn2.layer.cornerRadius = 14
        btn2.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        btn2.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        btn2.addTarget(self, action: #selector(addTap), for: .touchUpInside)
        btn2.accessibilityLabel = "Add Image Description"
        let moreButton1 = UIBarButtonItem(customView: btn2)
        navigationItem.setRightBarButton(moreButton1, animated: true)

        // set up table
        setupTable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
            cell1.charCount.text = "1000"
            if theAltText != "" {
                cell1.charCount.text = "\(1000 - theAltText.count)"
                // Resize the cell now that is has data
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            cell1.altText.becomeFirstResponder()
        }
    }

    func scrollViewDidScroll(_: UIScrollView) {
        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
            cell1.altText.resignFirstResponder()
        }
    }

    @objc func addTap() {
        if canAdd {
            // add alt text
            triggerHapticImpact(style: .light)
            dismiss(animated: true, completion: nil)
        }
    }

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        dismiss(animated: true, completion: nil)
    }

    func setupTable() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(AltTextMultiCell.self, forCellReuseIdentifier: "AltTextMultiCell")
        tableView.register(ImagePreviewCell.self, forCellReuseIdentifier: "ImagePreviewCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.alpha = 1
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        view.addSubview(tableView)
    }

    func numberOfSections(in _: UITableView) -> Int {
        if editList != "" {
            return 1
        } else {
            if newList {
                return 1
            } else {
                if newFilter {
                    return 1
                } else {
                    return 3
                }
            }
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if editList != "" {
            // Editing an existing list name
            let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell

            cell.altText.placeholder = NSLocalizedString("list.editTitle.placeholder", comment: "")
            cell.altText.accessibilityLabel = NSLocalizedString("list.editTitle.placeholder", comment: "")
            cell.altText.delegate = self
            cell.altText.text = editList

            cell.altText.tag = indexPath.section

            cell.separatorInset = .zero
            let bgColorView = UIView()
            bgColorView.backgroundColor = .clear
            cell.selectedBackgroundView = bgColorView
            cell.backgroundColor = .custom.quoteTint
            return cell
        } else {
            if newList {
                // Creating a new list name
                let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell

                cell.altText.placeholder = NSLocalizedString("list.new.placeholder", comment: "")
                cell.altText.accessibilityLabel = NSLocalizedString("list.new.placeholder", comment: "")
                cell.altText.delegate = self

                cell.altText.tag = indexPath.section

                cell.separatorInset = .zero
                let bgColorView = UIView()
                bgColorView.backgroundColor = .clear
                cell.selectedBackgroundView = bgColorView
                cell.backgroundColor = .custom.quoteTint
                return cell
            } else {
                if newFilter {
                    // Creating a new filter
                    let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell

                    cell.altText.placeholder = NSLocalizedString("filters.keywords.placeholder", comment: "")
                    cell.altText.accessibilityLabel = NSLocalizedString("filters.keywords.placeholder", comment: "")
                    cell.altText.delegate = self

                    cell.altText.tag = indexPath.section

                    cell.separatorInset = .zero
                    let bgColorView = UIView()
                    bgColorView.backgroundColor = .clear
                    cell.selectedBackgroundView = bgColorView
                    cell.backgroundColor = .custom.quoteTint
                    return cell
                } else {
                    // Editing an image's Alt text
                    if indexPath.section == 0 {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "AltTextMultiCell", for: indexPath) as! AltTextMultiCell

                        cell.altText.placeholder = NSLocalizedString("composer.alt.placeholder", comment: "")
                        cell.altText.accessibilityLabel = NSLocalizedString("composer.alt.placeholder", comment: "")
                        cell.altText.delegate = self

                        cell.altText.tag = indexPath.section
                        cell.altText.clipsToBounds = false

                        cell.separatorInset = .zero
                        let bgColorView = UIView()
                        bgColorView.backgroundColor = .clear
                        cell.selectedBackgroundView = bgColorView
                        cell.backgroundColor = .custom.quoteTint

                        cell.altText.text = theAltText
                        return cell
                    } else if indexPath.section == 1 {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "ImagePreviewCell", for: indexPath) as! ImagePreviewCell

                        cell.image.image = currentImage

                        cell.separatorInset = .zero
                        let bgColorView = UIView()
                        bgColorView.backgroundColor = .clear
                        cell.selectedBackgroundView = bgColorView
                        cell.backgroundColor = .custom.quoteTint
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)

                        cell.textLabel?.text = NSLocalizedString("composer.alt.detect", comment: "")
                        cell.textLabel?.textColor = UIColor.label
                        cell.textLabel?.textAlignment = .center
                        cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)

                        cell.separatorInset = .zero
                        let bgColorView = UIView()
                        bgColorView.backgroundColor = .custom.baseTint.withAlphaComponent(0.2)
                        cell.selectedBackgroundView = bgColorView
                        cell.backgroundColor = .custom.quoteTint
                        return cell
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            var images = [SKPhoto]()
            if let cell = self.tableView.cellForRow(at: indexPath) as? ImagePreviewCell {
                if let originImage = cell.image.image {
                    let photo = SKPhoto.photoWithImage(currentImage)
                    photo.shouldCachePhotoURLImage = true
                    images.append(photo)
                    let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: "", imageText2: 0, imageText3: 0, imageText4: "")
                    browser.delegate = self
                    SKPhotoBrowserOptions.enableSingleTapDismiss = false
                    SKPhotoBrowserOptions.displayCounterLabel = false
                    SKPhotoBrowserOptions.displayBackAndForwardButton = false
                    SKPhotoBrowserOptions.displayAction = false
                    SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                    SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                    SKPhotoBrowserOptions.displayCloseButton = false
                    SKPhotoBrowserOptions.displayStatusbar = false
                    browser.initializePageIndex(0)
                    getTopMostViewController()?.present(browser, animated: true, completion: {})
                }
            }
        }
        if indexPath.section == 2 {
            tableView.deselectRow(at: indexPath, animated: true)
            translateThis()
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        tableView.beginUpdates()

        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: textView.tag)) as? AltTextMultiCell {
            cell.charCount.text = "\(1000 - (cell.altText.text?.count ?? 0))"
        }

        if let cell1 = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
            let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
            if cell1.altText.text != "" {
                canAdd = true
                btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.custom.activeInverted, renderingMode: .alwaysOriginal), for: .normal)
                btn2.backgroundColor = .custom.active
            } else {
                canAdd = false
                btn2.setImage(UIImage(systemName: "checkmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal), for: .normal)
                btn2.backgroundColor = UIColor.label.withAlphaComponent(0.08)
            }
        }
        tableView.endUpdates()
    }

    func translateThis() {
        guard let img = currentImage.cgImage else {
            return
        }
        let requestHandler = VNImageRequestHandler(cgImage: img, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            var str = ""
            for observation in observations {
                let topCandidate: [VNRecognizedText] = observation.topCandidates(1)
                if let recognizedText: VNRecognizedText = topCandidate.first {
                    let mess = recognizedText.string
                    str = "\(str) \(mess)"
                }
            }
            let stat = str
            let unreserved = "-._~/?"
            let allowed = NSMutableCharacterSet.alphanumeric()
            allowed.addCharacters(in: unreserved)
            let bodyText = stat
            let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
            let unreservedCharset = NSCharacterSet(charactersIn: unreservedChars)
            var trans = bodyText.addingPercentEncoding(withAllowedCharacters: unreservedCharset as CharacterSet)
            trans = trans!.replacingOccurrences(of: "\n\n", with: "%20")
            var detectedLang = "auto"
            if bodyText != "" || bodyText != " " {
                let temp = self.detectedLanguage(for: bodyText) ?? "auto"
                detectedLang = "\(temp.split(separator: "-").first ?? "auto")"
            }
            let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(detectedLang)&tl=\(GlobalStruct.langStr)&dt=t&q=\(trans!)&ie=UTF-8&oe=UTF-8"
            guard let requestUrl = URL(string: urlString) else {
                return
            }
            let request = URLRequest(url: requestUrl)
            let task = URLSession.shared.dataTask(with: request) {
                data, _, error in
                if error == nil, let usableData = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: usableData, options: .mutableContainers) as! [Any]
                        var translatedText = ""
                        for i in json[0] as! [Any] {
                            translatedText += ((i as! [Any])[0] as? String ?? "")
                        }
                        if translatedText == "" {
                            translatedText = "No text to translate."
                        }
                        DispatchQueue.main.async { [weak self] in
                            if let cell1 = self?.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? AltTextMultiCell {
                                cell1.altText.text = translatedText
                                self?.textViewDidChange(cell1.altText)
                            }
                        }
                    } catch let error as NSError {
                        log.error(error.localizedDescription)
                    }
                }
            }
            task.resume()
        }
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        try? requestHandler.perform([request])
    }

    func detectedLanguage(for string: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        guard let languageCode = recognizer.dominantLanguage?.rawValue else { return nil }
        return languageCode
    }

    func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            if newList {
                return NSLocalizedString("list.new.footer", comment: "")
            } else {
                if newFilter {
                    return NSLocalizedString("filters.keywords.footer", comment: "")
                } else {
                    return nil
                }
            }
        } else if section == 1 {
            return NSLocalizedString("composer.alt.footer1", comment: "")
        } else {
            return NSLocalizedString("composer.alt.footer2", comment: "")
        }
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}
