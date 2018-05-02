/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

class WelcomeView: UIViewController {
    internal var presenter: WelcomePresenter?

    @IBOutlet internal weak var fxASigninButton: UIButton!
    @IBOutlet internal weak var accessLockboxMessage: UILabel!
    @IBOutlet internal weak var biometricSignInButton: UIButton!
    @IBOutlet internal weak var fxAButtonTopSpacing: NSLayoutConstraint!
    @IBOutlet internal weak var learnMore: UIButton!

    @IBOutlet private weak var oceanView: UIImageView!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = WelcomePresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.biometricSignInButton.setTitleColor(.white, for: .normal)
        self.biometricSignInButton.setTitleColor(UIColor(white: 1.0, alpha: 0.6), for: .highlighted)
        self.biometricSignInButton.setTitleColor(UIColor(white: 1.0, alpha: 0.6), for: .selected)
        self.biometricSignInButton.tintColor = .white

        self.fxASigninButton.layer.cornerRadius = 5
        self.fxASigninButton.clipsToBounds = true

        self.presenter?.onViewReady()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.oceanView.image = UIImage.createGradientImage(
                frame: self.oceanView.frame,
                colors: [Constant.color.lockBoxTeal, Constant.color.lockBoxBlue],
                locations: [0, 0.85]
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

extension WelcomeView: WelcomeViewProtocol {
    public var loginButtonPressed: ControlEvent<Void> {
        return self.fxASigninButton.rx.tap
    }

    public var biometricSignInButtonPressed: ControlEvent<Void> {
        return self.biometricSignInButton.rx.tap
    }

    public var learnMorePressed: ControlEvent<Void> {
        return self.learnMore.rx.tap
    }

    public var firstTimeLoginMessageHidden: AnyObserver<Bool> {
        return self.accessLockboxMessage.rx.isHidden.asObserver()
    }

    public var firstTimeLearnMoreHidden: AnyObserver<Bool> {
        return self.learnMore.rx.isHidden.asObserver()
    }

    public var biometricAuthenticationPromptHidden: AnyObserver<Bool> {
        return self.biometricSignInButton.rx.isHidden.asObserver()
    }

    public var biometricSignInText: AnyObserver<String?> {
        return self.biometricSignInButton.rx.title().asObserver()
    }

    public var biometricImageName: AnyObserver<String> {
        return Binder(self) { target, imageName in
            let image = UIImage(named: imageName)
            let tintedImage = image?.tinted(UIColor(white: 1.0, alpha: 0.6))

            target.biometricSignInButton.rx.image(for: .normal).onNext(image)
            target.biometricSignInButton.rx.image(for: .highlighted).onNext(tintedImage)
            target.biometricSignInButton.rx.image(for: .selected).onNext(tintedImage)
        }.asObserver()
    }

    public var fxAButtonTopSpace: AnyObserver<CGFloat> {
        return self.fxAButtonTopSpacing.rx.constant.asObserver()
    }
}
