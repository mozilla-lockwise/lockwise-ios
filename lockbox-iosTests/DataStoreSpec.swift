/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxBlocking
import SwiftKeychainWrapper
import MozillaAppServices

@testable import Lockbox

class DataStoreSpec: QuickSpec {
    class FakeLoginsStorage: LoginsStorageProtocol {
        var closeCalled = false
        var lockedStub = false
        var ensureUnlockedArgument: String?
        var ensureLockedCalled = false
        var syncArgument: SyncUnlockInfo?
        var wipeLocalCalled = false
        var getIdArgument: String?
        var getStub: LoginRecord?
        var touchIdArgument: String?
        var listStub: [LoginRecord] = []

        func close() {
            closeCalled = true
        }

        func isLocked() -> Bool {
            return lockedStub
        }

        func ensureUnlocked(withEncryptionKey key: String) throws {
            self.ensureUnlockedArgument = key
        }

        func ensureLocked() {
            self.ensureLockedCalled = true
        }

        func sync(unlockInfo: SyncUnlockInfo) throws {
            self.syncArgument = unlockInfo
        }

        func wipeLocal() throws {
            self.wipeLocalCalled = true
        }

        func get(id: String) throws -> LoginRecord? {
            self.getIdArgument = id
            return self.getStub
        }

        func touch(id: String) throws {
            self.touchIdArgument = id
        }

        func list() throws -> [LoginRecord] {
            return listStub
        }

        func clearInvocations() {
            self.closeCalled = false
            self.ensureUnlockedArgument = nil
            self.ensureLockedCalled = false
            self.syncArgument = nil
            self.wipeLocalCalled = false
            self.getIdArgument = nil
            self.touchIdArgument = nil
        }
    }

    class FakeDataStoreSupport: DataStoreSupport {
        var createArgument: String?
        let loginsStorage: LoginsStorageProtocol

        init(loginsStorageStub: LoginsStorageProtocol) {
            self.loginsStorage = loginsStorageStub
        }

        override func createLoginsStorage(databasePath: String) -> LoginsStorageProtocol {
            return self.loginsStorage
        }
    }

    class FakeAutoLockSupport: AutoLockSupport {
        var lockRequiredStub: Bool = false
        var storeNextTimeCalled = false
        var backdateCalled = false
        var forwardDateCalled = false

        override var lockCurrentlyRequired: Bool {
            return self.lockRequiredStub
        }

        override func storeNextAutolockTime() {
            self.storeNextTimeCalled = true
        }

        override func forwardDateNextLockTime() {
            self.forwardDateCalled = true
        }

        override func backDateNextLockTime() {
            self.backdateCalled = true
        }
    }

    class FakeKeychainWrapper: KeychainWrapper {
        var saveArguments: [String: String] = [:]
        var saveSuccess: Bool!
        var retrieveResult: [String: String] = [:]

        override func set(_ value: String, forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
            self.saveArguments[key] = value
            return saveSuccess
        }

        override func string(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> String? {
            return retrieveResult[key]
        }

        init() {
            super.init(serviceName: "blah")
        }
    }

    class FakeLifecycleStore: LifecycleStore {
        var fakeCycle = PublishSubject<LifecycleAction>()

        override var lifecycleEvents: Observable<LifecycleAction> {
            return self.fakeCycle.asObservable()
        }
    }

    class FakeDataStoreImpl: BaseDataStore {
        override init(dispatcher: Dispatcher = Dispatcher.shared,
             keychainWrapper: KeychainWrapper = KeychainWrapper.standard,
             autoLockSupport: AutoLockSupport = AutoLockSupport.shared,
             dataStoreSupport: DataStoreSupport = DataStoreSupport.shared,
             accountStore: BaseAccountStore = AccountStore.shared,
             networkStore: NetworkStore = NetworkStore.shared,
             lifecycleStore: LifecycleStore = LifecycleStore.shared) {
            super.init(
                    dispatcher: dispatcher,
                    keychainWrapper: keychainWrapper,
                    autoLockSupport: autoLockSupport,
                    dataStoreSupport: dataStoreSupport,
                    accountStore: accountStore,
                    networkStore: networkStore,
                    lifecycleStore: lifecycleStore
            )
        }

        override func initialized() {}
    }

    private var loginsStorage: FakeLoginsStorage!
    private var logins: [LoginRecord] = [
        LoginRecord(fromJSONDict: [:]),
        LoginRecord(fromJSONDict: [:]),
        LoginRecord(fromJSONDict: [:]),
        LoginRecord(fromJSONDict: [:]),
        LoginRecord(fromJSONDict: [:])
    ]

    private let scheduler = TestScheduler.init(initialClock: 0)
    private let disposeBag = DisposeBag()
    private var listObserver: TestableObserver<[LoginRecord]>!
    private var stateObserver: TestableObserver<LoginStoreState>!
    private var syncObserver: TestableObserver<SyncState>!

    private var dispatcher: Dispatcher!
    private var keychainWrapper: FakeKeychainWrapper!
    private var autoLockSupport: FakeAutoLockSupport!
    private var dataStoreSupport: FakeDataStoreSupport!
    private var lifecycleStore: FakeLifecycleStore!
    var subject: BaseDataStore!

    override func spec() {
        describe("DataStore") {
            beforeEach {
                self.loginsStorage = FakeLoginsStorage()
                self.dispatcher = Dispatcher()
                self.keychainWrapper = FakeKeychainWrapper()
                self.autoLockSupport = FakeAutoLockSupport()
                self.dataStoreSupport = FakeDataStoreSupport(loginsStorageStub: self.loginsStorage)
                self.lifecycleStore = FakeLifecycleStore()
                self.subject = FakeDataStoreImpl(
                        dispatcher: self.dispatcher,
                        keychainWrapper: self.keychainWrapper,
                        autoLockSupport: self.autoLockSupport,
                        dataStoreSupport: self.dataStoreSupport,
                        lifecycleStore: self.lifecycleStore
                )

                self.loginsStorage.listStub = self.logins

                self.stateObserver = self.scheduler.createObserver(LoginStoreState.self)
                self.listObserver = self.scheduler.createObserver([LoginRecord].self)
                self.syncObserver = self.scheduler.createObserver(SyncState.self)

                self.subject.list
                    .subscribe(self.listObserver)
                    .disposed(by: self.disposeBag)

                self.subject.syncState
                    .subscribe(self.syncObserver)
                    .disposed(by: self.disposeBag)

                self.subject.storageState
                    .subscribe(self.stateObserver)
                    .disposed(by: self.disposeBag)
            }

            it("takes initialization steps") {
                expect(self.dataStoreSupport.createArgument).notTo(beNil())
            }

            describe("reset / unprepared state") {
                beforeEach {
                    self.dispatcher.dispatch(action: DataStoreAction.reset)
                }

                it("pushes unprepared and wipes the loginsstorage") {
                    expect(self.loginsStorage.ensureUnlockedArgument).notTo(beNil())
                    expect(self.loginsStorage.wipeLocalCalled).to(beTrue())
                    expect(self.listObserver.events.last!.value.element!).to(beEmpty())
                    expect(self.stateObserver.events.last!.value.element!).to(equal(LoginStoreState.Unprepared))
                }
            }
        }
    }
}
