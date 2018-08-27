/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

class WelcomeView: BaseWelcomeView {
    @IBOutlet internal weak var fxASigninButton: UIButton!
    @IBOutlet internal weak var accessLockboxMessage: UILabel!
    @IBOutlet internal weak var learnMore: UIButton!
    @IBOutlet internal weak var learnMoreImage: UIImageView!
    @IBOutlet internal weak var lockImage: UIImageView!
    @IBOutlet internal weak var unlockButton: UIButton!
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
        self.roundButtons()
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
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

}

extension WelcomeView: WelcomeViewProtocol {
    public var loginButtonPressed: ControlEvent<Void> {
        return self.fxASigninButton.rx.tap
    }

    public var unlockButtonPressed: ControlEvent<Void> {
        return self.unlockButton.rx.tap
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

    public var firstTimeLearnMoreArrowHidden: AnyObserver<Bool> {
        return self.learnMoreImage.rx.isHidden.asObserver()
    }

    public var lockImageHidden: AnyObserver<Bool> {
        return self.lockImage.rx.isHidden.asObserver()
    }

    public var unlockButtonHidden: AnyObserver<Bool> {
        return self.unlockButton.rx.isHidden.asObserver()
    }
}

extension WelcomeView {
    private func roundButtons() {
        self.fxASigninButton.layer.cornerRadius = 5
        self.fxASigninButton.clipsToBounds = true
        self.unlockButton.layer.cornerRadius = 5
        self.unlockButton.clipsToBounds = true
    }
}
