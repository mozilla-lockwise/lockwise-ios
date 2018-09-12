/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional
import CoreGraphics
import FxAClient

class ItemListPresenter: BaseItemListPresenter {
    weak var view: ItemListViewProtocol? {
        return self.baseView as? ItemListViewProtocol
    }

    override var itemSelectedObserver: AnyObserver<String?> {
        return Binder(self) { target, itemId in
            guard let id = itemId else {
                return
            }

            if let view = target.view {
                view.dismissKeyboard()
            }

            self.dataStore.get(id)
                .take(1)
                .subscribe(onNext: { login in
                    if let login = login {
                        target.dispatcher.dispatch(action: CredentialStatusAction.loginSelected(login: login, relock: false))
                    } else {
                        target.dispatcher.dispatch(action: CredentialStatusAction.userCanceled)
                    }
                })
                .disposed(by: self.disposeBag)
            }.asObserver()
    }
}
