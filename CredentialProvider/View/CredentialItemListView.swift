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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.onViewReady()
    }

    override func createPresenter() -> BaseItemListPresenter {
        return ItemListPresenter(view: self)
    }

    override func styleNavigationBar() {
        super.styleNavigationBar()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.cancelButton)

        if let presenter = presenter {
            (self.navigationItem.leftBarButtonItem?.customView as? UIButton)?.rx.tap
                .bind(to: presenter.cancelButtonObserver)
                .disposed(by: self.disposeBag)
        }
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
            constant: 60)
        )
        return button
    }
}
