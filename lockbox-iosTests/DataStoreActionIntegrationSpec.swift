/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxSwift
import RxBlocking

@testable import Lockbox

class DataStoreHandlerIntegrationSpec : QuickSpec {
    private let scopedKey = "{\"kty\":\"oct\",\"kid\":\"kUIwo-jEhthmgdF_NhVAJesXh9OakaOfCWsmueU2MXA\",\"alg\":\"A256GCM\",\"k\":\"_6nSctCGlXWOOfCV6Faaieiy2HJri0qSjQmBvxYRlT8\"}"
    private let uid = "333333333"

    override func spec() {
        var initializeValue: [DataStoreAction]?
        var openedValue: DataStoreAction?
        beforeSuite {
            DataStoreActionHandler.shared.open(uid: self.uid)

            openedValue = try! Dispatcher.shared.register
                    .filterByType(class: DataStoreAction.self)
                    .take(3)
                    .toBlocking()
                    .first()

            DataStoreActionHandler.shared.initialize(scopedKey: self.scopedKey)

            initializeValue = try! Dispatcher.shared.register
                    .filterByType(class: DataStoreAction.self)
                    .take(3)
                    .toBlocking()
                    .toArray()
        }

        it("updates initialize & open value after opening & initializing successfully") {
            expect(openedValue).notTo(beNil())
            expect(openedValue).to(equal(DataStoreAction.opened(opened: true)))
            expect(initializeValue).notTo(beNil())
            expect(initializeValue).to(contain(DataStoreAction.initialized(initialized: true)))
        }

        xdescribe("DataStore with JavaScript integration") {
            var unlockValue:DataStoreAction?

            beforeEach {
                DataStoreActionHandler.shared.unlock(scopedKey: self.scopedKey)

                unlockValue = try! Dispatcher.shared.register
                        .filterByType(class: DataStoreAction.self)
                        .toBlocking().first()
            }

            it("unlocks appropriately") {
                expect(unlockValue).notTo(beNil())
                expect(unlockValue).to(equal(DataStoreAction.locked(locked: false)))
            }

            it("calls back from javascript with list of items") {
                DataStoreActionHandler.shared.list()

                let listValue = try! Dispatcher.shared.register
                        .filterByType(class: DataStoreAction.self)
                        .toBlocking().first()

                expect(listValue).to(equal(DataStoreAction.list(list: [])))
            }

            it("calls back from javascript after locking & unlocking") {
                DataStoreActionHandler.shared.lock()

                let lockValue = try! Dispatcher.shared.register
                        .filterByType(class: DataStoreAction.self)
                        .toBlocking().first()
                expect(lockValue).notTo(beNil())
                expect(lockValue).to(equal(DataStoreAction.locked(locked: true)))

                DataStoreActionHandler.shared.unlock(scopedKey: self.scopedKey)

                let reUnlockValue = try! Dispatcher.shared.register
                        .filterByType(class: DataStoreAction.self)
                        .toBlocking().first()
                expect(reUnlockValue).notTo(beNil())
                expect(reUnlockValue).to(equal(DataStoreAction.locked(locked: false)))
            }
    }
    }
}


