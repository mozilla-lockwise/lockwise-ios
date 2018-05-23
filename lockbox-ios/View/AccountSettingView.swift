/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxCocoa
import RxSwift

class AccountSettingView: UIViewController {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var unlinkAccountButton: UIButton!

    internal var presenter: AccountSettingPresenter?
    private let disposeBag = DisposeBag()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = AccountSettingPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constant.color.viewBackground
        self.setupUnlinkAccountButton()
        self.setupNavBar()
        self.presenter?.onViewReady()
    }
}

extension AccountSettingView: AccountSettingViewProtocol {
    func bind(avatarImage: Driver<Data>) {
        avatarImage
                .map { data -> UIImage? in
                    return UIImage(data: data)?.circleCrop(borderColor: Constant.color.cellBorderGrey)
                }
                .filterNil()
                .drive(self.avatarImageView.rx.image)
                .disposed(by: self.disposeBag)
    }

    func bind(displayName: Driver<String>) {
        displayName
                .drive(self.usernameLabel.rx.text)
                .disposed(by: self.disposeBag)
    }
}

extension AccountSettingView: UIGestureRecognizerDelegate {
    fileprivate func setupUnlinkAccountButton() {
        self.unlinkAccountButton.addTopBorderWithColor(color: Constant.color.cellBorderGrey, width: 0.5)
        self.unlinkAccountButton.addBottomBorderWithColor(color: Constant.color.cellBorderGrey, width: 0.5)

        if let presenter = self.presenter {
            self.unlinkAccountButton.rx.tap
                    .bind(to: presenter.unLinkAccountTapped)
                    .disposed(by: self.disposeBag)
        }
    }

    fileprivate func setupNavBar() {
        self.navigationItem.title = Constant.string.account
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        let leftButton = UIButton(title: Constant.string.settingsTitle, imageName: "back")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

        if let presenter = self.presenter {
            leftButton.rx.tap
                .bind(to: presenter.onSettingsTap)
                .disposed(by: self.disposeBag)

            self.navigationController?.interactivePopGestureRecognizer?.delegate = self
            self.navigationController?.interactivePopGestureRecognizer?.rx.event
                .map { _ -> Void in
                    return ()
                }
                .bind(to: presenter.onSettingsTap)
                .disposed(by: self.disposeBag)
        }
    }
}
