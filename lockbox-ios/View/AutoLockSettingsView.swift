/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias AutoLockSettingSectionModel = AnimatableSectionModel<Int, CheckmarkSettingCellConfiguration>

class AutoLockSettingView: UITableViewController {
    var presenter: AutoLockSettingPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<AutoLockSettingSectionModel>?

    init() {
        super.init(style: UITableViewStyle.grouped)
        self.presenter = AutoLockSettingPresenter(view: self)
        view.backgroundColor = Constant.color.viewBackground
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavbar()
        self.setupFooter()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDataSource()
        self.setupDelegate()
        self.presenter?.onViewReady()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell()
        cell.textLabel?.textColor = Constant.color.settingsHeader
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.regular)
        cell.textLabel?.text = Constant.string.autoLockHeader
        cell.textLabel?.textAlignment = NSTextAlignment.center
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}

extension AutoLockSettingView {
    private func setupNavbar() {
        navigationItem.title = Constant.string.settingsAutoLock
    }

    private func setupFooter() {
        self.tableView.tableFooterView = UIView()
    }

    private func setupDataSource() {
        self.dataSource = RxTableViewSectionedReloadDataSource(
            configureCell: {(_, _, _, cellConfiguration) -> UITableViewCell in
            let cell = SettingCell()
            cell.textLabel?.text = cellConfiguration.text
            cell.selectionStyle = UITableViewCellSelectionStyle.none

            cell.accessoryType = cellConfiguration.isChecked ?
                UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none

            return cell
        })
    }

    private func setupDelegate() {
        if let presenter = self.presenter {
            self.tableView.rx.itemSelected
                    .map { (indexPath) -> AutoLockSetting? in
                        self.tableView.deselectRow(at: indexPath, animated: true)
                        return self.dataSource?[indexPath].valueWhenChecked as? AutoLockSetting
                    }.bind(to: presenter.itemSelectedObserver)
                    .disposed(by: self.disposeBag)
        }
    }
}

extension AutoLockSettingView: AutoLockSettingViewProtocol {
    func bind(items: SharedSequence<DriverSharingStrategy, [AutoLockSettingSectionModel]>) {
        if let dataSource = self.dataSource {
            items
                    .drive(self.tableView.rx.items(dataSource: dataSource))
                    .disposed(by: self.disposeBag)
        }
    }
}
