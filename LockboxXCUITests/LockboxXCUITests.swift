/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let emailTestAccountLogins = "test-b62feb2ed6@restmail.net"
let passwordTestAccountLogins = "FRCuQaPm"

class LockboxXCUITests: BaseTestCase {

    func test1LoginWithSavedLogins() {
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
        // Instead of waiting we could pull down to refresh to force the logins appear and so the buttons are available
        waitforExistence(app.buttons["Finish"])
        app.buttons["Finish"].tap()
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        XCTAssertTrue(app.buttons["sorting.button"].exists)

        let buttonLabelInitally = app.buttons["sorting.button"].label
        XCTAssertEqual(buttonLabelInitally, "Select options for sorting your list of entries (currently A-Z)")

        XCTAssertTrue(app.navigationBars["Firefox Lockbox"].exists)
        XCTAssertTrue(app.navigationBars.buttons["Settings"].exists)

        // Go to Settings to disable the AutoLock
        // This is a temporary workaround needed to run other tests after this one until defining a tearDown
        sleep(5)
        navigator.goto(Screen.SettingsMenu)
        waitforExistence(app.navigationBars["Settings"])
        navigator.goto(Screen.AutolockSettingsMenu)

        app.cells.staticTexts["Never"].tap()
        // Go back to Lockbox main page view
        navigator.goto(Screen.LockboxMainPage)
        waitforExistence(app.buttons["sorting.button"])
        // Just to check that the logins are shown, the table should have more than the cell for search
        XCTAssertNotEqual(app.tables.cells.count, 1)
        XCTAssertTrue(app.tables.cells.staticTexts["iosmztest@gmail.com"].exists)

        // Verify that going to a saved login shows the correct options
        app.tables.cells.staticTexts["iosmztest@gmail.com"].tap()
        XCTAssertTrue(app.tables.cells.staticTexts["Web Address"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Username"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["iosmztest@gmail.com"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Password"].exists)
    }

    func test2SettingsAccountUI() {
        waitforExistence(app.navigationBars["Firefox Lockbox"])
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
        navigator.goto(Screen.SortEntriesMenu)
        navigator.performAction(Action.SelectAlphabeticalOrder)
        let buttonLabelInitally = app.buttons["sorting.button"].label
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        XCTAssertEqual(buttonLabelInitally, "Select options for sorting your list of entries (currently A-Z)")
        // Pending to create more entries and check that the order is actually changed
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
        waitforExistence(app.buttons["Finish"])
        app.buttons["Finish"].tap()
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

    func test7LockNowUnlock() {
        navigator.goto(Screen.LockboxMainPage)
        navigator.performAction(Action.LockNow)
        waitforExistence(app.buttons["unlock"])
        app.buttons["unlock"].tap()
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
