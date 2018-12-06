/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Foundation
import FxAClient
import FxAUtils
import RxSwift
import RxCocoa
import RxOptional
import Shared
import Storage
import SwiftyJSON
import SwiftKeychainWrapper
import Sync15Logins

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

public typealias ProfileFactory = (_ reset: Bool) -> FxAUtils.Profile

private let defaultProfileFactory: ProfileFactory = { reset in
    BrowserProfile(localName: "lockbox-profile", clear: reset)
}

class BaseDataStore {
    internal var disposeBag = DisposeBag()
    private var listSubject = BehaviorRelay<[Login]>(value: [])
    private var syncSubject = ReplaySubject<SyncState>.create(bufferSize: 1)
    internal var storageStateSubject = ReplaySubject<LoginStoreState>.create(bufferSize: 1)

    private let fxaLoginHelper: FxALoginHelper
    private let profileFactory: ProfileFactory
    private let keychainWrapper: KeychainWrapper
    internal let userDefaults: UserDefaults
    internal var profile: FxAUtils.Profile
    internal let dispatcher: Dispatcher
    private let application: UIApplication
    internal var syncUnlockInfo: SyncUnlockInfo?

    internal var loginsStorage: LoginsStorage?

    public var list: Observable<[Login]> {
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
        keychain.ensureStringItemAccessibility(.afterFirstUnlock, forKey: key)
        if keychain.hasValue(forKey: key) {
            return keychain.string(forKey: key)
        }

        let Length: UInt = 256
        let secret = Bytes.generateRandomBytes(Length).base64EncodedString
        keychain.set(secret, forKey: key, withAccessibility: .afterFirstUnlock)
        return secret
    }

    var unlockInfo: SyncUnlockInfo?

    init(dispatcher: Dispatcher = Dispatcher.shared,
         profileFactory: @escaping ProfileFactory = defaultProfileFactory,
         fxaLoginHelper: FxALoginHelper = FxALoginHelper.sharedInstance,
         keychainWrapper: KeychainWrapper = KeychainWrapper.standard,
         userDefaults: UserDefaults = UserDefaults(suiteName: Constant.app.group)!,
         application: UIApplication = UIApplication.shared) {
        self.profileFactory = profileFactory
        self.fxaLoginHelper = fxaLoginHelper
        self.keychainWrapper = keychainWrapper
        self.userDefaults = userDefaults
        self.application = application

        self.dispatcher = dispatcher
        self.profile = profileFactory(false)

        initializeLoginsStorage()

        self.initializeProfile()
        self.registerNotificationCenter()

        dispatcher.register
                .filterByType(class: DataStoreAction.self)
                .subscribe(onNext: { action in
                    print("Sync15: \(action)")
                    switch action {
                    case .updateCredentials(let oauthInfo, let fxaProfile, let account):
                        self.updateCredentials(oauthInfo, fxaProfile: fxaProfile, account: account)
                    case .reset:
                        self.reset()
                    case .sync:
                        self.sync()
                    case let .touch(id:id):
                        self.touch(id: id)
                    case .lock:
                        self.lock()
                    case .unlock:
                        self.unlock()
                    case let .add(item: login):
                        self.add(item: login)
                    case let .remove(id:id):
                        self.remove(id: id)
                    }
                })
                .disposed(by: self.disposeBag)

        dispatcher.register
                .filterByType(class: LifecycleAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .background:
                        self.profile.syncManager?.applicationDidEnterBackground()
                        var taskId = UIBackgroundTaskIdentifier.invalid
                        taskId = application.beginBackgroundTask (expirationHandler: {
                            self.profile.shutdown()
                            application.endBackgroundTask(taskId)
                        })
                    case .foreground:
                        self.profile.syncManager?.applicationDidBecomeActive()
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
                    } else if state == .NotSyncable {
                        self.makeEmptyList()
                    }
                })
                .disposed(by: self.disposeBag)

        self.storageState
                .subscribe(onNext: { state in
                    if state == .Unlocked {
                        self.updateList()
                    } else if state == .Locked {
                        self.makeEmptyList()
                    }
                })
                .disposed(by: self.disposeBag)

        self.setInitialState()
        self.initialized()
    }
    
    public func initialized() {
        fatalError("not implemented!")
    }

    public func get(_ id: String) -> Observable<Login?> {
        return self.listSubject
                .map { items -> Login? in
                    return items.filter { item in
                        return item.guid == id
                    }.first
                }.asObservable()
    }

    public func unlock() {
        func performUnlock() {
            do {
                if let loginsKey = BaseDataStore.loginsKey {
                    try self.loginsStorage?.unlock(withEncryptionKey: loginsKey)
                    if let syncUnlockInfo = self.syncUnlockInfo {
                        try self.loginsStorage?.sync(unlockInfo: syncUnlockInfo)
                    }
                }
            } catch let error {
                print("Sync15: \(error)")
            }
        }

        self.storageState
            .take(1)
            .subscribe(onNext: { state in
                if state == .Locked {
                    performUnlock()
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func shutdown() {
        if !self.profile.isShutdown {
            self.profile.shutdown()
        }
    }
}

extension BaseDataStore {
    public func updateCredentials(_ oauthInfo: OAuthInfo, fxaProfile: FxAClient.Profile, account: FxAClient.FirefoxAccount) {
        guard let keysString = oauthInfo.keys else {
            return
        }

        let keys = JSON(parseJSON: keysString)
        let scopedKey = keys[Constant.fxa.oldSyncScope]

        guard let profileAccount = profile.getAccount() else {
            _ = fxaLoginHelper.application(UIApplication.shared,
                                           email: fxaProfile.email,
                                           accessToken: oauthInfo.accessToken,
                                           oauthKeys: scopedKey)
            return
        }

        if let oauthInfoKey = OAuthInfoKey(from: scopedKey) {
            profileAccount.makeOAuthLinked(accessToken: oauthInfo.accessToken, oauthInfo: oauthInfoKey)
        }

        let syncKey = scopedKey["k"].stringValue
        let kid = scopedKey["kid"].stringValue

        do {
            self.syncUnlockInfo = try SyncUnlockInfo(kid: kid, fxaAccessToken: oauthInfo.accessToken, syncKey: syncKey, tokenserverURL: account.getTokenServerEndpointURL().absoluteString)

        } catch let error {
            print("Sync15: \(error)")
        }
    }
}

extension BaseDataStore {
    public func touch(id: String) {
        do {
            try self.loginsStorage?.touch(id: id)
        } catch let error {
            print("Sync15: \(error)")
        }
    }
}

extension BaseDataStore {
    private func reset() {
        do {
            try self.loginsStorage?.reset()
        } catch let error {
            print("Sync15: \(error)")
        }
    }
}

extension BaseDataStore {
    func lock() {
        do {
            try self.loginsStorage?.lock()
        } catch let error {
            print("Sync15: \(error)")
        }
    }
}

extension BaseDataStore {
    public func sync() {
        if let syncUnlockInfo = self.syncUnlockInfo {
            do {
                try self.loginsStorage?.sync(unlockInfo: syncUnlockInfo)
            } catch let error {
                print("Sync15: \(error)")
            }
        }
        self.profile.syncManager.syncEverything(why: .syncNow)
    }

    private func registerNotificationCenter() {
        let names = [NotificationNames.FirefoxAccountVerified,
                     NotificationNames.ProfileDidStartSyncing,
                     NotificationNames.ProfileDidFinishSyncing
        ]
        names.forEach { name in
            NotificationCenter.default.rx
                    .notification(name)
                    .subscribe(onNext: { self.updateSyncState(from: $0) })
                    .disposed(by: self.disposeBag)
        }
    }

    private func updateSyncState(from notification: Notification) {
        Observable.combineLatest(self.storageState, self.syncState)
            .take(1)
            .subscribe(onNext: { latest in
                self.update(storageState: latest.0, syncState: latest.1, from: notification)
            })
            .disposed(by: self.disposeBag)
    }

    private func update(storageState: LoginStoreState, syncState: SyncState, from notification: Notification) {
        // LoginStoreState: Unprepared, Preparing, Locked, Unlocked, Errored(cause: LoginStoreError)
        //      Store state goes from:
        //          * Unprepared to Preparing when a valid username and password are detected.
        //          * Preparing to Unlocked when first sync (including email confirmation) has finished.
        //          * Unlocked to Locked on locking (not sync related).

        // SyncState: NotSyncable, ReadyToSync, Syncing, Synced, Error(error: SyncError)
        //      Sync state goes from:
        //          * NotSyncable to Syncing after email confirmation.
        //          * Anything to Syncing at the start of sync after the first syncing starts
        //          * Syncing to Synced after all syncs.
        //
        //      (in sync world email confirmation happens as part of sync, and sync end happens even if not confirmed).
        switch (storageState, syncState, notification.name) {
        case (.Unprepared, _, NotificationNames.ProfileDidStartSyncing):
            syncSubject.onNext(.Syncing)
        case (_, _, NotificationNames.ProfileDidStartSyncing):
            // fall through for the locked and unlocked states.
            syncSubject.onNext(.Syncing)
        case (_, _, NotificationNames.ProfileDidFinishSyncing):
            // end of all syncs
            syncSubject.onNext(.Synced)
        default:
            print("Unexpected state combination: \(storageState) | \(syncState), \(notification.name)")
        }
    }

    private func updateList() {
        do {
            if let loginsStorage = self.loginsStorage {
                if loginsStorage.isLocked() {
                    return
                }

                let loginRecords = try loginsStorage.list()
                let oldStyleLogins = loginRecords.map { (record: LoginRecord) -> Login in
                    return Login(guid: record.id, hostname: record.hostname, username: record.username ?? "", password: record.password)
                }
                self.listSubject.accept(oldStyleLogins)
            }
        } catch let error {
            print("Sync15: \(error)")
        }
    }

    private func makeEmptyList() {
        self.listSubject.accept([])
    }
}

extension BaseDataStore {
    public func remove(id: String) {
//        self.profile.logins.removeLoginByGUID(id) >>== {
//            self.syncSubject.onNext(.ReadyToSync)
//        }
    }

    public func add(item: LoginData) {
//        self.profile.logins.addLogin(item) >>== {
//            self.syncSubject.onNext(.ReadyToSync)
//        }
    }
}

// initialization
extension BaseDataStore {
    private func initializeLoginsStorage() {
        let filename = "logins.db"

        let profileDirName = "profile.\(self.profile.localName())" // FIXME

        // Bug 1147262: First option is for device, second is for simulator.
        var rootPath: String
        let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerIdentifier) {
            rootPath = url.path
        } else {
            print("Unable to find the shared container. Defaulting profile location to ~/Documents instead.")
            rootPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        }

        let files = FileAccessor(rootPath: URL(fileURLWithPath: rootPath).appendingPathComponent(profileDirName).path)
        let file = URL(fileURLWithPath: (try! files.getAndEnsureDirectory())).appendingPathComponent(filename).path

        self.loginsStorage = LoginsStorage(databasePath: file)
    }

    private func initializeProfile() {
        self.profile.syncManager?.applicationDidBecomeActive()

        self.fxaLoginHelper.application(UIApplication.shared, didLoadProfile: profile)
    }

    private func setInitialState() {
        guard profile.hasSyncableAccount() else {
            if !profile.hasAccount() {
                // first run.
                self.storageStateSubject.onNext(.Unprepared)
            }

            self.syncSubject.onNext(.NotSyncable)
            return
        }
        self.syncSubject.onNext(.ReadyToSync)

        // default to locked state on initialized
        self.storageStateSubject.onNext(.Locked)
        self.handleLock()
    }

    internal func handleLock() {
        Observable.combineLatest(
            self.userDefaults.onAutoLockTime,
            self.userDefaults.onForceLock)
            .take(1)
            .subscribe(onNext: { autoLockSetting, forceLock in
                if forceLock {
                    self.lock()
                } else if autoLockSetting == .Never {
                    self.unlock()
                } else {
                    let date = NSDate(
                        timeIntervalSince1970: self.userDefaults.double(
                            forKey: UserDefaultKey.autoLockTimerDate.rawValue))

                    if date.timeIntervalSince1970 > 0 && date.timeIntervalSinceNow > 0 {
                        self.unlock()
                    } else {
                        self.lock()
                    }
                }
            })
        .disposed(by: self.disposeBag)
    }
}
