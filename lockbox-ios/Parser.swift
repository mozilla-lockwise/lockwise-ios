import Foundation

class Parser : NSObject {
    
    enum ParserError : Error {
        case InvalidDictionary, InvalidItem
    }
    
    private static var itemProperties:[String] {
        get {
            return Mirror(reflecting: Item.Builder().build()).children.flatMap { $0.label }
        }
    }
    
    static func itemFromDictionary(_ dictionary:[String:Any]) -> Item {
        let sanitizedDictionary = dictionary.filter { pair -> Bool in
            return Parser.itemProperties.contains(pair.key)
        }
        
        do {
            let json = try JSONSerialization.data(withJSONObject: sanitizedDictionary, options: [])
            
            let item = try JSONDecoder().decode(Item.self, from: json)
            
            return item
        } catch {
            print("bad dictionary")
//            throw ParserError.InvalidDictionary
        }
        
        return Item.ItemNotFound()
    }
    
    static func jsonStringFromItem(_ item:Item) -> String {
        let jsonEncoder = JSONEncoder()
        
        do {
            let jsonData = try jsonEncoder.encode(item)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString!
        } catch {
            print("bad item")
//            throw ParserError.InvalidItem
        }
        
        return ""
    }
}
