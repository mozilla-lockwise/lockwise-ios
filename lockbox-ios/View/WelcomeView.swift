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
    @IBOutlet internal weak var learnMore: UIButton!
    @IBOutlet internal weak var biometricButton: UIButton!
    @IBOutlet internal weak var biometricTitle: UILabel!
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

    public var biometricButtonPressed: ControlEvent<Void> {
        return self.biometricButton.rx.tap
    }

    public var loginButtonHidden: AnyObserver<Bool> {
        return self.fxASigninButton.rx.isHidden.asObserver()
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

    public var biometricButtonHidden: AnyObserver<Bool> {
        return self.biometricButton.rx.isHidden.asObserver()
    }

    public var biometricButtonTitleHidden: AnyObserver<Bool> {
        return self.biometricTitle.rx.isHidden.asObserver()
    }

    public var biometricButtonTitle: AnyObserver<String?> {
        return self.biometricTitle.rx.text.asObserver()
    }

    public var biometricButtonImageName: AnyObserver<String> {
        return Binder(self) { target, imageName in
            let image = UIImage(named: imageName)
            let tintedImage = image?.tinted(Constant.color.buttonTitleColorOtherState)
            target.biometricButton.setImage(image, for: .normal)
            target.biometricButton.setImage(tintedImage, for: .selected)
            target.biometricButton.setImage(tintedImage, for: .highlighted)
            target.biometricButton.setImage(tintedImage, for: .disabled)
        }.asObserver()
    }
}
