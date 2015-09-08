# SwiftAeson

[![CI Status](http://img.shields.io/travis/James Parker/SwiftAeson.svg?style=flat)](https://travis-ci.org/James Parker/SwiftAeson)
[![Version](https://img.shields.io/cocoapods/v/SwiftAeson.svg?style=flat)](http://cocoapods.org/pods/SwiftAeson)
[![License](https://img.shields.io/cocoapods/l/SwiftAeson.svg?style=flat)](http://cocoapods.org/pods/SwiftAeson)
[![Platform](https://img.shields.io/cocoapods/p/SwiftAeson.svg?style=flat)](http://cocoapods.org/pods/SwiftAeson)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

To utilize SwiftAeson in your projects, you need to implement the protocols `ToJSON` and `FromJSON` for whichever types you want to serialize and deserialize with JSON. 
Here is an example. First we define a class `Test`:

```swift
class Test : Equatable {
    var test : String = "test"
    var booltest : Bool = false
    var booltest2 : Bool = true
    var nul : NSNull = NSNull()
    var doub : Double = 32.0
    
    init() {
        
    }
    
    required init ( test: String, booltest : Bool, booltest2 : Bool, nul : NSNull, doub : Double) {
        self.test = test
        self.booltest = booltest
        self.booltest2 = booltest2
        self.nul = nul
        self.doub = doub
    }
}

func ==( a : Test, b : Test) -> Bool {
    return a.test == b.test
        && a.booltest == b.booltest
        && a.booltest2 == b.booltest2
        && a.nul == b.nul
        && a.doub == b.doub
}
```

Now we implement `ToJSON` and `FromJSON`. 
This is shown for a class, but it works for structs and enums as well.

```swift
extension Test : ToJSON, FromJSON {
    func toJSON() -> JValue {
        let test = "test" %= self.test
        let booltest = "booltest" %= self.booltest
        let booltest2 = "booltest2" %= self.booltest2
        let nul = "null" %= self.nul
        let doub = "double" %= self.doub
        
        return Aeson.object( [ test, booltest, booltest2, nul, doub])
    }
    
    static func fromJSON( value: JValue) -> Self? {
        switch value {
        case .JObject( let o):
            if let test : String = o %! "test" {
                if let booltest : Bool = o %! "booltest" {
                    if let booltest2 : Bool = o %! "booltest2" {
                        if let nul : NSNull = o %! "null" {
                            if let doub : Double = o %! "double" {
                                return self.init(test: test, booltest: booltest, booltest2: booltest2, nul: nul, doub: doub)
                            }
                        }
                    }
                }
            }
            
            return nil
        default:
            return nil
        }
    }
}
```

Here we show how to serialize and deserialize our test class. 
Then we compare them to test that the original and deserialized versions are equal. 

```swift
let original = Test()
let serialized = Aeson.encode( original)
let encoded = NSString(data: serialized!, encoding: NSUTF8StringEncoding)
print(encoded!)

let deserialized : Test? = Aeson.decode( serialized!)// Aeson.decode( test!)
print(deserialized!)

original == deserialized!
```

## Requirements

## Installation

SwiftAeson is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftAeson"
```

## Author

James Parker, jp@pkauth.com

## License

SwiftAeson is available under the MIT license. See the LICENSE file for more info.
