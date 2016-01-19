//
//  ItemDetail.swift
//  Knot
//
//  Created by Nathan Mueller on 11/15/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import UIKit
import CoreLocation

class ItemDetail: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!


    @IBOutlet weak var addressLabel: UILabel!

    @IBOutlet weak var payButton: UIButton!
    
    var picView: UIImageView!
    var pic : UIImage = UIImage()
    var name : String = "Text"
    var price : String = "Text"
    var time: String = "Time"
    var IDNum: String = ""
    var itemSeller: String = ""
    var location: String = ""
    
    //timer variables
    var secondsUntil: Int = 1000
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var cognitoID = ""
        appDelegate.credentialsProvider.getIdentityId().continueWithBlock { (task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                print("Error: " + task.error!.localizedDescription)
            }
            else {
                // the task result will contain the identity id
                cognitoID = task.result as! String
            }
            return nil
        }
        
        if itemSeller != cognitoID {
            payButton.hidden = true
        }
        
        self.updateLocation()
        
        picView = UIImageView(frame:CGRectMake(0, 60, 380, 380))
        
        nameLabel.text = name
        priceLabel.text = "$" + price
        picView.image = pic
        
        //set up countdown and timer stuff
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let overDate = dateFormatter.dateFromString(time)!
        let currentDate = NSDate()

        secondsUntil = secondsFrom(currentDate, endDate: overDate)
        
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
        
        self.view.addSubview(picView)
        self.view.sendSubviewToBack(picView)
        
    }
    
    func update() {
        
        if(secondsUntil > 0)
        {
            timeLabel.text = printSecondsToDaysHoursMinutesSeconds(secondsUntil--)
        }
        else {
            updateSoldStatus()
            timeLabel.text = "SOLD"
        }
        
    }
    
    func secondsToDaysHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int, Int) {
        return (seconds / 86400, (seconds % 86400) / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func printSecondsToDaysHoursMinutesSeconds (seconds:Int) -> String {
        let (d, h, m, s) = secondsToDaysHoursMinutesSeconds (seconds)
        if m < 10 {
            if s < 10 {
                return "\(d) Days, \(h):0\(m):0\(s) left"
            }
            return "\(d) Days, \(h):0\(m):\(s) left"
        }
        if s < 10 {
            return "\(d) Days, \(h):\(m):0\(s) left"
        }
        return "\(d) Days, \(h):\(m):\(s) left"
    }
    
    func secondsFrom(startDate:NSDate, endDate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: startDate, toDate: endDate, options: []).second
    }

    func updateLocation()
    {
        let coordinatesArr = self.location.characters.split{$0 == " "}.map(String.init)
        let latitude = Double(coordinatesArr[0])
        let longitude = Double(coordinatesArr[1])
        print(latitude)
        print(longitude)
        var address = ""
        var streetHolder = ""
        var cityHolder = ""
        
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude!, longitude: longitude!)
        geoCoder.reverseGeocodeLocation(location)
            {
                (placemarks, error) -> Void in
                
                let placeArray = placemarks as [CLPlacemark]!
                
                // Place details
                var placeMark: CLPlacemark!
                placeMark = placeArray?[0]
                
                // Address dictionary
                print(placeMark.addressDictionary)
                
                // Street address
                if let street = placeMark.addressDictionary?["Thoroughfare"] as? NSString
                {
                    print(street)
                    streetHolder = street as String
                }
                // City
                if let city = placeMark.addressDictionary?["City"] as? NSString
                {
                    print(city)
                    
                    cityHolder = (city as String)
                }
                address = streetHolder + ", " + cityHolder
                self.addressLabel.text = address
        }
    }
    
    func updateSoldStatus() {
        var hashValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        hashValue.S = self.IDNum
        var otherValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        otherValue.S = self.time
        var updatedValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        updatedValue.S = "true"
        
        var updateInput: AWSDynamoDBUpdateItemInput = AWSDynamoDBUpdateItemInput()
        updateInput.tableName = "knot-listings"
        updateInput.key = ["ID": hashValue, "time": otherValue]
        var valueUpdate: AWSDynamoDBAttributeValueUpdate = AWSDynamoDBAttributeValueUpdate()
        valueUpdate.value = updatedValue
        valueUpdate.action = AWSDynamoDBAttributeAction.Put
        updateInput.attributeUpdates = ["sold": valueUpdate]
        updateInput.returnValues = AWSDynamoDBReturnValue.UpdatedNew
        
        AWSDynamoDB.defaultDynamoDB().updateItem(updateInput).waitUntilFinished()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if (segue!.identifier == "paySegue") {
            let viewController:QrView = segue!.destinationViewController as! QrView
            viewController.price = price
            viewController.ID = IDNum
            viewController.time = time
        }
        
    }
    
}