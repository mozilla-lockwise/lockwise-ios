/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa

class CopyDisplayStore {
    static let shared = CopyDisplayStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let pasteboard: UIPasteboard
    private let _copyDisplay = PublishSubject<CopyField>()

    public var copyDisplay: Driver<CopyField> {
        return _copyDisplay.asDriver(onErrorJustReturn: CopyField.password)
    }

    init(dispatcher: Dispatcher = Dispatcher.shared,
         pasteboard: UIPasteboard = UIPasteboard.general) {
        self.dispatcher = dispatcher
        self.pasteboard = pasteboard

        self.dispatcher.register
                .filterByType(class: CopyAction.self)
                .bind { self.copy($0) }
                .disposed(by: self.disposeBag)
    }

    private func copy(_ action: CopyAction) {
        let expireDate = Date().addingTimeInterval(TimeInterval(Constant.number.copyExpireTimeSecs))

        self.pasteboard.setItems([[UIPasteboard.typeAutomatic: action.text]],
                options: [UIPasteboard.OptionsKey.expirationDate: expireDate])

        self._copyDisplay.onNext(action.field)
    }
}
