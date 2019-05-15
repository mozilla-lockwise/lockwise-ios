/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxDataSources
import RxCocoa
import MozillaAppServices

protocol ItemEditorViewProtocol: class {
    var saveTapped: Observable<Void> { get }
    var deleteTapped: Observable<Void> { get }
    var cancelTapped: Observable<Void> { get }
    var itemDetailObserver: ItemDetailSectionModelObserver { get }
}

class ItemEditorPresenter {
    weak var view: ItemEditorViewProtocol?

    private let dispatcher: Dispatcher
    private let dataStore: DataStore
    private let itemDetailStore: ItemDetailStore
    private let disposeBag = DisposeBag()

    lazy private var onPasswordToggle: AnyObserver<Bool> = {
        return Binder(self) { target, revealed in
            target.dispatcher.dispatch(action: ItemDetailDisplayAction.togglePassword(displayed: revealed))
        }.asObserver()
    }()

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
        let itemObservable = self.dataStore.locked
                .filter { !$0 }
                .take(1)
                .flatMap { _ in self.itemDetailStore.itemDetailId }
                .flatMap { self.dataStore.get($0) }

        let itemDriver = itemObservable.asDriver(onErrorJustReturn: nil)

        Driver.combineLatest(itemDriver.filterNil(), self.itemDetailStore.itemDetailDisplay)
                .map { e -> [ItemDetailSectionModel] in
                    if case let .togglePassword(passwordDisplayed) = e.1 {
                        return self.configurationForLogin(e.0, passwordDisplayed: passwordDisplayed)
                    }

                    return self.configurationForLogin(e.0, passwordDisplayed: false)
                }
                .drive(self.view!.itemDetailObserver)
                .disposed(by: self.disposeBag)
    }
}

extension ItemEditorPresenter {
    private func configurationForLogin(_ login: LoginRecord?, passwordDisplayed: Bool) -> [ItemDetailSectionModel] {
        var passwordText: String
        let itemPassword: String = login?.password ?? ""

        if passwordDisplayed {
            passwordText = itemPassword
        } else {
            passwordText = String(repeating: "•", count: itemPassword.count)
        }

        let hostname = login?.hostname ?? ""
        let username = login?.username ?? ""
        let sectionModels = [
            ItemDetailSectionModel(model: 0, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.name,
                        value: hostname.titleFromHostname(),
                        accessibilityLabel: "",
                        valueFontColor: Constant.color.lockBoxViolet,
                        accessibilityId: "nameItemDetail",
                        showOpenButton: true)
            ]),
            ItemDetailSectionModel(model: 1, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.webAddress,
                        value: hostname,
                        accessibilityLabel: "",
                        valueFontColor: Constant.color.lockBoxViolet,
                        accessibilityId: "webAddressItemDetail",
                        showOpenButton: true)
            ]),
            ItemDetailSectionModel(model: 2, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.username,
                        value: username,
                        accessibilityLabel: "",
                        accessibilityId: "userNameItemDetail",
                        showCopyButton: true),
                ItemDetailCellConfiguration(
                        title: Constant.string.password,
                        value: passwordText,
                        accessibilityLabel: "",
                        accessibilityId: "passwordItemDetail",
                        showCopyButton: true,
                        revealPasswordObserver: self.onPasswordToggle)
            ])
        ]

        return sectionModels
    }
}
