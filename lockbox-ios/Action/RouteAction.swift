/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol RouteAction: Action { }

struct ExternalWebsiteRouteAction: RouteAction {
    let urlString: String
    let title: String
    let returnRoute: RouteAction
}

extension ExternalWebsiteRouteAction: Equatable {
    static func ==(lhs: ExternalWebsiteRouteAction, rhs: ExternalWebsiteRouteAction) -> Bool {
        return lhs.urlString == rhs.urlString && lhs.title == rhs.title
    }
}

extension ExternalWebsiteRouteAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .show
    }

    var eventObject: TelemetryEventObject {
        switch self.urlString {
        case let str where str.contains(Constant.app.provideFeedbackURL):
            return .settingsProvideFeedback
        case Constant.app.getSupportURL:
            return .settingsGetSupport
        case Constant.app.faqURLtop:
            return .settingsFaq
        case Constant.app.privacyURL:
            return .settingsPrivacy
        case Constant.app.securityFAQ:
            return .onboardingConfirmationPrivacy
        default:
            return .externalWebsite
        }
    }

    var value: String? {
        return nil
    }

    var extras: [String: Any?]? {
        return nil
    }
}

enum LoginRouteAction: RouteAction {
    case welcome
    case fxa
    case onboardingConfirmation
    case autofillOnboarding
    case autofillInstructions
}

extension LoginRouteAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .show
    }

    var eventObject: TelemetryEventObject {
        switch self {
        case .welcome:
            return .loginWelcome
        case .fxa:
            return .loginFxa
        case .onboardingConfirmation:
            return .loginOnboardingConfirmation
        case .autofillOnboarding:
            return .autofillOnboarding
        case .autofillInstructions:
            return .autofillOnboardingInstructions
        }
    }

    var value: String? {
        return nil
    }

    var extras: [String: Any?]? {
      return nil
    }
}

enum MainRouteAction: RouteAction {
    case list
    case detail(itemId: String)
}

extension MainRouteAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .show
    }

    var eventObject: TelemetryEventObject {
        switch self {
        case .list:
            return .entryList
        case .detail:
            return .entryDetail
        }
    }

    var value: String? {
        return nil
    }

    var extras: [String: Any?]? {
        switch self {
        case .list:
            return nil
        case .detail(let itemId):
            return [ExtraKey.itemid.rawValue: itemId]
        }
    }
}

enum SettingRouteAction: RouteAction {
    case list
    case account
    case autoLock
    case preferredBrowser
    case autofillInstructions
}

extension SettingRouteAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .show
    }

    var eventObject: TelemetryEventObject {
        switch self {
        case .list:
            return .settingsList
        case .account:
            return .settingsAccount
        case .autoLock:
            return .settingsAutolock
        case .preferredBrowser:
            return .settingsPreferredBrowser
        case .autofillInstructions:
            return .autofillSettingsInstructions
        }
    }

    var value: String? {
        return nil
    }

    var extras: [String: Any?]? {
        return nil
    }
}

extension MainRouteAction: Equatable {
    static func ==(lhs: MainRouteAction, rhs: MainRouteAction) -> Bool {
        switch (lhs, rhs) {
        case (.list, .list):
            return true
        case (.detail(let lhId), .detail(let rhId)):
            return lhId == rhId
        default:
            return false
        }
    }
}

struct OnboardingStatusAction: Action {
    var onboardingInProgress: Bool
}

extension OnboardingStatusAction: Equatable {
    static func ==(lhs: OnboardingStatusAction, rhs: OnboardingStatusAction) -> Bool {
        return lhs.onboardingInProgress == rhs.onboardingInProgress
    }
}
