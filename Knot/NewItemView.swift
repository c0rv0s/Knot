//
//  NewItemView.swift
//  Knot
//
//  Created by Nathan Mueller on 11/23/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import UIKit
import AVFoundation

class NewItemView: UIViewController, UITextFieldDelegate  {
    
    var picView: UIImageView!
    var pic : UIImage = UIImage()
    
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var priceField: UITextField!
    
    //camera 
    @IBOutlet weak var previewView: UIView!
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    //end camera
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.nameField.delegate = self;
        self.retakeButton.hidden = true
        
        priceField.delegate = self
        priceField.keyboardType = UIKeyboardType.NumbersAndPunctuation
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)

    }
    
    //Camera
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession!.canAddOutput(stillImageOutput) {
                captureSession!.addOutput(stillImageOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                previewView.layer.addSublayer(previewLayer!)
                
                captureSession!.startRunning()
            }
        }
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer!.frame = previewView.bounds
    }
    /*
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        if (segue!.identifier == "AddDetailsSegue") {
            let viewController:NewItemView = segue!.destinationViewController as! NewItemView
            viewController.pic = image
            
        }
        
    }
*/
    @IBAction func didPressTakePhoto(sender: UIButton) {
        
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    
                    self.pic = self.RBSquareImage(UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right))
                    self.previewView.hidden = true
                    self.picView = UIImageView(frame:CGRectMake(0, 64, 375, 375))
                    self.picView.image = self.pic
                    self.view.addSubview(self.picView)
                    self.view.sendSubviewToBack(self.picView)
                    self.cameraButton.hidden = true
                    self.retakeButton.hidden = false
                }
            })
        }
    }

    func RBSquareImage(image: UIImage) -> UIImage {
        let originalWidth  = image.size.width
        let originalHeight = image.size.height
        
        let cropSquare = CGRectMake((originalHeight - originalWidth)/2, 0.0, originalWidth, originalWidth)
        let imageRef = CGImageCreateWithImageInRect(image.CGImage, cropSquare);
        
        return UIImage(CGImage: imageRef!, scale: UIScreen.mainScreen().scale, orientation: image.imageOrientation)
    }

    @IBAction func retakePhoto(sender: AnyObject) {
        self.cameraButton.hidden = false
        self.retakeButton.hidden = true
        self.picView.image = nil
        self.picView.removeFromSuperview()
        self.picView = nil
        self.previewView.hidden = false
        
        
    }
    //end camera
    
    //keyboard
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            self.view.frame.origin.y -= keyboardSize.height
        }
        
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
//end keyboard
    
    //upload and submission
    @IBAction func submitNewItem(sender: UIBarButtonItem) {
        if (self.nameField.text == "") {
            let alert = UIAlertController(title: "Attention", message: "Please enter the missing values.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            var uniqueID = randomStringWithLength(16) as String
            self.insertSomeItems(uniqueID).continueWithBlock({
                (task: BFTask!) -> BFTask! in
                
                if (task.error != nil) {
                    print(task.error!.description)
                } else {
                    print("DynamoDB save succeeded")
                }
                
                return nil;
            })

            //upload image
            let transferManager = AWSS3TransferManager.defaultS3TransferManager()
            let testFileURL1 = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent("temp"))
            let uploadRequest1 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
            
            let data = UIImageJPEGRepresentation(pic, 0.5)
            data!.writeToURL(testFileURL1, atomically: true)
            uploadRequest1.bucket = "knotcompleximages"
            uploadRequest1.key = uniqueID
            uploadRequest1.body = testFileURL1
            
            let task = transferManager.upload(uploadRequest1)
            task.continueWithBlock { (task: AWSTask!) -> AnyObject! in
                if task.error != nil {
                    print("Error: \(task.error)")
                } else {
                    print("Upload successful")
                    let alert = UIAlertController(title: "Success", message: "Your upload has completed.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Awesome!", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                return nil
            }

            print("submission code completed")
        }
        //notification handling

    }
    
    func insertSomeItems(uniqueID: String) -> BFTask! {
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        /***CONVERT FROM NSDate to String ****/
        let date = NSDate() //get the time, in this case the time an object was created.
        //format date
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "hh:mm" //format style. Browse online to get a format that fits your needs.
        var dateString = dateFormatter.stringFromDate(date)
        print(dateString)
        
        // Create a record in a dataset and synchronize with the server


        
        var item = ListItem()
        item.name  = self.nameField.text!
        item.ID   = uniqueID
        item.price   = self.priceField.text!
        item.location = "Silicon Valley"
        item.time  = dateString
        item.sold = false
        let task = mapper.save(item)
        
        print("item created, ready to run task")
        return BFTask(forCompletionOfAllTasks: [task])
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
    //end upload and submissions

}