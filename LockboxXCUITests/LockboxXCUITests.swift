/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let emailTestAccountLogins = "test-7012e53d0d@restmail.net"
let passwordTestAccountLogins = "UJJofTHO"
let emailTestAccountNoLogins = "test-e47278deb2@restmail.net"
let passwordTestAccountNoLogins = "IIJWKtOR"

class LockboxXCUITests: BaseTestCase {

    func test1LoginWithSavedLogins() {
        navigator.goto(FxASigninScreen)
        waitforExistence(app.webViews.textFields["Email"])

        // Try tapping on Sign In, no fields filled in
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Valid email required"])

        // Try incorrect Email then correct and tap on Sign In
        userState.fxaUsername = "test"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Valid email required"])

        userState.fxaUsername = "-7012e53d0d@restmail.net"
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
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        XCTAssertTrue(app.navigationBars.buttons["A-Z"].exists)
        XCTAssertTrue(app.navigationBars.buttons["Firefox Lockbox"].exists)
        XCTAssertTrue(app.navigationBars.buttons["preferences"].exists)

        // Go to Settings to disable the AutoLock
        // This is a temporary workaround needed to run other tests after this one until defining a tearDown
        navigator.goto(SettingsMenu)
        waitforExistence(app.navigationBars["Settings"])
        navigator.goto(AutolockSettingsMenu)

        app.cells.staticTexts["Never"].tap()
        // Go back to Lockbox main page view
        app.buttons["Settings"].tap()
        app.buttons["Done"].tap()
        sleep(5)
        waitforExistence(app.tables.cells.images["search"])
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

    // More tests to be added once the app is stable when re-launching and tearDown is defined according to app's behaviour
    func test2SettingsAccountUI() {
        navigator.goto(AccountSettingsMenu)
        waitforExistence(app.navigationBars["Account"])

        // Some checks can be done here to be sure the Account UI is fine
        XCTAssertTrue(app.images["avatar-placeholder"].exists, "The image placeholder does not appear")
        XCTAssertTrue(app.buttons["Disconnect Firefox Lockbox"].exists, "The option to disconnect does not appear")
    }

    func test3SettingOpenWebSitesIn() {
        navigator.goto(OpenSitesInMenu)
        waitforExistence(app.navigationBars["Open Websites in"])
        XCTAssertTrue(app.tables.cells.staticTexts["Firefox"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Firefox Focus"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Google Chrome"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Safari"].exists)
    }

    func test4SettingDisconnectAccount() {
        // First Cancel disconnecting the account
        navigator.performAction(Action.DisconnectFirefoxLockboxCancel)
        waitforExistence(app.buttons["Disconnect Firefox Lockbox"])

        // Now disconnect the account
        navigator.performAction(Action.DisconnectFirefoxLockbox)
        waitforExistence(app.buttons["Get Started"])
        app.buttons["Get Started"].tap()
        userState.fxaPassword = passwordTestAccountLogins
        waitforExistence(app.staticTexts["test-7012e53d0d@restmail.net"])
        navigator.nowAt(FxASigninScreen)
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.navigationBars["Firefox Lockbox"])
    }

    func test5SortEntries() {
        navigator.goto(LockboxMainPage)
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        sleep(3)
        navigator.performAction(Action.ChangeEntriesOrder)
        sleep(1)
        waitforExistence(app.staticTexts["Sort Entries"])
        XCTAssertTrue(app.buttons["Alphabetically"].exists)
        XCTAssertTrue(app.buttons["Recently Used"].exists)
        app.buttons["Recently Used"].tap()
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        XCTAssertTrue(app.buttons["Recent"].exists)
        // Pending to create more entries and check that the order is actually changed
    }

    func test6NoSavedLogins() {
        // Disconnect from previous account
        navigator.performAction(Action.DisconnectFirefoxLockbox)
        app.buttons["Get Started"].tap()
        waitforExistence(app.webViews.staticTexts[emailTestAccountLogins])
        print(app.debugDescription)
        app.webViews.links["Use a different account"].tap()
        sleep(3)

        navigator.nowAt(FxASigninScreen)
        waitforExistence(app.webViews.textFields["Email"])

        // Connect with new account without logins
        userState.fxaUsername = emailTestAccountNoLogins
        userState.fxaPassword = passwordTestAccountNoLogins
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxALogInSuccessfully)
        waitforExistence(app.navigationBars["Firefox Lockbox"])
        app.navigationBars["Firefox Lockbox"].tap()
        waitforExistence(app.images["empty-list-placeholder"])
        XCTAssertTrue(app.staticTexts["No entries found."].exists)
    }
}
