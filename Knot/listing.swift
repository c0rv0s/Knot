//
//  listing.swift
//  Knot
//
//  Created by Nathan Mueller on 12/18/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import Foundation

class ListItem : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var name  : String = ""
    var ID   : String = ""
    var price   : String = ""
    var location : String = ""
    var time : String = ""
    var sold : Int = 0
    
    /*
    override init!() { super.init() }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    */
    class func dynamoDBTableName() -> String! {
        return "knot-listings"
    }
    class func hashKeyAttribute() -> String! {
        return "time"
    }
    
    class func rangeKeyAttribute() -> String! {
        return "date"
    }
    /*
    //required to let DynamoDB Mapper create instances of this class
    init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: NSErrorPointer) {
        super.init(dictionary: dictionaryValue, error: error)
    }
*/
    override func isEqual(object: AnyObject?) -> Bool { return super.isEqual(object) }
    override func `self`() -> Self { return self }
}