/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

class OnboardingConfirmationView: UIViewController {
    internal var presenter: OnboardingConfirmationPresenter?
    @IBOutlet weak var finishButton: UIButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = OnboardingConfirmationPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.finishButton.layer.cornerRadius = 5
        self.finishButton.clipsToBounds = true

        self.presenter?.onViewReady()
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

extension OnboardingConfirmationView: OnboardingConfirmationViewProtocol {
    var finishButtonTapped: Observable<Void> {
        return self.finishButton.rx.tap.asObservable()
    }
}
