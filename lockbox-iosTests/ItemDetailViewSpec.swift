/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxCocoa
import RxDataSources
import RxTest

@testable import Lockbox

class ItemDetailViewSpec: QuickSpec {

    class FakeItemDetailPresenter: ItemDetailPresenter {
        var onViewReadyCalled = false
        var onPasswordToggleActionDispatched: Bool?
        var onCancelActionDispatched = false
        var onCellTappedValue: String?

        override func onViewReady() {
            self.onViewReadyCalled = true
        }

        override var onPasswordToggle: AnyObserver<Bool> {
            return Binder(self) { target, argument in
                target.onPasswordToggleActionDispatched = argument
            }.asObserver()
        }

        override var onCancel: AnyObserver<Void> {
            return Binder(self) { target, _ in
                target.onCancelActionDispatched = true
            }.asObserver()
        }

        override var onCellTapped: AnyObserver<String?> {
            return Binder(self) { target, value in
                target.onCellTappedValue = value
            }.asObserver()
        }
    }

    private var presenter: FakeItemDetailPresenter!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: ItemDetailView!

    override func spec() {
        describe("ItemDetailView") {
            beforeEach {
                let sb = UIStoryboard(name: "ItemDetail", bundle: nil)
                self.subject = sb.instantiateViewController(withIdentifier: "itemdetailview") as? ItemDetailView
                self.presenter = FakeItemDetailPresenter(view: self.subject)

                self.subject.presenter = self.presenter

                self.subject.preloadView()
            }

            it("informs the presenter") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("itemId") {
                it("returns an empty string when it hasn't been configured") {
                    expect(self.subject.itemId).to(equal(""))
                }

                it("returns the itemId it was configured with") {
                    let id = "fdssdfdfsdf"
                    self.subject.itemId = id
                    expect(self.subject.itemId).to(equal(id))
                }
            }

            describe("tableview datasource configuration") {
                let configDriver = PublishSubject<[ItemDetailSectionModel]>()
                let sectionModels = [
                    ItemDetailSectionModel(model: 0, items: [
                        ItemDetailCellConfiguration(
                                title: Constant.string.webAddress,
                                value: "www.meow.com",
                                accessibilityLabel: "something accessible",
                                password: false,
                                valueFontColor: Constant.color.lockBoxBlue,
                                accessibilityId: "")
                    ]),
                    ItemDetailSectionModel(model: 1, items: [
                        ItemDetailCellConfiguration(
                                title: Constant.string.username,
                                value: "tanya",
                                accessibilityLabel: "something else accessible",
                                password: false,
                                accessibilityId: ""),
                        ItemDetailCellConfiguration(
                                title: Constant.string.password,
                                value: "••••••••••",
                                accessibilityLabel: "something else accessible",
                                password: true,
                                accessibilityId: "")
                    ]),
                    ItemDetailSectionModel(model: 2, items: [
                        ItemDetailCellConfiguration(
                                title: Constant.string.notes,
                                value: "some long note about whatever thing yeahh",
                                accessibilityLabel: "something else accessible",
                                password: false,
                                accessibilityId: "")
                    ])
                ]

                beforeEach {
                    self.subject.bind(itemDetail: configDriver.asDriver(onErrorJustReturn: []))

                    configDriver.onNext(sectionModels)
                }

                it("configures the tableview based on the models provided") {
                    expect(self.subject.tableView.numberOfSections).to(equal(sectionModels.count))
                }

                it("binds password reveal tap actions to the appropriate presenter listener") {
                    let cell = self.subject.tableView.cellForRow(at: [1, 1]) as! ItemDetailCell
                    cell.revealButton.sendActions(for: .touchUpInside)

                    expect(self.presenter.onPasswordToggleActionDispatched).to(beTrue())
                }

                describe("tapping cells") {
                    beforeEach {
                        self.subject.tableView.delegate!.tableView!(self.subject.tableView, didSelectRowAt: [1, 0])
                    }

                    it("extracts the titlelabel text and tells the presenter") {
                        expect(self.presenter.onCellTappedValue).to(equal(Constant.string.username))
                    }
                }

                it("sets the font color for web address") {
                    expect((self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell).valueLabel.textColor).to(equal(Constant.color.lockBoxBlue))
                }

                it("sets the passed accessibility label for every cell") {
                    expect(self.subject.tableView.cellForRow(at: [0, 0])?.accessibilityLabel).to(equal("something accessible"))
                }
            }

            describe("title text") {
                let textDriver = PublishSubject<String>()
                beforeEach {
                    self.subject.bind(titleText: textDriver.asDriver(onErrorJustReturn: ""))
                }

                it("updates the navigation title with new values") {
                    let title = "new title"
                    textDriver.onNext(title)
                    expect(self.subject.navigationItem.title).to(equal(title))
                }
            }

            describe("tapping cancel button") {
                beforeEach {
                    let button = self.subject.navigationItem.leftBarButtonItem!.customView as! UIButton
                    _ = button.sendActions(for: .touchUpInside)
                }

                it("informs the presenter") {
                    expect(self.presenter.onCancelActionDispatched).to(beTrue())
                }
            }

            describe("tapping learnHowToEdit button") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)

                    self.subject.learnHowToEditTapped.bind(to: voidObserver).disposed(by: self.disposeBag)
                    self.subject.learnHowToEditButton.sendActions(for: .touchUpInside)
                }

                it("informs any observers") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }

            describe("tapping a password reveal button") {
                let sectionModelWithJustPassword = [
                    ItemDetailSectionModel(model: 1, items: [
                        ItemDetailCellConfiguration(
                                title: Constant.string.password,
                                value: "••••••••••",
                                accessibilityLabel: "something accessible",
                                password: true,
                                accessibilityId: "")
                    ])
                ]

                beforeEach {
                    self.subject.bind(itemDetail: Driver.just(sectionModelWithJustPassword))
                }

                it("returns the selected state of the password reveal button") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell
                    cell.revealButton.sendActions(for: .touchUpInside)

                    expect(self.presenter.onPasswordToggleActionDispatched).notTo(beNil())
                    expect(self.presenter.onPasswordToggleActionDispatched).to(equal(cell.revealButton.isSelected))
                }
            }

            describe("ItemDetailCell") {
                let sectionModelWithJustPassword = [
                    ItemDetailSectionModel(model: 1, items: [
                        ItemDetailCellConfiguration(
                                title: Constant.string.password,
                                value: "••••••••••",
                                accessibilityLabel: "something accessible",
                                password: true,
                                accessibilityId: "")
                    ])
                ]

                beforeEach {
                    self.subject.bind(itemDetail: Driver.just(sectionModelWithJustPassword))
                }

                it("prepareForReuse disposes the cell's dispose bag") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell

                    let disposeBag = cell.disposeBag

                    cell.prepareForReuse()

                    expect(cell.disposeBag === disposeBag).notTo(beTrue())
                }
            }

            describe("ItemDetailCell") {
                let sectionModel = [
                    ItemDetailSectionModel(model: 1, items: [
                        ItemDetailCellConfiguration(
                                title: Constant.string.password,
                                value: "••••••••••",
                                accessibilityLabel: "something accessible",
                                password: true,
                                accessibilityId: "")
                    ])
                ]

                beforeEach {
                    self.subject.bind(itemDetail: Driver.just(sectionModel))
                }

                it("highlighting the cell changes the background color") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell

                    cell.setHighlighted(true, animated: false)
                    expect(cell.backgroundColor).to(equal(Constant.color.tableViewCellHighlighted))

                    cell.setHighlighted(false, animated: false)
                    expect(cell.backgroundColor).to(equal(UIColor.white))
                }
            }
        }

        describe("ItemDetailViewCellConfiguration") {
            describe("IdentifiableType") {
                let title = "meow"
                let cellConfig = ItemDetailCellConfiguration(title: title, value: "cats", accessibilityLabel: "something accessible", password: false, accessibilityId: "")

                it("uses the title as the identity string") {
                    expect(cellConfig.identity).to(equal(title))
                }
            }

            describe("equality") {
                it("uses the value to determine equality") {
                    expect(ItemDetailCellConfiguration(
                            title: "meow",
                            value: "cats",
                            accessibilityLabel: "something accessible",
                            password: false,
                            accessibilityId: "")
                    ).to(equal(ItemDetailCellConfiguration(
                            title: "meow",
                            value: "cats",
                            accessibilityLabel: "something accessible",
                            password: false,
                            accessibilityId: "")
                    ))

                    expect(ItemDetailCellConfiguration(
                            title: "woof",
                            value: "cats",
                            accessibilityLabel: "something accessible",
                            password: false,
                            accessibilityId: "")
                    ).to(equal(ItemDetailCellConfiguration(
                            title: "meow",
                            value: "cats",
                            accessibilityLabel: "something accessible",
                            password: false,
                            accessibilityId: "")
                    ))

                    expect(ItemDetailCellConfiguration(
                            title: "meow",
                            value: "dogs",
                            accessibilityLabel: "something accessible",
                            password: false,
                            accessibilityId: "")
                    ).notTo(equal(ItemDetailCellConfiguration(
                            title: "meow",
                            value: "cats",
                            accessibilityLabel: "something accessible",
                            password: false,
                            accessibilityId: "")
                    ))
                }
            }
        }
    }
}
