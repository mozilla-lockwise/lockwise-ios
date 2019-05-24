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

        override var onRightSwipe: AnyObserver<Void> {
            return Binder(self) { target, _ in
                target.onCancelActionDispatched = true
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

            describe("tableview datasource configuration") {
                let textFieldEnabledStub = PublishSubject<Bool>()
                var revealPasswordObserver = self.scheduler.createObserver(Bool.self)

                beforeEach {
                    revealPasswordObserver = self.scheduler.createObserver(Bool.self)
                    let sectionModels = [
                        ItemDetailSectionModel(model: 0, items: [
                            ItemDetailCellConfiguration(
                                    title: Constant.string.webAddress,
                                    value: Driver.just("www.meow.com"),
                                    accessibilityLabel: "something accessible",
                                    valueFontColor: Constant.color.lockBoxViolet,
                                    accessibilityId: "",
                                    textFieldEnabled: textFieldEnabledStub.asDriver(onErrorJustReturn: false))
                            ]),
                        ItemDetailSectionModel(model: 1, items: [
                            ItemDetailCellConfiguration(
                                    title: Constant.string.username,
                                    value: Driver.just("tanya"),
                                    accessibilityLabel: "something else accessible",
                                    accessibilityId: "",
                                    textFieldEnabled: textFieldEnabledStub.asDriver(onErrorJustReturn: false)),
                            ItemDetailCellConfiguration(
                                    title: Constant.string.password,
                                    value: Driver.just("iluvdawgz"),
                                    accessibilityLabel: "more accessible here",
                                    valueFontColor: .black,
                                    accessibilityId: "",
                                    textFieldEnabled: textFieldEnabledStub.asDriver(onErrorJustReturn: false),
                                    revealPasswordObserver: revealPasswordObserver.asObserver())
                            ])
                    ]

                    Driver.just(sectionModels)
                            .drive(self.subject!.itemDetailObserver)
                            .disposed(by: self.disposeBag)
                }

                it("configures the tableview based on the models provided") {
                    expect(self.subject.tableView.numberOfSections).to(equal(2))
                }

                it("binds password reveal tap actions to the appropriate presenter listener") {
                    let cell = self.subject.tableView.cellForRow(at: [1, 1]) as! ItemDetailCell
                    cell.revealButton.sendActions(for: .touchUpInside)

                    expect(revealPasswordObserver.events.count).to(equal(1))
                    expect(revealPasswordObserver.events.first?.value.element).to(beTrue())
                }

                describe("tapping cells") {
                    var cellTapObserver = self.scheduler.createObserver(String?.self)

                    beforeEach {
                        cellTapObserver = self.scheduler.createObserver(String?.self)
                        self.subject.cellTapped
                                .subscribe(cellTapObserver)
                                .disposed(by: self.disposeBag)

                        self.subject.tableView.delegate!.tableView!(self.subject.tableView, didSelectRowAt: [1, 0])
                    }

                    it("extracts the titlelabel text and tells the presenter") {
                        expect(cellTapObserver.events.count).to(equal(1))
                        expect(cellTapObserver.events.first!.value.element).to(equal(Constant.string.username))
                    }
                }

                it("sets the font color for web address") {
                    expect((self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell).textValue.textColor).to(equal(Constant.color.lockBoxViolet))
                }

                it("sets the passed accessibility label for every cell") {
                    expect(self.subject.tableView.cellForRow(at: [0, 0])?.accessibilityLabel).to(equal("something accessible"))
                }
            }

            describe("title text") {
                let title = "new title"

                beforeEach {
                    Observable.just(title)
                            .subscribe(self.subject.titleText)
                            .disposed(by: self.disposeBag)
                }

                it("updates the navigation title with new values") {
                    expect(self.subject.navigationItem.title).to(equal(title))
                }
            }

            describe("tapping left button with text set") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)

                    self.subject.leftButtonText.onNext("Cancel")

                    self.subject.leftBarButtonTapped
                            .bind(to: voidObserver)
                            .disposed(by: self.disposeBag)

                    let button = self.subject.navigationItem.leftBarButtonItem!.customView as! UIButton
                    _ = button.sendActions(for: .touchUpInside)
                }

                it("informs the observer") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }

            describe("tapping right button with text set") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)

                    self.subject.rightButtonText.onNext("Edit")

                    self.subject.rightBarButtonTapped
                            .bind(to: voidObserver)
                            .disposed(by: self.disposeBag)

                    let editButton = self.subject.navigationItem.rightBarButtonItem!.customView as! UIButton
                    editButton.sendActions(for: .touchUpInside)
                }

                it("informs any observers") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }

            describe("ItemDetailCell") {
                var textFieldEnabledStub = PublishSubject<Bool>()

                beforeEach {
                    let sectionModelWithJustOneItem = [
                        ItemDetailSectionModel(model: 1, items: [
                            ItemDetailCellConfiguration(
                                    title: Constant.string.password,
                                    value: Driver.just("••••••••••"),
                                    accessibilityLabel: "something accessible",
                                    accessibilityId: "",
                                    textFieldEnabled: textFieldEnabledStub.asDriver(onErrorJustReturn: false))
                        ])
                    ]

                    Driver.just(sectionModelWithJustOneItem)
                            .drive(self.subject!.itemDetailObserver)
                            .disposed(by: self.disposeBag)
                }

                it("prepareForReuse disposes the cell's dispose bag") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell

                    let disposeBag = cell.disposeBag

                    cell.prepareForReuse()

                    expect(cell.disposeBag === disposeBag).notTo(beTrue())
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
    }
}
