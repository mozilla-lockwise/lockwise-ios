/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit

let settingsTitles = [
    UIConstants.strings.settingsHelpProvideFeedback,
    UIConstants.strings.settingsHelpFAQ,
    UIConstants.strings.settingsHelpEnableInBrowser,
    UIConstants.strings.settingsConfigurationAccount,
    UIConstants.strings.settingsConfigurationTouchID,
    UIConstants.strings.settingsConfigurationAutoLock,
]

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = UIConstants.strings.settingsTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: UIConstants.strings.done, style: UIBarButtonItemStyle.done, target: self, action: #selector(SettingsViewController.doneTapped))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ], for: .normal)
        
        navigationController!.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        view.backgroundColor = UIConstants.colors.settingsBackground
        tableView.tableFooterView = UIView()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell()
        cell.textLabel?.textColor = UIConstants.colors.settingsHeader
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13.0, weight: UIFont.Weight.regular)
        
        cell.textLabel?.text = section == 0 ? UIConstants.strings.settingsHelpSectionHeader : UIConstants.strings.settingsConfigurationSectionHeader
        return cell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.section * 3 + indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "settingsCell")
        
        cell.textLabel?.text = settingsTitles[row]
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    @objc func doneTapped() {
        dismiss(animated: true, completion: nil)
    }
}
