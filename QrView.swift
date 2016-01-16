//
//  QrView.swift
//  Knot
//
//  Created by Nathan Mueller on 11/16/15.
//  Copyright © 2015 Knot App. All rights reserved.
//


import UIKit

class QrView: UIViewController {
    
    var apiCall = "https://chart.googleapis.com/chart?chs=100x100&cht=qr&chl=bitcoin:"
    var address = "1A5iCBMXPJF7esUssyaaeLpTocoyW2EK6n"
    var imageURL: UIImageView!
    var BTCprice: String = "420.0"
    var price: String = "9.99"
    var ID: String = "fg5poud5gZW2z6Mw"
    
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
            
            let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            var lock:NSLock?
            var lastEvaluatedKey:[NSObject : AnyObject]!
            var item = ListItem()
            
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            let queryExpression = AWSDynamoDBScanExpression()
            queryExpression.exclusiveStartKey = lastEvaluatedKey
            queryExpression.limit = 50;
            dynamoDBObjectMapper.scan(ListItem.self, expression: queryExpression).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task:AWSTask!) -> AnyObject! in
                if task.result != nil {
                    let paginatedOutput = task.result as! AWSDynamoDBPaginatedOutput
                    for oldItem in paginatedOutput.items as! [ListItem] {
                        if item.ID == self.ID {
                            item.name  = oldItem.name
                            item.ID   = oldItem.ID
                            item.price   = oldItem.price
                            item.location =  oldItem.location
                            item.time  = oldItem.time
                            item.sold = "true"
                            item.seller = oldItem.seller
                            let task = mapper.save(item)
                        }
                    }
                }
                return nil
            })

        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }

}

