/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

protocol AutoLockSettingsProtocol {
    func bind(items: Driver<[AutoLockSettingSectionModel]>)
}

typealias AutoLockSettingSectionModel = AnimatableSectionModel<Int, CheckmarkSettingCellConfiguration>

class AutoLockSettingsView: UITableViewController {
    var presenter: AutoLockSettingsPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<AutoLockSettingSectionModel>?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.presenter = AutoLockSettingsPresenter(view: self)
        view.backgroundColor = Constant.color.settingsBackground
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavbar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        presenter?.onViewReady()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell()
        cell.textLabel?.textColor = Constant.color.settingsHeader
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.regular)
        cell.textLabel?.text = Constant.string.autoLockHeader
        cell.textLabel?.textAlignment = NSTextAlignment.center
        return cell
    }
}

extension AutoLockSettingsView {
    private func setupNavbar() {
        navigationItem.title = Constant.string.settingsAutoLock
    }

    private func setupDataSource() {
        dataSource = RxTableViewSectionedReloadDataSource(configureCell: { (_, tableView, indexPath, cellConfiguration) -> UITableViewCell in
            let cell = UITableViewCell()
            cell.textLabel?.text = cellConfiguration.text

            cell.accessoryType = cellConfiguration.isChecked ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none

            return cell
        })
    }
}

extension AutoLockSettingsView: AutoLockSettingsProtocol {
    func bind(items: SharedSequence<DriverSharingStrategy, [AutoLockSettingSectionModel]>) {
        guard let dataSource = self.dataSource else {
            fatalError("datasource not set!")
        }

        items
            .drive(self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: self.disposeBag)
    }
}
