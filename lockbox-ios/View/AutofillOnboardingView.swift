/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

class AutofillOnboardingView: UIViewController {
    internal var presenter: AutofillOnboardingPresenter?
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var setupAutofillButton: UIButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = AutofillOnboardingPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.onViewReady()
    }
}

extension AutofillOnboardingView: AutofillOnboardingViewProtocol {
    var skipButtonTapped: Observable<Void> {
        return self.skipButton.rx.tap.asObservable()
    }

    var setupAutofillTapped: Observable<Void> {
        return self.setupAutofillButton.rx.tap.asObservable()
    }
}
