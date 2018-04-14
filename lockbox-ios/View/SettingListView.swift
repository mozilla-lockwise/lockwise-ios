/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias SettingSectionModel = AnimatableSectionModel<Int, SettingCellConfiguration>

class SettingListView: UIViewController {
    var presenter: SettingListPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<SettingSectionModel>?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var signOutButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDataSource()
        self.setupDelegate()
        self.setupSignOutButton()
        self.presenter?.onViewReady()
    }

override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavbar()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = SettingListPresenter(view: self)
    }
}

extension SettingListView: SettingListViewProtocol {
    public var onSignOut: ControlEvent<Void> {
        return self.signOutButton.rx.tap
    }

    func bind(items: Driver<[SettingSectionModel]>) {
        if let dataSource = self.dataSource {
            items.drive(self.tableView.rx.items(dataSource: dataSource))
                    .disposed(by: self.disposeBag)
        }
    }
}

extension SettingListView {
    private func setupDataSource() {
        self.dataSource = RxTableViewSectionedReloadDataSource(
                configureCell: { _, _, _, cellConfiguration in

                let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "settings-cell")
                cell.textLabel?.text = cellConfiguration.text

                if cellConfiguration.routeAction != nil {
                    cell.accessoryType = .disclosureIndicator
                    cell.detailTextLabel?.text = cellConfiguration.detailText
                } else if let switchSetting = cellConfiguration as? SwitchSettingCellConfiguration {
                    let switchItem = UISwitch()
                    switchItem.onTintColor = Constant.color.lockBoxBlue
                    switchItem.addTarget(self, action: #selector(self.switchChanged), for: .valueChanged)
                    switchItem.isOn = switchSetting.isOn
                    cell.accessoryView = switchItem
                    cell.selectionStyle = UITableViewCellSelectionStyle.none
                }
                return cell
        }, titleForHeaderInSection: { _, section in
            return section == 0 ? Constant.string.settingsHelpSectionHeader :
                    Constant.string.settingsConfigurationSectionHeader
         })
    }

    private func setupDelegate() {
        if let presenter = self.presenter {
            self.tableView.rx.itemSelected
                    .map { path -> SettingRouteAction? in
                        self.tableView.deselectRow(at: path, animated: true)
                        return self.dataSource?[path].routeAction
                    }
                    .bind(to: presenter.onSettingCellTapped)
                    .disposed(by: self.disposeBag)
        }
    }

    private func setupNavbar() {
        self.navigationItem.title = Constant.string.settingsTitle
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Constant.string.done,
                style: .done,
                target: nil,
                action: nil)
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white

        if let presenter = presenter {
            navigationItem.rightBarButtonItem?.rx.tap
                    .bind(to: presenter.onDone)
                    .disposed(by: self.disposeBag)
        }
    }

    fileprivate func setupSignOutButton() {
        self.signOutButton.addTopBorderWithColor(color: Constant.color.cellBorderGrey, width: 0.5)
        self.signOutButton.addBottomBorderWithColor(color: Constant.color.cellBorderGrey, width: 0.5)
    }

    // todo: refactor this to use an rxcocoa binding on the switch
    @objc private func switchChanged(sender: UISwitch) {
        let rowChanged = sender.tag
        presenter?.switchChanged(row: rowChanged, isOn: sender.isOn)
    }
}

class SettingCellConfiguration {
    var text: String
    var routeAction: SettingRouteAction?
    var detailText: String?

    init(text: String, routeAction: SettingRouteAction?) {
        self.text = text
        self.routeAction = routeAction
    }
}

extension SettingCellConfiguration: IdentifiableType {
    var identity: String {
        return self.text
    }
}

extension SettingCellConfiguration: Equatable {
    static func ==(lhs: SettingCellConfiguration, rhs: SettingCellConfiguration) -> Bool {
        return lhs.text == rhs.text && lhs.routeAction == rhs.routeAction
    }
}

class SwitchSettingCellConfiguration: SettingCellConfiguration {
    var isOn: Bool = false

    init(text: String, routeAction: SettingRouteAction?, isOn: Bool = false) {
        super.init(text: text, routeAction: routeAction)
        self.isOn = isOn
    }
}

class CheckmarkSettingCellConfiguration: SettingCellConfiguration {
    var isChecked: Bool = false
    var valueWhenChecked: Any?

    init(text: String, isChecked: Bool = false, valueWhenChecked: Any?) {
        super.init(text: text, routeAction: nil)
        self.isChecked = isChecked
        self.valueWhenChecked = valueWhenChecked
    }
}
