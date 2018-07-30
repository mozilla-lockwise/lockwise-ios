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
        disconnectAccount()
        super.tearDown()
    }

    private func preTestStatus() {
        // App can start with user logged out, user logged out (email saved), user logged in
        // if user logged in, log out
        if (app.navigationBars["Firefox Lockbox"].exists) {
            disconnectAccount()
            logInFxAcc()
        } else if (app.buttons["getStarted.button"].exists) {
            // User logged out but emal remembered
            app.buttons["getStarted.button"].tap()
            waitforExistence(app.webViews.secureTextFields["Password"])
            if (app.staticTexts[emailTestAccountLogins].exists) {
                navigator.nowAt(Screen.FxASigninScreenSavedUser)
                navigator.performAction(Action.DisconnectUser)
                waitforExistence(app.webViews.textFields["Email"], timeout: 10)
                logInFxAcc()
            } else {
            // Starting like first time
            navigator.nowAt(Screen.FxASigninScreen)
            logInFxAcc()
            }
        }
    }

    func testLogin() {
        if (app.navigationBars["Firefox Lockbox"].exists) {
            disconnectAccount()
            navigator.nowAt(Screen.FxASigninScreen)
        } else if (app.buttons["getStarted.button"].exists){
            app.buttons["getStarted.button"].tap()
            waitforExistence(app.webViews.secureTextFields["Password"])
            if(app.staticTexts[emailTestAccountLogins].exists) {
                navigator.nowAt(Screen.FxASigninScreenSavedUser)
                navigator.performAction(Action.DisconnectUser)
            } else {
                navigator.nowAt(Screen.FxASigninScreen)
            }
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

    func testMainScreen() {
        preTestStatus()
        checkIfAccountIsVerified()
        // Check how to order the entries
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
        checkIfAccountIsVerified()

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
        checkIfAccountIsVerified()

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
        checkIfAccountIsVerified()

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
