/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class AutoLockSettingsView: UITableViewController {
    var presenter: AutoLockSettingsPresenter?

    init() {
        super.init(nibName: nil, bundle: nil)
        self.presenter = AutoLockSettingsPresenter(view: self)
        view.backgroundColor = Constant.color.settingsBackground
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavbar()
    }
}

extension AutoLockSettingsView {
    private func setupNavbar() {
        navigationItem.title = Constant.string.settingsAutoLock
    }
}
