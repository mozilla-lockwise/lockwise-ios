/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol ItemDetailViewProtocol: class {
    var itemId: String { get }
    var passwordRevealed: Bool { get }
    func bind(titleText: Driver<String>)
    func bind(itemDetail: Driver<[ItemDetailSectionModel]>)
}

class ItemDetailPresenter {
    weak var view: ItemDetailViewProtocol?
    private var dataStore: DataStore
    private var itemDetailStore: ItemDetailStore
    private var routeActionHandler: RouteActionHandler
    private var itemDetailActionHandler: ItemDetailActionHandler
    private var disposeBag = DisposeBag()

    lazy private(set) var onPasswordToggle: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            let updatedPasswordReveal = target.view?.passwordRevealed ?? false
            self.itemDetailActionHandler.invoke(.togglePassword(displayed: updatedPasswordReveal))
        }.asObserver()
    }()

    lazy private(set) var onCancel: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(MainRouteAction.list)
        }.asObserver()
    }()

    init(view: ItemDetailViewProtocol,
         dataStore: DataStore = DataStore.shared,
         itemDetailStore: ItemDetailStore = ItemDetailStore.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         itemDetailActionHandler: ItemDetailActionHandler = ItemDetailActionHandler.shared) {
        self.view = view
        self.dataStore = dataStore
        self.itemDetailStore = itemDetailStore
        self.routeActionHandler = routeActionHandler
        self.itemDetailActionHandler = itemDetailActionHandler

        self.itemDetailActionHandler.invoke(.togglePassword(displayed: false))
    }

    func onViewReady() {
        let itemObservable = self.dataStore.onItem(self.view?.itemId ?? "")

        let itemDriver = itemObservable.asDriver(onErrorJustReturn: Item.Builder().build())
        let viewConfigDriver = Driver.combineLatest(itemDriver, self.itemDetailStore.itemDetailDisplay)
                .map { e -> [ItemDetailSectionModel] in
                    if case let .togglePassword(passwordDisplayed) = e.1 {
                        return self.configurationForItem(e.0, passwordDisplayed: passwordDisplayed)
                    }

                    return self.configurationForItem(e.0, passwordDisplayed: false)
                }

        let titleDriver = itemObservable
                .map { item -> String in
                    return item.title ?? item.origins.first ?? Constant.string.unnamedEntry
                }.asDriver(onErrorJustReturn: Constant.string.unnamedEntry)

        self.view?.bind(itemDetail: viewConfigDriver)
        self.view?.bind(titleText: titleDriver)
    }
}

// helpers
extension ItemDetailPresenter {
    private func configurationForItem(_ item: Item, passwordDisplayed: Bool) -> [ItemDetailSectionModel] {
        var passwordText: String
        let itemPassword: String = item.entry.password ?? ""

        if passwordDisplayed {
            passwordText = itemPassword
        } else {
            passwordText = itemPassword.replacingOccurrences(of: "[^\\s]", with: "•", options: .regularExpression)
        }

        var sectionModels = [
            ItemDetailSectionModel(model: 0, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.webAddress,
                        value: item.origins.first ?? "",
                        password: false)
            ]),
            ItemDetailSectionModel(model: 1, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.username,
                        value: item.entry.username ?? "",
                        password: false),
                ItemDetailCellConfiguration(
                        title: Constant.string.password,
                        value: passwordText,
                        password: true)
            ])
        ]

        if let notes = item.entry.notes, !notes.isEmpty {
            let notesSectionModel = ItemDetailSectionModel(model: 2, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.notes,
                        value: notes,
                        password: false)
            ])

            sectionModels.append(notesSectionModel)
        }

        return sectionModels
    }
}
