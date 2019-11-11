/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class LockwiseXCUITests: BaseTestCase {

    override func tearDown() {
        navigator.goto(Screen.AccountSettingsMenu)
        waitforExistence(app.buttons["disconnectFirefoxLockwise.button"], timeout: 3)
        // Using taps directly because the action is intermittently failing on BB
        app.buttons["disconnectFirefoxLockwise.button"].tap()
        waitforExistence(app.buttons["Disconnect"], timeout: 3)
        app.buttons["Disconnect"].tap()

        waitforExistence(app.buttons["getStarted.button"], timeout: 30)
        navigator.nowAt(Screen.WelcomeScreen)
    }

    // To run this test locally, first run python3 upload_fake_passwordsBB.py 1
    // See more info in docs/AutomatedTests.md
    func testDeleteEntry() {
        loginToEntryListView()

        waitforExistence(app.tables.cells.staticTexts["aaafakeTesterDelete"])
        // Need to add firstMatch for iPad case
        app.tables.cells.staticTexts["aaafakeTesterDelete"].firstMatch.swipeLeft()
        app.tables.buttons["Delete"].tap()
        waitforExistence(app.alerts["Delete this login?"])
        // First check the Cancel button
        app.alerts.buttons["Cancel"].tap()
        waitforExistence(app.tables.cells.staticTexts["aaafakeTesterDelete"])
        app.tables.cells.staticTexts["aaafakeTesterDelete"].firstMatch.swipeLeft()
        app.tables.buttons["Delete"].tap()
        waitforExistence(app.alerts["Delete this login?"])
        // Then Delete the login
        app.alerts.buttons["Delete"].tap()
        waitforExistence(app.navigationBars["firefoxLockwise.navigationBar"])
        // Now check that the login has been removed
        // On iPad, entry is removed but only from the entry list, the entry detail view is still there
        if !iPad() {
            waitforNoExistence(app.tables.cells.staticTexts["aaafakeTesterDelete"])
        }
    }

    func testEntryDetailsView() {
        loginToEntryListView()

        XCTAssertNotEqual(app.tables.cells.count, 1)
        XCTAssertTrue(app.tables.cells.staticTexts[firstEntryEmail].exists)
        navigator.goto(Screen.EntryDetails)

        // The fields appear
        XCTAssertTrue(app.cells["userNameItemDetail"].exists)
        XCTAssertTrue(app.cells["passwordItemDetail"].exists)
        XCTAssertTrue(app.cells["webAddressItemDetail"].exists)
        // The value in each field is correct
        let userNameValue = app.cells["userNameItemDetail"].staticTexts.element(boundBy: 1).label
        XCTAssertEqual(userNameValue, firstEntryEmail)

        let passwordValue = app.cells["passwordItemDetail"].staticTexts.element(boundBy: 1).label
        XCTAssertEqual(passwordValue, "•••••••••••••")

        // Check the reveal Button
        navigator.performAction(Action.RevealPassword)

        let passwordValueReveal = app.cells["passwordItemDetail"].staticTexts.element(boundBy: 1).label
        XCTAssertEqual(passwordValueReveal, passwordTestAccountLogins)

        // Check the copy functionality with user name
        let userNameField = app.cells["userNameItemDetail"]
        userNameField.tap()

        // Now check the clipboard
        if let userNameString = UIPasteboard.general.string {
            let value = app.cells["userNameItemDetail"].staticTexts.element(boundBy: 1).label
            XCTAssertNotNil(value)
            XCTAssertEqual(userNameString, value, "Url matches with the UIPasteboard")
        }

        // Open website Web Address
        let webAddressValue = app.cells["webAddressItemDetail"].staticTexts.element(boundBy: 1).label
        XCTAssertEqual(webAddressValue, websiteDetailView)

        navigator.performAction(Action.OpenWebsite)
        // Safari is open
        waitforExistence(safari.buttons["URL"], timeout: 20)
        waitForValueContains(safari.buttons["URL"], value: "‎accounts")
        safari.terminate()

        app.launch()
        waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 5)
        navigator.nowAt(Screen.LockwiseMainPage)
        navigator.goto(Screen.SettingsMenu)
    }

    func testSettingsAccountUI() {
        loginToEntryListView()
        navigator.goto(Screen.AccountSettingsMenu)
        waitforExistence(app.navigationBars["accountSetting.navigationBar"])
        XCTAssertTrue(app.staticTexts["username.Label"].exists)
        XCTAssertEqual(app.staticTexts["username.Label"].label, userNameAccountSetting)
        XCTAssertTrue(app.buttons["disconnectFirefoxLockwise.button"].exists, "The option to disconnect does not appear")

        // Try Cancel disconnecting the account
        navigator.performAction(Action.DisconnectFirefoxLockwiseCancel)
        waitforExistence(app.buttons["disconnectFirefoxLockwise.button"])
    }

    func testSettings() {
        loginToEntryListView()

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
        let firstEntryRecentOrder = "arncyvuzox.co.uk"
        let firstEntryAphabeticallyOrder = "accounts.firefox.com"
        loginToEntryListView()

        // Use one entry
        app.tables.cells.staticTexts["fakeTester33333"].tap()
        // Copy its username and open the website
        let userName = app.cells["userNameItemDetail"]
        userName.press(forDuration: 1)

        waitforExistence(app.buttons["open.button"], timeout: 3)
        app.buttons["open.button"].tap()

        // Safari is open
        waitforExistence(safari.buttons["URL"], timeout: 30)
        safari.terminate()
        // Close Safari and re-open the app
        app.launch()
        waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 20)

        // Checking if doing the steps directly works on bb
        waitforExistence(app.buttons["sorting.button"], timeout: 15)
        app.buttons["sorting.button"].tap()
        waitforExistence(app.buttons["Recently Used"], timeout: 5)
        app.buttons["Recently Used"].tap()

        waitforExistence(app.navigationBars["firefoxLockwise.navigationBar"])
        let buttonLabelChanged = app.buttons["sorting.button"].label
        XCTAssertEqual(buttonLabelChanged, "Select options for sorting your list of logins (currently Recent)")

        // Check that the order has changed
        let firstCellRecent = app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellRecent, firstEntryRecentOrder )

        app.buttons["sorting.button"].tap()
        waitforExistence(app.buttons["Alphabetically"])
        app.buttons["Alphabetically"].tap()
        let buttonLabelInitally = app.buttons["sorting.button"].label
        waitforExistence(app.navigationBars["firefoxLockwise.navigationBar"])
        XCTAssertEqual(buttonLabelInitally, "Select options for sorting your list of logins (currently A-Z)")

        // Check that the order has changed again to its initial state
        let firstCellAlphabetically = app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellAlphabetically, firstEntryAphabeticallyOrder)

        // Search entries options
        let searchTextField = app.searchFields.firstMatch
        waitforExistence(searchTextField, timeout: 3)
        searchTextField.tap()
        searchTextField.typeText("a")
        // There should be the correct number of matches
        let aMatches = app.tables.cells.count
        if  iPad() {
            XCTAssertEqual(aMatches, 100)
        } else {
            XCTAssertEqual(aMatches, 97)
        }
        // There should be less number of matches
        searchTextField.typeText("cc")
        let accMatches = app.tables.cells.count
        if  iPad() {
            XCTAssertEqual(accMatches, 5)
        } else {
            XCTAssertEqual(accMatches, 2)
        }
        // There should not be any matches
        searchTextField.typeText("x")
        waitforExistence(app.cells.staticTexts["noMatchingEntries.label"])
        let noMatches = app.tables.cells.count
        if  iPad() {
            // There are not matches but the number of rows shown, more on iPad
            XCTAssertEqual(noMatches, 4)
        } else {
            XCTAssertEqual(noMatches, 1)
        }
        // Tap on cacel
        app.buttons["Cancel"].tap()
        let searchFieldValueAfterCancel = searchTextField.placeholderValue
        XCTAssertEqual(searchFieldValueAfterCancel, "Search logins")
        // Tap on 'x'
        searchTextField.tap()
        searchTextField.typeText("a")
        app.buttons["Clear text"].tap()
        let searchFieldValueAfterXButton = searchTextField.value as! String
        XCTAssertEqual(searchFieldValueAfterXButton, "Search logins")
        app.buttons["Cancel"].tap()
        navigator.nowAt(Screen.LockwiseMainPage)
    }

    func testCheckAutolock() {
        loginToEntryListView()

        navigator.goto(Screen.SettingsMenu)
        waitforExistence(app.navigationBars["settings.navigationBar"])
        navigator.goto(Screen.AutolockSettingsMenu)
        app.cells.staticTexts["Never"].tap()
        navigator.goto(Screen.LockwiseMainPage)
        // Send app to background and launch it
        XCUIDevice.shared.press(.home)
        app.activate()
        waitforExistence(app.tables.cells.staticTexts[firstEntryEmail])
        navigator.goto(Screen.LockwiseMainPage)
        navigator.performAction(Action.LockNow)
        waitforExistence(app.buttons["unlock.button"])
        app.buttons["unlock.button"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitforExistence(springboard.secureTextFields["Passcode field"])
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tap()
        passcodeInput.typeText("0000\r")
        waitforExistence(app.navigationBars["firefoxLockwise.navigationBar"])
        navigator.nowAt(Screen.LockwiseMainPage)
    }

    // Verify SetAutofillNow
    func testSetAutofill() {
        if #available(iOS 12.0, *) {
            let testingURL = "accounts.google.com"
            //Temporarily commenting this out as variable is unused until test code below is fixed
            //let safariButtons1 = "firefoxlockbox@gmail.com, for this website — Lockwise"
            let safariButtons2 = "Use “firefoxlockbox@example.com”"
            loginFxAccount()
            waitforExistence(app.buttons["setupAutofill.button"])
            navigator.goto(Screen.AutofillSetUpInstructionsWhenLogingIn)
            navigator.goto(Screen.LockwiseMainPage)
            waitForLockwiseEntriesListView()

            // Open Settings app
            settings.launch()

            // Wait until settings app is open
            waitforExistence(settings.cells.staticTexts["Passwords & Accounts"])
            // Configure Passwords & Accounts settings
            configureAutofillSettings()

            //Open Safari
            safari.launch()

            waitforExistence(safari.textFields["URL"], timeout: 20)
            safari.textFields["URL"].tap()
            safari.textFields["URL"].typeText(testingURL)
            safari.textFields["URL"].typeText("\r")

            waitforExistence(safari.webViews["WebView"].textFields["Email or phone"], timeout: 20)
            safari.buttons["ReloadButton"].tap()
            waitforExistence(safari.webViews["WebView"].textFields["Email or phone"], timeout: 20)
            safari.webViews["WebView"].textFields["Email or phone"].tap()


            // Need to confirm what is shown here, different elements have appeared and
            if (safari.buttons["Passwords"].exists) {
                safari.buttons["Passwords"].tap()
                // Commenting this part out until the final expected behaviour is clear
//                waitforExistence(safari.otherElements.staticTexts["Choose a saved password to use"])
//                XCTAssertTrue(safari.buttons.otherElements[safariButtons1].exists)
//                waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 10)
//                waitforExistence(app.staticTexts["Firefox Lockwise"], timeout: 10)
            } else if (safari.otherElements["Password Auto-fill"].exists) {
                safari.otherElements["Password Auto-fill"].tap()
            } else {
                XCTAssertTrue(safari.buttons[safariButtons2].exists)
            }
            // Commenting this part out since not clear yet how to check the elements in the new view open
            // showing the login list
//            safari.terminate()
            // Let's launch the app as usual so that the Tear Down works
            app.launch()
//            waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 10)
            navigator.nowAt(Screen.LockwiseMainPage)
        }
    }
}
