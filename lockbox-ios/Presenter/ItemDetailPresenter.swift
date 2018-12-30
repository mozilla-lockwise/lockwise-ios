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
    func enableBackButton(enabled: Bool)
    func bind(titleText: Driver<String>)
    func bind(itemDetail: Driver<[ItemDetailSectionModel]>)
}

let copyableFields = [Constant.string.username, Constant.string.password]

class ItemDetailPresenter {
    weak var view: ItemDetailViewProtocol?
    private var dispatcher: Dispatcher
    private var dataStore: DataStore
    private var itemDetailStore: ItemDetailStore
    private var copyDisplayStore: CopyDisplayStore
    private var tabletHelper: TabletHelper
    private var disposeBag = DisposeBag()

    lazy private(set) var onPasswordToggle: AnyObserver<Bool> = {
        return Binder(self) { target, revealed in
            target.dispatcher.dispatch(action: ItemDetailDisplayAction.togglePassword(displayed: revealed))
        }.asObserver()
    }()

    lazy private(set) var onCancel: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: MainRouteAction.list)
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

                            target.dispatcher.dispatch(action: DataStoreAction.touch(id: itemId))
                            target.dispatcher.dispatch(action: CopyAction(text: text, field: field, itemID: itemId))
                        })
                        .disposed(by: target.disposeBag)
            } else if value == Constant.string.webAddress {
                target.dataStore.get(self.view?.itemId ?? "")
                        .take(1)
                        .subscribe(onNext: { item in
                            if let origin = item?.hostname {
                                target.dispatcher.dispatch(action: ExternalLinkAction(baseURLString: origin))
                            }
                        })
                        .disposed(by: target.disposeBag)
            }
        }.asObserver()
    }()

    init(view: ItemDetailViewProtocol,
         dispatcher: Dispatcher = .shared,
         dataStore: DataStore = DataStore.shared,
         itemDetailStore: ItemDetailStore = ItemDetailStore.shared,
         copyDisplayStore: CopyDisplayStore = CopyDisplayStore.shared,
         tabletHelper: TabletHelper = TabletHelper.shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.dataStore = dataStore
        self.itemDetailStore = itemDetailStore
        self.copyDisplayStore = copyDisplayStore
        self.tabletHelper = tabletHelper

        self.dispatcher.dispatch(action: ItemDetailDisplayAction.togglePassword(displayed: false))
    }

    func onViewReady() {
        let itemObservable = self.dataStore.get(self.view?.itemId ?? "")

        let itemDriver = itemObservable.asDriver(onErrorJustReturn: nil)
        let viewConfigDriver = Driver.combineLatest(itemDriver, self.itemDetailStore.itemDetailDisplay)
                .map { e -> [ItemDetailSectionModel] in
                    if e.0 == nil {
                        return []
                    }

                    if case let .togglePassword(passwordDisplayed) = e.1 {
                        return self.configurationForLogin(e.0, passwordDisplayed: passwordDisplayed)
                    }

                    return self.configurationForLogin(e.0, passwordDisplayed: false)
                }

        let titleDriver = itemObservable
                .map { item -> String in
                    if item == nil {
                        return ""
                    }

                    guard let title = item?.hostname.titleFromHostname() else {
                        return Constant.string.unnamedEntry
                    }

                    return title.isEmpty ? Constant.string.unnamedEntry : title
                }.asDriver(onErrorJustReturn: Constant.string.unnamedEntry)

        self.view?.bind(itemDetail: viewConfigDriver)
        self.view?.bind(titleText: titleDriver)

        self.copyDisplayStore.copyDisplay
                .drive(onNext: { field in
                    let fieldName: String
                    switch field {
                    case .password: fieldName = Constant.string.password
                    case .username: fieldName = Constant.string.username
                    }

                    let message = String(format: Constant.string.fieldNameCopied, fieldName)
                    self.view?.displayTemporaryAlert(message, timeout: Constant.number.displayStatusAlertLength)
                })
                .disposed(by: self.disposeBag)

        self.view?.learnHowToEditTapped
                .subscribe { _ in
                    guard let itemID = self.view?.itemId else {
                        return
                    }

                    self.dispatcher.dispatch(action:
                            ExternalWebsiteRouteAction(
                                    urlString: Constant.app.editExistingEntriesFAQ,
                                    title: Constant.string.faq,
                                    returnRoute: MainRouteAction.detail(itemId: itemID))
                    )
                }
                .disposed(by: self.disposeBag)

        self.view?.enableBackButton(enabled: !tabletHelper.shouldDisplaySidebar)
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

        let hostname = login?.hostname ?? ""
        let username = login?.username ?? ""
        let sectionModels = [
            ItemDetailSectionModel(model: 0, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.webAddress,
                        value: hostname,
                        accessibilityLabel: String(format: Constant.string.websiteCellAccessibilityLabel, hostname),
                        password: false,
                        valueFontColor: Constant.color.lockBoxBlue,
                        accessibilityId: "webAddressItemDetail",
                        showOpenButton: true)
            ]),
            ItemDetailSectionModel(model: 1, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.username,
                        value: username,
                        accessibilityLabel: String(format: Constant.string.usernameCellAccessibilityLabel, username),
                        password: false,
                        accessibilityId: "userNameItemDetail",
                        showCopyButton: true),
                ItemDetailCellConfiguration(
                        title: Constant.string.password,
                        value: passwordText,
                        accessibilityLabel: String(
                            format: Constant.string.passwordCellAccessibilityLabel,
                            passwordText),
                        password: true,
                        accessibilityId: "passwordItemDetail",
                        showCopyButton: true)
            ])
        ]

        return sectionModels
    }
}
