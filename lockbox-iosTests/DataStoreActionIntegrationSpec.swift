/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxSwift
import RxBlocking

@testable import Lockbox

class DataStoreHandlerIntegrationSpec: QuickSpec {
    private let scopedKey = "{\"kty\":\"oct\",\"kid\":\"kUIwo-jEhthmgdF_NhVAJesXh9OakaOfCWsmueU2MXA\",\"alg\":\"A256GCM\",\"k\":\"_6nSctCGlXWOOfCV6Faaieiy2HJri0qSjQmBvxYRlT8\"}" // swiftlint:disable:this line_length
    private let uid = "333333333"
    private let disposeBag = DisposeBag()

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

        describe("DataStore with JavaScript integration") {
            var unlockValue: DataStoreAction?

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

                expect(listValue).to(equal(DataStoreAction.list(list: [:])))
            }

            it("pushes the updated value when touching an item") {
                DataStoreActionHandler.shared.populateTestData()

                let listValue = try! Dispatcher.shared.register
                        .filterByType(class: DataStoreAction.self)
                        .toBlocking()
                        .first()

                guard case let DataStoreAction.list(list: items) = listValue! else {
                    fail("wrong action!")
                    return
                }

                let addedItem = items.first!.value
                let lastUsed = addedItem.lastUsed
                expect(lastUsed).to(beNil())

                DataStoreActionHandler.shared.touch(addedItem)

                let updated = try! Dispatcher.shared.register
                        .filterByType(class: DataStoreAction.self)
                        .toBlocking().first()

                guard case let DataStoreAction.updated(item: updatedItem) = updated! else {
                    fail("wrong action!")
                    return
                }

                expect(updatedItem.lastUsed).notTo(beNil())
                expect(updatedItem.lastUsedDate).to(beCloseTo(Date(timeIntervalSinceNow: 0), within: 1.0))
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
