//
//  FeatureFlags.swift
//  Lockbox
//
//  Created by Kayla Galway on 11/8/19.
//  Copyright © 2019 Mozilla. All rights reserved.
//

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
        return FeatureFlagSupport.isDebug ? true : false
    }
    
}
