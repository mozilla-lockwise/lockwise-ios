/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let emailTestAccountLogins = "test-b62feb2ed6@restmail.net"
let passwordTestAccountLogins = "FRCuQaPm"

var uid: String!
var code: String!

let firstEntryEmail = "iosmztest@gmail.com"

let getEndPoint = "http://restmail.net/mail/test-b62feb2ed6"
let postEndPoint = "https://api.accounts.firefox.com/v1/recovery_email/verify_code"
let deleteEndPoint = "http://restmail.net/mail/test-b62feb2ed6@restmail.net"

class LockboxXCUITests: BaseTestCase {

    override func setUp() {
        // First Delete the inbox
        let restUrl = URL(string: deleteEndPoint)
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "DELETE"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print("Delete")
        }
        task.resume()
        super.setUp()
    }

    private func completeVerification(uid: String, code: String, done: @escaping () -> ()) {
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

    private func verifyAccount(done: @escaping () -> ()) {
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
                uid = (responseString?.substring(with:rangeUid))!
            }

            if let rangeCode = responseString?.range(of:regexCode, options: .regularExpression) {
                code = (responseString?.substring(with:rangeCode))!
            }

            let finalCodeIndex = code.index(code.endIndex, offsetBy: -32)
            let codeNumber = code[finalCodeIndex...]
            let finalUidIndex = uid.index(uid.endIndex, offsetBy: -32)
            let uidNumber = uid[finalUidIndex...]
            self.completeVerification(uid: String(uidNumber), code: String(codeNumber)) {
                done()
            }
        }
        task.resume()
    }

    func test1LoginWithSavedLogins() {
        snapshot("01Welcome" + CONTENT_SIZE)
        navigator.goto(Screen.FxASigninScreen)
        waitforExistence(app.webViews.textFields["Email"])

        // Try tapping on Sign In, no fields filled in
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Valid email required"])

        // Try incorrect Email then correct and tap on Sign In
        userState.fxaUsername = "test"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Valid email required"])

        userState.fxaUsername = "-b62feb2ed6@restmail.net"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Valid password required"])

        // Enter too short password
        userState.fxaPassword = "ab"
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Must be at least 8 characters"])

        // Remove previous chars
        app.webViews.secureTextFields["Password"].typeText("\u{0008}")
        app.webViews.secureTextFields["Password"].typeText("\u{0008}")

        // Enter valid password and tap on Sign In
        userState.fxaPassword = passwordTestAccountLogins
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxALogInSuccessfully)

        // App should start showing the main page
        waitforExistence(app.buttons["finish.button"])
        app.buttons["finish.button"].tap()
        sleep(8)
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        XCTAssertTrue(app.buttons["sorting.button"].exists)

        let buttonLabelInitally = app.buttons["sorting.button"].label
        XCTAssertEqual(buttonLabelInitally, "Select options for sorting your list of entries (currently A-Z)")

        XCTAssertTrue(app.navigationBars["Firefox Lockbox"].exists)
        XCTAssertTrue(app.navigationBars.buttons["Settings"].exists)
        snapshot("02EntryList" + CONTENT_SIZE)

        sleep(5)
        // Check if the account is verified and if not, verify it
        if (app.staticTexts["Confirm your account."].exists) {
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.verifyAccount() {
                    sleep(5)
                    self.waitforExistence(self.app.staticTexts["No entries found."])
                    group.leave()
                }
            }
            group.wait()
        } else {
            // Account is still verified, check that entries are shown
            waitforExistence(app.tables.cells.staticTexts[firstEntryEmail])
            XCTAssertNotEqual(app.tables.cells.count, 1)
            XCTAssertTrue(app.tables.cells.staticTexts[firstEntryEmail].exists)
        }
    }

    func test2SettingsAccountUI() {
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        snapshot("03Settings" + CONTENT_SIZE)

        navigator.goto(Screen.AccountSettingsMenu)
        waitforExistence(app.navigationBars["Account"])
        // Some checks can be done here to be sure the Account UI is fine
        // To be uncommented once it is sure they appear, now it is not consistent in all run
        //XCTAssertTrue(app.images["avatar-placeholder"].exists, "The image placeholder does not appear")
        XCTAssertTrue(app.staticTexts["username.Label"].exists)
        XCTAssertTrue(app.buttons["disconnectFirefoxLockbox.button"].exists, "The option to disconnect does not appear")
    }

    func test3SettingOpenWebSitesIn() {
        navigator.goto(Screen.OpenSitesInMenu)
        waitforExistence(app.navigationBars["Open Websites in"])
        XCTAssertTrue(app.tables.cells.staticTexts["Firefox"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Firefox Focus"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Google Chrome"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Safari"].exists)
    }

    func test4SortEntries() {
        navigator.goto(Screen.LockboxMainPage)
        sleep(5)
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        navigator.performAction(Action.SelectRecentOrder)
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        let buttonLabelChanged = app.buttons["sorting.button"].label
        XCTAssertEqual(buttonLabelChanged, "Select options for sorting your list of entries (currently Recent)")
        let firstCellRecent = app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellRecent, "wopr.norad.org")
        navigator.goto(Screen.SortEntriesMenu)
        navigator.performAction(Action.SelectAlphabeticalOrder)
        let buttonLabelInitally = app.buttons["sorting.button"].label
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        XCTAssertEqual(buttonLabelInitally, "Select options for sorting your list of entries (currently A-Z)")
        let firstCellAlphabetically = app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellAlphabetically, "accounts.google.com")
    }

    func test5SettingDisconnectAccount() {
        // First Cancel disconnecting the account
        navigator.performAction(Action.DisconnectFirefoxLockboxCancel)
        waitforExistence(app.buttons["disconnectFirefoxLockbox.button"])

        // Now disconnect the account
        navigator.performAction(Action.DisconnectFirefoxLockbox)
        waitforExistence(app.buttons["getStarted.button"])
        app.buttons["getStarted.button"].tap()
        userState.fxaPassword = passwordTestAccountLogins
        waitforExistence(app.staticTexts[emailTestAccountLogins])
        navigator.nowAt(Screen.FxASigninScreen)
        navigator.performAction(Action.FxATypePassword)
        // In small screens it is necessary to dismiss the keyboard
        app.buttons["Done"].tap()
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.buttons["finish.button"])
        app.buttons["finish.button"].tap()
        waitforExistence(app.navigationBars["Firefox Lockbox"])
    }

    func test6SendUsageDataSwitch() {
        navigator.goto(Screen.SettingsMenu)
        // Disable the send usage data
        navigator.performAction(Action.SendUsageData)
        XCTAssertEqual(app.switches["sendUsageData.switch"].value as? String, "0")

        // Enable it again
        navigator.performAction(Action.SendUsageData)
        XCTAssertEqual(app.switches["sendUsageData.switch"].value as? String, "1")
    }

    func test7EntryDetails() {
        navigator.goto(Screen.LockboxMainPage)
        waitforExistence(app.tables.cells.staticTexts["iosmztest@gmail.com"])
        app.tables.cells.staticTexts["iosmztest@gmail.com"].tap()
        XCTAssertTrue(app.tables.cells.staticTexts["Web Address"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Username"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["iosmztest@gmail.com"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Password"].exists)
    }

    func test8ChangeDefaultAutolock() {
        navigator.goto(Screen.SettingsMenu)
        waitforExistence(app.navigationBars["Settings"])
        navigator.goto(Screen.AutolockSettingsMenu)

        app.cells.staticTexts["Never"].tap()
        navigator.goto(Screen.LockboxMainPage)
        // Send app to background and launch it
        XCUIDevice.shared.press(.home)
        app.activate()
        waitforExistence(app.tables.cells.staticTexts["iosmztest@gmail.com"])
    }

    func test9LockNowUnlock() {
        navigator.goto(Screen.LockboxMainPage)
        navigator.performAction(Action.LockNow)
        waitforExistence(app.buttons["Unlock Firefox Lockbox"])
        app.buttons["Unlock Firefox Lockbox"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitforExistence(springboard.secureTextFields["Passcode field"])
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tap()
        passcodeInput.typeText("0000\r")
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        disconnectAccount()
    }

    private func disconnectAccount() {
        navigator.nowAt(Screen.LockboxMainPage)
        navigator.performAction(Action.DisconnectFirefoxLockbox)
        waitforExistence(app.buttons["getStarted.button"])
        app.buttons["getStarted.button"].tap()
        waitforExistence(app.staticTexts[emailTestAccountLogins])
        app.webViews.links["Use a different account"].tap()
        waitforExistence(app.webViews.textFields["Email"])
    }
}
