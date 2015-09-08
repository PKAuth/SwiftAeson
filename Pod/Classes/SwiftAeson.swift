//
//  SwiftAeson.swift
//  Pods
//
//  Created by James Parker on 8/27/15.
//  Copyright (c) 2015 PKAuth, LLC. All rights reserved.
//
//

import Foundation

// Mimics Haskell's Aeson library.
class Aeson {
    static func encode<T where T : ToJSON>( o : T) -> NSData? {
        let encoded = o.toJSON()
        
        let jsonObject : AnyObject = encodeHelper( encoded)
        
        if NSJSONSerialization.isValidJSONObject( jsonObject) {
            return try? NSJSONSerialization.dataWithJSONObject( jsonObject, options: [])
        }
        
        return nil
    }
    
    static func decode<T: FromJSON>( data : NSData) -> T? {
        if let json : AnyObject = try? NSJSONSerialization.JSONObjectWithData( data, options: []) {
            if let val = Aeson.decodeHelper( json) {
                return T.fromJSON(val)
            }
            else {
                return nil
            }
        }
        
        return nil
    }
    
    // Can't make nested recursive functions so...
    // Note: CPS to make tail recursive??
    private static func encodeHelper( value : JValue) -> AnyObject {
        switch value {
        case .JObject( let dict):
            var res : [String : AnyObject] = Dictionary( minimumCapacity: dict.count)
            for (key, value) in dict {
                res[key] = encodeHelper( value)
            }
            return res
        case .JArray( let arr):
            return arr.map( encodeHelper)
        case .JString( let str):
            return str
        case .JNumber( let num):
            return num
        case .JBool( let bool):
            return bool
        case .JNull:
            return NSNull()
        }
    }
    
    private static func decodeHelper( json : AnyObject) -> JValue? {
        // Hide all the reflection...
        if let dict = json as? NSDictionary {
            var res : [String : JValue] = Dictionary( minimumCapacity: dict.count)
            for (keyA, valueA) in dict {
                if let key = keyA as? String {
                    if let val = Aeson.decodeHelper( valueA) {
                        res[key] = val
                    }
                    else {
                        return nil
                    }
                }
                else {
                    return nil
                }
            }
            
            return JValue.JObject( res)
        }
        if let arr = json as? NSArray {
            var res : [JValue] = []
            res.reserveCapacity( arr.count)
            
            for e in arr {
                if let val = Aeson.decodeHelper( e) {
                    res.append( val)
                }
                else {
                    return nil
                }
            }
            
            return JValue.JArray( res)
        }
        if let str = json as? String {
            return JValue.JString( str)
        }
        if let num = json as? Double {
            return JValue.JNumber( num)
        }
        if let bool = json as? Bool {
            return JValue.JBool( bool)
        }
        if let _ = json as? NSNull {
            return JValue.JNull
        }
        
        return nil
    }
    
    static func pair<T : ToJSON>( key : String, value : T) -> (String, JValue) {
        return ( key, value.toJSON())
    }
    
    static func object( pairs : [(String, JValue)]) -> JValue {
        var r = [String : JValue](minimumCapacity: pairs.count)
        let _ = pairs.map({(key, value) in r[key] = value})
        return JValue.JObject( r)
    }
    
    static func lookup<T : FromJSON>( object : Dictionary<String, JValue>, key : String) -> T? {
        // return object[key] >>= { return T.fromJSON( $0)}
        if let val = object[key] {
            return T.fromJSON( val)
        }
        
        return nil
    }
    
    // Hack until Swift can support this as an extension. Limits expressibility.
    static func dictionaryToJSON<K : ToJSON,V : ToJSON> ( dictionary : Dictionary<K,V>) -> JValue {
        var res : [JValue] = []
        res.reserveCapacity( dictionary.count)
        
        let _ = dictionary.map( { (key : K, value : V) -> JValue in
            let k = "key" %= key
            let v = "value" %= value
            return Aeson.object( [ k, v])
        })
        
        return JValue.JArray( res)
        
    }
    
    // Hack until Swift can support this as an extension. Limits expressibility.
    static func dictionaryFromJSON<K : FromJSON, V : FromJSON> ( value : JValue) -> Dictionary<K,V>? {
        switch value {
        case JValue.JArray( let arr):
            var res : [ K : V] = Dictionary( minimumCapacity: arr.count)
            return arr.reduce( Optional.Some(res), combine: { ( acc, value) -> [ K : V]? in
                if acc == nil {
                    return Optional.None
                }
                
                switch value {
                case JValue.JObject( let o):
                    if let key : K = o %! "key" {
                        if let val : V = (o %! "value") {
                            res[key] = val
                            return res
                        }
                    }
                    
                    return nil
                default:
                    return nil
                }
            })
        default:
            return nil
        }
    }
    
    
    // Hack until Swift can support this as an extension. Limits expressibility.
    static func arrayToJSON<E : ToJSON>( arr : Array<E>) -> JValue {
        var res : [JValue] = []
        res.reserveCapacity( arr.count)
        let _ = arr.map({(e : E) in
            res.append( e.toJSON())
            ()
        })
        return JValue.JArray( res)
    }
    
    // Hack until Swift can support this as an extension. Limits expressibility.
    static func arrayFromJSON<E : FromJSON>( value : JValue) -> Array<E>? {
        switch value {
        case JValue.JArray( let arr):
            var res : [E] = []
            res.reserveCapacity( arr.count)
            
            let _ = arr.reduce( Optional.Some( res), combine: { ( acc, val) in
                if acc == nil {
                    return nil
                }
                
                if let e = E.fromJSON( val) {
                    res.append( e)
                    return res
                }
                
                return nil
            })
            
            return res
            
        default:
            return nil
        }
    }
}

infix operator %= { associativity left }
func %= <T : ToJSON>( key : String, value : T) -> (String, JValue) {
    return Aeson.pair( key, value: value)
}

infix operator %! { associativity left }
func %! <T : FromJSON>( object : Dictionary<String, JValue>, key : String) -> T? {
    return Aeson.lookup( object, key: key)
}


// JSON representation.
enum JValue {
    case JObject( Dictionary<String,JValue>)
    case JArray( Array<JValue>)
    case JString( String)
    case JNumber( Double)
    case JBool( Bool)
    case JNull
}

protocol ToJSON {
    func toJSON () -> JValue
}

protocol FromJSON {
    static func fromJSON (_: JValue) -> Self?
}

// Some protocol instances.

extension UInt : ToJSON, FromJSON {
    func toJSON() -> JValue {
        return JValue.JNumber( Double( self))
    }
    static func fromJSON( value: JValue) -> UInt? {
        switch value {
        case .JNumber( let doub):
            return UInt( doub)
        default:
            return Optional.None
        }
    }
}

extension Int : ToJSON, FromJSON {
    func toJSON() -> JValue {
        return JValue.JNumber( Double( self))
    }
    static func fromJSON( value: JValue) -> Int? {
        switch value {
        case .JNumber( let doub):
            return Int( doub)
        default:
            return Optional.None
        }
    }
}

extension Double : ToJSON, FromJSON {
    func toJSON() -> JValue {
        return JValue.JNumber( self)
    }
    static func fromJSON( value: JValue) -> Double? {
        switch value {
        case JValue.JNumber( let num):
            return num
        default:
            return nil
        }
    }
}

extension Float : ToJSON, FromJSON {
    func toJSON() -> JValue {
        return JValue.JNumber( Double( self))
    }
    static func fromJSON( value: JValue) -> Float? {
        switch value {
        case JValue.JNumber( let num):
            return Float( num)
        default:
            return nil
        }
    }
}

extension String : ToJSON, FromJSON {
    func toJSON() -> JValue {
        return JValue.JString( self)
    }
    static func fromJSON( value: JValue) -> String? {
        switch value {
        case JValue.JString( let str):
            return str
        default:
            return nil
        }
    }
}

extension Bool : ToJSON, FromJSON {
    func toJSON() -> JValue {
        return JValue.JBool( self)
    }
    
    static func fromJSON( value: JValue) -> Bool? {
        switch value {
        case JValue.JBool( let b):
            return b
            // ... Why?
        case JValue.JNumber( 0):
            return false
        case JValue.JNumber( 1):
            return true
        default:
            return nil
        }
    }
}

extension NSNull : ToJSON, FromJSON {
    func toJSON() -> JValue {
        return JValue.JNull
    }
    
    static func fromJSON( value: JValue) -> Self? {
        switch value {
        case JValue.JNull:
            return self.init() // What??
        default:
            return nil
        }
    }
}

/*
TODO: Waiting for this: https://forums.developer.apple.com/thread/7172
// extension Dictionary : ToJSON where Key : ToJSON, Value : ToJSON {
extension Dictionary where Key : ToJSON, Value : ToJSON {
func toJSON() -> JValue {
var res : [JValue] = []
res.reserveCapacity( self.count)

let _ = self.map( { (key : Key, value : Value) -> JValue in
let k = "key" %= key
let v = "value" %= value
return Aeson.object( [ k, v])
// key.toJSON()
// res.append( key.)
// return JValue.JNull
})

return JValue.JArray( res)
}
}extension Dictionary : ToJSON {

}

extension Array : ToJSON where Element : ToJSON {
func toJSON () -> JValue {
return JValue.JArray( self.map({$0.toJSON()}))
}
}
*/

extension NSDate : ToJSON, FromJSON {
    func toJSON() -> JValue {
        let formatter = NSDateFormatter()
        formatter.dateFromString( "yyyy-MM-dd'T'HH:mm:ss.SSSZZZ")
        
        let date = formatter.stringFromDate( self)
        return JValue.JString( date)
    }
    
    static func fromJSON( value : JValue) -> Self? {
        switch value {
        case JValue.JString( let str):
            let formatter = NSDateFormatter()
            formatter.dateFromString( "yyyy-MM-dd'T'HH:mm:ss.SSSZZZ")
            if let date = formatter.dateFromString( str) {
                return self.init( timeInterval: 0, sinceDate: date)
            }
            
            formatter.dateFromString( "yyyy-MM-dd")
            if let date = formatter.dateFromString( str) {
                return self.init( timeInterval: 0, sinceDate: date)
            }
            
            // TODO: This probably needs to be improved.
            
            return nil
            
        default:
            return nil
        }
    }
}
