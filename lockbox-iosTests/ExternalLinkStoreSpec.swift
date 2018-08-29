/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class ExternalLinkStoreSpec: QuickSpec {
    private var application: FakeApplication!
    private var dispatcher: Dispatcher!
    private var userDefaults: UserDefaults!
    private var testUrl = "https://github.com/mozilla-lockbox/lockbox-ios"

    class FakeApplication: OpenUrlProtocol {
        var openArgument: URL?
        var canOpenURLArgument: URL?

        func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: ((Bool) -> Void)?) {
            self.openArgument = url
        }
        func canOpenURL(_ url: URL) -> Bool {
            self.canOpenURLArgument = url
            return true
        }
    }

    override func spec() {
        describe("ExternalLinkStore") {
            beforeEach {
                self.dispatcher = .shared
                self.application = FakeApplication()
                self.userDefaults = UserDefaults(suiteName: Constant.app.group)!
                _ = ExternalLinkStore(dispatcher: self.dispatcher,
                                      application: self.application)
            }

            describe("invoke external link") {
                it("opens safari with deeplink") {
                    self.userDefaults.set(Setting.PreferredBrowser.Safari.rawValue, forKey: LocalUserDefaultKey.preferredBrowser.rawValue)
                    self.dispatcher.dispatch(action: ExternalLinkAction(baseURLString: self.testUrl))
                    expect(self.application.openArgument?.absoluteString).to(equal(self.testUrl))
                }

                it("does not call open on changes to preferred browser setting") {
                    self.userDefaults.set(Setting.PreferredBrowser.Firefox.rawValue, forKey: LocalUserDefaultKey.preferredBrowser.rawValue)
                    expect(self.application.openArgument).to(beNil())
                    self.dispatcher.dispatch(action: ExternalLinkAction(baseURLString: self.testUrl))
                    expect(self.application.openArgument?.absoluteString).to(equal("firefox://open-url?url=https%3A%2F%2Fgithub.com%2Fmozilla-lockbox%2Flockbox-ios"))
                    self.application.openArgument = nil
                    self.userDefaults.set(Setting.PreferredBrowser.Focus.rawValue, forKey: LocalUserDefaultKey.preferredBrowser.rawValue)
                    expect(self.application.openArgument).to(beNil())
                    self.dispatcher.dispatch(action: ExternalLinkAction(baseURLString: self.testUrl))
                    expect(self.application.openArgument?.absoluteString).to(equal("firefox-focus://open-url?url=https%3A%2F%2Fgithub.com%2Fmozilla-lockbox%2Flockbox-ios"))
                }
            }

            describe("open setting link") {
                beforeEach {
                    self.dispatcher.dispatch(action: SettingLinkAction.touchIDPasscode)
                }

                it("opens the appropriate string value of the settings page") {
                    let expectedURL = URL(string: "App-Prefs:root=TOUCHID_PASSCODE")
                    expect(self.application.canOpenURLArgument).to(equal(expectedURL))
                    expect(self.application.openArgument).to(equal(expectedURL))
                }
            }
        }
    }
}
