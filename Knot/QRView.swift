//
//  QrView.swift
//  Knot
//
//  Created by Nathan Mueller on 11/16/15.
//  Copyright © 2015 Knot App. All rights reserved.
//


import UIKit

class QRView: UIViewController {
    
    var apiCall = "https://chart.googleapis.com/chart?chs=100x100&cht=qr&chl=bitcoin:"
    var address = ""
    var imageURL: UIImageView!
    var BTCprice: String = ""
    var price: String = ""
    var ID: String = ""
    var time: String = ""
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //fetch user wallet
        let syncClient = AWSCognito.defaultCognito()
        let dataset = syncClient.openOrCreateDataset("userWallet")
        let value = dataset.stringForKey("walletBTC")
        if (value == nil) {
            let alert = UIAlertController(title: "Attention", message: "Please enter a wallet ID in Accounts Tab", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            address = value
        }

        //wallet complete, continure
        
        imageURL = UIImageView(frame:CGRectMake(0, 0, 400, 700))
        
        imageURL.image = nil
        
        var qrURL = apiCall
        calcBitPrice(price)
        qrURL += address
        qrURL += "?amount="
        
        //check that price fetched
        while(true) {
            let length = self.BTCprice.characters.count
            if length > 1 {
                break
            }
        }
        qrURL += self.BTCprice
        //self.priceLabel.text = "Total BTC: " + self.BTCprice
        
        if let checkedUrl = NSURL(string: qrURL) {
            imageURL.contentMode = .ScaleAspectFit
            downloadImage(checkedUrl)
        }
        self.view.addSubview(imageURL)
        self.view.sendSubviewToBack(imageURL)
        print(qrURL)
        
    }
    
    //MARK: Get QR code image
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func downloadImage(url: NSURL){
        print("Started downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                print("Finished downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
                self.imageURL.image = UIImage(data: data)
            }
        }
    }
    
    
    //MARK: get the current bitcoin price based on dollar amount
    func calcBitPrice(dollars: String) {
        self.BTCprice = ""
        var call = "https://blockchain.info/tobtc?currency=USD&value="
        call += dollars
        
        let url = NSURL(string: call)
        
        if url != nil {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
                print(data)
                
                if error == nil {
                    
                    var urlContent = NSString(data: data!, encoding: NSASCIIStringEncoding) as NSString!
                    self.BTCprice = urlContent as String
                    print(self.BTCprice)
                }
            })
            task.resume()
        }
    }
    
    @IBAction func paymentComplete(sender: AnyObject) {
        let alert = UIAlertController(title: "Attention", message: "This will remove this item from the feed, are you sure you want to keep going?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Keep Going", style: .Default, handler: { (alertAction) -> Void in
            self.updateSoldStatus()
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("MainRootView") as! UITabBarController
            self.presentViewController(vc, animated: true, completion: nil)

        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateSoldStatus() {
        SwiftSpinner.show("Completing Transaction")
        var hashValue: AWSDynamoDBAttributeValue = AWSDynamoDBAttributeValue()
        hashValue.S = self.ID
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
        print(updateInput)
        SwiftSpinner.hide()
    }

}

