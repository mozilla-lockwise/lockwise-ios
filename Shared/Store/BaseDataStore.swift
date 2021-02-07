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
    
    internal lazy var loginsDatabasePath: String? = {
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
        do {
            let filePath = try files.getAndEnsureDirectory()
            return URL(fileURLWithPath: filePath).appendingPathComponent(filename).path
        } catch {
            dispatcher.dispatch(action: SentryAction(title: "BaseDataStoreError accessing loginsDatabasePath", error: error, line: nil))
            return nil
        }
    }()

    internal var loginsKey: String? {
        let key = KeychainKey.loginsKey.rawValue
        if self.keychainWrapper.hasValue(forKey: key) {
            return self.keychainWrapper.string(forKey: key)
        }

        let Length: UInt = 256
        let secret = Bytes.generateRandomBytes(Length).base64EncodedString(options: [])
        self.keychainWrapper.set(secret, forKey: key, withAccessibility: .afterFirstUnlock)
        return secret
    }

    private var salt: String? {
        return setupSalt()
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
                    case .syncStart:
                        self.sync()
                    case .touch(let id):
                        self.touch(id: id)
                    case .lock:
                        self.lock()
                    case .unlock:
                        self.unlock()
                    case .delete(let id):
                        self.delete(id: id)
                    case .update(let login):
                        self.update(login)
                    default:
                        break
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
                            _ = try self.loginsStorage?.delete(id: id)
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

    private func update(_ login: LoginRecord) {
        queue.async {
            do {
                try self.loginsStorage?.update(login: login)
            } catch let error as LoginsStoreError {
                self.pushError(error)
            } catch let error {
                NSLog("DATASTORE:: Unexpected LoginsStorage error -- \(error)")
            }

            self.updateList()
            self.sync(supressNotification: true)
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
                    self.dispatcher.dispatch(action: DataStoreAction.syncTimeout)
                }
            })

            do {
                _ = try self.loginsStorage?.sync(unlockInfo: syncInfo)
            } catch let error as LoginsStoreError {
                self.pushError(error)
                self.dispatcher.dispatch(action: DataStoreAction.syncError(error: error.errorDescription ?? ""))
            } catch let error {
                NSLog("DATASTORE:: Unknown error syncing: \(error)")
            }
            self.syncSubject.accept(SyncState.Synced)
            self.dispatcher.dispatch(action: DataStoreAction.syncEnd)
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

/// Return kern.bootsessionuuid, which is a unique UUID that is set at device boot. The returned String can be nil or empty.
private func getBootSessionUUID() -> String? {
    if let key = "kern.bootsessionuuid".cString(using: String.Encoding.utf8) {
        var size: Int = 0
        if sysctlbyname(key, nil, &size, nil, 0) == 0 && size > 0 {
            var value = [CChar](repeating: 0, count: size)
            if sysctlbyname(key, &value, &size, nil, 0) == 0 {
                return String(cString: value)
            }
        }
    }
    return nil
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

        // Lock the app on first run but only if the device was restarted. We keep track of reboots
        // by looking at the kern.bootsessionuuidm, wich is set to a random value at device boot.
        
        // Grab the Boot Session UUID - If not available, lock and we're done.
        guard let currentBootSessionUUID = getBootSessionUUID(), currentBootSessionUUID.isNotEmpty else {
            lock()
            return
        }
        
        let LastBootSessionUUIDKey = "lastBootSessionUUID"

        // Grab the last seen Boot Session UUID. If it is different from the current Boot Session then
        // the device was rebooted and we lock the app.
        let lastBootSessionUUID = UserDefaults.standard.string(forKey: LastBootSessionUUIDKey) ?? ""
        if currentBootSessionUUID != lastBootSessionUUID {
            UserDefaults.standard.set(currentBootSessionUUID, forKey: LastBootSessionUUIDKey)
            lock()
        }
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
        guard let loginsStorage = loginsStorage,
            let loginsKey = loginsKey,
            let salt = salt,
            let loginsDatabasePath = loginsDatabasePath else { return }

        do {
            try loginsStorage.ensureUnlockedWithKeyAndSalt(key: loginsKey, salt: salt)
            self.storageStateSubject.onNext(.Unlocked)
        } catch let error as LoginsStoreError {
            pushError(error)
            // If we can not access database with current salt and key, need to delete local database and migrate to replacement salt
            // This only deletes the local database file, does not delete the user's sync data
            handleDatabaseAccessFailure(databasePath: loginsDatabasePath, encryptionKey: loginsKey)
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
        guard let loginsStorage = self.loginsStorage else { return }

        queue.async {
            do {
                self.storageStateSubject.onNext(.Unprepared)
                try loginsStorage.wipeLocal()
            } catch let error as LoginsStoreError {
                self.pushError(error)
            } catch let error {
                print("Unknown error wiping database: \(error.localizedDescription)")
            }
        }
    }

    private func shutdown() {
        loginsStorage?.close()
    }

    private func initializeLoginsStorage() {
        guard let loginsDatabasePath = loginsDatabasePath else { return }
        loginsStorage = dataStoreSupport.createLoginsStorage(databasePath: loginsDatabasePath)
    }
    
    private func setupSalt() -> String? {
        guard let loginsDatabasePath = loginsDatabasePath,
            let loginsKey = loginsKey else { return nil }

        let saltKey = KeychainKey.salt.rawValue
        if keychainWrapper.hasValue(forKey: saltKey, withAccessibility: .afterFirstUnlock) {
            return keychainWrapper.string(forKey: saltKey, withAccessibility: .afterFirstUnlock)
        }

        let val = setupPlaintextHeaderAndGetSalt(databasePath: loginsDatabasePath, encryptionKey: loginsKey)
        keychainWrapper.set(val, forKey: saltKey, withAccessibility: .afterFirstUnlock)
        return val
    }
    
    // Migrate and return the salt, or create a new salt
    // Also, in the event of an error, returns a new salt.
    private func setupPlaintextHeaderAndGetSalt(databasePath: String, encryptionKey: String) -> String {
        guard FileManager.default.fileExists(atPath: databasePath) else {
            return createRandomSalt()
        }
        guard let db = loginsStorage as? LoginsStorage else {
            return createRandomSalt()
        }
        
        do {
            let salt = try db.getDbSaltForKey(key: encryptionKey)
            try db.migrateToPlaintextHeader(key: encryptionKey, salt: salt)
            return salt
        } catch {
            self.dispatcher.dispatch(action: SentryAction(title: "setupPlaintextHeaderAndGetSalt failed", error: error, line: nil))
            return createRandomSalt()
        }
    }
    
    // Closes database
    // Deletes database file
    // Creates new database and syncs
    private func handleDatabaseAccessFailure(databasePath: String, encryptionKey: String) {
        let saltKey = KeychainKey.salt.rawValue
        if keychainWrapper.hasValue(forKey: saltKey, withAccessibility: .afterFirstUnlock) {
            keychainWrapper.removeObject(forKey: saltKey)
        }
        do {
            if let database = loginsStorage as? LoginsStorage {
                database.close()
            }
            if FileManager.default.fileExists(atPath: databasePath) {
                try FileManager.default.removeItem(atPath: databasePath)
                loginsStorage = nil
                try createNewDatabase()
            } else {
                loginsStorage = nil
                try createNewDatabase()
            }
        } catch {
            self.dispatcher.dispatch(action: SentryAction(title: "handleDatabaseAccessFailure failed", error: error, line: nil))
        }
    }
    
    enum DatabaseError: Error {
        case issueDeletingDatabase(description: String)
        case issueCreatingDatabase(description: String)
    }
    
    private func createNewDatabase() throws {
        guard let encryptionKey = loginsKey else { throw DatabaseError.issueCreatingDatabase(description: "logins database key is nil") }
        do {
            initializeLoginsStorage()
            guard let newDatabase = loginsStorage as? LoginsStorage else { throw DatabaseError.issueCreatingDatabase(description: "initializing new database failed") }
            let salt = createRandomSalt()
            try newDatabase.ensureUnlockedWithKeyAndSalt(key: encryptionKey, salt: salt)
            let saltKey = KeychainKey.salt.rawValue
            keychainWrapper.set(salt, forKey: saltKey, withAccessibility: .afterFirstUnlock)
            self.storageStateSubject.onNext(.Unlocked)
        } catch {
            self.dispatcher.dispatch(action: SentryAction(title: "handleDatabaseAccessFailure failed", error: error, line: nil))
            throw DatabaseError.issueCreatingDatabase(description: "failed to unlock new database with key and salt:\(error)")
        }
    }
    
    private func createRandomSalt() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
}
