/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import Foundation
import UIKit

protocol SettingsProtocol {
    func setItems(items: [Setting])
}

class SettingsView: UITableViewController {
    var presenter: SettingsPresenter?
    var settings: [Setting]?

    init() {
        super.init(nibName: nil, bundle: nil)
        self.presenter = SettingsPresenter(view: self)
        view.backgroundColor = Constant.color.settingsBackground
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

    }
    
    private func setupNavbar() {
        navigationItem.title = NSLocalizedString("settings.title", value: "Settings", comment: "Title on settings screen")
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("settings.done", value: "Done", comment: "Text on button to close settings"), style: .done, target: self, action: #selector(doneTapped))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white
    }
    
    private func setupFooter() {
        let footer = UIView()
        tableView.tableFooterView = footer
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavbar()
        setupFooter()
    }
    
    override func viewDidLoad() {
        presenter?.onViewReady()
    }
    
    @objc private func doneTapped() {
        presenter?.dismiss()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings != nil ? 3 : 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.section * 3 + indexPath.row
        let cell = UITableViewCell()
        cell.textLabel?.text = settings?[row].text
        
        if let setting = settings?[row] {
            if setting.routeAction != nil {
                cell.accessoryType = .disclosureIndicator
            } else if let switchSetting = setting as? SwitchSetting {
                let switchItem = UISwitch()
                switchItem.onTintColor = Constant.color.lockBoxBlue
                switchItem.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
                switchItem.tag = row
                switchItem.isOn = switchSetting.isOn
                cell.accessoryView = switchItem
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell()
        cell.textLabel?.textColor = Constant.color.settingsHeader
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.regular)
        cell.textLabel?.text = section == 0 ? Constant.string.settingsHelpSectionHeader : Constant.string.settingsConfigurationSectionHeader
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings != nil ? 2 : 0
    }
    
    @objc private func switchChanged(sender: UISwitch) {
        let rowChanged = sender.tag
        presenter?.switchChanged(row: rowChanged, isOn: sender.isOn)
    }
}

extension SettingsView: SettingsProtocol {
    func setItems(items: [Setting]) {
        settings = items
        tableView.reloadData()
    }
}

class Setting {
    var text: String
    var routeAction: SettingsRouteAction?
    
    init(text: String, routeAction: SettingsRouteAction?) {
        self.text = text
        self.routeAction = routeAction
    }
}

class SwitchSetting: Setting {
    var isOn: Bool = false
    
    init(text: String, routeAction: SettingsRouteAction?, isOn:Bool = false) {
        super.init(text: text, routeAction: routeAction)
        self.isOn = isOn
    }
}
