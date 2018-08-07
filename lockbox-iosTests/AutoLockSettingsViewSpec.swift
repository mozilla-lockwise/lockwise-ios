/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxCocoa

@testable import Lockbox

class AutoLockSettingsViewSpec: QuickSpec {

    class FakeAutoLockSettingPresenter: AutoLockSettingPresenter {
        var onViewReadyCalled = false
        var onItemSelectedActionDispatched = false

        override func onViewReady() {
            self.onViewReadyCalled = true
        }

        override var itemSelectedObserver: AnyObserver<Setting.AutoLock?> {
            return Binder(self) { target, _ in
                target.onItemSelectedActionDispatched = true
                }.asObserver()
        }
    }

    var subject: AutoLockSettingView!
    var presenter: FakeAutoLockSettingPresenter!

    override func spec() {
        beforeEach {
            self.subject = AutoLockSettingView()
            self.presenter = FakeAutoLockSettingPresenter(view: self.subject)
            self.subject.presenter = self.presenter
            self.subject.viewWillAppear(false)
            self.subject.viewDidLoad()
        }

        it("informs the presenter") {
            expect(self.presenter.onViewReadyCalled).to(beTrue())
        }

        it("labels the header") {
            expect((self.subject.tableView(self.subject.tableView, viewForHeaderInSection: 0) as? UITableViewCell)?.textLabel?.text).to(equal(Constant.string.autoLockHeader))
        }

        describe("tableview datasource configuration") {
            let configDriver = PublishSubject<[AutoLockSettingSectionModel]>()

            let sectionModels = [AutoLockSettingSectionModel(model: 0, items: [
                CheckmarkSettingCellConfiguration(text: "One Hour", isChecked: false, valueWhenChecked: Setting.AutoLock.OneHour),
                CheckmarkSettingCellConfiguration(text: "Never", isChecked: true, valueWhenChecked: Setting.AutoLock.Never),
                CheckmarkSettingCellConfiguration(text: "One Minute", isChecked: false, valueWhenChecked: Setting.AutoLock.OneMinute)
            ])]

            beforeEach {
                self.subject.bind(items: configDriver.asDriver(onErrorJustReturn: []))
                configDriver.onNext(sectionModels)
                (self.subject.tableView.delegate!).tableView!(self.subject.tableView, didSelectRowAt: [0, 0])
            }

            it("configures table view based on model") {
                expect(self.subject.tableView.numberOfSections).to(equal(1))
                expect(self.subject.tableView.numberOfRows(inSection: 0)).to(equal(3))
                expect(self.subject.tableView.cellForRow(at: IndexPath(row: 1, section: 0))?.accessoryType).to(equal(UITableViewCell.AccessoryType.checkmark))
                expect(self.subject.tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType).to(equal(UITableViewCell.AccessoryType.none))
                expect(self.subject.tableView.cellForRow(at: IndexPath(row: 2, section: 0))?.accessoryType).to(equal(UITableViewCell.AccessoryType.none))
            }

            it("calls presenter when cell is tapped") {
                expect(self.presenter.onItemSelectedActionDispatched).to(beTrue())
            }
        }
    }
}
