/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MappaMundi
import XCTest

let WelcomeScreen = "WelcomeScreen"
let LockboxMainPage = "LockboxMainPage"
let SettingsMenu = "SettingsMenu"

let FxASigninScreen = "FxASigninScreen"
let FxCreateAccount = "FxCreateAccount"

let OpenSitesInMenu = "OpenSitesInMenu"
let LockedScreen = "LockedScreen"
let AccountSettingsMenu = "AccountSettingsMenu"
let AutolockSettingsMenu = "AutolockSettingsMenu"

class Action {

    static let FxATypeEmail = "FxATypeEmail"
    static let FxATypePassword = "FxATypePassword"
    static let FxATapOnSignInButton = "FxATapOnSignInButton"
    static let FxALogInSuccessfully = "FxALogInSuccessfully"

    static let OpenSettingsMenu = "OpenSettingsMenu"

    static let LockNow = "LockNow"
}

@objcMembers
class FxUserState: MMUserState {
    required init() {
        super.init()
        initialScreenState = WelcomeScreen
    }

    var fxaUsername: String? = nil
    var fxaPassword: String? = nil
}

func createScreenGraph(for test: XCTestCase, with app: XCUIApplication) -> MMScreenGraph<FxUserState> {
    let map = MMScreenGraph(for: test, with: FxUserState.self)

    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    let cancelBackAction = {
        app.navigationBars["Lockbox.FxAView"].buttons["Cancel"].tap()
    }

    map.addScreenState(WelcomeScreen) { screenState in
        if (app.buttons["Get Started"].exists) {
            screenState.tap(app.buttons["Get Started"], to: FxASigninScreen)
        } else {
            screenState.noop(to: LockboxMainPage)
        }
    }

    map.addScreenState(FxASigninScreen) { screenState in
        screenState.gesture(forAction: Action.FxATypeEmail) { userState in
            app.webViews.textFields["Email"].tap()
            app.webViews.textFields["Email"].typeText(userState.fxaUsername!)
        }
        screenState.gesture(forAction: Action.FxATypePassword) { userState in
            app.webViews.secureTextFields["Password"].tap()
            app.webViews.secureTextFields["Password"].typeText(userState.fxaPassword!)
        }
        screenState.gesture(forAction: Action.FxATapOnSignInButton) { userState in
            app.webViews.buttons["Sign in"].tap()
        }

        screenState.gesture(forAction: Action.FxALogInSuccessfully, transitionTo: LockboxMainPage) { userState in
            app.webViews.buttons["Sign in"].tap()
            userState.fxaUsername = userState.fxaUsername!
            userState.fxaPassword = userState.fxaPassword!
        }
        screenState.tap(app.webViews.links["Create an account"], to: FxCreateAccount)
    }

    map.addScreenState(FxCreateAccount) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(LockboxMainPage) { screenState in
        screenState.tap(app.buttons["preferences"], to: SettingsMenu)
        screenState.dismissOnUse = true
    }

    map.addScreenState(SettingsMenu) { screenState in
        screenState.tap(app.tables.cells.staticTexts["Open Websites in"], to: OpenSitesInMenu)
        screenState.tap(app.tables.cells.staticTexts["Account"], to: AccountSettingsMenu)
        screenState.tap(app.tables.cells.staticTexts["Auto Lock"], to: AutolockSettingsMenu)

        screenState.gesture(forAction: Action.LockNow, transitionTo: LockedScreen) { userState in
            app.buttons["Lock Now"].tap()
        }
        screenState.dismissOnUse = true
    }

    map.addScreenState(OpenSitesInMenu) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(AccountSettingsMenu) { screenState in
        screenState.backAction = navigationControllerBackAction
        screenState.dismissOnUse = true
    }

    map.addScreenState(AutolockSettingsMenu) { screenState in
        screenState.backAction = navigationControllerBackAction
        screenState.dismissOnUse = true
    }

    map.addScreenState(LockedScreen) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    return map
}
