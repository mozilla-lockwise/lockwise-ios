/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SnapshotsXCUITests: BaseTestCase {
    
    override func tearDown() {
        navigator.goto(Screen.AccountSettingsMenu)
        waitforExistence(app.buttons["disconnectFirefoxLockwise.button"], timeout: 3)
        // Using taps directly because the action is intermittently failing on BB
        app.buttons["disconnectFirefoxLockwise.button"].tap()
        snapshot("14ConfirmDisconnect" + CONTENT_SIZE)
        // Workaround for languages where the disconnect confirm button changes its position
        waitforExistence(app.buttons.element(boundBy: 3), timeout: 3)
        app.buttons.element(boundBy: 3).tap()
        sleep(2)
        if (app.buttons["disconnectFirefoxLockwise.button"].exists) {
            app.buttons["disconnectFirefoxLockwise.button"].tap()
            waitforExistence(app.buttons.element(boundBy: 2), timeout: 3)
            app.buttons.element(boundBy: 2).tap()
        }
        waitforExistence(app.buttons["getStarted.button"], timeout: 30)
        navigator.nowAt(Screen.WelcomeScreen)
    }

    func testCheckEntryDetailsViewSnapshot() {
        snapshot("01Welcome" + CONTENT_SIZE)
        loginToEntryListView()
        
        snapshot("02EntryList" + CONTENT_SIZE)
        navigator.goto(Screen.EntryDetails)
        
        // The fields appear
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
        
        // Check the copy functionality for password
        let passwordField = app.cells["passwordItemDetail"]
        passwordField.press(forDuration: 1)
        snapshot("17CopyBanner" + CONTENT_SIZE)

        navigator.goto(Screen.LockwiseMainPage)
    }
    
    func testSettingsSnapshots() {
        loginToEntryListView()
        
        // Check OpenSitesIn Menu option
        navigator.goto(Screen.OpenSitesInMenu)
        waitforExistence(app.navigationBars["openWebSitesIn.navigationBar"])
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
        snapshot("06AccountUI" + CONTENT_SIZE)
        waitforExistence(app.navigationBars["accountSetting.navigationBar"])
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
        searchTextField.typeText("accx")
        waitforExistence(app.cells.staticTexts["noMatchingEntries.label"])
        snapshot("10SearchNoMatches" + CONTENT_SIZE)
        // Tap on cacel
        app.buttons.element(boundBy: 4).tap()
        navigator.nowAt(Screen.LockwiseMainPage)
    }

    func testDeleteEntrySnapshots() {
        loginToEntryListView()
        // Show the Delete option
        app.tables.cells.staticTexts["amazon.com"].swipeLeft()
        snapshot("DeleteButton" + CONTENT_SIZE)
        // Tap on Delete button
        app.tables.buttons.firstMatch.tap()
        snapshot("DeleteAlertDialog" + CONTENT_SIZE)
        // Cancel deleting the login
        app.alerts.buttons.firstMatch.tap()
    }
}
