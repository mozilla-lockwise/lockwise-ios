/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa

class OnboardingConfirmationView: UIViewController {
    internal var presenter: OnboardingConfirmationPresenter?
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var encryptionTextView: UITextView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = OnboardingConfirmationPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleButtonsAndText()
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

extension OnboardingConfirmationView: OnboardingConfirmationViewProtocol {
    var finishButtonTapped: Observable<Void> {
        return self.finishButton.rx.tap.asObservable()
    }
}

extension OnboardingConfirmationView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        self.presenter?.onEncryptionLinkTapped()
        return false
    }
}

extension OnboardingConfirmationView {
    private func styleButtonsAndText() {
        self.finishButton.layer.cornerRadius = 5
        self.finishButton.clipsToBounds = true

        if let encryptionText = self.encryptionTextView.text {
            self.encryptionTextView.delegate = self
            let text = NSMutableAttributedString(string: encryptionText)
            let range = text.mutableString.range(of: Constant.string.onboardingSecurityPostfix)
            text.addAttributes([
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)
            ], range: NSMakeRange(0, text.length)) // swiftlint:disable:this legacy_constructor

            text.addAttributes(
                    [
                        NSAttributedString.Key.link: NSString(string: Constant.app.securityFAQ),
                        NSAttributedString.Key.foregroundColor: Constant.color.lockBoxBlue
                    ],
                    range: range
            )

            self.encryptionTextView.attributedText = text
        }
    }
}
