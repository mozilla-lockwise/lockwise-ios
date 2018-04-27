/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class ExternalLinkActionSpec: QuickSpec {
    private var application: FakeApplication!
    private var userDefaults: UserDefaults!
    private var testUrl = "https://github.com/mozilla-lockbox/lockbox-ios"

    class FakeApplication: OpenUrlProtocol {
        var openArgument: URL?
        var canOpenURLArgument: URL?

        func open(_ url: URL, options: [String: Any], completionHandler completion: ((Bool) -> Swift.Void)?) {
            self.openArgument = url
        }

        func canOpenURL(_ url: URL) -> Bool {
            self.canOpenURLArgument = url
            return true
        }
    }

    override func spec() {
        describe("PreferredBrowserSetting") {
            beforeEach {
                self.application = FakeApplication()
                self.userDefaults = UserDefaults.standard
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

                    it("creates chrome https deeplinks") {
                        expect(PreferredBrowserSetting.Chrome.getPreferredBrowserDeeplink(url: self.testUrl)?.absoluteString).to(equal("googlechromes://github.com/mozilla-lockbox/lockbox-ios"))
                    }

                    it("creates chrome http deeplinks") {
                        expect(PreferredBrowserSetting.Chrome.getPreferredBrowserDeeplink(url: "http://mozilla.org")?.absoluteString).to(equal("googlechrome://mozilla.org"))
                    }
                }

                describe("canOpenBrowser") {
                    it("tries to open browser") {
                        expect(PreferredBrowserSetting.Safari.canOpenBrowser(application: self.application)).to(beTrue())
                        expect(self.application.canOpenURLArgument?.absoluteString).toNot(beNil())
                    }

                    it("uses an http link for chrome") {
                        expect(PreferredBrowserSetting.Chrome.canOpenBrowser(application: self.application)).to(beTrue())
                        expect(self.application.canOpenURLArgument?.absoluteString).to(equal("googlechrome://mozilla.org"))
                    }
                }
            }

            describe("ExternalLinkActionHandler") {
                var subject: ExternalLinkActionHandler!

                beforeEach {
                    subject = ExternalLinkActionHandler(dispatcher: Dispatcher.shared, application: self.application, userDefaults: self.userDefaults)
                }

                describe("openUrl") {
                    it("opens safari with deeplink") {
                        self.userDefaults.set(PreferredBrowserSetting.Safari.rawValue, forKey: SettingKey.preferredBrowser.rawValue)
                        subject.invoke(ExternalLinkAction(url: self.testUrl))
                        expect(self.application.openArgument?.absoluteString).to(equal(self.testUrl))
                    }

                    it("does not call open on changes to preferred browser setting") {
                        self.userDefaults.set(PreferredBrowserSetting.Firefox.rawValue, forKey: SettingKey.preferredBrowser.rawValue)
                        expect(self.application.openArgument).to(beNil())
                        subject.invoke(ExternalLinkAction(url: self.testUrl))
                        expect(self.application.openArgument?.absoluteString).to(equal("firefox://open-url?url=https%3A%2F%2Fgithub.com%2Fmozilla-lockbox%2Flockbox-ios"))
                        self.application.openArgument = nil
                        self.userDefaults.set(PreferredBrowserSetting.Focus.rawValue, forKey: SettingKey.preferredBrowser.rawValue)
                        expect(self.application.openArgument).to(beNil())
                        subject.invoke(ExternalLinkAction(url: self.testUrl))
                        expect(self.application.openArgument?.absoluteString).to(equal("firefox-focus://open-url?url=https%3A%2F%2Fgithub.com%2Fmozilla-lockbox%2Flockbox-ios"))
                    }
                }
            }
        }
    }
}
