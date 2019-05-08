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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = AutofillOnboardingPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

extension AutofillOnboardingView: AutofillOnboardingViewProtocol {
    var skipButtonTapped: Observable<Void> {
        return self.skipButton.rx.tap.asObservable()
    }

    var setupAutofillTapped: Observable<Void> {
        return self.setupAutofillButton.rx.tap.asObservable()
    }
}
