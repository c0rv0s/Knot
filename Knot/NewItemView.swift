//
//  NewItemView.swift
//  Knot
//
//  Created by Nathan Mueller on 11/23/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import UIKit
import CoreLocation

class NewItemView: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate,
UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var picOneView: UIImageView!
    @IBOutlet weak var picTwoView: UIImageView!
    @IBOutlet weak var picThreeView: UIImageView!
    
    var picOne: UIImage!
    var picTwo: UIImage!
    var picThree: UIImage!
    
    @IBOutlet weak var priceField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var descriptionField: UITextView!

    @IBOutlet weak var addphoto1: UIButton!
    @IBOutlet weak var addphoto2: UIButton!
    @IBOutlet weak var addphoto3: UIButton!
    
    @IBOutlet weak var lengthField: UITextField!
    @IBOutlet weak var categoryField: UITextField!
    @IBOutlet weak var conditionField: UITextField!
    
    var photoNum : Int = 1
    let picker = UIImagePickerController()
    var fbID = "eror"
    
    var one = false
    var two = false
    var three = false

    var timeHoursString = "1"
    var timeHoursInt = 1
    var hours = ["1 Hour": 1,"3 Hours": 3,"5 Hours": 5,"12 Hours": 12,"24 Hours": 24,"3 Days": 72,"5 Days": 120,"7 Days": 175]
    var lengthOption = ["1 Hour", "3 Hours", "5 Hours", "12 Hours", "24 Hours", "3 Days", "5 Days", "7 Days"]
    var conditionOption = ["New", "Manufacturer refurbished", "Seller refurbished", "Used", "For parts or not working"]
    var categoryOption = ["Art and Antiques", "Baby and Child", "Books, Movies and Music", "Games and Consoles", "Electronics", "Cameras and Photo", "Fashion and Accessories", "Sport and Leisure", "Cars and Motor", "Furniture", "Appliances", "Services", "Other"]
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //location
    var locationManager: OneShotLocationManager?
    var locString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        // Do any additional setup after loading the view, typically from a nib
        addphoto2.hidden = true
        addphoto3.hidden = true
        
        if((FBSDKAccessToken.currentAccessToken()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    var dict = result as! NSDictionary
                    self.fbID = dict.objectForKey("id") as! String
                }
            })
        }

        nameField.delegate = self;

        var lengthView = UIPickerView()
        lengthView.tag = 0
        lengthView.delegate = self
        lengthField.inputView = lengthView
        
        var categoryView = UIPickerView()
        categoryView.tag = 1
        categoryView.delegate = self
        categoryField.inputView = categoryView
        
        var conditionView = UIPickerView()
        conditionView.tag = 2
        conditionView.delegate = self
        conditionField.inputView = conditionView
        
        locationManager = OneShotLocationManager()
        locationManager!.fetchWithCompletion {location, error in
            // fetch location or an error
            if let loc = location {
                print(location)
                var construct = String(location!.coordinate.latitude) + " "
                construct += String(location!.coordinate.longitude)
                self.locString = construct
            } else if let err = error {
                print(err.localizedDescription)
            }
            self.locationManager = nil
        }
        
        priceField.delegate = self
        priceField.keyboardType = UIKeyboardType.NumbersAndPunctuation
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)

    }

    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
    func insertItem(uniqueID: String) -> BFTask! {
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        /***CONVERT FROM NSDate to String ****/
        let currentDate = NSDate()
        var overDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Hour, value: timeHoursInt, toDate: currentDate, options: NSCalendarOptions.init(rawValue: 0))
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        var dateString = dateFormatter.stringFromDate(overDate!)
        
        
        // Create a record in a dataset and synchronize with the server
        // Retrieve your Amazon Cognito ID
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
        
        var item = ListItem()
        
        item.name  = self.nameField.text!
        item.ID   = uniqueID
        item.price   = self.priceField.text!
        item.location =  locString
        item.time  = dateString
        item.sold = "false"
        item.seller = cognitoID
        item.sellerFBID = self.fbID
        item.descriptionKnot = self.descriptionField.text
        item.category = categoryField.text!
        item.condition = conditionField.text!
        item.numberOfPics = photoNum
        print(item)
        let task = mapper.save(item)
        
        
        
        print("item created, preparing upload")
        return BFTask(forCompletionOfAllTasks: [task])
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return lengthOption.count
        }
        if pickerView.tag == 1 {
            return categoryOption.count
        }
        else {
            return conditionOption.count
        }
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            timeHoursInt = hours[lengthOption[row]]!
            return lengthOption[row]
        }
        if pickerView.tag == 1 {
            return categoryOption[row]
        }
        else {
            return conditionOption[row]
        }
        return ""
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            lengthField.text = lengthOption[row]
        }
        if pickerView.tag == 1 {
            categoryField.text = categoryOption[row]
        }
        else {
            conditionField.text = conditionOption[row]
        }
    }
    
    func locationManager(manager: CLLocationManager,didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    //keyboard
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        let userInfo: [NSObject : AnyObject] = sender.userInfo!
        
        let keyboardSize: CGSize = userInfo[UIKeyboardFrameBeginUserInfoKey]!.CGRectValue.size
        let offset: CGSize = userInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue.size
        
        if keyboardSize.height == offset.height {
            if self.view.frame.origin.y == 0 {
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    self.view.frame.origin.y -= keyboardSize.height
                })
            }
        } else {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                self.view.frame.origin.y += keyboardSize.height - offset.height
            })
        }
        print(self.view.frame.origin.y)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.view.frame.origin.y += keyboardSize.height
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func userTappedBackground(sender: AnyObject) {
        view.endEditing(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: self.view.window)
    }
//end keyboard
    
    @IBAction func addphoto1(sender: AnyObject) {
        photoNum = 1
        self.showCamera()
    }
    @IBAction func addphoto2(sender: AnyObject) {
        photoNum = 2
        self.showCamera()
    }
    @IBAction func addphoto3(sender: AnyObject) {
        photoNum = 3
        self.showCamera()
    }
    
    func showCamera() {
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
        picker.allowsEditing = false
        picker.sourceType = UIImagePickerControllerSourceType.Camera
        picker.cameraCaptureMode = .Photo
        picker.modalPresentationStyle = .FullScreen
        presentViewController(picker,
            animated: true,
            completion: nil)
        }
    }
    
    //MARK: - Delegates
    //What to do when the picker returns with a photo
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]){
        var chosenImage = RBSquareImage(info[UIImagePickerControllerOriginalImage] as! UIImage) //2
        //myImageView.contentMode = .ScaleAspectFit //3
        if photoNum == 1 {
            picOne = chosenImage
            picOneView.image = chosenImage
            addphoto2.hidden = false
            addphoto1.setTitle("Change", forState: .Normal)
            one = true
        }
        if photoNum == 2 {
            picTwo = chosenImage
            picTwoView.image = chosenImage
            addphoto3.hidden = false
            addphoto2.setTitle("Change", forState: .Normal)
            two = true
        }
        if photoNum == 3 {
            picThree = chosenImage
            picThreeView.image = chosenImage
            addphoto3.setTitle("Change", forState: .Normal)
            three = true
        }
        dismissViewControllerAnimated(true, completion: nil) //5
    }
    //What to do if the image picker cancels.
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true,
            completion: nil)
    }
    
    func RBSquareImage(image: UIImage) -> UIImage {
        var originalWidth  = image.size.width
        var originalHeight = image.size.height
        var x: CGFloat = 0.0
        var y: CGFloat = 0.0
        var edge: CGFloat = 0.0
        
        if (originalWidth > originalHeight) {
            // landscape
            edge = originalHeight
            x = (originalWidth - edge) / 2.0
            y = 0.0
            
        } else if (originalHeight > originalWidth) {
            // portrait
            edge = originalWidth
            x = 0.0
            y = (originalHeight - originalWidth) / 2.0
        } else {
            // square
            edge = originalWidth
        }
        
        var cropSquare = CGRectMake(x, y, edge, edge)
        var imageRef = CGImageCreateWithImageInRect(image.CGImage, cropSquare);
        
        return UIImage(CGImage: imageRef!, scale: UIScreen.mainScreen().scale, orientation: image.imageOrientation)
    }
    
    @IBAction func submit(sender: AnyObject) {
        if (self.nameField.text == "" || self.priceField.text == "") {
            let alert = UIAlertController(title: "Attention", message: "Please enter the missing values.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            SwiftSpinner.show("Uploading \(self.nameField.text!)")
            
            var uniqueID = randomStringWithLength(16) as String
            self.insertItem(uniqueID).continueWithBlock({
                (task: BFTask!) -> BFTask! in
                
                if (task.error != nil) {
                    print(task.error!.description)
                } else {
                    print("DynamoDB save succeeded")
                }
                
                return nil;
            })
            print("hello")
            //upload image
            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
            
            //
            //
            var success1 = 0
            var success2 = 0
            var success3 = 0
            
            if one {
                print("one is one")
                let testFileURL1 = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent("temp"))
                let uploadRequest1 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
                let dataOne = UIImageJPEGRepresentation(picOne, 0.5)
                dataOne!.writeToURL(testFileURL1, atomically: true)
                uploadRequest1.bucket = "knotcompleximages"
                uploadRequest1.key = uniqueID
                uploadRequest1.body = testFileURL1
                let task1 = transferManager.upload(uploadRequest1)
                task1.continueWithBlock { (task: AWSTask!) -> AnyObject! in
                    if task.error != nil {
                        print("Error: \(task.error)")
                        success1 = 2
                    } else {
                        success1 = 1
                        if !self.two {
                            self.wrapUpSubmission(success1, succ2: success2, succ3: success3)
                        }
                    }
                    return nil
                }
                if two {
                    print("two is on")
                    let testFileURL2 = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent("temp"))
                    let uploadRequest2 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
                    let dataTwo = UIImageJPEGRepresentation(picTwo, 0.5)
                    dataTwo!.writeToURL(testFileURL2, atomically: true)
                    uploadRequest2.bucket = "knotcompleximage2"
                    uploadRequest2.key = uniqueID
                    uploadRequest2.body = testFileURL2
                    let task2 = transferManager.upload(uploadRequest2)
                    task2.continueWithBlock { (task: AWSTask!) -> AnyObject! in
                        if task.error != nil {
                            print("Error: \(task.error)")
                            success2 = 2
                        } else {
                            success2 = 1
                            if !self.three {
                                self.wrapUpSubmission(success1, succ2: success2, succ3: success3)
                            }
                        }
                        return nil
                    }
                    if three {
                        print("three is on")
                        let testFileURL3 = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent("temp"))
                        let uploadRequest3 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
                        let dataThree = UIImageJPEGRepresentation(picThree, 0.5)
                        dataThree!.writeToURL(testFileURL3, atomically: true)
                        uploadRequest3.bucket = "knotcompleximage3"
                        uploadRequest3.key = uniqueID
                        uploadRequest3.body = testFileURL3
                        let task3 = transferManager.upload(uploadRequest3)
                        task3.continueWithBlock { (task: AWSTask!) -> AnyObject! in
                            if task.error != nil {
                                print("Error: \(task.error)")
                                success3 = 2
                            }
                            else {
                                success3 = 1
                                self.wrapUpSubmission(success1, succ2: success2, succ3: success3)
                            }
                            return nil
                        }
                    }
                }
            }
        }
    }
    
    func wrapUpSubmission(succ1: Int, succ2: Int, succ3: Int) {
        SwiftSpinner.hide()
        if succ1 == 2 || succ2 == 2 || succ3 == 2 {
            let alert = UIAlertController(title: "Uh Oh", message: "Something went wrong, contact support or try again", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (alertAction) -> Void in
                self.priceField.text = ""
                self.nameField.text = ""
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        print("Upload successful")
        let alert = UIAlertController(title: "Success", message: "Your upload has completed.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Awesome!", style: .Default, handler: { (alertAction) -> Void in
            self.priceField.text = ""
            self.nameField.text = ""
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MainRootView") as! UITabBarController
            self.presentViewController(vc, animated: true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
        //end upload and submissions
    @IBAction func cancelListing(sender: AnyObject) {
        let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MainRootView") as! UITabBarController
        self.presentViewController(vc, animated: true, completion: nil)
    }
}