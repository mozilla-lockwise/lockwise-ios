/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Storage

protocol ItemDetailViewProtocol: class, StatusAlertView {
    var itemId: String { get }
    var learnHowToEditTapped: Observable<Void> { get }
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
    private var externalLinkActionHandler: LinkActionHandler
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

            let itemId = target.view?.itemId ?? ""

            if copyableFields.contains(value) {
                target.dataStore.get(itemId)
                        .take(1)
                        .subscribe(onNext: { item in
                            var field = CopyField.username
                            var text = ""
                            if value == Constant.string.username {
                                text = item?.username ?? ""
                                field = CopyField.username
                            } else if value == Constant.string.password {
                                text = item?.password ?? ""
                                field = CopyField.password
                            }

                            target.dataStoreActionHandler.invoke(.touch(id: itemId))
                            target.copyActionHandler.invoke(CopyAction(text: text, field: field, itemID: itemId))
                        })
                        .disposed(by: target.disposeBag)
            } else if value == Constant.string.webAddress {
                target.dataStore.get(self.view?.itemId ?? "")
                        .take(1)
                        .subscribe(onNext: { item in
                            if let origin = item?.hostname {
                                target.externalLinkActionHandler.invoke(ExternalLinkAction(baseURLString: origin))
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
         externalLinkActionHandler: LinkActionHandler = LinkActionHandler.shared) {
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
        let itemObservable = self.dataStore.get(self.view?.itemId ?? "")

        let itemDriver = itemObservable.asDriver(onErrorJustReturn: nil)
        let viewConfigDriver = Driver.combineLatest(itemDriver, self.itemDetailStore.itemDetailDisplay)
                .map { e -> [ItemDetailSectionModel] in
                    if case let .togglePassword(passwordDisplayed) = e.1 {
                        return self.configurationForLogin(e.0, passwordDisplayed: passwordDisplayed)
                    }

                    return self.configurationForLogin(e.0, passwordDisplayed: false)
                }

        let titleDriver = itemObservable
                .map { item -> String in
                    guard let title = item?.hostname.titleFromHostname() else {
                        return Constant.string.unnamedEntry
                    }

                    return title.isEmpty ? Constant.string.unnamedEntry : title
                }.asDriver(onErrorJustReturn: Constant.string.unnamedEntry)

        self.view?.bind(itemDetail: viewConfigDriver)
        self.view?.bind(titleText: titleDriver)

        self.copyDisplayStore.copyDisplay
                .drive(onNext: { action in
                    let fieldName: String
                    switch action.field {
                    case .password: fieldName = Constant.string.password
                    case .username: fieldName = Constant.string.username
                    }

                    let message = String(format: Constant.string.fieldNameCopied, fieldName)
                    self.view?.displayTemporaryAlert(message, timeout: Constant.number.displayStatusAlertLength)
                })
                .disposed(by: self.disposeBag)

        self.view?.learnHowToEditTapped
                .subscribe { _ in
                    self.routeActionHandler.invoke(
                            MainRouteAction.faqLink(urlString: Constant.app.editExistingEntriesFAQ)
                    )
                }
                .disposed(by: self.disposeBag)
    }
}

// helpers
extension ItemDetailPresenter {
    private func configurationForLogin(_ login: Login?, passwordDisplayed: Bool) -> [ItemDetailSectionModel] {
        var passwordText: String
        let itemPassword: String = login?.password ?? ""

        if passwordDisplayed {
            passwordText = itemPassword
        } else {
            passwordText = String(repeating: "•", count: itemPassword.count)
        }

        let sectionModels = [
            ItemDetailSectionModel(model: 0, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.webAddress,
                        value: login?.hostname ?? "",
                        password: false,
                        size: 16,
                        valueFontColor: Constant.color.lockBoxBlue)
            ]),
            ItemDetailSectionModel(model: 1, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.username,
                        value: login?.username ?? "",
                        password: false,
                        size: 16),
                ItemDetailCellConfiguration(
                        title: Constant.string.password,
                        value: passwordText,
                        password: true,
                        size: 16)
            ])
        ]

        return sectionModels
    }
}
