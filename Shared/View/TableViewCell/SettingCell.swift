/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift

class SettingCell: UITableViewCell {
    var disposeBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()

        self.disposeBag = DisposeBag()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        self.backgroundColor = highlighted ? Constant.color.tableViewCellHighlighted : .white
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority) -> CGSize {

        self.layoutIfNeeded()

        var size = super.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority)

        // This bug is fixed in iOS 11 and only appears on cells with subtitles
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion.init(
            majorVersion: 11,
            minorVersion: 0,
            patchVersion: 0)) {

            if let detailTextLabel = self.detailTextLabel,
                let textLabel = self.textLabel {

                if detailTextLabel.frame.height > textLabel.frame.height {
                    size.height += detailTextLabel.frame.height - textLabel.frame.height
                }
            }
        }

        return size
    }
}
