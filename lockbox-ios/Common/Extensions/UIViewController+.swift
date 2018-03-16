/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift

protocol ErrorView {
    func displayError(_ error: Error)
}

protocol StatusAlertView {
    func displayTemporaryAlert(_ message: String, timeout: TimeInterval)
}

struct OptionSheetButtonConfiguration {
    let title: String
    let tapObserver: AnyObserver<Void>?
    let cancel: Bool
}

protocol OptionSheetView {
    func displayOptionSheet(buttons: [OptionSheetButtonConfiguration], title: String?)
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

extension UIViewController: OptionSheetView {
    func displayOptionSheet(buttons: [OptionSheetButtonConfiguration], title: String?) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        for buttonConfig in buttons {
            let style = buttonConfig.cancel ? UIAlertActionStyle.cancel : UIAlertActionStyle.default
            let action = UIAlertAction(title: buttonConfig.title, style: style) { _ in
                buttonConfig.tapObserver?.onNext(())
                buttonConfig.tapObserver?.onCompleted()
            }

            alertController.addAction(action)
        }

        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
}

extension UIViewController {
    func preloadView() {
        _ = self.view
    }
}
