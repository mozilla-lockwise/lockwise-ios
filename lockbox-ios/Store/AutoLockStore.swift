/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class AutoLockStore {
    static let shared = AutoLockStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let dataStore: DataStore
    private let dataStoreActionHandler: DataStoreActionHandler
    private let userDefaults: UserDefaults

    var timer: Timer?
    var paused: Bool = false

    init(dispatcher: Dispatcher = Dispatcher.shared,
         dataStore: DataStore = DataStore.shared,
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared,
         userDefaults: UserDefaults = UserDefaults.standard
    ) {
        self.dispatcher = dispatcher
        self.userDefaults = userDefaults
        self.dataStore = dataStore
        self.dataStoreActionHandler = dataStoreActionHandler

        self.dataStore.locked
                .subscribe(onNext: { [weak self] locked in
                    if locked {
                        self?.stopTimer()
                    } else {
                        self?.setupTimer()
                    }
                })
                .disposed(by: self.disposeBag)

        self.dispatcher.register
                .filter { action -> Bool in
                    // future user interaction actions will need to get added to this list
                    action is MainRouteAction ||
                            action is SettingRouteAction ||
                            action is CopyConfirmationDisplayAction ||
                            action is ExternalLinkAction ||
                            action is ItemListDisplayAction ||
                            action is ItemDetailDisplayAction ||
                            action is SettingAction
                }
                .subscribe(onNext: { [weak self] _ in
                    self?.resetTimer()
                })
                .disposed(by: self.disposeBag)

        self.dispatcher.register
            .filterByType(class: ExternalWebsiteRouteAction.self)
            .subscribe(onNext: { [weak self] _ in
                self?.pauseTimer()
            })
            .disposed(by: self.disposeBag)
    }
}

extension AutoLockStore {
    private func resetTimer() {
        self.stopTimer(reset: !paused)
        self.setupTimer()
    }

    private func setupTimer() {
        self.userDefaults.onAutoLockTime
                .take(1)
                .subscribe(onNext: { (latest: AutoLockSetting) in
                    switch latest {
                    case .OneMinute:
                        self.setTimer(seconds: 60)
                    case .FiveMinutes:
                        self.setTimer(seconds: 60 * 5)
                    case .FifteenMinutes:
                        self.setTimer(seconds: 60 * 15)
                    case .ThirtyMinutes:
                        self.setTimer(seconds: 60 * 30)
                    case .OneHour:
                        self.setTimer(seconds: 60 * 60)
                    case .TwelveHours:
                        self.setTimer(seconds: 60 * 60 * 12)
                    case .TwentyFourHours:
                        self.setTimer(seconds: 60 * 60 * 24)
                    case .Never:
                        self.stopTimer()
                    }
                    return
                })
                .disposed(by: self.disposeBag)
    }

    private func setTimer(seconds: Int) {
        let timerValue = self.userDefaults.double(forKey: SettingKey.autoLockTimerDate.rawValue)
        if timerValue != 0 && timerValue < Date().timeIntervalSince1970 {
            self.timer = Timer(fireAt: Date(timeIntervalSince1970: timerValue),
                    interval: 0,
                    target: self,
                    selector: #selector(lockApp),
                    userInfo: nil,
                    repeats: false)
        } else {
            self.timer = Timer(timeInterval: TimeInterval(seconds),
                    target: self,
                    selector: #selector(lockApp),
                    userInfo: nil,
                    repeats: false)

            self.userDefaults.set(self.timer?.fireDate.timeIntervalSince1970,
                    forKey: SettingKey.autoLockTimerDate.rawValue)
        }

        paused = false

        if let timer = self.timer {
            DispatchQueue.main.async {
                RunLoop.current.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
            }
        }
    }

    private func pauseTimer() {
        paused = true
        self.stopTimer(reset: !paused)
    }

    private func stopTimer(reset: Bool = true) {
        if let timer = self.timer {
            timer.invalidate()
        }
        if reset {
            self.userDefaults.removeObject(forKey: SettingKey.autoLockTimerDate.rawValue)
        }
    }

    @objc private func lockApp() {
        self.dataStoreActionHandler.invoke(.lock)
        self.userDefaults.removeObject(forKey: SettingKey.autoLockTimerDate.rawValue)
    }
}
