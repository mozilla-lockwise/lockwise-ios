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

    override func tearDown() {
        navigator.goto(Screen.LockboxMainPage)
        disconnectAccount()
        super.tearDown()
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

    private func getPostValues(value: String) -> String {
        // From the regExp it is necessary to get only the number to add it to a json and send in POST request
        let finalNumberIndex = value.index(value.endIndex, offsetBy: -32);
        let numberValue = value[finalNumberIndex...];
        return String(numberValue)
    }

    private func disconnectAccount() {
        navigator.nowAt(Screen.LockboxMainPage)
        navigator.performAction(Action.DisconnectFirefoxLockbox)
        waitforExistence(app.buttons["getStarted.button"])
        app.buttons["getStarted.button"].tap()
        waitforExistence(app.staticTexts[emailTestAccountLogins])
        app.webViews.links["Use a different account"].tap()
        waitforExistence(app.webViews.textFields["Email"], timeout: 10)
    }

    private func preTestStatus() {
        // App can start with user logged out, user logged out (email saved), user logged in
        if (app.navigationBars["Firefox Lockbox"].exists) {
            disconnectAccount()
            logInAgain()
        } else if (app.staticTexts[emailTestAccountLogins].exists){
            app.webViews.links["Use a different account"].tap()
            waitforExistence(app.webViews.textFields["Email"], timeout: 10)
            logInAgain()
        } else {
            firstLogin()
        }
    }

    private func logInAgain() {
        navigator.nowAt(Screen.FxASigninScreen)
        enterDataAndTapOnSignIn()
        sleep(5)
        checkIfAccountIsVerified()
        waitForMainPage()
    }

    private func firstLogin() {
        navigator.goto(Screen.FxASigninScreen)
        waitforExistence(app.webViews.secureTextFields["Password"])

        enterDataAndTapOnSignIn()
        sleep(5)
        // Check if the account is verified and if not, verify it
        checkIfAccountIsVerified()
        waitForMainPage()
    }

    private func enterDataAndTapOnSignIn() {
        userState.fxaUsername = emailTestAccountLogins
        navigator.performAction(Action.FxATypeEmail)
        userState.fxaPassword = passwordTestAccountLogins
        navigator.performAction(Action.FxATypePassword)

        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.buttons["finish.button"])
        app.buttons["finish.button"].tap()
    }

    private func waitForMainPage() {
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 10)
    }

    func testLogin() {
        if (app.navigationBars["Firefox Lockbox"].exists) {
            disconnectAccount()
            navigator.nowAt(Screen.FxASigninScreen)
        } else if (app.staticTexts[emailTestAccountLogins].exists){
            app.webViews.links["Use a different account"].tap()
            waitforExistence(app.webViews.textFields["Email"], timeout: 10)
            navigator.nowAt(Screen.FxASigninScreen)
        } else {
            navigator.goto(Screen.FxASigninScreen)
        }
        snapshot("01Welcome" + CONTENT_SIZE)
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
        checkIfAccountIsVerified()
    }

    private func checkIfAccountIsVerified() {
        if (app.staticTexts["Confirm your account."].exists) {
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.verifyAccount() {
                    group.leave()
                }
            }
            group.wait()
            waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 20)
        } else {
            // Account is still verified, check that entries are shown
            waitforExistence(app.tables.cells.staticTexts[firstEntryEmail])
            XCTAssertNotEqual(app.tables.cells.count, 1)
            XCTAssertTrue(app.tables.cells.staticTexts[firstEntryEmail].exists)
        }
    }

    func testMainScreen() {
        preTestStatus()
        // Check how to order the entries
        navigator.nowAt(Screen.LockboxMainPage)
        sleep(5)
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

    func testSettingsMainPage() {
        preTestStatus()
        navigator.nowAt(Screen.LockboxMainPage)

        // Check the Lock Now button
        navigator.goto(Screen.LockboxMainPage)
        navigator.performAction(Action.LockNow)
        waitforExistence(app.buttons["Unlock Firefox Lockbox"])
        app.buttons["Unlock Firefox Lockbox"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitforExistence(springboard.secureTextFields["Passcode field"])
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tap()
        passcodeInput.typeText("0000\r")
        navigator.nowAt(Screen.LockboxMainPage)
        waitforExistence(app.navigationBars["Firefox Lockbox"])

        // Check the Send Data toggle
        navigator.goto(Screen.SettingsMenu)
        print(app.debugDescription)
        // Disable the send usage data
        navigator.performAction(Action.SendUsageData)
        XCTAssertEqual(app.switches["sendUsageData.switch"].value as? String, "0")

        // Enable it again
        navigator.performAction(Action.SendUsageData)
        XCTAssertEqual(app.switches["sendUsageData.switch"].value as? String, "1")
    }

    func testDifferentSettings() {
        preTestStatus()
        navigator.nowAt(Screen.LockboxMainPage)

        // Check the Account Setting
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        snapshot("03Settings" + CONTENT_SIZE)

        navigator.goto(Screen.AccountSettingsMenu)
        waitforExistence(app.navigationBars["Account"])
        // Some checks can be done here to be sure the Account UI is fine
        // To be uncommented once it is sure they appear, now it is not consistent in all run
        //XCTAssertTrue(app.images["avatar-placeholder"].exists, "The image placeholder does not appear")
        XCTAssertTrue(app.staticTexts["username.Label"].exists)
        XCTAssertTrue(app.buttons["disconnectFirefoxLockbox.button"].exists, "The option to disconnect does not appear")

        // Check that Cancel disconnecting the account works
        navigator.performAction(Action.DisconnectFirefoxLockboxCancel)
        waitforExistence(app.buttons["disconnectFirefoxLockbox.button"])

        navigator.goto(Screen.SettingsMenu)

        // Check the Autolock Setting
        waitforExistence(app.navigationBars["Settings"])
        navigator.goto(Screen.AutolockSettingsMenu)

        app.cells.staticTexts["Never"].tap()
        navigator.goto(Screen.LockboxMainPage)
        // Send app to background and launch it
        XCUIDevice.shared.press(.home)
        app.activate()
        waitforExistence(app.tables.cells.staticTexts["iosmztest@gmail.com"])

        navigator.goto(Screen.SettingsMenu)

        // Check the OpenWebSites with Setting
        navigator.goto(Screen.OpenSitesInMenu)
        waitforExistence(app.navigationBars["Open Websites in"])
        XCTAssertTrue(app.tables.cells.staticTexts["Firefox"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Google Chrome"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Safari"].exists)

        navigator.goto(Screen.LockboxMainPage)
    }

    func testEntryDetail() {
        preTestStatus()
        navigator.nowAt(Screen.LockboxMainPage)

        // Check the Entry Detail View and its details
        waitforExistence(app.tables.cells.staticTexts["iosmztest@gmail.com"])
        app.tables.cells.staticTexts["iosmztest@gmail.com"].tap()
        print(app.debugDescription)
        XCTAssertTrue(app.tables.cells.staticTexts["Web Address"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Username"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["iosmztest@gmail.com"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Password"].exists)

        app.buttons["Back"].tap()
        navigator.goto(Screen.LockboxMainPage)
    }
}
