/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

protocol ItemListViewProtocol: BaseItemListViewProtocol {
}

class ItemListView: BaseItemListView, ItemListViewProtocol {
    var presenter: ItemListPresenter? {
        return self.basePresenter as? ItemListPresenter
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.onViewReady()
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func createPresenter() -> BaseItemListPresenter {
        return ItemListPresenter(view: self)
    }

    override func styleNavigationBar() {
        super.styleNavigationBar()

        guard let presenter = presenter else {
            return
        }

        let button = self.cancelButton
        button.rx.tap
            .bind(to: presenter.cancelButtonObserver)
            .disposed(by: self.disposeBag)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    override func shouldHidesNavigationBarDuringPresentation() -> Bool {
        return UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad
    }
}

extension ItemListView {
    private var cancelButton: UIButton {
        let button = UIButton(title: Constant.string.cancel, imageName: nil)
        button.titleLabel?.font = .navigationButtonFont
        button.accessibilityIdentifier = "cancel.button"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addConstraint(NSLayoutConstraint(
            item: button,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: 90)
        )
        return button
    }
}
