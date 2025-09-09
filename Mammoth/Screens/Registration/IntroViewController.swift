//
//  IntroViewController.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 22/12/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class IntroViewController: UIViewController {
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var titleText: UILabel!
    @IBOutlet var descriptionText: UILabel!
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var miniIcon: UIImageView!

    @IBOutlet var tealBox: UIView! // the area available to center the mammoth in
    @IBOutlet var orangeBox: UIView! // vertically centered in the tealBox
    @IBOutlet var yellowBox: UIView! // horizontally centered in orangeBox
    // note that the mammoth trunk is beyond the box

    var fromPlus: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .custom.backgroundTint

        setupUI()
        SignInViewController.loadInstances(isFromSignIn: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let navApp = UINavigationBarAppearance()
        navApp.configureWithOpaqueBackground()
        navApp.backgroundColor = .custom.backgroundTint
        navApp.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold)]
        navigationController?.navigationBar.standardAppearance = navApp
        navigationController?.navigationBar.scrollEdgeAppearance = navApp
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        super.viewDidDisappear(animated)
    }

    func setupUI() {
        titleText.textColor = .custom.highContrast
        descriptionText.textColor = .custom.mediumContrast
        miniIcon.image = miniIcon.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        miniIcon.tintColor = .custom.highContrast

        signUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        signUpButton.setTitleColor(.custom.highContrast, for: .normal)
        signUpButton.backgroundColor = .custom.OVRLYMedContrast
        signUpButton.layer.cornerRadius = 8
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)

        signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        signInButton.setTitleColor(.custom.highContrast, for: .normal)
        signInButton.backgroundColor = .clear
        signInButton.layer.cornerRadius = 8
        signInButton.layer.borderColor = UIColor.custom.OVRLYMedContrast.cgColor
        signInButton.layer.borderWidth = 1
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)

        if !fromPlus {
            closeButton.isHidden = true
        }

        let backItem = UIBarButtonItem()
        backItem.title = "Login"
        navigationItem.backBarButtonItem = backItem

        tealBox.backgroundColor = .clear
        orangeBox.backgroundColor = .clear
        yellowBox.backgroundColor = .clear
    }

    @IBAction func closeTapped(_: Any) {
        triggerHapticImpact(style: .light)
        dismiss(animated: true)
    }

    @objc func signUpTapped() {
        triggerHapticImpact()
        let vc = SignUpViewController()
        vc.isModalInPresentation = true
        navigationController?.pushViewController(vc, animated: true)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    @objc func signInTapped() {
        triggerHapticImpact(style: .light)
        showMastodonSignIn()
    }

    private func showMastodonSignIn() {
        let vc = SignInViewController()
        vc.fromPlus = fromPlus
        navigationController?.pushViewController(vc, animated: true)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func showBlueskySignIn() {
        let vc = BlueskySignInViewController()
        vc.delegate = self
        present(vc, animated: true)
    }
}

extension IntroViewController: BlueskySignInViewControllerDelegate {
    func onSignIn(authResponse: BlueskyAPI.AuthResponse) {
        Task {
            try await AccountsManager.shared
                .addExistingBlueskyAccount(authResponse: authResponse)

            dismiss(animated: false)
        }
    }
}
