/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol ItemParser {
    static func itemFromDictionary(_ dictionary:[String:Any]) throws -> Item
    static func jsonStringFromItem(_ item:Item) -> String
}

enum ParserError : Error {
    case InvalidDictionary, InvalidItem
}

class Parser : NSObject {
    
    private static var itemProperties:[String] {
        get {
            return Mirror(reflecting: Item.Builder().build()).children.flatMap { $0.label }
        }
    }
    
    static func itemFromDictionary(_ dictionary:[String:Any]) throws -> Item {
        let sanitizedDictionary = dictionary.filter { pair -> Bool in
            return Parser.itemProperties.contains(pair.key)
        }
        
        do {
            let json = try JSONSerialization.data(withJSONObject: sanitizedDictionary, options: [])
            
            let item = try JSONDecoder().decode(Item.self, from: json)
            
            return item
        } catch {
            throw ParserError.InvalidDictionary
        }
    }
    
    static func jsonStringFromItem(_ item:Item) throws -> String {
        let jsonEncoder = JSONEncoder()
        
        do {
            let jsonData = try jsonEncoder.encode(item)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString!
        } catch {
            throw ParserError.InvalidItem
        }
    }
}
