/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol ItemDetailViewProtocol: class, StatusAlertView {
    var itemId: String { get }
    func bind(titleText: Driver<String>)
    func bind(itemDetail: Driver<[ItemDetailSectionModel]>)
}

let copyableFields = [Constant.string.username, Constant.string.password]

class ItemDetailPresenter {
    weak var view: ItemDetailViewProtocol?
    private var dataStore: DataStore
    private var itemDetailStore: ItemDetailStore
    private var copyDisplayStore: CopyConfirmationDisplayStore
    private var routeActionHandler: RouteActionHandler
    private var dataStoreActionHandler: DataStoreActionHandler
    private var copyActionHandler: CopyActionHandler
    private var itemDetailActionHandler: ItemDetailActionHandler
    private var externalLinkActionHandler: ExternalLinkActionHandler
    private var disposeBag = DisposeBag()

    lazy private(set) var onPasswordToggle: AnyObserver<Bool> = {
        return Binder(self) { target, revealed in
            target.itemDetailActionHandler.invoke(.togglePassword(displayed: revealed))
        }.asObserver()
    }()

    lazy private(set) var onCancel: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(MainRouteAction.list)
        }.asObserver()
    }()

    lazy private(set) var onCellTapped: AnyObserver<String?> = {
        return Binder(self) { target, value in
            guard let value = value else {
                return
            }

            if copyableFields.contains(value) {
                target.dataStore.onItem(self.view?.itemId ?? "")
                        .take(1)
                        .subscribe(onNext: { item in
                            var text = ""
                            if value == Constant.string.username {
                                text = item.entry.username ?? ""
                            } else if value == Constant.string.password {
                                text = item.entry.password ?? ""
                            }

                            target.dataStoreActionHandler.touch(item)
                            target.copyActionHandler.invoke(CopyAction(text: text, fieldName: value))
                        })
                        .disposed(by: target.disposeBag)
            } else if value == Constant.string.webAddress {
                target.dataStore.onItem(self.view?.itemId ?? "")
                        .take(1)
                        .subscribe(onNext: { item in
                            if let origin = item.origins.first {
                                target.externalLinkActionHandler.invoke(ExternalLinkAction(url: origin))
                            }
                        })
                        .disposed(by: target.disposeBag)
            }
        }.asObserver()
    }()

    init(view: ItemDetailViewProtocol,
         dataStore: DataStore = DataStore.shared,
         itemDetailStore: ItemDetailStore = ItemDetailStore.shared,
         copyDisplayStore: CopyConfirmationDisplayStore = CopyConfirmationDisplayStore.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared,
         copyActionHandler: CopyActionHandler = CopyActionHandler.shared,
         itemDetailActionHandler: ItemDetailActionHandler = ItemDetailActionHandler.shared,
         externalLinkActionHandler: ExternalLinkActionHandler = ExternalLinkActionHandler.shared) {
        self.view = view
        self.dataStore = dataStore
        self.itemDetailStore = itemDetailStore
        self.copyDisplayStore = copyDisplayStore
        self.routeActionHandler = routeActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler
        self.copyActionHandler = copyActionHandler
        self.itemDetailActionHandler = itemDetailActionHandler
        self.externalLinkActionHandler = externalLinkActionHandler

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

        self.copyDisplayStore.copyDisplay
                .drive(onNext: { action in
                    let message = String(format: Constant.string.fieldNameCopied, action.fieldName)
                    self.view?.displayTemporaryAlert(message, timeout: Constant.number.displayStatusAlertLength)
                })
                .disposed(by: self.disposeBag)
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
                        password: false,
                        size: 16,
                        valueFontColor: Constant.color.lockBoxBlue)
            ]),
            ItemDetailSectionModel(model: 1, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.username,
                        value: item.entry.username ?? "",
                        password: false,
                        size: 16),
                ItemDetailCellConfiguration(
                        title: Constant.string.password,
                        value: passwordText,
                        password: true,
                        size: 16)
            ])
        ]

        if let notes = item.entry.notes, !notes.isEmpty {
            let notesSectionModel = ItemDetailSectionModel(model: 2, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.notes,
                        value: notes,
                        password: false,
                        size: 14)
            ])

            sectionModels.append(notesSectionModel)
        }

        return sectionModels
    }
}
