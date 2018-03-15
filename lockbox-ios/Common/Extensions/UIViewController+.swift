/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol ErrorView {
    func displayError(_ error: Error)
}

protocol StatusAlertView {
    func displayTemporaryAlert(_ message: String, timeout: TimeInterval)
}

extension UIViewController: ErrorView {
    func displayError(_ error: Error) {
        let alertController = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: Constant.string.ok, style: .cancel)
        alertController.addAction(cancelAction)

        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension UIViewController: StatusAlertView {
    func displayTemporaryAlert(_ message: String, timeout: TimeInterval) {
        guard let temporaryAlertView = Bundle.main.loadNibNamed("StatusAlert", owner: self)?.first as? StatusAlert else { // swiftlint:disable:this line_length
            return
        }

        temporaryAlertView.messageLabel.text = message
        temporaryAlertView.layer.cornerRadius = 10.0
        temporaryAlertView.clipsToBounds = true
        temporaryAlertView.center = CGPoint(
                x: self.view.bounds.width * 0.5,
                y: self.view.bounds.height * Constant.number.displayStatusAlertYPercentage
        )
        temporaryAlertView.alpha = 0.0

        self.view.addSubview(temporaryAlertView)

        UIView.animate(
                withDuration: Constant.number.displayStatusAlertFade,
                animations: {
                    temporaryAlertView.alpha = Constant.number.displayStatusAlertOpacity
                }, completion: { _ in
            UIView.animate(
                    withDuration: Constant.number.displayStatusAlertFade,
                    delay: timeout,
                    animations: {
                        temporaryAlertView.alpha = 0.0
                    },
                    completion: { _ in
                        temporaryAlertView.removeFromSuperview()
                    })
        })

    }
}

extension UIViewController {
    func preloadView() {
        _ = self.view
    }
}
