/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

class ItemListView: UITableViewController {
    var presenter:ItemListPresenter?

    private var items:[Item] = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = ItemListPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let prefButton = UIButton()
        let prefImage = UIImage(named: "preferences")?.withRenderingMode(.alwaysTemplate)
        prefButton.setImage(prefImage, for: .normal)
        prefButton.tintColor = .white

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: prefButton)
        self.navigationItem.title = Constant.string.yourLockbox

        self.navigationController!.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = Constant.color.lightGrey
        self.tableView.backgroundView = backgroundView

        self.presenter?.onViewReady()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemlistcell") as? ItemListCell else {
            fatalError("couldn't find the right cell!")
        }
        let item = items[indexPath.row]

        cell.titleLabel.text = item.title
        cell.detailLabel.text = (item.entry.username == "" || item.entry.username == nil) ? Constant.string.noUsername : item.entry.username
        cell.kebabButton.tintColor = Constant.color.kebabBlue

        return cell
    }
}

extension ItemListView: ItemListViewProtocol {
    func displayItems(_ items: [Item]) {
        self.items = items
        self.tableView.reloadData()
    }

    func displayEmptyStateMessaging() {
        guard let emptyStateView = Bundle.main.loadNibNamed("EmptyList", owner: self)?[0] as? UIView else { return }
        self.tableView.backgroundView?.addSubview(emptyStateView)
    }

    func hideEmptyStateMessaging() {
        self.tableView.backgroundView?.subviews.forEach({ $0.removeFromSuperview() })
    }
}
