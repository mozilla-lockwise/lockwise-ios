/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class LockboxXCUITests: BaseTestCase {

    override func setUp() {
        // First Delete the inbox
        deleteUserInbox()
        super.setUp()
    }

    override func tearDown() {
        deleteApp(name: "Lockbox")
    }

    func testCheckEntryDetailsView() {
        snapshot("01Welcome" + CONTENT_SIZE)
        loginFxAccount()
        // Check if the account is verified and if not, verify it
        checkIfAccountIsVerified()
        skipAutofillConfiguration()
        tapOnFinishButton()

        waitForLockboxEntriesListView()
        XCTAssertNotEqual(app.tables.cells.count, 1)
        XCTAssertTrue(app.tables.cells.staticTexts[firstEntryEmail].exists)
        snapshot("02EntryList" + CONTENT_SIZE)

        navigator.goto(Screen.EntryDetails)

        // The fields appear
        XCTAssertTrue(app.cells["userNameItemDetail"].exists)
        XCTAssertTrue(app.cells["passwordItemDetail"].exists)
        XCTAssertTrue(app.cells["webAddressItemDetail"].exists)

        // The value in each field is correct
        let userNameValue = app.cells["userNameItemDetail"].staticTexts.element(boundBy: 1).label
        XCTAssertEqual(userNameValue, "iosmztest@gmail.com")

        let passwordValue = app.cells["passwordItemDetail"].staticTexts.element(boundBy: 1).label
        XCTAssertEqual(passwordValue, "••••••••")

        // Check the reveal Button
        navigator.performAction(Action.RevealPassword)

        let passwordValueReveal = app.cells["passwordItemDetail"].staticTexts.element(boundBy: 1).label
        XCTAssertEqual(passwordValueReveal, "test15mz")

        // Check the copy functionality with user name
        let userNameField = app.cells["userNameItemDetail"]
        userNameField.press(forDuration: 1)

        // Now check the clipboard
        if let userNameString = UIPasteboard.general.string {
            let value = app.cells["userNameItemDetail"].staticTexts.element(boundBy: 1).label
            XCTAssertNotNil(value)
            XCTAssertEqual(userNameString, value, "Url matches with the UIPasteboard")
        }

        // Open website Web Address
        let webAddressValue = app.cells["webAddressItemDetail"].staticTexts.element(boundBy: 1).label
        XCTAssertEqual(webAddressValue, "https://accounts.google.com")

        navigator.performAction(Action.OpenWebsite)
        // Safari is open
        waitforExistence(safari.buttons["URL"], timeout: 10)
        waitForValueContains(safari.buttons["URL"], value: "accounts")

        app.launch()
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
    }

    func testSettingsAccountUI() {
        loginFxAccount()
        // Check if the account is verified and if not, verify it
        checkIfAccountIsVerified()
        skipAutofillConfiguration()
        tapOnFinishButton()
        waitForLockboxEntriesListView()
        snapshot("03Settings" + CONTENT_SIZE)

        navigator.goto(Screen.AccountSettingsMenu)
        waitforExistence(app.navigationBars["accountSetting.navigationBar"])
        XCTAssertTrue(app.staticTexts["username.Label"].exists)
        XCTAssertEqual(app.staticTexts["username.Label"].label, emailTestAccountLogins)
        XCTAssertTrue(app.buttons["disconnectFirefoxLockbox.button"].exists, "The option to disconnect does not appear")

        // Try Cancel disconnecting the account
        navigator.performAction(Action.DisconnectFirefoxLockboxCancel)
        waitforExistence(app.buttons["disconnectFirefoxLockbox.button"])

        // Disconnect the account
        navigator.performAction(Action.DisconnectFirefoxLockbox)
        waitforExistence(app.buttons["getStarted.button"])
    }

    func testSettings() {
        loginFxAccount()
        // Check if the account is verified and if not, verify it
        checkIfAccountIsVerified()
        skipAutofillConfiguration()
        tapOnFinishButton()
        waitForLockboxEntriesListView()

        // Check OpenSitesIn Menu option
        navigator.goto(Screen.OpenSitesInMenu)
        waitforExistence(app.navigationBars["openWebSitesIn.navigationBar"])
        XCTAssertTrue(app.tables.cells.staticTexts["Firefox"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Google Chrome"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Safari"].exists)

        // Check App Version not empty
        navigator.goto(Screen.SettingsMenu)
        // The app version option exists and it is not empty
        XCTAssertTrue(app.cells["appVersionSettingOption"].exists)
        XCTAssertNotEqual(app.cells.staticTexts.element(boundBy: 2).label, "")

        // Check configure Autofill from settings
        if #available(iOS 12.0, *) {
            navigator.goto(Screen.AutoFillSetUpInstructionsSettings)
            XCTAssertTrue(app.buttons["gotIt.button"].exists)
        }
    }

    func testEntriesSortAndSearch() {
        loginFxAccount()
        // Check if the account is verified and if not, verify it
        checkIfAccountIsVerified()
        skipAutofillConfiguration()
        tapOnFinishButton()
        waitForLockboxEntriesListView()

        // Checking if doing the steps directly works on bb
        waitforExistence(app.buttons["sorting.button"])
        app.buttons["sorting.button"].tap()
        waitforExistence(app.buttons["Recently Used"])
        app.buttons["Recently Used"].tap()
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
        let buttonLabelChanged = app.buttons["sorting.button"].label
        XCTAssertEqual(buttonLabelChanged, "Select options for sorting your list of entries (currently Recent)")
        // Check that the order has changed
        let firstCellRecent = app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellRecent, "wopr.norad.org")

        app.buttons["sorting.button"].tap()
        waitforExistence(app.buttons["Alphabetically"])
        app.buttons["Alphabetically"].tap()
        let buttonLabelInitally = app.buttons["sorting.button"].label
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
        XCTAssertEqual(buttonLabelInitally, "Select options for sorting your list of entries (currently A-Z)")
        sleep(2)
        // Check that the order has changed again to its initial state
        let firstCellAlphabetically = app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellAlphabetically, "accounts.google.com")

        // Search entries options
        let searchTextField = app.cells.textFields["filterEntries.textField"]
        searchTextField.tap()
        searchTextField.typeText("a")
        // There should be two matches
        let twoMatches = app.tables.cells.count - 1
        XCTAssertEqual(twoMatches, 2)

        // There should be one match
        searchTextField.typeText("cc")
        let oneMatches = app.tables.cells.count - 1
        XCTAssertEqual(oneMatches, 1)

        // There should not be any matches
        searchTextField.typeText("x")
        waitforExistence(app.cells.staticTexts["noMatchingEntries.label"])
        let noMatches = app.tables.cells.count - 1
        XCTAssertEqual(noMatches, 1)

        // Tap on cacel
        app.buttons["cancelFilterTextEntry.button"].tap()
        let searchFieldValueAfterCancel = searchTextField.value as! String
        XCTAssertEqual(searchFieldValueAfterCancel, "Search your entries")

        // Tap on 'x'
        searchTextField.tap()
        searchTextField.typeText("a")
        app.buttons["Clear text"].tap()
        let searchFieldValueAfterXButton = searchTextField.value as! String
        XCTAssertEqual(searchFieldValueAfterXButton, "Search your entries")
    }

    func testCheckAutolock() {
        loginFxAccount()
        // Check if the account is verified and if not, verify it
        checkIfAccountIsVerified()
        skipAutofillConfiguration()
        tapOnFinishButton()
        waitForLockboxEntriesListView()

        navigator.goto(Screen.SettingsMenu)
        waitforExistence(app.navigationBars["settings.navigationBar"])
        navigator.goto(Screen.AutolockSettingsMenu)

        app.cells.staticTexts["Never"].tap()
        navigator.goto(Screen.LockboxMainPage)
        // Send app to background and launch it
        XCUIDevice.shared.press(.home)
        app.activate()
        waitforExistence(app.tables.cells.staticTexts["iosmztest@gmail.com"])

        navigator.goto(Screen.LockboxMainPage)
        navigator.performAction(Action.LockNow)
        waitforExistence(app.buttons["Unlock Firefox Lockbox"])
        app.buttons["Unlock Firefox Lockbox"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitforExistence(springboard.secureTextFields["Passcode field"])
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tap()
        passcodeInput.typeText("0000\r")
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
    }

    func testSetAutofill() {
        if #available(iOS 12.0, *) {
            let testingURL = "https://wopr.norad.org/~sarentz/fxios/testpages/password.html"
            loginFxAccount()
            checkIfAccountIsVerified()
            waitforExistence(app.buttons["setupAutofill.button"])
            navigator.goto(Screen.AutofillSetUpInstructionsWhenLogingIn)
            navigator.goto(Screen.LockboxMainPage)
            waitForLockboxEntriesListView()

            // Open Settings app
            settings.launch()
            // Wait until settings app is open
            waitforExistence(settings.cells.staticTexts["Passwords & Accounts"])
            // Configure Passwords & Accounts settings
            configureAutofillSettings()
            // Wait until the app is updated
            sleep(5)
            settings.terminate()

            //Open Safari
            safari.launch()
            waitforExistence(safari.buttons["URL"], timeout: 5)
            safari.buttons["URL"].tap()
            safari.textFields["URL"].typeText(testingURL)
            safari.textFields["URL"].typeText("\r")
            waitforExistence(safari.buttons["submit"], timeout: 5)
            // Need to confirm what is shown here, different elements have appeared and
            if (safari.buttons["Other passwords"].exists) {
                safari.buttons["Other passwords"].tap()
                waitforExistence(safari.otherElements.staticTexts["Choose a saved password to use"])
                XCTAssertTrue(safari.buttons.otherElements["test@example.com, for this website — Lockbox"].exists)
            } else if (safari.otherElements["Password Auto-fill"].exists) {
                safari.otherElements["Password Auto-fill"].tap()
                XCTAssertTrue(safari.buttons["test@example.com, for this website — Lockbox"].exists)
            } else {
                XCTAssertTrue(safari.buttons["Use “test@example.com”"].exists)
            }
            safari.terminate()
            }
    }
}
