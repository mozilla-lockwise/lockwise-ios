/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class RouteStore {
    public static let shared = RouteStore()

    fileprivate let disposeBag = DisposeBag()
    fileprivate var routeState = ReplaySubject<RouteAction>.create(bufferSize: 1)
    fileprivate var onboardingState = BehaviorRelay<Bool>(value: false)

    public var onRoute: Observable<RouteAction> {
        return self.routeState.asObservable()
    }

    public var onboarding: Observable<Bool> {
        return self.onboardingState.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        dispatcher.register
                .filterByType(class: RouteAction.self)
                .bind(to: self.routeState)
                .disposed(by: self.disposeBag)

        dispatcher.register
                .filterByType(class: OnboardingStatusAction.self)
                .map { $0.onboardingInProgress }
                .bind(to: self.onboardingState)
                .disposed(by: self.disposeBag)
    }
}
