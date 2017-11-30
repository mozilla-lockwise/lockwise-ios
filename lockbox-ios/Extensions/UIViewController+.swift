/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol ErrorView {
    func displayError(_ error:Error) -> Void
}

extension UIViewController : ErrorView {
    func displayError(_ error:Error) -> Void {
        let alertController = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)

        // todo: localization!
        let cancelAction = UIAlertAction(title: "OK", style: .cancel)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
}

extension UIViewController {
    func preloadView() -> Void {
        _ = self.view
    }
}