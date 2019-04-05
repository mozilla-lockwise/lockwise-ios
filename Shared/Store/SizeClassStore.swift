/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class SizeClassStore {
    internal let disposeBag = DisposeBag()

    internal let dispatcher: Dispatcher

    static let shared = SizeClassStore()

    private let _shouldDisplaySidebar = ReplaySubject<Bool>.create(bufferSize: 1)

    public var shouldDisplaySidebar: Observable<Bool> {
        return _shouldDisplaySidebar.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher
            .register
            .filterByType(class: SizeClassAction.self)
            .subscribe(onNext: { action in
                switch action {
                case .changed(let traitCollection):
                    self._shouldDisplaySidebar.onNext(traitCollection.horizontalSizeClass == .regular)
                }
            })
            .disposed(by: self.disposeBag)
    }
}
