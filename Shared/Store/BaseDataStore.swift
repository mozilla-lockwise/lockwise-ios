/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MozillaAppServices
import RxSwift
import RxRelay
import RxOptional
import SwiftKeychainWrapper

enum SyncState: Equatable {
    case Syncing(supressNotification: Bool), Synced, TimedOut

    public static func ==(lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.Syncing(let lhSupressNotification), .Syncing(let rhSupressNotification)):
            return lhSupressNotification == rhSupressNotification
        case (Synced, Synced):
            return true
        case (TimedOut, TimedOut):
            return true
        default:
            return false
        }
    }

    public func isSyncing() -> Bool {
        switch self {
        case .Syncing(_):
            return true
        default:
            return false
        }
    }
}

enum LoginStoreState: Equatable {
    case Unprepared, Locked, Unlocked, Errored(cause: LoginsStoreError)

    public static func ==(lhs: LoginStoreState, rhs: LoginStoreState) -> Bool {
        switch (lhs, rhs) {
        case (Unprepared, Unprepared): return true
        case (Locked, Locked): return true
        case (Unlocked, Unlocked): return true
        case (Errored, Errored): return true
        default:
            return false
        }
    }
}

class BaseDataStore {
    private let queue = DispatchQueue(label: "Logins queue", attributes: [])

    internal var disposeBag = DisposeBag()
    private var listSubject = BehaviorRelay<[LoginRecord]>(value: [])
    private var syncSubject = BehaviorRelay<SyncState>(value: .Synced)
    private var storageStateSubject = ReplaySubject<LoginStoreState>.create(bufferSize: 1)

    private let dispatcher: Dispatcher
    private let keychainWrapper: KeychainWrapper
    internal let autoLockSupport: AutoLockSupport
    private let dataStoreSupport: DataStoreSupport
    private let networkStore: NetworkStore
    private let lifecycleStore: LifecycleStore

    private var loginsStorage: LoginsStorageProtocol?
    private var syncUnlockInfo: SyncUnlockInfo?

    public var list: Observable<[LoginRecord]> {
        return self.listSubject.asObservable()
    }

    public var syncState: Observable<SyncState> {
        return self.syncSubject.asObservable()
    }

    public var locked: Observable<Bool> {
        return self.storageState.map { $0 == LoginStoreState.Locked }
    }

    public var storageState: Observable<LoginStoreState> {
        return self.storageStateSubject.asObservable()
    }

    // From: https://github.com/mozilla-lockwise/lockwise-ios-fxa-sync/blob/120bcb10967ea0f2015fc47bbf8293db57043568/Providers/Profile.swift#L168
    internal var loginsKey: String? {
        let key = "sqlcipher.key.logins.db"
        if self.keychainWrapper.hasValue(forKey: key) {
            return self.keychainWrapper.string(forKey: key)
        }

        let Length: UInt = 256
        let secret = Bytes.generateRandomBytes(Length).base64EncodedString(options: [])
        self.keychainWrapper.set(secret, forKey: key, withAccessibility: .afterFirstUnlock)
        return secret
    }

    var unlockInfo: SyncUnlockInfo?

    init(dispatcher: Dispatcher = Dispatcher.shared,
         keychainWrapper: KeychainWrapper = KeychainWrapper.sharedAppContainerKeychain,
         autoLockSupport: AutoLockSupport = AutoLockSupport.shared,
         dataStoreSupport: DataStoreSupport = DataStoreSupport.shared,
         networkStore: NetworkStore = NetworkStore.shared,
         lifecycleStore: LifecycleStore = LifecycleStore.shared) {
        self.keychainWrapper = keychainWrapper
        self.networkStore = networkStore
        self.lifecycleStore = lifecycleStore
        self.autoLockSupport = autoLockSupport
        self.dataStoreSupport = dataStoreSupport
        self.dispatcher = dispatcher

        self.initializeLoginsStorage()
        self.setupAutolock()

        self.dispatcher.register
                .filterByType(class: DataStoreAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .updateCredentials(let syncCredential):
                        self.updateCredentials(syncCredential)
                    case .reset:
                        self.reset()
                    case .sync:
                        self.sync()
                    case .touch(let id):
                        self.touch(id: id)
                    case .lock:
                        self.lock()
                    case .unlock:
                        self.unlock()
                    case .delete(let id):
                        self.delete(id: id)
                    }
                })
                .disposed(by: self.disposeBag)

        self.lifecycleStore.lifecycleEvents
                .filter { $0 == .shutdown || $0 == .background }
                .subscribe(onNext: { [weak self] _ in
                    self?.shutdown()
                })
                .disposed(by: self.disposeBag)

        self.lifecycleStore.lifecycleEvents
                .filter { $0 == .foreground }
                .subscribe(onNext: { [weak self] _ in
                    guard let _ = self?.loginsStorage else {
                        self?.initializeLoginsStorage()
                        return
                    }
                })
                .disposed(by: self.disposeBag)

        self.syncState
                .subscribe(onNext: { state in
                    if state == .Synced {
                        self.updateList()
                    }
                })
                .disposed(by: self.disposeBag)

        self.storageState
                .subscribe(onNext: { state in
                    switch state {
                    case .Unlocked: self.sync()
                    case .Locked, .Unprepared: self.clearList()
                    default: break
                    }
                })
                .disposed(by: self.disposeBag)

        self.initialized()
    }

    public func get(_ id: String) -> Observable<LoginRecord?> {
        return Observable.create({ [weak self] observer -> Disposable in
            self?.queue.async {
                do {
                    let login = try self?.loginsStorage?.get(id: id)
                    observer.onNext(login)
                } catch let error {
                    observer.onError(error)
                }
            }

            return Disposables.create()
        })
    }

    public func initialized() {
        fatalError("not implemented!")
    }
}

// login entry operations
extension BaseDataStore {
    private func touch(id: String) {
        do {
            try self.loginsStorage?.touch(id: id)
        } catch let error as LoginsStoreError {
            self.pushError(error)
        } catch let error {
            NSLog("DATASTORE:: Unexpected LoginsStorage error -- \(error)")
        }
    }
}

extension BaseDataStore {
    private func delete(id: String) {
        queue.async {
            self.get(id)
                .take(1)
                .subscribe(onNext: { (record) in
                    if let record = record {
                        let title = record.hostname.titleFromHostname()
                        self.dispatcher.dispatch(action: ItemDeletedAction(name: title, id: record.id))

                        do {
                            try self.loginsStorage?.delete(id: id)
                        } catch let error as LoginsStoreError {
                            self.pushError(error)
                        } catch let error {
                            NSLog("DATASTORE:: Unexpected LoginsStorage error -- \(error)")
                        }

                        self.updateList()
                        self.sync(supressNotification: true)
                    }

                })
                .disposed(by: self.disposeBag)
        }
    }
}

// list operations
extension BaseDataStore {
    private func sync(supressNotification: Bool = false) {
        guard let loginsStorage = self.loginsStorage,
            let syncInfo = self.syncUnlockInfo,
            !loginsStorage.isLocked()
            else { return }

        if (networkStore.isConnectedToNetwork) {
            self.syncSubject.accept(SyncState.Syncing(supressNotification: supressNotification))
        } else {
            self.syncSubject.accept(SyncState.Synced)
            return
        }

        queue.async {
            self.queue.asyncAfter(deadline: .now() + Constant.app.syncTimeout, execute: {
                // this block serves to "cancel" the sync if the operation is running slowly
                if (self.syncSubject.value != .Synced) {
                    self.syncSubject.accept(.TimedOut)
                    self.dispatcher.dispatch(action: SentryAction(title: "Sync timeout without error", error: nil, line: ""))
                }
            })

            do {
                try self.loginsStorage?.sync(unlockInfo: syncInfo)
            } catch let error as LoginsStoreError {
                self.pushError(error)
            } catch let error {
                NSLog("DATASTORE:: Unknown error syncing: \(error)")
            }
            self.syncSubject.accept(SyncState.Synced)
        }
    }

    private func updateList() {
        guard let loginsStorage = self.loginsStorage,
            !loginsStorage.isLocked() else { return }
        queue.async {
            do {
                let loginRecords = try loginsStorage.list()
                self.listSubject.accept(loginRecords)
            } catch let error as LoginsStoreError {
                self.pushError(error)
            } catch let error {
                NSLog("DATASTORE:: Unknown error updating list: \(error)")
            }
        }
    }

    private func clearList() {
        self.listSubject.accept([])
    }
}

// locking management
extension BaseDataStore {
    private func setupAutolock() {
        self.lifecycleStore.lifecycleEvents
            .filter { $0 == .background }
            .withLatestFrom(self.storageState, resultSelector: { (_, state) -> Void? in
                return state == .Unlocked ? () : nil
            })
            .filterNil()
            .subscribe(onNext: { [weak self] _ in
                self?.autoLockSupport.storeNextAutolockTime()
            })
            .disposed(by: disposeBag)

        self.lifecycleStore.lifecycleEvents
                .filter { $0 == .foreground }
                .withLatestFrom(self.storageState, resultSelector: { (_, state) -> Void? in
                    return state != .Unprepared ? () : nil
                })
                .filterNil()
                .subscribe(onNext: { [weak self] _ in
                    self?.handleLock()
                })
                .disposed(by: self.disposeBag)
    }

    private func unlock() {
        self.autoLockSupport.forwardDateNextLockTime()
        self.unlockInternal()
    }

    private func lock() {
        self.autoLockSupport.backDateNextLockTime()
        self.lockInternal()
    }

    private func lockInternal() {
        guard let loginsStorage = self.loginsStorage else { return }

        queue.async {
            self.storageStateSubject.onNext(.Locked)
            loginsStorage.ensureLocked()
        }
    }

    private func unlockInternal() {
        guard let loginsStorage = self.loginsStorage,
            let loginsKey = self.loginsKey else { return }

        do {
            try loginsStorage.ensureUnlocked(withEncryptionKey: loginsKey)
            self.storageStateSubject.onNext(.Unlocked)
        } catch let error as LoginsStoreError {
            pushError(error)
        } catch let error {
            NSLog("Unknown error unlocking: \(error)")
        }
    }

    private func handleLock() {
        if self.autoLockSupport.lockCurrentlyRequired {
            self.lockInternal()
        } else {
            self.unlockInternal()
        }
    }
}

// lifecycle management
extension BaseDataStore {
    private func updateCredentials(_ syncCredential: SyncCredential) {
        self.syncUnlockInfo = syncCredential.syncInfo

        guard let loginsStorage = self.loginsStorage else { return }

        if syncCredential.isNew {
            if (loginsStorage.isLocked()) {
                self.unlockInternal()
            } else {
                self.storageStateSubject.onNext(.Unlocked)
            }
        } else {
            self.handleLock()
        }
    }

    private func pushError(_ error: LoginsStoreError) {
        self.storageStateSubject.onNext(.Errored(cause: error))
        self.dispatcher.dispatch(action: SentryAction(title: "Datastore Error", error: error, line: nil))

        switch error {
        case .authInvalid, .invalidKey:
            self.dispatcher.dispatch(action: DataStoreAction.reset)
            self.dispatcher.dispatch(action: AccountAction.clear)
        default:
            return
        }
    }

    private func reset() {
        guard let loginsStorage = self.loginsStorage,
            let loginsKey = self.loginsKey else { return }

        queue.async {
            do {
                self.storageStateSubject.onNext(.Unprepared)
                try loginsStorage.ensureUnlocked(withEncryptionKey: loginsKey)
                try loginsStorage.wipeLocal()
            } catch let error as LoginsStoreError {
                self.pushError(error)
            } catch let error {
                NSLog("Unknown error wiping database: \(error.localizedDescription)")
            }
        }
    }

    private func shutdown() {
        self.loginsStorage?.close()
    }

    private func initializeLoginsStorage() {
        let filename = "logins.db"

        let profileDirName = "profile.lockbox-profile)"

        // Bug 1147262: First option is for device, second is for simulator.
        var rootPath: String
        let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerIdentifier) {
            rootPath = url.path
        } else {
            print("Unable to find the shared container. Defaulting profile location to ~/Documents instead.")
            rootPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        }

        let files = File(rootPath: URL(fileURLWithPath: rootPath).appendingPathComponent(profileDirName).path)
        let file = URL(fileURLWithPath: (try! files.getAndEnsureDirectory())).appendingPathComponent(filename).path

        self.loginsStorage = dataStoreSupport.createLoginsStorage(databasePath: file)
    }
}
