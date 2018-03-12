/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift

class ItemDetailCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var revealButton: UIButton!

    var disposeBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()

        self.disposeBag = DisposeBag()
    }
}
