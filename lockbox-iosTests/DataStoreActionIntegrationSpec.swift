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
    private let scopedKey = "{\"kty\":\"oct\",\"kid\":\"L9-eBkDrYHdPdXV_ymuzy_u9n3drkQcSw5pskrNl4pg\",\"k\":\"WsTdZ2tjji2W36JN9vk9s2AYsvp8eYy1pBbKPgcSLL4\"}"
    private let uid = "333333333"

    override func spec() {
        var initializeValue: DataStoreAction?
        beforeSuite {
            DataStoreActionHandler.shared.initialize(scopedKey: self.scopedKey, uid: self.uid)

            initializeValue = try! Dispatcher.shared.register
                    .filterByType(class: DataStoreAction.self)
                    .toBlocking().first()
        }

        it("updates initialize value after initializing successfully") {
            expect(initializeValue).notTo(beNil())
            expect(initializeValue).to(equal(DataStoreAction.initialized(initialized: true)))
        }

        describe("DataStore with JavaScript integration") {
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


