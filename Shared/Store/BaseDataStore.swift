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
    internal let disposeBag = DisposeBag()
    private var listSubject = BehaviorRelay<[Login]>(value: [])
    private var syncSubject = ReplaySubject<SyncState>.create(bufferSize: 1)
    internal var storageStateSubject = ReplaySubject<LoginStoreState>.create(bufferSize: 1)

    private let fxaLoginHelper: FxALoginHelper
    private let profileFactory: ProfileFactory
    private let keychainWrapper: KeychainWrapper
    internal var profile: FxAUtils.Profile
    private let dispatcher: Dispatcher

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

    init(dispatcher: Dispatcher = Dispatcher.shared,
         profileFactory: @escaping ProfileFactory = defaultProfileFactory,
         fxaLoginHelper: FxALoginHelper = FxALoginHelper.sharedInstance,
         keychainWrapper: KeychainWrapper = KeychainWrapper.standard) {
        self.profileFactory = profileFactory
        self.fxaLoginHelper = fxaLoginHelper
        self.keychainWrapper = keychainWrapper

        self.dispatcher = dispatcher
        self.profile = profileFactory(false)
        self.initializeProfile()
        self.registerNotificationCenter()

        dispatcher.register
                .filterByType(class: DataStoreAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .updateCredentials(let oauthInfo, let fxaProfile):
                        self.updateCredentials(oauthInfo, fxaProfile: fxaProfile)
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
                    case .foreground:
                        self.profile.syncManager?.applicationDidBecomeActive()
                    case .startup:
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
            self.storageStateSubject.onNext(.Unlocked)

            self.profile.reopen()

            self.profile.syncManager.syncEverything(why: .startup)
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
}

extension BaseDataStore {
    public func updateCredentials(_ oauthInfo: OAuthInfo, fxaProfile: FxAClient.Profile) {
        guard let keysString = oauthInfo.keys else {
            return
        }

        let keys = JSON(parseJSON: keysString)
        let scopedKey = keys[Constant.fxa.oldSyncScope]

        guard let account = profile.getAccount() else {
            _ = fxaLoginHelper.application(UIApplication.shared,
                                           email: fxaProfile.email,
                                           accessToken: oauthInfo.accessToken,
                                           oauthKeys: scopedKey)
            return
        }

        if let oauthInfoKey = OAuthInfoKey(from: scopedKey) {
            account.makeOAuthLinked(accessToken: oauthInfo.accessToken, oauthInfo: oauthInfoKey)
        }
    }
}

extension BaseDataStore {
    public func touch(id: String) {
        self.profile.logins.addUseOfLoginByGUID(id)
    }
}

extension BaseDataStore {
    private func reset() {
        func stopSyncing() -> Success {
            guard let syncManager = self.profile.syncManager else {
                return succeed()
            }
            syncManager.endTimedSyncs()
            if !syncManager.isSyncing {
                return succeed()
            }

            return syncManager.syncEverything(why: .backgrounded)
        }

        func disconnect() -> Success {
            return self.fxaLoginHelper.applicationDidDisconnect(UIApplication.shared)
        }

        func deleteAll() -> Success {
            return self.profile.logins.removeAll()
        }

        func resetProfile() {
            self.profile = profileFactory(true)
            self.initializeProfile()
            self.syncSubject.onNext(.NotSyncable)
            self.storageStateSubject.onNext(.Unprepared)
        }

        stopSyncing() >>== disconnect >>== deleteAll >>== resetProfile
    }
}

extension BaseDataStore {
    func lock() {
        guard !self.profile.isShutdown else {
            return
        }

        guard self.profile.hasSyncableAccount() else {
            return
        }

        self.profile.syncManager?.endTimedSyncs()

        func finalShutdown() {
            self.profile.shutdown()
        }
        self.storageStateSubject.onNext(.Locked)

        if self.profile.syncManager.isSyncing {
            self.profile.syncManager.syncEverything(why: .backgrounded) >>== finalShutdown
        } else {
            finalShutdown()
        }
    }
}

extension BaseDataStore {
    public func sync() {
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
        let logins = self.profile.logins
        logins.getAllLogins() >>== { (cursor: Cursor<Login>) in
            self.listSubject.accept(cursor.asArray())
        }
    }

    private func makeEmptyList() {
        self.listSubject.accept([])
    }
}

extension BaseDataStore {
    public func remove(id: String) {
        self.profile.logins.removeLoginByGUID(id) >>== {
            self.syncSubject.onNext(.ReadyToSync)
        }
    }

    public func add(item: LoginData) {
        self.profile.logins.addLogin(item) >>== {
            self.syncSubject.onNext(.ReadyToSync)
        }
    }
}

// initialization
extension BaseDataStore {
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
        self.handleLock()
    }

    private func handleLock() {
        // default to locked state
        self.storageStateSubject.onNext(.Locked)

        UserDefaults(suiteName: Constant.app.group)?.onAutoLockTime
                .take(1)
                .subscribe(onNext: { autoLockSetting in
                    switch autoLockSetting {
                    case .Never:
                        self.unlock()
                    default:
                        let date = NSDate(
                                timeIntervalSince1970: UserDefaults.standard.double(
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
