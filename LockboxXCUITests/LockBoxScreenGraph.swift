/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MappaMundi
import XCTest

class Screen {
    static let WelcomeScreen = "WelcomeScreen"
    static let LockboxMainPage = "LockboxMainPage"
    static let SettingsMenu = "SettingsMenu"

    static let FxASigninScreenEmail = "FxASigninScreenEmail"
    static let FxASigninScreenPassword = "FxASigninScreenPassword"
    static let FxCreateAccount = "FxCreateAccount"

    static let OpenSitesInMenu = "OpenSitesInMenu"
    static let LockedScreen = "LockedScreen"
    static let AccountSettingsMenu = "AccountSettingsMenu"
    static let AutolockSettingsMenu = "AutolockSettingsMenu"

    static let SortEntriesMenu = "SortEntriesMenu"

    static let EntryDetails = "EntryDetails"
}

class Action {
    static let FxATypeEmail = "FxATypeEmail"
    static let FxATypePassword = "FxATypePassword"
    static let FxATapOnSignInButton = "FxATapOnSignInButton"
    static let FxALogInSuccessfully = "FxALogInSuccessfully"

    static let OpenSettingsMenu = "OpenSettingsMenu"

    static let LockNow = "LockNow"
    static let SendUsageData = "SendUsageData"
    static let OpenDeviceSettings = "OpenDeviceSettings"

    static let DisconnectFirefoxLockbox = "DisconnectFirefoxLockbox"
    static let DisconnectFirefoxLockboxCancel = "DisconnectFirefoxLockboxCancel"

    static let ChangeEntriesOrder = "ChangeEntriesOrder"
    static let SelectAlphabeticalOrder = "SelectAlphabeticalOrder"
    static let SelectRecentOrder = "SelectRecentOrder"

    static let RevealPassword = "RevealPassword"
    static let OpenWebsite = "OpenWebsite"
}

@objcMembers
class LockboxUserState: MMUserState {
    required init() {
        super.init()
        initialScreenState = Screen.WelcomeScreen
    }

    var fxaUsername: String? = nil
    var fxaPassword: String? = nil
}

func createScreenGraph(for test: XCTestCase, with app: XCUIApplication) -> MMScreenGraph<LockboxUserState> {
    let map = MMScreenGraph(for: test, with: LockboxUserState.self)

    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    let settingsBackAction = {
        app.buttons["Done"].tap()
    }

    let fxaViewCancelButton = {
        app.navigationBars["Lockbox.FxAView"].buttons["Cancel"].tap()
    }

    map.addScreenState(Screen.WelcomeScreen) { screenState in
            screenState.tap(app.buttons["getStarted.button"], to: Screen.FxASigninScreenEmail)
            screenState.noop(to: Screen.LockboxMainPage)
    }

    map.addScreenState(Screen.FxASigninScreenEmail) { screenState in
        screenState.gesture(forAction: Action.FxATypeEmail, transitionTo: Screen.FxASigninScreenPassword) { userState in
            app.webViews.textFields["Email"].tap()
            app.webViews.textFields["Email"].typeText(userState.fxaUsername!)
            app.webViews.buttons["Continue"].tap()
        }
    }

    map.addScreenState(Screen.FxASigninScreenPassword) { screenState in
        screenState.gesture(forAction: Action.FxATypePassword) { userState in
            app.webViews.secureTextFields["Password"].tap()
            app.webViews.secureTextFields["Password"].typeText(userState.fxaPassword!)
            app.webViews.buttons["Sign in"].tap()
        }
    }


    map.addScreenState(Screen.FxCreateAccount) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(Screen.LockboxMainPage) { screenState in
        screenState.tap(app.buttons["settings.button"], to: Screen.SettingsMenu)
        screenState.tap(app.buttons["sorting.button"], to: Screen.SortEntriesMenu)
        screenState.tap(app.tables.cells.staticTexts.firstMatch, to: Screen.EntryDetails)
    }

    map.addScreenState(Screen.EntryDetails) { screenState in
        screenState.gesture(forAction: Action.RevealPassword) { userState in
            app.buttons["reveal.button"].tap()
        }

        screenState.gesture(forAction: Action.OpenWebsite) { userState in
            app.cells["webAddressItemDetail"].press(forDuration: 1)
        }

    }

    map.addScreenState(Screen.SortEntriesMenu) { screenState in
        screenState.gesture(forAction: Action.SelectAlphabeticalOrder, transitionTo: Screen.LockboxMainPage) { userState in
            app.buttons["Alphabetically"].tap()
        }
        screenState.gesture(forAction: Action.SelectRecentOrder, transitionTo: Screen.LockboxMainPage) { userState in
            app.buttons["Recently Used"].tap()
        }

        screenState.backAction = {
            app.sheets["Sort Entries"].buttons["Cancel"].tap()
        }
    }

    map.addScreenState(Screen.SettingsMenu) { screenState in
        screenState.tap(app.tables.cells["openWebSitesInSettingOption"], to: Screen.OpenSitesInMenu)
        screenState.tap(app.tables.cells["accountSettingOption"], to: Screen.AccountSettingsMenu)
        screenState.tap(app.tables.cells["autoLockSettingOption"], to: Screen.AutolockSettingsMenu)

        screenState.gesture(forAction: Action.SendUsageData) { userState in
            app.switches["sendUsageData.switch"].tap()
        }

        screenState.gesture(forAction: Action.OpenDeviceSettings) { userState in
            app.cells["autoFillSettingsOption"].tap()

        }

        screenState.gesture(forAction: Action.LockNow) { userState in
            app.buttons["lockNow.button"].tap()
        }
        // Back action tapping on Done Button
        screenState.backAction = settingsBackAction
    }

    map.addScreenState(Screen.OpenSitesInMenu) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(Screen.AccountSettingsMenu) { screenState in
        screenState.backAction = navigationControllerBackAction

        screenState.gesture(forAction: Action.DisconnectFirefoxLockbox, transitionTo: Screen.WelcomeScreen) { userState in
            app.buttons["disconnectFirefoxLockbox.button"].tap()
            app.buttons["Disconnect"].tap()
        }
        screenState.gesture(forAction: Action.DisconnectFirefoxLockboxCancel, transitionTo: Screen.AccountSettingsMenu) { userState in
            app.buttons["disconnectFirefoxLockbox.button"].tap()
            app.buttons["Cancel"].tap()
        }
    }

    map.addScreenState(Screen.AutolockSettingsMenu) { screenState in
        screenState.backAction = navigationControllerBackAction
        screenState.dismissOnUse = true
    }

    return map
}

extension BaseTestCase {

    func checkIfAccountIsVerified() {
        if (app.webViews.staticTexts["Confirm this sign-in"].exists) {
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.verifyAccount() {
                    group.leave()
                }
            }
            group.wait()
        }
    }

    func completeVerification(uid: String, code: String, done: @escaping () -> ()) {
        // POST to EndPoint api.accounts.firefox.com/v1/recovery_email/verify_code
        let restUrl = URL(string: postEndPoint)
        var request = URLRequest(url: restUrl!)
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"

        let jsonObject: [String: Any] = ["uid": uid, "code":code]
        let data = try! JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted)
        let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        if let json = json {
            print("json \(json)")
        }
        let jsonData = json?.data(using: String.Encoding.utf8.rawValue)

        request.httpBody = jsonData
        print("json \(jsonData!)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("error:", error)
                return
            }
            done()
        }
        task.resume()
    }

    func verifyAccount(done: @escaping () -> ()) {
        // GET to EndPoint/mail/test-9876@restmail.net
        let restUrl = URL(string: getEndPoint)
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if(error != nil) {
                print("Error: \(error ?? "Get Error" as! Error)")
            }
            let responseString = String(data: data!, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")

            let regexpUid = "(uid=[a-z0-9]{0,32}$?)"
            let regexCode = "(code=[a-z0-9]{0,32}$?)"
            if let rangeUid = responseString?.range(of:regexpUid, options: .regularExpression) {
                uid = String(responseString![rangeUid])
            }

            if let rangeCode = responseString?.range(of:regexCode, options: .regularExpression) {
                code = String(responseString![rangeCode])
            }

            if (code != nil && uid != nil) {
                let codeNumber = self.getPostValues(value: code)
                let uidNumber = self.getPostValues(value: uid)

                self.completeVerification(uid: String(uidNumber), code: String(codeNumber)) {
                    done()
                }
            } else {
                done()
            }
        }
        task.resume()
    }

    func getPostValues(value: String) -> String {
        // From the regExp it is necessary to get only the number to add it to a json and send in POST request
        let finalNumberIndex = value.index(value.endIndex, offsetBy: -32);
        let numberValue = value[finalNumberIndex...];
        return String(numberValue)
    }
}
