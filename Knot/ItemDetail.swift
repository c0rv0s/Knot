//
//  ItemDetail.swift
//  Knot
//
//  Created by Nathan Mueller on 11/15/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import MessageUI

class ItemDetail: UIViewController, UITextViewDelegate, MFMailComposeViewControllerDelegate, UIScrollViewDelegate {
    
    
    @IBOutlet weak var alternatingButton: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var descripText: UITextView!

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var profPic: UIImageView!

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var sellerName: UILabel!
    @IBOutlet weak var addressLabel: UILabel!

    @IBOutlet weak var payButton: UIButton!
    
    var dict : NSDictionary!
    
    var picView: UIImageView!
    var pic : UIImage = UIImage()
    var name : String = "Text"
    var price : String = "Text"
    var time: String = "Time"
    var IDNum: String = ""
    var itemSeller: String = ""
    var location: String = ""
    var sold: String = ""
    var cognitoID: String = ""
    var fbID: String = ""
    var descript: String = ""
    var condition: String = ""
    var category: String = ""
    
    var selleremail: String = ""
    
    var owned: Bool = false
    
    //timer variables
    var secondsUntil: Int = 1000
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.contentSize = CGSize(width:375, height: 1100)
        if self.owned {
            self.alternatingButton.setTitle("Receive Payment", forState: .Normal)
        }
        else {
            self.alternatingButton.setTitle("Contact", forState: .Normal)
        }

        descripText.text = descript
        descripText.editable = false
        
        appDelegate.credentialsProvider.getIdentityId().continueWithBlock { (task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                print("Error: " + task.error!.localizedDescription)
            }
            else {
                // the task result will contain the identity id
                self.cognitoID = task.result as! String
            }
            return nil
        }
        
        if itemSeller != cognitoID || sold == "true" {
            payButton.hidden = true
        }
        
        FBSDKGraphRequest(graphPath: fbID, parameters: ["fields": "name, first_name, last_name, picture.type(large), email"]).startWithCompletionHandler({ (connection, result, error) -> Void in
            if (error == nil){
                self.dict = result as! NSDictionary
                print(self.dict)
                NSLog(self.dict.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as! String)
                
                
                if let url = NSURL(string: self.dict.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as! String) {
                    if let data = NSData(contentsOfURL: url){
                        var profilePicture = UIImage(data: data)
                        /*
                        self.profPic.layer.borderWidth = 1.0
                        self.profPic.layer.masksToBounds = false
                        self.profPic.layer.borderColor = UIColor.whiteColor().CGColor
                        self.profPic.layer.cornerRadius = profilePicture.frame.size.width/2
                        self.profPic.clipsToBounds = true
                        */
                        self.profPic.image = profilePicture
                    }
                }
                let nametext = (self.dict.objectForKey("first_name") as! String) + " " + (self.dict.objectForKey("last_name") as! String)
                self.selleremail = (self.dict.objectForKey("email") as! String)
                self.sellerName.text = nametext
                //self.emial.text = (self.dict.objectForKey("email") as! String)
                
            }
        })
        
        self.updateLocation()
        
        picView = UIImageView(frame:CGRectMake(0, 0, 380, 506))
        
        nameLabel.text = name
        priceLabel.text = "$" + price
        categoryLabel.text = self.category
        conditionLabel.text = self.condition
        picView.image = pic
        
        
        //set up countdown and timer stuff
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let overDate = dateFormatter.dateFromString(time)!
        let currentDate = NSDate()

        secondsUntil = secondsFrom(currentDate, endDate: overDate)
        
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
        
        self.scrollView.addSubview(picView)
        self.scrollView.sendSubviewToBack(picView)
        
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    func update() {
        if(secondsUntil < 43200)
        {
            timeLabel.textColor = UIColor.redColor()
        }
        if(secondsUntil >= 43200)
        {
            timeLabel.textColor = UIColor.blackColor()
        }
        
        if(secondsUntil > 0)
        {
            if sold == "true" {
                timeLabel.text = "Sold!"
            }
            else {
                timeLabel.text = printSecondsToDaysHoursMinutesSeconds(secondsUntil--)
            }
        }
        else {
            updateSoldStatus("ended")
            timeLabel.text = "Ended"
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
        
        let initialLocation = CLLocation(latitude: latitude!, longitude: longitude!)
        let regionRadius: CLLocationDistance = 500
        func centerMapOnLocation(location: CLLocation) {
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                regionRadius * 2.0, regionRadius * 2.0)
            map.setRegion(coordinateRegion, animated: true)
        }
        centerMapOnLocation(initialLocation)
        
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
    
    
    
    func updateSoldStatus(type: String) {
        var hashValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        hashValue.S = self.IDNum
        var otherValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        otherValue.S = self.time
        var updatedValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        updatedValue.S = type
        
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
            let viewController:QRView = segue!.destinationViewController as! QRView
            viewController.price = price
            viewController.ID = IDNum
            viewController.time = time
        }
        
    }
    
    @IBAction func reportuser(sender: AnyObject) {
        var why = "Cancel"
        let alert = UIAlertController(title: "Report Item", message: "Please select an option: ", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Violence", style: .Default, handler: { (alertAction) -> Void in
            why = "Violence"
            self.sendEmail(why)
        }))
        alert.addAction(UIAlertAction(title: "Nudity", style: .Default, handler: { (alertAction) -> Void in
            why = "Nudity"
            self.sendEmail(why)
        }))
        alert.addAction(UIAlertAction(title: "Illicit Goods (Drugs, Weapons)", style: .Default, handler: { (alertAction) -> Void in
            why = "Nudity"
            self.sendEmail(why)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (alertAction) -> Void in
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    func sendEmail(why: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["hashwage@gmail.com"])
            var body = "Reporting item " + IDNum + " for " + why + " (add any other details here)" + "\n Thanks!"
            mail.setMessageBody(body, isHTML: false)
            
            presentViewController(mail, animated: true, completion: nil)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func alternatingButton(sender: AnyObject) {
        if owned {
            self.performSegueWithIdentifier("paySegue", sender: self)
        }
        else {
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients([selleremail])
                var body = "Hey, I'm interested in " + name + ". Can I learn more?"
                mail.setMessageBody(body, isHTML: false)
                
                presentViewController(mail, animated: true, completion: nil)
            } else {
                // show failure alert
            }
        }
    }
}