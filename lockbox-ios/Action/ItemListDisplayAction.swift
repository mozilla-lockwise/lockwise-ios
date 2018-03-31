/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol ItemListDisplayAction: Action {}

struct ItemListFilterAction: ItemListDisplayAction {
    let filteringText: String
}

enum ItemListSortingAction: ItemListDisplayAction {
    case alphabetically, recentlyUsed
}

class ItemListDisplayActionHandler: ActionHandler {
    static let shared = ItemListDisplayActionHandler()
    private let dispatcher: Dispatcher

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher
    }

    func invoke(_ action: ItemListDisplayAction) {
        self.dispatcher.dispatch(action: action)
    }
}
