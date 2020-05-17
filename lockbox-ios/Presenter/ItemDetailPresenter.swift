/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import MozillaAppServices

protocol ItemDetailViewProtocol: class, StatusAlertView, AlertControllerView {
    func enableSwipeNavigation(enabled: Bool)
    func enableLargeTitle(enabled: Bool)
    var cellTapped: Observable<String?> { get }
    var deleteTapped: Observable<Void> { get }
    var rightBarButtonTapped: Observable<Void> { get }
    var leftBarButtonTapped: Observable<Void> { get }
    var itemDetailObserver: ItemDetailSectionModelObserver { get }
    var titleText: AnyObserver<String?> { get }
    var rightButtonText: AnyObserver<String?> { get }
    var leftButtonText: AnyObserver<String?> { get }
    var leftButtonIcon: AnyObserver<UIImage?> { get }
    var deleteHidden: AnyObserver<Bool> { get }
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
    
    var savedLoginInfo: [String: String?] = ["username": nil, "password": nil]

    lazy private(set) var onPasswordToggle: AnyObserver<Bool> = {
        return Binder(self) { target, revealed in
            target.dispatcher.dispatch(action: ItemDetailDisplayAction.togglePassword(displayed: revealed))
        }.asObserver()
    }()

    lazy private(set) var onRightSwipe: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: MainRouteAction.list)
        }.asObserver()
    }()

    lazy private var discardChangesObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            let PasswordIndexPath = IndexPath(item: 1, section: 1)
            
            self.updateCellOnDiscard(value: self.savedLoginInfo["username"],
                                forIndexPath: IndexPath(item: 0, section: 1))
            self.updateCellOnDiscard(value: self.savedLoginInfo["password"],
                                forIndexPath: IndexPath(item: 1, section: 1))
            target.dispatcher.dispatch(action: ItemDetailDisplayAction.viewMode)
        }.asObserver()
    }()
    
    private func updateCellOnDiscard(value: String??, forIndexPath: IndexPath) {
        if let view: ItemDetailView = self.view as? ItemDetailView {
            guard let tableView = view.tableView else { return }
            guard let cell: ItemDetailCell = tableView.cellForRow(at: forIndexPath) as? ItemDetailCell else { return }
            guard let value = value else { return }
            cell.textValue.text = value
        }
    }

    lazy private var usernameObserver: AnyObserver<String?> = {
        return Binder(self) { target, val in
            if let val = val {
                if let _: String = self.savedLoginInfo["username"] as? String {}
                else { self.savedLoginInfo["username"] = val }
                target.dispatcher.dispatch(action: ItemEditAction.editUsername(value: val))
            }
        }.asObserver()
    }()

    lazy private var passwordObserver: AnyObserver<String?> = {
        return Binder(self) { target, val in
            if let val = val {
                if let _: String = self.savedLoginInfo["password"] as? String {}
                else { self.savedLoginInfo["password"] = val }
                target.dispatcher.dispatch(action: ItemEditAction.editPassword(value: val))
            }
        }.asObserver()
    }()

    lazy private var webAddressObserver: AnyObserver<String?> = {
        return Binder(self) { target, val in
            if let val = val {
                target.dispatcher.dispatch(action: ItemEditAction.editWebAddress(value: val))
            }
        }.asObserver()
    }()

    lazy private var deleteObserver: AnyObserver<Void>? = {
        return Binder(self) { target, _ in
            target.itemDetailStore.itemDetailId
                .take(1)
                .map { id -> [Action] in
                    return [DataStoreAction.delete(id: id),
                        MainRouteAction.list,
                        ItemDetailDisplayAction.viewMode]
                }
                .subscribe(onNext: { actions in
                    for action in actions {
                        self.dispatcher.dispatch(action: action)
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
    }

    func onViewReady() {
        let itemObservable = dataStore.locked
                .filter { !$0 }
                .take(1)
                .flatMap { _ in self.itemDetailStore.itemDetailId }
                .take(1)
                .flatMap { self.dataStore.get($0) }

        itemObservable.asDriver(onErrorJustReturn: nil)
                .filterNil()
                .map { self.configurationForLogin($0) }
                .drive(view!.itemDetailObserver)
                .disposed(by: disposeBag)

        itemObservable
                .filterNil()
                .map { item -> String in
                    let title = item.hostname.titleFromHostname()
                    return title.isEmpty ? Constant.string.unnamedEntry : title
                }
                .asDriver(onErrorJustReturn: Constant.string.unnamedEntry)
                .drive(view!.titleText)
                .disposed(by: disposeBag)

        // Only allow edit functionality on debug builds
        if FeatureFlags.crudEdit {
            setupEdit()
        }
        setupDelete()
        setupCopy(itemObservable: itemObservable)
        setupNavigation(itemObservable: itemObservable)
    }
    
    private func setupDelete() {
        view?.deleteTapped
            .subscribe(onNext: { (_) in
                self.view?.displayAlertController(
                    buttons: [
                        AlertActionButtonConfiguration(
                            title: Constant.string.cancel,
                            tapObserver: nil,
                            style: .cancel
                        ),
                        AlertActionButtonConfiguration(
                            title: Constant.string.delete,
                            tapObserver: self.deleteObserver,
                            style: .destructive)
                    ],
                    title: Constant.string.confirmDeleteLoginDialogTitle,
                    message: String(format: Constant.string.confirmDeleteLoginDialogMessage,
                                    Constant.string.productNameShort),
                    style: .alert,
                    barButtonItem: nil)
            })
            .disposed(by: disposeBag)
    }

    private func setupEdit() {
        itemDetailStore.isEditing
                .map { !$0 }
                .subscribe(view!.deleteHidden)
                .disposed(by: disposeBag)

        itemDetailStore.isEditing
                .subscribe(onNext: { editing in self.view?.enableLargeTitle(enabled: !editing) })
                .disposed(by: disposeBag)
    }

    private func setupCopy(itemObservable: Observable<LoginRecord?>) {
        // use the behaviorrelay to cache the most recent version of the LoginRecord
        let itemDetailRelay = BehaviorRelay<LoginRecord?>(value: nil)

        itemObservable
                .asDriver(onErrorJustReturn: nil)
                .drive(itemDetailRelay)
                .disposed(by: disposeBag)

        view?.cellTapped
                .withLatestFrom(itemDetailStore.isEditing) { cellTitle, isEditing -> String? in
                    return !isEditing ? cellTitle : nil
                }
                .filterNil()
                .withLatestFrom(itemDetailRelay) { (cellTitle: String, item: LoginRecord?) -> [Action] in
                    var actions: [Action] = []
                    if copyableFields.contains(cellTitle) {
                        if let item = item {
                            actions.append(DataStoreAction.touch(id: item.id))
                            actions.append(ItemDetailPresenter.getCopyActionFor(item, value: cellTitle, actionType: .tap))
                        }
                    } else if cellTitle == Constant.string.webAddress {
                        if let origin = item?.hostname {
                            actions.append(ExternalLinkAction(baseURLString: origin))
                        }
                    }
                    return actions

                }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { actions in
                    for action in actions {
                        self.dispatcher.dispatch(action: action)
                    }
                })
                .disposed(by: disposeBag)

        copyDisplayStore.copyDisplay
                .drive(onNext: { field in
                    let fieldName: String
                    switch field {
                    case .password: fieldName = Constant.string.password
                    case .username: fieldName = Constant.string.username
                    }

                    let message = String(format: Constant.string.fieldNameCopied, fieldName)
                    self.view?.displayTemporaryAlert(message, timeout: Constant.number.displayStatusAlertLength, icon: nil)
                })
        .disposed(by: disposeBag)
    }

    private func setupNavigation(itemObservable: Observable<LoginRecord?>) {
        view?.leftBarButtonTapped
                .withLatestFrom(itemDetailStore.isEditing) { _, editing -> Action? in
                    if editing {
                        self.view?.displayAlertController(
                            buttons: [
                                AlertActionButtonConfiguration(
                                    title: Constant.string.cancel,
                                    tapObserver: nil,
                                    style: .cancel
                                ),
                                AlertActionButtonConfiguration(
                                    title: Constant.string.discard,
                                    tapObserver: self.discardChangesObserver,
                                    style: .destructive)
                            ],
                            title: Constant.string.discardChangesTitle,
                            message: Constant.string.discardChangesMessage,
                            style: .alert,
                            barButtonItem: nil)
                    } else {
                        return MainRouteAction.list
                    }
                    return nil
                }
                .filterNil()
                .subscribe(onNext: { self.dispatcher.dispatch(action: $0) })
                .disposed(by: disposeBag)

        let editingObservable = Observable.combineLatest(itemDetailStore.usernameEditValue,
                                                         itemDetailStore.passwordEditValue,
                                                         itemDetailStore.webAddressEditValue,
                                                         itemDetailStore.isEditing,
                                                         itemObservable)

        //Only allow edit functional on debug builds
        if FeatureFlags.crudEdit {
            view?.rightBarButtonTapped
                .withLatestFrom(editingObservable) { (_, tuple) -> [Action] in
                    let (username, password, webAddress, editing, item) = tuple
                    if editing {
                        if let item = item {
                            item.username = username
                            item.password = password
                            item.hostname = webAddress
                            self.savedLoginInfo["username"] = username
                            self.savedLoginInfo["password"] = password
                            return [DataStoreAction.update(login: item),
                                    ItemDetailDisplayAction.viewMode]
                        }
                    } else {
                        return [ItemDetailDisplayAction.editMode]
                    }
                    
                    return []
            }
            .subscribe(onNext: { actions in
                for action in actions {
                    self.dispatcher.dispatch(action: action)
                }
            })
                .disposed(by: disposeBag)
            
            itemDetailStore.isEditing
                .map { editing in
                    return editing ? Constant.string.save : Constant.string.edit
            }
            .subscribe(view!.rightButtonText)
            .disposed(by: disposeBag)
            
            itemDetailStore.isEditing
                .withLatestFrom(sizeClassStore.shouldDisplaySidebar) { (editing: Bool, sidebar: Bool) -> String? in
                    if editing {
                        return Constant.string.cancel
                    } else if !sidebar {
                        return Constant.string.back
                    }
                    return nil
            }
            .subscribe(view!.leftButtonText)
            .disposed(by: disposeBag)
            
            itemDetailStore.isEditing
                .withLatestFrom(sizeClassStore.shouldDisplaySidebar) { (editing: Bool, sidebar: Bool) -> UIImage? in
                    if !editing && !sidebar {
                        return UIImage(named: "back")
                    }
                    return nil
            }
            .subscribe(view!.leftButtonIcon)
            .disposed(by: disposeBag)
        }
        
        sizeClassStore.shouldDisplaySidebar
                .subscribe(onNext: { (enableSidebar) in
                    self.view?.enableSwipeNavigation(enabled: !enableSidebar)
                })
                .disposed(by: disposeBag)
    }

    func onViewDisappear() {
        self.dispatcher.dispatch(action: ItemDetailDisplayAction.togglePassword(displayed: false))
    }

    func dndStarted(value: String?) {
        self.itemDetailStore.itemDetailId
            .take(1)
            .flatMap { self.dataStore.get($0) }
            .map { item -> [Action] in
                var actions: [Action] = []
                if let item = item {
                    actions.append(DataStoreAction.touch(id: item.id))
                    actions.append(ItemDetailPresenter.getCopyActionFor(item, value: value, actionType: .dnd))
                }

                return actions
            }
            .subscribe(onNext: { actions in
                for action in actions {
                    self.dispatcher.dispatch(action: action)
                }
            })
            .disposed(by: disposeBag)
    }
}

// helpers
extension ItemDetailPresenter {
    private func configurationForLogin(_ login: LoginRecord?) -> [ItemDetailSectionModel] {
        let itemPassword: String = login?.password ?? ""

        let passwordTextDriver = itemDetailStore.passwordRevealed
                .map { revealed -> String in
                    return revealed ? itemPassword : String(repeating: "•", count: itemPassword.count)
                }
                .asDriver(onErrorJustReturn: "")

        let isEditing = itemDetailStore.isEditing
                .asDriver(onErrorJustReturn: true)

        let hostname = login?.hostname ?? ""
        let username = login?.username ?? ""
        let sectionModels = [
            ItemDetailSectionModel(model: 0, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.webAddress,
                        value: Driver.just(hostname),
                        accessibilityLabel: String(format: Constant.string.websiteCellAccessibilityLabel, hostname),
                        valueFontColor: Constant.color.lockBoxViolet,
                        accessibilityId: "webAddressItemDetail",
                        textFieldEnabled: isEditing,
                        openButtonHidden: isEditing,
                        textObserver: webAddressObserver,
                        dragValue: hostname)
            ]),
            ItemDetailSectionModel(model: 1, items: [
                ItemDetailCellConfiguration(
                        title: Constant.string.username,
                        value: Driver.just(username),
                        accessibilityLabel: String(format: Constant.string.usernameCellAccessibilityLabel, username),
                        accessibilityId: "userNameItemDetail",
                        textFieldEnabled: isEditing,
                        copyButtonHidden: isEditing,
                        textObserver: usernameObserver,
                        dragValue: username),
                ItemDetailCellConfiguration(
                        title: Constant.string.password,
                        value: passwordTextDriver,
                        accessibilityLabel: Constant.string.passwordCellAccessibilityLabel,
                        accessibilityId: "passwordItemDetail",
                        textFieldEnabled: isEditing,
                        copyButtonHidden: isEditing,
                        textObserver: passwordObserver,
                        revealPasswordObserver: onPasswordToggle,
                        dragValue: login?.password)
            ])
        ]

        return sectionModels
    }

    private static func getCopyActionFor(_ item: LoginRecord?, value: String?, actionType: CopyActionType) -> CopyAction {
        var field = CopyField.username
        var text = ""
        if value == Constant.string.username {
            text = item?.username ?? ""
            field = CopyField.username
        } else if value == Constant.string.password {
            text = item?.password ?? ""
            field = CopyField.password
        }

        return CopyAction(text: text, field: field, itemID: item?.id ?? "", actionType: actionType)
    }
}
