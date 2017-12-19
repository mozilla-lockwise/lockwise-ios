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
    weak var view:ItemListViewProtocol?
    var dataStore:DataStore!
    private var disposeBag = DisposeBag()

    func onViewReady() {
        self.dataStore.dataStoreLoaded()
                .flatMap { _ in
                    return self.dataStore.open()
                }.flatMap { _ in
                    return self.dataStore.unlock(password: "password")
                }.flatMap { _ in
                    return self.dataStore.list()
                }
                .take(1)
                .asSingle()
                .subscribe(onSuccess: { items in
                    self.view!.displayItems(items)
                }, onError: { error in
                    self.view!.displayError(error)
                })
                .disposed(by: self.disposeBag)
    }
}
