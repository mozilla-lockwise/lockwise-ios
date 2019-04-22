/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MozillaAppServices
import RxSwift
import RxCocoa
import RxOptional
import SwiftKeychainWrapper

enum SyncError: Error {
    case CryptoInvalidKey
    case CryptoMissingKey
    case Crypto
    case Locked
    case Offline
    case Network
    case NeedAuth
    case Conflict
    case AccountDeleted
    case AccountReset
    case DeviceRevoked
}

enum SyncState: Equatable {
    case NotSyncable, ReadyToSync, Syncing, Synced, Error(error: SyncError)

    public static func ==(lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (NotSyncable, NotSyncable):
            return true
        case (ReadyToSync, ReadyToSync):
            return true
        case (Syncing, Syncing):
            return true
        case (Synced, Synced):
            return true
        case (Error, Error):
            return true
        default:
            return false
        }
    }
}

enum LoginStoreState: Equatable {
    case Unprepared, Locked, Unlocked, Errored(cause: LoginStoreError)

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

public enum LoginStoreError: Error {
    // applies to just about every function call
    case Unknown(cause: Error?)
    case NotInitialized
    case AlreadyInitialized
    case VersionMismatch
    case CryptoInvalidKey
    case CryptoMissingKey
    case Crypto
    case InvalidItem
    case Locked
}

class BaseDataStore {
    private let queue = DispatchQueue(label: "Logins queue", attributes: [])

    internal var disposeBag = DisposeBag()
    private var listSubject = BehaviorRelay<[LoginRecord]>(value: [])
    private var syncSubject = ReplaySubject<SyncState>.create(bufferSize: 1)
    internal var storageStateSubject = ReplaySubject<LoginStoreState>.create(bufferSize: 1)

    private let keychainWrapper: KeychainWrapper
    private let networkStore: NetworkStore
    internal let dispatcher: Dispatcher
    private let application: UIApplication
    internal var syncUnlockInfo: SyncUnlockInfo?
    internal let accountStore: BaseAccountStore
    private let autoLockSupport: AutoLockSupport

    internal var loginsStorage: LoginsStorage?

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

    // From: https://github.com/mozilla-lockbox/lockbox-ios-fxa-sync/blob/120bcb10967ea0f2015fc47bbf8293db57043568/Providers/Profile.swift#L168
    internal static var loginsKey: String? {
        let key = "sqlcipher.key.logins.db"
        let keychain = KeychainWrapper.sharedAppContainerKeychain
        if keychain.hasValue(forKey: key) {
            return keychain.string(forKey: key)
        }

        let Length: UInt = 256
        let secret = Bytes.generateRandomBytes(Length).base64EncodedString(options: [])
        keychain.set(secret, forKey: key, withAccessibility: .afterFirstUnlock)
        return secret
    }

    var unlockInfo: SyncUnlockInfo?

    init(dispatcher: Dispatcher = Dispatcher.shared,
         keychainWrapper: KeychainWrapper = KeychainWrapper.standard,
         accountStore: BaseAccountStore = AccountStore.shared,
         autoLockSupport: AutoLockSupport = AutoLockSupport.shared,
         networkStore: NetworkStore = NetworkStore.shared,
         application: UIApplication = UIApplication.shared) {
        self.keychainWrapper = keychainWrapper
        self.application = application
        self.accountStore = accountStore
        self.networkStore = networkStore
        self.autoLockSupport = autoLockSupport
        self.dispatcher = dispatcher

        self.initializeLoginsStorage()

        dispatcher.register
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
                    }
                })
                .disposed(by: self.disposeBag)

        dispatcher.register
                .filterByType(class: LifecycleAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .background:
                        self.autoLockSupport.storeNextAutolockTime()
                    case .foreground:
                        self.initializeLoginsStorage()
                        self.handleLock()
                    case .upgrade(let previous, _):
                        if previous <= 2 {
                            self.handleLock()
                        }
                    case .shutdown:
                        self.shutdown()
                    default:
                        break
                    }
                })
                .disposed(by: disposeBag)

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

    public func initialized() {
        fatalError("not implemented!")
    }
}

// login entry operations
extension BaseDataStore {
    public func get(_ id: String) -> Observable<LoginRecord?> {
        return self.listSubject
            .map { items -> LoginRecord? in
                return items.filter { item in
                    return item.id == id
                    }.first
        }
    }

    public func touch(id: String) {
        do {
            try self.loginsStorage?.touch(id: id)
        } catch let error {
            print("Sync15: \(error)")
        }
    }
}

// list operations
extension BaseDataStore {
    public func sync() {
        guard let loginsStorage = self.loginsStorage,
            let syncInfo = self.syncUnlockInfo,
            !loginsStorage.isLocked()
            else { return }

        if (networkStore.isConnectedToNetwork) {
            self.syncSubject.onNext(SyncState.Syncing)
        } else {
            self.syncSubject.onNext(SyncState.Synced)
            return
        }

        queue.async {
            do {
                try self.loginsStorage?.sync(unlockInfo: syncInfo)
            } catch let error {
                print("Sync15 Sync Error: \(error)")
            }
            self.syncSubject.onNext(SyncState.Synced)
        }
    }

    private func updateList() {
        guard let loginsStorage = self.loginsStorage,
            !loginsStorage.isLocked() else { return }
        queue.async {
            do {
                let loginRecords = try loginsStorage.list()
                self.listSubject.accept(loginRecords)
            } catch let error {
                print("Sync15 list update error: \(error)")
            }
        }
    }

    private func clearList() {
        self.listSubject.accept([])
    }
}

// locking management
extension BaseDataStore {
    public func unlock() {
        self.autoLockSupport.forwardDateNextLockTime()
        self.unlockInternal()
    }
    
    public func lock() {
        self.autoLockSupport.backDateNextLockTime()
        self.lockInternal()
    }

    private func lockInternal() {
        guard let loginsStorage = self.loginsStorage else { return }
        
        queue.async {
            loginsStorage.ensureLocked()
            self.storageStateSubject.onNext(.Locked)
        }
    }

    private func unlockInternal() {
        guard let loginsStorage = self.loginsStorage,
            let loginsKey = BaseDataStore.loginsKey else { return }

        do {
            try loginsStorage.ensureUnlocked(withEncryptionKey: loginsKey)
            self.storageStateSubject.onNext(.Unlocked)
        } catch let error {
            print("LoginsError: \(error)")
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
    public func updateCredentials(_ syncCredential: SyncCredential) {
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

    private func reset() {
        guard let loginsStorage = self.loginsStorage,
            let loginsKey = BaseDataStore.loginsKey else { return }

        queue.async {
            do {
                self.storageStateSubject.onNext(.Unprepared)
                try loginsStorage.ensureUnlocked(withEncryptionKey: loginsKey)
                try loginsStorage.wipeLocal()
            } catch let error {
                print("Sync15 wipe error: \(error.localizedDescription)")
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

        self.loginsStorage = LoginsStorage(databasePath: file)
    }
}
