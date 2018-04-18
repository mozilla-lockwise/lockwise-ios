/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

class BiometryOnboardingView: UIViewController {
    internal var presenter: BiometryOnboardingPresenter?

    @IBOutlet internal weak var biometricImage: UIImageView!
    @IBOutlet internal weak var biometricTitle: UILabel!
    @IBOutlet internal weak var biometricSubTitle: UILabel!
    @IBOutlet internal weak var enableButton: UIButton!
    @IBOutlet internal weak var notNowButton: UIButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = BiometryOnboardingPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.onViewReady()
    }
}

extension BiometryOnboardingView: BiometryOnboardingViewProtocol {
    var enableTapped: Observable<Void> {
        return self.enableButton.rx.tap.asObservable()
    }

    var notNowTapped: Observable<Void> {
        return self.notNowButton.rx.tap.asObservable()
    }

    func setBiometricsImageName(_ name: String) {
        self.biometricImage.image = UIImage(named: name)
    }

    func setBiometricsTitle(_ title: String) {
        self.biometricTitle.text = title
    }

    func setBiometricsSubTitle(_ subTitle: String) {
        self.biometricSubTitle.text = subTitle
    }
}
