/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class RouteActionHandler: ActionHandler {
    static let shared = RouteActionHandler()
    fileprivate var dispatcher: Dispatcher

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher
    }

    func invoke(_ action: RouteAction) {
        self.dispatcher.dispatch(action: action)
    }
}

protocol RouteAction: Action { }

enum LoginRouteAction: RouteAction {
    case welcome
    case fxa
    case learnMore
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
        case .learnMore:
            return .loginLearnMore
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
    case learnMore
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
        case .learnMore:
            return .entryListLearnMore
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
        case .learnMore:
            return nil
        }
    }
}

enum SettingRouteAction: RouteAction {
    case list
    case provideFeedback
    case faq
    case account
    case autoLock
    case preferredBrowser
}

extension SettingRouteAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .show
    }

    var eventObject: TelemetryEventObject {
        switch self {
        case .list:
            return .settingsList
        case .provideFeedback:
            return .settingsProvideFeedback
        case .faq:
            return .settingsFaq
        case .account:
            return .settingsAccount
        case .autoLock:
            return .settingsAutolock
        case .preferredBrowser:
            return .settingsPreferredBrowser

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
        case (.learnMore, .learnMore):
            return true
        default:
            return false
        }
    }
}
