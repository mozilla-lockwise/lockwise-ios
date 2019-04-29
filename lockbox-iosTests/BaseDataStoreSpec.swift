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

class BaseDataStoreSpec: QuickSpec {
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
            self.createArgument = databasePath
            return self.loginsStorage
        }

        func clearInvocations() {
            self.createArgument = nil
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

        func clearInvocations() {
            self.storeNextTimeCalled = false
            self.backdateCalled = false
            self.forwardDateCalled = false
        }
    }

    class FakeKeychainWrapper: KeychainWrapper {
        var hasValueStub: Bool = true
        var saveArguments: [String: String] = [:]
        var saveSuccess: Bool = true
        var retrieveResult: [String: String] = ["sqlcipher.key.logins.db": "sdffdsfds"]

        override func set(_ value: String, forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
            self.saveArguments[key] = value
            return saveSuccess
        }

        override func hasValue(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
            return hasValueStub
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
        override init(dispatcher: Dispatcher,
                      keychainWrapper: KeychainWrapper,
                      autoLockSupport: AutoLockSupport,
                      dataStoreSupport: DataStoreSupport,
                      networkStore: NetworkStore = NetworkStore.shared,
                      lifecycleStore: LifecycleStore) {
            super.init(
                    dispatcher: dispatcher,
                    keychainWrapper: keychainWrapper,
                    autoLockSupport: autoLockSupport,
                    dataStoreSupport: dataStoreSupport,
                    networkStore: networkStore,
                    lifecycleStore: lifecycleStore
            )
        }

        override func initialized() {
        }
    }

    private var loginsStorage: FakeLoginsStorage!
    private var logins: [LoginRecord] = [
        LoginRecord(fromJSONDict: [:]),
        LoginRecord(fromJSONDict: [:]),
        LoginRecord(fromJSONDict: [:]),
        LoginRecord(fromJSONDict: [:]),
        LoginRecord(fromJSONDict: [:])
    ]
    private var syncInfo = SyncUnlockInfo(
            kid: "fdsfdssd",
            fxaAccessToken: "fsdffds",
            syncKey: "lkfskjlfds",
            tokenserverURL: "www.mozilla.org"
    )

    private let scheduler = TestScheduler.init(initialClock: 0)
    private let disposeBag = DisposeBag()
    private var listObserver: TestableObserver<[LoginRecord]>!
    private var syncObserver: TestableObserver<SyncState>!

    private var dispatcher: Dispatcher!
    private var keychainWrapper: FakeKeychainWrapper!
    private var autoLockSupport: FakeAutoLockSupport!
    private var dataStoreSupport: FakeDataStoreSupport!
    private var lifecycleStore: FakeLifecycleStore!
    var subject: BaseDataStore!

    override func spec() {
        describe("BaseDataStoreSpec") {
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

                self.listObserver = self.scheduler.createObserver([LoginRecord].self)
                self.syncObserver = self.scheduler.createObserver(SyncState.self)

                self.subject.list
                        .subscribe(self.listObserver)
                        .disposed(by: self.disposeBag)

                self.subject.syncState
                        .subscribe(self.syncObserver)
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
                    let state = try! self.subject.storageState.toBlocking().first()
                    expect(state).to(equal(.Unprepared))
                    expect(self.loginsStorage.wipeLocalCalled).to(beTrue())
                }

                describe("getting background events") {
                    it("closes the database and does not interact with autolock support") {
                        self.lifecycleStore.fakeCycle.onNext(.background)
                        expect(self.autoLockSupport.storeNextTimeCalled).to(beFalse())
                        expect(self.loginsStorage.closeCalled).to(beTrue())
                    }
                }

                describe("getting foreground events") {
                    it("re-opens the database and does not interact with locking or state") {
                        self.loginsStorage.clearInvocations()
                        self.dataStoreSupport.clearInvocations()
                        self.lifecycleStore.fakeCycle.onNext(.foreground)
                        _ = try! self.subject.storageState.toBlocking().first()
                        expect(self.dataStoreSupport.createArgument).notTo(beNil())
                        expect(self.loginsStorage.ensureUnlockedArgument).notTo(beNil())
                        expect(self.loginsStorage.ensureLockedCalled).to(beFalse())
                        expect(self.listObserver.events.last!.value.element!).to(beEmpty())
                    }
                }
            }

            describe("when the datastore is unlocked from new credentials") {
                beforeEach {
                    let syncCred = SyncCredential(syncInfo: self.syncInfo, isNew: true)
                    self.dispatcher.dispatch(action: DataStoreAction.updateCredentials(syncInfo: syncCred))
                }

                describe("backgrounding actions") {
                    beforeEach {
                        self.lifecycleStore.fakeCycle.onNext(.background)
                    }

                    it("stores the next autolock time") {
                        expect(self.autoLockSupport.storeNextTimeCalled).to(beTrue())
                    }
                }

                describe("foregrounding actions") {
                    beforeEach {
                        self.loginsStorage.clearInvocations()
                    }

                    describe("when the app should lock") {
                        beforeEach {
                            self.autoLockSupport.lockRequiredStub = true
                            self.lifecycleStore.fakeCycle.onNext(.foreground)
                        }

                        it("locks") {
                            let state = try! self.subject.storageState.toBlocking().first()
                            expect(self.loginsStorage.ensureLockedCalled).to(beTrue())
                            expect(state).to(equal(LoginStoreState.Locked))
                        }
                    }

                    describe("when the app should not lock") {
                        beforeEach {
                            self.autoLockSupport.lockRequiredStub = false
                            self.lifecycleStore.fakeCycle.onNext(.foreground)
                        }

                        it("stays unlocked & emits no new values") {
                            let state = try! self.subject.storageState.toBlocking().first()
                            expect(self.loginsStorage.ensureUnlockedArgument).notTo(beNil())
                            expect(state).to(equal(LoginStoreState.Unlocked))
                        }
                    }
                }

                describe("external lock actions") {
                    beforeEach {
                        self.loginsStorage.clearInvocations()
                        self.autoLockSupport.clearInvocations()
                        self.dispatcher.dispatch(action: DataStoreAction.lock)
                    }

                    it("backdates the next lock time and locks the db") {
                        expect(self.autoLockSupport.backdateCalled).to(beTrue())
                        let state = try! self.subject.storageState.toBlocking().first()
                        expect(self.loginsStorage.ensureLockedCalled).to(beTrue())
                        expect(state).to(equal(LoginStoreState.Locked))
                    }
                }
            }

            describe("when the datastore is locked") {
                beforeEach {
                    let syncCred = SyncCredential(syncInfo: self.syncInfo, isNew: true)
                    self.dispatcher.dispatch(action: DataStoreAction.updateCredentials(syncInfo: syncCred))
                    self.dispatcher.dispatch(action: DataStoreAction.lock)
                }

                describe("external unlock actions") {
                    beforeEach {
                        self.loginsStorage.clearInvocations()
                        self.autoLockSupport.clearInvocations()
                        self.dispatcher.dispatch(action: DataStoreAction.unlock)
                    }

                    it("forward dates the next lock time and unlocks the db") {
                        expect(self.autoLockSupport.forwardDateCalled).to(beTrue())
                        _ = try! self.subject.storageState.toBlocking().first()
                        expect(self.loginsStorage.ensureUnlockedArgument).notTo(beNil())
                    }
                }
            }

            describe("lifecycle interactions") {
                describe("background events") {
                    beforeEach {
                        self.loginsStorage.clearInvocations()
                        self.lifecycleStore.fakeCycle.onNext(.background)
                    }

                    it("closes the db") {
                        expect(self.loginsStorage.closeCalled).to(beTrue())
                    }
                }

                describe("shutdown events") {
                    beforeEach {
                        self.loginsStorage.clearInvocations()
                        self.lifecycleStore.fakeCycle.onNext(.shutdown)
                    }

                    it("closes the db") {
                        expect(self.loginsStorage.closeCalled).to(beTrue())
                    }
                }

                describe("foreground events") {
                    beforeEach {
                        self.dataStoreSupport.clearInvocations()
                        self.lifecycleStore.fakeCycle.onNext(.foreground)
                    }

                    it("re-inits the datastore") {
                        expect(self.dataStoreSupport.createArgument).notTo(beNil())
                    }
                }
            }
        }
    }
}
