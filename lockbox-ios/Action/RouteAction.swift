/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class RouteActionHandler : ActionHandler {
    fileprivate var dispatcher:Dispatcher

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher
    }
}

protocol RouteAction: Action { }

enum LoginRouteAction: RouteAction {
    case login
    case fxa
}

class LoginRouteActionHandler: RouteActionHandler {
    static let shared = LoginRouteActionHandler()

    func invoke(_ action: LoginRouteAction) {
        self.dispatcher.dispatch(action: action)
    }
}

enum MainRouteAction: RouteAction {
    case list
    case detail(itemId:String)
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

class MainRouteActionHandler : RouteActionHandler {
    static let shared = MainRouteActionHandler()

    func invoke(_ action: MainRouteAction) {
        self.dispatcher.dispatch(action: action)
    }
}
