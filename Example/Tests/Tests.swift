// https://github.com/Quick/Quick

import Quick
import Nimble
import SwiftAeson

class TableOfContentsSpec: QuickSpec {
    override func spec() {
        describe( "Basic JSON serialization test") {
            let original = Test()
            let serialized = Aeson.encode( original)
            let encoded = NSString(data: serialized!, encoding: NSUTF8StringEncoding)
            // print(encoded!)
        
            let deserialized : Test? = Aeson.decode( serialized!)
            // print(deserialized!)
        
            it ( "Deserialized test JSON matches original") {
                expect( original) == deserialized!
            }
        }
        
        /*
        describe("these will fail") {

            it("can do maths") {
                expect(1) == 2
            }

            it("can read") {
                expect("number") == "string"
            }

            it("will eventually fail") {
                expect("time").toEventually( equal("done") )
            }
            
            context("these will pass") {

                it("can do maths") {
                    expect(23) == 23
                }

                it("can read") {
                    expect("🐮") == "🐮"
                }

                it("will eventually pass") {
                    var time = "passing"

                    dispatch_async(dispatch_get_main_queue()) {
                        time = "done"
                    }

                    waitUntil { done in
                        NSThread.sleepForTimeInterval(0.5)
                        expect(time) == "done"

                        done()
                    }
                }
            }
        }
        */
    }
}

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
