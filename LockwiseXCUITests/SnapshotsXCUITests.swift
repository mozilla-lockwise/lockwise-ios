/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SnapshotsXCUITests: BaseTestCase {
    let preferredLanguage = NSLocale.preferredLanguages[0]
    let currentDeviceLanguage = Locale.current.languageCode
    
    override func tearDown() {
        navigator.goto(Screen.AccountSettingsMenu)
        waitforExistence(app.buttons["disconnectFirefoxLockwise.button"], timeout: 3)
        // Using taps directly because the action is intermittently failing on BB
        app.buttons["disconnectFirefoxLockwise.button"].tap()
        // This is the confirm Disconnect account
        snapshot("14ConfirmDisconnect" + CONTENT_SIZE)
        // Button is 3rd for ES,IT,EN, it is 2nd for DE, FR
        print("idioma \(currentDeviceLanguage)")
        if currentDeviceLanguage == "es" {
            waitforExistence(app.buttons.element(boundBy: 3), timeout: 3)
            app.buttons.element(boundBy: 3).tap()
        } else if currentDeviceLanguage == "de-DE" {
            waitforExistence(app.buttons.element(boundBy: 2), timeout: 3)
            app.buttons.element(boundBy: 2).tap()
        }
        waitforExistence(app.buttons["getStarted.button"], timeout: 30)
        navigator.nowAt(Screen.WelcomeScreen)
    }
    
    func testCheckEntryDetailsViewSnapshot() {
        snapshot("01Welcome" + CONTENT_SIZE)
        loginToEntryListView()
        
        XCTAssertNotEqual(app.tables.cells.count, 1)
        XCTAssertTrue(app.tables.cells.staticTexts[firstEntryEmail].exists)
        snapshot("02EntryList" + CONTENT_SIZE)
        navigator.goto(Screen.EntryDetails)
        
        // The fields appear
        XCTAssertTrue(app.cells["userNameItemDetail"].exists)
        XCTAssertTrue(app.cells["passwordItemDetail"].exists)
        XCTAssertTrue(app.cells["webAddressItemDetail"].exists)
        snapshot("03EntryDetail" + CONTENT_SIZE)
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
        userNameField.press(forDuration: 1)
        snapshot("04CopyBanner" + CONTENT_SIZE)
        // Now check the clipboard
        if let userNameString = UIPasteboard.general.string {
            let value = app.cells["userNameItemDetail"].staticTexts.element(boundBy: 1).label
            XCTAssertNotNil(value)
            XCTAssertEqual(userNameString, value, "Url matches with the UIPasteboard")
        }
        navigator.goto(Screen.LockwiseMainPage)
    }

    func testSettingsSnapshots() {
        loginToEntryListView()
        
        // Check OpenSitesIn Menu option
        navigator.goto(Screen.OpenSitesInMenu)
        waitforExistence(app.navigationBars["openWebSitesIn.navigationBar"])
        XCTAssertTrue(app.tables.cells.staticTexts["Firefox"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Google Chrome"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Safari"].exists)
        snapshot("05OpenSitesMenu" + CONTENT_SIZE)
        
        // Check App Version not empty
        navigator.goto(Screen.SettingsMenu)
        // The app version option exists and it is not empty
        XCTAssertTrue(app.cells["appVersionSettingOption"].exists)
        XCTAssertNotEqual(app.cells.staticTexts.element(boundBy: 2).label, "")
        snapshot("06SettingsMenu" + CONTENT_SIZE)
        
        // Check configure Autofill from settings
        if #available(iOS 12.0, *) {
            navigator.goto(Screen.AutoFillSetUpInstructionsSettings)
            XCTAssertTrue(app.buttons["gotIt.button"].exists)
        }
        
        // Check Autolock
        navigator.goto(Screen.AutolockSettingsMenu)
        snapshot("11AutolockSettingsMenu" + CONTENT_SIZE)
        navigator.goto(Screen.SettingsMenu)
        
        // Check AccountSettings
        navigator.goto(Screen.AccountSettingsMenu)
        snapshot("05AccountUI" + CONTENT_SIZE)
        waitforExistence(app.navigationBars["accountSetting.navigationBar"])
        XCTAssertTrue(app.staticTexts["username.Label"].exists)
        XCTAssertEqual(app.staticTexts["username.Label"].label, userNameAccountSetting)
        XCTAssertTrue(app.buttons["disconnectFirefoxLockwise.button"].exists, "The option to disconnect does not appear")
    }
    
    func testEntriesSortAndSearchSnapshots() {
        let firstEntryRecentOrder = "bmo.com"
        let firstEntryAphabeticallyOrder = "accounts.firefox.com"
        loginToEntryListView()
        
        // Checking if doing the steps directly works on bb
        waitforExistence(app.buttons["sorting.button"], timeout: 5)
        app.buttons["sorting.button"].tap()
        snapshot("07SortingMenu" + CONTENT_SIZE)

        app.sheets.buttons.element(boundBy: 1).tap()
        waitforExistence(app.navigationBars["firefoxLockwise.navigationBar"])

        snapshot("08ListSortByRecent" + CONTENT_SIZE)
        // Check that the order has changed
        let firstCellRecent = app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellRecent, firstEntryRecentOrder )
        
        app.buttons["sorting.button"].tap()
        waitforExistence(app.sheets.buttons.element(boundBy: 1))
        app.sheets.buttons.element(boundBy: 0).tap()

        waitforExistence(app.navigationBars["firefoxLockwise.navigationBar"])

        // Check that the order has changed again to its initial state
        let firstCellAlphabetically = app.tables.cells.element(boundBy: 0).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellAlphabetically, firstEntryAphabeticallyOrder)
        
        // Search entries options
        let searchTextField = app.searchFields.firstMatch
        waitforExistence(searchTextField, timeout: 3)
        searchTextField.tap()
        snapshot("09SearchOptions" + CONTENT_SIZE)
    
        // There should not be any matches
        searchTextField.typeText("x")
        waitforExistence(app.cells.staticTexts["noMatchingEntries.label"])
        snapshot("10SearchNoMatches" + CONTENT_SIZE)
        let noMatches = app.tables.cells.count
        if  iPad() {
            // There are not matches but the number of rows shown, more on iPad
            XCTAssertEqual(noMatches, 4)
        } else {
            XCTAssertEqual(noMatches, 1)
        }
        // Tap on cacel
        app.buttons.element(boundBy: 4).tap()
        navigator.nowAt(Screen.LockwiseMainPage)
    }
}
