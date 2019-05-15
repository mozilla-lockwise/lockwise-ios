/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxDataSources
import RxCocoa

protocol ItemEditorViewProtocol: class {
    var saveTapped: Observable<Void> { get }
    var deleteTapped: Observable<Void> { get }
    var cancelTapped: Observable<Void> { get }
    func bind(itemDetail: Driver<[ItemDetailSectionModel]>)
}

class ItemEditorPresenter {
    weak var view: ItemEditorViewProtocol?

    private let dispatcher: Dispatcher
    private let dataStore: DataStore
    private let itemDetailStore: ItemDetailStore
    private let disposeBag = DisposeBag()

    init(
        view: ItemEditorViewProtocol,
        dispatcher: Dispatcher = .shared,
        dataStore: DataStore = .shared,
        itemDetailStore: ItemDetailStore = .shared
        ) {
        self.view = view
        self.dispatcher = dispatcher
        self.dataStore = dataStore
        self.itemDetailStore = itemDetailStore
    }

    func onViewReady() {
        
    }
}
