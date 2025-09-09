//
//  TranslationComposeViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 15/07/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import NaturalLanguage
import OrderedCollections
import UIKit

protocol TranslationComposeViewControllerDelegate: AnyObject {
    func didSelectLanguage(language: String)
    func removeLanguage(language: String)
}

class TranslationComposeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableOfContentsSelectionDelegate {
    let btn0 = UIButton(type: .custom)
    let btn1 = UIButton(type: .custom)
    var tableView = UITableView()
    var postText: String = ""
    var langStr: String = Locale.current.languageCode ?? "en"
    var detectedLang: String = "auto"
    var firstSection: OrderedDictionary = ["Afrikaans": "af", "Albanian": "sq", "Amharic": "am", "Arabic": "ar", "Armenian": "hy", "Azerbaijani": "az", "Basque": "eu", "Belarusian": "be", "Bengali": "bn", "Bosnian": "bs", "Bulgarian": "bg", "Catalan": "ca", "Cebuano": "ceb", "Chinese (Simplified)": "zh", "Chinese (Traditional)": "zh-TW", "Corsican": "co", "Croatian": "hr", "Czech": "cs", "Danish": "da", "Dutch": "nl", "English": "en", "Esperanto": "eo", "Estonian": "et", "Finnish": "fi", "French": "fr", "Frisian": "fy", "Galician": "gl", "Georgian": "ka", "German": "de", "Greek": "el", "Gujarati": "gu", "Haitian Creole": "ht", "Hausa": "ha", "Hawaiian": "haw", "Hebrew": "he", "Hindi": "hi", "Hmong": "hmn", "Hungarian": "hu", "Icelandic": ": is", "Igbo": "ig", "Indonesian": "id", "Irish": "ga", "Italian": "it", "Japanese": "ja", "Javanese": "jv", "Kannada": "kn", "Kazakh": "kk", "Khmer": "km", "Kinyarwanda": "rw", "Korean": "ko", "Kurdish": "ku", "Kyrgyz": "ky", "Lao": "lo", "Latin": "la", "Latvian": "lv", "Lithuanian": "lt", "Luxembourgish": "lb", "Macedonian": "mk", "Malagasy": "mg", "Malay": "ms", "Malayalam": "ml", "Maltese": "mt", "Maori": "mi", "Marathi": "mr", "Mongolian": "mn", "Myanmar (Burmese)": "my", "Nepali": "ne", "Norwegian": "no", "Nyanja (Chichewa)": "ny", "Odia (Oriya)": "or", "Pashto": "ps", "Persian": "fa", "Polish": "pl", "Portuguese": "pt", "Punjabi": "pa", "Romanian": "ro", "Russian": "ru", "Samoan": "sm", "Scots Gaelic": "gd", "Serbian": "sr", "Sesotho": "st", "Shona": "sn", "Sindhi": "sd", "Sinhala (Sinhalese)": "si", "Slovak": "sk", "Slovenian": "sl", "Somali": "so", "Spanish": "es", "Sundanese": "su", "Swahili": "sw", "Swedish": "sv", "Tagalog (Filipino)": "tl", "Tajik": "tg", "Tamil": "ta", "Tatar": "tt", "Telugu": "te", "Thai": "th", "Turkish": "tr", "Turkmen": "tk", "Ukrainian": "uk", "Urdu": "ur", "Uyghur": "ug", "Uzbek": "uz", "Vietnamese": "vi", "Welsh": "cy", "Xhosa": "xh", "Yiddish": "yi", "Yoruba": "yo", "Zulu": "zu"]
    var prefLang: [String] = []
    var fromSetLanguage: Bool = false
    var fromEditProfile: Bool = false
    weak var delegate: TranslationComposeViewControllerDelegate?

    let tableOfContentsSelector1 = TableOfContentsSelector()

    override func viewDidLayoutSubviews() {
        tableView.frame = CGRect(x: view.safeAreaInsets.left, y: 0, width: view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right, height: view.bounds.height)

        tableOfContentsSelector1.frame.size.height = tableView.bounds.height
        tableOfContentsSelector1.frame.size.width = 30
        tableOfContentsSelector1.frame.origin.x = tableView.bounds.width - 32
        tableOfContentsSelector1.frame.origin.y = tableView.frame.origin.y
        tableView.tableHeaderView?.frame.size.height = 60

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

    @objc func dismissTap() {
        triggerHapticImpact(style: .light)
        dismiss(animated: true, completion: nil)
    }

    override var keyCommands: [UIKeyCommand]? {
        let closeWindow = UIKeyCommand(input: "w", modifierFlags: [.command], action: #selector(dismissTap))
        closeWindow.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            closeWindow.wantsPriorityOverSystemBehavior = true
        }
        return [closeWindow]
    }

    @objc func removeTap() {
        let currentLanguage = PostLanguages.shared.postLanguage
        delegate?.removeLanguage(language: currentLanguage)
        dismissTap()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint
        if fromEditProfile {
            navigationItem.title = "Default Language"
        } else {
            if fromSetLanguage {
                navigationItem.title = "Set Language"
            } else {
                navigationItem.title = "Translate Post"
            }
        }

        prefLang = Locale.preferredLanguages

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
        let moreButton1 = UIBarButtonItem(customView: btn0)
        navigationItem.setLeftBarButton(moreButton1, animated: true)

        if fromSetLanguage {
            btn1.setTitle("Remove", for: .normal)
            btn1.setTitleColor(UIColor.systemRed, for: .normal)
            btn1.backgroundColor = UIColor.systemRed.withAlphaComponent(0.28)
            btn1.layer.cornerRadius = 14
            btn1.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            btn1.frame = CGRect(x: 0, y: 0, width: 88, height: 28)
            btn1.addTarget(self, action: #selector(removeTap), for: .touchUpInside)
            btn1.accessibilityLabel = "Remove"
            let moreButton1 = UIBarButtonItem(customView: btn1)
            navigationItem.setRightBarButton(moreButton1, animated: true)
        }

        if #available(iOS 15.0, *) {
            self.tableView.allowsFocus = true
        }
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell0")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.layer.masksToBounds = true
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundView = UIView()
        view.addSubview(tableView)
        tableView.reloadData()

        // scrubber
        var tableOfContentsItems1: [TableOfContentsItem] = [.symbol(name: "star.fill", isCustom: false)] + TableOfContentsSelector.alphanumericItems
        if fromSetLanguage || fromEditProfile {
            tableOfContentsItems1 = TableOfContentsSelector.alphanumericItems
        }
        tableOfContentsSelector1.updateWithItems(tableOfContentsItems1)
        tableOfContentsSelector1.font = UIFont.systemFont(ofSize: 11, weight: .light)
        tableOfContentsSelector1.selectionDelegate = self
        view.addSubview(tableOfContentsSelector1)

        if postText != "" || postText != " " {
            let temp = detectedLanguage(for: postText) ?? "auto"
            detectedLang = "\(temp.split(separator: "-").first ?? "auto")"
        }
    }

    func detectedLanguage(for string: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        guard let languageCode = recognizer.dominantLanguage?.rawValue else { return nil }
        return languageCode
    }

    func viewToShowOverlayIn() -> UIView? {
        return navigationController?.view
    }

    func selectedItem(_ item: TableOfContentsItem) {
        switch item {
        case let .letter(letter):
            let ind = Array(firstSection.keys).firstIndex(where: { x -> Bool in
                x.first ?? Character("a") == letter
            })
            if fromSetLanguage || fromEditProfile {
                tableView.scrollToRow(at: IndexPath(row: ind ?? 0, section: 0), at: .top, animated: false)
            } else {
                tableView.scrollToRow(at: IndexPath(row: ind ?? 0, section: 1), at: .top, animated: false)
            }
        case .symbol(_ /* name */, _ /* isCustom */ ):
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        if fromSetLanguage || fromEditProfile {
            return UITableView.automaticDimension
        } else {
            return 52
        }
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if fromSetLanguage || fromEditProfile {
            return nil
        } else {
            if section == 0 {
                let bg = UIView()
                bg.frame = CGRect(x: 0, y: 6, width: view.bounds.width, height: 40)
                let lab = UILabel()
                lab.frame = bg.frame
                lab.text = NSLocalizedString("settings.appearance.translationLang.preferred", comment: "")
                lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
                lab.textColor = UIColor.label
                bg.addSubview(lab)
                return bg
            } else if section == 1 {
                let bg = UIView()
                bg.frame = CGRect(x: 0, y: 6, width: view.bounds.width, height: 40)
                let lab = UILabel()
                lab.frame = bg.frame
                lab.text = NSLocalizedString("settings.appearance.translationLang.all", comment: "")
                lab.font = UIFont.systemFont(ofSize: 24, weight: .bold)
                lab.textColor = UIColor.label
                bg.addSubview(lab)
                return bg
            } else {
                return nil
            }
        }
    }

    func beganSelection() {}

    func endedSelection() {}

    // MARK: TableView

    func numberOfSections(in _: UITableView) -> Int {
        if fromSetLanguage || fromEditProfile {
            return 1
        } else {
            return 2
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fromSetLanguage || fromEditProfile {
            return firstSection.count
        } else {
            if section == 0 {
                return prefLang.count
            } else {
                return firstSection.count
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if fromSetLanguage || fromEditProfile {
            var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell")
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = Array(firstSection.keys)[indexPath.row]
            cell.backgroundColor = .custom.quoteTint
            if fromSetLanguage {
                if PostLanguages.shared.postLanguage == Array(firstSection.values)[indexPath.row] {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
                cell.accessoryType = .none
            }
            if #available(iOS 15.0, *) {
                cell.focusEffect = UIFocusHaloEffect()
            }
            return cell
        } else {
            if indexPath.section == 0 {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell0", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell0")
                cell.textLabel?.numberOfLines = 0

                let temp = prefLang[indexPath.row]
                let temp2 = "\(temp.split(separator: "-").first ?? "en")"
                if let key = firstSection.first(where: { $0.value == temp2 })?.key {
                    cell.textLabel?.text = key
                }

                cell.backgroundColor = .custom.quoteTint
                cell.accessoryType = .none
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
            } else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell")
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = Array(firstSection.keys)[indexPath.row]
                cell.backgroundColor = .custom.quoteTint
                cell.accessoryType = .none
                if #available(iOS 15.0, *) {
                    cell.focusEffect = UIFocusHaloEffect()
                }
                return cell
            }
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if fromEditProfile {
            langStr = Array(firstSection.values)[indexPath.row]
            GlobalStruct.currentPostLang2 = langStr
            dismiss(animated: true, completion: nil)
        } else {
            if fromSetLanguage {
                langStr = Array(firstSection.values)[indexPath.row]
                delegate?.didSelectLanguage(language: langStr)
                dismiss(animated: true, completion: nil)
            } else {
                if indexPath.section == 0 {
                    let temp = prefLang[indexPath.row]
                    let temp2 = "\(temp.split(separator: "-").first ?? "")"
                    langStr = temp2
                    if postText == "" || postText == " " {
                        dismiss(animated: true, completion: nil)
                    } else {
                        translateThis()
                    }
                } else {
                    langStr = Array(firstSection.values)[indexPath.row]
                    if postText == "" || postText == " " {
                        dismiss(animated: true, completion: nil)
                    } else {
                        translateThis()
                    }
                }
            }
        }
    }

    func translateThis() {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        let bodyText = postText
        let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        let unreservedCharset = NSCharacterSet(charactersIn: unreservedChars)
        var trans = bodyText.addingPercentEncoding(withAllowedCharacters: unreservedCharset as CharacterSet)
        trans = trans!.replacingOccurrences(of: "\n\n", with: "%20")
        let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(detectedLang)&tl=\(langStr)&dt=t&q=\(trans!)&ie=UTF-8&oe=UTF-8"
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
                    translatedText = translatedText.removingUrls()
                    if translatedText == "" {
                        translatedText = self.postText
                    }
                    DispatchQueue.main.async {
                        GlobalStruct.tempPostTranslate = translatedText
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "translateAdded"), object: nil)
                        self.dismiss(animated: true, completion: nil)
                    }
                } catch let error as NSError {
                    log.error(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
}
