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

    static let FxASigninScreen = "FxASigninScreen"
    static let FxCreateAccount = "FxCreateAccount"
    static let FxASigninScreenSavedUser = "FxASigninScreenSavedUser"

    static let OpenSitesInMenu = "OpenSitesInMenu"
    static let LockedScreen = "LockedScreen"
    static let AccountSettingsMenu = "AccountSettingsMenu"
    static let AutolockSettingsMenu = "AutolockSettingsMenu"

    static let SortEntriesMenu = "SortEntriesMenu"
}

class Action {
    static let FxATypeEmail = "FxATypeEmail"
    static let FxATypePassword = "FxATypePassword"
    static let FxATapOnSignInButton = "FxATapOnSignInButton"
    static let FxALogInSuccessfully = "FxALogInSuccessfully"
    static let DisconnectUser = "DisconnectUser"

    static let OpenSettingsMenu = "OpenSettingsMenu"

    static let LockNow = "LockNow"
    static let SendUsageData = "SendUsageData"

    static let DisconnectFirefoxLockbox = "DisconnectFirefoxLockbox"
    static let DisconnectFirefoxLockboxCancel = "DisconnectFirefoxLockboxCancel"

    static let ChangeEntriesOrder = "ChangeEntriesOrder"
    static let SelectAlphabeticalOrder = "SelectAlphabeticalOrder"
    static let SelectRecentOrder = "SelectRecentOrder"
}

@objcMembers
class LockboxUserState: MMUserState {
    required init() {
        super.init()
        initialScreenState = Screen.WelcomeScreen
    }

    var fxaUsername: String? = nil
    var fxaPassword: String? = nil
    var savedUser = false
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
            screenState.tap(app.buttons["getStarted.button"], to: Screen.FxASigninScreen, if: "savedUser = false")

            screenState.tap(app.buttons["getStarted.button"], to: Screen.FxASigninScreenSavedUser, if: "savedUser = true")

            screenState.noop(to: Screen.LockboxMainPage)
    }

    map.addScreenState(Screen.FxASigninScreenSavedUser) { screenState in
        screenState.gesture(forAction: Action.DisconnectUser, transitionTo: Screen.FxASigninScreen) { userState in
            app.webViews.links["Use a different account"].tap()
        }
    }

    map.addScreenState(Screen.FxASigninScreen) { screenState in
        screenState.gesture(forAction: Action.FxATypeEmail) { userState in
            app.webViews.textFields["Email"].tap()
            app.webViews.textFields["Email"].typeText(userState.fxaUsername!)
        }
        screenState.gesture(forAction: Action.FxATypePassword) { userState in
            app.webViews.secureTextFields["Password"].tap()
            app.webViews.secureTextFields["Password"].typeText(userState.fxaPassword!)
        }
        screenState.gesture(forAction: Action.FxATapOnSignInButton) { userState in
            app.webViews.buttons["Sign in"].tap()
        }

        screenState.gesture(forAction: Action.FxALogInSuccessfully, transitionTo: Screen.LockboxMainPage) { userState in
            app.webViews.buttons["Sign in"].tap()
            userState.fxaUsername = userState.fxaUsername!
            userState.fxaPassword = userState.fxaPassword!
        }
        screenState.tap(app.webViews.links["Create an account"], to: Screen.FxCreateAccount)
    }

    map.addScreenState(Screen.FxCreateAccount) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(Screen.LockboxMainPage) { screenState in
        screenState.tap(app.buttons["settings.button"], to: Screen.SettingsMenu)
        screenState.tap(app.buttons["sorting.button"], to: Screen.SortEntriesMenu)
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
        screenState.tap(app.tables.cells.staticTexts["Open Websites in"], to: Screen.OpenSitesInMenu)
        screenState.tap(app.tables.cells.staticTexts["Account"], to: Screen.AccountSettingsMenu)
        screenState.tap(app.tables.cells.staticTexts["Auto Lock"], to: Screen.AutolockSettingsMenu)

        screenState.gesture(forAction: Action.SendUsageData) { userState in
            app.switches["sendUsageData.switch"].tap()
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
            userState.savedUser = !userState.savedUser
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

    func waitForMainPage() {
        let app = XCUIApplication()
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 10)
    }

    func enterDataAndTapOnSignIn() {
        waitforExistence(app.webViews.secureTextFields["Password"])
        userState.fxaUsername = emailTestAccountLogins
        navigator.performAction(Action.FxATypeEmail)
        userState.fxaPassword = passwordTestAccountLogins
        navigator.performAction(Action.FxATypePassword)

        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.buttons["finish.button"])
        app.buttons["finish.button"].tap()
        waitForMainPage()
    }

    func disconnectAccount() {
        navigator.performAction(Action.DisconnectFirefoxLockbox)
        waitforExistence(app.buttons["getStarted.button"])
        userState.savedUser = true
        navigator.goto(Screen.FxASigninScreenSavedUser)
        navigator.performAction(Action.DisconnectUser)
        waitforExistence(app.webViews.textFields["Email"], timeout: 10)
    }

    func logInFxAcc() {
        //navigator.nowAt(Screen.FxASigninScreen)
        enterDataAndTapOnSignIn()
        checkIfAccountIsVerified()
        waitForMainPage()
    }

    func checkIfAccountIsVerified() {
        if (app.staticTexts["Confirm your account."].exists) {
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.verifyAccount() {
                    group.leave()
                }
            }
            group.wait()
            waitforNoExistence(app.staticTexts["Confirm your account."], timeoutValue: 5)
            waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 20)
        } else {
            // Account is still verified, check that entries are shown
            waitforNoExistence(app.staticTexts["Confirm your account."], timeoutValue: 5)
            waitforExistence(app.tables.cells.staticTexts[firstEntryEmail])
            XCTAssertNotEqual(app.tables.cells.count, 1)
            XCTAssertTrue(app.tables.cells.staticTexts[firstEntryEmail].exists)
        }
        navigator.nowAt(Screen.LockboxMainPage)
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
