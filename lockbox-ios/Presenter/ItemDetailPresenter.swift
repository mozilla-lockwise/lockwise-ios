/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Sync15Logins

protocol ItemDetailViewProtocol: class, StatusAlertView {
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
    private var sizeClassStore: SizeClassStore
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

            target.itemDetailStore.itemDetailId
                .take(1)
                .flatMap { target.dataStore.get($0) }
                .map { item -> [Action] in
                    var actions: [Action] = []
                    if copyableFields.contains(value) {
                        if let item = item {
                            actions.append(DataStoreAction.touch(id: item.guid))
                            actions.append(ItemDetailPresenter.getCopyActionFor(item, value: value, actionType: .tap))
                        }
                    } else if value == Constant.string.webAddress {
                        if let origin = item?.hostname {
                            actions.append(ExternalLinkAction(baseURLString: origin))
                        }
                    }
                    return actions
                }
                .subscribe(onNext: { actions in
                    for action in actions {
                        target.dispatcher.dispatch(action: action)
                    }
                })
                .disposed(by: target.disposeBag)
        }.asObserver()
    }()

    init(view: ItemDetailViewProtocol,
         dispatcher: Dispatcher = .shared,
         dataStore: DataStore = DataStore.shared,
         itemDetailStore: ItemDetailStore = ItemDetailStore.shared,
         copyDisplayStore: CopyDisplayStore = CopyDisplayStore.shared,
         sizeClassStore: SizeClassStore = SizeClassStore.shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.dataStore = dataStore
        self.itemDetailStore = itemDetailStore
        self.copyDisplayStore = copyDisplayStore
        self.sizeClassStore = sizeClassStore

        self.dispatcher.dispatch(action: ItemDetailDisplayAction.togglePassword(displayed: false))
    }

    func onViewReady() {
        let itemObservable = self.itemDetailStore.itemDetailId
            .flatMap { self.dataStore.get($0) }

        let itemDriver = itemObservable.asDriver(onErrorJustReturn: nil)
        let viewConfigDriver = Driver.combineLatest(itemDriver.filterNil(), self.itemDetailStore.itemDetailDisplay)
                .map { e -> [ItemDetailSectionModel] in
                    if case let .togglePassword(passwordDisplayed) = e.1 {
                        return self.configurationForLogin(e.0, passwordDisplayed: passwordDisplayed)
                    }

                    return self.configurationForLogin(e.0, passwordDisplayed: false)
                }

        let titleDriver = itemObservable
                .filterNil()
                .map { item -> String in
                    let title = item.hostname.titleFromHostname()
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
            .flatMap({ _ -> Observable<String> in
                return self.itemDetailStore.itemDetailId
            })
            .take(1)
            .map({ (itemId) -> Action in
                return ExternalWebsiteRouteAction(
                    urlString: Constant.app.editExistingEntriesFAQ,
                    title: Constant.string.faq,
                    returnRoute: MainRouteAction.detail(itemId: itemId))
            })
            .subscribe(onNext: { (action) in
                self.dispatcher.dispatch(action: action)
            })
            .disposed(by: self.disposeBag)

        self.sizeClassStore.shouldDisplaySidebar
            .subscribe(onNext: { (enableSidebar) in
                self.view?.enableBackButton(enabled: !enableSidebar)
            })
            .disposed(by: self.disposeBag)
    }

    func dndStarted(value: String?) {
        self.itemDetailStore.itemDetailId
            .take(1)
            .flatMap { self.dataStore.get($0) }
            .take(1)
            .flatMap { item -> Observable<[Action]> in
                var actions: [Action] = []
                if let item = item {
                    actions.append(DataStoreAction.touch(id: item.guid))
                    actions.append(ItemDetailPresenter.getCopyActionFor(item, value: value, actionType: .dnd))
                }

                return Observable.just(actions)
            }.subscribe(onNext: { actions in
                for action in actions {
                    self.dispatcher.dispatch(action: action)
                }
            }).disposed(by: self.disposeBag)
    }
}

// helpers
extension ItemDetailPresenter {
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
                        title: Constant.string.webAddress,
                        value: hostname,
                        accessibilityLabel: String(format: Constant.string.websiteCellAccessibilityLabel, hostname),
                        password: false,
                        valueFontColor: Constant.color.lockBoxBlue,
                        accessibilityId: "webAddressItemDetail",
                        showOpenButton: true,
                        dragValue: hostname)
            ]),
            ItemDetailSectionModel(model: 1, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.username,
                        value: username,
                        accessibilityLabel: String(format: Constant.string.usernameCellAccessibilityLabel, username),
                        password: false,
                        accessibilityId: "userNameItemDetail",
                        showCopyButton: true,
                        dragValue: username),
                ItemDetailCellConfiguration(
                        title: Constant.string.password,
                        value: passwordText,
                        accessibilityLabel: String(
                            format: Constant.string.passwordCellAccessibilityLabel,
                            passwordText),
                        password: true,
                        accessibilityId: "passwordItemDetail",
                        showCopyButton: true,
                        dragValue: login?.password)
            ])
        ]

        return sectionModels
    }

    private static func getCopyActionFor(_ item: Login?, value: String?, actionType: CopyActionType) -> CopyAction {
        var field = CopyField.username
        var text = ""
        if value == Constant.string.username {
            text = item?.username ?? ""
            field = CopyField.username
        } else if value == Constant.string.password {
            text = item?.password ?? ""
            field = CopyField.password
        }

        return CopyAction(text: text, field: field, itemID: item?.guid ?? "", actionType: actionType)
    }
}
