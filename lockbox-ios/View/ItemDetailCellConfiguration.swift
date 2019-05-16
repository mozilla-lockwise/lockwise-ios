/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import UIKit
import RxDataSources
import RxSwift
import RxCocoa

struct ItemDetailCellConfiguration {
    let title: String
    let value: String
    let accessibilityLabel: String
    let valueFontColor: UIColor
    let accessibilityId: String
    let textFieldEnabled: Driver<Bool>
    let copyButtonHidden: Driver<Bool>
    let openButtonHidden: Driver<Bool>
    let textObserver: AnyObserver<String>?
    let revealPasswordObserver: AnyObserver<Bool>?
    let dragValue: String?

    init(title: String,
         value: String,
         accessibilityLabel: String,
         valueFontColor: UIColor = UIColor.black,
         accessibilityId: String,
         textFieldEnabled: Driver<Bool>,
         copyButtonHidden: Driver<Bool> = Driver.just(true),
         openButtonHidden: Driver<Bool> = Driver.just(true),
         textObserver: AnyObserver<String>? = nil,
         revealPasswordObserver: AnyObserver<Bool>? = nil,
         dragValue: String? = nil) {
        self.title = title
        self.value = value
        self.accessibilityLabel = accessibilityLabel
        self.valueFontColor = valueFontColor
        self.accessibilityId = accessibilityId
        self.textFieldEnabled = textFieldEnabled
        self.copyButtonHidden = copyButtonHidden
        self.openButtonHidden = openButtonHidden
        self.textObserver = textObserver
        self.revealPasswordObserver = revealPasswordObserver
        self.dragValue = dragValue
    }
}

extension ItemDetailCellConfiguration: IdentifiableType {
    var identity: String {
        return self.title
    }
}

extension ItemDetailCellConfiguration: Equatable {
    static func ==(lhs: ItemDetailCellConfiguration, rhs: ItemDetailCellConfiguration) -> Bool {
        return lhs.value == rhs.value
    }
}

typealias ItemDetailSectionModelObserver = ((Observable<[ItemDetailSectionModel]>) -> Disposable)
