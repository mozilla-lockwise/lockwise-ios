/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ItemDetailDisplayAction: Action {
    case togglePassword(displayed: Bool)
}

extension ItemDetailDisplayAction: Equatable {
    static func ==(lhs: ItemDetailDisplayAction, rhs: ItemDetailDisplayAction) -> Bool {
        switch (lhs, rhs) {
        case (.togglePassword(let lhDisplay), .togglePassword(let rhDisplay)):
            return lhDisplay == rhDisplay
        }
    }
}

class ItemDetailActionHandler: ActionHandler {
    static let shared = ItemDetailActionHandler()

    private let dispatcher: Dispatcher

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher
    }

    func invoke(_ displayAction: ItemDetailDisplayAction) {
        self.dispatcher.dispatch(action: displayAction)
    }
}
