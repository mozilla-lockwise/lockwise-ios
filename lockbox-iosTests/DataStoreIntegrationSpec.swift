/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxSwift
import RxBlocking

@testable import lockbox_ios

class DataStoreIntegrationSpec : QuickSpec {

    var subject:DataStore!
    private let password = "password"

    override func spec() {
        beforeSuite {
            let vc = UIViewController(nibName: nil, bundle: nil)
            UIApplication.shared.delegate!.window!!.rootViewController = vc

            var webView = WebView(frame: .zero, configuration: WKWebViewConfiguration())
            self.subject = DataStore(webView: &webView)

            vc.view.addSubview(webView)

            _ = try! self.subject.dataStoreLoaded().toBlocking().first()
        }

        describe("DataStore with JavaScript integration") {
            var initializeValue:Any?
            let item = Item.Builder()
                    .title("cats")
                    .origins(["www.meow.com"])
                    .entry(ItemEntry.Builder().kind("login").build())
                    .build()

            beforeEach {
                // only initialize once
                if (initializeValue == nil) {
                    initializeValue = try! self.subject.open().flatMap { _ in
                        let initialized = try! self.subject.initialized().toBlocking().first()!
                        if !initialized {
                            return self.subject.initialize(password: self.password)
                        }

                        return Single.just("")
                    }.toBlocking().first()
                }

                if (try! self.subject.locked().toBlocking().first()!) {
                    _ = try! self.subject.unlock(password: self.password).toBlocking().first()
                }
            }

            it("calls back from javascript after initialization") {
                expect(initializeValue).notTo(beNil())
            }

            it("calls back from javascript after adding item") {
                let addedItem = try! self.subject.addItem(item).toBlocking().first()

                expect(addedItem!.title).to(equal(item.title))
                expect(addedItem!.origins).to(equal(item.origins))
            }

            it("calls back from javascript after adding & getting items") {
                let addedItem = try! self.subject.addItem(item).toBlocking().first()
                let gottenItem = try! self.subject.getItem(addedItem!.id!).toBlocking().first()

                expect(gottenItem!.title).to(equal(item.title))
                expect(gottenItem!.origins).to(equal(item.origins))
            }

            it("calls back from javascript after adding & listing items") {
                var itemList = try! self.subject.addItem(item)
                        .flatMap { _ in
                            return self.subject.list()
                        }
                        .toBlocking().first()

                expect(itemList![0].title).to(equal(item.title))
                expect(itemList![0].origins).to(equal(item.origins))
            }

            it("calls back from javascript after adding & updating items") {
                let newTagsValue = ["fancy.feast"]
                let addedItem = try! self.subject.addItem(item).toBlocking().first()
                addedItem!.tags = newTagsValue

                let updatedItem = try! self.subject.updateItem(addedItem!).toBlocking().first()

                expect(updatedItem!.tags).to(equal(newTagsValue))
            }

            it("calls back from javascript after adding & deleting items") {
                let addedItem = try! self.subject.addItem(item).toBlocking().first()

                let deletedValue = try! self.subject.deleteItem(addedItem!).toBlocking().first()
                expect(deletedValue).notTo(beNil())
            }

            it("calls back from javascript after locking & unlocking") {
                let lockValue = try! self.subject.lock().toBlocking().first()
                expect(lockValue).notTo(beNil())

                let unlockValue = try! self.subject.unlock(password: self.password).toBlocking().first()
                expect(unlockValue).notTo(beNil())
            }
    }
    }
}


