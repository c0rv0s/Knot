//
//  listing.swift
//  Knot
//
//  Created by Nathan Mueller on 12/18/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import Foundation

class Item : AWSDynamoDBModel, AWSDynamoDBModeling {
    
    var name  : String = ""
    var ID   : String = ""
    var price   : String = ""
    var location : String = ""
    var time : String = ""
    
    override init!() { super.init() }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func dynamoDBTableName() -> String! {
        return "knot-listings"
    }
    class func hashKeyAttribute() -> String! {
        return "time"
    }
    
    /*
    //required to let DynamoDB Mapper create instances of this class
    override init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: NSErrorPointer) {
        super.init(dictionary: dictionaryValue, error: error)
    }
*/
    
    //workaround to possible XCode 6.1 Bug : "Type NotificationAck" does not conform to protocol "NSObjectProtocol"
    override func isEqual(anObject: AnyObject?) -> Bool {
        return super.isEqual(anObject)
    } }