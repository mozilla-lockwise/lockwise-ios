//
//  FeatureFlags.swift
//  Lockbox
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Helper struct that checks if Build Configuration is Release or Debug
struct FeatureFlagSupport {
    static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    static var isRelease: Bool {
        #if RELEASE
            return true
        #else
            return false
        #endif
    }
}

/// Boolean flags that identify if test feature should be shown depending on whether the Build Configuration is Release or Debug
struct FeatureFlags {
    /// Feature flag for the ability to edit a credential
    static var crudEdit: Bool {
        if FeatureFlagSupport.isDebug {
            return true
        } else if FeatureFlagSupport.isRelease {
            return false
        } else {
            return false
        }
    }
}
