/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import UIKit

protocol LinkAction: Action {}

struct ExternalLinkAction: LinkAction {
    let baseURLString: String
}

enum SettingLinkAction: RouteAction {
    case touchIDPasscode
    case autofill
}

extension ExternalLinkAction: Equatable {
    static func ==(lhs: ExternalLinkAction, rhs: ExternalLinkAction) -> Bool {
        return lhs.baseURLString == rhs.baseURLString
    }
}

extension ExternalLinkAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .tap
    }

    var eventObject: TelemetryEventObject {
        return .openInBrowser
    }

    var value: String? {
        return nil
    }

    var extras: [String: Any?]? {
        return nil
    }
}
