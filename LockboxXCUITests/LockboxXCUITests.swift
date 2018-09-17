/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let emailTestAccountLogins = "test-b62feb2ed6@restmail.net"
let passwordTestAccountLogins = "FRCuQaPm"
let testingURL = "https://wopr.norad.org/~sarentz/fxios/testpages/password.html"

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

    func test0LoginSuccessfully() {
        snapshot("01Welcome" + CONTENT_SIZE)
        userState.fxaPassword = passwordTestAccountLogins
        userState.fxaUsername = "test-b62feb2ed6@restmail.net"
        navigator.goto(Screen.FxASigninScreenEmail)
        waitforExistence(app.navigationBars["Lockbox.FxAView"])
        waitforExistence(app.webViews.textFields["Email"], timeout: 10)
        navigator.performAction(Action.FxATypeEmail)
        waitforExistence(app.webViews.secureTextFields["Password"])
        navigator.performAction(Action.FxATypePassword)
        // Lets try to remove this sleep(10) and see if the tests consistently pass
        // Check if the account is verified and if not, verify it
        checkIfAccountIsVerified()

        if #available(iOS 12.0, *) {
            waitforExistence(app.buttons["setupAutofill.button"])
            app.buttons["notNow.button"].tap()
        }
        waitforExistence(app.buttons["finish.button"])
        app.buttons["finish.button"].tap()

        waitforExistence(app.tables.cells.staticTexts[firstEntryEmail], timeout: 15)

        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
        waitforExistence(app.tables.cells.staticTexts[firstEntryEmail])
        XCTAssertNotEqual(app.tables.cells.count, 1)
        XCTAssertTrue(app.tables.cells.staticTexts[firstEntryEmail].exists)
        snapshot("02EntryList" + CONTENT_SIZE)
    }

    func test1SettingsAccountUI() {
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
        snapshot("03Settings" + CONTENT_SIZE)

        navigator.goto(Screen.AccountSettingsMenu)
        waitforExistence(app.navigationBars["accountSetting.navigationBar"])
        XCTAssertTrue(app.staticTexts["username.Label"].exists)
        XCTAssertEqual(app.staticTexts["username.Label"].label, emailTestAccountLogins)
        XCTAssertTrue(app.buttons["disconnectFirefoxLockbox.button"].exists, "The option to disconnect does not appear")
    }

    func test2SettingOpenWebSitesIn() {
        navigator.goto(Screen.OpenSitesInMenu)
        waitforExistence(app.navigationBars["openWebSitesIn.navigationBar"])
        XCTAssertTrue(app.tables.cells.staticTexts["Firefox"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Google Chrome"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Safari"].exists)
    }

    func test3EntryDetails() {
        navigator.goto(Screen.LockboxMainPage)
        waitforExistence(app.tables.cells.staticTexts["iosmztest@gmail.com"], timeout: 15)
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
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        waitforExistence(safari.buttons["URL"], timeout: 10)
        waitForValueContains(safari.buttons["URL"], value: "accounts")

        app.launch()
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
    }

    func test4SettingDisconnectAccount() {
        // First Cancel disconnecting the account
        navigator.performAction(Action.DisconnectFirefoxLockboxCancel)
        waitforExistence(app.buttons["disconnectFirefoxLockbox.button"])

        // Now disconnect the account
        disconnectAndConnectAccount()

        if #available(iOS 12.0, *) {
            waitforExistence(app.buttons["setupAutofill.button"])
            app.buttons["notNow.button"].tap()
        }
        waitforExistence(app.buttons["finish.button"], timeout: 10)
        app.buttons["finish.button"].tap()
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
    }

    func test5SendUsageDataSwitch() {
//        navigator.goto(Screen.SettingsMenu)
//        // Disable the send usage data
//        navigator.performAction(Action.SendUsageData)
//        XCTAssertEqual(app.switches["sendUsageData.switch"].value as? String, "0")
//
//        // Enable it again
//        navigator.performAction(Action.SendUsageData)
//        XCTAssertEqual(app.switches["sendUsageData.switch"].value as? String, "1")
    }

    func test6SortEntries() {
        navigator.goto(Screen.LockboxMainPage)
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"], timeout: 10)
        // Checking if doing the steps directly works on bb
        waitforExistence(app.buttons["sorting.button"])
        app.buttons["sorting.button"].tap()
        waitforExistence(app.buttons["Recently Used"])
        app.buttons["Recently Used"].tap()
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
        let buttonLabelChanged = app.buttons["sorting.button"].label
        XCTAssertEqual(buttonLabelChanged, "Select options for sorting your list of entries (currently Recent)")
        // Lets see if this is fixed now
        // Disable the label check until BB failure is not present
        let firstCellRecent = app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellRecent, "wopr.norad.org")

        app.buttons["sorting.button"].tap()
        waitforExistence(app.buttons["Alphabetically"])
        app.buttons["Alphabetically"].tap()
        let buttonLabelInitally = app.buttons["sorting.button"].label
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
        XCTAssertEqual(buttonLabelInitally, "Select options for sorting your list of entries (currently A-Z)")
        sleep(2)
        let firstCellAlphabetically = app.tables.cells.element(boundBy: 1).staticTexts.element(boundBy: 0).label
        XCTAssertEqual(firstCellAlphabetically, "accounts.google.com")
    }

    func test7ChangeDefaultAutolock() {
        navigator.goto(Screen.SettingsMenu)
        waitforExistence(app.navigationBars["settings.navigationBar"])
        navigator.goto(Screen.AutolockSettingsMenu)

        app.cells.staticTexts["Never"].tap()
        navigator.goto(Screen.LockboxMainPage)
        // Send app to background and launch it
        XCUIDevice.shared.press(.home)
        app.activate()
        waitforExistence(app.tables.cells.staticTexts["iosmztest@gmail.com"])
    }

    func test8SearchOptions() {
        navigator.goto(Screen.LockboxMainPage)
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
        waitforExistence(app.navigationBars["firefoxLockbox.navigationBar"])
    }

    func testAppVersion() {
        navigator.goto(Screen.SettingsMenu)
        // The app version option exists and it is not empty
        XCTAssertTrue(app.cells["appVersionSettingOption"].exists)
        XCTAssertNotEqual(app.cells.staticTexts.element(boundBy: 2).label, "")
    }

    // Verify SetAutofillNow
    func testSetAutofillNow() {
        // Disconnect account
        disconnectAndConnectAccount()
        if #available(iOS 12.0, *) {
            waitforExistence(app.buttons["setupAutofill.button"])
            app.buttons["setupAutofill.button"].tap()
        }
        let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        waitforExistence(settingsApp.cells.staticTexts["Passwords & Accounts"])
    }

    // Once app is open
    func testSetAutofillSettings() {
        // Open Setting to add Lockbox
        navigator.goto(Screen.SettingsMenu)
        navigator.performAction(Action.OpenDeviceSettings)
        // Wait until settings app is open
        let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        waitforExistence(settingsApp.cells.staticTexts["Passwords & Accounts"])
        // Configure Passwords & Accounts settings
        settingsApp.cells.staticTexts["Passwords & Accounts"].tap()
        settingsApp.cells.staticTexts["AutoFill Passwords"].tap()
        settingsApp.switches["AutoFill Passwords"].tap()
        waitforExistence(settingsApp.cells.staticTexts["Lockbox"])
        settingsApp.cells.staticTexts["Lockbox"].tap()
        // Wait until the app is updated
        sleep(5)
        settingsApp.terminate()

        // Open Safari
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        waitforExistence(safari.buttons["URL"], timeout: 5)
        waitforExistence(safari.textFields["Email or phone"])
        safari.textFields["Email or phone"].tap()
        // Need to confirm what is shown here, different elements have appeared and
        if (safari.otherElements["Password Auto-fill"].exists) {
            safari.otherElements["Password Auto-fill"].tap()
        }
        safari.buttons["Use “iosmztest@gmail.com”"].tap()
        // Once previous is clear we can assert that the element shown is correct
        //XCTAssertTrue(safari.buttons["iosmztest@gmail.com, for this website — Lockbox"].exists)
        safari.terminate()
    }
}
