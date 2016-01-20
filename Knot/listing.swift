//
//  listing.swift
//  Knot
//
//  Created by Nathan Mueller on 12/18/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import Foundation

class ListItem : AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var ID   : String = "placeholder"
    var name  : String = "placeholder"
    var price   : String = "placeholder"
    var location : String = "placeholder"
    var time : String = "placeholder"
    var sold : String = "false"
    var seller : String = "placehoder"
    var buyer : String = "None"
    var sellerFBID : String = "placeholder"
    var descriptionKnot : String = "placeholder"
    var condition : String = "placeholder"
    var category : String = "placeholder"
    var international : Bool = false
    var numberOfPics : Int = 1
    
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
        return "ID"
    }
    
    class func rangeKeyAttribute() -> String! {
        return "time"
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