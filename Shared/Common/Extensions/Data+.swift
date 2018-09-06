/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

extension Data {
    func base64URLEncodedString() -> String {
        let encodedString = self.base64EncodedString()

        return encodedString
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
    }

    static func loadImageData(_ url: URL) -> Observable<Data?> {
        return Observable<Data?>.create { observer in
            DispatchQueue.main.async {

                var imageData: Data?
                do {
                    imageData = try Data(contentsOf: url)
                } catch {
                    observer.onError(error)
                }

                observer.onNext(imageData)
            }

            return Disposables.create()
        }
    }
}
