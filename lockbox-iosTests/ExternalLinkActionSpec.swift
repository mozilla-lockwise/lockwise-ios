/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class ExternalLinkActionSpec: QuickSpec {
    private var application: UIApplication!
    private var userDefaults: FakeUserDefaults!
    private var testUrl = "https://github.com/mozilla-lockbox/lockbox-ios"

    class FakeUserDefaults: UserDefaults {
        var keyArgument: String?
        override func string(forKey defaultName: String) -> String? {
            keyArgument = defaultName
            return PreferredBrowserSetting.Firefox.rawValue
        }
    }

    override func spec() {
        describe("PreferredBrowserSetting") {
            beforeEach {
                self.application = UIApplication.shared
                self.userDefaults = FakeUserDefaults()
            }

            describe("PreferredBrowserSetting") {
                describe("getPreferredBrowserDeeplink") {
                    it("creates safari deeplinks") {
                        expect(PreferredBrowserSetting.Safari.getPreferredBrowserDeeplink(url: self.testUrl)?.absoluteString).to(equal(self.testUrl))
                    }

                    it("creates firefox deeplinks") {
                        expect(PreferredBrowserSetting.Firefox.getPreferredBrowserDeeplink(url: self.testUrl)?.absoluteString).to(equal("firefox://open-url?url=https%3A%2F%2Fgithub.com%2Fmozilla-lockbox%2Flockbox-ios"))
                    }

                    it("creates focus deeplinks") {
                        expect(PreferredBrowserSetting.Focus.getPreferredBrowserDeeplink(url: self.testUrl)?.absoluteString).to(equal("firefox-focus://open-url?url=https%3A%2F%2Fgithub.com%2Fmozilla-lockbox%2Flockbox-ios"))
                    }

                    it("creates chrome deeplinks") {
                        expect(PreferredBrowserSetting.Chrome.getPreferredBrowserDeeplink(url: self.testUrl)?.absoluteString).to(equal("googlechrome://\(self.testUrl)"))
                    }
                }
            }

            describe("ExternalLinkActionHandler") {
                var subject: ExternalLinkActionHandler!

                beforeEach {
                    subject = ExternalLinkActionHandler(dispatcher: Dispatcher.shared, application: self.application, userDefaults: self.userDefaults)
                    subject.invoke(ExternalLinkAction(url: self.testUrl))
                }

                describe("openUrl") {


                }
            }
        }
    }
}
