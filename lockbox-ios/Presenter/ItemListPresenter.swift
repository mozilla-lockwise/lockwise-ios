/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

protocol ItemListViewProtocol: class, ErrorView {
    var webView: WebView { get }
    func displayItems(_ items: [Item]) -> Void
}

class ItemListPresenter  {
    private weak var view:ItemListViewProtocol?
    private var dataStoreActionHandler:DataStoreActionHandler
    private var dataStore:DataStore
    private var disposeBag = DisposeBag()

    init(view:ItemListViewProtocol,
         dataStoreActionHandler:DataStoreActionHandler = DataStoreActionHandler.shared,
         dataStore:DataStore = DataStore.shared) {
        self.view = view
        self.dataStoreActionHandler = dataStoreActionHandler
        self.dataStore = dataStore
    }

    func onViewReady() {
        self.dataStore.onItemList
                .debug()
                .subscribe(onNext: { items in
                    self.view?.displayItems(items)
                }, onError: { error in
                    self.view?.displayError(error)
                })
                .disposed(by: self.disposeBag)
    }
}
