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

protocol RouteAction: Action {
    func equalTo(_ other: RouteAction) -> Bool
    var asEquatable: EquatableRouteAction { get }
}

enum LoginRouteAction: RouteAction {
    case welcome
    case fxa
}

enum MainRouteAction: RouteAction {
    case list
    case detail(itemId: String)
}

enum SettingRouteAction: RouteAction {
    case list
    case provideFeedback
    case faq
    case enableInBrowser
    case account
    case autoLock
}

extension RouteAction where Self: Equatable {
    func equalTo(_ other: RouteAction) -> Bool {
        guard let o = other as? Self else {
            return false
        }

        return self == o
    }

    var asEquatable: EquatableRouteAction {
        return EquatableRouteAction(self)
    }
}

struct EquatableRouteAction: RouteAction, Equatable {
    init(_ value: RouteAction) { self.value = value }
    private let value: RouteAction
    static func ==(lhs: EquatableRouteAction, rhs: EquatableRouteAction) -> Bool {
        return lhs.value.equalTo(rhs.value)
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
