//
//  AddDetailsView.swift
//  Knot
//
//  Created by Nathan Mueller on 11/23/15.
//  Copyright © 2015 Knot App. All rights reserved.
//

import UIKit
import AVFoundation

class AddDetailsView: UIViewController, UITextFieldDelegate  {
    
    @IBOutlet weak var picView: UIImageView!
    var pic : UIImage = UIImage()
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var priceField: UITextField!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.nameField.delegate = self;
        picView.image = pic
        
        priceField.delegate = self
        priceField.keyboardType = UIKeyboardType.NumbersAndPunctuation
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func userTappedBackground(sender: AnyObject) {
        view.endEditing(true)
    }

    @IBAction func submitNewItem(sender: AnyObject) {
        
        /*
        // Initialize the Cognito Sync client
        let syncClient = AWSCognito.defaultCognito()
        
        // Create a record in a dataset and synchronize with the server
        var dataset = syncClient.openOrCreateDataset("myDataset")
        dataset.setString(nameField.text, forKey:"name")
        dataset.setString(priceField.text, forKey:"price")
        //dataset.setValue(pic, forKey: "picture")
        dataset.synchronize().continueWithBlock {(task: AWSTask!) -> AnyObject! in
            if task.error != nil {
                print("Error: \(task.error)")
            } else {
                print("Upload successful")
            }
            
            return nil
            
        }
        */
        
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        let testFileURL1 = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent(nameField.text! + ".png"))
        let uploadRequest1 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        
        let data = UIImageJPEGRepresentation(pic, 0.5)
        data!.writeToURL(testFileURL1, atomically: true)
        uploadRequest1.bucket = "knot-listings"
        uploadRequest1.key =  nameField.text
        uploadRequest1.body = testFileURL1
        
        let task = transferManager.upload(uploadRequest1)
        task.continueWithBlock { (task: AWSTask!) -> AnyObject! in
            if task.error != nil {
                print("Error: \(task.error)")
            } else {
                print("Upload successful")
            }
            return nil
        }
        self.performSegueWithIdentifier("SubmitItem", sender: nil)
    }

}