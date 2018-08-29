/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

class CredentialWelcomeView: UIViewController {
    internal var presenter: CredentialWelcomePresenter?
    @IBOutlet private weak var oceanView: UIImageView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = CredentialWelcomePresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
}

extension CredentialWelcomeView: CredentialWelcomeViewProtocol {}
