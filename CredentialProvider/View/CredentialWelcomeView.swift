/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

class CredentialWelcomeView: UIViewController {
    internal var presenter: CredentialWelcomePresenter?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = CredentialWelcomePresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.onViewReady()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presenter?.onViewAppeared()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

extension CredentialWelcomeView: CredentialWelcomeViewProtocol {}
