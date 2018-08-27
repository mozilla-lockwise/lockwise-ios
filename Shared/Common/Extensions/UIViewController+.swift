/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

protocol StatusAlertView {
    func displayTemporaryAlert(_ message: String, timeout: TimeInterval)
}

struct AlertActionButtonConfiguration {
    let title: String
    let tapObserver: AnyObserver<Void>?
    let style: UIAlertAction.Style
    let checked: Bool

    init(title: String, tapObserver: AnyObserver<Void>?, style: UIAlertAction.Style) {
        self.init(title: title, tapObserver: tapObserver, style: style, checked: false)
    }

    init(title: String, tapObserver: AnyObserver<Void>?, style: UIAlertAction.Style, checked: Bool) {
        self.title = title
        self.tapObserver = tapObserver
        self.style = style
        self.checked = checked
    }
}

protocol AlertControllerView {
    func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                title: String?,
                                message: String?,
                                style: UIAlertController.Style)
}

protocol SpinnerAlertView {
    func displaySpinner(_ dismiss: Driver<Void>, bag: DisposeBag, message: String, completionMessage: String)
}

extension UIViewController: StatusAlertView {
    func displayTemporaryAlert(_ message: String, timeout: TimeInterval) {
        if let temporaryAlertView = Bundle.main.loadNibNamed("StatusAlert", owner: self)?.first as? StatusAlert {
            temporaryAlertView.messageLabel.text = message
            self.styleAndCenterAlert(temporaryAlertView)
            self.view.addSubview(temporaryAlertView)

            self.animateAlertIn(temporaryAlertView) { _ in
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: message)
                self.animateAlertOut(temporaryAlertView, delay: timeout)
            }
        }
    }
}

extension UIViewController: AlertControllerView {
    func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                title: String?,
                                message: String?,
                                style: UIAlertController.Style) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)

        for buttonConfig in buttons {
            let action = UIAlertAction(title: buttonConfig.title, style: buttonConfig.style) { _ in
                buttonConfig.tapObserver?.onNext(())
                buttonConfig.tapObserver?.onCompleted()
            }

            action.setValue(buttonConfig.checked, forKey: "checked")

            alertController.addAction(action)
        }

        DispatchQueue.main.async {
            self.present(alertController, animated: !isRunningTest)
        }
    }
}

extension UIViewController: SpinnerAlertView {
    func displaySpinner(_ dismiss: Driver<Void>, bag: DisposeBag, message: String, completionMessage: String) {
        if let spinnerAlertView = Bundle.main.loadNibNamed("SpinnerAlert", owner: self)?.first as? SpinnerAlert {
            self.styleAndCenterAlert(spinnerAlertView)
            self.view.addSubview(spinnerAlertView)

            spinnerAlertView.activityIndicatorView.startAnimating()
            self.animateAlertIn(spinnerAlertView)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: message)

            dismiss
                    .delay(Constant.number.minimumSpinnerHUDTime)
                    .drive(onNext: { _ in
                        UIAccessibility.post(
                                notification: UIAccessibility.Notification.announcement,
                                argument: completionMessage)
                        self.animateAlertOut(spinnerAlertView)
                    })
                    .disposed(by: bag)
        }
    }
}

extension UIViewController {
    fileprivate func styleAndCenterAlert(_ view: UIView) {
        view.layer.cornerRadius = 10.0
        view.clipsToBounds = true
        view.center = CGPoint(
                x: self.view.bounds.width * 0.5,
                y: self.view.bounds.height * Constant.number.displayAlertYPercentage
        )
        view.alpha = 0.0
    }

    fileprivate func animateAlertIn(_ view: UIView, completion: @escaping ((Bool) -> Void) = { _ in }) {
        UIView.animate(
                withDuration: Constant.number.displayAlertFade,
                animations: {
                    view.alpha = Constant.number.displayAlertOpacity
                }, completion: completion)
    }

    fileprivate func animateAlertOut(_ view: UIView, delay: TimeInterval = 0.0) {
        UIView.animate(
                withDuration: Constant.number.displayAlertFade,
                delay: delay,
                animations: {
                    view.alpha = 0.0
                },
                completion: { _ in
                    view.removeFromSuperview()
                })
    }
}

extension UIViewController {
    func preloadView() {
        _ = self.view
    }
}
