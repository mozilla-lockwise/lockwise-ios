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
}
