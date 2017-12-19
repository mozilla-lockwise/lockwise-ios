/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

class ItemListView : UITableViewController, ItemListViewProtocol {
    var presenter:ItemListPresenter!
    internal(set) var webView: WebView

    private var items:[Item] = []

    required init?(coder aDecoder: NSCoder) {
        self.webView = WebView(frame: .zero, configuration: WKWebViewConfiguration())
        super.init(coder: aDecoder)
    }

    func displayItems(_ items: [Item]) {
        self.items = items
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.webView)
        styleNavigationBar()

        self.presenter.onViewReady()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemlistcell") as? ItemListCell
        let item = items[indexPath.row]

        cell!.titleLabel.text = item.title
        cell!.detailLabel.text = item.entry.username
        cell!.kebabButton.tintColor = UIColor.kebabBlue

        return cell!
    }

    private func styleNavigationBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "preferences"), style: .done, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem?.tintColor = .white
        self.navigationItem.title = "Your Lockbox"

        self.navigationController!.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 20, weight: .regular)
        ]

        self.navigationController!.navigationBar.addLockboxGradient()
        self.navigationController!.navigationBar.layoutIfNeeded()
    }
}
