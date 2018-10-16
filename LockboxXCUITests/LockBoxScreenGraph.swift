/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MappaMundi
import XCTest

let emailTestAccountLogins = "test-b62feb2ed6@restmail.net"
let passwordTestAccountLogins = "FRCuQaPm"

var uid: String!
var code: String!

let firstEntryEmail = "iosmztest@gmail.com"

let getEndPoint = "http://restmail.net/mail/test-b62feb2ed6"
let postEndPoint = "https://api.accounts.firefox.com/v1/recovery_email/verify_code"
let deleteEndPoint = "http://restmail.net/mail/test-b62feb2ed6@restmail.net"

let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

let appName = "Lockbox"

class Screen {
    static let WelcomeScreen = "WelcomeScreen"
    static let OnboardingWelcomeScreen = "OnboardingWelcomeScreen"
    static let AutofillOnboardingWhenLogingIn = "AutofillOnboardingWhenLogingIn"
    static let AutofillSetUpInstructionsWhenLogingIn = "AutofillSetUpInstructionsWhenLogingIn"
    static let LockboxMainPage = "LockboxMainPage"
    static let SettingsMenu = "SettingsMenu"

    static let FxASigninScreenEmail = "FxASigninScreenEmail"
    static let FxASigninScreenPassword = "FxASigninScreenPassword"
    static let FxCreateAccount = "FxCreateAccount"

    static let OpenSitesInMenu = "OpenSitesInMenu"
    static let LockedScreen = "LockedScreen"
    static let AccountSettingsMenu = "AccountSettingsMenu"
    static let AutolockSettingsMenu = "AutolockSettingsMenu"
    static let AutoFillSetUpInstructionsSettings = "AutoFillSetUpInstructionsSettings"

    static let SortEntriesMenu = "SortEntriesMenu"

    static let EntryDetails = "EntryDetails"
}

class Action {
    static let FxATypeEmail = "FxATypeEmail"
    static let FxATypePassword = "FxATypePassword"
    static let FxATapOnSignInButton = "FxATapOnSignInButton"
    static let FxALogInSuccessfully = "FxALogInSuccessfully"

    static let NotAutofillSetUpNow = "NotAutofillSetUpNow"
    static let SetAutofillNow = "SetAutofillNow"
    static let TapOnFinish = "TapOnFinish"

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
        screenState.gesture(forAction: Action.FxATypePassword, transitionTo: Screen.AutofillOnboardingWhenLogingIn) { userState in
            app.webViews.secureTextFields["Password"].tap()
            app.webViews.secureTextFields["Password"].typeText(userState.fxaPassword!)
            app.webViews.buttons["Sign in"].tap()
        }
    }

    map.addScreenState(Screen.OnboardingWelcomeScreen) { screenState in
        screenState.gesture(forAction: Action.TapOnFinish, transitionTo: Screen.LockboxMainPage) { userState in
            app.buttons["finish.button"].tap()
        }
    }

    map.addScreenState(Screen.AutofillOnboardingWhenLogingIn) { screenState in
        screenState.gesture(forAction: Action.NotAutofillSetUpNow, transitionTo: Screen.OnboardingWelcomeScreen) { userState in
            app.buttons["notNow.button"].tap()
        }
        screenState.gesture(forAction: Action.SetAutofillNow, transitionTo: Screen.AutofillSetUpInstructionsWhenLogingIn) { userState in
            app.buttons["setupAutofill.button"].tap()
        }
    }

    map.addScreenState(Screen.AutofillSetUpInstructionsWhenLogingIn) { screenState in
        screenState.tap(app.buttons["gotIt.button"], to: Screen.OnboardingWelcomeScreen)
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
        screenState.tap(app.tables.cells["autoFillSettingsOption"], to: Screen.AutoFillSetUpInstructionsSettings)

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
        }
        screenState.gesture(forAction: Action.DisconnectFirefoxLockboxCancel, transitionTo: Screen.AccountSettingsMenu) { userState in
            app.buttons["disconnectFirefoxLockbox.button"].tap()
            app.buttons["Cancel"].tap()
        }
    }

    map.addScreenState(Screen.AutoFillSetUpInstructionsSettings) { screenState in
        screenState.tap(app.buttons["gotIt.button"], to: Screen.SettingsMenu)
    }

    map.addScreenState(Screen.AutolockSettingsMenu) { screenState in
        screenState.backAction = navigationControllerBackAction
        screenState.dismissOnUse = true
    }

    return map
}

extension BaseTestCase {

    func loginFxAccount() {
        userState.fxaPassword = passwordTestAccountLogins
        userState.fxaUsername = "test-b62feb2ed6@restmail.net"
        navigator.goto(Screen.FxASigninScreenEmail)
        waitforExistence(app.navigationBars["Lockbox.FxAView"])
        waitforExistence(app.webViews.textFields["Email"], timeout: 10)
        navigator.performAction(Action.FxATypeEmail)
        waitforExistence(app.webViews.secureTextFields["Password"])
        navigator.performAction(Action.FxATypePassword)
    }

    func skipAutofillConfiguration() {
        if #available(iOS 12.0, *) {
            //If autofill is set this option will not appear
            sleep(3)
            if (app.buttons["setupAutofill.button"].exists) {
                app.buttons["notNow.button"].tap()
            }
        }
    }

    func tapOnAutofillConfiguration() {
        waitforExistence(app.buttons["setupAutofill.button"])
        app.buttons["setupAutofill.button"].tap()
    }

    func tapOnFinishButton() {
        waitforExistence(app.buttons["finish.button"])
        app.buttons["finish.button"].tap()
    }

    func waitForLockboxEntriesListView() {
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
        waitforExistence(app.tables.cells.staticTexts[firstEntryEmail])
        navigator.nowAt(Screen.LockboxMainPage)
    }

    func disconnectAccount() {
        navigator.goto(Screen.LockboxMainPage)
        navigator.performAction(Action.DisconnectFirefoxLockbox)
    }

    func configureAutofillSettings() {
        settings.cells.staticTexts["Passwords & Accounts"].tap()
        settings.cells.staticTexts["AutoFill Passwords"].tap()
        waitforExistence(settings.switches["AutoFill Passwords"], timeout: 3)
        settings.switches["AutoFill Passwords"].tap()
        waitforExistence(settings.cells.staticTexts["Lockbox"])
        settings.cells.staticTexts["Lockbox"].tap()
    }

    func deleteUserInbox() {
        let restUrl = URL(string: deleteEndPoint)
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "DELETE"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print("Delete")
        }
        task.resume()
    }

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

    func deleteApp(name: String) {
        app.terminate()
        let icon = springboard.icons[appName]
        if icon.exists {
            let iconFrame = icon.frame
            let springboardFrame = springboard.frame
            icon.press(forDuration: 1.3)
            springboard.coordinate(withNormalizedOffset: CGVector(dx: (iconFrame.minX + 3 * UIScreen.main.scale) / springboardFrame.maxX, dy: (iconFrame.minY + 3 * UIScreen.main.scale) / springboardFrame.maxY)).tap()
            waitforExistence(springboard.alerts.buttons["Delete"])
            springboard.alerts.buttons["Delete"].tap()
        }
    }
}
