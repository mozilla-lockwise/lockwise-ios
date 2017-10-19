import Foundation

class ItemFromJSONParser : NSObject {
    static func itemFromDictionary(_ dictionary:[String:Any]) -> Item {
        do {
            let json = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        } catch {
            print("nope!")
        }
    }
    
    private static func checkValue(_ value:String, dictionary:[String:Any]) -> Any? {
        if let val = dictionary[value]{
            return val
        } else {
            return nil
        }
    }
}
