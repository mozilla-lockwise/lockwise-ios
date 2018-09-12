/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol ItemListDisplayAction: Action {}

struct ItemListFilterAction: ItemListDisplayAction {
    let filteringText: String
}

struct ItemListFilterEditAction: ItemListDisplayAction {
    let editing: Bool
}

struct PullToRefreshAction: ItemListDisplayAction {
    let refreshing: Bool
}
