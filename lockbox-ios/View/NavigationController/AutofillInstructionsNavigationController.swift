/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class AutofillInstructionsNavigationController: UINavigationController {
    convenience init() {
        let welcomeView = UIStoryboard(name: "SetupAutofill", bundle: .main)
            .instantiateViewController(withIdentifier: "autofillinstructions")
        self.init(rootViewController: welcomeView)
    }
}
