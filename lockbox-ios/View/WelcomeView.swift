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

        self.fxASigninButton.layer.cornerRadius = 5
        self.fxASigninButton.clipsToBounds = true

        self.presenter?.onViewReady()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.oceanView.image = UIImage.createGradientImage(
                frame: self.oceanView.frame,
                colors: [Constant.color.lockBoxTeal, Constant.color.lockBoxBlue]
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

    public var firstTimeLoginMessageHidden: AnyObserver<Bool> {
        return self.accessLockboxMessage.rx.isHidden.asObserver()
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

            target.biometricSignInButton.rx.image().onNext(image)
        }.asObserver()
    }

    public var fxAButtonTopSpace: AnyObserver<CGFloat> {
        return self.fxAButtonTopSpacing.rx.constant.asObserver()
    }
}
